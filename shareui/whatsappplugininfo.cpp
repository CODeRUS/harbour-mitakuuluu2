#include "whatsappplugininfo.h"

MitakuuluuPluginInfo::MitakuuluuPluginInfo(): m_ready(false)
{
}

MitakuuluuPluginInfo::~MitakuuluuPluginInfo()
{

}

QList<TransferMethodInfo> MitakuuluuPluginInfo::info() const
{
    return m_infoList;
}

void MitakuuluuPluginInfo::query()
{
    TransferMethodInfo info;

    QStringList capabilities;
    capabilities << QLatin1String("image/*")
                 << QLatin1String("audio/*")
                 << QLatin1String("video/*")
                 << QLatin1String("text/vcard");

    info.displayName     = QLatin1String("Mitakuuluu");
    info.methodId        = QLatin1String("MitakuuluuSharePlugin");
    info.shareUIPath     = QLatin1String("/usr/share/harbour-mitakuuluu2/qml/ShareUI.qml");
    info.capabilitities  = capabilities;
    m_infoList.clear();
    m_infoList << info;

    m_ready = true;
    Q_EMIT infoReady();
}

bool MitakuuluuPluginInfo::ready() const
{
    return m_ready;
}
