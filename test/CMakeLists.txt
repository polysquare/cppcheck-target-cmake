# /tests/CMakeLists.txt
# Main entry point for the common-universal-cmake tests.
#
# See LICENCE.md for Copyright information

if (POLICY CMP0025)

    cmake_policy (SET CMP0025 NEW)

endif (POLICY CMP0025)
project (CMakeCPPCheckTests)
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

add_cmake_test (AddSourcesToUnusedFunctionCheck)
add_cmake_test (AddUnusedFunctionCheckWithNameAddsTarget)
add_cmake_test (AddingDuplicatedUnusedCheckGivesUniqueEntry)
add_cmake_test (GetUnusedFunctionChecks)
add_cmake_build_test (CreateTargetForUnusedFunctionCheck
                      CreateTargetForUnusedFunctionCheckVerify)
add_cmake_build_test (CreateTargetForUnusedFunctionCheckWarnOnly
                      CreateTargetForUnusedFunctionCheckWarnOnlyVerify)
add_cmake_build_test (CreateTargetForUnusedFunctionCheckIncludes
                      CreateTargetForUnusedFunctionCheckIncludesVerify)
add_cmake_build_test (CreateTargetForUnusedFunctionCheckGenerated
                      CreateTargetForUnusedFunctionCheckGeneratedVerify)
add_cmake_build_test (CreateTargetForUnusedFunctionCheckNoGeneratedDefault
                      CreateTargetForUnusedFunctionCheckNoGeneratedDefaultVerify)
add_cmake_build_test (CheckTargetSources
                      CheckTargetSourcesVerify)
add_cmake_build_test (CheckTargetSourcesWarnOnly
                      CheckTargetSourcesWarnOnlyVerify)
add_cmake_build_test (CheckTargetSourcesNoCheckStyle
                      CheckTargetSourcesNoCheckStyleVerify)
add_cmake_build_test (CheckTargetSourcesCheckUnused
                      CheckTargetSourcesCheckUnusedVerify)
add_cmake_build_test (CheckTargetSourcesIncludes
                      CheckTargetSourcesIncludesVerify)
add_cmake_build_test (CheckTargetSourcesGenerated
                      CheckTargetSourcesGeneratedVerify)
add_cmake_build_test (CheckTargetSourcesNoGeneratedDefault
                      CheckTargetSourcesNoGeneratedDefaultVerify)
add_cmake_build_test (StampfileGeneratedForUnusedFunctionCheck
                      StampfileGeneratedForUnusedFunctionCheckVerify)
add_cmake_build_test (MultipleUnusedFunctionChecksCoexist
                      MultipleUnusedFunctionChecksCoexistVerify)
add_cmake_build_test (UnusedFunctionCheckRunForGeneratedSourcesIfStampfileExists
                      UnusedFunctionCheckRunForGeneratedSourcesIfStampfileExistsVerify)

# The ninja generator does dependency scanning at the start of the build
# so we can't fool it into skipping this dependency by generating the
# stampfile during the build.
if (NOT CMAKE_GENERATOR STREQUAL "Ninja")
    add_cmake_build_test (UnusedFunctionCheckNotRunIfStampfileExists
                          UnusedFunctionCheckNotRunIfStampfileExistsVerify)
endif (NOT CMAKE_GENERATOR STREQUAL "Ninja")

add_cmake_build_test (CheckGeneratedSourcesOnNonBinaryTarget
                      CheckGeneratedSourcesOnNonBinaryTargetVerify)
