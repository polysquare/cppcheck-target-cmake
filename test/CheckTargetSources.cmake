# /test/CheckTargetSources.cmake
# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

find_program (CPPCHECK_EXECUTABLE cppcheck)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/SecondSource.cpp)

foreach (SOURCE ${SOURCES})

	file (WRITE ${SOURCE} "")

endforeach ()

add_library (library SHARED
             ${SOURCES})
cppcheck_target_sources (library)