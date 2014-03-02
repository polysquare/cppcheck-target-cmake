# /test/GetUnusedFunctionChecks.cmake
# Tests getting back a list of unused function checks, even if they
# haven't been activated yet.
#
# See LICENCE.md for Copyright Information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

find_program (CPPCHECK_EXECUTABLE cppcheck)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
file (WRITE ${SOURCES} "")

cppcheck_add_to_unused_function_check (one
                                       SOURCES ${SOURCES})
cppcheck_add_to_unused_function_check (two
                                       SOURCES ${SOURCES})

cppcheck_get_unused_function_checks (UNUSED_CHECKS)

assert_list_contains_value (UNUSED_CHECKS STRING EQUAL "one")
assert_list_contains_value (UNUSED_CHECKS STRING EQUAL "two")