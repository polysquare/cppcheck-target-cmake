# /test/CheckTargetSources.cmake
# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)

foreach (SOURCE ${SOURCES})

	file (WRITE ${SOURCE} "")

endforeach ()

add_library (library SHARED
             ${SOURCES})
cppcheck_target_sources (library)