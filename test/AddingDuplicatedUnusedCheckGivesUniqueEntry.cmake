# /test/AddUnusedFunctionCheckWithNameAddsTarget.cmake
# Adds an unused function check and asserts that a target with the name
# of the unused function check is added.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
file (WRITE ${SOURCES} "")

cppcheck_add_to_unused_function_check (global
                                       SOURCES ${SOURCES})
cppcheck_add_to_unused_function_check (global
                                       SOURCES ${SOURCES})

set (NUMBER_OF_TIMES_NAME_APPEARS 0)

get_property (NAMES
	          GLOBAL
              PROPERTY CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES)

foreach (NAME ${NAMES})

	if (NAME STREQUAL "global")

		math (EXPR NUMBER_OF_TIMES_NAME_APPEARS
		      "${NUMBER_OF_TIMES_NAME_APPEARS} + 1")

	endif (NAME STREQUAL "global")

endforeach ()

assert_variable_is (NUMBER_OF_TIMES_NAME_APPEARS STRING EQUAL "1")