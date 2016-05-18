# /CMakeLists.txt
#
# Main entry point for CPPCheck tests.
#
# See /LICENCE.md for Copyright information

include ("${CMAKE_CURRENT_LIST_DIR}/conanbuildinfo.cmake")
set (CMAKE_MODULE_PATH
     "${CMAKE_CURRENT_LIST_DIR}"
     ${CONAN_CMAKE_MODULE_PATH}  # NOLINT:correctness/quotes
     ${CMAKE_MODULE_PATH})  # NOLINT:correctness/quotes

cmake_minimum_required (VERSION 2.8)

set (_CURRENT_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}")

include ("cmake/cmake-module-common/Common")
include (CPPCheck)

if (NOT CMAKE_SCRIPT_MODE_FILE)

    cppcheck_validate (HAVE_CPPCHECK)

else ()

    # Set these variables such that the conditions to add tests always pass
    # as we're not in the pre-configure phase, which is the only place
    # we'd want them to fail.
    set (HAVE_CPPCHECK TRUE)
    set (CPPCHECK_VERSION 1.58)

endif ()

# Adds an unused function check and asserts that a target with the name
# of the unused function check is added.
function (cppcheck_test_adding_duplicated_unused_check_gives_unique_entry)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        set (NUMBER_OF_TIMES_NAME_APPEARS 0)
        get_property (NAMES GLOBAL PROPERTY
                      CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES)
        foreach (NAME ${NAMES})
            if (NAME STREQUAL "global")
                math (EXPR NUMBER_OF_TIMES_NAME_APPEARS
                      "${NUMBER_OF_TIMES_NAME_APPEARS} + 1")

            endif ()
        endforeach ()

        cmake_unit_assert_that (NUMBER_OF_TIMES_NAME_APPEARS
                                compare_as STRING EQUAL "1")

    endfunction ()

    if (HAVE_CPPCHECK)
        cmake_unit_configure_config_only_test (CONFIGURE
                                               COMMAND
                                               cppcheck_configure)
    endif ()

endfunction ()

# Checks the that when we add a source or include to the global unused
# function check it is added to one of the following properties:
# - CPPCHECK_${CHECK_NAME}_UNUSED_FUNCTION_CHECK_SOURCES
# - CPPCHECK_${CHECK_NAME}_UNUSED_FUNCTION_CHECK_INCLUDES
function (cppcheck_test_add_sources_to_unused_function_check)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        set (SOURCES
             "${SOURCE_DIR}/First.cpp"
             "${SOURCE_DIR}/Second.cpp")
        set (INCLUDES "${BINARY_DIR}" "${SOURCE_DIR}")
        set (CHECK_NAME global)
        cppcheck_add_to_unused_function_check (${CHECK_NAME} SOURCES ${SOURCES}
                                               INCLUDES
                                               ${INCLUDES})
        set (CHECK_SOURCES_PROPERTY
             CPPCHECK_${CHECK_NAME}_UNUSED_FUNCTION_CHECK_SOURCES)
        set (CHECK_INCLUDES_PROPERTY
             CPPCHECK_${CHECK_NAME}_UNUSED_FUNCTION_CHECK_INCLUDES)
        cmake_unit_assert_that (GLOBAL item_has_property_containing_value
                                GLOBAL
                                CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES
                                STRING
                                EQUAL
                                ${CHECK_NAME})
        foreach (SOURCE ${SOURCES})
            cmake_unit_assert_that (GLOBAL
                                    item_has_property_containing_value
                                    GLOBAL
                                    ${CHECK_SOURCES_PROPERTY}
                                    STRING
                                    EQUAL
                                    "${SOURCE}")
        endforeach ()

        foreach (INCLUDE ${INCLUDES})
            cmake_unit_assert_that (GLOBAL
                                    item_has_property_containing_value
                                    GLOBAL
                                    ${CHECK_INCLUDES_PROPERTY}
                                    STRING
                                    EQUAL
                                    ${INCLUDE})
        endforeach ()


    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND cppcheck_configure)
endfunction ()

