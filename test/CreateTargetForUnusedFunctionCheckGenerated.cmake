# /test/CreateTargetForUnusedFunctionCheckGenerated.cmake
# Adds some sources and generated sources to the global unused function check -
# passing the CHECK_GENERATED flag.
#
# See LICENCE.md for Copyright Information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

find_program (CPPCHECK_EXECUTABLE cppcheck)

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
                                       ${GENERATED_SOURCES}
                                       CHECK_GENERATED)

# Put CMAKE_CURRENT_SOURCE_DIR in the global INCLUDES
cppcheck_add_unused_function_check_with_name (global)