# /test/CreateTargetForGlobalUnusedFunctionCheckIncludesVerify.cmake
# Verifies that cppcheck was called for our nominated sources
# on the custom target, along with --enable=unusedFunction and
# all the members in CPPCHECK_COMMON_OPTIONS.
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

assert_file_contains (${BUILD_OUTPUT} "-I${REAL_SOURCE_DIR}")