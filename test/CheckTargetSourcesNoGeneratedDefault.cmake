# /test/CheckTargetSourcesNoGeneratedDefault.cmake
# Creates a new library target with native and generated sources and
# adds a cppcheck target to it, but does not pass the CHECK_GENERATED
# flag.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

find_program (CPPCHECK_EXECUTABLE cppcheck)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
set (GENERATED_SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/GeneratedSource.cpp)

file (WRITE ${SOURCES} "")
add_custom_command (OUTPUT ${GENERATED_SOURCES}
                    COMMAND ${CMAKE_COMMAND} -E touch ${GENERATED_SOURCES})

add_library (library SHARED
             ${SOURCES}
             ${GENERATED_SOURCES})

cppcheck_target_sources (library
                         INCLUDES
                         ${CMAKE_CURRENT_SOURCE_DIR})