message(STATUS "Including the PI API CUDA backend.")

 # cannot rely on cmake support for CUDA; it assumes runtime API is being used.
 # we only require the CUDA driver API to be used
 # CUDA_CUDA_LIBRARY variable defines the path to libcuda.so, the CUDA Driver API library.

find_package(CUDA 10.0 REQUIRED)

add_library(cudadrv SHARED IMPORTED)

set_target_properties(
  cudadrv PROPERTIES 
    IMPORTED_LOCATION             ${CUDA_CUDA_LIBRARY}
    INTERFACE_INCLUDE_DIRECTORIES ${CUDA_INCLUDE_DIRS}
)

add_library(pi_cuda SHARED
  "${pi_include_dir}/pi/pi.h"
  "${pi_include_dir}/pi/pi.hpp"
  "pi_cuda.hpp"
  "pi_cuda.cpp"
)
set_target_properties(pi_cuda PROPERTIES
  ARCHIVE_OUTPUT_DIRECTORY "${pi_library_output_dir}"
  LIBRARY_OUTPUT_DIRECTORY "${pi_library_output_dir}"
  RUNTIME_OUTPUT_DIRECTORY "${pi_binary_output_dir}"
)

target_link_libraries(pi_cuda PUBLIC piapi cudadrv)
target_link_libraries(pi_cuda PRIVATE pi_export_library)

target_include_directories(pi_cuda PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

target_include_directories(pi_cuda PUBLIC ${CUDA_INCLUDE_DIRS})

install(TARGETS pi_cuda
  LIBRARY DESTINATION "lib${LLVM_LIBDIR_SUFFIX}" COMPONENT pi_cuda
  RUNTIME DESTINATION "bin" COMPONENT pi_cuda
)
install(FILES "pi_cuda.hpp" DESTINATION include/pi COMPONENT headers)
