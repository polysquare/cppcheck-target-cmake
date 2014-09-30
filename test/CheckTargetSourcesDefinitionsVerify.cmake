# /test/CheckTargetSourcesIncludesVerify.cmake
# Verifies that cppcheck was actually run on the target's source files
# and specifies its definitions.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*-DDEFINITION_SUCCESS=1.*$")