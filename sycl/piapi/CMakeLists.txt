cmake_minimum_required(VERSION 3.7)
project(piapi VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(pi_include_dir "${CMAKE_SOURCE_DIR}/include")
set(pi_source_dir "${CMAKE_SOURCE_DIR}/src")
set(pi_output_dir "${CMAKE_CURRENT_BINARY_DIR}/lib")

add_library(piapi STATIC
  "${pi_include_dir}/pi/pi.h"
  "${pi_include_dir}/pi/pi.hpp"
  "${pi_source_dir}/pi.cpp"
  "$<$<PLATFORM_ID:Windows>:${pi_source_dir}/windows_pi.cpp>"
  "$<$<OR:$<PLATFORM_ID:Linux>,$<PLATFORM_ID:Darwin>>:${pi_source_dir}/posix_pi.cpp>"
)
set_target_properties(piapi PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY "${pi_output_dir}"
)

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

target_include_directories(piapi PUBLIC "${pi_include_dir}" "${CMAKE_CURRENT_BINARY_DIR}")

target_link_libraries(piapi PUBLIC ${CMAKE_DL_LIBS})

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

# Interface library that simplifies exporting symbols for the plugins
add_library(pi_export_library INTERFACE)
target_include_directories(pi_export_library INTERFACE "${pi_output_dir}")
target_compile_definitions(pi_export_library INTERFACE
  pi_export_library_shim_EXPORTS
  PI_REQUIRES_EXPORT
)

enable_testing()

add_subdirectory(plugins)
