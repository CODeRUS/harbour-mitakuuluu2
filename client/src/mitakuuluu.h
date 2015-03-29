#ifndef MITAKUULUU_H
#define MITAKUULUU_H

#include <QObject>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QStringList>
#include <QtDBus/QtDBus>
#include <QTimer>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>

#include <mlite5/MGConfItem>

#include "profile_dbus.h"

#include "../qexifimageheader/qexifimageheader.h"

#define PROFILEKEY_PRIVATE_TONE     "mitakuuluu.private.tone"
#define PROFILEKEY_PRIVATE_ENABLED  "mitakuuluu.private.enabled"
#define PROFILEKEY_PRIVATE_PATTERN  "mitakuuluu.private.pattern"

#define PROFILEKEY_GROUP_TONE       "mitakuuluu.group.tone"
#define PROFILEKEY_GROUP_ENABLED    "mitakuuluu.group.enabled"
#define PROFILEKEY_GROUP_PATTERN    "mitakuuluu.group.pattern"

#define PROFILEKEY_MEDIA_TONE       "mitakuuluu.media.tone"
#define PROFILEKEY_MEDIA_ENABLED    "mitakuuluu.media.enabled"
#define PROFILEKEY_MEDIA_PATTERN    "mitakuuluu.media.pattern"

#define TONE_FALLBACK               "/usr/share/sounds/jolla-ringtones/stereo/jolla-imtone.wav"

typedef QList<QVariantMap> QVariantMapList;
Q_DECLARE_METATYPE(QVariantMapList)

struct MyStructure {
    QString key, val, type;
};
QDBusArgument &operator<<(QDBusArgument &a, const MyStructure &mystruct);
const QDBusArgument &operator>>(const QDBusArgument &a, MyStructure &mystruct);

Q_DECLARE_METATYPE(MyStructure)

class Mitakuuluu: public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "harbour.mitakuuluu2.client")
    Q_ENUMS(ConnectionStatus)
    Q_ENUMS(MessageType)
    Q_ENUMS(MessageStatus)
    Q_ENUMS(ContactType)
    Q_SCRIPTABLE Q_PROPERTY(int connectionStatus READ connectionStatus NOTIFY connectionStatusChanged)
    Q_SCRIPTABLE Q_PROPERTY(QString connectionString READ connectionString NOTIFY connectionStringChanged)
    Q_PROPERTY(QString mcc READ mcc NOTIFY mccChanged)
    Q_PROPERTY(QString mnc READ mnc NOTIFY mncChanged)
    Q_SCRIPTABLE Q_PROPERTY(int totalUnread READ totalUnread NOTIFY totalUnreadChanged)
    Q_SCRIPTABLE Q_PROPERTY(QString myJid READ myJid NOTIFY myJidChanged)

    Q_PROPERTY(QString mediaTone READ getMediaTone WRITE setMediaTone NOTIFY mediaToneChanged)
    Q_PROPERTY(QString privateTone READ getPrivateTone WRITE setPrivateTone NOTIFY privateToneChanged)
    Q_PROPERTY(QString groupTone READ getGroupTone WRITE setGroupTone NOTIFY groupToneChanged)

    Q_PROPERTY(bool mediaToneEnabled READ getMediaToneEnabled WRITE setMediaToneEnabled NOTIFY mediaToneEnabledChanged)
    Q_PROPERTY(bool privateToneEnabled READ getPrivateToneEnabled WRITE setPrivateToneEnabled NOTIFY privateToneEnabledChanged)
    Q_PROPERTY(bool groupToneEnabled READ getGroupToneEnabled WRITE setGroupToneEnabled NOTIFY groupToneEnabledChanged)

    Q_PROPERTY(QString mediaLedColor READ getMediaLedColor WRITE setMediaLedColor NOTIFY mediaLedColorChanged)
    Q_PROPERTY(QString privateLedColor READ getPrivateLedColor WRITE setPrivateLedColor NOTIFY privateLedColorChanged)
    Q_PROPERTY(QString groupLedColor READ getGroupLedColor WRITE setGroupLedColor NOTIFY groupLedColorChanged)

    Q_SCRIPTABLE Q_PROPERTY(QString version READ version NOTIFY versionChanged)
    Q_PROPERTY(QString fullVersion READ fullVersion NOTIFY fullVersionChanged)
    Q_PROPERTY(QVariantMap webVersion READ webVersion NOTIFY webVersionChanged)

