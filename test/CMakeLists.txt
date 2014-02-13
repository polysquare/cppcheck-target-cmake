# /tests/CMakeLists.txt
# Main entry point for the common-universal-cmake tests.
#
# See LICENCE.md for Copyright information

cmake_minimum_required (VERSION 2.8)

# We assume that it is one-above us
set (CPPCHECK_RELATIVE_CMAKE_DIRECTORY
     ${CMAKE_CURRENT_SOURCE_DIR}/..)
get_filename_component (CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY
                        ${CPPCHECK_RELATIVE_CMAKE_DIRECTORY}
                        ABSOLUTE)
set (CMAKE_UNIT_DIRECTORY
     ${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/cmake-unit)

set (CPPCHECK_INITIAL_CACHE_CONTENTS
     "set (CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY\n"
     "     ${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}\n"
     "     CACHE STRING \"\" FORCE)\n"
     "set (CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY\n"
     "     ${CMAKE_UNIT_DIRECTORY}\n"
     "     CACHE STRING \"\" FORCE)\n")

set (CMAKE_MODULE_PATH
     ${CMAKE_UNIT_DIRECTORY}
     ${CMAKE_MODULE_PATH})

include (CMakeUnitRunner)

bootstrap_cmake_unit (INITIAL_CACHE_CONTENTS
                      CPPCHECK_INITIAL_CACHE_CONTENTS)

add_cmake_test (AddSourcesToGlobalUnusedFunctionCheck)
add_cmake_build_test (CreateTargetForGlobalUnusedFunctionCheck
                      CreateTargetForGlobalUnusedFunctionCheckVerify)
add_cmake_build_test (CreateTargetForGlobalUnusedFunctionCheckWarnOnly
                      CreateTargetForGlobalUnusedFunctionCheckWarnOnlyVerify)
add_cmake_build_test (CreateTargetForGlobalUnusedFunctionCheckIncludes
                      CreateTargetForGlobalUnusedFunctionCheckIncludesVerify)
add_cmake_build_test (CheckTargetSources
                      CheckTargetSourcesVerify)
add_cmake_build_test (CheckTargetSourcesComment
                      CheckTargetSourcesCommentVerify)
add_cmake_build_test (CheckTargetSourcesWarnOnly
                      CheckTargetSourcesWarnOnlyVerify)
add_cmake_build_test (CheckTargetSourcesNoCheckStyle
                      CheckTargetSourcesNoCheckStyleVerify)
add_cmake_build_test (CheckTargetSourcesCheckUnused
                      CheckTargetSourcesCheckUnusedVerify)
add_cmake_build_test (CheckTargetSourcesIncludes
                      CheckTargetSourcesIncludesVerify)
