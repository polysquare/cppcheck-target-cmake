# /test/CheckTargetSourcesNoCheckStleVerify.cmake
# Verifies that cppcheck was actually run on the target's source files
# but without any style checks
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_does_not_contain (${BUILD_OUTPUT} "--enable=style")