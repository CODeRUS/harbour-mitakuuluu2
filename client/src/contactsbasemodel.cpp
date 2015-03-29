#include "contactsbasemodel.h"
#include "constants.h"
#include <QDebug>
#include <cmath>

#include <QUuid>

ContactsBaseModel::ContactsBaseModel(QObject *parent) :
    QAbstractListModel(parent)
{
    _keys << "jid";
    _keys << "pushname";
    _keys << "name";
    _keys << "nickname";
    _keys << "message";
    _keys << "contacttype";
    _keys << "owner";
    _keys << "subowner";
    _keys << "timestamp";
    _keys << "subtimestamp";
    _keys << "avatar";
    _keys << "unread";
    _keys << "available";
    _keys << "lastmessage";
    _keys << "blocked";
    _keys << "typing";
    int role = Qt::UserRole + 1;
    foreach (const QString &rolename, _keys) {
        _roles[role++] = rolename.toLatin1();
    }

    uuid = QUuid::createUuid().toString();

    iface = new QDBusInterface(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);

    dbExecutor = QueryExecutor::GetInstance();
    connect(dbExecutor, SIGNAL(actionDone(QVariant)), this, SLOT(dbResults(QVariant)));


    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "pictureUpdated", this, SLOT(pictureUpdated(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "setUnread", this, SLOT(setUnread(QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "pushnameUpdated", this, SLOT(pushnameUpdated(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactAvailable", this, SLOT(presenceAvailable(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactUnavailable", this, SLOT(presenceUnavailable(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactLastSeen", this, SLOT(presenceLastSeen(QString, int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupInfo", this, SLOT(groupInfo(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactChanged", this, SLOT(contactChanged(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactSynced", this, SLOT(contactSynced(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactsChanged", this, SLOT(contactsChanged()));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "newGroupSubject", this, SLOT(newGroupSubject(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "messageReceived", this, SLOT(messageReceived(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactStatus", this, SLOT(contactStatus(QString, QString, int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactsBlocked", this, SLOT(contactsBlocked(QStringList)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactsAvailable", this, SLOT(contactsAvailable(QStringList)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactTyping", this, SIGNAL(contactTyping(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactPaused", this, SIGNAL(contactPaused(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupRemoved", this, SIGNAL(contactRemoved(QString)));

    if (iface) {
        iface->call(QDBus::NoBlock, "getPrivacyList");
        iface->call(QDBus::NoBlock, "getAvailableJids");
    }

    contactsChanged();
}

ContactsBaseModel::~ContactsBaseModel()
{
}

void ContactsBaseModel::reloadContact(const QString &jid)
{
    QVariantMap query;
    query["type"] = QueryType::ContactsReloadContact;
    query["jid"] = jid;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

void ContactsBaseModel::setPropertyByJid(const QString &jid, const QString &name, const QVariant &value)
{
    if (_modelData.contains(jid)) {
        if (_modelData[jid][name] == value)
            return;

        int row = _modelData.keys().indexOf(jid);
        if (name == "avatar") {
            _modelData[jid][name] = QString();
            Q_EMIT dataChanged(index(row), index(row));
        }
        _modelData[jid][name] = value;
        Q_EMIT dataChanged(index(row), index(row));

        if (name == "unread")
            checkTotalUnread();
    }
}

void ContactsBaseModel::deleteContact(const QString &jid)
{
    if (_modelData.contains(jid)) {
        contactRemoved(jid);

        QVariantMap query;
        query["type"] = QueryType::ContactsRemove;
        query["jid"]  = jid;
        query["uuid"] = uuid;
        dbExecutor->queueAction(query);

        iface->call(QDBus::NoBlock, "contactRemoved", jid);
    }
}

QVariantMap ContactsBaseModel::getModel(const QString &jid)
{
    if (_modelData.contains(jid))
        return _modelData[jid];
    return QVariantMap();
}

QVariantMap ContactsBaseModel::get(int index)
{
    if (index < 0 || index >= _modelData.count())
        return QVariantMap();
    return _modelData[_modelData.keys().at(index)];
}

QColor ContactsBaseModel::getColorForJid(const QString &jid)
{
    if (!_colors.keys().contains(jid))
        _colors[jid] = generateColor();
    QColor color = _colors[jid];
    //color.setAlpha(96);
    return color;
}

void ContactsBaseModel::clear()
{
    beginResetModel();
    _modelData.clear();
    endResetModel();
}

QColor ContactsBaseModel::generateColor()
{
    qreal golden_ratio_conjugate = 0.618033988749895;
    qreal h = (qreal)rand()/(qreal)RAND_MAX;
    h += golden_ratio_conjugate;
    h = fmod(h, 1);
    QColor color = QColor::fromHsvF(h, 0.5, 0.95);
    return color;
}

int ContactsBaseModel::getTotalUnread()
{
    return _totalUnread;
}

void ContactsBaseModel::checkTotalUnread()
{
    _totalUnread = 0;
    foreach (const QVariantMap &contact, _modelData.values()) {
        _totalUnread += contact["unread"].toInt();
    }
    Q_EMIT totalUnreadChanged();
}

bool ContactsBaseModel::getAvailable(const QString &jid)
{
    return _availableContacts.contains(jid);
}

bool ContactsBaseModel::getBlocked(const QString &jid)
{
    return _blockedContacts.contains(jid);
}

QString ContactsBaseModel::getNicknameBy(const QString &jid, const QString &message, const QString &name, const QString &pushname)
{
    QString nickname;
    if (jid.contains("-")) {
        nickname = message;
    }
    else if (name == jid.split("@").first() || name.isEmpty()) {
        if (!pushname.isEmpty())
            nickname = pushname;
        else
            nickname = jid.split("@").first();
    }
    else {
        nickname = name;
    }
    return nickname;
}

void ContactsBaseModel::pictureUpdated(const QString &jid, const QString &path)
{
    if (_modelData.contains(jid)) {
        setPropertyByJid(jid, jid.contains("-") ? "avatar" : "owner", path);
    }
}

void ContactsBaseModel::groupInfo(const QVariantMap &data)
{
    QString jid = data["jid"].toString();
    if (_modelData.contains(jid)) {
        if (_modelData[jid]["nickname"] == data["message"]
             && _modelData[jid]["pushname"] == data["pushname"]
             && _modelData[jid]["owner"] == data["owner"]
             && _modelData[jid]["message"] == data["message"]
             && _modelData[jid]["subowner"] == data["subowner"]
             && _modelData[jid]["subtimestamp"] == data["subtimestamp"]
             && _modelData[jid]["timestamp"] == data["timestamp"])
            return;
        qDebug() << "change group info for" << jid;


        _modelData[jid]["nickname"] = data["message"];
        _modelData[jid]["pushname"] = data["pushname"];
        _modelData[jid]["owner"] = data["owner"];
        _modelData[jid]["message"] = data["message"];
        _modelData[jid]["subowner"] = data["subowner"];
        _modelData[jid]["subtimestamp"] = data["subtimestamp"];
        _modelData[jid]["timestamp"] = data["timestamp"];
        _modelData[jid]["typing"] = false;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
    else {
        qDebug() << "create group info for" << jid;
        beginResetModel();

        _modelData[jid] = data;
        _modelData[jid]["blocked"] = false;
        _modelData[jid]["available"] = false;
        _modelData[jid]["typing"] = false;
        _modelData[jid]["nickname"] = data["message"];

        endResetModel();
    }
}

void ContactsBaseModel::contactChanged(const QVariantMap &data)
{
    QVariantMap contact = data;
    QString jid = contact["jid"].toString();
    qDebug() << "contact changed" << jid;

    QString name = contact["name"].toString();
    QString message = contact["message"].toString();
    QString pushname = contact["pushname"].toString();
    QString nickname = getNicknameBy(jid, message, name, pushname);

    contact["nickname"] = nickname;
    contact["typing"] = false;
    bool available = getAvailable(jid);
    contact["available"] = available;
    bool blocked = false;
    if (!jid.contains("-"))
        blocked = getBlocked(jid);
    contact["blocked"] = blocked;

    if (_modelData.contains(jid)) {
        if (_modelData[jid] == contact)
            return;
        _modelData[jid] = contact;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
    else {
        beginResetModel();

        _modelData[jid] = contact;

        endResetModel();
    }
}

void ContactsBaseModel::contactSynced(const QVariantMap &data)
{
    QVariantMap contact = data;
    QString jid = contact["jid"].toString();
    if (_modelData.contains(jid)) {
        if (_modelData[jid]["name"] == contact["name"]
                && (contact["avatar"].toString().isEmpty()
                    || contact["avatar"] == _modelData[jid]["avatar"]))
            return;
        QString name = contact["name"].toString();
        QString pushname = _modelData[jid]["pushname"].toString();

        qDebug() << "contact synced:" << name << pushname << jid;

        _modelData[jid]["nickname"] = getNicknameBy(jid, "", name, pushname);
        _modelData[jid]["avatar"] = contact["avatar"];

        bool blocked = getBlocked(jid);
        _modelData[jid]["blocked"] = blocked;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));

        if (_modelData[jid]["avatar"].toString().isEmpty())
            requestAvatar(jid);
    }
}

void ContactsBaseModel::contactStatus(const QString &jid, const QString &message, int timestamp)
{
    if (_modelData.contains(jid)) {
        if (_modelData[jid]["subtimestamp"].toInt() == timestamp)
            return;
        Q_EMIT statusChanged(jid, message, timestamp);
        qDebug() << "contact status for" << jid << message;
        _modelData[jid]["message"] = message;
        _modelData[jid]["subtimestamp"] = timestamp;
        int row = _modelData.keys().indexOf(jid);
        dataChanged(index(row), index(row));
    }
}

void ContactsBaseModel::newGroupSubject(const QVariantMap &data)
{
    QString jid = data["jid"].toString();
    if (_modelData.contains(jid)) {
        if (_modelData[jid]["message"] == data["message"]
             && _modelData[jid]["subowner"] == data["subowner"]
             && _modelData[jid]["subtimestamp"] == data["subtimestamp"])
            return;
        QString message = data["message"].toString();
        QString subowner = data["subowner"].toString();
        QString subtimestamp = data["subtimestamp"].toString();

        _modelData[jid]["message"] = message;
        _modelData[jid]["nickname"] = message;
        _modelData[jid]["subowner"] = subowner;
        _modelData[jid]["subtimestamp"] = subtimestamp;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ContactsBaseModel::contactsChanged()
{
    QVariantMap query;
    query["type"] = QueryType::ContactsGetAll;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

void ContactsBaseModel::setUnread(const QString &jid, int count)
{
    setPropertyByJid(jid, "unread", count);
}

void ContactsBaseModel::pushnameUpdated(const QString &jid, const QString &pushName)
{
    if (_modelData.contains(jid) && (pushName != jid.split("@").first())) {
        if (_modelData[jid]["pushname"].toString() == pushName)
            return;
        setPropertyByJid(jid, "pushname", pushName);

        QString nickname = _modelData[jid]["nickname"].toString();
        QString pushname = _modelData[jid]["pushname"].toString();
        QString message = _modelData[jid]["message"].toString();
        QString name = _modelData[jid]["name"].toString();

        nickname = getNicknameBy(jid, message, name, pushname);

        _modelData[jid]["nickname"] = nickname;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));

        Q_EMIT nicknameChanged(jid, nickname);
    }
}

void ContactsBaseModel::presenceAvailable(const QString &jid)
{
    if (!_availableContacts.contains(jid))
        _availableContacts.append(jid);
    setPropertyByJid(jid, "available", true);
}

void ContactsBaseModel::presenceUnavailable(const QString &jid)
{
    if (_availableContacts.contains(jid))
        _availableContacts.removeAll(jid);
    setPropertyByJid(jid, "available", false);
}

void ContactsBaseModel::presenceLastSeen(const QString jid, int timestamp)
{
    setPropertyByJid(jid, "timestamp", timestamp);
    setPropertyByJid(jid, "available", timestamp == 0);
}

void ContactsBaseModel::messageReceived(const QVariantMap &data)
{
    QString jid = data["jid"].toString();
    contactPaused(jid);
    int lastmessage = data["timestamp"].toInt();
    if (_modelData.contains(jid)) {
        _modelData[jid]["lastmessage"] = lastmessage;
        _modelData[jid]["typing"] = false;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
    else {
        contactsChanged();
    }
}

void ContactsBaseModel::contactsBlocked(const QStringList &jids)
{
    _blockedContacts = jids;
    foreach (const QString &jid, _modelData.keys()) {
        if (_modelData[jid]["blocked"].toBool() == jids.contains(jid))
            continue;
        if (!jid.contains("-")) {
            if (jids.contains(jid))
                _modelData[jid]["blocked"] = true;
            else
                _modelData[jid]["blocked"] = false;
        }
        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ContactsBaseModel::contactsAvailable(const QStringList &jids)
{
    _availableContacts = jids;
    foreach (const QString &jid, _modelData.keys()) {
        if (_modelData[jid]["available"].toBool() == jids.contains(jid))
            continue;
        if (jids.contains(jid))
            _modelData[jid]["available"] = true;
        else
            _modelData[jid]["available"] = false;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ContactsBaseModel::contactTyping(const QString &jid)
{
    if (_modelData.contains(jid)) {
        _modelData[jid]["typing"] = true;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ContactsBaseModel::contactPaused(const QString &jid)
{
    if (_modelData.contains(jid)) {
        _modelData[jid]["typing"] = false;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ContactsBaseModel::contactRemoved(const QString &jid)
{
    int row = _modelData.keys().indexOf(jid);
    beginRemoveRows(QModelIndex(), row, row);
    _modelData.remove(jid);
    endRemoveRows();
}

void ContactsBaseModel::dbResults(const QVariant &result)
{
    QVariantMap reply = result.toMap();
    int vtype = reply["type"].toInt();

    if (vtype == QueryType::ContactsSaveModel) {
        contactChanged(reply);
    }

    if (reply["uuid"].toString() != uuid)
        return;
    switch (vtype) {
    case QueryType::ContactsReloadContact: {
        QVariantMap contact = reply["contact"].toMap();
        contactChanged(contact);
        break;
    }
    case QueryType::ContactsGetAll: {
        QVariantList records = reply["contacts"].toList();
        qDebug() << "Received QueryGetContacts reply. Size:" << QString::number(records.size());
        if (records.size() > 0) {
            beginResetModel();
            _modelData.clear();
            foreach (const QVariant &c, records) {
                QVariantMap data = c.toMap();
                QString jid = data["jid"].toString();
                QString pushname = data["pushname"].toString();
                QString name = data["name"].toString();
                QString message = data["message"].toString();
                //qDebug() << "jid:" << jid << pushname << name << message;
                bool blocked = false;
                if (!jid.contains("-"))
                    blocked = getBlocked(jid);
                data["blocked"] = blocked;
                bool available = getAvailable(jid);
                data["available"] = available;
                QString nickname = getNicknameBy(jid, message, name, pushname);
                data["nickname"] = nickname;
                data["typing"] = false;
                _modelData[jid] = data;
                if (!_colors.keys().contains(jid))
                    _colors[jid] = generateColor();
                if (data["avatar"].toString().isEmpty())
                    requestAvatar(jid);
            }
            endResetModel();
        }
        checkTotalUnread();
        break;
    }
    case QueryType::ContactsClearConversation: {
        reloadContact(reply["jid"].toString());
        Q_EMIT conversationClean(reply["jid"].toString());
        break;
    }
    case QueryType::ContactsCreateBroadcast: {
        Q_EMIT broadcastCreated(reply["jid"].toString(), reply["jids"].toStringList());
        reloadContact(reply["jid"].toString());
        break;
    }
    }
}

int ContactsBaseModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return _modelData.size();
}

QVariant ContactsBaseModel::data(const QModelIndex &index, int role) const
{
    int row = index.row();
    if (row < 0 || row >= _modelData.count())
        return QVariantMap();
    return _modelData[_modelData.keys()[row]][_roles[role]];
}

bool ContactsBaseModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    qDebug() << "Model setData" << index.row() << value << role;
    return false;
}

int ContactsBaseModel::count()
{
    return _modelData.count();
}


void ContactsBaseModel::renameContact(const QString &jid, const QString &name)
{
    if (_modelData.contains(jid)) {
        if (_modelData[jid]["name"].toString() == name)
            return;

        _modelData[jid]["name"] = name;
        QString pushname = _modelData[jid]["pushname"].toString();

        QString nickname;
        if (name == jid.split("@").first()) {
            if (!pushname.isEmpty())
                nickname = pushname;
            else
                nickname = name;
        }
        else {
            nickname = name;
        }
        _modelData[jid]["nickname"] = nickname;
        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));

        QVariantMap query = _modelData[jid];
        query["type"] = QueryType::ContactsSaveModel;
        dbExecutor->queueAction(query);
    }
}

void ContactsBaseModel::requestAvatar(const QString &jid)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "getPicture", jid);
    }
}

void ContactsBaseModel::clearChat(const QString &jid)
{
    _modelData[jid]["lastmessage"] = 0;
    int row = _modelData.keys().indexOf(jid);
    Q_EMIT dataChanged(index(row), index(row));

    QVariantMap query;
    query["type"] = QueryType::ContactsClearConversation;
    query["jid"] = jid;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

void ContactsBaseModel::createBroadcast(const QStringList &jids)
{
    QString jid = QString("%1@broadcast").arg(QDateTime::currentMSecsSinceEpoch());

    QVariantMap query;
    query["type"] = QueryType::ContactsCreateBroadcast;
    query["uuid"] = uuid;
    query["jids"] = jids;
    query["name"] = QString();
    query["jid"] = jid;
    dbExecutor->queueAction(query);
}

void ContactsBaseModel::renameBroadcast(const QString &jid, const QString &name)
{
    if (_modelData.contains(jid)) {
        setPropertyByJid(jid, "name", name);

        QVariantMap query;
        query["type"] = QueryType::ContactsCreateBroadcast;
        query["uuid"] = uuid;
        query["name"] = name;
        query["jid"] = jid;
        dbExecutor->queueAction(query);
    }
}
