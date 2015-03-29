#include "conversationmodel.h"
#include "constants.h"

#include <QGuiApplication>
#include <QClipboard>

#include <QUuid>
#include <QDateTime>

ConversationModel::ConversationModel(QObject *parent) :
    QAbstractListModel(parent)
{
    _keys << "msgid";
    _keys << "jid";
    _keys << "author";
    _keys << "timestamp";
    _keys << "data";
    _keys << "status";
    _keys << "watype";
    _keys << "url";
    _keys << "name";
    _keys << "latitude";
    _keys << "longitude";
    _keys << "size";
    _keys << "duration";
    _keys << "width";
    _keys << "height";
    _keys << "rotation";
    _keys << "hash";
    _keys << "mime";
    _keys << "broadcast";
    _keys << "live";
    _keys << "local";
    _keys << "section";
    _keys << "mediaprogress";
    int role = Qt::UserRole + 1;
    foreach (const QString &rolename, _keys) {
        _roles[role++] = rolename.toLatin1();
    }

    uuid = QUuid::createUuid().toString();

    dbExecutor = QueryExecutor::GetInstance();
    connect(dbExecutor, SIGNAL(actionDone(QVariant)), this, SLOT(dbResults(QVariant)));

    iface = new QDBusInterface(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "messageReceived", this, SLOT(onMessageReceived(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "messageStatusUpdated", this, SLOT(onMessageStatusUpdated(QString,QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadProgress", this, SLOT(onMediaProgress(QString,QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadFinished", this, SLOT(onMediaFinished(QString,QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadFailed", this, SLOT(onMediaFailed(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadProgress", this, SLOT(onMediaProgress(QString,QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadFailed", this, SLOT(onMediaFailed(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "mediaTitleReceived", this, SLOT(onMediaTitleReceived(QString,QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadFinished", this, SLOT(onMediaUploadFinished(QString,QString,QString)));
}

ConversationModel::~ConversationModel()
{
    if (iface)
        delete iface;
}

void ConversationModel::loadLastConversation(QString newjid)
{
    _loadingBusy = true;
    qDebug() << "load last conversation for:" << newjid;
    QDBusReply<QVariantMap> reply = iface->call(QDBus::AutoDetect, "getDownloads");
    if (reply.isValid())
        _downloadData = reply.value();
    jid = newjid;
    table = jid.split("@").first().replace("-", "g");

    getAllCount();

    reloadConversation();
}

int ConversationModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return _modelData.count();
}

QVariant ConversationModel::data(const QModelIndex &index, int role) const
{
    int row = index.row();
    if (row < 0 || row >= _modelData.count())
        return QVariant();
    QString msgId = _sortedTimestampMsgidList.at(row)._msgid;
    QVariant value = _modelData[msgId][_roles[role]];
    return value;
}

void ConversationModel::reloadConversation()
{
    QVariantMap query;
    query["type"] = QueryType::ConversationLoadLast;
    query["table"] = table;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

void ConversationModel::setPropertyByMsgId(const QString &msgId, const QString &name, const QVariant &value)
{
    if (_modelData.keys().contains(msgId)) {
        _modelData[msgId][name] = value;
        int row = getIndexByMsgId(msgId);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ConversationModel::loadOldConversation(int count)
{
    if (_modelData.isEmpty())
        return;
    if (_loadingBusy)
        return;
    _loadingBusy = true;
    qDebug() << "load old converstaion for:" << jid;
    int stamp = _sortedTimestampMsgidList.last()._timestamp;

    QVariantMap query;
    query["type"] = QueryType::ConversationLoadNext;
    query["table"] = table;
    query["timestamp"] = stamp;
    query["count"] = count;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

void ConversationModel::deleteMessage(const QString &msgId, const QString &myJid, bool deleteMediaFiles)
{
    if (!_modelData.keys().contains(msgId))
        return;

    if (deleteMediaFiles && iface) {
        QString author = _modelData[msgId]["author"].toString();
        QString localurl = _modelData[msgId]["local"].toString();
        if (author != myJid) {
            QFile media(localurl);
            if (media.exists()) {
                media.remove();
            }
        }
    }

    int rowIndex = getIndexByMsgId(msgId);
    beginRemoveRows(QModelIndex(), rowIndex, rowIndex);
    _modelData.remove(msgId);
    _sortedTimestampMsgidList.removeAt(rowIndex);
    endRemoveRows();

    Q_EMIT countChanged();

    QVariantMap query;
    query["type"] = QueryType::ConversationRemoveMessage;
    query["table"] = table;
    query["msgid"] = msgId;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);

    getAllCount();
}

QVariantMap ConversationModel::get(int index)
{
    if (index < 0 || index >= _modelData.size())
        return QVariantMap();
    QString msgId = _sortedTimestampMsgidList.at(index)._msgid;
    return _modelData[msgId];
}

QVariantMap ConversationModel::getModelByIndex(int index)
{
    if (index < 0 || index >= _modelData.size())
        return QVariantMap();
    QString msgId = _sortedTimestampMsgidList.at(index)._msgid;
    QVariantMap data = _modelData[msgId];
    return data;
}

QVariantMap ConversationModel::getModelByMsgId(const QString &msgId)
{
    if (_modelData.keys().contains(msgId))
        return _modelData[msgId];
    return QVariantMap();
}

void ConversationModel::copyToClipboard(const QString &msgId)
{
    if (!_modelData.keys().contains(msgId))
        return;
    QString text;
    QVariantMap data = _modelData[msgId];
    int msgtype = data["watype"].toInt();
    if (msgtype == 0) {
        text = data["data"].toString();
    }
    else if (msgtype > 0 && msgtype < 4) {
        QString url = data["url"].toString();
        text = url;
    }
    else if (msgtype == 5) {
        QString latitude = data["latitude"].toString();
        QString longitude = data["longitude"].toString();
        QString url = QString("https://maps.google.com/maps?q=loc:%1,%2").arg(latitude).arg(longitude);
        text = url;
    }
    if (!text.isEmpty()) {
        QGuiApplication::clipboard()->setText(text);
    }
}

void ConversationModel::forwardMessage(const QStringList &jids, const QString &msgId)
{
    if (iface) {
        QVariantMap model = getModelByMsgId(msgId);
        iface->call(QDBus::NoBlock, "forwardMessage", jids, model);
    }
}

void ConversationModel::resendMessage(const QString &jid, const QString &msgId)
{
    if (iface) {
        QVariantMap model = getModelByMsgId(msgId);
        iface->call(QDBus::NoBlock, "resendMessage", jid, model);
    }
}

void ConversationModel::removeConversation(const QString &rjid)
{
    if (jid == rjid) {
        beginResetModel();
        _modelData.clear();
        _sortedTimestampMsgidList.clear();
        endResetModel();
        Q_EMIT lastMessageChanged(rjid, true);
    }

    Q_EMIT countChanged();

    QVariantMap query;
    query["type"] = QueryType::ConversationRemoveAll;
    query["jid"] = rjid;
    query["table"] = table;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

int ConversationModel::count()
{
    return _modelData.size();
}

void ConversationModel::requestContactMedia(const QString &sjid)
{
    QVariantMap query;
    query["type"] = QueryType::ConversationGetMedia;
    query["jid"] = jid;
    query["table"] = jid.split("@").first().replace("-", "g");;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

int ConversationModel::getIndexByMsgId(const QString &msgId)
{
    if (!_modelData.keys().contains(msgId))
        return -1;
    for (int i = 0; i < _sortedTimestampMsgidList.count(); i++) {
        if (_sortedTimestampMsgidList.at(i)._msgid == msgId)
            return i;
    }
    return -1;
}

int ConversationModel::allCount()
{
    return _allCount;
}

void ConversationModel::getAllCount()
{
    QVariantMap cnt;
    cnt["type"] = QueryType::ConversationGetCount;
    cnt["table"] = table;
    cnt["uuid"] = uuid;
    dbExecutor->queueAction(cnt);
}

QString ConversationModel::makeTimestampDate(int timestamp)
{
    return QDateTime::fromTime_t(timestamp).toString("dd MMM yyyy");
}

void ConversationModel::onLoadingFree()
{
    _loadingBusy = false;
}

void ConversationModel::onMessageReceived(const QVariantMap &data)
{
    if (data["jid"].toString() == jid) {
        QVariantMap message = data;
        QString msgId = message["msgid"].toString();
        QString author = message["author"].toString();
        int timestamp = message["timestamp"].toInt();
        message["mediaprogress"] = 0;

        if (!_modelData.contains(msgId)) {
            Q_EMIT lastMessageToBeChanged(jid);
            beginInsertRows(QModelIndex(), 0, 0);
            _modelData[msgId] = message;
            _modelData[msgId]["section"] = makeTimestampDate(timestamp);
            _sortedTimestampMsgidList.prepend(TimestampMsgidPair(timestamp, msgId));
            endInsertRows();
            Q_EMIT lastMessageChanged(jid, false);
        }
        else {
            int row = getIndexByMsgId(msgId);
            _modelData[msgId] = message;
            _modelData[msgId]["section"] = makeTimestampDate(timestamp);
            dataChanged(index(row), index(row));
        }

        Q_EMIT countChanged();
        getAllCount();
    }
}

void ConversationModel::onMessageStatusUpdated(const QString &mjid, const QString &msgId, int msgstatus)
{
    if (mjid == jid) {
        qDebug() << "Update message status for:" << msgId << "status:" << QString::number(msgstatus);
        setPropertyByMsgId(msgId, "status", msgstatus);
    }
}

void ConversationModel::onMediaProgress(const QString &mjid, const QString &msgId, int progress)
{
    //qDebug() << "Media download progress" << mjid << msgId << QString::number(progress);
    if (mjid == jid) {
        setPropertyByMsgId(msgId, "mediaprogress", progress);
    }
}

void ConversationModel::onMediaFinished(const QString &mjid, const QString &msgId, const QString &path)
{
    if (mjid == jid) {
        setPropertyByMsgId(msgId, "local", path);
        setPropertyByMsgId(msgId, "mediaprogress", 100);
    }
}

void ConversationModel::onMediaFailed(const QString &mjid, const QString &msgId)
{
    if (mjid == jid) {
        if (_downloadData.contains(msgId)) {
            _downloadData.remove(msgId);
        }
        setPropertyByMsgId(msgId, "mediaprogress", 0);
    }
}

void ConversationModel::onMediaTitleReceived(const QString &msgid, const QString &title, const QString &mjid)
{
    if (mjid == jid) {
        setPropertyByMsgId(msgid.split("-cap").first(), "name", title);
    }
}

void ConversationModel::onMediaUploadFinished(const QString &mjid, const QString &msgid, const QString &url)
{
    if (mjid == jid) {
        setPropertyByMsgId(msgid, "url", url);
    }
}

void ConversationModel::dbResults(const QVariant &result)
{
    QVariantMap reply = result.toMap();
    if (reply["uuid"].toString() != uuid)
        return;
    int vtype = reply["type"].toInt();
    switch (vtype) {
    case QueryType::ConversationLoadLast: {
        beginResetModel();
        _modelData.clear();
        _sortedTimestampMsgidList.clear();
        //endResetModel();

        //Q_EMIT lastMessageToBeChanged(jid);
        QVariantList records = reply["messages"].toList();
        if (records.size() > 0) {
            //beginInsertRows(QModelIndex(), 0, records.size() - 1);
            foreach (const QVariant &c, records) {
                QVariantMap data = c.toMap();
                //qDebug() << data["msgid"].toString() << "local:" << data["local"].toString();
                QString msgId = data["msgid"].toString();
                int timestamp = data["timestamp"].toInt();
                data["mediaprogress"] = _downloadData.contains(msgId) ? _downloadData[msgId] : 0;
                data["section"] = makeTimestampDate(timestamp);
                if (!_modelData.keys().contains(msgId)) {
                    //qDebug() << data["message"].toString();
                    _modelData[msgId] = data;
                    _sortedTimestampMsgidList.append(TimestampMsgidPair(timestamp, msgId));
                }
            }
            qSort(_sortedTimestampMsgidList);
            //endInsertRows();
        }
        endResetModel();

        Q_EMIT countChanged();

        _loadingBusy = false;
        Q_EMIT lastMessageChanged(jid, true);
        break;
    }
    case QueryType::ConversationLoadNext: {
        QVariantList records = reply["messages"].toList();
        if (records.size() > 0) {
            beginInsertRows(QModelIndex(), _modelData.size(), _modelData.size() + records.size() - 1);
            foreach (const QVariant &c, records) {
                QVariantMap data = c.toMap();
                QString msgId = data["msgid"].toString();
                int timestamp = data["timestamp"].toInt();
                data["mediaprogress"] = _downloadData.contains(msgId) ? _downloadData[msgId] : 0;
                data["section"] = makeTimestampDate(timestamp);
                if (!_modelData.keys().contains(msgId)) {
                    //qDebug() << "insert data:" << data;
                    _modelData[msgId] = data;
                    _sortedTimestampMsgidList.prepend(TimestampMsgidPair(timestamp, msgId));
                }
                else {
                    //qDebug() << "duplicate message:" << data;
                }
            }
            qSort(_sortedTimestampMsgidList);
            endInsertRows();
        }

        Q_EMIT countChanged();

        _loadingBusy = false;
        Q_EMIT lastMessageChanged(jid, false);
        break;
    }
    case QueryType::ConversationGetMedia: {
        QVariantList mediaList = reply["media"].toList();
        if (mediaList.size() > 0) {
            Q_EMIT mediaListReceived(jid, mediaList);
        }
        break;
    }
    case QueryType::ConversationGetCount: {
        _allCount = reply["count"].toInt();
        Q_EMIT allCountChanged();
        break;
    }
    default: {
        break;
    }
    }
}
