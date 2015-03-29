#ifndef SHARECONTACTSBASEMODEL_H
#define SHARECONTACTSBASEMODEL_H

#include <QObject>
#include <QHash>
#include <QVariantMap>
#include <QStringList>
#include <QAbstractListModel>

#include <QtSql/QtSql>
#include <QtDBus/QtDBus>

#include <QDebug>

#define SERVER_INTERFACE "harbour.mitakuuluu2.server"
#define SERVER_SERVICE "harbour.mitakuuluu2.server"
#define SERVER_PATH "/"

class ShareContactsBaseModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count FINAL)
public:
    explicit ShareContactsBaseModel(QObject *parent = 0);
    virtual ~ShareContactsBaseModel();

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
    virtual QHash<int, QByteArray> roleNames() const { return _roles; }
    QVariantMap get(int index);

public slots:
    void startSharing(const QStringList &jids, const QString &name, const QString &data);

private:
    void setPropertyByJid(const QString &jid, const QString &name, const QVariant &value);
    int count();

    QString getNicknameBy(const QString &jid, const QString &message, const QString &name, const QString &pushname);

    QStringList _keys;

    QHash<QString, QVariantMap> _modelData;
    QHash<int, QByteArray> _roles;
    QSqlDatabase db;
    QDBusInterface *iface;

signals:
    void nicknameChanged(const QString &pjid, const QString &nickname);

private slots:
    void pictureUpdated(const QString &jid, const QString &path);
    void contactChanged(const QVariantMap &data);
    void contactSynced(const QVariantMap &data);
    void contactStatus(const QString &jid, const QString &message);
    void newGroupSubject(const QVariantMap &data);
    void pushnameUpdated(const QString &jid, const QString &pushName);
};

#endif // SHARECONTACTSBASEMODEL_H
