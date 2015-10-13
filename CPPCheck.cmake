# /CPPCheck.cmake
#
# Utility functions to add cppcheck static analysis to source files in a
# particular target
#
# See /LICENCE.md for Copyright information

include (CMakeParseArguments)
include ("smspillaz/tooling-cmake-util/PolysquareToolingUtil")

set (CPPCHECK_COMMON_OPTIONS
     --quiet
     --template
     "{file}:{line}: {severity} {id}: {message}"
     --inline-suppr
     --max-configs=1)

macro (cppcheck_validate CONTINUE)

    if (NOT DEFINED CPPCheck_FOUND)

        find_package (CPPCHECK ${ARGN})

    endif ()

    set (${CONTINUE} ${CPPCHECK_FOUND})

endmacro ()

function (_cppcheck_get_commandline COMMANDLINE_RETURN)

    set (COMMANDLINE_SINGLEVAR_ARGS LANGUAGE)
    set (COMMANDLINE_MULTIVAR_ARGS SOURCES OPTIONS)

    cmake_parse_arguments (COMMANDLINE
                           ""
                           "${COMMANDLINE_SINGLEVAR_ARGS}"
                           "${COMMANDLINE_MULTIVAR_ARGS}"
                           ${ARGN})

    if (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

        if (COMMANDLINE_LANGUAGE STREQUAL "C")

            set (LANGUAGE_OPTION --language=c)

        elseif (COMMANDLINE_LANGUAGE STREQUAL "CXX")

            set (LANGUAGE_OPTION --language=c++ -D__cplusplus)

        endif ()

    endif ()

    set (${COMMANDLINE_RETURN}
         "${CPPCHECK_EXECUTABLE}"
         ${COMMANDLINE_OPTIONS}
         ${LANGUAGE_OPTION}
         ${COMMANDLINE_SOURCES}
         PARENT_SCOPE)

endfunction ()

function (_cppcheck_add_normal_check_command TARGET SOURCE)

    set (ADD_NORMAL_CHECK_SINGLEVAR_ARGS LANGUAGE)
    set (ADD_NORMAL_CHECK_MULTIVAR_ARGS OPTIONS DEPENDS)

    cmake_parse_arguments (ADD_NORMAL_CHECK
                           ""
                           "${ADD_NORMAL_CHECK_SINGLEVAR_ARGS}"
                           "${ADD_NORMAL_CHECK_MULTIVAR_ARGS}"
                           ${ARGN})

    # Get a commandline
    psq_forward_options (ADD_NORMAL_CHECK GET_COMMANDLINE_FORWARD_OPTIONS
                         SINGLEVAR_ARGS LANGUAGE
                         MULTIVAR_ARGS OPTIONS)
    _cppcheck_get_commandline (CPPCHECK_COMMAND
                               SOURCES "${SOURCE}"
                               ${GET_COMMANDLINE_FORWARD_OPTIONS})

    # cppcheck (c) and cppcheck (cxx) can both be run on one source
    string (TOLOWER "${ADD_NORMAL_CHECK_LANGUAGE}" LANGUAGE_LOWER)
    psq_forward_options (ADD_NORMAL_CHECK RUN_TOOL_ON_SOURCE_FORWARD
                         MULTIVAR_ARGS DEPENDS)
    psq_run_tool_on_source (${TARGET} "${SOURCE}" "cppcheck (${LANGUAGE_LOWER})"
                            COMMAND ${CPPCHECK_COMMAND}
                            ${RUN_TOOL_ON_SOURCE_FORWARD})

endfunction ()

function (_cppcheck_add_checks_to_target TARGET)

    set (ADD_CHECKS_OPTIONS CHECK_GENERATED)
    set (ADD_CHECKS_SINGLEVAR_OPTIONS FORCE_LANGUAGE)
    set (ADD_CHECKS_MULTIVAR_OPTIONS
         SOURCES
         OPTIONS
         INCLUDES
         DEFINES
         CPP_IDENTIFIERS
         DEPENDS)

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

    psq_forward_options (ADD_CHECKS ADD_NORMAL_CHECK_COMMAND_FORWARD
                         MULTIVAR_ARGS DEPENDS)

    # For C headers, pass --language=c
    foreach (SOURCE ${C_SOURCES})

        _cppcheck_add_normal_check_command (${TARGET} "${SOURCE}"
                                            OPTIONS
                                            ${ADD_CHECKS_OPTIONS}
                                            LANGUAGE C
                                            ${ADD_NORMAL_CHECK_COMMAND_FORWARD})

    endforeach ()

    # For CXX headers, pass --language=c++ and -D__cplusplus
    foreach (SOURCE ${CXX_SOURCES})

        _cppcheck_add_normal_check_command (${TARGET} "${SOURCE}"
                                            OPTIONS
                                            ${ADD_CHECKS_OPTIONS}
                                            LANGUAGE CXX
                                            ${ADD_NORMAL_CHECK_COMMAND_FORWARD})

    endforeach ()

endfunction ()

# cppcheck_add_to_unused_function_check
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
#                      guaranteed to run only after those sources have been
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

    # Saves some space
    set (W ${WHICH})
    psq_append_to_global_property (CPPCHECK_${W}_UNUSED_FUNCTION_CHECK_SOURCES
                                   LIST ${FILTERED_CHECK_SOURCES})
    psq_append_to_global_property (CPPCHECK_${W}_UNUSED_FUNCTION_CHECK_INCLUDES
                                   LIST ${UNUSED_CHECK_INCLUDES})
    psq_append_to_global_property (CPPCHECK_${W}_UNUSED_FUNCTION_CHECK_DEFINES
                                   LIST ${UNUSED_CHECK_DEFINES})
    psq_append_to_global_property (CPPCHECK_${W}_UNUSED_FUNCTION_CHECK_TARGETS
                                   LIST ${UNUSED_CHECK_TARGETS})

endfunction ()

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

endfunction ()

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
# [Optional] DEPENDS : Targets on which this unused function check depends.
function (cppcheck_add_unused_function_check_with_name WHICH)

    cppcheck_validate (CPPCHECK_AVAILABLE)

    if (NOT CPPCHECK_AVAILABLE)

        return ()

    endif ()

    get_property (_CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES
                  GLOBAL
                  PROPERTY CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES)

    set (HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME FALSE)

    foreach (NAME ${_CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES})

        if (NAME STREQUAL ${WHICH})

            set (HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME TRUE)
            break ()

        endif ()

    endforeach ()

    psq_assert_set (HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME
                    "No unused function check with name ${WHICH} exists")

    get_property (_CPPCHECK_UNUSED_FUNCTION_SOURCES_SET
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_SOURCES
                  SET)

    psq_assert_set (_CPPCHECK_UNUSED_FUNCTION_SOURCES_SET
                    "No unused function sources registered, "
                    "they should be registered using "
                    "cppcheck_add_to_global_unused_function_check "
                    "before calling "
                    "cppcheck_add_global_unused_function_check_to_"
                    "target")

    set (UNUSED_CHECK_OPTION_ARGS WARN_ONLY)
    set (UNUSED_CHECK_MULTIVAR_ARGS INCLUDES DEFINES DEPENDS)

    cmake_parse_arguments (UNUSED_CHECK
                           "${UNUSED_CHECK_OPTION_ARGS}"
                           ""
                           "${UNUSED_CHECK_MULTIVAR_ARGS}"
                           ${ARGN})

    get_property (_CPPCHECK_UNUSED_FUNCTION_SOURCES
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_SOURCES)

    get_property (_CPPCHECK_UNUSED_FUNCTION_INCLUDES
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_INCLUDES)

    get_property (_CPPCHECK_UNUSED_FUNCTION_DEFINITIONS
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_DEFINES)

    get_property (_CPPCHECK_UNUSED_FUNCTION_TARGETS
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_TARGETS)

    set (OPTIONS
         ${CPPCHECK_COMMON_OPTIONS}
         --enable=unusedFunction)

    if (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

        list (APPEND OPTIONS --language=c++)

    endif ()

    psq_add_switch (OPTION UNUSED_CHECK_WARN_ONLY
                    ON --error-exitcode=1)

    list (APPEND UNUSED_CHECK_INCLUDES
          ${_CPPCHECK_UNUSED_FUNCTION_INCLUDES})

    psq_append_each_to_options_with_prefix (OPTIONS -I
                                            LIST
                                            ${UNUSED_CHECK_INCLUDES})

    list (APPEND UNUSED_CHECK_DEFINES
          ${_CPPCHECK_UNUSED_FUNCTION_DEFINITIONS})

    psq_append_each_to_options_with_prefix (OPTIONS -D
                                            LIST
                                            ${UNUSED_CHECK_DEFINES})

    _cppcheck_get_commandline (CPPCHECK_COMMAND
                               SOURCES ${_CPPCHECK_UNUSED_FUNCTION_SOURCES}
                               OPTIONS ${OPTIONS})

    set (STAMPFILE "${CMAKE_CURRENT_BINARY_DIR}/${WHICH}.cppcheck-unused.stamp")

    add_custom_command (OUTPUT ${STAMPFILE}
                        COMMAND ${CPPCHECK_COMMAND}
                        COMMAND "${CMAKE_COMMAND}" -E touch ${STAMPFILE}
                        DEPENDS
                        ${_CPPCHECK_UNUSED_FUNCTION_SOURCES}
                        ${_CPPCHECK_UNUSED_FUNCTION_TARGETS}
                        ${UNUSED_CHECK_DEPENDS}
                        COMMENT "Running unused function check: ${WHICH}")

    add_custom_target (${WHICH} ALL SOURCES ${STAMPFILE})

endfunction ()

# cppcheck_sources
#
# Run CPPCheck on the sources as specified in SOURCES, reporting any
# warnings or errors on stderr.
#
# TARGET : Target to attach checks to
# [Mandatory] SOURCES : A list of sources to scan.
# [Optional] WARN_ONLY : Don't error out, just warn on potential problems.
# [Optional] NO_CHECK_STYLE : Don't check for style issues.
# [Optional] NO_CHECK_UNUSED : Don't check for unused functions.
# [Optional] CHECK_GENERATED : Also check generated sources.
# [Optional] CHECK_GENERATED_FOR_UNUSED: Check generated sources later for
#            the unused function check. This option works independently of
#            the CHECK_GENERATED option.
# [Optional] FORCE_LANGUAGE : Force all scanned files to be a certain language,
#                             eg C, CXX
# [Optional] INCLUDES : Include directories to search.
# [Optional] DEFINES : Set compile time definitions.
# [Optional] CPP_IDENTIFIERS : A list of identifiers which indicate that
#                              any header file specified in the source
#                              list is definitely a C++ header file
# [Optional] DEPENDS : Targets or source files to depend on.
function (cppcheck_sources TARGET)

    cppcheck_validate (CPPCHECK_AVAILABLE)

    if (NOT CPPCHECK_AVAILABLE)

        return ()

    endif ()

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
         CPP_IDENTIFIERS
         DEPENDS)
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
    psq_add_switch (CPPCHECK_OPTIONS CPPCHECK_NO_CHECK_UNUSED
                    OFF --enable=unusedFunction
                    ON --suppress=unusedStructMember)

    psq_append_each_to_options_with_prefix (CPPCHECK_OPTIONS -I
                                            LIST
                                            ${CPPCHECK_INCLUDES})

    psq_append_each_to_options_with_prefix (CPPCHECK_OPTIONS -D
                                            LIST
                                            ${CPPCHECK_DEFINES})

    psq_forward_options (CPPCHECK ADD_CHECKS_TO_TARGET_FORWARD
                         SINGLEVAR_ARGS FORCE_LANGUAGE
                         MULTIVAR_ARGS OPTIONS
                                       INCLUDES
                                       DEFINES
                                       CPP_IDENTIFIERS
                                       DEPENDS)
    _cppcheck_add_checks_to_target (${TARGET}
                                    SOURCES ${FILTERED_CHECK_SOURCES}
                                    ${ADD_CHECKS_TO_TARGET_FORWARD})

endfunction ()

# cppcheck_target_sources
#
# Run CPPCheck on all the sources for a particular TARGET, reporting any
# warnings or errors on stderr
#
# TARGET : Target to check sources on
# [Optional] WARN_ONLY : Don't error out, just warn on potential problems.
# [Optional] NO_CHECK_STYLE : Don't check for style issues
# [Optional] NO_CHECK_UNUSED : Don't check for unused functions
# [Optional] CHECK_GENERATED : Also check generated sources.
# [Optional] CHECK_GENERATED_FOR_UNUSED: Check generated sources later for
#            the unused function check. This option works independently of
#            the CHECK_GENERATED option.
# [Optional] FORCE_LANGUAGE : Force all scanned files to be a certain language,
#                             eg C, CXX
# [Optional] INCLUDES : Check header files in specified include directories.
# [Optional] DEFINES : Set compile time definitions.
# [Optional] CPP_IDENTIFIERS : A list of identifiers which indicate that
#                              any header file specified in the target's
#                              sources is definitely a C++ header file
# [Optional] DEPENDS : Targets or source files to depend on.
function (cppcheck_target_sources TARGET)

    psq_strip_extraneous_sources (files_to_check ${TARGET})
    message (STATUS "To check: ${files_to_check}")
    cppcheck_sources (${TARGET}
                      SOURCES ${files_to_check}
                      ${ARGN})

endfunction ()

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
# [Optional] CHECK_GENERATED : Add generated files to the unused function check.
function (cppcheck_add_target_sources_to_unused_function_check TARGET
                                                               WHICH)

    psq_strip_extraneous_sources (files_to_check ${TARGET})
    cppcheck_add_to_unused_function_check (${WHICH}
                                           TARGETS ${TARGET}
                                           SOURCES ${files_to_check}
                                           ${ARGN})

endfunction ()


