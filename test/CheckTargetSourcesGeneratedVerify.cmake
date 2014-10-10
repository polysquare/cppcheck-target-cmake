# /test/CheckTargetSourcesGeneratedVerify.cmake
# Verifies that cppcheck was actually run on the target's native and generated
# source files.
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck .*FirstSource.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck .*GeneratedSource.*$")