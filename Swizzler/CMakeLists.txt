cmake_minimum_required(VERSION 2.8)
include_directories(${CMAKE_CURRENT_LIST_DIR})
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")

set(SOURCES main.mm)

find_library(COCOA_FOUNDATION Foundation)
find_library(COCOA_APPKIT AppKit)

add_library(Swizzler SHARED ${SOURCES})
target_link_libraries(Swizzler ${COCOA_FOUNDATION} ${COCOA_APPKIT})
