#ifndef SHARECONTACTSPLUGIN_H
#define SHARECONTACTSPLUGIN_H

#include <QQmlExtensionPlugin>

class TranslatorPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);

};

#endif // SHARECONTACTSPLUGIN_H
