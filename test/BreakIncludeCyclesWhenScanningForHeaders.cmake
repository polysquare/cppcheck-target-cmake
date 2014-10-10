# /test/BreakIncludeCyclesWhenScanningForHeaders.cmake
# Add source and header files in the following include hierarchy:
# Toplevel.h
# |
# -Immediate.h
#  |
#  - CXXSource.cxx
# - CXXSource.cxx
#
# Immediate.h shall also include Toplevel.h. This would technically
# create a cycle.
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (INCLUDE_DIRECTORY
     ${CMAKE_CURRENT_BINARY_DIR}/include)
set (CXX_HEADER_FILE_DIRECTORY
     ${INCLUDE_DIRECTORY}/cxx)
set (TOPLEVEL_HEADER_FILE
     ${CXX_HEADER_FILE_DIRECTORY}/Toplevel.h)
set (TOPLEVEL_HEADER_FILE_CONTENTS
     "\#ifndef TOPLEVEL_H\n"
     "\#define TOPLEVEL_H\n"
     "\#include <cxx/Immediate.h>\n"
     "struct MyThing\n"
     "{\n"
     "    int dataMember\;\n"
     "}\;\n"
     "\#endif"
     "\n")

set (IMMEDIATE_HEADER_FILE
     ${CXX_HEADER_FILE_DIRECTORY}/Immediate.h)
set (IMMEDIATE_HEADER_FILE_CONTENTS
     "\#ifndef IMMEDIATE_H\n"
     "\#define IMMEDIATE_H\n"
     "\#include <cxx/Toplevel.h>\n"
     "int function ()\n"
     "{\n"
     "    return 1\;\n"
     "}\n"
     "\#endif\n"
     "\n")

set (CXX_SOURCE_FILE
     ${CMAKE_CURRENT_BINARY_DIR}/CXXSource.cxx)
set (CXX_SOURCE_FILE_CONTENTS
     "\#include <cxx/Immediate.h>\n"
     "\#include <cxx/Toplevel.h>\n"
     "int main (void)\n"
     "{\n"
     "    return function ()\;\n"
     "}\n"
     "\n")

file (MAKE_DIRECTORY ${INCLUDE_DIRECTORY})
file (MAKE_DIRECTORY ${CXX_HEADER_FILE_DIRECTORY})

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
