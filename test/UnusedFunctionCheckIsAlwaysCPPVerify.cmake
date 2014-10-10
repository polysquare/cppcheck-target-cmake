# /test/UnusedfunctionCheckIsAlwaysCPPVerify.cmake
# Check to make sure that cppcheck was run with --language=c++
# on unused function checks, no matter what the sources are. This is
# because all valid C++ function declarations are also valid C function
# declarations, so we should scan for both.
#
# See LICENCE.md for Copyright Information.

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*unuse.*language=c\\+\\+.*$")
assert_file_does_not_have_line_matching (${BUILD_OUTPUT}
                                         "^.*cppcheck.*unuse.*language=c\\s.*$")
