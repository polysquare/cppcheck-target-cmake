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

function (_cppcheck_add_checks_to_target TARGET
                                         WHEN)

    set (ADD_CHECKS_SINGLEVAR_OPTIONS COMMENT)
    set (ADD_CHECKS_MULTIVAR_OPTIONS SOURCES OPTIONS)

    cmake_parse_arguments (ADD_CHECKS_TO_TARGET
                           ""
                           "${ADD_CHECKS_SINGLEVAR_OPTIONS}"
                           "${ADD_CHECKS_MULTIVAR_OPTIONS}"
                           ${ARGN})

    set (EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND)
    if (ADD_CHECKS_TO_TARGET_COMMENT)

        set (EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND
             COMMENT ${ADD_CHECKS_TO_TARGET_COMMENT})

    endif (ADD_CHECKS_TO_TARGET_COMMENT)

    add_custom_command (TARGET ${TARGET}
                        ${WHEN}
                        COMMAND
                        ${CPPCHECK_EXECUTABLE}
                        ARGS
                        ${ADD_CHECKS_TO_TARGET_OPTIONS}
                        ${ADD_CHECKS_TO_TARGET_SOURCES}
                        ${EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND})

endfunction (_cppcheck_add_checks_to_target)

# cppcheck_add_to_global_unused_function_check
#
# Adds the source files as specified in SOURCES to the global
# list of source files to check during the global unused function
# target
#
# [Optional] SOURCES : A variable containing a list of sources
# [Optional] INCLUDES : A list of include directories used to
#                       build these sources.
function (cppcheck_add_to_global_unused_function_check)

    set (GLOBAL_CHECK_MULTIVAR_ARGS
         SOURCES
         INCLUDES)

    cmake_parse_arguments (GLOBAL_CHECK
                           ""
                           ""
                           "${GLOBAL_CHECK_MULTIVAR_ARGS}"
                           ${ARGN})

    foreach (SOURCE ${GLOBAL_CHECK_SOURCES})

        set_property (GLOBAL
                      APPEND
                      PROPERTY CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_SOURCES
                      ${SOURCE})

    endforeach ()

    foreach (INCLUDE ${GLOBAL_CHECK_INCLUDES})

        set_property (GLOBAL
                      APPEND
                      PROPERTY CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES
                      ${INCLUDE})

    endforeach ()

endfunction (cppcheck_add_to_global_unused_function_check)

# cppcheck_add_global_unused_function_check_to_target
#
# Adds a global check of all registered source files for unused functions to
# the specified TARGET
#
# TARGET : Target to add checks to
# [Optional] WARN_ONLY : Only print warnings if there are unused functions,
#                        do not error out
# [Optional] INCLUDES : Include directories to search when analyzing.
function (cppcheck_add_global_unused_function_check_to_target TARGET)

    _validate_cppcheck (CPPCHECK_AVAILABLE)

    if (NOT CPPCHECK_AVAILABLE)

        return ()

    endif ()

    get_property (_cppcheck_unused_function_sources_set
                  GLOBAL
                  PROPERTY CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_SOURCES
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
                  PROPERTY CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_SOURCES)

    get_property (_cppcheck_unused_function_includes
                  GLOBAL
                  PROPERTY CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES)

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

    _cppcheck_add_checks_to_target (${TARGET}
                                    PRE_BUILD
                                    SOURCES ${_cppcheck_unused_function_sources}
                                    OPTIONS ${OPTIONS}
                                    COMMENT "Checking for unused functions")

endfunction (cppcheck_add_global_unused_function_check_to_target)

# cppcheck_sources
#
# Run CPPCheck on the sources as specified in SOURCES, reporting any
# warnings or errors on stderr.
#
# TARGET : Target to attach checks to
# [Mandatory] SOURCES : A list of sources to scan.
# [Optional] COMMENT : Text to print when checking sources
# [Optional] WARN_ONLY : Don't error out, just warn on potential problems.
# [Optional] NO_CHECK_STYLE : Don't check for style issues
# [Optional] CHECK_UNUSED : Check for unused functions
# [Optional] INCLUDES : Include directories to search.
function (cppcheck_sources TARGET)

    _validate_cppcheck (CPPCHECK_AVAILABLE)

    if (NOT CPPCHECK_AVAILABLE)

        return ()

    endif (NOT CPPCHECK_AVAILABLE)

    set (OPTIONAL_OPTIONS WARN_ONLY NO_CHECK_STYLE NO_CHECK_UNUSED)
    set (SINGLEVALUE_OPTIONS COMMENT)
    set (MULTIVALUE_OPTIONS INCLUDES SOURCES)
    cmake_parse_arguments (CPPCHECK
                           "${OPTIONAL_OPTIONS}"
                           "${SINGLEVALUE_OPTIONS}"
                           "${MULTIVALUE_OPTIONS}"
                           ${ARGN})

    if (NOT CPPCHECK_SOURCES)

        message (FATAL_ERROR "SOURCES must be set when using cppcheck_sources")

    endif (NOT CPPCHECK_SOURCES)

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

    if (CPPCHECK_COMMENT)

        list (APPEND EXTRA_ARGS COMMENT ${CPPCHECK_COMMENT})

    endif (CPPCHECK_COMMENT)

    _cppcheck_add_checks_to_target (${TARGET}
                                    PRE_LINK
                                    SOURCES ${CPPCHECK_SOURCES}
                                    OPTIONS ${CPPCHECK_OPTIONS}
                                    ${EXTRA_ARGS})

    cppcheck_add_to_global_unused_function_check (SOURCES ${CPPCHECK_SOURCES}
                                                  INCLUDES ${CPPCHECK_INCLUDES})

endfunction (cppcheck_sources)

# cppcheck_target_sources
#
# Run CPPCheck on all the sources for a particular TARGET, reporting any
# warnigns or errors on stderr
#
# TARGET : Target to check sources on
# [Optional] COMMENT : Text to print when checking sources
# [Optional] WARN_ONLY : Don't error out, just warn on potential problems.
# [Optional] NO_CHECK_STYLE : Don't check for style issues
# [Optional] CHECK_UNUSED : Check for unused functions
# [Optional] INCLUDES : Check header files in specified include directories.
function (cppcheck_target_sources TARGET)

    get_target_property (_sources ${TARGET} SOURCES)
    set (_files_to_check)
    foreach (_file ${_sources})

        get_source_file_property (_lang ${_file} LANGUAGE)
        get_source_file_property (_location ${_file} LOCATION)

        if ("${_lang}" MATCHES "CXX")

            list (APPEND _files_to_check ${_location})

        endif ("${_lang}" MATCHES "CXX")

    endforeach ()

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
