# /test/CheckTargetSourcesGenerated.cmake
# Creates a new library target from both native and generated sources.
# Adds cppcheck to all sources, with an explicit marker to check generated
# sources too.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

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
                         ${CMAKE_CURRENT_SOURCE_DIR}
                         CHECK_GENERATED)