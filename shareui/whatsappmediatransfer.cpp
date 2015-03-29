#include "whatsappmediatransfer.h"

MitakuuluuMediaTransfer::MitakuuluuMediaTransfer(QObject *parent) :
    MediaTransferInterface(parent)
{
    _iface = new QDBusInterface(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);

    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadFailed", this, SIGNAL(uploadMediaFailed(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadFinished", this, SIGNAL(uploadMediaFinished(QString,QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadStarted", this, SIGNAL(uploadMediaStarted(QString,QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadProgress", this, SIGNAL(uploadMediaProgress(QString,QString,int)));
}

MitakuuluuMediaTransfer::~MitakuuluuMediaTransfer()
{

}

bool MitakuuluuMediaTransfer::cancelEnabled() const
{
    return false;
}

QString MitakuuluuMediaTransfer::displayName() const
{
    return QString("Mitakuuluu");
}

bool MitakuuluuMediaTransfer::restartEnabled() const
{
    return false;
}

QUrl MitakuuluuMediaTransfer::serviceIcon() const
{
    return QUrl::fromLocalFile("/usr/share/harbour-mitakuuluu2/images/notification.png");
}

void MitakuuluuMediaTransfer::uploadMediaProgress(const QString &jid, const QString &msgId, int percent)
{
    Q_UNUSED(jid);
    if (msgId == _messageId) {
        if (percent < 100) {
            qreal s_progress = (qreal)percent / (qreal)100;
            setProgress(s_progress);
        }
        else {
            setStatus(MediaTransferInterface::TransferFinished);
        }
    }
}

void MitakuuluuMediaTransfer::uploadMediaFinished(const QString &jid, const QString &msgId, const QString &remoteUrl)
{
    Q_UNUSED(jid);
    Q_UNUSED(remoteUrl);
    if (msgId == _messageId) {
        setStatus(MediaTransferInterface::TransferFinished);
    }
}

void MitakuuluuMediaTransfer::uploadMediaStarted(const QString &jid, const QString &msgId, const QString &localUrl)
{
    Q_UNUSED(jid);
    if (localUrl == _mediaName) {
        _messageId = msgId;
        setStatus(MediaTransferInterface::TransferStarted);
    }
}

void MitakuuluuMediaTransfer::uploadMediaFailed(const QString &jid, const QString &msgId)
{
    Q_UNUSED(jid);
    if (msgId == _messageId) {
        setStatus(MediaTransferInterface::TransferInterrupted);
    }
}

void MitakuuluuMediaTransfer::cancel()
{
    setStatus(MediaTransferInterface::TransferCanceled);
}

void MitakuuluuMediaTransfer::start()
{
    _mediaName = mediaItem()->value(MediaItem::Url).toString().replace("file://", "");
    if (_iface) {
        QStringList jids = mediaItem()->value(MediaItem::Description).toString().split(",");
        _iface->call(QDBus::NoBlock, "sendMedia", jids, _mediaName);
    }
}
