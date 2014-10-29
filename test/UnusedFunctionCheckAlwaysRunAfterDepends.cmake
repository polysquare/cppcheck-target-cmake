# /test/UnusedFunctionCheckAlwaysRunAfterDepends.cmake
# Adds an unused function check and a custom target (not added to ALL)
# that it depends on.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/CSource.cpp)

# The sources actually need to exist for cppcheck to succeed.
foreach (SOURCE ${SOURCES})

    file (WRITE ${SOURCE} "")

endforeach ()

add_custom_target (custom_dependency)
cppcheck_add_to_unused_function_check (global
                                       SOURCES ${SOURCES}
                                       DEPENDS custom_dependency)

# Put CMAKE_CURRENT_SOURCE_DIR in the global INCLUDES
cppcheck_add_unused_function_check_with_name (global)
