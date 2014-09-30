# /test/CreateTargetForUnusedFunctionCheckDefinitionsVerify.cmake
# Verifies that cppcheck was called for our nominated sources
# on the custom target, along with --enable=unusedFunction and
# our custom definition.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (RELATIVE_REAL_SOURCE_DIR
     ${CMAKE_CURRENT_SOURCE_DIR}/../)
get_filename_component (REAL_SOURCE_DIR
                        ${RELATIVE_REAL_SOURCE_DIR}
                        ABSOLUTE)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (CPPCHECK_COMMAND_LOCAL
     "^.*cppcheck.*unusedFunction.*-DDEFINITION_SUCCESS=1.*$")
set (CPPCHECK_COMMAND_GLOBAL
     "^.*cppcheck.*unusedFunction.*-DGLOBAL_DEFINITION=1.*$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${CPPCHECK_COMMAND_LOCAL})
assert_file_has_line_matching (${BUILD_OUTPUT} ${CPPCHECK_COMMAND_GLOBAL})