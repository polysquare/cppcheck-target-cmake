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

function (_get_absolute_path_to_header_file_language ABSOLUTE_PATH_TO_HEADER
                                                     LANGUAGE)

    # ABSOLUTE_PATH is a GLOBAL property
    # called "_CPPCHECK_H_MAP_" + ABSOLUTE_PATH.
    # We can't address it immediately by that name though,
    # because CMake properties and variables can only be
    # addressed by certain characters, however, internally,
    # they are stored as std::map <std::string, std::string>,
    # so we can fool CMake into doing so.
    #
    # We first save our desired property string into a new
    # variable called MAP_KEY and then use set
    # ("${MAP_KEY}" ${LANGUAGE}). CMake will expand ${MAP_KEY}
    # and pass the string directly to the internal
    # implementation of "set", which sets the string
    # as the key value
    set (MAP_KEY "_CPPCHECK_H_MAP_${ABSOLUTE_PATH_TO_HEADER}")
    get_property (HEADER_FILE_LANGUAGE_SET GLOBAL PROPERTY "${MAP_KEY}" SET)

    if (HEADER_FILE_LANGUAGE_SET)

        get_property (HEADER_FILE_LANGUAGE GLOBAL PROPERTY "${MAP_KEY}")
        set (${LANGUAGE} ${HEADER_FILE_LANGUAGE} PARENT_SCOPE)
        return ()

    endif (HEADER_FILE_LANGUAGE_SET)

    return ()

endfunction ()

function (_get_language_from_source_name SOURCE RETURN_LANGUAGE)

    set (GET_LANG_OPTIONS "NO_HEADERS")

    cmake_parse_arguments (GET_LANG
                           "${GET_LANG_OPTIONS}"
                           ""
                           ""
                           ${ARGN})

    set (${RETURN_LANGUAGE} "" PARENT_SCOPE)

    get_property (LANGUAGE SOURCE ${SOURCE} PROPERTY SET_LANGUAGE)

    # User overrode the LANGUAGE property, use that.
    if (DEFINED SET_LANGUAGE)

       set (${LANGUAGE} ${SET_LANGUAGE} PARENT_SCOPE)
       return ()

    endif (DEFINED SET_LANGUAGE)

    # Try and detect the language based on the file's extension
    get_filename_component (EXTENSION ${SOURCE} EXT)
    string (SUBSTRING ${EXTENSION} 1 -1 EXTENSION)

    list (FIND CMAKE_C_SOURCE_FILE_EXTENSIONS ${EXTENSION} C_INDEX)

    if (NOT C_INDEX EQUAL -1)

        set (${RETURN_LANGUAGE} "C" PARENT_SCOPE)
        return ()

    endif (NOT C_INDEX EQUAL -1)

    list (FIND CMAKE_CXX_SOURCE_FILE_EXTENSIONS ${EXTENSION} CXX_INDEX)

    if (NOT CXX_INDEX EQUAL -1)

        set (${RETURN_LANGUAGE} "CXX" PARENT_SCOPE)
        return ()

    endif ()

    # Couldn't find source langauge from either extension or property.
    # We might be scanning a header so check the header maps for a language
    if (NOT GET_LANG_NO_HEADERS)

        set (LANGUAGE "")
        _get_absolute_path_to_header_file_language (${SOURCE} LANGUAGE)
        set (${RETURN_LANGUAGE} ${LANGUAGE} PARENT_SCOPE)

    endif (NOT GET_LANG_NO_HEADERS)

endfunction () 

