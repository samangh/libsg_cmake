# Copyright 2014-2016 Kitware, Inc.
# Modifed by S. Ghannadzadeh 2021

find_package(libpqxx CONFIG)

if(NOT libpqxx_FOUND)
  ## See if we can load use pkg-config
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(libpqxx REQUIRED IMPORTED_TARGET libpqxx)

  add_library(libpqxx::pqxx ALIAS PkgConfig::libpqxx) # Use our library

  # include(FindPackageHandleStandardArgs)
  # find_package_handle_standard_args(libpqxx
  #   REQUIRED_VARS libpqxx_LIBRARIES libpqxx_INCLUDE_DIRS libpqxx_CFLAGS_OTHER
  #   FAIL_MESSAGE
  #   "Could NOT find lipqxx")

  # #-----------------------------------------------------------------------------
  # # Provide documented result variables and targets.
  # if(libpqxx_FOUND)
  #   if(NOT TARGET libpqxx)
  #     add_library(libpqxx UNKNOWN IMPORTED)
  #     set_target_properties(libpqxx PROPERTIES
  #       IMPORTED_LINK_INTERFACE_LANGUAGES "C"
  #       IMPORTED_LOCATION "${libpqxx_LIBRARIES}"
  #       INTERFACE_INCLUDE_DIRECTORIES "${libpqxx_INCLUDE_DIRS}"
  #       INTERFACE_LINK_LIBRARIES "${LibUV_LIBRARIES_WIN}")
  #   endif()
  # endif()

endif()

