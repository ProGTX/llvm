cmake_minimum_required(VERSION 3.4)
project(piapi VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

################################################################################
# Main library

set(pi_include_dir "${CMAKE_SOURCE_DIR}/include")
set(pi_source_dir "${CMAKE_SOURCE_DIR}/src")
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
  set(opencl_ext_include_dir "${CMAKE_SOURCE_DIR}/../include")

  # Do not link against the OpenCL::OpenCL library, just need the headers
  list(APPEND CONF_INCLUDE_DIRS "${opencl_ext_include_dir}")
  target_include_directories(piapi PUBLIC
    "$<BUILD_INTERFACE:${opencl_ext_include_dir}>"
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

################################################################################
# Install

install(DIRECTORY "${pi_include_dir}"
  DESTINATION . COMPONENT headers
  FILES_MATCHING
    PATTERN "*.h"
    PATTERN "*.hpp"
    PATTERN "*.def" EXCLUDE
)
install(TARGETS piapi
  EXPORT piapiTargets
  ARCHIVE DESTINATION "lib" COMPONENT piapi
  RUNTIME DESTINATION "bin" COMPONENT piapi
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

export(PACKAGE piapi)

if(WIN32 AND NOT CYGWIN)
  set(INSTALL_CMAKE_DIR CMake)
else()
  set(INSTALL_CMAKE_DIR lib/CMake/piapi)
endif()
# Add all targets to the build-tree export set
export(TARGETS
    piapi
    pi_opencl
    pi_cuda
  FILE "${PROJECT_BINARY_DIR}/piapiTargets.cmake")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE piapi)

# Create piapiConfig.cmake
# ... for the build tree
set(configuration_include_dirs "${PROJECT_SOURCE_DIR}" "${PROJECT_BINARY_DIR}")
configure_file(piapiConfig.cmake.in
  "${PROJECT_BINARY_DIR}/piapiConfig.cmake" @ONLY)
# ... for the install tree
set(configuration_include_dirs "\${FOOBAR_CMAKE_DIR}/include")
configure_file(piapiConfig.cmake.in
  "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/piapiConfig.cmake" @ONLY)

# Install piapiConfig.cmake
install(FILES
  "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/piapiConfig.cmake"
  DESTINATION "${INSTALL_CMAKE_DIR}" COMPONENT dev)

# Install the export set for use with the install-tree
install(EXPORT piapiTargets DESTINATION
  "${INSTALL_CMAKE_DIR}" COMPONENT dev)