function (_scan_source_file_for_headers)

    set (SCAN_SINGLEVAR_ARGUMENTS SOURCE)
    set (SCAN_MULTIVAR_ARGUMENTS INCLUDE_DIRECTORIES ALREADY_SCANNED CPP_IDENTIFIERS)

    cmake_parse_arguments (SCAN
                           ""
                           "${SCAN_SINGLEVAR_ARGUMENTS}"
                           "${SCAN_MULTIVAR_ARGUMENTS}"
                           ${ARGN})

    if (NOT DEFINED SCAN_SOURCE)

        message (FATAL_ERROR "SOURCE must be set to use this function")

    endif (NOT DEFINED SCAN_SOURCE)

    # Source doesn't exist. This is fine, we might be recursively scanning
    # a header path which is generated. If it is generated, gracefully bail
    # out, otherwise exit with a FATAL_ERROR as this is really an assertion
    if (NOT EXISTS ${SCAN_SOURCE})

        get_property (SOURCE_IS_GENERATED SOURCE ${SCAN_SOURCE}
                      PROPERTY GENERATED)

        if (SOURCE_IS_GENERATED)

            return ()

        else (SOURCE_IS_GENERATED)

            message (FATAL_ERROR "_scan_source_file_for_headers called with "
                                 "a source file that does not exist or was "
                                 "not generated as part of a build rule")

        endif (SOURCE_IS_GENERATED)

    endif (NOT EXISTS ${SCAN_SOURCE})

    # We've already scanned this source file in this pass, bail out
    list (FIND SCAN_ALREADY_SCANNED ${SCAN_SOURCE} SOURCE_INDEX)

    if (NOT SOURCE_INDEX EQUAL -1)

        return ()

    endif (NOT SOURCE_INDEX EQUAL -1)

    # Open the source file and read its contents
    file (READ ${SCAN_SOURCE} SOURCE_CONTENTS)

    # Split the read contents into lines, using ; as the delimiter
    string (REGEX REPLACE ";" "\\\\;" SOURCE_CONTENTS "${SOURCE_CONTENTS}")
    string (REGEX REPLACE "\n" ";" SOURCE_CONTENTS "${SOURCE_CONTENTS}")

    _get_language_from_source_name (${SCAN_SOURCE} LANGUAGE)

    foreach (LINE ${SOURCE_CONTENTS})

        # This is an #include statement, check what is within it
        if (LINE MATCHES "^.*\#include.*[<\"].*[>\"]")

            # Start with ${LINE}
            set (HEADER ${LINE})

            # Trim out the beginning and end of the include statement
            # Because CMake doesn't support non-greedy expressions (eg "?")
            # we need to match based on indices and not using REGEX REPLACE
            # so we need to use REGEX MATCH to get the first match and then
            # FIND to get the index.
            string (REGEX MATCH "[<\"]" PATH_START "${HEADER}")
            string (FIND "${HEADER}" "${PATH_START}" PATH_START_INDEX)
            math (EXPR PATH_START_INDEX "${PATH_START_INDEX} + 1")
            string (SUBSTRING "${HEADER}" ${PATH_START_INDEX} -1 HEADER)

            string (REGEX MATCH "[>\"]" PATH_END "${HEADER}")
            string (FIND "${HEADER}" "${PATH_END}" PATH_END_INDEX)
            string (SUBSTRING "${HEADER}" 0 ${PATH_END_INDEX} HEADER)

            string (STRIP ${HEADER} HEADER)

            foreach (INCLUDE_DIRECTORY ${SCAN_INCLUDE_DIRECTORIES})

                set (RELATIVE_PATH "${INCLUDE_DIRECTORY}/${HEADER}")
                get_filename_component (ABSOLUTE_PATH ${RELATIVE_PATH} ABSOLUTE)

                # Header doesn't exist, don't update in map
                get_property (HEADER_IS_GENERATED SOURCE ${ABSOLUTE_PATH}
                              PROPERTY GENERATED)

                if (NOT EXISTS ${ABSOLUTE_PATH} AND NOT HEADER_IS_GENERATED)

                    break ()

                endif (NOT EXISTS ${ABSOLUTE_PATH} AND NOT HEADER_IS_GENERATED)

                # First see if a language has already been set for this header
                # file. If so, and it is "C", then we can't change it any
                # further at this point.
                set (HEADER_LANGUAGE "")
                _get_absolute_path_to_header_file_language (${ABSOLUTE_PATH}
                                                            HEADER_LANGUAGE)

                set (MAP_KEY "_CPPCHECK_H_MAP_${ABSOLUTE_PATH}")
                set (UPDATE_HEADER_IN_MAP FALSE)

                if (DEFINED HEADER_LANGUAGE AND
                    NOT HEADER_LANGUAGE STREQUAL "C")

                    set (UPDATE_HEADER_IN_MAP TRUE)

                elseif (NOT DEFINED HEADER_LANGUAGE)

                    set (UPDATE_HEADER_IN_MAP TRUE)

                endif (DEFINED HEADER_LANGUAGE AND
                       NOT HEADER_LANGUAGE STREQUAL "C")

                if (UPDATE_HEADER_IN_MAP)

                    set_property (GLOBAL PROPERTY "${MAP_KEY}" "${LANGUAGE}")

                    # Recursively scan for header more header files in this one
                    _scan_source_file_for_headers (SOURCE ${ABSOLUTE_PATH}
                                                   INCLUDE_DIRECTORIES
                                                   ${SCAN_INCLUDE_DIRECTORIES}
                                                   ALREADY_SCANNED
                                                   ${SCAN_ALREADY_SCANNED}
                                                   ${SCAN_SOURCE}
                                                   CPP_IDENTIFIERS
                                                    ${SCAN_CPP_IDENTIFIERS})

                endif (UPDATE_HEADER_IN_MAP)

            endforeach ()

       endif (LINE MATCHES "^.*\#include.*[<\"].*[>\"]")

    endforeach ()

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

