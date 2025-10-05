# Set this to OFF to build static libraries
option (BUILD_SHARED_LIBS "Build shared libraries" ON)

if (BUILD_SHARED_LIBS)
  set(USE_STATIC_LIBS_DEFAULT OFF)
else()
  set(USE_STATIC_LIBS_DEFAULT ON)
endif()
option (USE_STATIC_LIBS "Use external static libs if possible" ${USE_STATIC_LIBS_DEFAULT})

if(MSVC)
  option (USE_STATIC_RUNTIME "Statically link against the C++ runtime" USE_STATIC_LIBS)
endif()

option (IPO "Enable inter-process and link-time optimisation" OFF)
option (ARCH_NATIVE "Optimise code for current architecture" OFF)
option (USE_SSE "Enable global use of SSE if possible" ARCH_NATIVE)

# By default, install headers. Note that you can always choose the component wih `--component` flag
option (INSTALL_${PROJECT_NAME}_HEADERS "Install project headers as part of cmake install" ${PROJECT_IS_TOP_LEVEL})
option (INSTALL_${PROJECT_NAME}_BINARIES "Install project binaries as part of cmake install" ${PROJECT_IS_TOP_LEVEL})
option(INSTALL_ALL_HEADERS "Install headers of all targets" OFF)
option(INSTALL_ALL_BINARIES "Install binaries of all targets" OFF)


option (SANITIZE "Enable address, eak and undefined Behaviour sanitizers" OFF)
# Note, the sanitizer also provides SANITIZE_THREAD and SANITIZE_MEMORY options

option (USE_LIBC++ "Use clang libc++" OFF)

# Commonly used packages
option(OWN_UV "Use our own copy of libuv" OFF)
option(OWN_FMT "Use own libfmt" OFF)

option(BUILD_DOCS "Generator documentation" OFF)

##
## Includes and module paths
##

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../external/sanitizers-cmake/cmake")

# Load all custom functions
include(GetOS)
include(SetSpaceSeparatedString)
include(ConfigureFileWithGeneratorExpressions)
##
## libc++
##

if(USE_LIBC++)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(SEND_ERROR "option USE_LIBC++ is only possible with clang" )
  endif()

  # Set default, note we can't just set by using target-specific compile options
  # becausethe get_standard_library_name() doesn't use them
  #
  # We also use target_link_options() etc in SetupTargets() to make sure
  # all targets and their depdencies use libc++
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++")
endif()

##
## Static linking (Windows)
##

# Allows for setting MSVC static runtime
if(USE_STATIC_RUNTIME)
  # Enable policy for subprojects that are using an old cmake_minimum_version
  set(CMAKE_POLICY_DEFAULT_CMP0091 NEW)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

if(USE_STATIC_LIBS)
  include(prioritise_static_libraries)
  prioritise_static_libraries()
endif()

##
## Enable link-time optimisation for all targets
##

if(IPO)
  # Enable policy for subprojects that are using an old cmake_minimum_version
  set(CMAKE_POLICY_DEFAULT_CMP0069 NEW)

  include(CheckIPOSupported)
  check_ipo_supported(RESULT IPO_SUPPORTED)
  if (IPO_SUPPORTED)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
  endif()
endif()

##
## CPU Architecture
##

include(GetProcessor)
get_processor(CPU_ARCH)

if(CPU_ARCH STREQUAL "X86")
  set(X86 TRUE)
elseif(CPU_ARCH STREQUAL "ARM")
  set(ARM TRUE)
endif()

message(STATUS "Detected CPU architecture: ${CPU_ARCH} (${CMAKE_SYSTEM_PROCESSOR})")

##
## SSE architecture
##

include(EnableSSE)

# But we only consider this only once (at this scope level), so that duplicated flags
# are not added for any libraries or projects that we add at this level
# or below

macro(_use_sse)
  if(X86)
      enable_sse(SSE42 REQUIRED)
      enable_sse(AVX2 REQUIRED)
      enable_sse(CLMUL) #Only supported on 64-bit systems
  elseif(ARM)
    enable_sse(ARM_CRC)
    enable_sse(ARM_SHA3) #supported mostly on Apple M1
  endif()
endmacro()