# Adds an unused function check and asserts that a target with the name
# of the unused function check is added.
function (cppcheck_test_add_unused_function_check_with_name_adds_target)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        cppcheck_add_unused_function_check_with_name (global)
        cmake_unit_assert_that (global target_exists)

    endfunction ()

    if (HAVE_CPPCHECK)
        cmake_unit_configure_config_only_test (CONFIGURE
                                               COMMAND
                                               cppcheck_configure)
    endif ()

endfunction ()

# Add source and header files in the following include hierarchy:
# /Toplevel.h
# |
# -/Immediate.h
#  |
#  - /CXXSource.cxx
# - /CXXSource.cxx
function (cppcheck_test_break_include_cycles_when_scanning_for_headers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIR "${SOURCE_DIR}/include")
        set (CXX_HDR_DIRECTORY_NAME "cxx")
        set (TOPLEVEL_HDR "${CXX_HDR_DIRECTORY_NAME}/Toplevel.h")
        set (IMMEDIATE_HDR "${CXX_HDR_DIRECTORY_NAME}/Immediate.h")
        set (PATH_TO_TOPLEVEL_HDR "${INCLUDE_DIR}/${TOPLEVEL_HDR}")
        set (PATH_TO_IMMEDIATE_HDR "${INCLUDE_DIR}/${IMMEDIATE_HDR}")

        cmake_unit_create_source_file_before_build (NAME
                                                    "include/${TOPLEVEL_HDR}"
                                                    INCLUDES
                                                    "${IMMEDIATE_HDR}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME
                                                    "include/${IMMEDIATE_HDR}"
                                                    INCLUDES
                                                    "${TOPLEVEL_HDR}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")

        set (CXX_SOURCE CXXSource.cxx)
        set (PATH_TO_CXX_SOURCE
             "${CMAKE_CURRENT_SOURCE_DIR}/${CXX_SOURCE}")

        cmake_unit_create_source_file_before_build (NAME "${CXX_SOURCE}"
                                                    INCLUDES
                                                    "${IMMEDIATE_HDR}"
                                                    "${TOPLEVEL_HDR}"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${INCLUDE_DIR}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}" "${PATH_TO_CXX_SOURCE}"
                        "${PATH_TO_IMMEDIATE_HDR}"
                        "${PATH_TO_TOPLEVEL_HDR}")
        cppcheck_target_sources ("${EXECUTABLE}"
                                 INCLUDES "${INCLUDE_DIR}"
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*language=c\\+\\+.*Toplevel.h.*$")

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some source files which will be detected as C source files
# and include a header in them, with ${BINARY_DIR}/include
# to be used as the include-directory.
function (cppcheck_test_check_for_c_and_cpp_where_header_has_ifdef_c_plus_plus)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIR "${SOURCE_DIR}")
        set (C_HDR_DIRECTORY_NAME "c")
        set (BOTH_HDR_NAME "${C_HDR_DIRECTORY_NAME}/both.h")
        set (BOTH_HDR_PATH "${INCLUDE_DIR}/${BOTH_HDR_NAME}")
        set (C_HDR_NAME "${C_HDR_DIRECTORY_NAME}/c.h")
        set (C_HDR_PATH "${INCLUDE_DIR}/${C_HDR_NAME}")
        set (C_SOURCE_NAME "CSource.c")
        set (C_SOURCE_PATH "${SOURCE_DIR}/${C_SOURCE_NAME}")

        cmake_unit_create_source_file_before_build (NAME "${BOTH_HDR_NAME}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    PREPEND_CONTENTS
                                                    "#ifdef __cplusplus\n"
                                                    "#endif\n"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_HDR_NAME}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_SOURCE_NAME}"
                                                    INCLUDES
                                                    "${BOTH_HDR_NAME}"
                                                    "${C_HDR_NAME}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")

        include_directories ("${INCLUDE_DIR}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${C_SOURCE_PATH}"
                        "${BOTH_HDR_PATH}"
                        "${C_HDR_PATH}")
        cppcheck_target_sources ("${EXECUTABLE}"
                                 INCLUDES "${INCLUDE_DIR}"
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*language=c.*both.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck.*language=c.*c.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck.*language=c\\+\\+.*both.h.*$")

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new custom target with some sources, some of which are
# generated and add cppcheck to it.
function (cppcheck_test_check_generated_sources_on_non_binary_target)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME
                                                      "Generated.cpp"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}")

        set (SOURCES "${SOURCE_DIR}/First.cpp"
             "${BINARY_DIR}/Generated.cpp")
        add_custom_target (custom_target ALL SOURCES ${SOURCES})
        cppcheck_target_sources (custom_target CHECK_GENERATED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*First\\.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck.*Generated\\.cpp.*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself.
function (cppcheck_test_check_target_sources)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES
             "${SOURCE_DIR}/First.cpp"
             "${SOURCE_DIR}/Second.cpp")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        add_library (library SHARED ${SOURCES})
        cppcheck_target_sources (library)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents variable_contains "cppcheck")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "First.cpp")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "Second.cpp")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "--enable=style")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "--error-exitcode=1")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "--enable=performance")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "--enable=style")
        foreach (OPTION ${CPPCHECK_COMMON_OPTIONS})
            cmake_unit_assert_that (${BUILD_OUTPUT}
                                    file_contents
                                    variable_contains
                                    "${OPTION}")
        endforeach ()


    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself and some mock definitions.
