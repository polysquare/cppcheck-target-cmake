# /util/CppCheckUtil.cmake
#
# Utility functions for CPPCheck.cmake
#
# See LICENCE.md for Copyright information.

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

function (_append_to_global_property PROPERTY)

    cmake_parse_arguments (APPEND
                           ""
                           ""
                           "LIST"
                           ${ARGN})

    foreach (ITEM ${APPEND_LIST})

        set_property (GLOBAL
                      APPEND
                      PROPERTY ${PROPERTY}
                      ${ITEM})

    endforeach ()

endfunction (_append_to_global_property)

function (_append_each_to_options_with_prefix MAIN_LIST PREFIX)

    cmake_parse_arguments (APPEND
                           ""
                           ""
                           "LIST"
                           ${ARGN})

    foreach (ITEM ${APPEND_LIST})

        list (APPEND ${MAIN_LIST} ${PREFIX}${ITEM})

    endforeach ()

    set (${MAIN_LIST} ${${MAIN_LIST}} PARENT_SCOPE)

endfunction (_append_each_to_options_with_prefix)

function (_add_switch ALL_OPTIONS OPTION_NAME)

    set (ADD_SWITCH_SINGLEVAR_ARGS ON OFF)
    cmake_parse_arguments (ADD_SWITCH
                           ""
                           "${ADD_SWITCH_SINGLEVAR_ARGS}"
                           ""
                           ${ARGN})

    if (${OPTION_NAME})

        list (APPEND ${ALL_OPTIONS} ${ADD_SWITCH_ON})

    else (DEFINED ${OPTION_NAME})

        list (APPEND ${ALL_OPTIONS} ${ADD_SWITCH_OFF})

    endif (${OPTION_NAME})

    set (${ALL_OPTIONS} ${${ALL_OPTIONS}} PARENT_SCOPE)

endfunction (_add_switch)

function (_strip_add_custom_target_sources RETURN_SOURCES TARGET)

    get_target_property (_sources ${TARGET} SOURCES)
    list (GET _sources 0 _first_source)
    string (FIND "${_first_source}" "/" LAST_SLASH REVERSE)
    math (EXPR LAST_SLASH "${LAST_SLASH} + 1")
    string (SUBSTRING "${_first_source}" ${LAST_SLASH} -1 END_OF_SOURCE)

    if (END_OF_SOURCE STREQUAL "${TARGET}")

        list (REMOVE_AT _sources 0)

    endif (END_OF_SOURCE STREQUAL "${TARGET}")

    set (${RETURN_SOURCES} ${_sources} PARENT_SCOPE)

endfunction ()

function (_get_target_command_attach_point TARGET ATTACH_POINT_RETURN)

    # Figure out if this target is linkable. If it is a UTILITY
    # target then we need to run the checks at the PRE_BUILD stage.
    set (_ATTACH_POINT PRE_LINK)

    get_property (TARGET_TYPE
                  TARGET ${TARGET}
                  PROPERTY TYPE)

    if (TARGET_TYPE STREQUAL "UTILITY")

        set (_ATTACH_POINT PRE_BUILD)

    endif (TARGET_TYPE STREQUAL "UTILITY")

    set (${ATTACH_POINT_RETURN} ${_ATTACH_POINT} PARENT_SCOPE)

endfunction (_get_target_command_attach_point)

function (_handle_check_generated_option PREFIX SOURCES_RETURN)

    cmake_parse_arguments (HANDLE_CHECK_GENERATED
                           ""
                           ""
                           "SOURCES"
                           ${ARGN})

    # First case: We're checking generated sources, so
    # we can just check all passed in sources.
    if (${PREFIX}_CHECK_GENERATED)

        set (_FILTERED_SOURCES ${HANDLE_CHECK_GENERATED_SOURCES})

    # Second case: We only want to check real sources,
    # so filter out generated ones.
    else (${PREFIX}_CHECK_GENERATED)

        _filter_out_generated_sources (_FILTERED_SOURCES
                                       SOURCES
                                       ${HANDLE_CHECK_GENERATED_SOURCES})

    endif (${PREFIX}_CHECK_GENERATED)

    set (${SOURCES_RETURN} ${_FILTERED_SOURCES} PARENT_SCOPE)

endfunction (_handle_check_generated_option)

function (_assert_set VARIABLE)

    if (NOT VARIABLE)

        message (FATAL_ERROR "${ARGN}")

    endif (NOT VARIABLE)

endfunction (_assert_set)

