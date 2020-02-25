cmake_minimum_required(VERSION 3.7)
project(piapi_opencl VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

#TODO:
#1. Figure out why CMP0057 has to be set. Should have been taken care of earlier in the build
#2. Use AddLLVM to modify the build and access config options
#cmake_policy(SET CMP0057 NEW)
#include(AddLLVM)

find_package(OpenCL REQUIRED)

set(pi_include_dir "../../include")
set(opencl_ext_include_dir "../../../include")

# Plugin for OpenCL
# Create Shared library for libpi_opencl.so.
#TODO: remove dependency on pi.hpp in sycl project.
#TODO: Currently, the pi.hpp header is common between sycl and plugin library sources. 
#This can be changed by copying the pi.hpp file in the plugins project.
add_library(pi_opencl SHARED
  "${pi_include_dir}/pi.h"
  "pi_opencl.cpp"
  )

set_target_properties(pi_opencl PROPERTIES LINKER_LANGUAGE CXX)

#preprocessor definitions for compiling a target's sources. We do not need it for pi_opencl
target_include_directories(pi_opencl PRIVATE "${pi_include_dir}" "${opencl_ext_include_dir}")

#link pi_opencl with OpenCL headers and ICD Loader.
target_link_libraries( pi_opencl
    PRIVATE OpenCL::OpenCL
)
target_compile_definitions(pi_opencl PRIVATE CL_TARGET_OPENCL_VERSION=210)

install(TARGETS pi_opencl
    LIBRARY DESTINATION "lib${LLVM_LIBDIR_SUFFIX}" COMPONENT pi_opencl
    RUNTIME DESTINATION "bin" COMPONENT pi_opencl)
