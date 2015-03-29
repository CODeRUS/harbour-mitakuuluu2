TEMPLATE = lib
QT += quick sql core dbus
CONFIG += qt plugin

TARGET = $$qtLibraryTarget(sharecontacts)
target.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/sharecontacts

SOURCES += \
    sharecontactsplugin.cpp \
    sharecontactsbasemodel.cpp \
    sharecontactsfiltermodel.cpp

HEADERS += \
    sharecontactsplugin.h \
    sharecontactsfiltermodel.h \
    sharecontactsbasemodel.h

qmldir.files = qmldir
qmldir.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/sharecontacts

INSTALLS += target qmldir
