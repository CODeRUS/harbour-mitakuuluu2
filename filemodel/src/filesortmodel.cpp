#include "filesortmodel.h"

#include <QDebug>

FileSortModel::FileSortModel(QObject *parent) :
    QSortFilterProxyModel(parent),
    _sorting(false)
{
    setSortRole(Qt::UserRole + 5);
}

FileSourceModel *FileSortModel::fileModel()
{
    return _fileModel;
}

void FileSortModel::setFileModel(FileSourceModel *newModel)
{
    _fileModel = newModel;
    setSourceModel(_fileModel);
    sort(0);
    Q_EMIT fileModelChanged();
}

bool FileSortModel::getSorting()
{
    return _sorting;
}

void FileSortModel::setSorting(bool newSorting)
{
    _sorting = newSorting;
    setSortRole(_sorting ? Qt::UserRole + 1 : Qt::UserRole + 5);
    Q_EMIT sortingChanged();
}

int FileSortModel::count()
{
    return rowCount();
}

QVariantMap FileSortModel::get(int itemIndex)
{
    QModelIndex sourceIndex = mapToSource(index(itemIndex, 0, QModelIndex()));
    QVariantMap data = _fileModel->get(sourceIndex.row());
    return data;
}

bool FileSortModel::remove(int itemIndex)
{
    QModelIndex sourceIndex = mapToSource(index(itemIndex, 0, QModelIndex()));
    return _fileModel->remove(sourceIndex.row());
}

bool FileSortModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    if (_sorting) {
        QString leftPath = sourceModel()->data(left, Qt::UserRole + 1).toString();
        QString rightPath = sourceModel()->data(right, Qt::UserRole + 1).toString();

        return leftPath.localeAwareCompare(rightPath) < 0;
    }
    else {
        int leftTime = sourceModel()->data(left, Qt::UserRole + 5).toInt();
        int rightTime = sourceModel()->data(right, Qt::UserRole + 5).toInt();

        return leftTime > rightTime;
    }
}
