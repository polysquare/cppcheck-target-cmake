# /FindCPPCHECK.cmake
#
# This CMake script will search for cppcheck and set the following
# variables
#
# CPPCHECK_FOUND : Whether or not cppcheck is available on the target system
# CPPCHECK_VERSION : Version of cppcheck
# CPPCHECK_EXECUTABLE : Fully qualified path to the cppcheck executable
#
# The following variables will affect the operation of this script
# CPPCHECK_SEARCH_PATHS : List of directories to search for cppcheck in, before
#                         searching any system paths. This should be the prefix
#                         to which cppcheck was installed, and not the path
#                         that contains the cppcheck binary. Eg /opt/ not
#                         /opt/bin/
#
# See /LICENCE.md for Copyright information

include ("cmake/tooling-find-pkg-util/ToolingFindPackageUtil")

function (cppcheck_find)

    if (DEFINED CPPCHECK_FOUND)

        return ()

    endif ()

    # Set-up the directory tree of the cppcheck installation
    set (BIN_SUBDIR bin)
    set (CPPCHECK_EXECUTABLE_NAME cppcheck)

    psq_find_tool_executable (${CPPCHECK_EXECUTABLE_NAME}
                              CPPCHECK_EXECUTABLE
                              PATHS ${CPPCHECK_SEARCH_PATHS}
                              PATH_SUFFIXES "${BIN_SUBDIR}")

    psq_report_not_found_if_not_quiet (CPPCheck CPPCHECK_EXECUTABLE
                                       "The 'cppcheck' executable was not found"
                                       "in any search or system paths.\n.."
                                       "Please adjust CPPCHECK_SEARCH_PATHS"
                                       "to the installation prefix of the"
                                       "'cppcheck'\n.. executable or install"
                                       "cppcheck")

    if (CPPCHECK_EXECUTABLE)

        psq_find_tool_extract_version ("${CPPCHECK_EXECUTABLE}" CPPCHECK_VERSION
                                       VERSION_ARG --version
                                       VERSION_HEADER "Cppcheck "
                                       VERSION_END_TOKEN " ")

        # Check the version of cppcheck. If it is < 1.58 output a warning about
        # detecting the language of header files
        if (${CPPCHECK_VERSION} VERSION_LESS 1.58)

            psq_print_if_not_quiet (CPPCheck
                                    MSG "Only cppcheck versions >= 1.58"
                                        "support specifying a language for"
                                        "analysis. You may encounter false"
                                        "positives when scanning header"
                                        "files if cppcheck is unable to"
                                        "determine their source language."
                                        "Consider upgrading to a newer"
                                        "version of cppcheck, such that"
                                        "this script can specify the"
                                        "language of your header files"
                                        "after detecting them")

        endif ()

    endif ()

    psq_check_and_report_tool_version (CPPCheck
                                       "${CPPCHECK_VERSION}"
                                       REQUIRED_VARS
                                       CPPCHECK_EXECUTABLE
                                       CPPCHECK_VERSION)

    set (CPPCHECK_FOUND # NOLINT:style/set_var_case
         ${CPPCHECK_FOUND}
         PARENT_SCOPE)

endfunction ()

cppcheck_find ()