public:
    enum ConnectionStatus {
        Unknown,
        WaitingForConnection,
        Connecting,
        Connected,
        LoggedIn,
        LoginFailure,
        Disconnected,
        Registering,
        RegistrationFailed,
        AccountExpired
    };

    enum MessageType {
        Text,
        Image,
        Audio,
        Video,
        Contact,
        Location,
        Divider,
        System,
        Voice
    };

    enum MessageStatus {
        Unsent = 0,
        Uploading,
        Uploaded,
        SentByClient,
        ReceivedByServer,
        ReceivedByTarget,
        NeverSent,
        ServerBounce,
        Played,
        Notification
    };

    enum ContactType {
        UnknownContact = 0,
        KnownContact
    };

    Mitakuuluu(QObject *parent = 0);
    ~Mitakuuluu();

private:
    QVariant getProfileValue(const QString &key, const QVariant &def = QVariant()) const;
    bool setProfileValue(const QString &key, const QVariant &value);

    QString getPrivateTone() const;
    void setPrivateTone(const QString &path);
    QString getGroupTone() const;
    void setGroupTone(const QString &path);
    QString getMediaTone() const;
    void setMediaTone(const QString &path);

    bool getPrivateToneEnabled();
    void setPrivateToneEnabled(bool value);
    bool getGroupToneEnabled();
    void setGroupToneEnabled(bool value);
    bool getMediaToneEnabled();
    void setMediaToneEnabled(bool value);

    QString getPrivateLedColor() const;
    void setPrivateLedColor(const QString &pattern);
    QString getGroupLedColor() const;
    void setGroupLedColor(const QString &pattern);
    QString getMediaLedColor() const;
    void setMediaLedColor(const QString &pattern);

    QString version() const;
    QString _version;

    QString fullVersion() const;
    QString _fullVersion;

    QVariantMap webVersion() const;
    QVariantMap _webVersion;

    int connStatus;
    int connectionStatus();

    int _totalUnread;
    int totalUnread();

    QString _myJid;
    QString myJid() const;

    QHash<QString, int> _unreadCount;

    QString connString;
    QString connectionString() const;

    QString mcc() const;
    QString _mcc;
    QString mnc() const;
    QString _mnc;

    QNetworkAccessManager *nam;
    QString _pendingJid;

    QDBusInterface *iface;

    QTranslator *translator;

    QTimer *pingServer;

    QString _pendingGroup;
    QString _pendingAvatar;

    QStringList _locales;
    QStringList _localesNames;
    QString _currentLocale;

    QDBusInterface *profiled;

