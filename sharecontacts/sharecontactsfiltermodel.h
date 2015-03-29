#ifndef SHARECONTACTSFILTERMODEL_H
#define SHARECONTACTSFILTERMODEL_H

#include "sharecontactsbasemodel.h"

#include <QSortFilterProxyModel>

class ShareContactsFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
public:
    explicit ShareContactsFilterModel(QObject *parent = 0);

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    int count();

    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    QString filter();
    void setFilter(const QString &newFilter);

public slots:
    Q_INVOKABLE void startSharing(const QStringList &jids, const QString &name, const QString &data);
    Q_INVOKABLE QVariantMap get(int itemIndex);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const;

private:
    ShareContactsBaseModel *_baseModel;

signals:
    void countChanged();
    void filterChanged();
};

#endif // SHARECONTACTSFILTERMODEL_H