function (_determine_language_from_any_source_type SOURCE
                                                   LANGUAGE_RETURN)

    set (DETERMINE_LANG_MULTIVAR_ARGS INCLUDES CPP_IDENTIFIERS)
    cmake_parse_arguments (DETERMINE_LANG
                           ""
                           ""
                           "${DETERMINE_LANG_MULTIVAR_ARGS}"
                           ${ARGN})

    _get_language_from_source_name (${SOURCE} LANGUAGE NO_HEADERS)

    if (DEFINED LANGUAGE)

        # A language was set for this source - let cppcheck figure it out
        list (APPEND KNOWN_LANGUAGE_SOURCES ${SOURCE})

        # Also accumulate some headers from this source file
        _scan_source_file_for_headers (SOURCE ${SOURCE}
                                       INCLUDE_DIRECTORIES
                                       ${DETERMINE_LANG_INCLUDES}
                                       CPP_IDENTIFIERS
                                       ${DETERMINE_LANG_CPP_IDENTIFIERS})

        set (${LANGUAGE_RETURN} ${LANGUAGE} PARENT_SCOPE)
        return ()

    else (DEFINED LANGUAGE)

        # This is a header file - we need to look up in the list
        # of header files to determine what language this header
        # file is. That will generally be "C" if it was
        # included by any "C" source files and "CXX" if it was included
        # by any other (CXX) sources.
        #
        # There is one exception - If a header is set to "C", we should
        # open it and scan for #ifdef __cplusplus. That would indicate
        # that it can be used in both modes and so it should be scanned
        # in both modes.
        #
        # There is also one error case - If we are unable to determine
        # the language of the header file initially, then it was never
        # added to the list of known headers. We'll error out with a message
        # suggesting that it must be included at least once somewhere, or
        # a FORCE_LANGUAGE option should be passed
        get_filename_component (ABSOLUTE_PATH ${SOURCE} ABSOLUTE)
        _get_absolute_path_to_header_file_language (${ABSOLUTE_PATH}
                                                    HEADER_LANGUAGE)

        # Error case
        if (NOT DEFINED HEADER_LANGUAGE)
        
            message (SEND_ERROR "Couldn't find language for the header file"
                                " ${ABSOLUTE_PATH}. Make sure to include "
                                " this header file in at least one source "
                                " file and add that source file to a "
                                " target and scan it using "
                                " cppcheck_target_sources or "
                                " cppcheck_sources OR pass the "
                                " FORCE_LANGUAGE option to either of those "
                                " two functions where the header will be "
                                " included.")
            return ()

        endif (NOT DEFINED HEADER_LANGUAGE)

        # C case - open the file and check for #ifdef __cplusplus - if we
        # do have that, then add it to our CXX sources as well
        get_property (HEADER_IS_GENERATED SOURCE ${SOURCE} PROPERTY GENERATED)
        if (HEADER_LANGUAGE STREQUAL "C")

            if (NOT HEADER_IS_GENERATED)

                file (READ ${SOURCE} SOURCE_CONTENTS)

                # Split the read contents into lines, using ; as the delimiter
                string (REGEX REPLACE ";" "\\\\;"
                        SOURCE_CONTENTS "${SOURCE_CONTENTS}")
                string (REGEX REPLACE "\n" ";"
                        SOURCE_CONTENTS "${SOURCE_CONTENTS}")

                foreach (LINE ${SOURCE_CONTENTS})

                    list (APPEND DETERMINE_LANG_CPP_IDENTIFIERS
                          __cplusplus)

                    foreach (IDENTIFIER ${DETERMINE_LANG_CPP_IDENTIFIERS})

                        if (LINE MATCHES "^.*${IDENTIFIER}")

                            set (${LANGUAGE_RETURN} "C;CXX" PARENT_SCOPE)
                            return ()

                        endif (LINE MATCHES "^.*${IDENTIFIER}")

                    endforeach ()

                endforeach ()

            endif (NOT HEADER_IS_GENERATED)

            set (${LANGUAGE_RETURN} "C" PARENT_SCOPE)
            return ()

        elseif (HEADER_LANGUAGE STREQUAL "CXX")

            set (${LANGUAGE_RETURN} "CXX" PARENT_SCOPE)
            return ()

        endif (HEADER_LANGUAGE STREQUAL "C")

    endif (DEFINED LANGUAGE)

    message (FATAL_ERROR "This section should not be reached")

