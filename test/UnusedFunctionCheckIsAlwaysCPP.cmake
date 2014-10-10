# /test/UnusedFunctionCheckIsAlwaysCPP.cmake
# Adds a C, CXX and header file to an unused function check.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/CSource.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/CXXSource.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/Header.h)

# The sources actually need to exist for cppcheck to succeed.
foreach (SOURCE ${SOURCES})

    file (WRITE ${SOURCE} "")

endforeach ()

cppcheck_add_to_unused_function_check (global
                                       SOURCES
                                       ${SOURCES})

# Put CMAKE_CURRENT_SOURCE_DIR in the global INCLUDES
cppcheck_add_unused_function_check_with_name (global)
