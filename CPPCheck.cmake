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
                            "to call find_package (cppcheck) before "
                            "using this module")

    else (NOT CPPCHECK_EXECUTABLE)

        set (${CONTINUE} TRUE PARENT_SCOPE)

    endif (NOT CPPCHECK_EXECUTABLE)

endfunction (_validate_cppcheck)

function (_cppcheck_add_checks_to_target SOURCES_VAR
                                         TARGET
                                         WHEN
                                         OPTIONS_VAR)

    set (ADD_CHECKS_OPTIONS COMMENT)
    cmake_parse_arguments (ADD_CHECKS_TO_TARGET "${COMMENT}" "" "")

    set (EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND)
    if (ADD_CHECKS_OPTIONS_COMMENT)

        set (EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND
             COMMENT ${ADD_CHECKS_OPTIONS})

    endif (ADD_CHECKS_OPTIONS_COMMENT)

    add_custom_command (TARGET ${TARGET}
                        ${WHEN}
                        COMMAND
                        ${CPPCHECK_EXECUTABLE}
                        ARGS
                        ${${OPTIONS_VAR}}
                        ${${SOURCES_VAR}}
                        ${EXTRA_ARGUMENTS_TO_ADD_CUSTOM_COMMAND})

endfunction (_cppcheck_add_checks_to_target)

# cppcheck_add_to_global_unused_function_check
#
# Adds the source files as specified in SOURCES_VAR to the global
# list of source files to check during the global unused function
# target
#
# SOURCES_VAR : A variable containing a list of sources
function (cppcheck_add_to_global_unused_function_check SOURCES_VAR)

    set (_sources ${${SOURCES_VAR}})

    foreach (_source ${_sources})

        set_property (GLOBAL
                      APPEND
                      PROPERTY CPPCHECK_GLOBAL_UNUSED_FUNCTION_CHECK_SOURCES
                      ${_source})

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

    set (OPTIONS
    	 ${CPPCHECK_COMMON_OPTIONS}
    	 --enable=unusedFunction)

    if (NOT ADD_GLOBAL_UNUSED_FUNCTION_CHECK_WARN_ONLY)

        list (APPEND OPTIONS --error-exitcode=1)

    endif (NOT ADD_GLOBAL_UNUSED_FUNCTION_CHECK_WARN_ONLY)

    if (ADD_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES)

        foreach (_include ${ADD_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES})

            list (APPEND OPTIONS -I${_include})

        endforeach (_include)

    endif (ADD_GLOBAL_UNUSED_FUNCTION_CHECK_INCLUDES)

    _cppcheck_add_checks_to_target (_cppcheck_unused_function_sources
                                    ${TARGET}
                                    PRE_BUILD
                                    OPTIONS
                                    COMMENT "Checking for unused functions")

endfunction (cppcheck_add_global_unused_function_check_to_target)

# cppcheck_sources
#
# Run CPPCheck on the sources as specified in SOURCES, reporting any
# warnings or errors on stderr.
#
# SOURCES_VAR : A variable containing a list of sources
# TARGET : Target to attach checks to
# [Optional] COMMENT : Text to print when checking sources
# [Optional] WARN_ONLY : Don't error out, just warn on potential problems.
# [Optional] NO_CHECK_STYLE : Don't check for style issues
# [Optional] CHECK_UNUSED : Check for unused functions
# [Optional] INCLUDES : Include directories to search.
function (cppcheck_sources SOURCES_VAR TARGET)

    _validate_cppcheck (CPPCHECK_AVAILABLE)

    if (NOT CPPCHECK_AVAILABLE)

        return ()

    endif (NOT CPPCHECK_AVAILABLE)

    set (OPTIONAL_OPTIONS WARN_ONLY NO_CHECK_STYLE NO_CHECK_UNUSED COMMENT)
    set (MULTIVALUE_OPTIONS INCLUDES)
    cmake_parse_arguments (CPPCHECK
                           "${OPTIONAL_OPTIONS}"
                           ""
                           "${MULTIVALUE_OPTIONS}" ${ARGN})

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

    _cppcheck_add_checks_to_target (${SOURCES_VAR}
                                    ${TARGET}
                                    PRE_LINK
                                    CPPCHECK_OPTIONS
                                    ${EXTRA_ARGS})

    cppcheck_add_to_global_unused_function_check (${SOURCES_VAR})

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
# [Optional] CHECK_TARGET_HEADERS : Also check header files on TARGET
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
    set (OPTIONAL_OPTIONS CHECK_TARGET_HEADERS)
    cmake_parse_arguments (CPPCHECK "${OPTIONAL_OPTIONS}" "" "" ${ARGN})

    if (CPPCHECK_CHECK_TARGET_HEADERS)

        get_target_property (_include_directories
                             ${TARGET}
                             INCLUDE_DIRECTORIES)

        set (EXTRA_OPTIONS INCLUDES ${_include_directories} ${EXTRA_OPTIONS})

    endif (CPPCHECK_CHECK_TARGET_HEADERS)

    cppcheck_sources (_files_to_check
                      ${TARGET}
                      INCLUDES ${_include_directories}
                      ${ARGN})

endfunction (cppcheck_target_sources)
