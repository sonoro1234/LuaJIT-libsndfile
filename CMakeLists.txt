PROJECT(libsndfile_ffi)
#to allow install from subdirectory
cmake_minimum_required(VERSION 3.13)
if(WIN32) #to mingw work as all the others
set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif(WIN32)

set(BUILD_SHARED_LIBS ON CACHE INTERNAL "build shared!")
set(BUILD_PROGRAMS OFF CACHE INTERNAL "dont build programs")
set(BUILD_TESTING OFF CACHE INTERNAL "dont build testing")
set(BUILD_EXAMPLES OFF CACHE INTERNAL "dont build examples")
set(ENABLE_CPACK OFF CACHE INTERNAL "disable cpack")
set(ENABLE_STATIC_RUNTIME OFF CACHE INTERNAL "disable static runtime")
set(ENABLE_PACKAGE_CONFIG OFF CACHE INTERNAL "disable package config")
add_subdirectory(libsndfile EXCLUDE_FROM_ALL)
add_subdirectory(libsamplerate EXCLUDE_FROM_ALL)
set_target_properties(sndfile PROPERTIES NO_SONAME 1)
set_target_properties(samplerate PROPERTIES OUTPUT_NAME "samplerate")

add_custom_target(sndfile_ffi ALL)
add_dependencies(sndfile_ffi sndfile samplerate)

install(TARGETS sndfile samplerate RUNTIME DESTINATION ${LUAJIT_BIN} LIBRARY DESTINATION ${LUAJIT_BIN})
INSTALL(FILES sndfile_ffi.lua samplerate.lua DESTINATION ${LUAJIT_BIN}/lua)


