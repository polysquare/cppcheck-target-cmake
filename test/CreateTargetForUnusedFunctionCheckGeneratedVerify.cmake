# /test/CreateTargetForUnusedFunctionCheckGeneratedVerify.cmake
# Verifies that cppcheck was called for our nominated sources
# and generated sources on the custom target.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck .*FirstSource.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck .*GeneratedSource.*$")