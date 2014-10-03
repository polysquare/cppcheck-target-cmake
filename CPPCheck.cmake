#
# CPPCheck.cmake
#
# Utility functions to add cppcheck static analysis to source files in a
# particular target
#
# See LICENCE.md for Copyright information.

include (CMakeParseArguments)
include (${CMAKE_CURRENT_LIST_DIR}/tooling-cmake-util/PolysquareToolingUtil.cmake)

set (CPPCHECK_COMMON_OPTIONS
     --quiet
     --template "{file}:{line}: {severity} {id}: {message}"
     --inline-suppr
     --max-configs=1)

function (_validate_cppcheck CONTINUE)

    if (DEFINED CPPCHECK_VERSION)

        set (${CONTINUE} TRUE PARENT_SCOPE)
        return ()

    endif (DEFINED CPPCHECK_VERSION)

    if (NOT CPPCHECK_EXECUTABLE)

        message (SEND_ERROR "cppcheck binary was not found, make sure "
                            "to call find_program (cppcheck) before "
                            "using this module")

    else (NOT CPPCHECK_EXECUTABLE)

        set (${CONTINUE} TRUE PARENT_SCOPE)

        # Check the version of cppcheck. If it is < 1.58 output a warning about
        # detecting the language of header files
        execute_process (COMMAND ${CPPCHECK_EXECUTABLE} --version
                         OUTPUT_VARIABLE CPPCHECK_VERSION_OUTPUT)

        string (LENGTH "Cppcheck " CPPCHECK_VERSION_HEADER_LENGTH)
        set (CPPCHECK_VERSION_LENGTH 4)
        string (SUBSTRING "${CPPCHECK_VERSION_OUTPUT}"
                ${CPPCHECK_VERSION_HEADER_LENGTH} 
                ${CPPCHECK_VERSION_LENGTH}
                CPPCHECK_READ_VERSION)

        set (CPPCHECK_VERSION ${CPPCHECK_READ_VERSION} CACHE STRING "" FORCE)
        mark_as_advanced (CPPCHECK_VERSION)

        message (STATUS "Detected cppcheck version ${CPPCHECK_VERSION}")

        if (${CPPCHECK_VERSION} VERSION_LESS 1.58)

            message (WARNING "Only cppcheck versions >= 1.58 support specifying"
                             " a language for analysis. You may encounter false"
                             " positives when scanning header files if cppcheck"
                             " is unable to determine their source language."
                             " Consider upgrading to a newer version of"
                             " cppcheck, such that this script can specify the"
                             " language of your header files after detecting"
                             " them")

        endif (${CPPCHECK_VERSION} VERSION_LESS 1.58)

    endif (NOT CPPCHECK_EXECUTABLE)

endfunction (_validate_cppcheck)

function (_cppcheck_get_commandline COMMANDLINE_RETURN)

    set (COMMANDLINE_MULTIVAR_OPTIONS SOURCES OPTIONS)

    cmake_parse_arguments (COMMANDLINE
                           ""
                           ""
                           "${COMMANDLINE_MULTIVAR_OPTIONS}"
                           ${ARGN})

    set (${COMMANDLINE_RETURN}
         ${CPPCHECK_EXECUTABLE}
         ${COMMANDLINE_OPTIONS}
         ${COMMANDLINE_SOURCES}
         PARENT_SCOPE)

endfunction ()

function (_cppcheck_add_normal_check_command TARGET
                                             WHEN)

    set (ADD_NORMAL_CHECK_MULTIVAR_OPTIONS SOURCES OPTIONS)

    cmake_parse_arguments (ADD_NORMAL_CHECK
                           ""
                           ""
                           "${ADD_NORMAL_CHECK_MULTIVAR_OPTIONS}"
                           ${ARGN})

    # Silently return if we don't have any sources to scan here
    if (NOT ADD_NORMAL_CHECK_SOURCES)

        return ()

    endif (NOT ADD_NORMAL_CHECK_SOURCES)

    _cppcheck_get_commandline (CPPCHECK_COMMAND
                               SOURCES ${ADD_NORMAL_CHECK_SOURCES}
                               OPTIONS ${ADD_NORMAL_CHECK_OPTIONS})

    add_custom_command (TARGET ${TARGET}
                        ${WHEN}
                        COMMAND
                        ${CPPCHECK_COMMAND})

endfunction (_cppcheck_add_normal_check_command)

