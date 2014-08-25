# /test/CheckTransientIncludesForLanguageVerify.cmake
#
# When a toplevel header file is included by a header file which in itself
# includes a C source file, then make sure the toplevel header file is
# marked as a C header file.
#
# See LICENCE.md for Copyright information

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*language=c.*Toplevel.h.*$")
assert_file_does_not_have_line_matching (${BUILD_OUTPUT}
                                        "^.*language=c\\+\\+.*Toplevel.h.*$")
