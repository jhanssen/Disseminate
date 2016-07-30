cmake_minimum_required(VERSION 3.2)
include_directories(${CMAKE_CURRENT_LIST_DIR})

cmake_policy(SET CMP0042 NEW)

include(ExternalProject)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")

set(SOURCES main.mm MessagePort.mm EventLoop.mm ScriptEngine.mm)

find_library(COCOA_FOUNDATION Foundation)
find_library(COCOA_APPKIT AppKit)

if(NOT IS_DIRECTORY Selene)
    execute_process(COMMAND git submodule update --init)
endif()

ExternalProject_Add(
    lua
    BINARY_DIR ${CMAKE_BINARY_DIR}/externals/lua-build
    URL http://www.lua.org/ftp/lua-5.3.3.tar.gz
    URL_HASH SHA256=5113c06884f7de453ce57702abaac1d618307f33f6789fa870e87a59d772aca2
    PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/externals/lua-prefix
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/externals/lua-source
    CONFIGURE_COMMAND ""
    BUILD_COMMAND make -C ${CMAKE_CURRENT_SOURCE_DIR}/externals/lua-source macosx
    INSTALL_DIR ${CMAKE_BINARY_DIR}/externals/lua
    INSTALL_COMMAND make INSTALL_TOP=${CMAKE_BINARY_DIR}/externals/lua -C ${CMAKE_CURRENT_SOURCE_DIR}/externals/lua-source install
    )

find_library(LUA_LIBRARY lua HINTS ${CMAKE_BINARY_DIR}/externals/lua/lib)
find_path(LUA_INCLUDE_DIR lua.h HINTS ${CMAKE_BINARY_DIR}/externals/lua/include)

add_library(Swizzler SHARED ${SOURCES})
include_directories(${LUA_INCLUDE_DIR} ${CMAKE_CURRENT_LIST_DIR}/Selene/include)
target_link_libraries(Swizzler ${COCOA_FOUNDATION} ${COCOA_APPKIT} ${LUA_LIBRARY} ${FLATBUFFERS_LIBRARY})
