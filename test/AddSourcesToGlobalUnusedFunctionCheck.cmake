# /test/AddSourcestoGlobalUnusedFunctionCheck.cmake
# Checks the that when we add a source or include to the global unused
# function check it is added to one of the following properties:
# - CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_SOURCES
# - CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES
#
# See LICENCE.md for Copyright Information.

include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_DIRECTORY}/CPPCheck.cmake)
include (${CPPCHECK_COMMON_UNIVERSAL_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)

set (SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/FirstSource.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/SecondSource.cpp)

set (INCLUDES
     ${CMAKE_CURRENT_BINARY_DIR}
     ${CMAKE_CURRENT_SOURCE_DIR})

cppcheck_add_to_global_unused_function_check (SOURCES ${SOURCES}
                                              INCLUDES ${INCLUDES})

set (CHECK_SOURCES_PROPERTY
     CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_SOURCES)
set (CHECK_INCLUDES_PROPERTY
     CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES)

foreach (SOURCE ${SOURCES})

	assert_has_property_containing_value (GLOBAL
	                                      GLOBAL
	                                      ${CHECK_SOURCES_PROPERTY}
	                                      STRING
	                                      EQUAL
	                                      ${SOURCE})

endforeach ()

foreach (INCLUDE ${INCLUDES})

	assert_has_property_containing_value (GLOBAL
	                                      GLOBAL
	                                      ${CHECK_INCLUDES_PROPERTY}
	                                      STRING
	                                      EQUAL
	                                      ${INCLUDE})

endforeach ()