# /test/MultipleUnusedFunctionChecksCoexistVerify.cmake
# Verifies that both our checks are run.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*enable=unusedFunction.*FirstSource.cpp.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*touch.*one.cppcheck-unused.stamp.*$")

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*enable=unusedFunction.*SecondSource.cpp.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*touch.*two.cppcheck-unused.stamp.*$")