signals:
    void connectionStatusChanged();
    void connectionStringChanged();
    void mccChanged();
    void mncChanged();
    void myJidChanged();
    void versionChanged();
    void fullVersionChanged();
    void webVersionChanged();
    void activeChanged();
    void messageReceived(const QVariantMap &data);
    void disconnected(const QString &reason);
    void authFail(const QString &username, const QString &reason);
    void authSuccess(const QString &username);
    void networkChanged(bool value);
    void noAccountData();
    void registered();
    void smsTimeout(int timeout);
    void registrationFailed(const QVariantMap &reason);
    void registrationComplete();
    void accountExpired(const QVariantMap &reason);
    void gotAccountData(const QString &username, const QString &password);
    void codeRequested(const QVariantMap &method);
    void existsRequestFailed(const QVariantMap &serverReply);
    void codeRequestFailed(const QVariantMap &serverReply);
    void messageStatusUpdated(const QString &mjid, const QString &msgId, int msgstatus);
    void pictureUpdated(const QString &pjid, const QString &path);
    void contactsChanged();
    void contactChanged(const QVariantMap &data);
    void contactSynced(const QVariantMap &data);
    void newGroupSubject(const QVariantMap &data);
    void notificationOpenJid(const QString &njid);
    void setUnread(const QString &jid, int count);
    void pushnameUpdated(const QString &mjid, const QString &pushName);
    void presenceAvailable(const QString &mjid);
    void presenceUnavailable(const QString &mjid);
    void presenceLastSeen(const QString &mjid, int seconds);
    void mediaDownloadProgress(const QString &mjid, const QString &msgId, int progress);
    void mediaDownloadFinished(const QString &mjid, const QString &msgId, const QString &path);
    void mediaDownloadFailed(const QString &mjid, const QString &msgId);
    void groupParticipants(const QString &gjid, const QStringList &pjids);
    void groupInfo(const QVariantMap &group);
    void participantAdded(const QString &gjid, const QString &pjid);
    void participantRemoved(const QString &gjid, const QString &pjid);
    void contactsBlocked(const QStringList &list);
    void privacySettings(const QVariantMap &values);
    void activeJidChanged(const QString &ajid);
    void contactTyping(const QString &cjid);
    void contactPaused(const QString &cjid);
    void synchronizationFinished();
    void synchronizationFailed();
    void phonebookReceived(const QVariantList &contactsmodel);
    void uploadMediaFailed(const QString &mjid, const QString &msgId);
    void groupsMuted(const QStringList &jids);
    void codeReceived();
    void dissectError();
    void networkUsage(const QVariantList &networkUsage);
    void replyCrashed(bool isCrashed);
    void myAccount(const QString &account);
    void logfileReady(const QByteArray &data, bool isReady);
    void totalUnreadChanged();
    Q_SCRIPTABLE void totalUnreadValue(int totalUnread);
    void privateToneChanged();
    void groupToneChanged();
    void mediaToneChanged();
    void privateToneEnabledChanged();
    void groupToneEnabledChanged();
    void mediaToneEnabledChanged();
    void privateLedColorChanged();
    void groupLedColorChanged();
    void mediaLedColorChanged();
    void whatsappStatusReply(const QVariantMap &features);
    void androidReady(const QVariantMap &creds);
    void mediaListReceived(const QString &pjid, const QVariantList &mediaList);
    void paymentReceived(const QString &sku, const QString &delta, const QString &account);

private slots:
    void onConnectionStatusChanged(int status);
    void onSimParameters(const QString &mcccode, const QString &mnccode);
    void onSetUnread(const QString &jid, int count);
    void onMyAccount(const QString &jid);

    void onReplyCrashed(QDBusPendingCallWatcher *call);

    void doPingServer();
    void onServerPong();

    void groupCreated(const QString &gjid);
    void onGroupInfo(const QVariantMap &data);

    void handleProfileChanged(bool changed, bool active, QString profile, QList<MyStructure> keyValType);

    void onWhatsappStatus();
    void onVersionReceived();

    void readVersion();
    void readFullVersion();

    void onMediaListReceived(const QString &jid, const QVariantMapList &mediaList);

