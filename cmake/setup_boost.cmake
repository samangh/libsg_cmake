# Always include this before find_package(Boost ...)

# Use boost statially if making a static library
if(NOT BUILD_SHARED_LIBS)
  set(Boost_USE_STATIC_LIBS ON)
endif()

if (USE_STATIC_RUNTIME)
  set(Boost_USE_STATIC_RUNTIME ON)
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