function (_polysquare_forward_options PREFIX RETURN_LIST_NAME)

    set (FORWARD_OPTION_ARGS "")
    set (FORWARD_SINGLEVAR_ARGS "")
    set (FORWARD_MULTIVAR_ARGS
         OPTION_ARGS
         SINGLEVAR_ARGS
         MULTIVAR_ARGS)

    cmake_parse_arguments (FORWARD
                           "${FORWARD_OPTION_ARGS}"
                           "${FORWARD_SINGLEVAR_ARGS}"
                           "${FORWARD_MULTIVAR_ARGS}"
                           ${ARGN})

    # Temporary accumulation of variables to forward
    set (RETURN_LIST)

    # Option args - just forward the value of each set ${REFIX_OPTION_ARG}
    # as this will be set to the option or to ""
    foreach (OPTION_ARG ${FORWARD_OPTION_ARGS})

        set (PREFIXED_OPTION_ARG ${PREFIX}_${OPTION_ARG})

        if (${PREFIXED_OPTION_ARG})

             list (APPEND RETURN_LIST ${OPTION_ARG})

        endif (${PREFIXED_OPTION_ARG})

    endforeach ()

    # Single-variable args - add the name of the argument and its value to
    # the return list
    foreach (SINGLEVAR_ARG ${FORWARD_SINGLEVAR_ARGS})

        set (PREFIXED_SINGLEVAR_ARG ${PREFIX}_${SINGLEVAR_ARG})
        list (APPEND RETURN_LIST ${SINGLEVAR_ARG})
        list (APPEND RETURN_LIST ${${PREFIXED_SINGLEVAR_ARG}})

    endforeach ()

    # Multi-variable args - add the name of the argument and all its values
    # to the return-list
    foreach (MULTIVAR_ARG ${FORWARD_MULTIVAR_ARGS})

        set (PREFIXED_MULTIVAR_ARG ${PREFIX}_${MULTIVAR_ARG})
        list (APPEND RETURN_LIST ${MULTIVAR_ARG})

        foreach (VALUE ${${PREFIXED_MULTIVAR_ARG}})

            list (APPEND RETURN_LIST ${VALUE})

        endforeach ()

    endforeach ()

    set (${RETURN_LIST_NAME} ${RETURN_LIST} PARENT_SCOPE)

endfunction ()

function (_sort_sources_to_languages C_SOURCES CXX_SOURCES)

    set (SORT_SOURCES_SINGLEVAR_OPTIONS FORCE_LANGUAGE)
    set (SORT_SOURCES_MULTIVAR_OPTIONS
         SOURCES
         CPP_IDENTIFIERS
         INCLUDES)
    cmake_parse_arguments (SORT_SOURCES
                           ""
                           "${SORT_SOURCES_SINGLEVAR_OPTIONS}"
                           "${SORT_SOURCES_MULTIVAR_OPTIONS}"
                           ${ARGN})

    _polysquare_forward_options (SORT_SOURCES
                                 DETERMINE_LANG_OPTIONS
                                 SINGLEVAR_ARGS FORCE_LANGUAGE
                                 MULTIVAR_ARGS CPP_IDENTIFIERS INCLUDES)

    foreach (SOURCE ${SORT_SOURCES_SOURCES})

        set (LANGUAGE ${SORT_SOURCES_FORCE_LANGUAGE})

        if (NOT LANGUAGE)

            set (INCLUDES ${SORT_SOURCES_INCLUDES})
            set (CPP_IDENTIFIERS ${SORT_SOURCES_CPP_IDENTIFIERS})
            polysquare_determine_language_for_source (${SOURCE}
                                                      LANGUAGE
                                                      SOURCE_WAS_HEADER
                                                      ${DETERMINE_LANG_OPTIONS})

            # Scan this source for headers, we'll need them later
            if (NOT SOURCE_WAS_HEADER)

                polysquare_scan_source_for_headers (SOURCE ${SOURCE}
                                                    ${DETERMINE_LANG_OPTIONS})

            endif (NOT SOURCE_WAS_HEADER)

        endif (NOT LANGUAGE)

        list (FIND LANGUAGE "C" C_INDEX)
        list (FIND LANGUAGE "CXX" CXX_INDEX)

        if (NOT C_INDEX EQUAL -1)

            list (APPEND _C_SOURCES ${SOURCE})

        endif (NOT C_INDEX EQUAL -1)

        if (NOT CXX_INDEX EQUAL -1)

            list (APPEND _CXX_SOURCES ${SOURCE})

        endif (NOT CXX_INDEX EQUAL -1)

    endforeach ()

    set (${C_SOURCES} ${_C_SOURCES} PARENT_SCOPE)
    set (${CXX_SOURCES} ${_CXX_SOURCES} PARENT_SCOPE)

endfunction (_sort_sources_to_languages)
