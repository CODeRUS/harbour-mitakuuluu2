#ifndef QUERYEXECUTER_H
#define QUERYEXECUTER_H

#include <QMap>
#include <QVariantMap>
#include <QStringList>

#include <QtSql/QtSql>

#include "threadworker.h"

namespace QueryType {
    enum EnumType {
        ContactsGetAll = 0,
        ContactsReloadContact,
        ContactsGetModel,
        ContactsUpdateModel,
        ContactsSaveModel,
        ContactsSetLastmessage,
        ContactsUpdatePushname,
        ContactsGetJids,
        ContactsSyncResults,
        ContactsSyncContacts,
        ContactsSetUnread,
        ContactsSetSync,
        ContactsSetStatus,
        ContactsSetAvatar,
        ContactsUpdateGroup,
        ContactsSetLastSeen,
        ContactsRemove,
        ContactsMuteGroup,
        ContactsGetMuted,
        ContactsGroupParticipants,
        ContactsClearConversation,
        ContactsCreateBroadcast,
        ConversationLoadLast = 100,
        ConversationLoadNext,
        ConversationGetMessage,
        ConversationGetDownloadMessage,
        ConversationSaveMessage,
        ConversationNotifyMessage,
        ConversationMessageStatus,
        ConversationRemoveMessage,
        ConversationRemoveAll,
        ConversationSave,
        ConversationDownloadFinished,
        ConversationMediaUploaded,
        ConversationGetMedia,
        ConversationGetCount,
        ConversationResendMessage,
        ConversationLoadFiltered,
        ConversationSetTitle,
        ConversationUpdateUrl,
        AccountGetData = 200,
        AccountSetData,
        AccountRemoveData,
        RemoveNoAction = 400
    };
}

class QueryExecutor : public QObject
{
    Q_OBJECT
public:
    explicit QueryExecutor(QObject *parent);
    static QueryExecutor *GetInstance();

public slots:
    void queueAction(QVariant msg, int priority = 0);
    void processAction(QVariant msg);

signals:
    void actionDone(QVariant msg);

private:
    void processQuery(const QVariant &msg);

    void getAccountData(QVariantMap &query);
    void setAccountData(QVariantMap &query);
    void removeAccountData(QVariantMap &query);
    void getContactsAll(QVariantMap &query);
    void getContactsJids(QVariantMap &query);
    void getContactModel(QVariantMap &query);
    void messageNotify(QVariantMap &query);
    void setContactsLastmessage(QVariantMap &query);
    void saveConversationMessage(QVariantMap &query);
    void setContactPushname(QVariantMap &query);
    void setContactUnread(QVariantMap query);
    void setContactsResults(QVariantMap &query);
    void setContactSync(QVariantMap &query);
    void setContactAvatar(QVariantMap &query);
    void getContactsShareui(QVariantMap &query);
    void getMessageModel(QVariantMap &query);
    void setGroupUpdated(QVariantMap &query);
    void setMessageStatus(QVariantMap &query);
    void setContactLastSeen(QVariantMap &query);
    void setContactModel(QVariantMap &query);
    void removeContact(QVariantMap &query);
    void getLastConversation(QVariantMap &query);
    void getNextConversation(QVariantMap &query);
    void removeMessage(QVariantMap &query);
    void removeAllMessages(QVariantMap &query);
    void saveConversation(QVariantMap &query);
    void downloadFinished(QVariantMap &query);
    void muteGroup(QVariantMap &query);
    void getMuted(QVariantMap &query);
    void mediaUploaded(QVariantMap &query);
    void getContactMedia(QVariantMap &query);
    void groupParticipants(QVariantMap &query);
    void getConversationCount(QVariantMap &query);
    void searchMessage(QVariantMap &query);
    void clearConversation(QVariantMap &query);
    void setMediaTitle(QVariantMap &query);
    void setMessageUrl(QVariantMap &query);
    void createBroadcastContact(QVariantMap &query);

private:
    ThreadWorker m_worker;
    QSqlDatabase db;
};

#endif // QUERYEXECUTER_H
