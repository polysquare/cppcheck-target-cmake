# /test/AddUnusedFunctionCheckWithNameAddsTarget.cmake
# Adds an unused function check and asserts that a target with the name
# of the unused function check is added.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

foreach (PATH ${CMAKE_MODULE_PATH})

    message ("PATH: ${PATH}")

endforeach ()

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
file (WRITE ${SOURCES} "")

cppcheck_add_to_unused_function_check (global
                                       SOURCES ${SOURCES})

# Put CMAKE_CURRENT_SOURCE_DIR in the global INCLUDES
cppcheck_add_unused_function_check_with_name (global)

assert_target_exists (global)