#include "sharecontactsbasemodel.h"
#include <QDebug>
#include <cmath>

#include <QUuid>

ShareContactsBaseModel::ShareContactsBaseModel(QObject *parent) :
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
    _keys << "lastmessage";
    int role = Qt::UserRole + 1;
    foreach (const QString &rolename, _keys) {
        _roles[role++] = rolename.toLatin1();
    }

    iface = new QDBusInterface(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);

    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "pictureUpdated", this, SLOT(pictureUpdated(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "pushnameUpdated", this, SLOT(pushnameUpdated(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactChanged", this, SLOT(contactChanged(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactSynced", this, SLOT(contactSynced(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "newGroupSubject", this, SLOT(newGroupSubject(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactStatus", this, SLOT(contactStatus(QString, QString)));

    QSqlDatabase db;

    db = QSqlDatabase::database();
    if (!db.isOpen()) {
        qDebug() << "QE Opening database";
        db = QSqlDatabase::addDatabase("QSQLITE");
        QString appname = "harbour-mitakuuluu2";
        QString dataDir = QString("%1/.local/share/%2/%3").arg(QDir::homePath()).arg(appname).arg(appname);

        QDir dir(dataDir);
        if (dir.exists()) {
            qDebug() << "DB Dir:" << dataDir;
            db.setDatabaseName(QString("%1/database.db").arg(dataDir));
            qDebug() << "DB Name:" << db.databaseName();
            if (db.open())
                qDebug() << "QE opened database";
            else
                qWarning() << "QE failed to open database";
        }
        else {
            qWarning() << "Database doesnt exists";
        }
    }
    else {
        qWarning() << "QE used existing DB connection!";
    }

    beginResetModel();
    _modelData.clear();

    QSqlQuery sql("SELECT * FROM contacts", db);
    while (sql.next()) {
        QVariantMap contact;
        for (int i = 0; i < sql.record().count(); i ++) {
            contact[sql.record().fieldName(i)] = sql.value(i);
        }
        QString jid = contact["jid"].toString();
        QString pushname = contact["pushname"].toString();
        QString name = contact["name"].toString();
        QString message = contact["message"].toString();
        QString nickname = getNicknameBy(jid, message, name, pushname);
        contact["nickname"] = nickname;
        _modelData[jid] = contact;
    }

    endResetModel();
}

ShareContactsBaseModel::~ShareContactsBaseModel()
{
}

QString ShareContactsBaseModel::getNicknameBy(const QString &jid, const QString &message, const QString &name, const QString &pushname)
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

void ShareContactsBaseModel::pictureUpdated(const QString &jid, const QString &path)
{
    setPropertyByJid(jid, "avatar", path);
}

void ShareContactsBaseModel::contactChanged(const QVariantMap &data)
{
    QVariantMap contact = data;
    QString jid = contact["jid"].toString();

    QString name = contact["name"].toString();
    QString message = contact["message"].toString();
    QString pushname = contact["pushname"].toString();
    QString nickname = getNicknameBy(jid, message, name, pushname);

    contact["nickname"] = nickname;

    _modelData[jid] = contact;

    int row = _modelData.keys().indexOf(jid);
    Q_EMIT dataChanged(index(row), index(row));
}

void ShareContactsBaseModel::contactSynced(const QVariantMap &data)
{
    QVariantMap contact = data;
    QString jid = contact["jid"].toString();
    if (_modelData.keys().contains(jid)) {
        _modelData[jid]["timestamp"] = contact["timestamp"];
        QString message = contact["message"].toString();
        _modelData[jid]["message"] = message;

        QString name = contact["name"].toString();
        QString pushname = _modelData[jid]["pushname"].toString();

        _modelData[jid]["nickname"] = getNicknameBy(jid, message, name, pushname);

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ShareContactsBaseModel::contactStatus(const QString &jid, const QString &message)
{
    if (_modelData.keys().contains(jid)) {
        _modelData[jid]["message"] = message;
        int row = _modelData.keys().indexOf(jid);
        dataChanged(index(row), index(row));
    }
}

void ShareContactsBaseModel::newGroupSubject(const QVariantMap &data)
{
    QString jid = data["jid"].toString();
    if (_modelData.keys().contains(jid)) {
        QString message = data["message"].toString();
        QString subowner = data["subowner"].toString();
        QString subtimestamp = data["subtimestamp"].toString();

        _modelData[jid]["message"] = message;
        _modelData[jid]["nickname"] = message;
        _modelData[jid]["subowner"] = subowner;
        _modelData[jid]["subtimestamp"] = subtimestamp;

        int row = _modelData.keys().indexOf(jid);
        Q_EMIT dataChanged(index(row), index(row));

        qDebug() << "New subject saved:" << message << "for jid:" << jid;
    }
}

void ShareContactsBaseModel::pushnameUpdated(const QString &jid, const QString &pushName)
{
    if (_modelData.keys().contains(jid) && (pushName != jid.split("@").first())) {
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

int ShareContactsBaseModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return _modelData.size();
}

QVariant ShareContactsBaseModel::data(const QModelIndex &index, int role) const
{
    int row = index.row();
    if (row < 0 || row >= _modelData.count())
        return QVariantMap();
    return _modelData[_modelData.keys().at(row)][_roles[role]];
}

bool ShareContactsBaseModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    qDebug() << "Model setData" << index.row() << value << role;
    return false;
}

QVariantMap ShareContactsBaseModel::get(int index)
{
    if (index < 0 || index >= _modelData.count())
        return QVariantMap();
    return _modelData[_modelData.keys()[index]];
}

void ShareContactsBaseModel::startSharing(const QStringList &jids, const QString &name, const QString &data)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "sendVCard", jids, name, data);
    }
}

void ShareContactsBaseModel::setPropertyByJid(const QString &jid, const QString &name, const QVariant &value)
{
    if (_modelData.keys().contains(jid)) {
        //qDebug() << "Model setPropertyByJid:" << jid << name << value;
        if (_modelData.keys().contains(jid)) {
            int row = _modelData.keys().indexOf(jid);
            if (name == "avatar") {
                _modelData[jid][name] = QString();
                Q_EMIT dataChanged(index(row), index(row));
            }
            _modelData[jid][name] = value;
            Q_EMIT dataChanged(index(row), index(row));
        }
    }
}

int ShareContactsBaseModel::count()
{
    return _modelData.count();
}
