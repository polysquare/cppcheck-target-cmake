# /test/StampfileGeneratedForUnusedFunctionCheckVerify.cmake
# Verfies that the stampfile is generated as a result of running the check.
#
# See LICENCE.md for Copyright information.

include (CPPCheck)
include (CMakeUnit)

assert_file_exists (${CMAKE_CURRENT_BINARY_DIR}/global.stamp)