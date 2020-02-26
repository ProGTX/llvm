
add_executable(test_pi_plugins EXCLUDE_FROM_ALL
  "test.cpp"
)
target_link_libraries(test_pi_plugins PRIVATE
  piapi
)
add_test(NAME test_pi_plugins
  COMMAND test_pi_plugins
  WORKING_DIRECTORY "${pi_output_dir}"
)

if(SYCL_BUILD_PI_CUDA)
 add_subdirectory(cuda)
 add_dependencies(test_pi_plugins pi_cuda)
endif()

add_subdirectory(opencl)
add_dependencies(test_pi_plugins pi_opencl)
