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

option (SANITIZE "Enable address, eak and undefined Behaviour sanitizers" OFF)
# Note, the sanitizer also provides SANITIZE_THREAD and SANITIZE_MEMORY options

option (USE_LIBC++ "Use clang libc++" OFF)

# Commonly used packages
option(OWN_UV "Use our own copy of libuv" OFF)
option(OWN_FMT "Use own libfmt" OFF)

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
## SSE architecture
##

# We use CXX_CMAKE_FLAGS here because we would like SSE to be enabled
# for all targets, event ones that are added usign FetchPacakge,
# CPMAddPacakge, etc.
#
# But we onlt consider this only once (at this scope level), so that duplicated flags
# are not added for any libraries or projects that we add at this level
# or below

macro(_use_sse)
  find_package(SSE OPTIONAL_COMPONENTS SSE2 SSE3 SSSE3 SSE41 SSE42 AVX AVX2 AVX512 CLMUL)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SSE_CXX_FLAGS}")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SSE_C_FLAGS}")
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

## Enable the CPU_SUPPORTS_xxx flags. this is useful if the SSE package
## is not loaded, but the arch or features is manually set but the
## user. For example, if they do CMAKE_CXX_FLGS="-march=haswell".
include(CheckSSEFeatures)
check_sse_features()

##
## IDE support
##

# Export compile database for IDEs, needed for QtCreator
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)


##
## CMake module paths
##

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../external/sanitizers-cmake/cmake")

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

##
## Packages
##

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
