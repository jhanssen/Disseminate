#-------------------------------------------------
#
# Project created by QtCreator 2016-07-26T21:54:38
#
#-------------------------------------------------

QT       += core gui macextras

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = Disseminate
TEMPLATE = app

ICON = icons/AppIcon.icns

CONFIG += c++11

#CONFIG += debug
#QMAKE_CXXFLAGS += -fsanitize=address
#QMAKE_LFLAGS += -fsanitize=address

SOURCES += main.cpp\
    Disseminate.cpp \
    Utils.mm \
    WindowSelector.cpp \
    WindowSelectorOSX.mm \
    KeyInput.cpp \
    Preferences.cpp \
    Templates.cpp \
    TemplateChooser.cpp

HEADERS  += Disseminate.h \
    Item.h \
    Utils.h \
    WindowSelector.h \
    WindowSelectorOSX.h \
    KeyInput.h \
    Preferences.h \
    Helpers.h \
    Templates.h \
    TemplateChooser.h

FORMS    += Disseminate.ui \
    WindowSelector.ui \
    KeyInput.ui \
    Preferences.ui \
    Templates.ui \
    TemplateChooser.ui

RESOURCES += \
    icons.qrc

LIBS += -framework Foundation -framework CoreFoundation -framework CoreGraphics -framework ApplicationServices -framework AppKit
