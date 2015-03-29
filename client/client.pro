TARGET = harbour-mitakuuluu2
target.path = /usr/bin

QT += sql dbus core multimedia sensors
CONFIG += sailfishapp link_pkgconfig
#CONFIG += qml_debug
PKGCONFIG += sailfishapp gstreamer-0.10 Qt5Sensors mlite5 dconf

INCLUDEPATH += /usr/include/mlite5

images.files = images/
images.path = /usr/share/harbour-mitakuuluu2

emoji.files = emoji/
emoji.path = /usr/share/harbour-mitakuuluu2

dbus.files = dbus/harbour.mitakuuluu2.client.service
dbus.path = /usr/share/dbus-1/services

qmls.files = qml
qmls.path = /usr/share/$${TARGET}

desktops.files = $${TARGET}.desktop
desktops.path = /usr/share/applications

icons.files = $${TARGET}.png
icons.path = /usr/share/icons/hicolor/86x86/apps

presets.files = presets
presets.path = /usr/share/harbour-mitakuuluu2

INSTALLS = images dbus emoji qmls desktops icons presets

SOURCES += \
    src/audiorecorder.cpp \
    ../threadworker/threadworker.cpp \
    ../threadworker/queryexecutor.cpp \
    ../qexifimageheader/qexifimageheader.cpp \
    src/conversationmodel.cpp \
    src/mitakuuluu.cpp \
    src/contactsfiltermodel.cpp \
    src/contactsbasemodel.cpp \
    src/main.cpp \
    src/conversationfiltermodel.cpp \
    ../dconf/dconfvalue.cpp \
    ../dconf/mdconf.cpp \
    ../dconf/mdconfitem.cpp

HEADERS += \
    ../threadworker/threadworker.h \
    ../threadworker/queryexecutor.h \
    ../qexifimageheader/qexifimageheader.h \
    src/profile_dbus.h \
    src/constants.h \
    src/conversationmodel.h \
    src/mitakuuluu.h \
    src/audiorecorder.h \
    ../logging/logging.h \
    src/contactsfiltermodel.h \
    src/contactsbasemodel.h \
    src/conversationfiltermodel.h \
    ../dconf/dconfvalue.h \
    ../dconf/mdconf_p.h \
    ../dconf/mdconfitem.h \
    ../dconf/dconfmigration.h

OTHER_FILES += \
    qml/MediaPreview.qml