function (cppcheck_test_check_target_sources_definitions)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp"
             "${SOURCE_DIR}/Second.cpp")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        add_library (library SHARED ${SOURCES})
        cppcheck_target_sources (library DEFINES DEFINITION_SUCCESS=1)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*-DDEFINITION_SUCCESS=1.*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new library target from both native and generated sources.
# Adds cppcheck to all sources, with an explicit marker to check generated
# sources too.
function (cppcheck_test_check_target_sources_generated)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        set (GENERATED_SOURCES "${BINARY_DIR}/Generated.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME
                                                      "Generated.cpp"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}")
        add_library (library SHARED ${SOURCES} ${GENERATED_SOURCES})
        cppcheck_target_sources (library INCLUDES "${SOURCE_DIR}"
                                 CHECK_GENERATED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck[\\.a-z]* .*First.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck[\\.a-z]* .*Generated.*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself and some mock include directories
function (cppcheck_test_check_target_sources_includes)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp"
             "${SOURCE_DIR}/Second.cpp")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        add_library (library SHARED ${SOURCES})
        cppcheck_target_sources (library INCLUDES "${SOURCE_DIR}")

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (REAL_SOURCE_DIR_RELATIVE "${SOURCE_DIR}/../")
        get_filename_component (REAL_SOURCE_DIR ${REAL_SOURCE_DIR_RELATIVE}
                                ABSOLUTE)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents variable_contains
                                "-I${REAL_SOURCE_DIR}")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself. Do not check style.
function (cppcheck_test_check_target_sources_no_check_style)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        add_library (library SHARED ${SOURCES})
        cppcheck_target_sources (library NO_CHECK_STYLE)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} not file_contents
                                variable_contains
                                "--enable=style")

    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                               CONFIGURE COMMAND cppcheck_configure
                               VERIFY COMMAND cppcheck_verify)

endfunction ()

# Creates a new library target with native and generated sources and
# adds a cppcheck target to it, but does not pass the CHECK_GENERATED
# flag.
function (cppcheck_test_check_target_sources_no_generated_default)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        set (GENERATED_SOURCES "${BINARY_DIR}/Generated.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME
                                                      "Generated.cpp"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}")
        add_library (library SHARED ${SOURCES} ${GENERATED_SOURCES})
        cppcheck_target_sources (library INCLUDES "${SOURCE_DIR}")

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} not file_contents any_line
                                matches_regex
                                "^.*cppcheck[\\.a-z]* .*Generated.cpp( |$).*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself - checking for unused structs should
