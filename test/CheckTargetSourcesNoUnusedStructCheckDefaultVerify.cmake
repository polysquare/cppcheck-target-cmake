# /test/CheckTargetSourcesNoStructCheckDefaultVerify.cmake
# Verifies that cppcheck runs with suppress=unusedStructMember
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_contains (${BUILD_OUTPUT} "--suppress=unusedStructMember")

foreach (OPTION ${CPPCHECK_COMMON_OPTIONS})

	assert_file_contains (${BUILD_OUTPUT} "${OPTION}")

endforeach ()