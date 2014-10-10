# /test/CreateTargetForUnusedFunctionChecWarnOnlyVerify.cmake
# Verifies that cppcheck was called for our nominated sources
# on the custom target, without --error-exitcode=1
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_does_not_contain (${BUILD_OUTPUT} "--error-exitcode=1")