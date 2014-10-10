# /test/CreateTargetForUnusedFunctionCheckNoGeneratedDefault.cmake
# Adds some sources and generated sources to the global unused function check
# but does not pass the CHECK_GENERATED flag.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
set (GENERATED_SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/GeneratedSource.cpp)

# The sources actually need to exist for cppcheck to succeed.
file (WRITE ${SOURCES} "")
add_custom_command (OUTPUT ${GENERATED_SOURCES}
                    COMMAND ${CMAKE_COMMAND} -E touch ${GENERATED_SOURCES})

cppcheck_add_to_unused_function_check (global
	                                   SOURCES
                                       ${SOURCES}
                                       ${GENERATED_SOURCES})

# Put CMAKE_CURRENT_SOURCE_DIR in the global INCLUDES
cppcheck_add_unused_function_check_with_name (global)