# Adds STRING to variable VAR, if it doesn't contain it already
#
# Useful for additiong paramets to CMAKE_CXX_FLAGS, etc
function(add_to_var VAR STRING)
  if(DEFINED ${VAR})
    if(NOT "${${VAR}}" MATCHES ".*${STRING}.*")
      set(${VAR} "${${VAR}} ${STRING}" PARENT_SCOPE)
    endif()
  else()
    set(${VAR} ${STRING} PARENT_SCOPE)
  endif()
endfunction()
