TARGET = Swizzler
TEMPLATE = lib

CONFIG -= QT

CONFIG += c++11

#CONFIG += debug
#QMAKE_CXXFLAGS += -fsanitize=address
#QMAKE_LFLAGS += -fsanitize=address

SOURCES += main.mm

LIBS += -framework Foundation -framework AppKit
