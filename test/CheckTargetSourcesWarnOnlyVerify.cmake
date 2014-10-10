# /test/CheckTargetSourcesWarnOnlyVerify.cmake
# Verifies that cppcheck was actually run on the target's source files
# but without an error exitcode of 1.
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_does_not_contain (${BUILD_OUTPUT} "--error-exitcode=1")