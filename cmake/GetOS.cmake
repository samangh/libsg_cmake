# Note: the MSYS variable provided by CMAKE is difference
if (MSYS OR ${CMAKE_SYSTEM_NAME} MATCHES "MSYS")
  set(MSYS2 TRUE)
endif()
