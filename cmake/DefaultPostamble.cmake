include(GetAllTargets)
#include(DoesTargetUseLinker)

if(PROJECT_IS_TOP_LEVEL)
  get_property(LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

  message(STATUS "Global default flags:")
  foreach(LANG ${LANGUAGES})
    message(STATUS "  ${LANG}:")
    message(STATUS "          Compiler: ${CMAKE_${LANG}_COMPILER_ID} ${CMAKE_${LANG}_COMPILER_VERSION} (${CMAKE_${LANG}_COMPILER})")
    message(STATUS "          Standard: ${CMAKE_${LANG}_STANDARD_DEFAULT}")
    message(STATUS "           Release: ${CMAKE_${LANG}_FLAGS} ${CMAKE_${LANG}_FLAGS_RELEASE}")
    message(STATUS "    RelWithDebInfo: ${CMAKE_${LANG}_FLAGS} ${CMAKE_${LANG}_FLAGS_RELWITHDEBINFO}")
    message(STATUS "             Debug: ${CMAKE_${LANG}_FLAGS} ${CMAKE_${LANG}_FLAGS_DEBUG}")
  endforeach()

  get_all_targets(TARGETS)
  set(PARAMETER_FILES)
  foreach(TARGET ${TARGETS})
    set(OUTPUT "Target ${TARGET}\n")
    string(APPEND OUTPUT "        Language Standard: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},$<COMPILE_LANGUAGE>_STANDARD>>\n")
    string(APPEND OUTPUT "         Compile features: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},COMPILE_FEATURES>>\n")
    string(APPEND OUTPUT "          Compile options: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},COMPILE_OPTIONS>>\n")
    string(APPEND OUTPUT "      Compile definitions: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>>\n")
    string(APPEND OUTPUT "             Link options: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},LINK_OPTIONS>>\n")
    string(APPEND OUTPUT "           Link libraries: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},LINK_LIBRARIES>>\n")
    string(APPEND OUTPUT " Link interface libraries: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},LINK_INTERFACE_LIBRARIES>>\n")
    string(APPEND OUTPUT "      Include directories: $<TARGET_GENEX_EVAL:${TARGET},$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>>\n")
    string(APPEND OUTPUT "\n")

    # Note:
    #  - this will run once for every language
    #  - in MSVC this will run once for every config (Debug/Release/etc)

    file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/Parameters_${TARGET}_$<CONFIG>_$<COMPILE_LANGUAGE>.txt" CONTENT "${OUTPUT}" TARGET ${TARGET})
    foreach(LANG ${LANGUAGES})
      list(APPEND PARAMETER_FILES "${CMAKE_BINARY_DIR}/Parameters_${TARGET}_$<CONFIG>_${LANG}.txt")
    endforeach()
  endforeach()

  add_custom_target(print_target_parameters
    COMMAND ${CMAKE_COMMAND} -E cat -- ${PARAMETER_FILES})
endif()
