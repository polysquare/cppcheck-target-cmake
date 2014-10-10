# /test/CheckTargetSourcesIncludesVerify.cmake
# Verifies that cppcheck was actually run on the target's source files
# and specifies its include directories.
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (REAL_SOURCE_DIR_RELATIVE
     ${CMAKE_CURRENT_SOURCE_DIR}/../)
get_filename_component (REAL_SOURCE_DIR
                        ${REAL_SOURCE_DIR_RELATIVE}
                        ABSOLUTE)

assert_file_contains (${BUILD_OUTPUT} "-I${REAL_SOURCE_DIR}")