#include "sharecontactsplugin.h"
#include "sharecontactsfiltermodel.h"

#include <qqml.h>

void TranslatorPlugin::registerTypes(const char *uri)
{
    // @uri harbour.mitakuuluu2.sharecontacts
    qmlRegisterType<ShareContactsFilterModel>(uri, 1, 0, "ShareContactsModel");
}
