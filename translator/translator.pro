TEMPLATE = lib
QT += quick sql core dbus
CONFIG += qt plugin link_pkgconfig
PKGCONFIG += mlite5
INCLUDEPATH += /usr/include/mlite5

TARGET = $$qtLibraryTarget(translator)
target.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/translator

SOURCES += \
    translatorplugin.cpp \
    translator.cpp

HEADERS += \
    translatorplugin.h \
    translator.h

qmldir.files = qmldir
qmldir.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/translator

INSTALLS += target qmldir
