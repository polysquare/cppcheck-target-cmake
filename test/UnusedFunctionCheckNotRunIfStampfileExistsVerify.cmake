# /test/UnusedFunctionCheckNotRunIfStampfileExistsVerify
# Check that the unused function check is not run in case all sources are
# up-to-date and the stampfile already exists.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

# Now make sure that the cppcheck rule was not run.
set (UNUSED_FUNCTION_REGEX
     "^.*cppcheck.*unusedFunction.*FirstSource\\.cpp.*$")
assert_file_does_not_have_line_matching (${BUILD_OUTPUT}
                                         ${UNUSED_FUNCTION_REGEX})