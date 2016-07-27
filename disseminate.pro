#-------------------------------------------------
#
# Project created by QtCreator 2016-07-26T21:54:38
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = disseminate
TEMPLATE = app

CONFIG += c++11

SOURCES += main.cpp\
    Disseminate.cpp \
    WindowSelector.cpp \
    WindowSelectorOSX.mm

HEADERS  += Disseminate.h \
    WindowSelector.h \
    WindowSelectorOSX.h

FORMS    += Disseminate.ui \
    WindowSelector.ui

RESOURCES += \
    icons.qrc

LIBS += -framework Foundation -framework CoreFoundation -framework CoreGraphics