if(NOT SSE_OR_NATIVE_SET)
  if(MSVC)
    if(USE_SSE OR ARCH_NATIVE)
      _use_sse()
    endif()
  else()
    if(ARCH_NATIVE)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=native")
    elseif(USE_SSE)
      _use_sse()
    endif()
  endif()
  set(SSE_OR_NATIVE_SET)
endif()

## If running on Apple Silicon, enable some features. We can't tranfer
## compiled files to non-Apple Silicon systems anyway.
if(ARM AND DARWIN AND NOT SSE_OR_NATIVE_SET)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8.2-a+crypto+sha3")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv8.2-a+crypto+sha3")
endif()

## Enable the CPU_SUPPORTS_xxx flags. this is useful if the SSE package
## is not loaded, but the arch or features is manually set but the
## user. For example, if they do CMAKE_CXX_FLGS="-march=haswell", OR they
## have enable ARCH_NATIVE, etc.
check_parent_sse_features()

##
## IDE support
##

# Export compile database for IDEs, needed for QtCreator
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)


##
## Global properties
##

# Disable additional targets from being created when using CTest
set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)

##
## Import functions
##

include(setup_ide_folders)
include(get_standard_library_name)
include(SetupTarget)

# Check for name of standard library, use by common
include(CheckCXXSourceCompiles)
get_standard_library_name(STANDARD_LIBRARY)

# CPM
include(get_cpm)

##
## Install path
##
include(GNUInstallDirs)

# Place libraries in same location as executables in Windows
if(WIN32 OR MSYS2)
  set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_BINDIR})
endif()

# Set RPATH for all targets (even ones imported via CPM)
#
# You can do this via proprty INSTALL_RPATH, but that would only apply
# to specific targets
if(NOT CMAKE_INSTALL_RPATH)
  if(APPLE)
    set(CMAKE_INSTALL_RPATH "@loader_path;@loader_path/../lib")
  elseif(UNIX)
    set(CMAKE_INSTALL_RPATH "\$ORIGIN;\$ORIGIN/../lib")
  endif()
endif()

##
## Documentation
##

if(BUILD_DOCS)
  find_package(Doxygen)

  ## Use default file pattern
  set(DOXYGEN_FILE_PATTERNS "")
  set(DOXYGEN_RECURSIVE "YES")

  # set(DOXYGEN_CLANG_DATABASE_PATH ${CMAKE_BINARY_DIR})
  # set(DOXYGEN_CLANG_ASSISTED_PARSING "YES")

  # Import default CMake Doxygen settings
  include(${PROJECT_BINARY_DIR}/CMakeDoxygenDefaults.cmake)
endif()

##
## Packages
##

# System threading library
find_package(Threads REQUIRED)

# Setup boost variables, in case any of our projects use it
include(setup_boost)
find_package(Sanitizers REQUIRED)

# Enable default SANitizer options
if(SANITIZE)
  set(SANITIZE_ADDRESS ON)
  set(SANITIZE_UNDEFINED ON)
endif()

if(OWN_FMT)
CPMAddPackage(NAME fmt
  GITHUB_REPOSITORY fmtlib/fmt
  GIT_TAG 11.1.4
  GIT_SHALLOW
  OPTIONS
  "BUILD_TESTING OFF"
  "FMT_INSTALL OFF"
)
endif()

if(OWN_UV)
CPMAddPackage(NAME libuv
  GITHUB_REPOSITORY libuv/libuv
  VERSION 1.50.0
  GIT_SHALLOW
  OPTIONS
    "BUILD_TESTING OFF")
endif()


##
## Global project version
##

string(TOLOWER ${NAMESPACE} NAMESPACE_LOWER)
string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LOWER)

configure_file (
  "${CMAKE_CURRENT_LIST_DIR}/version.h.in"
  "${CMAKE_BINARY_DIR}/include/${NAMESPACE_LOWER}/export/${PROJECT_NAME_LOWER}_version.h"
)

install(
  FILES "${CMAKE_BINARY_DIR}/include/${NAMESPACE_LOWER}/export/${PROJECT_NAME_LOWER}_version.h"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${NAMESPACE_LOWER}/export/"
  COMPONENT dev
)
