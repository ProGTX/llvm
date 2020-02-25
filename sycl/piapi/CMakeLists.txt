cmake_minimum_required(VERSION 3.7)
project(piapi VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(pi_include_dir "${CMAKE_SOURCE_DIR}/include")

add_library(piapi STATIC
  "${pi_include_dir}/pi.h"
  "${pi_include_dir}/pi.hpp"
  "${CMAKE_SOURCE_DIR}/src/pi.cpp"
)
target_include_directories(piapi PUBLIC "${pi_include_dir}")

option(PI_OPENCL_HEADERS "Should OpenCL headers be included" ON)
if(PI_OPENCL_HEADERS)
  find_package(OpenCL REQUIRED)
  set(opencl_ext_include_dir "${CMAKE_SOURCE_DIR}/../include")

  # Do not link against the OpenCL::OpenCL library, just need the headers
  target_include_directories(piapi PUBLIC
    "${opencl_ext_include_dir}"
    "${OpenCL_INCLUDE_DIR}"
  )
  target_compile_definitions(piapi PUBLIC CL_TARGET_OPENCL_VERSION=210)

  install(DIRECTORY "${opencl_ext_include_dir}"
    DESTINATION . COMPONENT headers
    FILES_MATCHING
      PATTERN "cl_usm_ext.h"
      PATTERN "__spirv" EXCLUDE
      PATTERN "sycl" EXCLUDE
  )
endif()

install(DIRECTORY "${pi_include_dir}"
  DESTINATION . COMPONENT headers
  FILES_MATCHING
    PATTERN "*.h"
    PATTERN "*.hpp"
    PATTERN "*.def" EXCLUDE
)
install(TARGETS piapi
  ARCHIVE DESTINATION "lib" COMPONENT piapi
  RUNTIME DESTINATION "bin" COMPONENT piapi
)

add_subdirectory(plugins)
