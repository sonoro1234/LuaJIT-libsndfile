cmake_minimum_required(VERSION 3.13)
PROJECT(libsndfile_ffi)

if(WIN32) #to mingw work as all the others
set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif(WIN32)

add_subdirectory(xiph)

set(ENABLE_EXTERNAL_LIBS ON CACHE INTERNAL "xiph!")
set(BUILD_SHARED_LIBS ON CACHE INTERNAL "build shared!")
set(BUILD_PROGRAMS OFF CACHE INTERNAL "dont build programs")
set(BUILD_TESTING OFF CACHE INTERNAL "dont build testing")
set(BUILD_EXAMPLES OFF CACHE INTERNAL "dont build examples")
set(ENABLE_CPACK OFF CACHE INTERNAL "disable cpack")
set(ENABLE_STATIC_RUNTIME OFF CACHE INTERNAL "disable static runtime")
set(ENABLE_PACKAGE_CONFIG OFF CACHE INTERNAL "disable package config")

add_subdirectory(libsndfile EXCLUDE_FROM_ALL)
target_compile_definitions(sndfile PUBLIC FLAC__NO_DLL)

add_subdirectory(libsamplerate EXCLUDE_FROM_ALL)
set_target_properties(sndfile PROPERTIES NO_SONAME 1)
set_target_properties(samplerate PROPERTIES RUNTIME_OUTPUT_NAME "samplerate")

#necessary from cmake 3.14.0 to avoid header installation
set_target_properties (sndfile PROPERTIES PUBLIC_HEADER "")
set_target_properties (samplerate PROPERTIES PUBLIC_HEADER "")

add_custom_target(sndfile_ffi ALL)
add_dependencies(sndfile_ffi sndfile samplerate)

install(TARGETS sndfile samplerate RUNTIME DESTINATION ${LUAJIT_BIN} LIBRARY DESTINATION ${LUAJIT_BIN})
INSTALL(FILES sndfile_ffi.lua samplerate.lua DESTINATION ${LUAJIT_BIN}/lua)


