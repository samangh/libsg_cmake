# Note: the MSYS variable provided by CMAKE is difference
if (${CMAKE_SYSTEM_NAME} MATCHES "MSYS")
    set(MSYS2 TRUE)
endif()
