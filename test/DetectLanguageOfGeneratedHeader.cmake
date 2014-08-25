# /test/DetectLanguageOfGeneratedHeader.cmake
# Adds some source files which will be detected as C source files
# and include a header in them, although that header will be a generated file.
#
# See LICENCE.md for Copyright Information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

find_program (CPPCHECK_EXECUTABLE cppcheck)

set (INCLUDE_DIRECTORY
     ${CMAKE_CURRENT_BINARY_DIR}/include)
set (C_HEADER_FILE_DIRECTORY
     ${INCLUDE_DIRECTORY}/c)
set (C_HEADER_FILE
     ${C_HEADER_FILE_DIRECTORY}/header.h)
set (C_HEADER_FILE_CONTENTS
     "struct MyThing\n"
     "{\n"
     "    int dataMember\;\n"
     "}\;\n"
     "\n")

set (C_SOURCE_FILE
     ${CMAKE_CURRENT_BINARY_DIR}/CSource.c)
set (C_SOURCE_FILE_CONTENTS
     "\#include <c/header.h>\n"
     "int main (void)\n"
     "{\n"
     "    return 0\;\n"
     "}\n"
     "\n")

file (MAKE_DIRECTORY ${INCLUDE_DIRECTORY})
file (MAKE_DIRECTORY ${C_HEADER_FILE_DIRECTORY})

file (WRITE ${C_SOURCE_FILE} ${C_SOURCE_FILE_CONTENTS})
add_custom_command (OUTPUT ${C_HEADER_FILE}
                    COMMAND ${CMAKE_COMMAND} -E touch ${C_HEADER_FILE})

include_directories (${INCLUDE_DIRECTORY})

set (EXECUTABLE executable)
add_executable (${EXECUTABLE}
                ${C_SOURCE_FILE}
                ${C_HEADER_FILE})

cppcheck_target_sources (${EXECUTABLE}
                         INCLUDES ${INCLUDE_DIRECTORY}
                         CHECK_GENERATED)
