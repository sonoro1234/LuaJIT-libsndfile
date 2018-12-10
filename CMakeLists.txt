PROJECT(libsndfile_ffi)
#to allow install from subdirectory
cmake_minimum_required(VERSION 3.13)
set(CMAKE_SHARED_LIBRARY_PREFIX "")

set(BUILD_SHARED_LIBS ON CACHE INTERNAL "build shared!")
set(BUILD_PROGRAMS OFF CACHE INTERNAL "dont build programs")
set(BUILD_TESTING OFF CACHE INTERNAL "dont build testing")
set(BUILD_EXAMPLES OFF CACHE INTERNAL "dont build examples")
set(ENABLE_CPACK OFF CACHE INTERNAL "disable cpack")
set(ENABLE_STATIC_RUNTIME OFF CACHE INTERNAL "disable static runtime")
set(ENABLE_PACKAGE_CONFIG OFF CACHE INTERNAL "disable package config")
add_subdirectory(libsndfile) #EXCLUDE_FROM_ALL)


install(TARGETS sndfile RUNTIME DESTINATION ${LUAJIT_BIN})
INSTALL(FILES sndfile_ffi.lua DESTINATION ${LUAJIT_BIN}/lua)


