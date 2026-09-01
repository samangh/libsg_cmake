function(add_sanitizer_suppression TARGET)
  set(options "")
  set(multiValueArgs "")
  set(oneValueArgs SUPPRESSION_FILE SANITIZER)
  cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

  # Get the function nname for setting suppressions
  if("${ARG_SANITIZER}" STREQUAL "ASAN")
    set(SUPPRESSIONS_FUNCTION "__asan_default_suppressions")
  elseif("${ARG_SANITIZER}" STREQUAL "TSAN")
    set(SUPPRESSIONS_FUNCTION "__tsan_default_suppressions")
  elseif("${ARG_SANITIZER}" STREQUAL "LSAN")
    set(SUPPRESSIONS_FUNCTION "__lsan_default_suppressions")
  elseif("${ARG_SANITIZER}" STREQUAL "UBSAN")
    set(SUPPRESSIONS_FUNCTION "__ubsan_default_suppressions")
  elseif("${ARG_SANITIZER}" STREQUAL "NSAN")
    set(SUPPRESSIONS_FUNCTION "__nsan_default_suppressions")
  else()
    message(SEND_ERROR "Sanitizer ${ARG_SANITIZER} not understood")
  endif()

  # Make sure CMake reconfigures if the input file is changed
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${ARG_SUPPRESSION_FILE})

  # Record contents of file into variable
  file(READ ${ARG_SUPPRESSION_FILE} SUPPRESSIONS_TEXT)

  # Create .cp file and add to soures
  set(SUPP_FILE_CPP ${CMAKE_CURRENT_BINARY_DIR}/sanitizer_suppression_${ARG_SANITIZER}.cpp)
  configure_file(
    ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/sanitizer_suppressions.cpp.in
    ${SUPP_FILE_CPP} @ONLY)
  target_sources(${TARGET} PRIVATE ${SUPP_FILE_CPP})
endfunction()
