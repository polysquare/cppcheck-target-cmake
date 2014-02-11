# /test/CreateTargetForGlobalUnusedFunctionCheckWarnOnlyVerify.cmake
# Verifies that cppcheck was called for our nominated sources
# on the custom target, without --error-exitcode=1
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_does_not_contain (${BUILD_OUTPUT} "--error-exitcode=1")