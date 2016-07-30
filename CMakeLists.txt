cmake_minimum_required(VERSION 3.2)

project(Disseminate)

if(NOT IS_DIRECTORY flatbuffers)
    execute_process(COMMAND git submodule update --init)
endif()

add_subdirectory(flatbuffers)
add_subdirectory(Swizzler)

# Find includes in corresponding build directories
set(CMAKE_INCLUDE_CURRENT_DIR ON)
# Instruct CMake to run moc automatically when needed.
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)

# Find the QtWidgets library
find_package(Qt5Widgets REQUIRED)
find_package(Qt5MacExtras REQUIRED)

qt5_add_resources(ICONS_QRC icons.qrc)

set(MACOSX_BUNDLE_INFO_FILE Info.plist.in)
set_source_files_properties(icons/AppIcon.icns PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

#-framework Foundation -framework CoreFoundation -framework CoreGraphics -framework ApplicationServices -framework AppKit
find_library(COCOA_FOUNDATION Foundation)
find_library(COCOA_COREFOUNDATION CoreFoundation)
find_library(COCOA_COREGRAPHICS CoreGraphics)
find_library(COCOA_APPLICATIONSERVICES ApplicationServices)
find_library(COCOA_APPKIT AppKit)

set(COCOA_LIBRARIES
    ${COCOA_FOUNDATION}
    ${COCOA_COREFOUNDATION}
    ${COCOA_COREGRAPHICS}
    ${COCOA_APPLICATIONSERVICES}
    ${COCOA_APPKIT}
    )

set(SOURCES
    main.cpp
    Disseminate.cpp
    Utils.mm
    WindowSelector.cpp
    WindowSelectorOSX.mm
    KeyInput.cpp
    Preferences.cpp
    Templates.cpp
    TemplateChooser.cpp
    ${ICONS_QRC}
    )

# Tell CMake to create the helloworld executable
add_executable(Disseminate MACOSX_BUNDLE icons/AppIcon.icns ${SOURCES})

# Use the Widgets module from Qt 5.
target_link_libraries(Disseminate Qt5::Widgets Qt5::MacExtras ${COCOA_LIBRARIES})

set_target_properties(Disseminate PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in)
