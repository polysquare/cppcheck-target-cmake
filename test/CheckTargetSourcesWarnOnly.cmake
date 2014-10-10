# /test/CheckTargetSourcesWarnOnly.cmake
# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself. Only print warnings and do not exit
# on error.
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
cppcheck_target_sources (library WARN_ONLY)