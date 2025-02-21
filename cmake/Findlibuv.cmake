#[=======================================================================[.rst:
FindLibUV
---------

Find libuv includes and library.

Imported Targets
^^^^^^^^^^^^^^^^

An :ref:`imported target <Imported targets>` named
``libuv::libuv`` is provided if libuv has been found.

Result Variables
^^^^^^^^^^^^^^^^

This module defines the following variables:

``libuv_FOUND``
  True if libuv was found, false otherwise.
``libuv_INCLUDE_DIRS``
  Include directories needed to include libuv headers.
``libuv_LIBRARIES``
  Libraries needed to link to libuv.
``libuv_VERSION``
  The version of libuv found.
``libuv_VERSION_MAJOR``
  The major version of libuv.
``libuv_VERSION_MINOR``
  The minor version of libuv.
``libuv_VERSION_PATCH``
  The patch version of libuv.

Cache Variables
^^^^^^^^^^^^^^^

This module uses the following cache variables:

``libuv_LIBRARY``
  The location of the libuv library file.
``libuv_INCLUDE_DIR``
  The location of the libuv include directory containing ``uv.h``.

The cache variables should not be used by project code.
They may be set by end users to point at libuv components.
#]=======================================================================]

#=============================================================================
# Copyright 2014-2016 Kitware, Inc.
# Modifed by S. Ghannadzadeh 2021

# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.

# Modified by S. Ghannadzadeh to:
# - prefer static version of libuv if USE_STATIC_LIBS is set
# - use LIBUV_DIR as well as libuv_DIR for hints

if (USE_STATIC_LIBS)
  find_library(libuv_LIBRARY NAMES uv_a uv libuv HINTS ${libuv_DIR} ${libuv_DIR}/lib ${LIBUV_DIR} ${LIBUV_DIR}/lib)
else()
  find_library(libuv_LIBRARY NAMES uv uv_a libuv HINTS ${libuv_DIR} ${libuv_DIR}/lib ${LIBUV_DIR} ${LIBUV_DIR}/lib)
endif()
mark_as_advanced(libuv_LIBRARY)

find_path(libuv_INCLUDE_DIR NAMES uv.h HINTS ${libuv_DIR}/include ${LIBUV_DIR}/include)
mark_as_advanced(libuv_INCLUDE_DIR)

if(WIN32)
  set(libuv_LIBRARIES_WIN
    psapi
    user32
    advapi32
    iphlpapi
    userenv
    ws2_32
    dbghelp
    ole32
    uuid)
endif()

#-----------------------------------------------------------------------------
# Extract version number if possible.
set(_libuv_H_REGEX "#[ \t]*define[ \t]+UV_VERSION_(MAJOR|MINOR|PATCH)[ \t]+[0-9]+")
if(libuv_INCLUDE_DIR AND EXISTS "${libuv_INCLUDE_DIR}/uv-version.h")
  file(STRINGS "${libuv_INCLUDE_DIR}/uv/version.h" _libuv_H REGEX "${_libuv_H_REGEX}")
elseif(libuv_INCLUDE_DIR AND EXISTS "${libuv_INCLUDE_DIR}/uv.h")
  file(STRINGS "${libuv_INCLUDE_DIR}/uv.h" _libuv_H REGEX "${_libuv_H_REGEX}")
else()
  set(_libuv_H "")
endif()
foreach(c MAJOR MINOR PATCH)
  if(_libuv_H MATCHES "#[ \t]*define[ \t]+UV_VERSION_${c}[ \t]+([0-9]+)")
    set(_libuv_VERSION_${c} "${CMAKE_MATCH_1}")
  else()
    unset(_libuv_VERSION_${c})
  endif()
endforeach()
if(DEFINED _libuv_VERSION_MAJOR AND DEFINED _libuv_VERSION_MINOR)
  set(libuv_VERSION_MAJOR "${_libuv_VERSION_MAJOR}")
  set(libuv_VERSION_MINOR "${_libuv_VERSION_MINOR}")
  set(libuv_VERSION "${libuv_VERSION_MAJOR}.${libuv_VERSION_MINOR}")
  if(DEFINED _libuv_VERSION_PATCH)
    set(libuv_VERSION_PATCH "${_libuv_VERSION_PATCH}")
    set(libuv_VERSION "${libuv_VERSION}.${libuv_VERSION_PATCH}")
  else()
    unset(libuv_VERSION_PATCH)
  endif()
else()
  set(libuv_VERSION_MAJOR "")
  set(libuv_VERSION_MINOR "")
  set(libuv_VERSION_PATCH "")
  set(libuv_VERSION "")
endif()
unset(_libuv_VERSION_MAJOR)
unset(_libuv_VERSION_MINOR)
unset(_libuv_VERSION_PATCH)
unset(_libuv_H_REGEX)
unset(_libuv_H)

#-----------------------------------------------------------------------------
include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(libuv
  REQUIRED_VARS libuv_LIBRARY libuv_INCLUDE_DIR
  VERSION_VAR libuv_VERSION
    FAIL_MESSAGE
    "Could NOT find libuv, try to set the path to libuv root folder in libuv_DIR")
set(LIBUV_FOUND ${libuv_FOUND})

#-----------------------------------------------------------------------------
# Provide documented result variables and targets.
if(libuv_FOUND)
  set(libuv_INCLUDE_DIRS ${libuv_INCLUDE_DIR})
  set(libuv_LIBRARIES ${libuv_LIBRARY})
  if(NOT TARGET libuv::libuv)
    add_library(libuv::libuv UNKNOWN IMPORTED)
    set_target_properties(libuv::libuv PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "C"
      IMPORTED_LOCATION "${libuv_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${libuv_INCLUDE_DIRS}"
      INTERFACE_LINK_LIBRARIES "${libuv_LIBRARIES_WIN}")
  endif()
endif()
