# Always include this before find_package(Boost ...)

# Use boost statially if making a static library
if(NOT BUILD_SHARED_LIBS)
  set(Boost_USE_STATIC_LIBS ON)
endif()

# Boost_USE_STATIC_RUNTIME is effective when using system-supplied Boost headers
# BOOST_RUNTIME_LINK is effective when building boost from scratch
set(Boost_USE_STATIC_RUNTIME ${USE_STATIC_RUNTIME})
if (USE_STATIC_RUNTIME)
  set(BOOST_RUNTIME_LINK "static")
else()
  set(BOOST_RUNTIME_LINK "shared")
endif()

# Disable location/function infromation from Boost ASIO exception messages
if(NOT(LIBSG_EXCEPTION_DETAILS OR LIBSG_STACKTRACE))
  add_compile_definitions(BOOST_ASIO_DISABLE_SOURCE_LOCATION)
  add_compile_definitions(BOOST_ASIO_DISABLE_ERROR_LOCATION)
endif()

# Configure Boost in Windows
if(MSVC)
  # Boost tries to use auto linking (i.e. #pragma lib in headers) to tell
  # the compiler what to link to. This does not work properly on
  # Widnows/MSVC.
  add_compile_definitions(BOOST_ALL_NO_LIB)
endif()

if(OWN_BOOST)
  # Boost CMake options are defined in https://github.com/boostorg/cmake

  if (NOT BOOST_INCLUDE_LIBRARIES)
    message(STATUS "Adding all boost targets. Populate BOOST_INCLUDE_LIBRARIES if you wish limit this (e.g.-DBOOST_INCLUDE_LIBRARIES=container\;asio)")
  endif()

  if(BOOST_SKIP_INSTALL_RULES)
    message(STATUS "Boost headers will not be included in install targets. To change this, set BOOST_SKIP_INSTALL_RULES to OFF")
  endif()

  CPMAddPackage(
    NAME Boost
    VERSION 1.91.0 # Versions less than 1.85.0 may need patches for installation targets.
    URL https://github.com/boostorg/boost/releases/download/boost-1.91.0-1/boost-1.91.0-1-cmake.tar.xz
    URL_HASH SHA256=cc5dc5006ecbdf0051f90979be31b4eee5987d9ae14ae9fb9c03cfa43fa3cdad
    OPTIONS
    "BOOST_ENABLE_CMAKE ON"       # Enable CMake support in boost
    "BUILD_TESTING OFF"
    # Compatibility targets for use add_subdirectory/FetchContent (enables Boost::boost / Boost:headers)
    "BOOST_ENABLE_COMPATIBILITY_TARGETS ON"

    # By default, build all targets
    # "BOOST_INCLUDE_LIBRARIES container\\\;asio" # Note the escapes!
  )
endif()

