# /test/ScanForBothWithCustomCPPIdentifier.cmake
# Adds some source files which will be detected as C source files
# and include a header in them, with ${CMAKE_CURRENT_BINARY_DIR}/include
# to be used as the include-directory.
#
# Add POLYSQUARE_BEGIN_DECLS to the header file and let
# cppcheck_target_sources know about that identifier. This shall make it scanned
# in both modes
#
# See LICENCE.md for Copyright Information.

include (CPPCheck)
include (CMakeUnit)

_validate_cppcheck (CONTINUE)

set (INCLUDE_DIRECTORY
     ${CMAKE_CURRENT_BINARY_DIR}/include)
set (C_HEADER_FILE_DIRECTORY
     ${INCLUDE_DIRECTORY}/c)
set (DECLS_HEADER_FILE
     ${C_HEADER_FILE_DIRECTORY}/decls.h)
set (DECLS_HEADER_FILE_CONTENTS
     "\#ifndef DECLS_H\n"
     "\#define DECLS_H\n"
     "\#define POLYSQUARE_IS_CPP __cplusplus\n"
     "\#endif\n"
     "\n")

set (BOTH_HEADER_FILE
     ${C_HEADER_FILE_DIRECTORY}/both.h)
set (BOTH_HEADER_FILE_CONTENTS
     "\#include <c/decls.h>\n"
     "\#if POLYSQUARE_IS_CPP\n"
     "class MyClass\n"
     "{\n"
     "    public:\n"
     "        int dataMember\;\n"
     "}\;\n"
     "\#endif\n"
     "\n")

set (C_HEADER_FILE
     ${C_HEADER_FILE_DIRECTORY}/c.h)
set (C_HEADER_FILE_CONTENTS
     "struct MyThing\n"
     "{\n"
     "    int dataMember\;\n"
     "}\;\n"
     "\n")

set (C_SOURCE_FILE
     ${CMAKE_CURRENT_BINARY_DIR}/CSource.c)
set (C_SOURCE_FILE_CONTENTS
     "\#include <c/both.h>\n"
     "\#include <c/c.h>\n"
     "int main (void)\n"
     "{\n"
     "    struct MyThing myThing = { 1 }\;\n"
     "    return myThing.dataMember\;\n"
     "}\n"
     "\n")

file (MAKE_DIRECTORY ${INCLUDE_DIRECTORY})
file (MAKE_DIRECTORY ${C_HEADER_FILE_DIRECTORY})

file (WRITE ${C_SOURCE_FILE} ${C_SOURCE_FILE_CONTENTS})
file (WRITE ${C_HEADER_FILE} ${C_HEADER_FILE_CONTENTS})
file (WRITE ${BOTH_HEADER_FILE} ${BOTH_HEADER_FILE_CONTENTS})
file (WRITE ${DECLS_HEADER_FILE} ${DECLS_HEADER_FILE_CONTENTS})

include_directories (${INCLUDE_DIRECTORY})

set (EXECUTABLE executable)
add_executable (${EXECUTABLE}
                ${C_SOURCE_FILE}
                ${BOTH_HEADER_FILE}
                ${DECLS_HEADER_FILE}
                ${C_HEADER_FILE})

cppcheck_target_sources (${EXECUTABLE}
                         INCLUDES ${INCLUDE_DIRECTORY}
                         CPP_IDENTIFIERS
                         POLYSQUARE_BEGIN_DECLS
                         POLYSQUARE_IS_CPP)
