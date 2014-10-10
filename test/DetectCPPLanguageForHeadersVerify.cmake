# /test/DetectCPPLanguageForHeadersVerify.cmake
# Check to make sure that cppcheck was run with --language=c++
#
# See LICENCE.md for Copyright Information.

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (CXX_REGEX "^.*cppcheck.*language=c\\+\\+.*header.h.*$")

assert_file_has_line_matching (${BUILD_OUTPUT} ${CXX_REGEX})
