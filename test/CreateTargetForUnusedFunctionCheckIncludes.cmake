# /test/CreateTargetForUnusedFunctionCheckIncludes.cmake
# Adds some sources to the global unused function check properties and adds
# checks to a newly created external target.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)

# The sources actually need to exist for cppcheck to succeed.
foreach (SOURCE ${SOURCES})

	file (WRITE ${SOURCE} "")

endforeach ()

set (INCLUDES
     ${CMAKE_CURRENT_BINARY_DIR})

cppcheck_add_to_unused_function_check (global
	                                   SOURCES ${SOURCES}
                                       INCLUDES ${INCLUDES})

# Put CMAKE_CURRENT_SOURCE_DIR in the global INCLUDES
cppcheck_add_unused_function_check_with_name (global)