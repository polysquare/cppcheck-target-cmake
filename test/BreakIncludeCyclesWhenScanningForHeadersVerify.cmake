
# /test/BreakIncludeCyclesWhenScanningForHeadersVerify.cmake
#
# When a toplevel header file is included by a header file which in itself
# includes a C source file, then make sure the toplevel header file is
# marked as a C header file.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*language=c\\+\\+.*Toplevel.h.*$")
