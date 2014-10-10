# /test/CheckTargetSourcesDefinitions.cmake
# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself and some mock defoinitions.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/SecondSource.cpp)

foreach (SOURCE ${SOURCES})

    file (WRITE ${SOURCE} "")

endforeach ()

add_library (library SHARED
             ${SOURCES})
cppcheck_target_sources (library
                         DEFINES
                         DEFINITION_SUCCESS=1)