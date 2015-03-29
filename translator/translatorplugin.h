#ifndef TRANSLATORPLUGIN_H
#define TRANSLATORPLUGIN_H

#include <QQmlExtensionPlugin>

class TranslatorPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);

};

#endif // TRANSLATORPLUGIN_H
