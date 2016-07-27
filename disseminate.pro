#-------------------------------------------------
#
# Project created by QtCreator 2016-07-26T21:54:38
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = disseminate
TEMPLATE = app

ICON = icons/AppIcon.icns

CONFIG += c++11 debug

SOURCES += main.cpp\
    Disseminate.cpp \
    Utils.mm \
    WindowSelector.cpp \
    WindowSelectorOSX.mm \
    KeyInput.cpp \
    Preferences.cpp

HEADERS  += Disseminate.h \
    Item.h \
    Utils.h \
    WindowSelector.h \
    WindowSelectorOSX.h \
    KeyInput.h \
    Preferences.h

FORMS    += Disseminate.ui \
    WindowSelector.ui \
    KeyInput.ui \
    Preferences.ui

RESOURCES += \
    icons.qrc

LIBS += -framework Foundation -framework CoreFoundation -framework CoreGraphics -framework ApplicationServices -framework AppKit
