# /test/CreateTargetForGlobalUnusedFunctionCheckIncludes.cmake
# Adds some sources to the global unused function check properties and adds
# checks to a newly created external target.
#
# See LICENCE.md for Copyright Information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

find_program (CPPCHECK_EXECUTABLE cppcheck)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)

# The sources actually need to exist for cppcheck to succeed.
foreach (SOURCE ${SOURCES})

	file (WRITE ${SOURCE} "")

endforeach ()

set (INCLUDES
     ${CMAKE_CURRENT_BINARY_DIR})

cppcheck_add_to_global_unused_function_check (SOURCES ${SOURCES}
                                              INCLUDES ${INCLUDES})

add_custom_target (on_all ALL)

# Put CMAKE_CURRENT_SOURCE_DIR in the global INCLUDES
cppcheck_add_global_unused_function_check_to_target (on_all)