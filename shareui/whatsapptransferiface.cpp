#include "whatsapptransferiface.h"
#include "whatsappplugininfo.h"
#include "whatsappmediatransfer.h"

#include <QtPlugin>

MitakuuluuSharePlugin::MitakuuluuSharePlugin()
{

}

MitakuuluuSharePlugin::~MitakuuluuSharePlugin()
{

}

QString MitakuuluuSharePlugin::pluginId() const
{
    return QLatin1String("MitakuuluuSharePlugin");
}

bool MitakuuluuSharePlugin::enabled() const
{
    return true;
}

TransferPluginInfo *MitakuuluuSharePlugin::infoObject()
{
    return new MitakuuluuPluginInfo;
}

MediaTransferInterface *MitakuuluuSharePlugin::transferObject()
{
    return new MitakuuluuMediaTransfer;
}
