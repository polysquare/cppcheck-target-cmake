#
# CPPCheck.cmake
#
# Utility functions to add cppcheck static analysis to source files in a
# particular target
#
# See LICENCE.md for Copyright information.

include (CMakeParseArguments)

set (CPPCHECK_COMMON_OPTIONS
     --quiet
     --template "{file}:{line}: {severity} {id}: {message}"
     --inline-suppr
     --max-configs=1)

function (_validate_cppcheck CONTINUE)

    if (NOT CPPCHECK_EXECUTABLE)

        message (SEND_ERROR "cppcheck binary was not found, make sure "
                            "to call find_program (cppcheck) before "
                            "using this module")

    else (NOT CPPCHECK_EXECUTABLE)

        set (${CONTINUE} TRUE PARENT_SCOPE)

    endif (NOT CPPCHECK_EXECUTABLE)

endfunction (_validate_cppcheck)

function (_filter_out_generated_sources RESULT_VARIABLE)

    set (FILTER_OUT_MUTLIVAR_OPTIONS SOURCES)

    cmake_parse_arguments (FILTER_OUT
                           ""
                           ""
                           "${FILTER_OUT_MUTLIVAR_OPTIONS}"
                           ${ARGN})

    set (${RESULT_VARIABLE} PARENT_SCOPE)
    set (FILTERED_SOURCES)

    foreach (SOURCE ${FILTER_OUT_SOURCES})

        get_property (SOURCE_IS_GENERATED
                      SOURCE ${SOURCE}
                      PROPERTY GENERATED)

        if (NOT SOURCE_IS_GENERATED)

            list (APPEND FILTERED_SOURCES ${SOURCE})

        endif (NOT SOURCE_IS_GENERATED)

    endforeach ()

    set (${RESULT_VARIABLE} ${FILTERED_SOURCES} PARENT_SCOPE)

endfunction (_filter_out_generated_sources)

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

function (_cppcheck_add_checks_to_target TARGET
                                         WHEN)

    set (ADD_CHECKS_OPTIONS CHECK_GENERATED)
    set (ADD_CHECKS_MULTIVAR_OPTIONS SOURCES OPTIONS)

    cmake_parse_arguments (ADD_CHECKS_TO_TARGET
                           ""
                           "${ADD_CHECKS_SINGLEVAR_OPTIONS}"
                           "${ADD_CHECKS_MULTIVAR_OPTIONS}"
                           ${ARGN})

    set (EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND)

    _cppcheck_get_commandline (CPPCHECK_COMMAND
                               SOURCES ${ADD_CHECKS_TO_TARGET_SOURCES}
                               OPTIONS ${ADD_CHECKS_TO_TARGET_OPTIONS})

    add_custom_command (TARGET ${TARGET}
                        ${WHEN}
                        COMMAND
                        ${CPPCHECK_COMMAND}
                        ${EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND})

endfunction (_cppcheck_add_checks_to_target)

