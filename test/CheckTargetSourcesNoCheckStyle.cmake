# /test/CheckTargetSourcesNoCheckStyle.cmake
# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself. Do not check style.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
file (WRITE ${SOURCES} "")

add_library (library SHARED
             ${SOURCES})
cppcheck_target_sources (library NO_CHECK_STYLE)