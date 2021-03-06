//===- VectorUtils.cpp - MLIR Utilities for VectorOps   ------------------===//
//
// Part of the MLIR Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements utility methods for working with the VectorOps dialect.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/VectorOps/VectorUtils.h"
#include "mlir/Analysis/LoopAnalysis.h"
#include "mlir/Dialect/AffineOps/AffineOps.h"
#include "mlir/Dialect/StandardOps/Ops.h"
#include "mlir/Dialect/VectorOps/VectorOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/IntegerSet.h"
#include "mlir/IR/Operation.h"
#include "mlir/Support/Functional.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/MathExtras.h"
#include "mlir/Support/STLExtras.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SetVector.h"

using llvm::SetVector;

namespace mlir {

SmallVector<int64_t, 4> computeStrides(ArrayRef<int64_t> shape,
                                       ArrayRef<int64_t> sizes) {
  int64_t rank = shape.size();
  // Compute the count for each dimension.
  SmallVector<int64_t, 4> sliceDimCounts(rank);
  for (int64_t r = 0; r < rank; ++r)
    sliceDimCounts[r] = ceilDiv(shape[r], sizes[r]);
  // Use that to compute the slice stride for each dimension.
  SmallVector<int64_t, 4> sliceStrides(rank);
  sliceStrides[rank - 1] = 1;
  for (int64_t r = rank - 2; r >= 0; --r)
    sliceStrides[r] = sliceStrides[r + 1] * sliceDimCounts[r + 1];
  return sliceStrides;
}

SmallVector<int64_t, 4> delinearize(ArrayRef<int64_t> sliceStrides,
                                    int64_t index) {
  int64_t rank = sliceStrides.size();
  SmallVector<int64_t, 4> vectorOffsets(rank);
  for (int64_t r = 0; r < rank; ++r) {
    assert(sliceStrides[r] > 0);
    vectorOffsets[r] = index / sliceStrides[r];
    index %= sliceStrides[r];
  }
  return vectorOffsets;
}

SmallVector<int64_t, 4>
computeElementOffsetsFromVectorSliceOffsets(ArrayRef<int64_t> sizes,
                                            ArrayRef<int64_t> vectorOffsets) {
  return functional::zipMap([](int64_t v1, int64_t v2) { return v1 * v2; },
                            vectorOffsets, sizes);
}

SmallVector<int64_t, 4> computeSliceSizes(ArrayRef<int64_t> shape,
                                          ArrayRef<int64_t> sizes,
                                          ArrayRef<int64_t> elementOffsets) {
  int64_t rank = shape.size();
  SmallVector<int64_t, 4> sliceSizes(rank);
  for (unsigned r = 0; r < rank; ++r)
    sliceSizes[r] = std::min(sizes[r], shape[r] - elementOffsets[r]);
  return sliceSizes;
}

Optional<SmallVector<int64_t, 4>> shapeRatio(ArrayRef<int64_t> superShape,
                                             ArrayRef<int64_t> subShape) {
  if (superShape.size() < subShape.size()) {
    return Optional<SmallVector<int64_t, 4>>();
  }

  // Starting from the end, compute the integer divisors.
  // Set the boolean `divides` if integral division is not possible.
  std::vector<int64_t> result;
  result.reserve(superShape.size());
  bool divides = true;
  auto divide = [&divides, &result](int superSize, int subSize) {
    assert(superSize > 0 && "superSize must be > 0");
    assert(subSize > 0 && "subSize must be > 0");
    divides &= (superSize % subSize == 0);
    result.push_back(superSize / subSize);
  };
  functional::zipApply(
      divide, SmallVector<int64_t, 8>{superShape.rbegin(), superShape.rend()},
      SmallVector<int64_t, 8>{subShape.rbegin(), subShape.rend()});

  // If integral division does not occur, return and let the caller decide.
  if (!divides) {
    return None;
  }

  // At this point we computed the ratio (in reverse) for the common
  // size. Fill with the remaining entries from the super-vector shape (still in
  // reverse).
  int commonSize = subShape.size();
  std::copy(superShape.rbegin() + commonSize, superShape.rend(),
            std::back_inserter(result));

  assert(result.size() == superShape.size() &&
         "super to sub shape ratio is not of the same size as the super rank");

  // Reverse again to get it back in the proper order and return.
  return SmallVector<int64_t, 4>{result.rbegin(), result.rend()};
}

Optional<SmallVector<int64_t, 4>> shapeRatio(VectorType superVectorType,
                                             VectorType subVectorType) {
  assert(superVectorType.getElementType() == subVectorType.getElementType() &&
         "vector types must be of the same elemental type");
  return shapeRatio(superVectorType.getShape(), subVectorType.getShape());
}

/// Constructs a permutation map from memref indices to vector dimension.
///
/// The implementation uses the knowledge of the mapping of enclosing loop to
/// vector dimension. `enclosingLoopToVectorDim` carries this information as a
/// map with:
///   - keys representing "vectorized enclosing loops";
///   - values representing the corresponding vector dimension.
/// The algorithm traverses "vectorized enclosing loops" and extracts the
/// at-most-one MemRef index that is invariant along said loop. This index is
/// guaranteed to be at most one by construction: otherwise the MemRef is not
/// vectorizable.
/// If this invariant index is found, it is added to the permutation_map at the
/// proper vector dimension.
/// If no index is found to be invariant, 0 is added to the permutation_map and
/// corresponds to a vector broadcast along that dimension.
///
/// Returns an empty AffineMap if `enclosingLoopToVectorDim` is empty,
/// signalling that no permutation map can be constructed given
/// `enclosingLoopToVectorDim`.
///
/// Examples can be found in the documentation of `makePermutationMap`, in the
/// header file.
static AffineMap makePermutationMap(
    ArrayRef<Value> indices,
    const DenseMap<Operation *, unsigned> &enclosingLoopToVectorDim) {
  if (enclosingLoopToVectorDim.empty())
    return AffineMap();
  MLIRContext *context =
      enclosingLoopToVectorDim.begin()->getFirst()->getContext();
  using functional::makePtrDynCaster;
  using functional::map;
  SmallVector<AffineExpr, 4> perm(enclosingLoopToVectorDim.size(),
                                  getAffineConstantExpr(0, context));

  for (auto kvp : enclosingLoopToVectorDim) {
    assert(kvp.second < perm.size());
    auto invariants = getInvariantAccesses(
        cast<AffineForOp>(kvp.first).getInductionVar(), indices);
    unsigned numIndices = indices.size();
    unsigned countInvariantIndices = 0;
    for (unsigned dim = 0; dim < numIndices; ++dim) {
      if (!invariants.count(indices[dim])) {
        assert(perm[kvp.second] == getAffineConstantExpr(0, context) &&
               "permutationMap already has an entry along dim");
        perm[kvp.second] = getAffineDimExpr(dim, context);
      } else {
        ++countInvariantIndices;
      }
    }
    assert((countInvariantIndices == numIndices ||
            countInvariantIndices == numIndices - 1) &&
           "Vectorization prerequisite violated: at most 1 index may be "
           "invariant wrt a vectorized loop");
  }
  return AffineMap::get(indices.size(), 0, perm);
}

/// Implementation detail that walks up the parents and records the ones with
/// the specified type.
/// TODO(ntv): could also be implemented as a collect parents followed by a
/// filter and made available outside this file.
template <typename T>
static SetVector<Operation *> getParentsOfType(Operation *op) {
  SetVector<Operation *> res;
  auto *current = op;
  while (auto *parent = current->getParentOp()) {
    if (auto typedParent = dyn_cast<T>(parent)) {
      assert(res.count(parent) == 0 && "Already inserted");
      res.insert(parent);
    }
    current = parent;
  }
  return res;
}

/// Returns the enclosing AffineForOp, from closest to farthest.
static SetVector<Operation *> getEnclosingforOps(Operation *op) {
  return getParentsOfType<AffineForOp>(op);
}

AffineMap
makePermutationMap(Operation *op, ArrayRef<Value> indices,
                   const DenseMap<Operation *, unsigned> &loopToVectorDim) {
  DenseMap<Operation *, unsigned> enclosingLoopToVectorDim;
  auto enclosingLoops = getEnclosingforOps(op);
  for (auto *forInst : enclosingLoops) {
    auto it = loopToVectorDim.find(forInst);
    if (it != loopToVectorDim.end()) {
      enclosingLoopToVectorDim.insert(*it);
    }
  }
  return makePermutationMap(indices, enclosingLoopToVectorDim);
}

bool matcher::operatesOnSuperVectorsOf(Operation &op,
                                       VectorType subVectorType) {
  // First, extract the vector type and distinguish between:
  //   a. ops that *must* lower a super-vector (i.e. vector.transfer_read,
  //      vector.transfer_write); and
  //   b. ops that *may* lower a super-vector (all other ops).
  // The ops that *may* lower a super-vector only do so if the super-vector to
  // sub-vector ratio exists. The ops that *must* lower a super-vector are
  // explicitly checked for this property.
  /// TODO(ntv): there should be a single function for all ops to do this so we
  /// do not have to special case. Maybe a trait, or just a method, unclear atm.
  bool mustDivide = false;
  (void)mustDivide;
  VectorType superVectorType;
  if (auto read = dyn_cast<vector::TransferReadOp>(op)) {
    superVectorType = read.getVectorType();
    mustDivide = true;
  } else if (auto write = dyn_cast<vector::TransferWriteOp>(op)) {
    superVectorType = write.getVectorType();
    mustDivide = true;
  } else if (op.getNumResults() == 0) {
    if (!isa<ReturnOp>(op)) {
      op.emitError("NYI: assuming only return operations can have 0 "
                   " results at this point");
    }
    return false;
  } else if (op.getNumResults() == 1) {
    if (auto v = op.getResult(0).getType().dyn_cast<VectorType>()) {
      superVectorType = v;
    } else {
      // Not a vector type.
      return false;
    }
  } else {
    // Not a vector.transfer and has more than 1 result, fail hard for now to
    // wake us up when something changes.
    op.emitError("NYI: operation has more than 1 result");
    return false;
  }

  // Get the ratio.
  auto ratio = shapeRatio(superVectorType, subVectorType);

  // Sanity check.
  assert((ratio.hasValue() || !mustDivide) &&
         "vector.transfer operation in which super-vector size is not an"
         " integer multiple of sub-vector size");

  // This catches cases that are not strictly necessary to have multiplicity but
  // still aren't divisible by the sub-vector shape.
  // This could be useful information if we wanted to reshape at the level of
  // the vector type (but we would have to look at the compute and distinguish
  // between parallel, reduction and possibly other cases.
  if (!ratio.hasValue()) {
    return false;
  }

  return true;
}

} // namespace mlir
