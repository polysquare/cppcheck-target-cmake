# /test/ScanForBothWithCustomCPPIdentifier.cmake
# Check to make sure that cppcheck was run with --language=c++ and
# --language=c
#
# See LICENCE.md for Copyright Information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*language=c.*both.h.*c.h.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*cppcheck.*language=c\\+\\+.*both.h.*$")
