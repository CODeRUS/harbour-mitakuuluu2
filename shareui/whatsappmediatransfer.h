#ifndef WHATSAPPMEDIATRANSFER_H
#define WHATSAPPMEDIATRANSFER_H

#include <TransferEngine-qt5/mediatransferinterface.h>
#include <TransferEngine-qt5/mediaitem.h>

#include <QtDBus/QtDBus>

#define SERVER_INTERFACE "harbour.mitakuuluu2.server"
#define SERVER_SERVICE "harbour.mitakuuluu2.server"
#define SERVER_PATH "/"

class MitakuuluuMediaTransfer : public MediaTransferInterface
{
    Q_OBJECT
public:
    MitakuuluuMediaTransfer(QObject * parent = 0);
    ~MitakuuluuMediaTransfer();

    bool	cancelEnabled() const;
    QString	displayName() const;
    bool	restartEnabled() const;
    QUrl	serviceIcon() const;

private:
    QDBusInterface *_iface;
    QString _mediaName;
    QString _messageId;

private slots:
    void uploadMediaProgress(const QString &jid, const QString &msgId, int percent);
    void uploadMediaFinished(const QString &jid, const QString &msgId, const QString &remoteUrl);
    void uploadMediaStarted(const QString &jid, const QString &msgId, const QString &localUrl);
    void uploadMediaFailed(const QString &jid, const QString &msgId);

public slots:
    void	cancel();
    void	start();

};

#endif // WHATSAPPMEDIATRANSFER_H
