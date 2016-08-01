cmake_minimum_required(VERSION 3.2)

project(Disseminate)

if(NOT IS_DIRECTORY flatbuffers)
    execute_process(COMMAND git submodule update --init)
endif()

add_subdirectory(flatbuffers)

find_library(FLATBUFFERS_LIBRARY flatbuffers HINTS ${CMAKE_BINARY_DIR}/flatbuffers)
include_directories(flatbuffers/include buffers common)

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
    ProcessInformation.mm
    KeyInput.cpp
    Preferences.cpp
    Templates.cpp
    TemplateChooser.cpp
    common/MessagePort.mm
    ${ICONS_QRC}
    )

# Tell CMake to create the helloworld executable
add_executable(Disseminate MACOSX_BUNDLE icons/AppIcon.icns ${SOURCES})

set(FLATBUFFERS_FLATC_EXECUTABLE flatbuffers/flatc)
function(buffers_to_cpp TARGET SRC_FBS)
  get_filename_component(SRC_FBS_DIR ${SRC_FBS} PATH)
  string(REGEX REPLACE "\\.fbs$" "_generated.h" GEN_HEADER ${SRC_FBS})
  add_custom_target(
      ${TARGET}
      COMMAND "${FLATBUFFERS_FLATC_EXECUTABLE}" -c --no-includes --gen-mutable
              --gen-object-api -o "${SRC_FBS_DIR}"
              "${CMAKE_CURRENT_SOURCE_DIR}/${SRC_FBS}"
              )
  add_dependencies(Disseminate ${TARGET})
endfunction()

set(FLATFILES
    buffers/MouseEvent.fbs
    )

buffers_to_cpp(flatbufferfiles ${FLATFILES})

# Use the Widgets module from Qt 5.
target_link_libraries(Disseminate Qt5::Widgets Qt5::MacExtras ${COCOA_LIBRARIES} ${FLATBUFFERS_LIBRARY})

set_target_properties(Disseminate PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in)
