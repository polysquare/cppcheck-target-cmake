# /test/CheckTransientIncludesForLanguage.cmake
# Add source and header files in the following include hierarchy:
# Toplevel.h
# |
# -Immediate.h
#  |
#  - CSource.c
#  - CXXSource.cxx
# - CXXSource.cxx
#
# Immediate.h is included by at least one C source, so it becomes a "C"
# header. Because Immediate.h includes Toplevel.h, it also becomes a "C"
# header too, even though CXXSource.cxx includes it.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (INCLUDE_DIRECTORY
     ${CMAKE_CURRENT_BINARY_DIR}/include)
set (C_HEADER_FILE_DIRECTORY
     ${INCLUDE_DIRECTORY}/c)
set (TOPLEVEL_HEADER_FILE
     ${C_HEADER_FILE_DIRECTORY}/Toplevel.h)
set (TOPLEVEL_HEADER_FILE_CONTENTS
     "\#ifndef TOPLEVEL_H\n"
     "\#define TOPLEVEL_H\n"
     "struct MyThing\n"
     "{\n"
     "    int dataMember\;\n"
     "}\;\n"
     "\#endif"
     "\n")

set (IMMEDIATE_HEADER_FILE
     ${C_HEADER_FILE_DIRECTORY}/Immediate.h)
set (IMMEDIATE_HEADER_FILE_CONTENTS
     "\#include <c/Toplevel.h>\n"
     "int function ()\;\n"
     "\n")

set (C_SOURCE_FILE
     ${CMAKE_CURRENT_BINARY_DIR}/CSource.c)
set (C_SOURCE_FILE_CONTENTS
     "\#include <c/Immediate.h>\n"
     "int function ()\n"
     "{\n"
     "    struct MyThing myThing = { 1 }\;\n"
     "    return myThing.dataMember\;\n"
     "}\n"
     "\n")

set (CXX_SOURCE_FILE
     ${CMAKE_CURRENT_BINARY_DIR}/CXXSource.cxx)
set (CXX_SOURCE_FILE_CONTENTS
     "extern \"C\" {\n"
     "\#include <c/Immediate.h>\n"
     "\#include <c/Toplevel.h>\n"
     "}\n"
     "int main (void)\n"
     "{\n"
     "    return function ()\;\n"
     "}\n"
     "\n")

file (MAKE_DIRECTORY ${INCLUDE_DIRECTORY})
file (MAKE_DIRECTORY ${C_HEADER_FILE_DIRECTORY})

file (WRITE ${C_SOURCE_FILE} ${C_SOURCE_FILE_CONTENTS})
file (WRITE ${CXX_SOURCE_FILE} ${CXX_SOURCE_FILE_CONTENTS})
file (WRITE ${TOPLEVEL_HEADER_FILE} ${TOPLEVEL_HEADER_FILE_CONTENTS})
file (WRITE ${IMMEDIATE_HEADER_FILE} ${IMMEDIATE_HEADER_FILE_CONTENTS})

include_directories (${INCLUDE_DIRECTORY})

set (EXECUTABLE executable)
add_executable (${EXECUTABLE}
                ${C_SOURCE_FILE}
                ${CXX_SOURCE_FILE}
                ${IMMEDIATE_HEADER_FILE}
                ${TOPLEVEL_HEADER_FILE})

cppcheck_target_sources (${EXECUTABLE}
                         INCLUDES ${INCLUDE_DIRECTORY})
