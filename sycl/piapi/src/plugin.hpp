//==--------------------- plugin.hpp - SYCL platform-------------------==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#pragma once

#include <pi.hpp>

namespace detail {

/// The plugin class provides a unified interface to the underlying low-level
/// runtimes for the device-agnostic SYCL runtime.
///
/// \ingroup sycl_pi
class plugin {
public:
  plugin() = delete;

  plugin(pi::PiPlugin Plugin) : MPlugin(Plugin) {
    MPiEnableTrace = (std::getenv("SYCL_PI_TRACE") != nullptr);
  }

  ~plugin() = default;

  /// Checks return value from PI calls.
  ///
  /// \throw Exception if pi_result is not a PI_SUCCESS.
  template <typename Exception>
  void checkPiResult(pi::PiResult pi_result, const Exception& ex) const {
    if(pi_result != 0) {
      throw ex;
    }
  }

  /// Calls the PiApi, traces the call, and returns the result.
  ///
  /// Usage:
  /// \code{cpp}
  /// PiResult Err = plugin.call<PiApiKind::pi>(Args);
  /// Plugin.checkPiResult(Err); // Checks Result and throws a runtime_error
  /// // exception.
  /// \endcode
  ///
  /// \sa plugin::checkPiResult
  template <PiApiKind PiApiOffset, typename... ArgsT>
  pi::PiResult call_nocheck(ArgsT... Args) const {
    pi::PiFuncInfo<PiApiOffset> PiCallInfo;
    if (MPiEnableTrace) {
      std::string FnName = PiCallInfo.getFuncName();
      std::cout << "---> " << FnName << "(" << std::endl;
      pi::printArgs(Args...);
    }
    pi::PiResult R = PiCallInfo.getFuncPtr(MPlugin)(Args...);
    if (MPiEnableTrace) {
      std::cout << ") ---> ";
      pi::printArgs(R);
    }
    return R;
  }

  /// Calls the API, traces the call, checks the result
  ///
  /// \throw cl::sycl::runtime_exception if the call was not successful.
  template <PiApiKind PiApiOffset, typename... ArgsT>
  void call(ArgsT... Args) const {
    pi::PiResult Err = call_nocheck<PiApiOffset>(Args...);
    checkPiResult(Err, std::runtime_error("Invalid PIAPI call"));
  }
  // TODO: Make this private. Currently used in program_manager to create a
  // pointer to PiProgram.
  pi::PiPlugin MPlugin;

private:
  bool MPiEnableTrace;

}; // class plugin

} // namespace detail
