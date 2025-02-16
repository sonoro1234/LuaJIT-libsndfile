cmake_minimum_required(VERSION 3.13)
PROJECT(xiph)
#include(CMakePrintHelpers)
function (build_external_project target repo tag args)# source_dir argn)
    #cmake_print_variables(args)
    set(EXT_BUILDS ${CMAKE_CURRENT_BINARY_DIR}/ext_builds)
    set(XIPH_BUILD ${EXT_BUILDS}/${target})
    if(NOT EXISTS ${XIPH_BUILD}/install)
        include(FetchContent)
        Set(FETCHCONTENT_QUIET FALSE)
        FetchContent_Declare(
                ${target}
                GIT_REPOSITORY ${repo}
                GIT_TAG ${tag}
                GIT_PROGRESS TRUE
        )
        FetchContent_GetProperties(${target})
        if (NOT ${target}_POPULATED)
            set(FETCHCONTENT_QUIET NO)
            FetchContent_Populate(${target})
        endif()
    
        file(MAKE_DIRECTORY ${XIPH_BUILD})
        set(EXECUTE_COMMAND ${CMAKE_COMMAND}  -G${CMAKE_GENERATOR} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}  -DCMAKE_INSTALL_PREFIX=${XIPH_BUILD}/install ${args} ${${target}_SOURCE_DIR})
    
        #cmake_print_variables("EXECUTE_COMMANDis" EXECUTE_COMMAND)
        message(STATUS "       ------------------ cmake configuring " ${target} "------------------------------")
        execute_process(COMMAND ${EXECUTE_COMMAND} 
                WORKING_DIRECTORY ${XIPH_BUILD}
                )
        message(STATUS "        ----------------- building " ${target} "------------------------------")
        execute_process(COMMAND ${CMAKE_COMMAND} --build . --target install
            WORKING_DIRECTORY ${XIPH_BUILD}
            RESULT_VARIABLE build_command_result
            )
        message(STATUS "build_command_result: " ${build_command_result} "---------------------------------")
    endif()#NOT EXISTS ${XIPH_BUILD}/install)
    set(installed_dir ${XIPH_BUILD}/install PARENT_SCOPE)
endfunction()

message(STATUS "--------------build extenal Ogg------------------------")
set(argsOgg "-DBUILD_TESTING=off" "-DINSTALL_DOCS=off")
build_external_project(ogg https://github.com/xiph/ogg.git v1.3.5 "${argsOgg}")
set(Ogg_ROOT ${installed_dir})
set(Ogg_ROOT ${Ogg_ROOT} PARENT_SCOPE)

message(STATUS "--------------build extenal FLAC------------------------")
set(argsFLAC "-DOgg_ROOT=${Ogg_ROOT}" "-DINSTALL_MANPAGES=off" "-DBUILD_CXXLIBS=off" "-DBUILD_PROGRAMS=off" "-DBUILD_EXAMPLES=off" "-DBUILD_TESTING=off" "-DBUILD_DOCS=off")
build_external_project(flac https://github.com/xiph/flac.git 1.5.0 "${argsFLAC}")
set(FLAC_ROOT ${installed_dir} PARENT_SCOPE)

message(STATUS "--------------build extenal Vorbis------------------------")
set(argsVorbis "-DOgg_ROOT=${Ogg_ROOT}" "-DCMAKE_POLICY_DEFAULT_CMP0074=NEW")
build_external_project(vorbis https://github.com/xiph/vorbis.git v1.3.7 "${argsVorbis}")
set(Vorbis_ROOT ${installed_dir} PARENT_SCOPE)

message(STATUS "--------------build extenal Opus------------------------")
set(argsOpus "")
build_external_project(opus https://github.com/xiph/opus.git v1.5.2 "${argsOpus}")
set(Opus_ROOT ${installed_dir} PARENT_SCOPE)
