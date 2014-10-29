# /test/UnusedFunctionCheckNotRunForIfStampfileExists.cmake
# During the build, create the stampfile as if it already exists
# and ensure that this build rule runs before the global build rule.
#
# If the build rules were set up correctly, the stampfile will be up
# to date already and the build rule will not be run.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)

file (WRITE ${SOURCES} "")

set (STAMPFILE ${CMAKE_CURRENT_BINARY_DIR}/global.cppcheck-unused.stamp)

# STAMPFILE will already have a build rule, so we create a
# proxy STAMPFILE stamp and then silently generate the stampfile
# in that rule as well.
set (STAMPFILE_PROXY ${STAMPFILE}.stamp)
add_custom_command (OUTPUT ${STAMPFILE_PROXY}
                    COMMAND ${CMAKE_COMMAND} -E touch ${STAMPFILE}
                    COMMAND ${CMAKE_COMMAND} -E touch ${STAMPFILE_PROXY})
add_custom_target (create_stampfile_first
                   DEPENDS ${STAMPFILE_PROXY})

cppcheck_add_to_unused_function_check (global
                                       SOURCES ${SOURCES}
                                       TARGETS create_stampfile_first)

cppcheck_add_unused_function_check_with_name (global)