
add_executable(test_pi_plugins EXCLUDE_FROM_ALL
  "test.cpp"
)
target_link_libraries(test_pi_plugins PRIVATE
  piapi
)
add_test(NAME pi_plugins COMMAND test_pi_plugins)
if(WIN32)
  set_tests_properties(pi_plugins PROPERTIES
    ENVIRONMENT "PATH=${pi_binary_output_dir}/$<$<BOOL:${CMAKE_CONFIGURATION_TYPES}>:$<CONFIG>>;$ENV{PATH}"
  )
else()
  set_tests_properties(pi_plugins PROPERTIES
    ENVIRONMENT "LD_LIBRARY_PATH=${pi_library_output_dir}/$<$<BOOL:${CMAKE_CONFIGURATION_TYPES}>:$<CONFIG>>:$ENV{LD_LIBRARY_PATH}"
  )
endif()

if(SYCL_BUILD_PI_CUDA)
 add_subdirectory(cuda)
 add_dependencies(test_pi_plugins pi_cuda)
endif()

add_subdirectory(opencl)
add_dependencies(test_pi_plugins pi_opencl)
