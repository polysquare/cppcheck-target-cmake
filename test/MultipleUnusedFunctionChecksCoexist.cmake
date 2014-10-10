# /test/MultipleUnusedFunctionChecksCoexist.cmake
# Adds multiple unused function checks and checks that both their targets
# are added.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (FIRST_SOURCE_GROUP
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
set (SECOND_SOURCE_GROUP
     ${CMAKE_CURRENT_SOURCE_DIR}/SecondSource.cpp)
file (WRITE ${FIRST_SOURCE_GROUP} "")
file (WRITE ${SECOND_SOURCE_GROUP} "")

cppcheck_add_to_unused_function_check (one
                                       SOURCES ${FIRST_SOURCE_GROUP})
cppcheck_add_to_unused_function_check (two
                                       SOURCES ${SECOND_SOURCE_GROUP})

cppcheck_add_unused_function_check_with_name (one)
cppcheck_add_unused_function_check_with_name (two)

assert_target_exists (one)
assert_target_exists (two)