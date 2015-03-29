#ifndef FILEMODELPLUGIN_H
#define FILEMODELPLUGIN_H

#include <QQmlExtensionPlugin>

class FilemodelPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);

};

#endif // FILEMODELPLUGIN_H
