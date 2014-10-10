# /test/CheckTargetSourcesVerify.cmake
# Verifies that cppcheck was actually run on the target's source files
# with the default options.
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_contains (${BUILD_OUTPUT} "cppcheck")
assert_file_contains (${BUILD_OUTPUT} "FirstSource.cpp")
assert_file_contains (${BUILD_OUTPUT} "SecondSource.cpp")
assert_file_contains (${BUILD_OUTPUT} "--enable=style")
assert_file_contains (${BUILD_OUTPUT} "--error-exitcode=1")
assert_file_contains (${BUILD_OUTPUT} "--enable=performance")
assert_file_contains (${BUILD_OUTPUT} "--enable=style")

foreach (OPTION ${CPPCHECK_COMMON_OPTIONS})

	assert_file_contains (${BUILD_OUTPUT} "${OPTION}")

endforeach ()