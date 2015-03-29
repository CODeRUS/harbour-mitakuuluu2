#include "translatorplugin.h"
#include "translator.h"

#include <qqml.h>

void TranslatorPlugin::registerTypes(const char *uri)
{
    // @uri harbour.mitakuuluu2.translator
    qmlRegisterType<Translator>(uri, 1, 0, "Translator");
}
