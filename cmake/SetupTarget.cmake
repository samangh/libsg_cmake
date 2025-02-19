function(setup_target)
  set(options
    LIBRARY
    EXECUTABLE
    INSTALL_HEADERS
    INSTALL_BINARIES
    DONT_RECURSE_SRC_DIR
    GENERATE_EXPORT_HEADER   #Libraries only
    STATIC                   #Libraries only
  )
  set(multiValueArgs
    SRC_FILES
    ADDITTIONAl_SRC_FILES
    INCLUDE_INTERFACE
    INCLUDE_PUBLIC
    INCLUDE_PRIVATE
    LINK_INTERFACE
    LINK_PUBLIC
    LINK_PRIVATE
    COMPILE_OPTIONS_INTERFACE
    COMPILE_OPTIONS_PUBLIC
    COMPILE_OPTIONS_PRIVATE
    COMPILE_FEATURES_INTERFACE
    COMPILE_FEATURES_PUBLIC
    COMPILE_FEATURES_PRIVATE
    COMPILE_DEFINITIONS_INTERFACE
    COMPILE_DEFINITIONS_PUBLIC
    COMPILE_DEFINITIONS_PRIVATE
    LINK_OPTIONS_INTERFACE
    LINK_OPTIONS_PUBLIC
    LINK_OPTIONS_PRIVATE
  )
  set(oneValueArgs TARGET NAMESPACE NAMESPACE_TARGET DIRECTORY)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  ##
  ## Check for required parameters
  ##
  foreach(item TARGET NAMESPACE DIRECTORY)
    if(NOT ARG_${item})
      message(FATAL_ERROR "parameter '${item}' not set for target ${ARG_TARGET}")
    endif()
  endforeach()

  if(NOT ARG_LIBRARY AND NOT ARG_EXECUTABLE)
    message("Need to either LIBRARY or EXECUTABLE for target ${ARG_TARGET}")
  endif()

  if(ARG_LIBRARY AND ARG_EXECUTABLE)
    message("${ARG_TARGET} can't be both LIBRARY and EXECUTABLE")
  endif()

  ##
  ## Source files
  ##
  if(ARG_SRC_FILES OR ARG_DONT_RECURSE_SRC_DIR)
    message("target ${ARG_TARGET}: not recursively searching for source files, remember to include them manually")
  else()
    file(GLOB_RECURSE ARG_SRC_FILES
      ${ARG_DIRECTORY}/src/*.c
      ${ARG_DIRECTORY}/src/*.cc
      ${ARG_DIRECTORY}/src/*.cpp)
  endif()

  if(ARG_ADDITTIONAl_SRC_FILES)
    list(APPEND SRC_FILES ${ARG_ADDITTIONAl_SRC_FILES})
  endif()

  ##
  ## Namespace bookkeeping
  ##
  if(NOT ARG_NAMESPACE_TARGET)
      set(ARG_NAMESPACE_TARGET ${ARG_TARGET})
  endif()

  string(TOLOWER ${ARG_TARGET} TARGET_LOWER)
  string(TOLOWER ${ARG_NAMESPACE_TARGET} NAMESPACE_TARGET_LOWER)
  string(TOLOWER ${ARG_NAMESPACE} NAMESPACE_LOWER)

  # Copy headers if other flags are set
  if(INSTALL_ALL_HEADERS
     OR INSTALL_${PROJECT_NAME}_HEADERS
     OR INSTALL_${ARG_NAMESPACE}_HEADERS
     OR INSTALL_${ARG_NAMESPACE}_${ARG_NAMESPACE_TARGET}_HEADERS
     OR INSTALL_${ARG_TARGET}_HEADERS)
     set(ARG_INSTALL_HEADERS TRUE)
   endif()

  if(INSTALL_ALL_BINARIES
     OR INSTALL_${PROJECT_NAME}_BINARIES
     OR INSTALL_${ARG_NAMESPACE}_BINARIES
     OR INSTALL_${ARG_NAMESPACE}_${ARG_NAMESPACE_TARGET}_BINARIES
     OR INSTALL_${ARG_TARGET}_BINARIES)
     set(ARG_INSTALL_BINARIES TRUE)
  endif()
  ########################################################
  ## Library
  ########################################################
  if(ARG_LIBRARY)
    if(ARG_STATIC)
      add_library(${ARG_TARGET} STATIC ${ARG_SRC_FILES})
    else()
      add_library(${ARG_TARGET} ${ARG_SRC_FILES})
    endif()
    add_library(${ARG_NAMESPACE}::${ARG_NAMESPACE_TARGET} ALIAS ${ARG_TARGET})

    ##
    ## Export headers
    ##
    if(ARG_GENERATE_EXPORT_HEADER)
      include(GenerateExportHeader)
      generate_export_header(${ARG_TARGET}
        EXPORT_FILE_NAME "${CMAKE_BINARY_DIR}/include/${NAMESPACE_LOWER}/export/${NAMESPACE_TARGET_LOWER}.h")
    endif()
  endif()

  ########################################################
  ## Executable
  ########################################################
  if(ARG_EXECUTABLE)
    add_executable(${ARG_TARGET} ${ARG_SRC_FILES})
    add_executable(${ARG_NAMESPACE}::${ARG_NAMESPACE_TARGET} ALIAS ${ARG_TARGET})
  endif()
  ########################################################

  # Record target name
  set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_TARGETS ${ARG_TARGET})

  ##
  ## Headers
  ##
  target_include_directories(${ARG_TARGET}
    INTERFACE
      ${ARG_INCLUDE_INTERFACE}
    PUBLIC
      ${ARG_INCLUDE_PUBLIC}
      $<INSTALL_INTERFACE:include>
      $<BUILD_INTERFACE:${ARG_DIRECTORY}/include>     # Normal heades
      $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>  #  generate_export_header() files
    PRIVATE
      ${ARG_INCLUDE_PRIVATE}
  )

  ##
  ## Add link libraries and compiler flags
  ##
  target_link_libraries(${ARG_TARGET}
    INTERFACE
      ${ARG_LINK_INTERFACE}
    PUBLIC
      ${ARG_LINK_PUBLIC}
      $<$<AND:$<CXX_COMPILER_ID:GNU>,$<VERSION_LESS:$<CXX_COMPILER_VERSION>,9.1>>:${STANDARD_LIBRARY}fs>
      $<$<AND:$<CXX_COMPILER_ID:Clang>,$<VERSION_LESS:$<CXX_COMPILER_VERSION>,9.0>>:${STANDARD_LIBRARY}fs>
    PRIVATE
      ${ARG_LINK_PRIVATE}
      # Enable SSE if
      $<$<AND:$<BOOL:${USE_SSE}>,$<BOOL:${SSE_SSE42_FOUND}>>:SSE::SSE42>
      $<$<AND:$<BOOL:${USE_SSE}>,$<BOOL:${SSE_AVX2_FOUND}>>:SSE::AVX2>)

  ##
  ## Compiler features/options
  ##
  target_compile_features(${ARG_TARGET}
    INTERFACE
      ${ARG_COMPILE_FEATURES_INTERFACE}
    PUBLIC
      ${ARG_COMPILE_FEATURES_PUBLIC}
    PRIVATE
      ${ARG_COMPILE_FEATURES_PRIVATE}
  )

  target_compile_definitions(${ARG_TARGET}
    INTERFACE
      ${ARG_COMPILE_DEFINITIONS_INTERFACE}
    PUBLIC
      ${ARG_COMPILE_DEFINITIONS_PUBLIC}
    PRIVATE
      ${ARG_COMPILE_DEFINITIONS_PRIVATE}
  )

  target_compile_options(${ARG_TARGET}
    INTERFACE
      ${ARG_COMPILE_OPTIONS_INTERFACE}
    PUBLIC
      ${ARG_COMPILE_OPTIONS_PUBLIC}
    PRIVATE
      ${ARG_COMPILE_OPTIONS_PRIVATE}
      #Warnings
      $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra>
      $<$<CXX_COMPILER_ID:MSVC>:/permissive->

      # Set arch to native (i.e. use all processor flags)
      $<$<AND:$<BOOL:${ARCH_NATIVE}>,$<NOT:$<CXX_COMPILER_ID:MSVC>>>:-march=native>

      # Enable __cpluscplus header in MSVC for getting C++ version
      $<$<CXX_COMPILER_ID:MSVC>:/Zc:__cplusplus>)

  ##
  ## Link options
  ##
  target_link_options(${ARG_TARGET}
    INTERFACE
      ${ARG_LINK_OPTIONS_INTERFACE}
    PUBLIC
      ${ARG_LINK_OPTIONS_PUBLIC}
    PRIVATE
      ${ARG_LINK_OPTIONS_PRIVATE}
  )

  ##
  ## Version
  ##
  set_target_properties(${TARGET} PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR})

  ##
  ## Sanitizers
  ##
  add_sanitizers(${ARG_TARGET})


  ##
  ## Copy dependencies
  ##

  # On DLL paltforms (e.g. Windows), copy dependent libraries to
  # executable folder. Has no effect on other systems
  #
  # Note: requires Cmake 3.26 or higher
  if (ARG_EXECUTABLE AND CMAKE_VERSION VERSION_GREATER_EQUAL "3.26.0")
    add_custom_command(TARGET ${ARG_TARGET} PRE_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy -t $<TARGET_FILE_DIR:${ARG_TARGET}> $<TARGET_RUNTIME_DLLS:${ARG_TARGET}>
      COMMAND_EXPAND_LISTS)
  endif()

  ##
  ## Install
  ##
  if (ARG_INSTALL_HEADERS)
    install(
      DIRECTORY ${ARG_DIRECTORY}/include/
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
      COMPONENT dev
      FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.hpp")

      if (ARG_GENERATE_EXPORT_HEADER)
        install(
          FILES "${CMAKE_BINARY_DIR}/include/${NAMESPACE_LOWER}/export/${NAMESPACE_TARGET_LOWER}.h"
          DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${NAMESPACE_LOWER}/export/"
          COMPONENT dev)
      endif()
  endif()

  if(ARG_INSTALL_BINARIES)
    install(TARGETS ${ARG_TARGET}
      #EXPORT  ${PROJECT_NAME}Targets
      RUNTIME ARCHIVE FRAMEWORK LIBRARY RUNTIME FRAMEWORK BUNDLE PUBLIC_HEADER RESOURCE)

    # Copy DLL-dependencies if a shared library or excutable on Windows on install
    if(WIN32 OR MSYS)
      get_target_property(TARGET_TYPE ${ARG_TARGET} TYPE)
      foreach(TYPE  "EXECUTABLE" "MODULE_LIBRARY" "SHARED_LIBRARY")
        if (TARGET_TYPE STREQUAL ${TYPE})
          install(FILES $<TARGET_RUNTIME_DLLS:${ARG_TARGET}> TYPE BIN)

          # install(TARGETS ${ARG_TARGET}
          #   COMPONENT ${ARG_TARGET}
          #   RUNTIME_DEPENDENCIES
          #   PRE_EXCLUDE_REGEXES "api-ms-" "ext-ms-"
          #   POST_EXCLUDE_REGEXES ".*system32/.*\\.dll"
          #   DIRECTORIES ${CMAKE_LIBRARY_PATH})
        endif()
      endforeach()
    endif()
  endif()

endfunction()

function(setup_library)
  setup_target(LIBRARY ${ARGN})
endfunction()

function(setup_executable)
  setup_target(EXECUTABLE ${ARGN})
endfunction()
