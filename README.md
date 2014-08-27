cppcheck-target-cmake
=====================

Per-target CPPCheck for CMake

Status
======
[![Build Status](https://travis-ci.org/polysquare/cppcheck-target-cmake.svg?branch=master)](https://travis-ci.org/polysquare/cppcheck-target-cmake)

Static analysis on a group of sources
=====================================
Every check asides from a check for unused methods or functions can be performed on any group of sources after any target in the build has been run. If any checks fail, a fatal error to the build is raised.

Headers will be checked by default if they are part of the check sources, using a technique to scan source files for includes. If header files are part of the sources, they must be listed after sources that include them, such that the language for cppcheck to use will be correct.

To check all sources for a target just before the target links, use `cppcheck_target_sources`. For example:

    cppcheck_target_sources (my_target
                             INCLUDES ${INCLUDE_DIRS})

To check an arbitrary list of sources before some arbitrary target links, use `cppcheck_sources`. For example:

    cppcheck_sources (my_target
                      SOURCES ${SOURCES}
                      INCLUDES ${INCLUDE_DIRS})

The following options may affect the checks run on sources:

  * `WARN_ONLY` : Do not raise a fatal error, only complain by issuing a warning.
  * `CHECK_GENERATED` : Also check `GENERATED` sources in the source list (those that are the output of `add_custom_command`)
  * `CHECK_UNUSED` : Check immediately for unused functions. Note that this option should only be used where functions as specified in the sources provided will not be exported to other sources.
  * `FORCE_LANGUAGE` : Forces the check to run in a specified language. Valid values are `C` and `CXX`.
  * `INCLUDES` : List of include directories to pass to the checking tool.
  * `CPP_IDENTIFIERS` : List of identifiers, which, if found in a header file, would indicate that it can be included in both C and C++ code and should be scanned in both modes.


Checking for unused functions
=============================
Checks for unused functions are generally run over all sources in large group, usually all the sources in a particular library and set of executables or tests using that library.

Sources can be added to an unused function check group with `cppcheck_add_to_global_unused_function_check`. For example

    cppcheck_add_to_global_unused_function_check (check_unused_functions
                                                  TARGETS liba
                                                  SOURCES ${SOURCES_A}
                                                  INCLUDES ${INCLUDES_A})

If `check_unused_functions` did not exist as an unused funciton check group, then a new target called `check_unused_functions` is created. For existing or new targets, the specified sources and include directories are added to it.

If `TARGETS` are specified, then the unused function check target will be made to depend on the `TARGETS` as listed. This is useful to ensure that the unused function check is run when those targets are out of date.

If `CHECK_GENERATED` is specified, then source files marked `GENERATED` will also be checked for unused functions.

Once all sources have been added to an unused function check, it can be "committed" and added to the build with `cppcheck_add_unused_function_check_with_name`

    cppcheck_add_unused_function_check_with_name (check_unused_functions)
