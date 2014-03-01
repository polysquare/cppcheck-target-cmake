# /test/StampfileGeneratedForUnusedFunctionCheckVerify.cmake
# Verfies that the stampfile is generated as a result of running the check.
#
# See LICENCE.md for Copyright information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

assert_file_exists (${CMAKE_CURRENT_BINARY_DIR}/global.stamp)