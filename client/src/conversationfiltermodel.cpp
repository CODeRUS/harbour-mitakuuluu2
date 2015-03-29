#include "conversationfiltermodel.h"

ConversationFilterModel::ConversationFilterModel(QObject *parent) :
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
    int role = Qt::UserRole + 1;
    foreach (const QString &rolename, _keys) {
        _roles[role++] = rolename.toLatin1();
    }

    uuid = QUuid::createUuid().toString();

    dbExecutor = QueryExecutor::GetInstance();
    connect(dbExecutor, SIGNAL(actionDone(QVariant)), this, SLOT(dbResults(QVariant)));
}

QString ConversationFilterModel::filter() const
{
    return _filter;
}

void ConversationFilterModel::setFilter(const QString &newFilter)
{
    _filter = newFilter;
    Q_EMIT filterChanged();

    if (_filter.isEmpty()) {
        beginResetModel();
        _modelData.clear();
        endResetModel();
    }
    else {
        QVariantMap query;
        query["type"] = QueryType::ConversationLoadFiltered;
        query["uuid"] = uuid;
        query["table"] = _table;
        query["filter"] = _filter;
        dbExecutor->queueAction(query);
    }
}

QString ConversationFilterModel::jid() const
{
    return _jid;
}

void ConversationFilterModel::setJid(const QString &newJid)
{
    _jid = newJid;
    _table = _jid.split("@").first().replace("-", "g");
    Q_EMIT jidChanged();
}

int ConversationFilterModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return _modelData.size();
}

QVariant ConversationFilterModel::data(const QModelIndex &index, int role) const
{
    int row = index.row();
    if (row < 0 || row >= _modelData.count())
        return QVariant();
    return _modelData.at(row).toMap().value(_roles[role]);
}

QVariantMap ConversationFilterModel::get(int index) const
{
    if (index < 0 || index >= _modelData.size())
        return QVariantMap();
    return _modelData.at(index).toMap();
}

void ConversationFilterModel::dbResults(const QVariant &result)
{
    QVariantMap reply = result.toMap();
    if (reply["uuid"].toString() != uuid)
        return;
    int vtype = reply["type"].toInt();
    switch (vtype) {
    case QueryType::ConversationLoadFiltered: {
        beginResetModel();
        _modelData = reply["messages"].toList();
        endResetModel();
        break;
    }
    default: {
        break;
    }
    }
}
