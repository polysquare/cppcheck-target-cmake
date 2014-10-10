# /test/GetUnusedFunctionChecks.cmake
# Tests getting back a list of unused function checks, even if they
# haven't been activated yet.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

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