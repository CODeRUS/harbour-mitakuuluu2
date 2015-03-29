#include "contactsfiltermodel.h"

ContactsFilterModel::ContactsFilterModel(QObject *parent) :
    QSortFilterProxyModel(parent),
    _showActive(false),
    _showUnknown(false),
    _filterContacts(),
    _initComplete(false)
{
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    setFilterRole(Qt::UserRole + 1);
    setSortRole(Qt::UserRole + 1);
}

QVariantMap ContactsFilterModel::get(int itemIndex)
{
    QModelIndex sourceIndex = mapToSource(index(itemIndex, 0, QModelIndex()));
    QVariantMap data = _contactsModel->get(sourceIndex.row());
    return data;
}

void ContactsFilterModel::init()
{
    changeFilterRole();
    setSourceModel(_contactsModel);
    sort(0);
    _initComplete = true;
}

bool ContactsFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    QString jid = sourceModel()->data(index, Qt::UserRole + 1).toString();
    if (!_filterContacts.isEmpty()) {
        if (_filterContacts.contains(jid)) {
            return false;
        }
    }
    if (_showActive && (!jid.contains("-") && !jid.contains("@broadcast"))) {
        int lastmessage = sourceModel()->data(index, Qt::UserRole + 14).toInt();
        if (lastmessage == 0)
            return false;
    }
    if (!_showUnknown) {
        int contacttype = sourceModel()->data(index, Qt::UserRole + 6).toInt();
        if (contacttype == 0)
            return false;
    }
    if (_hideGroups) {
        if (jid.contains("-") || jid.contains("@broadcast"))
            return false;
    }

    if (filterRegExp().isEmpty())
        return true;
    else {
        QString nickname = sourceModel()->data(index, Qt::UserRole + 4).toString();
        return nickname.contains(filterRegExp());
    }
}

bool ContactsFilterModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    if (_showActive) {
        int leftlastmessage = sourceModel()->data(left, Qt::UserRole + 14).toInt();
        int rightlastmessage = sourceModel()->data(right, Qt::UserRole + 14).toInt();
        if (leftlastmessage > rightlastmessage)
            return true;
        else if (rightlastmessage > leftlastmessage)
            return false;
    }

    QString leftString = sourceModel()->data(left, Qt::UserRole + 4).toString();
    QString rightString = sourceModel()->data(right, Qt::UserRole + 4).toString();

    return leftString.toLower().localeAwareCompare(rightString.toLower()) < 0;
}

QString ContactsFilterModel::filter()
{
    return filterRegExp().pattern();
}

void ContactsFilterModel::setFilter(const QString &newFilter)
{
    setFilterFixedString(newFilter);
    if (_initComplete) {
        changeFilterRole();
    }
    Q_EMIT filterChanged();
}

bool ContactsFilterModel::showActive()
{
    return _showActive;
}

void ContactsFilterModel::setShowActive(bool value)
{
    _showActive = value;
    if (_initComplete) {
        changeFilterRole();
    }
}

bool ContactsFilterModel::showUnknown()
{
    return _showUnknown;
}

void ContactsFilterModel::setShowUnknown(bool value)
{
    _showUnknown = value;
    if (_initComplete) {
        changeFilterRole();
    }
}

bool ContactsFilterModel::hideGroups()
{
    return _hideGroups;
}

void ContactsFilterModel::setHideGroups(bool value)
{
    _hideGroups = value;
    if (_initComplete) {
        changeFilterRole();
    }
}

QStringList ContactsFilterModel::filterContacts()
{
    return _filterContacts;
}

void ContactsFilterModel::setFilterContacts(const QStringList &value)
{
    _filterContacts = value;
    _filterContacts.removeAll("undefined");
    if (_initComplete) {
        changeFilterRole();
    }
}

int ContactsFilterModel::count()
{
    return rowCount();
}

void ContactsFilterModel::changeFilterRole()
{
    int role = Qt::UserRole + 1;
    if (_showUnknown)
        role += 1;
    if (_showActive)
        role += 2;
    if (_hideGroups)
        role += 4;
    if (!_filterContacts.isEmpty())
        role += 8;
    setFilterRole(role);
}

ContactsBaseModel *ContactsFilterModel::contactsModel()
{
    return _contactsModel;
}

void ContactsFilterModel::setContactsModel(ContactsBaseModel *newModel)
{
    _contactsModel = newModel;
    if (_initComplete) {
        setSourceModel(_contactsModel);
        Q_EMIT contactsModelChanged();
    }
}
