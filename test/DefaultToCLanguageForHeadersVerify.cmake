# /test/DefaultToCLanguageForHeadersVerify.cmake
# Check to make sure that cppcheck was run with --language=c
#
# See LICENCE.md for Copyright Information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (C_REGEX "^.*cppcheck.*language=c.*header.h.*$")
set (CXX_REGEX "^.*cppcheck.*language=c\\+\\+.*header.h.*$")

assert_file_has_line_matching (${BUILD_OUTPUT} ${C_REGEX})
assert_file_does_not_have_line_matching (${BUILD_OUTPUT} ${CXX_REGEX})