public slots:
    Q_SCRIPTABLE void exit();
    Q_SCRIPTABLE void notificationCallback(const QString &jid);

    void authenticate();
    void init();
    void disconnect();
    void sendMessage(const QString &jid, const QString &message, const QString &media, const QString &mediaData);
    void sendBroadcast(const QStringList &jids, const QString &message);
    void sendText(const QString &jid, const QString &message, const QStringList &participants = QStringList(), const QString &broadcastName = QString());
    void syncContactList();
    void setActiveJid(const QString &jid);
    QString shouldOpenJid();
    void startRecording(const QString &jid);
    void startTyping(const QString &jid);
    void endTyping(const QString &jid);
    void downloadMedia(const QString &msgId, const QString &jid);
    void cancelDownload(const QString &msgId, const QString &jid);
    void abortMediaDownload(const QString &msgId, const QString &jid);
    QString openVCardData(const QString &name, const QString &data);
    void getParticipants(const QString &jid);
    void getGroupInfo(const QString &jid);
    void regRequest(const QString &cc, const QString &phone, const QString &method, const QString &password, const QString &mcc, const QString &mnc);
    void enterCode(const QString &cc, const QString &phone, const QString &code, const QString &password);
    void setGroupSubject(const QString &gjid, const QString &subject);
    void createGroup(const QString &subject, const QString &picture, const QStringList &participants);
    void groupLeave(const QString &gjid);
    void groupRemove(const QString &gjid);
    void setPicture(const QString &jid, const QString &path);
    void getPicture(const QString &jid);
    void getContactStatus(const QString &jid);
    void removeParticipant(const QString &gjid, const QString &jid);
    void addParticipant(const QString &gjid, const QString &jid);
    void addParticipants(const QString &gjid, const QStringList &jids);
    void refreshContact(const QString &jid);
    QString transformPicture(const QString &filename, const QString &jid, int posX, int posY, int sizeW, int sizeH, int maxSize, int rotation);
    void copyToClipboard(const QString &text);
    void blockOrUnblockContact(const QString &jid);
    void sendBlockedJids(const QStringList &jids);
    void setPrivacySettings(const QString &category, const QString &value);
    void muteOrUnmuteGroup(const QString &jid);
    void muteGroups(const QStringList &jids);
    void getPrivacyList();
    void getPrivacySettings();
    void getMutedGroups();
    void forwardMessage(const QStringList &jids, const QString &jid, const QString &msgid);
    void setMyPushname(const QString &pushname);
    void setMyPresence(const QString &presence);
    void sendRecentLogs();
    void shutdown();
    void isCrashed();
    void requestLastOnline(const QString &jid);
    void addPhoneNumber(const QString &name, const QString &phone);
    void sendMedia(const QStringList &jids, const QString &path, const QString &title = QString(), const QStringList &participants = QStringList(), const QString &broadcastName = QString());
    void sendVCard(const QStringList &jids, const QString &name, const QString& data, const QStringList &participants = QStringList(), const QString &broadcastName = QString());
    QString rotateImage(const QString &path, int rotation);
    QString saveVoice(const QString &path);
    QString saveImage(const QString &path);
    QString saveMedia(const QString &path, int watype);
    QString saveWallpaper(const QString &path, const QString &jid);
    void openProfile(const QString &name, const QString &phone, const QString avatar = QString());
    void removeAccount();
    void syncContacts(const QStringList &numbers, const QStringList &names, const QStringList &avatars);
    void setPresenceAvailable();
    void setPresenceUnavailable();
    void syncAllPhonebook();
    void removeAccountFromServer();
    void forceConnection();
    void setLocale(const QString &localeName);
    void setLocale(int  index);
    int getExifRotation(const QString &image);
    void windowActive();
    bool checkLogfile();
    bool checkAutostart();
    void setAutostart(bool enabled);
    void sendLocation(const QStringList &jids, double latitude, double longitude, int zoom, const QString &source, const QStringList &participants = QStringList(), const QString &broadcastName = QString());
    void renewAccount(const QString &method, int years);
    QString checkIfExists(const QString &path);
    void unsubscribe(const QString &jid);
    QString getAvatarForJid(const QString &jid);
    QString saveAvatarForJid(const QString &jid, const QString &path);
    void rejectMediaCapture(const QString &path);
    void getNetworkUsage();
    void resetNetworkUsage();
    QStringList getLocalesNames();
    int getCurrentLocaleIndex();
    void checkWhatsappStatus();
    void checkAndroid();
    void importCredentials(const QVariantMap &data);
    void setCamera(QObject *camera);
    bool locationEnabled();
    void saveHistory(const QString &sjid, const QString &sname);
    void requestContactMedia(const QString &sjid);
    bool compressLogs();
    void checkWebVersion();
    void setRecoveryToken(const QString &token);
    void deleteBroadcast(const QString &jid);
//Settings

public slots:
    Q_INVOKABLE QString generateSalt();
};

#endif // MITAKUULUU_H
