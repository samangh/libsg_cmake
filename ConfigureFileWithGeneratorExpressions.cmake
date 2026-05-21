## In CMake, by default configure_file(..) does not expand generator
## expressions. This function does.
##
function(configure_file_with_generator_expressions FILE_IN FILE_OUT)
  # Configure
  configure_file(${FILE_IN} ${FILE_OUT} ${ARGN})

  # Run teh output file through file(GEERATE ...), this will expand the
  # generator expressions
  file(GENERATE OUTPUT ${FILE_OUT} INPUT ${FILE_OUT})
endfunction()
