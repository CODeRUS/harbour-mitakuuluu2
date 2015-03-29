#ifndef CONVERSATIONFILTERMODEL_H
#define CONVERSATIONFILTERMODEL_H

#include <QDebug>
#include <QAbstractListModel>

#include "../threadworker/queryexecutor.h"

class ConversationFilterModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit ConversationFilterModel(QObject *parent = 0);

    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    QString filter() const;
    void setFilter(const QString &newFilter);

    Q_PROPERTY(QString jid READ jid WRITE setJid NOTIFY jidChanged)
    QString jid() const;
    void setJid(const QString &newJid);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    virtual QHash<int, QByteArray> roleNames() const { return _roles; }

    Q_INVOKABLE QVariantMap get(int index) const;

private:
    QStringList _keys;
    QHash<int, QByteArray> _roles;
    QueryExecutor *dbExecutor;
    QString uuid;

    QString _filter;
    QString _jid;
    QString _table;

    QVariantList _modelData;

private slots:
    void dbResults(const QVariant &result);

signals:
    void filterChanged();
    void jidChanged();

public slots:

};

#endif // CONVERSATIONFILTERMODEL_H
