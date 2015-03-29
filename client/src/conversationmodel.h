#ifndef CONVERSATIONMODEL_H
#define CONVERSATIONMODEL_H

#include <QObject>
#include <QHash>
#include <QVariantMap>
#include <QStringList>

#include <QAbstractListModel>

#include <QtSql/QtSql>

#include <QtDBus/QtDBus>

#include <QTimer>

#include <QDebug>

#include "../threadworker/queryexecutor.h"

class TimestampMsgidPair
{
public:
    TimestampMsgidPair(int timestamp, const QString &msgId) {
        _timestamp = timestamp;
        _msgid = msgId;
    }
    bool operator <(const TimestampMsgidPair &target) const {
        bool result = _timestamp > target._timestamp;
        return result;
    }
    TimestampMsgidPair& operator =(const TimestampMsgidPair &from) {
        _timestamp = from._timestamp;
        _msgid = from._msgid;
        return *this;
    }
    friend QDebug operator<< (QDebug d, const TimestampMsgidPair &data) {
        d << "{" << data._timestamp << ":" << data._msgid << ")";
        return d;
    }
    int _timestamp;
    QString _msgid;
};

class ConversationModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString jid READ getJid WRITE loadLastConversation FINAL)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int allCount READ allCount NOTIFY allCountChanged)
public:
    ConversationModel(QObject *parent = 0);
    ~ConversationModel();

    void loadLastConversation(QString newjid);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    virtual QHash<int, QByteArray> roleNames() const { return _roles; }

    QString getJid() { return jid; }
    QString jid;
    QString table;

public slots:
    void reloadConversation();
    void setPropertyByMsgId(const QString &msgId, const QString &name, const QVariant &value);
    void loadOldConversation(int count = 20);
    void deleteMessage(const QString &msgId, const QString &myJid, bool deleteMediaFiles = false);
    QVariantMap get(int index);
    QVariantMap getModelByIndex(int index);
    QVariantMap getModelByMsgId(const QString &msgId);
    void copyToClipboard(const QString &msgId);
    void forwardMessage(const QStringList &jids, const QString &msgId);
    void resendMessage(const QString &jid, const QString& msgId);
    void removeConversation(const QString &rjid);
    int count();
    void requestContactMedia(const QString &sjid);

private:
    int getIndexByMsgId(const QString &msgId);

    QStringList _keys;
    QHash<int, QByteArray> _roles;
    QList<TimestampMsgidPair> _sortedTimestampMsgidList;
    QHash<QString, QVariantMap> _modelData;
    QVariantMap _downloadData;
    QSqlDatabase db;
    QDBusInterface *iface;

    QueryExecutor *dbExecutor;

    bool _loadingBusy;

    QString uuid;

    int _allCount;
    int allCount();
    void getAllCount();

    QString makeTimestampDate(int timestamp);

private slots:
    void onLoadingFree();
    
    void onMessageReceived(const QVariantMap &data);
    void onMessageStatusUpdated(const QString &mjid, const QString &msgId, int msgstatus);
    void onMediaProgress(const QString &mjid, const QString &msgId, int progress);
    void onMediaFinished(const QString &mjid, const QString &msgId, const QString &path);
    void onMediaFailed(const QString &mjid, const QString &msgId);
    void onMediaTitleReceived(const QString &msgid, const QString &title, const QString &mjid);
    void onMediaUploadFinished(const QString &mjid, const QString &msgid, const QString &url);
    void dbResults(const QVariant &result);

signals:
    void lastMessageToBeChanged(const QString &mjid);
    void lastMessageChanged(const QString &mjid, bool force);
    void mediaListReceived(const QString &pjid, const QVariantList &mediaList);

    void countChanged();
    void allCountChanged();

};

#endif // CONVERSATIONMODEL_H
