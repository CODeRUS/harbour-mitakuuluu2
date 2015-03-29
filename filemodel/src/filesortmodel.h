#ifndef FILESORTMODEL_H
#define FILESORTMODEL_H

#include "filemodel.h"

#include <QSortFilterProxyModel>

class FileSortModel : public QSortFilterProxyModel
{
    Q_OBJECT
public:
    explicit FileSortModel(QObject *parent = 0);

    Q_PROPERTY(FileSourceModel *fileModel READ fileModel WRITE setFileModel NOTIFY fileModelChanged)

    Q_PROPERTY(bool sorting READ getSorting WRITE setSorting NOTIFY sortingChanged)

    Q_PROPERTY(int count READ count NOTIFY countChanged FINAL)
    int count();

    Q_INVOKABLE QVariantMap get(int itemIndex);
    Q_INVOKABLE bool remove(int itemIndex);

private:
    bool getSorting();
    void setSorting(bool newSorting);
    bool _sorting;

    FileSourceModel *_fileModel;
    FileSourceModel *fileModel();
    void setFileModel(FileSourceModel *newModel);

signals:
    void sortingChanged();
    void fileModelChanged();
    void countChanged();

protected:
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const;

};

#endif // FILESORTMODEL_H
