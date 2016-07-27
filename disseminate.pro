#-------------------------------------------------
#
# Project created by QtCreator 2016-07-26T21:54:38
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = disseminate
TEMPLATE = app

CONFIG += c++11 debug

SOURCES += main.cpp\
    Disseminate.cpp \
    Utils.mm \
    WindowSelector.cpp \
    WindowSelectorOSX.mm \
    KeyInput.cpp

HEADERS  += Disseminate.h \
    Item.h \
    Utils.h \
    WindowSelector.h \
    WindowSelectorOSX.h \
    KeyInput.h

FORMS    += Disseminate.ui \
    WindowSelector.ui \
    KeyInput.ui

RESOURCES += \
    icons.qrc

LIBS += -framework Foundation -framework CoreFoundation -framework CoreGraphics -framework ApplicationServices -framework AppKit