function (_append_to_global_property_unique PROPERTY ITEM)

    get_property (GLOBAL_PROPERTY
                  GLOBAL
                  PROPERTY ${PROPERTY})

    set (LIST_CONTAINS_ITEM FALSE)

    foreach (LIST_ITEM ${GLOBAL_PROPERTY})

        if (LIST_ITEM STREQUAL ${ITEM})

            set (LIST_CONTAINS_ITEM TRUE)
            break ()

        endif (LIST_ITEM STREQUAL ${ITEM})

    endforeach ()

    if (NOT LIST_CONTAINS_ITEM)

        set_property (GLOBAL
                      APPEND
                      PROPERTY ${PROPERTY}
                      ${ITEM})

    endif (NOT LIST_CONTAINS_ITEM)

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
# [Optional] CHECK_GENERATED: Whether to check generated sources too.
function (cppcheck_add_to_unused_function_check WHICH)

    set (UNUSED_CHECK_OPTION_ARGS
         CHECK_GENERATED)
    set (UNUSED_CHECK_MULTIVAR_ARGS
         TARGETS
         SOURCES
         INCLUDES)

    cmake_parse_arguments (UNUSED_CHECK
                           "${UNUSED_CHECK_OPTION_ARGS}"
                           ""
                           "${UNUSED_CHECK_MULTIVAR_ARGS}"
                           ${ARGN})

    set (FILTERED_CHECK_SOURCES)

    # First case: We're checking generated sources, so
    # we can just check all passed in sources.
    if (UNUSED_CHECK_CHECK_GENERATED)

        set (FILTERED_CHECK_SOURCES ${UNUSED_CHECK_SOURCES})

    # Second case: We only want to check real sources,
    # so filter out generated ones.
    else (UNUSED_CHECK_CHECK_GENERATED)

        _filter_out_generated_sources (FILTERED_CHECK_SOURCES
                                       SOURCES ${UNUSED_CHECK_SOURCES})

    endif (UNUSED_CHECK_CHECK_GENERATED)

    _append_to_global_property_unique (CPPCHECK_UNUSED_FUNCTION_CHECK_NAMES
                                       ${WHICH})

    foreach (SOURCE ${FILTERED_CHECK_SOURCES})

        set_property (GLOBAL
                      APPEND
                      PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_SOURCES
                      ${SOURCE})

    endforeach ()

    foreach (INCLUDE ${UNUSED_CHECK_INCLUDES})

        set_property (GLOBAL
                      APPEND
                      PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_INCLUDES
                      ${INCLUDE})

    endforeach ()

    set (STAMPFILE ${CMAKE_CURRENT_BINARY_DIR}/${WHICH}.stamp)

    foreach (TARGET ${UNUSED_CHECK_TARGETS})

        set_property (GLOBAL
                      APPEND
                      PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_TARGETS
                      ${TARGET})

    endforeach ()

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

    if (NOT HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME)

        message (SEND_ERROR "No unused function check with name ${WHICH} exists")
        return ()

    endif (NOT HAS_UNUSED_FUNCTION_CHECK_WITH_THIS_NAME)

    get_property (_cppcheck_unused_function_sources_set
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_SOURCES
                  SET)

    if (NOT _cppcheck_unused_function_sources_set)

        message (SEND_ERROR "No unused function sources registered, "
                            "they should be registered using "
                            "cppcheck_add_to_global_unused_function_check "
                            "before calling "
                            "cppcheck_add_global_unused_function_check_to_"
                            "target")

        return ()

    endif (NOT _cppcheck_unused_function_sources_set)

    set (OPTIONAL_OPTIONS WARN_ONLY)
    set (MULTIVALUE_OPTIONS INCLUDES)

    cmake_parse_arguments (ADD_GLOBAL_UNUSED_FUNCTION_CHECK
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

    get_property (_cppcheck_unused_function_targets
                  GLOBAL
                  PROPERTY CPPCHECK_${WHICH}_UNUSED_FUNCTION_CHECK_TARGETS)

    set (OPTIONS
         ${CPPCHECK_COMMON_OPTIONS}
         --enable=unusedFunction)

    if (NOT ADD_GLOBAL_UNUSED_FUNCTION_CHECK_WARN_ONLY)

        list (APPEND OPTIONS --error-exitcode=1)

    endif (NOT ADD_GLOBAL_UNUSED_FUNCTION_CHECK_WARN_ONLY)

    list (APPEND ADD_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES
          ${_cppcheck_unused_function_includes})

    if (ADD_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES)

        foreach (_include ${ADD_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES})

            list (APPEND OPTIONS -I${_include})

        endforeach (_include)

    endif (ADD_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES)

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
# [Optional] INCLUDES : Include directories to search.
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
    set (MULTIVALUE_OPTIONS INCLUDES SOURCES)
    cmake_parse_arguments (CPPCHECK
                           "${OPTIONAL_OPTIONS}"
                           "${SINGLEVALUE_OPTIONS}"
                           "${MULTIVALUE_OPTIONS}"
                           ${ARGN})

    set (FILTERED_CHECK_SOURCES)

    # First case: We're checking generated sources, so
    # we can just check all passed in sources.
    if (CPPCHECK_CHECK_GENERATED)

        set (FILTERED_CHECK_SOURCES ${CPPCHECK_SOURCES})

    # Second case: We only want to check real sources,
    # so filter out generated ones.
    else (CPPCHECK_CHECK_GENERATED)

        _filter_out_generated_sources (FILTERED_CHECK_SOURCES
                                       SOURCES ${CPPCHECK_SOURCES})

    endif (CPPCHECK_CHECK_GENERATED)

    # Figure out if this target is linkable. If it is a UTILITY
    # target then we need to run the checks at the PRE_BUILD stage.
    set (WHEN PRE_LINK)

    get_property (TARGET_TYPE
                  TARGET ${TARGET}
                  PROPERTY TYPE)

    if (TARGET_TYPE STREQUAL "UTILITY")

        set (WHEN PRE_BUILD)

    endif (TARGET_TYPE STREQUAL "UTILITY")

    if (NOT FILTERED_CHECK_SOURCES)

        message (FATAL_ERROR "SOURCES must be set to either native sources "
                 "or generated sources with the CHECK_GENERATED flag set "
                 "when using cppcheck_sources")

    endif (NOT FILTERED_CHECK_SOURCES)

    set (CPPCHECK_OPTIONS
         ${CPPCHECK_COMMON_OPTIONS}
         --enable=performance
         --enable=portability)

    if (NOT CPPCHECK_WARN_ONLY)

        list (APPEND CPPCHECK_OPTIONS --error-exitcode=1)

    endif (NOT CPPCHECK_WARN_ONLY)

    if (NOT CPPCHECK_NO_CHECK_STYLE)

        list (APPEND CPPCHECK_OPTIONS --enable=style)

    endif (NOT CPPCHECK_NO_CHECK_STYLE)

    if (CPPCHECK_CHECK_UNUSED)

        list (APPEND CPPCHECK_OPTIONS --enable=unusedFunction)

    endif (CPPCHECK_CHECK_UNUSED)

    if (CPPCHECK_INCLUDES)

        foreach (_include ${CPPCHECK_INCLUDES})

            list (APPEND CPPCHECK_OPTIONS -I${_include})

        endforeach (_include)

    endif (CPPCHECK_INCLUDES)

    set (EXTRA_ARGS)

    _cppcheck_add_checks_to_target (${TARGET}
                                    ${WHEN}
                                    SOURCES ${FILTERED_CHECK_SOURCES}
                                    OPTIONS ${CPPCHECK_OPTIONS}
                                    ${EXTRA_ARGS})

endfunction (cppcheck_sources)

function (_get_target_c_or_cxx_sources RETURN_SOURCES TARGET)

    get_target_property (_sources ${TARGET} SOURCES)
    set (_files_to_check)
    foreach (_file ${_sources})

        get_source_file_property (_lang ${_file} LANGUAGE)
        get_source_file_property (_location ${_file} LOCATION)

        if ("${_lang}" MATCHES "CXX" OR
            "${_lang}" MATCHES "C")

            list (APPEND _files_to_check ${_location})

        endif ("${_lang}" MATCHES "CXX" OR
               "${_lang}" MATCHES "C")

    endforeach ()

    set (${RETURN_SOURCES} ${_files_to_check} PARENT_SCOPE)

endfunction ()

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
# [Optional] INCLUDES : Check header files in specified include directories.
function (cppcheck_target_sources TARGET)

    _get_target_c_or_cxx_sources (_files_to_check ${TARGET})

    set (EXTRA_OPTIONS)
    set (MULTIVALUE_OPTIONS INCLUDES)
    cmake_parse_arguments (CPPCHECK
                           ""
                           ""
                           "${MULTIVALUE_OPTIONS}"
                           ${ARGN})

    cppcheck_sources (${TARGET}
                      INCLUDES ${CPPCHECK_INCLUDES}
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
# [Optional] NO_CHECK_GENERATED : Do not add generated files
#            to the unused function check.
function (cppcheck_add_target_sources_to_unused_function_check TARGET
                                                               WHICH)

    _get_target_c_or_cxx_sources (_files_to_check ${TARGET})

    cppcheck_add_to_unused_function_check (${WHICH}
                                           TARGETS ${TARGET}
                                           SOURCES ${_files_to_check}
                                           ${ARGN})

endfunction ()


