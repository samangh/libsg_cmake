##
## Checks that coverage conditions are met, and if so sets the correct paramters
##
function(coverage_init)
  if(NOT (CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?[Cc]lang"))
    message(FATAL_ERROR "Coverage option only compatible with clang")
  endif()

  if(NOT COVERAGE_DIR)
    set(COVERAGE_DIR ${CMAKE_BINARY_DIR}/coverage PARENT_SCOPE)
  endif()
endfunction()


##
## Enables coverage instrumentation for target
##
function(coverage_add_target TARGET)
    target_compile_options(${TARGET} PRIVATE -fprofile-instr-generate -fcoverage-mapping)
    target_link_options(${TARGET} PRIVATE -fprofile-instr-generate -fcoverage-mapping)
endfunction()


##
## Generates coverage report for target, target must be an executable
##
function(coverage_add_exe TARGET)
  set(PROFILE_FILE ${COVERAGE_DIR}/${TARGET}.profraw)
  set(HTML_DIR ${COVERAGE_DIR}/html/${TARGET})

  set(options "")
  set(multiValueArgs
      EXCLUDE # List of folders to excluded, these are regexes (e.g. "*/test/*")
      ARGUMENTS # Arguments to pass to thr executable
  )
  set(oneValueArgs "")
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # Generate exclude list
  foreach(ENTRY ${ARG_EXCLUDE})
    set(EXCLUDE_LIST ${EXCLUDE_LIST} -ignore-filename-regex='${ENTRY}')
  endforeach()

  add_custom_command(
    # The dummy file, which is always mising, forces this command to always run
    OUTPUT ${PROFILE_FILE} ${PROFILE_FILE}_dummy
    COMMAND
      ${CMAKE_COMMAND} -E env LLVM_PROFILE_FILE=${PROFILE_FILE}
      $<TARGET_FILE:${TARGET}> $<$<BOOL:${ARG_ARGUMENTS}>:${ARG_ARGUMENTS}>
    COMMAND
      llvm-profdata merge -sparse -output=${PROFILE_FILE} ${PROFILE_FILE}
    COMMAND
      llvm-cov report $<TARGET_FILE:${TARGET}> -instr-profile=${PROFILE_FILE} ${EXCLUDE_LIST}
    COMMAND
      llvm-cov show $<TARGET_FILE:${TARGET}> -show-line-counts-or-regions -instr-profile=${PROFILE_FILE}
      -format=html -output-dir=${HTML_DIR} ${EXCLUDE_LIST}
    COMMAND
      ${CMAKE_COMMAND} -E echo ""
    COMMAND
      ${CMAKE_COMMAND} -E echo "Coverage profile data for ${TARGET} save to ${PROFILE_FILE}."
    COMMAND
      ${CMAKE_COMMAND} -E echo "Coverage HTML report for ${TARGET} save to ${HTML_DIR}."
    DEPENDS ${TARGET})

  #Create individual target
  add_custom_target(coverage-${TARGET} DEPENDS ${PROFILE_FILE} ${PROFILE_FILE}_dummy)

  # Create top coverage target
  if(NOT TARGET coverage)
    add_custom_target(coverage DEPENDS coverage-${TARGET})
  else()
    add_dependencies(coverage DEPENDS coverage-${TARGET})
  endif()

endfunction()
