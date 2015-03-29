#ifndef CONTACTSBASEMODEL_H
#define CONTACTSBASEMODEL_H

#include <QObject>
#include <QHash>
#include <QVariantMap>
#include <QStringList>
#include <QAbstractListModel>

#include <QtSql/QtSql>

#include <QtDBus/QtDBus>

#include <QColor>

#include <QDebug>

#include "../threadworker/queryexecutor.h"

class ContactsBaseModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int totalUnread READ getTotalUnread NOTIFY totalUnreadChanged)
    Q_PROPERTY(int count READ count FINAL)
public:
    explicit ContactsBaseModel(QObject *parent = 0);
    virtual ~ContactsBaseModel();

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
    virtual QHash<int, QByteArray> roleNames() const { return _roles; }

public slots:
    int count();
    void reloadContact(const QString &jid);
    void setPropertyByJid(const QString &jid, const QString &name, const QVariant &value);
    void deleteContact(const QString &jid);
    QVariantMap getModel(const QString &jid);
    QVariantMap get(int index);
    QColor getColorForJid(const QString &jid);
    void renameContact(const QString &jid, const QString &name);
    void requestAvatar(const QString &jid);
    void clearChat(const QString &jid);
    void createBroadcast(const QStringList &jids);
    void renameBroadcast(const QString &jid, const QString &name);

    void clear();
    void contactsChanged();

private:
    bool getAvailable(const QString &jid);
    bool getBlocked(const QString &jid);

    QString getNicknameBy(const QString &jid, const QString &message, const QString &name, const QString &pushname);

    QColor generateColor();
    QHash<QString, QColor> _colors;

    QStringList _keys;

    QHash<QString, QVariantMap> _modelData;
    QHash<int, QByteArray> _roles;
    QSqlDatabase db;
    QDBusInterface *iface;

    QueryExecutor *dbExecutor;

    QString uuid;

    int _totalUnread;
    int getTotalUnread();
    void checkTotalUnread();

    QStringList _blockedContacts;
    QStringList _availableContacts;

signals:
    void nicknameChanged(const QString &pjid, const QString &nickname);
    void statusChanged(const QString &pjid, const QString &message, int ptimestamp);
    void totalUnreadChanged();
    void deleteEverythingSuccessful();
    void conversationClean(const QString &pjid);
    void broadcastCreated(const QString &bjid, const QStringList &bjids);

private slots:
    void pictureUpdated(const QString &jid, const QString &path);
    void groupInfo(const QVariantMap &data);
    void contactChanged(const QVariantMap &data);
    void contactSynced(const QVariantMap &data);
    void contactStatus(const QString &jid, const QString &message, int timestamp);
    void newGroupSubject(const QVariantMap &data);
    void setUnread(const QString &jid, int count);
    void pushnameUpdated(const QString &jid, const QString &pushName);
    void presenceAvailable(const QString &jid);
    void presenceUnavailable(const QString &jid);
    void presenceLastSeen(const QString jid, int timestamp);
    void messageReceived(const QVariantMap &data);
    void dbResults(const QVariant &result);
    void contactsBlocked(const QStringList &jids);
    void contactsAvailable(const QStringList &jids);
    void contactTyping(const QString &jid);
    void contactPaused(const QString &jid);
    void contactRemoved(const QString &jid);
};

#endif // CONTACTSBASEMODEL_H
