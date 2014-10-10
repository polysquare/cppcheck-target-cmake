# /test/CheckGeneratedsourcesOnNonBinaryTargetVerify.cmake
# Verifies that cppcheck was run on both the native and generated
# source during the build process.
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*FirstSource\\.cpp.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*GeneratedSource\\.cpp.*$")