endfunction ()

function (_cppcheck_add_checks_to_target TARGET
                                         WHEN)

    set (ADD_CHECKS_OPTIONS CHECK_GENERATED)
    set (ADD_CHECKS_SINGLEVAR_OPTIONS FORCE_LANGUAGE)
    set (ADD_CHECKS_MULTIVAR_OPTIONS SOURCES OPTIONS INCLUDES CPP_IDENTIFIERS)

    cmake_parse_arguments (ADD_CHECKS_TO_TARGET
                           "${ADD_CHECKS_OPTIONS}"
                           "${ADD_CHECKS_SINGLEVAR_OPTIONS}"
                           "${ADD_CHECKS_MULTIVAR_OPTIONS}"
                           ${ARGN})

    set (DETECT_LANGUAGE_SOURCES)
    set (C_HEADERS)
    set (CXX_HEADERS)

    foreach (SOURCE ${ADD_CHECKS_TO_TARGET_SOURCES})

        set (LANGUAGE ${ADD_CHECKS_TO_TARGET_FORCE_LANGUAGE})

        if (NOT LANGUAGE)

            set (INCLUDES ${ADD_CHECKS_TO_TARGET_INCLUDES})
            set (CPP_IDENTIFIERS ${ADD_CHECKS_TO_TARGET_CPP_IDENTIFIERS})
            _determine_language_from_any_source_type (${SOURCE} LANGUAGE
                                                      INCLUDES ${INCLUDES}
                                                      CPP_IDENTIFIERS
                                                      ${CPP_IDENTIFIERS})

        endif (NOT LANGUAGE)

        list (FIND LANGUAGE "C" C_INDEX)
        list (FIND LANGUAGE "CXX" CXX_INDEX)

        if (NOT C_INDEX EQUAL -1)

            list (APPEND C_HEADERS ${SOURCE})

        endif (NOT C_INDEX EQUAL -1)

        if (NOT CXX_INDEX EQUAL -1)

            list (APPEND CXX_HEADERS ${SOURCE})

        endif (NOT CXX_INDEX EQUAL -1)

    endforeach ()

    # For known languages, no special options
    _cppcheck_add_normal_check_command (${TARGET} ${WHEN}
                                        SOURCES ${KNOWN_LANGUAGE_SOURCES}
                                        OPTIONS ${ADD_CHECKS_TO_TARGET_OPTIONS})

    set (C_LANGUAGE_OPTION)
    set (CXX_LANGUAGE_OPTION)

    if (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

        set (C_LANGUAGE_OPTION --language=c)
        set (CXX_LANGUAGE_OPTION --language=c++)

    endif (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

    # For C headers, pass --language=c
    _cppcheck_add_normal_check_command (${TARGET} ${WHEN}
                                        SOURCES ${C_HEADERS}
                                        OPTIONS
                                        ${ADD_CHECKS_TO_TARGET_OPTIONS}
                                        ${C_LANGUAGE_OPTION})

    # For CXX headers, pass --language=c++ and -D__cplusplus
    _cppcheck_add_normal_check_command (${TARGET} ${WHEN}
                                        SOURCES ${CXX_HEADERS}
                                        OPTIONS
                                        ${ADD_CHECKS_TO_TARGET_OPTIONS}
                                        ${CXX_LANGUAGE_OPTION}
                                        -D__cplusplus)

endfunction ()

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

    if (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

        list (APPEND OPTIONS --language=c++)

    endif (${CPPCHECK_VERSION} VERSION_GREATER 1.57)

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
# [Optional] FORCE_LANGUAGE : Force all scanned files to be a certain language,
#                             e.g. C, CXX
# [Optional] INCLUDES : Include directories to search.
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
    set (MULTIVALUE_OPTIONS INCLUDES SOURCES CPP_IDENTIFIERS)
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

    else (CPPCHECK_CHECK_UNUSED)

        list (APPEND CPPCHECK_OPTIONS --suppress=unusedStructMember)

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
                                    INCLUDES ${CPPCHECK_INCLUDES}
                                    CPP_IDENTIFIERS ${CPPCHECK_CPP_IDENTIFIERS}
                                    FORCE_LANGUAGE ${CPPCHECK_FORCE_LANGUAGE}
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
# [Optional] FORCE_LANGUAGE : Force all scanned files to be a certain language,
#                             e.g. C, CXX
# [Optional] INCLUDES : Check header files in specified include directories.
# [Optional] CPP_IDENTIFIERS : A list of identifiers which indicate that
#                              any header file specified in the target's
#                              sources is definitely a C++ header file
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