function (_cppcheck_add_checks_to_target TARGET
                                         WHEN)

    set (ADD_CHECKS_OPTIONS CHECK_GENERATED)
    set (ADD_CHECKS_SINGLEVAR_OPTIONS FORCE_LANGUAGE)
    set (ADD_CHECKS_MULTIVAR_OPTIONS
         SOURCES
         OPTIONS
         INCLUDES
         DEFINES
         CPP_IDENTIFIERS)

    cmake_parse_arguments (ADD_CHECKS
                           "${ADD_CHECKS_OPTIONS}"
                           "${ADD_CHECKS_SINGLEVAR_OPTIONS}"
                           "${ADD_CHECKS_MULTIVAR_OPTIONS}"
                           ${ARGN})

    psq_forward_options (ADD_CHECKS
                         SORT_SOURCES_OPTIONS
                         SINGLEVAR_ARGS FORCE_LANGUAGE
                         MULTIVAR_ARGS SOURCES INCLUDES CPP_IDENTIFIERS)
    psq_sort_sources_to_languages (C_SOURCES CXX_SOURCES HEADERS
                                   ${SORT_SOURCES_OPTIONS})

    if (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

        set (C_LANGUAGE_OPTION --language=c)
        set (CXX_LANGUAGE_OPTION --language=c++)

    endif (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

    # For C headers, pass --language=c
    _cppcheck_add_normal_check_command (${TARGET} ${WHEN}
                                        SOURCES ${C_SOURCES}
                                        OPTIONS
                                        ${ADD_CHECKS_OPTIONS}
                                        ${C_LANGUAGE_OPTION})

    # For CXX headers, pass --language=c++ and -D__cplusplus
    _cppcheck_add_normal_check_command (${TARGET} ${WHEN}
                                        SOURCES ${CXX_SOURCES}
                                        OPTIONS
                                        ${ADD_CHECKS_OPTIONS}
                                        ${CXX_LANGUAGE_OPTION}
                                        -D__cplusplus)

endfunction ()

# cppcheck_add_to_global_unused_function_check
#
# Adds the source files as specified in SOURCES to the global
# list of source files to check during the global unused function
# target
#
# WHICH : A unique identifier for the unused function check to which
#         these sources, targets and includes should be added to.
# [Optional] TARGETS : A list of targets which the check should depend on.
#                      Ideally this should be a target which would cause
#                      the relevant sources to be re-generated or re-built.
#                      If it is, then the unused function check rule is
#                      guarunteed to run only after those sources have been
#                      updated.
# [Optional] SOURCES : A variable containing a list of sources
# [Optional] INCLUDES : A list of include directories used to
#                       build these sources.
# [Optional] DEFINES : Set compile time definitions.
# [Optional] CHECK_GENERATED: Whether to check generated sources too.
function (cppcheck_add_to_unused_function_check WHICH)

    set (UNUSED_CHECK_OPTION_ARGS
         CHECK_GENERATED)
    set (UNUSED_CHECK_MULTIVAR_ARGS
         TARGETS
         SOURCES
         DEFINES
         INCLUDES)

    cmake_parse_arguments (UNUSED_CHECK
                           "${UNUSED_CHECK_OPTION_ARGS}"
                           ""
                           "${UNUSED_CHECK_MULTIVAR_ARGS}"
                           ${ARGN})

    psq_handle_check_generated_option (UNUSED_CHECK FILTERED_CHECK_SOURCES
                                       SOURCES ${UNUSED_CHECK_SOURCES})

    psq_append_to_global_property_unique (CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES
                                          ${WHICH})

    psq_append_to_global_property (CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_SOURCES
                                   LIST ${FILTERED_CHECK_SOURCES})
    psq_append_to_global_property (CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_INCLUDES
                                   LIST ${UNUSED_CHECK_INCLUDES})
    psq_append_to_global_property (CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_DEFINES
                                   LIST ${UNUSED_CHECK_DEFINES})
    psq_append_to_global_property (CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_TARGETS
                                   LIST ${UNUSED_CHECK_TARGETS})

endfunction (cppcheck_add_to_unused_function_check)

# cppcheck_get_unused_function_checks
#
# Get a list of all unused function checks that have been added, even if
# their targets have not yet been added.
#
# RESULT_VARIABLE: A variable in which to store the resulting list.
function (cppcheck_get_unused_function_checks RESULT_VARIABLE)

    get_property (UNUSED_CHECKS
                  GLOBAL
                  PROPERTY CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES)

    set (${RESULT_VARIABLE} ${UNUSED_CHECKS} PARENT_SCOPE)

endfunction (cppcheck_get_unused_function_checks)

# cppcheck_add_unused_function_check_with_name
#
# Indicates that we have finished collecting sources for a particular global
# unused function check and a target with the same name as the identifier
# should be added to perform that check.
#
# WHICH : A unique identifier for the unused function check.
# [Optional] WARN_ONLY : Only print warnings if there are unused functions,
#                        do not error out
# [Optional] INCLUDES : Include directories to search when analyzing.
# [Optional] DEFINES : Set compile time definitions.
function (cppcheck_add_unused_function_check_with_name WHICH)

    _validate_cppcheck (CPPCHECK_AVAILABLE)

    if (NOT CPPCHECK_AVAILABLE)

        return ()

    endif ()

    get_property (_cppcheck_unused_function_check_names
                  GLOBAL
                  PROPERTY CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES)

    set (HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME FALSE)

    foreach (NAME ${_cppcheck_unused_function_check_names})

        if (NAME STREQUAL ${WHICH})

            set (HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME TRUE)
            break ()

        endif (NAME STREQUAL ${WHICH})

    endforeach ()

    psq_assert_set (HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME
                    "No unused function check with name ${WHICH} exists")

    get_property (_cppcheck_unused_function_sources_set
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_SOURCES
                  SET)

    psq_assert_set (_cppcheck_unused_function_sources_set
                    "No unused function sources registered, "
                    "they should be registered using "
                    "cppcheck_add_to_global_unused_function_check "
                    "before calling "
                    "cppcheck_add_global_unused_function_check_to_"
                    "target")

    set (OPTIONAL_OPTIONS WARN_ONLY)
    set (MULTIVALUE_OPTIONS
         INCLUDES
         DEFINES)

    cmake_parse_arguments (UNUSED_CHECK
                           "${OPTIONAL_OPTIONS}"
                           ""
                           "${MULTIVALUE_OPTIONS}"
                           ${ARGN})

    get_property (_cppcheck_unused_function_sources
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_SOURCES)

    get_property (_cppcheck_unused_function_includes
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_INCLUDES)

    get_property (_cppcheck_unused_function_definitions
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_DEFINES)

    get_property (_cppcheck_unused_function_targets
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_TARGETS)

    set (OPTIONS
         ${CPPCHECK_COMMON_OPTIONS}
         --enable=unusedFunction)

    if (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

        list (APPEND OPTIONS --language=c++)

    endif (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

    psq_add_switch (OPTION UNUSED_CHECK_WARN_ONLY
                    ON --error-exitcode=1)

    list (APPEND UNUSED_CHECK_INCLUDES
          ${_cppcheck_unused_function_includes})

    psq_append_each_to_options_with_prefix (OPTIONS -I
                                            LIST
                                            ${UNUSED_CHECK_INCLUDES})

    list (APPEND UNUSED_CHECK_DEFINES
          ${_cppcheck_unused_function_definitions})

    psq_append_each_to_options_with_prefix (OPTIONS -D
                                            LIST
                                            ${UNUSED_CHECK_DEFINES})

    _cppcheck_get_commandline (CPPCHECK_COMMAND
                               SOURCES ${_cppcheck_unused_function_sources}
                               OPTIONS ${OPTIONS})

    set (STAMPFILE ${CMAKE_CURRENT_BINARY_DIR}/${WHICH}.stamp)

    add_custom_command (OUTPUT ${STAMPFILE}
                        COMMAND ${CPPCHECK_COMMAND}
                        COMMAND ${CMAKE_COMMAND} -E touch ${STAMPFILE}
                        DEPENDS ${_cppcheck_unused_function_sources}
                        COMMENT "Running unused function check: ${WHICH}")

    add_custom_target (${WHICH} ALL
                       DEPENDS
                       ${STAMPFILE})

    if (_cppcheck_unused_function_targets)

        add_dependencies (${WHICH} ${_cppcheck_unused_function_targets})

    endif (_cppcheck_unused_function_targets)

endfunction (cppcheck_add_unused_function_check_with_name)

# cppcheck_sources
#
# Run CPPCheck on the sources as specified in SOURCES, reporting any
# warnings or errors on stderr.
#
# TARGET : Target to attach checks to
# [Mandatory] SOURCES : A list of sources to scan.
# [Optional] WARN_ONLY : Don't error out, just warn on potential problems.
# [Optional] NO_CHECK_STYLE : Don't check for style issues.
# [Optional] CHECK_UNUSED : Check for unused functions.
# [Optional] CHECK_GENERATED : Also check generated sources.
# [Optional] CHECK_GENERATED_FOR_UNUSED: Check generated sources later for
#            the unused function check. This option works independently of
#            the CHECK_GENERATED option.
# [Optional] FORCE_LANGUAGE : Force all scanned files to be a certain language,
#                             e.g. C, CXX
# [Optional] INCLUDES : Include directories to search.
# [Optional] DEFINES : Set compile time definitions.
# [Optional] CPP_IDENTIFIERS : A list of identifiers which indicate that
#                              any header file specified in the source
#                              list is definitely a C++ header file
function (cppcheck_sources TARGET)

    _validate_cppcheck (CPPCHECK_AVAILABLE)

    if (NOT CPPCHECK_AVAILABLE)

        return ()

    endif (NOT CPPCHECK_AVAILABLE)

    set (OPTIONAL_OPTIONS
         WARN_ONLY
         NO_CHECK_STYLE
         NO_CHECK_UNUSED
         CHECK_GENERATED
         CHECK_GENERATED_FOR_UNUSED)
    set (SINGLEVALUE_OPTIONS FORCE_LANGUAGE)
    set (MULTIVALUE_OPTIONS
         INCLUDES
         DEFINES
         SOURCES
         CPP_IDENTIFIERS)
    cmake_parse_arguments (CPPCHECK
                           "${OPTIONAL_OPTIONS}"
                           "${SINGLEVALUE_OPTIONS}"
                           "${MULTIVALUE_OPTIONS}"
                           ${ARGN})

    psq_handle_check_generated_option (CPPCHECK FILTERED_CHECK_SOURCES
                                       SOURCES ${CPPCHECK_SOURCES})

    psq_assert_set (FILTERED_CHECK_SOURCES
                    "SOURCES must be set to either native sources "
                    "or generated sources with the CHECK_GENERATED flag set "
                    "when using cppcheck_sources")

    set (CPPCHECK_OPTIONS
         ${CPPCHECK_COMMON_OPTIONS}
         --enable=performance
         --enable=portability)

    psq_add_switch (CPPCHECK_OPTIONS CPPCHECK_WARN_ONLY
                    OFF --error-exitcode=1)
    psq_add_switch (CPPCHECK_OPTIONS CPPCHECK_NO_CHECK_STYLE
                    OFF --enable=style)
    psq_add_switch (CPPCHECK_OPTIONS CPPCHECK_CHECK_UNUSED
                    ON --enable=unusedFunction
                    OFF --suppress=unusedStructMember)

    psq_append_each_to_options_with_prefix (CPPCHECK_OPTIONS -I
                                            LIST
                                            ${CPPCHECK_INCLUDES})

    psq_append_each_to_options_with_prefix (CPPCHECK_OPTIONS -D
                                            LIST
                                            ${CPPCHECK_DEFINES})

    psq_get_target_command_attach_point (${TARGET} WHEN)

    _cppcheck_add_checks_to_target (${TARGET}
                                    ${WHEN}
                                    SOURCES ${FILTERED_CHECK_SOURCES}
                                    OPTIONS ${CPPCHECK_OPTIONS}
                                    INCLUDES ${CPPCHECK_INCLUDES}
                                    DEFINES ${CPPCHECK_DEFINES}
                                    CPP_IDENTIFIERS ${CPPCHECK_CPP_IDENTIFIERS}
                                    FORCE_LANGUAGE ${CPPCHECK_FORCE_LANGUAGE})

endfunction (cppcheck_sources)

# cppcheck_target_sources
#
# Run CPPCheck on all the sources for a particular TARGET, reporting any
# warnings or errors on stderr
#
# TARGET : Target to check sources on
# [Optional] WARN_ONLY : Don't error out, just warn on potential problems.
# [Optional] NO_CHECK_STYLE : Don't check for style issues
# [Optional] CHECK_UNUSED : Check for unused functions
# [Optional] CHECK_GENERATED : Also check generated sources.
# [Optional] CHECK_GENERATED_FOR_UNUSED: Check generated sources later for
#            the unused function check. This option works independently of
#            the CHECK_GENERATED option.
# [Optional] FORCE_LANGUAGE : Force all scanned files to be a certain language,
#                             e.g. C, CXX
# [Optional] INCLUDES : Check header files in specified include directories.
# [Optional] DEFINES : Set compile time definitions.
# [Optional] CPP_IDENTIFIERS : A list of identifiers which indicate that
#                              any header file specified in the target's
#                              sources is definitely a C++ header file
function (cppcheck_target_sources TARGET)

    psq_strip_add_custom_target_sources (_files_to_check ${TARGET})

    cppcheck_sources (${TARGET}
                      SOURCES ${_files_to_check}
                      ${ARGN})

endfunction (cppcheck_target_sources)

# cppcheck_add_target_sources_to_unused_function_check
#
# Adds sources files attached to the specified TARGET to
# the unused function check specified by WHICH.
#
# TARGET : Target with the source files to add to the unused
#          function check
# WHICH : The name of the unused function check to add the
#         source files to.
# [Optional] INCLUDES : Include directories to scan when parsing
#            the sources for this target.
# [Optional] DEFINES : Set compile time definitions.
# [Optional] NO_CHECK_GENERATED : Do not add generated files
#            to the unused function check.
function (cppcheck_add_target_sources_to_unused_function_check TARGET
                                                               WHICH)

    psq_strip_add_custom_target_sources (_files_to_check ${TARGET})

    cppcheck_add_to_unused_function_check (${WHICH}
                                           TARGETS ${TARGET}
                                           SOURCES ${_files_to_check}
                                           ${ARGN})

endfunction ()