# occur by default.
function (cppcheck_test_check_target_sources_unused_struct_check_default)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        add_library (library SHARED ${SOURCES})
        cppcheck_target_sources (library)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                variable_contains
                                "--suppress=unusedStructMember")
        foreach (OPTION ${CPPCHECK_COMMON_OPTIONS})
            cmake_unit_assert_that (${BUILD_OUTPUT}
                                    file_contents
                                    variable_contains
                                    "${OPTION}")
        endforeach ()


    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Creates a new library target and adds cppcheck checks to it, using the
# sources from the library itself. Only print warnings and do not exit
# on error.
function (cppcheck_test_check_target_sources_warn_only)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        add_library (library SHARED ${SOURCES})
        cppcheck_target_sources (library WARN_ONLY)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} not file_contents
                                variable_contains
                                "--error-exitcode=1")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Add source and header files in the following include hierarchy:
# /Toplevel.h
# |
# - /Immediate.h
#  |
#  - /CSource.c
#  - /CXXSource.cxx
# - /CXXSource.cxx
function (cppcheck_test_check_transient_includes_for_language)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIR "${SOURCE_DIR}/include")
        set (TOPLEVEL_HDR "Toplevel.h")
        set (IMMEDIATE_HDR "Immediate.h")
        set (PATH_TO_TOPLEVEL_HDR "${INCLUDE_DIR}/${TOPLEVEL_HDR}")
        set (PATH_TO_IMMEDIATE_HDR "${INCLUDE_DIR}/${IMMEDIATE_HDR}")

        cmake_unit_create_source_file_before_build (NAME
                                                    "include/${TOPLEVEL_HDR}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME
                                                    "include/${IMMEDIATE_HDR}"
                                                    INCLUDES
                                                    "${TOPLEVEL_HDR}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")

        set (CXX_SOURCE CXXSource.cxx)
        set (PATH_TO_CXX_SOURCE
             "${CMAKE_CURRENT_SOURCE_DIR}/${CXX_SOURCE}")
        set (C_SOURCE CSource.c)
        set (PATH_TO_C_SOURCE
             "${CMAKE_CURRENT_SOURCE_DIR}/${C_SOURCE}")

        cmake_unit_create_source_file_before_build (NAME "${C_SOURCE}"
                                                    INCLUDES
                                                    "${IMMEDIATE_HDR}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    FUNCTIONS "function"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${CXX_SOURCE}"
                                                    INCLUDES
                                                    "${IMMEDIATE_HDR}"
                                                    "${TOPLEVEL_HDR}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")

        include_directories ("${INCLUDE_DIR}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${PATH_TO_C_SOURCE}"
                        "${PATH_TO_CXX_SOURCE}"
                        "${PATH_TO_IMMEDIATE_HDR}"
                        "${PATH_TO_TOPLEVEL_HDR}")
        cppcheck_target_sources ("${EXECUTABLE}"
                                 INCLUDES "${INCLUDE_DIR}"
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*language=c.*Toplevel.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                any_line
                                matches_regex
                                "^.*language=c\\+\\+.*Toplevel.h.*$")

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some sources to the global unused function check properties and adds
# checks to a newly created external target.
function (cppcheck_test_unused_function_check)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents variable_contains
                                "cppcheck")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "First.cpp")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                variable_contains
                                "--enable=unusedFunction")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some sources to the global unused function check properties and adds
# checks to a newly created external target.
function (cppcheck_test_unused_function_check_definitions)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES}
                                               DEFINES
                                               DEFINITION_SUCCESS=1)
        cppcheck_add_unused_function_check_with_name (global DEFINES
                                                      GLOBAL_DEFINITION=1)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (CPPCHECK_COMMAND_LOCAL
             "^.*cppcheck.*unusedFunction.*-DDEFINITION_SUCCESS=1.*$")
        set (CPPCHECK_COMMAND_GLOBAL
             "^.*cppcheck.*unusedFunction.*-DGLOBAL_DEFINITION=1.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${CPPCHECK_COMMAND_LOCAL})
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                ${CPPCHECK_COMMAND_GLOBAL})

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some sources and generated sources to the global unused function check -
# passing the CHECK_GENERATED flag.
function (cppcheck_test_unused_function_check_generated)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        set (GENERATED_SOURCES "${BINARY_DIR}/Generated.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME
                                                      "Generated.cpp"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES}
                                               ${GENERATED_SOURCES}
                                               CHECK_GENERATED)
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck[\\.a-z]* .*First.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck[\\.a-z]* .*Generated.*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some sources to the global unused function check properties and adds
# checks to a newly created external target.
function (cppcheck_test_unused_function_check_includes)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        set (INCLUDES "${BINARY_DIR}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES}
                                               INCLUDES
                                               ${INCLUDES})
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        set (RELATIVE_REAL_SOURCE_DIR "${SOURCE_DIR}/../")
        get_filename_component (REAL_SOURCE_DIR "${RELATIVE_REAL_SOURCE_DIR}"
                                ABSOLUTE)
        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents variable_contains
                                "-I${REAL_SOURCE_DIR}")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some sources and generated sources to the global unused function check
