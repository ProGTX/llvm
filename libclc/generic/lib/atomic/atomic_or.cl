#include <clc/clc.h>
#include <spirv/spirv.h>

#define IMPL(TYPE, TYPE_MANGLED, AS, AS_MANGLED) \
_CLC_OVERLOAD _CLC_DEF TYPE atomic_or(volatile AS TYPE *p, TYPE val) { \
  /* TODO: Stop manually mangling this name. Need C++ namespaces to get the exact mangling. */ \
  return _Z16__spirv_AtomicOrPU3##AS_MANGLED##TYPE_MANGLED##N5__spv5ScopeENS1_19MemorySemanticsMaskE##TYPE_MANGLED( \
      p, Device, SequentiallyConsistent, val); \
}

IMPL(int, i, global, AS1)
IMPL(unsigned int, j, global, AS1)
IMPL(int, i, local, AS3)
IMPL(unsigned int, j, local, AS3)
#undef IMPL
