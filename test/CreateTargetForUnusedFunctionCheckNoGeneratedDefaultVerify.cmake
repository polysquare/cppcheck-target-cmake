# /test/CreateTargetForUnusedFunctionCheckNoGeneratedDefaultVerify.cmake
# Verifies that cppcheck is called on our target but only for non-generated
# sources.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_does_not_have_line_matching (${BUILD_OUTPUT}
                                         "^.*cppcheck .*GeneratedSource.*$")