cmake_minimum_required(VERSION 3.4)
project(piapi VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

################################################################################
# Main library

set(pi_include_dir "${PROJECT_SOURCE_DIR}/include")
set(pi_source_dir "${PROJECT_SOURCE_DIR}/src")
set(pi_library_output_dir "${CMAKE_CURRENT_BINARY_DIR}/lib")
set(pi_binary_output_dir "${CMAKE_CURRENT_BINARY_DIR}/bin")

set(CONF_INCLUDE_DIRS "")

add_library(piapi STATIC
  "${pi_include_dir}/pi/pi.h"
  "${pi_include_dir}/pi/pi.hpp"
  "${pi_source_dir}/pi.cpp"
  "$<$<PLATFORM_ID:Windows>:${pi_source_dir}/windows_pi.cpp>"
  "$<$<OR:$<PLATFORM_ID:Linux>,$<PLATFORM_ID:Darwin>>:${pi_source_dir}/posix_pi.cpp>"
)
set_target_properties(piapi PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY "${pi_library_output_dir}"
)
list(APPEND CONF_INCLUDE_DIRS "${pi_include_dir}")
list(APPEND CONF_INCLUDE_DIRS "${CMAKE_CURRENT_BINARY_DIR}")
target_include_directories(piapi PUBLIC
  "$<BUILD_INTERFACE:${pi_include_dir}>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
)
target_include_directories(piapi INTERFACE
  "$<INSTALL_INTERFACE:include>"
)
target_link_libraries(piapi PUBLIC ${CMAKE_DL_LIBS})

################################################################################
# Export header

set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)

# Define export header for the plugins
# We don't have the plugins yet, so we rely on a shim shared library
set(pi_export_header "${CMAKE_CURRENT_BINARY_DIR}/piapi_export.h")
add_library(pi_export_library_shim EXCLUDE_FROM_ALL SHARED "${pi_source_dir}/shim.cpp")
include(GenerateExportHeader)
generate_export_header(pi_export_library_shim
  BASE_NAME PIAPI
  EXPORT_MACRO_NAME PIAPI_EXPORT
  EXPORT_FILE_NAME "${pi_export_header}"
  STATIC_DEFINE PIAPI_STATIC
)

################################################################################
# OpenCL

option(PI_OPENCL_HEADERS "Should OpenCL headers be included" ON)
if(PI_OPENCL_HEADERS)
  find_package(OpenCL REQUIRED)
  set(opencl_ext_include_dir "${PROJECT_SOURCE_DIR}/../include")

  # Do not link against the OpenCL::OpenCL library, just need the headers
  list(APPEND CONF_INCLUDE_DIRS "${opencl_ext_include_dir}")
  target_include_directories(piapi PUBLIC
    "$<BUILD_INTERFACE:${opencl_ext_include_dir}>"
    "${OpenCL_INCLUDE_DIR}"
  )

  install(DIRECTORY "${opencl_ext_include_dir}"
    DESTINATION . COMPONENT pi_opencl_ext_headers
    FILES_MATCHING
      PATTERN "cl_usm_ext.h"
      PATTERN "__spirv" EXCLUDE
      PATTERN "sycl" EXCLUDE
  )
endif()

################################################################################
# Install

# Export the package for use from the build-tree
export(PACKAGE piapi)

install(DIRECTORY "${pi_include_dir}"
  DESTINATION . COMPONENT piapi
)
install(TARGETS piapi
  EXPORT piapiTargets
  ARCHIVE DESTINATION "lib" COMPONENT piapi
  RUNTIME DESTINATION "bin" COMPONENT piapi
)
export(TARGETS piapi APPEND
  FILE "${PROJECT_BINARY_DIR}/piapiTargets.cmake"
)

################################################################################
# Interface library that simplifies exporting symbols for the plugins

add_library(pi_export_library INTERFACE)
target_include_directories(pi_export_library INTERFACE "${pi_library_output_dir}")
target_compile_definitions(pi_export_library INTERFACE
  pi_export_library_shim_EXPORTS
  PI_REQUIRES_EXPORT
)

################################################################################
# Tests

enable_testing()

################################################################################
# Plugins

add_subdirectory(plugins)

################################################################################
# Package

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/piapiConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY ExactVersion
)

export(EXPORT piapiTargets
  FILE ${CMAKE_CURRENT_BINARY_DIR}/piapiTargets.cmake
  NAMESPACE piapi::
)
configure_file(piapiConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/piapiConfig.cmake
  COPYONLY
)

set(config_package_location lib/cmake/piapi)
install(EXPORT piapiTargets
  FILE piapiTargets.cmake
  NAMESPACE piapi::
  DESTINATION ${config_package_location}
  COMPONENT piapi
)

install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/piapiConfig.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/piapiConfigVersion.cmake
  DESTINATION ${config_package_location}
  COMPONENT piapi
)