# but does not pass the CHECK_GENERATED flag.
function (cppcheck_test_unused_function_check_no_gen_default)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        set (GENERATED_SOURCES "${BINARY_DIR}/Generated.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME
                                                      "Generated.cpp"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES}
                                               ${GENERATED_SOURCES})
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} not file_contents any_line
                                matches_regex
                                "^.*cppcheck[\\.a-z]* .*Generated.*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some sources to the global unused function check properties and adds
# checks to a newly created external target.
function (cppcheck_test_unused_function_check_unused_struct_member)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} not file_contents
                                variable_contains
                                "--suppress=unusedStructMember")

    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                               CONFIGURE COMMAND cppcheck_configure
                               VERIFY COMMAND cppcheck_verify)

endfunction ()

# Adds some sources to the global unused function check properties and adds
# checks to a newly created external target, but only for warnings.
function (cppcheck_test_unused_function_check_warn_only)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        cppcheck_add_unused_function_check_with_name (global WARN_ONLY)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} not file_contents
                                variable_contains
                                "--error-exitcode=1")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some source files which will be detected as C source files
# and include a header in them, with ${BINARY_DIR}/include
# to be used as the include-directory.
function (cppcheck_test_default_to_c_language_for_headers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIRECTORY "${SOURCE_DIR}/include")
        set (C_HEADER_DIRECTORY "c")
        set (C_HEADER "${C_HEADER_DIRECTORY}/header.h")
        set (C_SOURCE "CSource.c")
        set (CXX_SOURCE "CXXSource.cpp")

        cmake_unit_create_source_file_before_build (NAME "include/${C_HEADER}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_SOURCE}"
                                                    INCLUDES "${C_HEADER}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIRECTORY}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${CXX_SOURCE}"
                                                    INCLUDES "${C_HEADER}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIRECTORY}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}"
                                                    FUNCTIONS "main")

        include_directories ("${INCLUDE_DIRECTORY}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/${C_SOURCE}"
                        "${SOURCE_DIR}/${CXX_SOURCE}"
                        "${INCLUDE_DIRECTORY}/${C_HEADER}")
        cppcheck_target_sources ("${EXECUTABLE}"
                                 INCLUDES "${INCLUDE_DIRECTORY}"
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (C_REGEX "^.*cppcheck.*language=c.*header.h.*$")
        set (CXX_REGEX "^.*cppcheck.*language=c\\+\\+.*header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${C_REGEX})
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                any_line
                                matches_regex
                                ${CXX_REGEX})

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some source files which will be detected as C source files
# and include a header in them, with ${SOURCE_DIR}/include
# to be used as the include-directory.
function (cppcheck_test_detect_c_language_for_headers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIRECTORY "${SOURCE_DIR}/include")
        set (C_HEADER_DIRECTORY "c")
        set (C_HEADER "${C_HEADER_DIRECTORY}/header.h")
        set (C_SOURCE "CSource.c")

        cmake_unit_create_source_file_before_build (NAME "include/${C_HEADER}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_SOURCE}"
                                                    INCLUDES "${C_HEADER}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIRECTORY}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}"
                                                    FUNCTIONS "main")

        include_directories ("${INCLUDE_DIRECTORY}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/${C_SOURCE}"
                        "${INCLUDE_DIRECTORY}/${C_HEADER}")
        cppcheck_target_sources ("${EXECUTABLE}"
                                 INCLUDES "${INCLUDE_DIRECTORY}"
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (C_REGEX "^.*cppcheck.*language=c.*header.h.*$")
        set (CXX_REGEX "^.*cppcheck.*language=c\\+\\+.*header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${C_REGEX})
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                any_line
                                matches_regex
                                ${CXX_REGEX})

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some source files which will be detected as CPP source files
# and include a header in them, with ${BINARY_DIR}/include
# to be used as the include-directory.
function (cppcheck_test_detect_cpp_language_for_headers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIRECTORY "${SOURCE_DIR}/include")
        set (CXX_HEADER_DIRECTORY "cxx")
        set (CXX_HEADER "${CXX_HEADER_DIRECTORY}/header.h")
        set (CXX_SOURCE "CXXSource.cxx")

        cmake_unit_create_source_file_before_build (NAME "include/${CXX_HEADER}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${CXX_SOURCE}"
                                                    INCLUDES "${CXX_HEADER}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIRECTORY}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}"
                                                    FUNCTIONS "main")

        include_directories ("${INCLUDE_DIRECTORY}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/${CXX_SOURCE}"
                        "${INCLUDE_DIRECTORY}/${CXX_HEADER}")
        cppcheck_target_sources ("${EXECUTABLE}"
                                 INCLUDES "${INCLUDE_DIRECTORY}"
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (CXX_REGEX "^.*cppcheck.*language=c\\+\\+.*header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${CXX_REGEX})

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some source files which will be detected as C source files
# and include a header in them, although that header will be a generated file.
function (cppcheck_test_detect_language_of_generated_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (C_HEADER "header.h")
        set (C_SOURCE "CSource.c")

        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME "${C_HEADER}"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_SOURCE}"
                                                    FUNCTIONS "main"
                                                    INCLUDES "${C_HEADER}"
                                                    INCLUDE_DIRECTORIES
                                                    "${BINARY_DIR}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        include_directories ("${BINARY_DIR}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/${C_SOURCE}"
                        "${BINARY_DIR}/${C_HEADER}")
        cppcheck_target_sources ("${EXECUTABLE}" INCLUDES "${BINARY_DIR}"
                                 CHECK_GENERATED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (C_REGEX "^.*cppcheck.*language=c.*header.h.*$")
        set (CXX_REGEX "^.*cppcheck.*language=c\\+\\+.*header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${C_REGEX})
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                any_line
                                matches_regex
                                ${CXX_REGEX})

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some source files which will be detected as C source files
# and include a header in them, with ${SOURCE_DIR}/include
# to be used as the include-directory.
function (cppcheck_test_force_language_overrides_detected_header_language)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIRECTORY "${SOURCE_DIR}/include")
        set (C_HEADER "c/header.h")
        set (C_SOURCE "CSource.c")

        cmake_unit_create_source_file_before_build (NAME "include/${C_HEADER}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_SOURCE}"
                                                    INCLUDES "${C_HEADER}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIRECTORY}"
                                                    FUNCTIONS "main")
        include_directories ("${INCLUDE_DIRECTORY}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/${C_SOURCE}"
                        "${INCLUDE_DIRECTORY}/${C_HEADER}")
        cppcheck_target_sources ("${EXECUTABLE}"
                                 INCLUDES "${INCLUDE_DIRECTORY}"
                                 FORCE_LANGUAGE CXX
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*language=c\\+\\+.*$")

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Tests getting back a list of unused function checks, even if they
# haven't been activated yet.
function (cppcheck_test_get_unused_function_checks)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (one SOURCES ${SOURCES})
        cppcheck_add_to_unused_function_check (two SOURCES ${SOURCES})
        cppcheck_get_unused_function_checks (UNUSED_CHECKS)
        cmake_unit_assert_that (UNUSED_CHECKS list_contains_value STRING EQUAL
                                "one")
        cmake_unit_assert_that (UNUSED_CHECKS
                                list_contains_value
                                STRING
                                EQUAL
                                "two")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_config_only_test (CONFIGURE
                                               COMMAND
                                               cppcheck_configure)

    endif ()

endfunction ()

# Adds multiple unused function checks and checks that both their targets
# are added.
function (cppcheck_test_multiple_unused_function_checks_coexist)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (FIRST_SOURCE_GROUP "${SOURCE_DIR}/1.cpp")
        set (SECOND_SOURCE_GROUP "${SOURCE_DIR}/2.cpp")
        cmake_unit_create_source_file_before_build (NAME "1.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "2.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (one SOURCES
                                               ${FIRST_SOURCE_GROUP})
        cppcheck_add_to_unused_function_check (two SOURCES
                                               ${SECOND_SOURCE_GROUP})
        cppcheck_add_unused_function_check_with_name (one)
        cppcheck_add_unused_function_check_with_name (two)
        cmake_unit_assert_that (one target_exists)
        cmake_unit_assert_that (two target_exists)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*enable=unusedFunction.*1.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*touch.*one.cppcheck-unused.stamp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck.*enable=unusedFunction.*2.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*touch.*two.cppcheck-unused.stamp.*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds some source files which will be detected as C source files
# and include a header in them, with ${BINARY_DIR}/include
# to be used as the include-directory.
function (cppcheck_test_scan_for_both_with_custom_cpp_identifier)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
        set (SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
        set (C_HEADER_FILE_DIRECTORY_NAME "c")
        set (DECLS_HEADER_FILE_NAME "${C_HEADER_FILE_DIRECTORY_NAME}/decls.h")
        set (DECLS_HEADER_FILE_PATH "${INCLUDE_DIR}/${DECLS_HEADER_FILE_NAME}")
        set (BOTH_HEADER_FILE_NAME "${C_HEADER_FILE_DIRECTORY_NAME}/both.h")
        set (BOTH_HEADER_FILE_PATH "${INCLUDE_DIR}/${BOTH_HEADER_FILE_NAME}")
        set (C_HEADER_FILE_NAME "${C_HEADER_FILE_DIRECTORY_NAME}/c.h")
        set (C_HEADER_FILE_PATH "${INCLUDE_DIR}/${C_HEADER_FILE_NAME}")
        set (C_SOURCE_FILE_NAME "CSource.c")
        set (C_SOURCE_FILE_PATH "${SOURCE_DIR}/${C_SOURCE_FILE_NAME}")

        cmake_unit_create_source_file_before_build (NAME
                                                    "${DECLS_HEADER_FILE_NAME}"
                                                    DEFINES "PSQ_IS_CPP"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME
                                                    "${BOTH_HEADER_FILE_NAME}"
                                                    DEFINES "PSQ_IS_CPP"
                                                    INCLUDES
                                                    "${DECLS_HEADER_FILE_NAME}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_HEADER_FILE_NAME}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (NAME "${C_SOURCE_FILE_NAME}"
                                                    INCLUDES
                                                    "${BOTH_HEADER_FILE_NAME}"
                                                    "${C_HEADER_FILE_NAME}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIR}"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")

        include_directories ("${INCLUDE_DIR}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${C_SOURCE_FILE_PATH}"
                        "${BOTH_HEADER_FILE_PATH}"
                        "${DECLS_HEADER_FILE_PATH}"
                        "${C_HEADER_FILE_PATH}")
        cppcheck_target_sources ("${EXECUTABLE}" INCLUDES "${INCLUDE_DIRECTORY}"
                                 CPP_IDENTIFIERS
                                 POLYSQUARE_BEGIN_DECLS
                                 PSQ_IS_CPP
                                 NO_CHECK_UNUSED)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*language=c.*both.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck.*language=c.*c.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck.*language=c\\+\\+.*both.h.*$")

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Sets up an unused function check target so we can check if a stampfile
# is generated later in the build process.
function (cppcheck_test_stampfile_generated_for_unused_function_check)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        cppcheck_add_unused_function_check_with_name (global)
        set (STAMPFILE "${BINARY_DIR}/global.cppcheck-unused.stamp")
        cmake_unit_assert_that ("${STAMPFILE}"
                                item_has_property_with_value
                                SOURCE
                                GENERATED
                                INTEGER
                                EQUAL
                                1)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_assert_that ("${BINARY_DIR}/global.cppcheck-unused.stamp"
                                exists_as_file)

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds an unused function check and a custom target (not added to ALL)
# that it depends on.
function (cppcheck_test_unused_function_check_always_run_after_depends)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/CSource.cpp")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        add_custom_target (custom_dependency
                           COMMAND "${CMAKE_COMMAND}" -E echo "custom_dep")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES}
                                               DEPENDS
                                               custom_dependency)
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents any_line matches_regex
                                "^.*cppcheck.*unused.*$")

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   INVOKE_BUILD OPTIONS TARGET custom_dependency
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# Adds a C, CXX and header file to an unused function check.
function (cppcheck_test_unused_function_check_is_always_cpp)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/CSource.cpp"
             "${SOURCE_DIR}/CXXSource.cpp"
             "${SOURCE_DIR}/Header.h")
        foreach (SOURCE ${SOURCES})
            get_filename_component (BASE "${SOURCE}" NAME)
            cmake_unit_create_source_file_before_build (NAME "${BASE}"
                                                        GENERATING_FILE
                                                        "${_CURRENT_LIST_FILE}")
        endforeach ()

        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES})
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*cppcheck.*unuse.*language=c\\+\\+.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                any_line
                                matches_regex
                                "^.*cppcheck.*unuse.*language=c\\s.*$")

    endfunction ()

    if (CPPCHECK_VERSION VERSION_GREATER 1.57)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

