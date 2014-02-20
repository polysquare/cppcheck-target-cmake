# /test/CreateTargetForGlobalUnusedFunctionCheckGeneratedVerify.cmake
# Verifies that cppcheck was called for our nominated sources
# and generated sources on the custom target.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck .*FirstSource.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck .*GeneratedSource.*$")