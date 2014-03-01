# /test/MultipleUnusedFunctionChecksCoexistVerify.cmake
# Verifies that both our checks are run.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*Running unused function check\\: one.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*Running unused function check\\: two.*$")