# During the build, create the stampfile as if it already exists
# and ensure that this build rule runs before the global build rule.
function (cppcheck_test_unused_function_check_not_run_if_stampfile_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (cppcheck_configure)

        cppcheck_validate (CONTINUE)
        set (SOURCES "${SOURCE_DIR}/First.cpp")
        cmake_unit_create_source_file_before_build (NAME "First.cpp"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (STAMPFILE "${BINARY_DIR}/global.cppcheck-unused.stamp")
        set (STAMPFILE_PROXY "${STAMPFILE}.stamp")
        add_custom_command (OUTPUT "${STAMPFILE_PROXY}"
                            COMMAND "${CMAKE_COMMAND}" -E touch "${STAMPFILE}"
                            COMMAND
                            "${CMAKE_COMMAND}"
                            -E
                            touch
                            "${STAMPFILE_PROXY}")
        add_custom_target (create_stampfile_first DEPENDS "${STAMPFILE_PROXY}")
        cppcheck_add_to_unused_function_check (global SOURCES ${SOURCES}
                                               TARGETS
                                               create_stampfile_first)
        cppcheck_add_unused_function_check_with_name (global)

    endfunction ()

    function (cppcheck_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (UNUSED_FUNCTION_REGEX
             "^.*cppcheck.*unusedFunction.*First\\.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} not file_contents any_line
                                matches_regex
                                ${UNUSED_FUNCTION_REGEX})

    endfunction ()

    if (HAVE_CPPCHECK)

        cmake_unit_configure_test (PRECONFIGURE OPTIONS
                                                SKIP_GENERATOR_REGEX
                                                "Ninja|NMake.*|Visual.*"
                                   INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND cppcheck_configure
                                   VERIFY COMMAND cppcheck_verify)

    endif ()

endfunction ()

set (CMAKE_FILES
     "${CMAKE_CURRENT_LIST_DIR}/CPPCheck.cmake"
     "${CMAKE_CURRENT_LIST_DIR}/FindCPPCHECK.cmake"
     "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt")
set (MARKDOWN_FILES
     "${CMAKE_CURRENT_LIST_DIR}/LICENSE.md"
     "${CMAKE_CURRENT_LIST_DIR}/README.md")

cmake_module_add_common_targets (NAMESPACE "psq"
                                 CMAKE_FILES ${CMAKE_FILES}
                                 DOCUMENTATION_FILES ${MARKDOWN_FILES})
