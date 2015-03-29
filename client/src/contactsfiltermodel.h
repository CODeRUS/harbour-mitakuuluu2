#ifndef CONTACTSFILTERMODEL_H
#define CONTACTSFILTERMODEL_H

#include "contactsbasemodel.h"

#include <QSortFilterProxyModel>

class ContactsFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(ContactsBaseModel *contactsModel READ contactsModel WRITE setContactsModel NOTIFY contactsModelChanged)
    Q_PROPERTY(bool showActive READ showActive WRITE setShowActive FINAL)
    Q_PROPERTY(bool showUnknown READ showUnknown WRITE setShowUnknown FINAL)
    Q_PROPERTY(bool hideGroups READ hideGroups WRITE setHideGroups FINAL)
    Q_PROPERTY(int count READ count NOTIFY countChanged FINAL)
    Q_PROPERTY(QStringList filterContacts READ filterContacts WRITE setFilterContacts FINAL)
public:
    explicit ContactsFilterModel(QObject *parent = 0);

public slots:
    Q_INVOKABLE QVariantMap get(int itemIndex);
    Q_INVOKABLE void init();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const;

private:
    bool _initComplete;

    QString filter();
    void setFilter(const QString &newFilter);

    bool _showActive;
    bool showActive();
    void setShowActive(bool value);

    bool _showUnknown;
    bool showUnknown();
    void setShowUnknown(bool value);

    bool _hideGroups;
    bool hideGroups();
    void setHideGroups(bool value);

    QStringList _filterContacts;
    QStringList filterContacts();
    void setFilterContacts(const QStringList &value);

    int count();

    void changeFilterRole();

    ContactsBaseModel *_contactsModel;
    ContactsBaseModel *contactsModel();
    void setContactsModel(ContactsBaseModel *newModel);

signals:
    void filterChanged();
    void contactsModelChanged();
    void countChanged();

};

#endif // CONTACTSFILTERMODEL_H
