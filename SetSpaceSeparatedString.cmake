## Converts the provided arguemnts to a space-separated string. This is
## useful when you have a set of CMAKE semicolon strings and you want to convert them.
##
## Example:
##   `set_space_separated_string(MY_STRING ONE TWO THREE)`
## sets MY_STRING to "ONE TWO THREE"
##
function(set_space_separated_string RETURN_VARIABLE_NAME)
  string(REPLACE ";" " " OUTPUT "${ARGN}")
  set(${RETURN_VARIABLE_NAME} "${OUTPUT}" PARENT_SCOPE)
endfunction()
