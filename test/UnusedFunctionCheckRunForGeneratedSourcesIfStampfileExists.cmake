# /test/UnusedFunctionCheckRunForGeneratedSourceFilesIfStampfileExists.cmake
# Before the build, create the stampfile as though it already exists. It won't
# get removed on the clean phase.
#
# Add some sources which require generation themselves as sources to be
# checked as part of the unused function check.
#
# If the build rules were set up correctly, the generation of the sources
# will cause the stampfile to become out of date and the cppcheck unused
# function check rule to be re-run.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (NATIVE_SOURCE
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp)
set (GENERATED_SOURCE
     ${CMAKE_CURRENT_BINARY_DIR}/Generated.cpp)
set (SOURCES ${NATIVE_SOURCE} ${GENERATED_SOURCE})

file (WRITE ${NATIVE_SOURCE} "")
add_custom_command (OUTPUT ${GENERATED_SOURCE}
                    COMMAND ${CMAKE_COMMAND} -E touch ${GENERATED_SOURCE})

set (STAMPFILE ${CMAKE_CURRENT_BINARY_DIR}/global.stamp)
file (WRITE ${STAMPFILE} "")

cppcheck_add_to_unused_function_check (global
                                       SOURCES ${SOURCES}
                                       CHECK_GENERATED)

cppcheck_add_unused_function_check_with_name (global)