# /test/CheckGeneratedSourcesOnNonBinaryTarget.cmake
# Creates a new custom target with some sources, some of which are
# generated and add cppcheck to it.
#
# A compliant implementation should detect that this isn't a binary
# target and still attempt to run the checks as best as it can.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (NATIVE_SOURCE
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
set (GENERATED_SOURCE
     ${CMAKE_CURRENT_SOURCE_DIR}/GeneratedSource.cpp)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/GeneratedSource.cpp)

file (WRITE ${NATIVE_SOURCE} "")
add_custom_command (OUTPUT ${GENERATED_SOURCE}
                    COMMAND ${CMAKE_COMMAND} -E touch ${GENERATED_SOURCE})

add_custom_target (custom_target ALL
                   SOURCES ${SOURCES})

cppcheck_target_sources (custom_target CHECK_GENERATED)