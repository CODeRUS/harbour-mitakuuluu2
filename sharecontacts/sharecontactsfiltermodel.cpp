#include "sharecontactsfiltermodel.h"

ShareContactsFilterModel::ShareContactsFilterModel(QObject *parent) :
    QSortFilterProxyModel(parent)
{
    setSortRole(Qt::UserRole + 4);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setSortLocaleAware(true);

    setFilterRole(Qt::UserRole + 4);
    setFilterCaseSensitivity(Qt::CaseInsensitive);

    _baseModel = new ShareContactsBaseModel(parent);
    setSourceModel(_baseModel);
    sort(0);
}

void ShareContactsFilterModel::startSharing(const QStringList &jids, const QString &name, const QString &data)
{
    _baseModel->startSharing(jids, name, data);
}

QVariantMap ShareContactsFilterModel::get(int itemIndex)
{
    QModelIndex sourceIndex = mapToSource(index(itemIndex, 0, QModelIndex()));
    QVariantMap data = _baseModel->get(sourceIndex.row());
    return data;
}

bool ShareContactsFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (filterRegExp().isEmpty())
        return true;
    else {
        QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
        QString nickname = sourceModel()->data(index, Qt::UserRole + 4).toString();
        return nickname.contains(filterRegExp());
    }
}

bool ShareContactsFilterModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    QString leftString = sourceModel()->data(left, Qt::UserRole + 4).toString();
    QString rightString = sourceModel()->data(right, Qt::UserRole + 4).toString();

    return leftString.toLower().localeAwareCompare(rightString.toLower()) < 0;
}

int ShareContactsFilterModel::count()
{
    return rowCount();
}

QString ShareContactsFilterModel::filter()
{
    return filterRegExp().pattern();
}

void ShareContactsFilterModel::setFilter(const QString &newFilter)
{
    setFilterFixedString(newFilter);
    Q_EMIT filterChanged();
}
