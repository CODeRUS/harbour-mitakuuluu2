#include "mitakuuluu.h"
#include "constants.h"

#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QDateTime>
#include <QDesktopServices>
#include <QImage>
#include <QImageReader>
#include <QTransform>
#include <QGuiApplication>
#include <QClipboard>
#include <QStandardPaths>
#include <QMediaService>
#include <QMediaObject>
#include <QVideoEncoderSettingsControl>
#include <QVideoEncoderSettings>
#include <QAudioEncoderSettingsControl>
#include <QAudioEncoderSettings>

Q_DECLARE_METATYPE(QList<MyStructure>)

QDBusArgument &operator<<(QDBusArgument &argument, const MyStructure &mystruct)
{
    argument.beginStructure();
    argument << mystruct.key << mystruct.val << mystruct.type;
    argument.endStructure();
    return argument;
}

// Retrieve the MyStructure data from the D-Bus argument
const QDBusArgument &operator>>(const QDBusArgument &argument, MyStructure &mystruct)
{
    argument.beginStructure();
    argument >> mystruct.key;
    argument >> mystruct.val;
    argument >> mystruct.type;
    argument.endStructure();
    return argument;
}

Mitakuuluu::Mitakuuluu(QObject *parent): QObject(parent)
{
    qDebug() << "Creating dbus...";
    bool ret =
            QDBusConnection::sessionBus().registerService(SERVICE_NAME) &&
            QDBusConnection::sessionBus().registerObject(OBJECT_NAME,
                                                         this,
                                                         QDBusConnection::ExportScriptableContents);
    if (ret) {
        qDebug() << "dbus created";
        nam = new QNetworkAccessManager(this);
        _pendingJid = QString();
        connStatus = Unknown;
        translator = 0;
        _totalUnread = 0;

        QStringList locales;
        QStringList localeNames;
        QString baseName("/usr/share/harbour-mitakuuluu2/locales/");
        QDir localesDir(baseName);
        if (localesDir.exists()) {
            locales = localesDir.entryList(QStringList() << "*.qm", QDir::Files | QDir::NoDotAndDotDot, QDir::Name | QDir::IgnoreCase);
            qDebug() << "available translations:" << locales;
        }
        foreach (const QString &locale, locales) {
            if (locale.contains("-")) {
                localeNames << QString("%1 (%2)")
                                       .arg(QLocale::languageToString(QLocale(locale).language()))
                                       .arg(QLocale::countryToString(QLocale(locale).country()));
            }
            else {
                localeNames << QLocale::languageToString(QLocale(locale).language());
            }
        }
        _locales =  locales.isEmpty() ? QStringList() << "en.qm" : locales;
        _localesNames = localeNames.isEmpty() ? QStringList() << "Engineering english" : localeNames;

        MGConfItem ready("/apps/harbour-mitakuuluu2/migrationIsDone");
        if (!ready.value(false).toBool()) {
            QSettings settings("coderus", "mitakuuluu2");
            _currentLocale = settings.value("settings/locale", QString("%1.qm").arg(QLocale::system().name().split(".").first())).toString();
        }
        else {
            MGConfItem locale("/apps/harbour-mitakuuluu2/settings/locale");
            _currentLocale = locale.value(QString("%1.qm").arg(QLocale::system().name().split(".").first())).toString();
        }

        setLocale(_currentLocale);

        qDBusRegisterMetaType<QVariantMapList>();

        QDBusConnection::sessionBus().connect(PROFILED_SERVICE, PROFILED_PATH, PROFILED_INTERFACE,
                        "profile_changed", QString("bbsa(sss)"), this,
                        SIGNAL(handleProfileChanged(bool, bool, QString, QList<MyStructure>)));

        profiled = new QDBusInterface(PROFILED_SERVICE, PROFILED_PATH, PROFILED_INTERFACE, QDBusConnection::sessionBus());

        qDebug() << "Connecting to DBus signals";
        iface = new QDBusInterface(SERVER_SERVICE,
                                   SERVER_PATH,
                                   SERVER_INTERFACE,
                                   QDBusConnection::sessionBus(),
                                   this);
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "messageReceived", this, SIGNAL(messageReceived(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "disconnected", this, SIGNAL(disconnected(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "authFail", this, SIGNAL(authFail(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "authSuccess", this, SIGNAL(authSuccess(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "networkAvailable", this, SIGNAL(networkChanged(bool)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "noAccountData", this, SIGNAL(noAccountData()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "messageStatusUpdated", this, SIGNAL(messageStatusUpdated(QString,QString,int)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "pictureUpdated", this, SIGNAL(pictureUpdated(QString,QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsChanged", this, SIGNAL(contactsChanged()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "notificationOpenJid", this, SIGNAL(notificationOpenJid(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "setUnread", this, SLOT(onSetUnread(QString,int)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "myAccount", this, SLOT(onMyAccount(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "pushnameUpdated", this, SIGNAL(pushnameUpdated(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactAvailable", this, SIGNAL(presenceAvailable(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactUnavailable", this, SIGNAL(presenceUnavailable(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactLastSeen", this, SIGNAL(presenceLastSeen(QString, int)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactChanged", this, SIGNAL(contactChanged(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactSynced", this, SIGNAL(contactSynced(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "newGroupSubject", this, SIGNAL(newGroupSubject(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "downloadProgress", this, SIGNAL(mediaDownloadProgress(QString, QString, )));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "mediaDownloadFinished", this, SIGNAL(mediaDownloadFinished(QString, QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "downloadFailed", this, SIGNAL(mediaDownloadFailed(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "connectionStatusChanged", this, SIGNAL(onConnectionStatusChanged(int)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupParticipants", this, SIGNAL(groupParticipants(QString, QStringList)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupInfo", this, SIGNAL(onGroupInfo(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "registered", this, SIGNAL(registered()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "smsTimeout", this, SIGNAL(smsTimeout(int)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "registrationFailed", this, SIGNAL(registrationFailed(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "existsRequestFailed", this, SIGNAL(existsRequestFailed(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "registrationComplete", this, SIGNAL(registrationComplete()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "codeRequestFailed", this, SIGNAL(codeRequestFailed(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "codeRequested", this, SIGNAL(codeRequested(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "accountExpired", this, SIGNAL(accountExpired(QVariantMap)));;
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupCreated", this, SLOT(groupCreated(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupParticipantAdded", this, SIGNAL(participantAdded(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupParticipantRemoved", this, SIGNAL(participantRemoved(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsBlocked", this, SIGNAL(contactsBlocked(QStringList)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "privacySettings", this, SIGNAL(privacySettings(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactTyping", this, SIGNAL(contactTyping(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactPaused", this, SIGNAL(contactPaused(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "synchronizationFinished", this, SIGNAL(synchronizationFinished()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "synchronizationFailed", this, SIGNAL(synchronizationFailed()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "uploadFailed", this, SIGNAL(uploadMediaFailed(QString,QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupsMuted", this, SIGNAL(groupsMuted(QStringList)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "dissectError", this, SIGNAL(dissectError()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "logfileReady", this, SIGNAL(logfileReady(QByteArray, bool)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "pong", this, SLOT(onServerPong()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "simParameters", this, SLOT(onSimParameters(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "networkUsage", this, SIGNAL(networkUsage(QVariantList)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "mediaListReceived", this, SLOT(onMediaListReceived(QString,QVariantMapList)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "paymentReceived", this, SIGNAL(paymentReceived(QString,QString,QString)));
        qDebug() << "Start pinging server";
        pingServer = new QTimer(this);
        QObject::connect(pingServer, SIGNAL(timeout()), this, SLOT(doPingServer()));
        pingServer->setInterval(30000);
        pingServer->setSingleShot(false);
        pingServer->start();
        qDebug() << "Sending ready to daemon";
        iface->call(QDBus::NoBlock, "ready");

        checkWhatsappStatus();

        QProcess *app = new QProcess(this);
        app->start("/bin/rpm", QStringList() << "-qa" << "--queryformat" << "%{version}" <<  "harbour-mitakuuluu2");
        if (app->bytesAvailable() > 0) {
            _version = app->readAll();
            Q_EMIT versionChanged();
        }
        else {
            _version = "n/a";
            connect(app, SIGNAL(readyRead()), this, SLOT(readVersion()));
        }

        QProcess *app2 = new QProcess(this);
        app2->start("/bin/rpm", QStringList() << "-qa" << "--queryformat" << "%{version}-%{release}" <<  "harbour-mitakuuluu2");
        if (app2->bytesAvailable() > 0) {
            _fullVersion = app2->readAll();
            Q_EMIT fullVersionChanged();
        }
        else {
            _fullVersion = "n/a";
            connect(app2, SIGNAL(readyRead()), this, SLOT(readFullVersion()));
        }

        checkWebVersion();
    }
    else {
        QGuiApplication::exit(1);
    }
}

Mitakuuluu::~Mitakuuluu()
{
    if (connStatus == LoggedIn)
        setPresenceUnavailable();
}

QVariant Mitakuuluu::getProfileValue(const QString &key, const QVariant &def) const
{
    QDBusMessage reply = profiled->call(PROFILED_GET_VALUE,
                                        QVariant("general"),
                                        QVariant(key));

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qDebug() << "error reply:" << reply.errorName();
    } else if (reply.arguments().count() > 0) {
        return reply.arguments().at(0);
    }
    return def;
}

bool Mitakuuluu::setProfileValue(const QString &key, const QVariant &value)
{
    QDBusMessage reply = profiled->call(PROFILED_SET_VALUE,
                                        QVariant("general"),
                                        QVariant(key),
                                        value);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qDebug() << "error reply:" << reply.errorName();
    } else if (reply.arguments().count() > 0) {
        return reply.arguments().at(0).toBool();
    }
    return false;
}

int Mitakuuluu::connectionStatus()
{
    return connStatus;
}

QString Mitakuuluu::connectionString() const
{
    return connString;
}

QString Mitakuuluu::mcc() const
{
    return _mcc;
}

QString Mitakuuluu::mnc() const
{
    return _mnc;
}

int Mitakuuluu::totalUnread()
{
    return _totalUnread;
}

QString Mitakuuluu::myJid() const
{
    return _myJid;
}

void Mitakuuluu::onConnectionStatusChanged(int status)
{
    connStatus = status;
    Q_EMIT connectionStatusChanged();
    switch (connStatus) {
    default:
        connString = tr("Unknown", "Unknown connection status");
        break;
    case WaitingForConnection:
        connString = tr("Waiting for connection", "Waiting for connection connection status");
        break;
    case Connecting:
        connString = tr("Connecting...", "Connecting connection status");
        break;
    case Connected:
        connString = tr("Authentication...", "Authentication connection status");
        break;
    case LoggedIn:
        connString = tr("Logged in", "Logged in connection status");
        break;
    case LoginFailure:
        connString = tr("Login failed!", "Login failed connection status");
        break;
    case Disconnected:
        connString = tr("Disconnected", "Disconnected connection status");
        break;
    case Registering:
        connString = tr("Registering...", "Registering connection status");
        break;
    case RegistrationFailed:
        connString = tr("Registration failed!", "Registration failed connection status");
        break;
    case AccountExpired:
        connString = tr("Account expired!", "Account expired connection status");
        break;
    }
    Q_EMIT connectionStringChanged();
}

void Mitakuuluu::authenticate()
{
    if (iface)
        iface->call(QDBus::NoBlock, "recheckAccountAndConnect");
}

void Mitakuuluu::init()
{
    if (iface)
        iface->call(QDBus::NoBlock, "init");
}

void Mitakuuluu::disconnect()
{
    if (iface)
        iface->call(QDBus::NoBlock, "disconnect");
}

void Mitakuuluu::sendMessage(const QString &jid, const QString &message, const QString &media, const QString &mediaData)
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendMessage", jid, message, media, mediaData);
}

void Mitakuuluu::sendBroadcast(const QStringList &jids, const QString &message)
{
    if (iface)
        iface->call(QDBus::NoBlock, "broadcastSend", jids, message);
}

void Mitakuuluu::sendText(const QString &jid, const QString &message, const QStringList &participants, const QString &broadcastName)
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendText", jid, message, participants, broadcastName);
}

void Mitakuuluu::syncContactList()
{
    if (iface)
        iface->call(QDBus::NoBlock, "synchronizeContacts");
}

void Mitakuuluu::setActiveJid(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "setActiveJid", jid);
    Q_EMIT activeJidChanged(jid);
}

QString Mitakuuluu::shouldOpenJid()
{
    return _pendingJid;
}

void Mitakuuluu::startRecording(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "startRecording", jid);
}

void Mitakuuluu::startTyping(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "startTyping", jid);
}

void Mitakuuluu::endTyping(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "endTyping", jid);
}

void Mitakuuluu::downloadMedia(const QString &msgId, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "downloadMedia", msgId, jid);
}

void Mitakuuluu::cancelDownload(const QString &msgId, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "cancelDownload", msgId, jid);
}

void Mitakuuluu::abortMediaDownload(const QString &msgId, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "cancelDownload", msgId, jid);
}

QString Mitakuuluu::openVCardData(const QString &name, const QString &data)
{
    QString path = QString("%1/%2.vcf").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation))
                                       .arg(name);
    QFile file(path);
    if (file.exists())
        file.remove();
    if (file.open(QFile::WriteOnly | QFile::Text)) {
        file.write(data.toUtf8());
        file.close();
    }
    return path;
}

void Mitakuuluu::getParticipants(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "getParticipants", jid);
}

void Mitakuuluu::getGroupInfo(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "getGroupInfo", jid);
}

void Mitakuuluu::regRequest(const QString &cc, const QString &phone, const QString &method, const QString &password, const QString &mcc, const QString &mnc)
{
    if (iface)
        iface->call(QDBus::NoBlock, "regRequest", cc, phone, method, password, mcc, mnc);
}

void Mitakuuluu::enterCode(const QString &cc, const QString &phone, const QString &code, const QString &password)
{
    if (iface)
        iface->call(QDBus::NoBlock, "enterCode", cc, phone, code, password);
}

void Mitakuuluu::setGroupSubject(const QString &gjid, const QString &subject)
{
    if (iface)
        iface->call(QDBus::NoBlock, "setGroupSubject", gjid, subject);
}

void Mitakuuluu::createGroup(const QString &subject, const QString &picture, const QStringList &participants)
{
    if (iface) {
        _pendingAvatar = picture;
        iface->call(QDBus::NoBlock, "createGroupChat", subject, participants);
    }
}

void Mitakuuluu::groupLeave(const QString &gjid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "requestLeaveGroup", gjid);
}

void Mitakuuluu::groupRemove(const QString &gjid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "requestRemoveGroup", gjid);
}

void Mitakuuluu::setPicture(const QString &jid, const QString &path)
{
    if (iface)
        iface->call(QDBus::NoBlock, "setPicture", jid, path);
}

void Mitakuuluu::getPicture(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "getPicture", jid);
}

void Mitakuuluu::getContactStatus(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "getContactStatus", jid);
}

void Mitakuuluu::removeParticipant(const QString &gjid, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "removeGroupParticipant", gjid, jid);
}

void Mitakuuluu::addParticipant(const QString &gjid, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "addGroupParticipant", gjid, jid);
}

void Mitakuuluu::addParticipants(const QString &gjid, const QStringList &jids)
{
    if (iface)
        iface->call(QDBus::NoBlock, "addGroupParticipants", gjid, jids);
}

void Mitakuuluu::refreshContact(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "refreshContact", jid);
}

QString Mitakuuluu::transformPicture(const QString &filename, const QString &jid, int posX, int posY, int sizeW, int sizeH, int maxSize, int rotation)
{
    qDebug() << "Preparing picture" << filename << "- rotation:" << QString::number(rotation);
    QString image = filename;
    image = image.replace("file://","");

    QImage preimg(image);

    if (sizeW == sizeH) {
        preimg = preimg.copy(posX,posY,sizeW,sizeH);
        if (sizeW > maxSize)
            preimg = preimg.scaledToWidth(maxSize, Qt::SmoothTransformation);
    }
    if (rotation != 0) {
        QTransform rot;
        rot.rotate(rotation);
        preimg = preimg.transformed(rot);
    }
    if (sizeW != sizeH) {
        preimg = preimg.copy(posX,posY,sizeW,sizeH);
        if (sizeW > maxSize)
            preimg = preimg.scaledToWidth(maxSize, Qt::SmoothTransformation);
    }
    QString destDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/avatar";
    QDir dir(destDir);
    if (!dir.exists())
        dir.mkpath(destDir);
    QString path = QString("%1/%2").arg(destDir)
                                   .arg(jid);
    qDebug() << "Saving to:" << path << (preimg.save(path, "JPG", 90) ? "success" : "error");

    return path;
}

void Mitakuuluu::copyToClipboard(const QString &text)
{
    QClipboard *clip = QGuiApplication::clipboard();
    clip->setText(text);
}

void Mitakuuluu::blockOrUnblockContact(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "blockOrUnblockContact", jid);
}

void Mitakuuluu::sendBlockedJids(const QStringList &jids)
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendBlockedJids", jids);
}

void Mitakuuluu::setPrivacySettings(const QString &category, const QString &value)
{
    if (iface)
        iface->call(QDBus::NoBlock, "setPrivacySettings", category, value);
}

void Mitakuuluu::muteOrUnmuteGroup(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "muteOrUnmuteGroup", jid);
}

void Mitakuuluu::muteGroups(const QStringList &jids)
{
    if (iface)
        iface->call(QDBus::NoBlock, "muteGroups", jids);
}

void Mitakuuluu::getPrivacyList()
{
    if (iface)
        iface->call(QDBus::NoBlock, "getPrivacyList");
}

void Mitakuuluu::getPrivacySettings()
{
    if (iface)
        iface->call(QDBus::NoBlock, "getPrivacySettings");
}

void Mitakuuluu::getMutedGroups()
{
    if (iface)
        iface->call(QDBus::NoBlock, "getMutedGroups");
}

void Mitakuuluu::forwardMessage(const QStringList &jids, const QString &jid, const QString &msgid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "forwardMessage", jids, jid, msgid);
}

void Mitakuuluu::setMyPushname(const QString &pushname)
{
    if (iface)
        iface->call(QDBus::NoBlock, "changeUserName", pushname);
}

void Mitakuuluu::setMyPresence(const QString &presence)
{
    if (iface)
        iface->call(QDBus::NoBlock, "changeStatus", presence);
}

void Mitakuuluu::sendRecentLogs()
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendRecentLogs");
}

void Mitakuuluu::shutdown()
{
    qDebug() << "shutdown";
    pingServer->stop();
    if (iface)
        iface->call(QDBus::NoBlock, "exit");
    qDebug() << system("killall -9 harbour-mitakuuluu2-server");
    qDebug() << system("killall -9 harbour-mitakuuluu2");
}

void Mitakuuluu::isCrashed()
{
    if (iface) {
        QDBusPendingCall async = iface->asyncCall("isCrashed");
        QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(async, this);
        if (watcher->isFinished()) {
           onReplyCrashed(watcher);
        }
        else {
            QObject::connect(watcher, SIGNAL(finished(QDBusPendingCallWatcher*)),this, SLOT(onReplyCrashed(QDBusPendingCallWatcher*)));
        }
    }
}

void Mitakuuluu::requestLastOnline(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "requestQueryLastOnline", jid);
}

void Mitakuuluu::addPhoneNumber(const QString &name, const QString &phone)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "newContactAdd", name, phone);
    }
}

void Mitakuuluu::onReplyCrashed(QDBusPendingCallWatcher *call)
{
    bool value = false;
    QDBusPendingReply<bool> reply = *call;
    if (reply.isError()) {
        qDebug() << "error:" << reply.error().name() << reply.error().message();
    } else {
        value = reply.argumentAt<0>();
    }
    Q_EMIT replyCrashed(value);
    call->deleteLater();
}

void Mitakuuluu::onSimParameters(const QString &mcccode, const QString &mnccode)
{
    _mcc = mcccode;
    Q_EMIT mccChanged();
    _mnc = mnccode;
    Q_EMIT mncChanged();
}

void Mitakuuluu::onSetUnread(const QString &jid, int count)
{
    int lastUnread = _totalUnread;

    _unreadCount[jid] = count;
    _totalUnread = 0;
    foreach (int unread, _unreadCount.values())
        _totalUnread += unread;
    Q_EMIT setUnread(jid, count);

    if (lastUnread != _totalUnread) {
        Q_EMIT totalUnreadValue(_totalUnread);
    }
    Q_EMIT totalUnreadChanged();
}

void Mitakuuluu::onMyAccount(const QString &jid)
{
    _myJid = jid;
    Q_EMIT myJidChanged();
}

void Mitakuuluu::doPingServer()
{
    if (iface)
        iface->call(QDBus::NoBlock, "ping");
}

void Mitakuuluu::onServerPong()
{

}

void Mitakuuluu::groupCreated(const QString &gjid)
{
    _pendingGroup = gjid;
}

void Mitakuuluu::onGroupInfo(const QVariantMap &data)
{
    if (data["jid"].toString() == _pendingGroup) {
        if (!_pendingAvatar.isEmpty()) {
            setPicture(_pendingGroup, _pendingAvatar);
        }
        Q_EMIT notificationOpenJid(_pendingGroup);
        _pendingAvatar.clear();
        _pendingGroup.clear();
    }
    Q_EMIT groupInfo(data);
}

void Mitakuuluu::handleProfileChanged(bool changed, bool active, QString profile, QList<MyStructure> keyValType)
{
    qDebug() << "handleProfileChanged" << changed << active << profile;
    foreach (MyStructure item, keyValType) {
        qDebug() << item.type << item.key << item.val;
    }
}

void Mitakuuluu::onWhatsappStatus()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray json = reply->readAll();
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(json, &error);
        if (error.error == QJsonParseError::NoError) {
            QVariantMap mapResult = doc.toVariant().toMap();
            Q_EMIT whatsappStatusReply(mapResult);
            /*
            {"email":{"available":true},
            "last":{"available":true},
            "sync":{"available":true},
            "chat":{"available":true},
            "group":{"available":true},
            "multimedia":{"available":true},
            "online":{"available":true},
            "profile":{"available":true},
            "push":{"available":true},
            "registration":{"available":true},
            "status":{"available":true},
            "broadcast":{"available":true},
            "version":{"available":true}}
            */
        }
    }
}

void Mitakuuluu::onVersionReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray json = reply->readAll();
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(json, &error);
        if (error.error == QJsonParseError::NoError) {
            _webVersion = doc.toVariant().toMap();
            Q_EMIT webVersionChanged();
        }
    }
}

void Mitakuuluu::readVersion()
{
    QProcess *app = qobject_cast<QProcess*>(sender());
    if (app && app->bytesAvailable() > 0) {
        _version = app->readAll();
        Q_EMIT versionChanged();
    }
}

void Mitakuuluu::readFullVersion()
{
    QProcess *app = qobject_cast<QProcess*>(sender());
    if (app && app->bytesAvailable() > 0) {
        _fullVersion = app->readAll();
        Q_EMIT fullVersionChanged();
    }
}

void Mitakuuluu::onMediaListReceived(const QString &jid, const QVariantMapList &mediaList)
{
    QVariantList val;
    foreach(const QVariantMap &var, mediaList) {
        val << var;
    }
    Q_EMIT mediaListReceived(jid, val);
}

void Mitakuuluu::exit()
{
    qDebug() << "Remote command requested exit";
    QGuiApplication::exit(0);
}

void Mitakuuluu::notificationCallback(const QString &jid)
{
    _pendingJid = jid;
    Q_EMIT notificationOpenJid(jid);
}

void Mitakuuluu::sendMedia(const QStringList &jids, const QString &path, const QString &title, const QStringList &participants, const QString &broadcastName)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "sendMedia", jids, path, title.isEmpty() ? path.split("/").last() : title, participants, broadcastName);
    }
}

void Mitakuuluu::sendVCard(const QStringList &jids, const QString &name, const QString &data, const QStringList &participants, const QString &broadcastName)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "sendVCard", jids, name, data, participants, broadcastName);
    }
}

QString Mitakuuluu::rotateImage(const QString &path, int rotation)
{
    if (rotation == 0)
        return path;
    QString fname = path;
    fname = fname.replace("file://", "");
    if (QFile(fname).exists()) {
        qDebug() << "rotateImage" << fname << QString::number(rotation);
        QImage img(fname);
        QTransform rot;
        rot.rotate(rotation);
        img = img.transformed(rot);
        fname = fname.split("/").last();
        fname = QString("%1/%2-%3").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation))
                                   .arg(QDateTime::currentDateTime().toTime_t())
                                   .arg(fname);
        qDebug() << "destination:" << fname;
        if (img.save(fname))
            return fname;
        else
            return QString();
    }
    return QString();
}

QString Mitakuuluu::saveVoice(const QString &path)
{
    //TODO: remove it
    QString savePath = QString("%1/Mitakuuluu").arg(QStandardPaths::writableLocation(QStandardPaths::MusicLocation));
    qDebug() << "Requested to save" << path << "to gallery" << savePath;
    QDir dir(savePath);
    if (!dir.exists())
        dir.mkpath(savePath);

    if (!path.contains(savePath)) {
        QString cutpath = path;
        cutpath = cutpath.replace("file://", "");
        QFile old(cutpath);
        if (old.exists()) {
            QString fname = cutpath.split("/").last();
            QString destination = QString("%1/%2").arg(savePath).arg(fname);
            old.copy(cutpath, destination);
            return destination;
        }
    }
    return path;
}

QString Mitakuuluu::saveImage(const QString &path)
{
    QString images = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    qDebug() << "Requested to save" << path << "to gallery" << images;

    if (!path.contains(images)) {
        QString cutpath = path;
        cutpath = cutpath.replace("file://", "");
        QFile img(cutpath);
        if (img.exists()) {
            QString name = path.split("/").last().split("@").first();
            QString id = path.split("/").last().split("-").last();
            if (name != id) {
                name = QString("%1-%2").arg(name).arg(id);
            }
            qDebug() << "saveImage" << path << "name:" << name;
            img.open(QFile::ReadOnly);
            QString ext = "jpg";
            img.seek(1);
            QByteArray buf = img.read(3);
            if (buf == "PNG")
                ext = "png";
            img.close();
            QString destination = QString("%1/%2.%3").arg(images).arg(name).arg(ext);
            img.copy(cutpath, destination);
            qDebug() << "destination:" << destination;
            return destination;
        }
    }
    return path;
}

QString Mitakuuluu::saveMedia(const QString &path, int watype)
{
    QString location;
    switch (watype) {
    case Image: {
        location = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
        break;
    }
    case Audio: {
        location = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
        break;
    }
    case Video: {
        location = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
        break;
    }
    default: {
        location = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
        break;
    }
    }
    qDebug() << "Requested to save" << path << "to gallery" << location;

    if (!path.contains(location)) {
        QString cutpath = path;
        cutpath = cutpath.replace("file://", "");
        QFile file(cutpath);
        if (file.exists()) {
            QString name = path.split("/").last().split("@").first();
            qDebug() << "saveMedia" << path << "name:" << name;
            QString destination = QString("%1/%2").arg(location).arg(name);
            file.copy(cutpath, destination);
            qDebug() << "destination:" << destination;
            return destination;
        }
    }
    return path;
}

QString Mitakuuluu::saveWallpaper(const QString &path, const QString &jid)
{
    QString wallpapers = QStandardPaths::writableLocation(QStandardPaths::DataLocation) + "/wallpapers";
    if (!QDir(wallpapers).exists())
        QDir::home().mkpath(wallpapers);

    if (!path.contains(wallpapers)) {
        QString cutpath = path;
        cutpath = cutpath.replace("file://", "");
        QFile img(cutpath);
        if (img.exists()) {
            img.open(QFile::ReadOnly);
            img.close();
            QString destination = QString("%1/%2").arg(wallpapers).arg(jid);
            QFile(destination).remove();
            img.copy(cutpath, destination);
            qDebug() << "destination:" << destination;
            return destination;
        }
    }
    return path;
}

void Mitakuuluu::openProfile(const QString &name, const QString &phone, const QString avatar)
{
    QFile tmp(QString("%1/_mitakuuluu-%2").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation))
                                         .arg(phone));
    if (tmp.open(QFile::WriteOnly | QFile::Text)) {
        QTextStream out(&tmp);
        out << "BEGIN:VCARD\n";
        out << "VERSION:3.0\n";
        out << "FN:" << name << "\n";
        out << "N:" << name << "\n";
        out << "TEL:" << phone << "\n";
        if (!avatar.isEmpty()) {

        }
        out << "END:VCARD";
        tmp.close();

        QDesktopServices::openUrl(tmp.fileName());
    }
}

void Mitakuuluu::removeAccount()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "removeAccount");
    }
}

void Mitakuuluu::syncContacts(const QStringList &numbers, const QStringList &names, const QStringList &avatars)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "syncContacts", numbers, names, avatars);
    }
}

void Mitakuuluu::setPresenceAvailable()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "setPresenceAvailable");
    }
}

void Mitakuuluu::setPresenceUnavailable()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "setPresenceUnavailable");
    }
}

void Mitakuuluu::syncAllPhonebook()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "synchronizePhonebook");
    }
}

void Mitakuuluu::removeAccountFromServer()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "removeAccountFromServer");
    }
}

void Mitakuuluu::forceConnection()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "forceConnection");
    }
}

void Mitakuuluu::setLocale(const QString &localeName)
{
    if (translator) {
        QGuiApplication::removeTranslator(translator);
        delete translator;
        translator = 0;
    }

    QString locale = localeName.split(".").first();

    translator = new QTranslator(this);

    qDebug() << "Loading translation:" << locale;
    if (translator->load(locale, "/usr/share/harbour-mitakuuluu2/locales", QString(), ".qm")) {
        qDebug() << "Translator loaded";
        qDebug() << (QGuiApplication::installTranslator(translator) ? "Translator installed" : "Error installing translator");
    }
    else {
        qDebug() << "Translation not available";
    }
}

void Mitakuuluu::setLocale(int index)
{
    QString locale = _locales[index];
    MGConfItem localeSetting("/apps/harbour-mitakuuluu2/settings/locale");
    localeSetting.set(locale);
    setLocale(locale);
}

int Mitakuuluu::getExifRotation(const QString &image)
{
    int rotation = 0;
    if (image.toLower().endsWith(".jpg") || image.toLower().endsWith(".jpeg")) {
        QExifImageHeader exif(image);
        int orientation = exif.value(QExifImageHeader::Orientation).toSignedLong();
        if (orientation == 6)
            rotation = 90;
    }
    return rotation;
}

void Mitakuuluu::windowActive()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "windowActive");
    }
}

bool Mitakuuluu::checkLogfile()
{
    return QFile("/tmp/mitakuuluu2.log").exists();
}

bool Mitakuuluu::checkAutostart()
{
    QString autostartUser = QString(AUTOSTART_USER).arg(QDir::homePath());
    QFile service(autostartUser);
    return service.exists();
}

void Mitakuuluu::setAutostart(bool enabled)
{
    QString autostartUser = QString(AUTOSTART_USER).arg(QDir::homePath());
    if (enabled) {
        QString autostartDir = QString(AUTOSTART_DIR).arg(QDir::homePath());
        QDir dir(autostartDir);
        if (!dir.exists())
            dir.mkpath(autostartDir);
        QFile service(AUTOSTART_SERVICE);
        service.link(autostartUser);
    }
    else {
        QFile service(autostartUser);
        service.remove();
    }
}

void Mitakuuluu::sendLocation(const QStringList &jids, double latitude, double longitude, int zoom, const QString &source, const QStringList &participants, const QString &broadcastName)
{
    if (iface) {
        qDebug() << "sendLocation" << latitude << longitude;
        iface->call(QDBus::NoBlock, "sendLocation", jids, QString::number(latitude), QString::number(longitude), zoom, source, participants, broadcastName);
    }
}

void Mitakuuluu::renewAccount(const QString &method, int years)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "renewAccount", method, years);
    }
}

QString Mitakuuluu::checkIfExists(const QString &path)
{
    if (QFile(path).exists())
        return path;
    return QString();
}

void Mitakuuluu::unsubscribe(const QString &jid)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "unsubscribe", jid);
    }
}

QString Mitakuuluu::getAvatarForJid(const QString &jid)
{
    QString dirname = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/avatar";
    QString fname = QString("%1/%2").arg(dirname).arg(jid);
    return fname;
}

QString Mitakuuluu::saveAvatarForJid(const QString &jid, const QString &path)
{
    QString dirname = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/avatar";
    QString toName = QString("%1/%2").arg(dirname).arg(jid);
    QString fromName = path;
    fromName.replace("file://", "");
    QFile(toName).remove();
    QFile(fromName).copy(toName);
    return toName;
}

void Mitakuuluu::rejectMediaCapture(const QString &path)
{
    QFile file(path);
    if (file.exists())
        file.remove();
}

void Mitakuuluu::getNetworkUsage()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "getNetworkUsage");
    }
}

void Mitakuuluu::resetNetworkUsage()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "resetNetworkUsage");
    }
}

QString Mitakuuluu::getPrivateTone() const
{
    QString tone = getProfileValue(PROFILEKEY_PRIVATE_TONE, TONE_FALLBACK).toString();
    qDebug() << "getPrivateTone" << tone;
    return tone;
}

void Mitakuuluu::setPrivateTone(const QString &path)
{
    qDebug() << "setPrivateTone" << path;

    qDebug() << "success:" << setProfileValue(PROFILEKEY_PRIVATE_TONE, path);

    Q_EMIT privateToneChanged();
}

QString Mitakuuluu::getGroupTone() const
{
    return getProfileValue(PROFILEKEY_GROUP_TONE, TONE_FALLBACK).toString();
}

void Mitakuuluu::setGroupTone(const QString &path)
{
    setProfileValue(PROFILEKEY_GROUP_TONE, path);

    Q_EMIT groupToneChanged();
}

QString Mitakuuluu::getMediaTone() const
{
    return getProfileValue(PROFILEKEY_MEDIA_TONE, TONE_FALLBACK).toString();
}

void Mitakuuluu::setMediaTone(const QString &path)
{
    setProfileValue(PROFILEKEY_MEDIA_TONE, path);

    Q_EMIT mediaToneChanged();
}

bool Mitakuuluu::getPrivateToneEnabled()
{
    return getProfileValue(PROFILEKEY_PRIVATE_ENABLED, "On").toString() == "On";
}

void Mitakuuluu::setPrivateToneEnabled(bool value)
{
    setProfileValue(PROFILEKEY_PRIVATE_ENABLED, value ? "On" : "Off");

    Q_EMIT privateToneEnabledChanged();
}

bool Mitakuuluu::getGroupToneEnabled()
{
    return getProfileValue(PROFILEKEY_GROUP_ENABLED, "On").toString() == "On";
}

void Mitakuuluu::setGroupToneEnabled(bool value)
{
    setProfileValue(PROFILEKEY_GROUP_ENABLED, value ? "On" : "Off");

    Q_EMIT groupToneEnabledChanged();
}

bool Mitakuuluu::getMediaToneEnabled()
{
    return getProfileValue(PROFILEKEY_MEDIA_ENABLED, "On").toString() == "On";
}

void Mitakuuluu::setMediaToneEnabled(bool value)
{
    setProfileValue(PROFILEKEY_MEDIA_ENABLED, value ? "On" : "Off");

    Q_EMIT mediaToneEnabledChanged();
}

QString Mitakuuluu::getPrivateLedColor() const
{
    return getProfileValue(PROFILEKEY_PRIVATE_PATTERN, "PatternMitakuuluuRed").toString();
}

void Mitakuuluu::setPrivateLedColor(const QString &pattern)
{
    setProfileValue(PROFILEKEY_PRIVATE_PATTERN, pattern);

    Q_EMIT privateLedColorChanged();
}

QString Mitakuuluu::getGroupLedColor() const
{
    return getProfileValue(PROFILEKEY_GROUP_PATTERN, "PatternMitakuuluuGreen").toString();
}

void Mitakuuluu::setGroupLedColor(const QString &pattern)
{
    setProfileValue(PROFILEKEY_GROUP_PATTERN, pattern);

    Q_EMIT groupLedColorChanged();
}

QString Mitakuuluu::getMediaLedColor() const
{
    return getProfileValue(PROFILEKEY_MEDIA_PATTERN, "PatternMitakuuluuCyan").toString();
}

void Mitakuuluu::setMediaLedColor(const QString &pattern)
{
    setProfileValue(PROFILEKEY_MEDIA_PATTERN, pattern);

    Q_EMIT mediaLedColorChanged();
}

QString Mitakuuluu::version() const
{
    return _version;
}

QString Mitakuuluu::fullVersion() const
{
    return _fullVersion;
}

QVariantMap Mitakuuluu::webVersion() const
{
    return _webVersion;
}

QStringList Mitakuuluu::getLocalesNames()
{
    return _localesNames;
}

int Mitakuuluu::getCurrentLocaleIndex()
{
    if (_locales.contains(_currentLocale)) {
        return _locales.indexOf(_currentLocale);
    }
    else
        return 0;
}

void Mitakuuluu::checkWhatsappStatus()
{
    connect(nam->get(QNetworkRequest(QUrl("https://www.whatsapp.com/status.php?v=2"))),
            SIGNAL(finished()), this, SLOT(onWhatsappStatus()));
}

void Mitakuuluu::checkAndroid()
{
    QProcess proc;
    proc.start("/usr/bin/harbour-mitakuuluu2-helper");
    proc.waitForFinished(5000);
    if (proc.exitCode() == 0) {
        QStringList data = QString(proc.readAll()).split(",");
        if (data.length() > 1) {
            QVariantMap creds;
            creds["cc"] = data.at(0);
            creds["number"] = data.at(1);
            creds["login"] = QString("%1%2").arg(data.at(0)).arg(data.at(1));
            creds["pw"] = data.at(2);
            Q_EMIT androidReady(creds);
        }
    }
}

void Mitakuuluu::importCredentials(const QVariantMap &data)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "saveCredentials", data);
    }
}

void Mitakuuluu::setCamera(QObject *camera)
{
    QMediaObject *mediaObject = camera
            ? qobject_cast<QMediaObject *>(camera->property("mediaObject").value<QObject *>())
            : 0;

    if (mediaObject && mediaObject->service()) {

        /*QAudioEncoderSettingsControl *audioEncoder = mediaObject->service()->requestControl<QAudioEncoderSettingsControl *>();
        if (audioEncoder) {
            QAudioEncoderSettings settings = audioEncoder->audioSettings();
            settings.setBitRate(64000);
            settings.setSampleRate(12000);
            settings.setChannelCount(2);
            audioEncoder->setAudioSettings(settings);
        }*/

        QVideoEncoderSettingsControl *videoEncoder = mediaObject->service()->requestControl<QVideoEncoderSettingsControl *>();
        if (videoEncoder) {
            QVideoEncoderSettings settings = videoEncoder->videoSettings();
            settings.setEncodingOption(QLatin1String("preset"), QLatin1String("vga"));
            /*settings.setBitRate(2000000);
            settings.setEncodingMode(QMultimedia::ConstantBitRateEncoding);
            settings.setFrameRate(30);
            settings.setQuality(QMultimedia::HighQuality);*/
            videoEncoder->setVideoSettings(settings);
        }
    }
}

bool Mitakuuluu::locationEnabled()
{
    QSettings location("/etc/location/location.conf", QSettings::IniFormat);
    return location.value("location/enabled", false).toBool();
}

void Mitakuuluu::saveHistory(const QString &sjid, const QString &sname)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "saveHistory", sjid, sname);
    }
}

void Mitakuuluu::requestContactMedia(const QString &sjid)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "requestContactMedia", sjid);
    }
}

bool Mitakuuluu::compressLogs()
{
    QFile logfile("/tmp/mitakuuluu2.log");
    if (logfile.exists()) {
        QProcess zip;
        zip.start("/usr/bin/zip", QStringList() << "/tmp/mitakuuluu2log.zip" << "/tmp/mitakuuluu2.log");
        zip.waitForFinished();
        return zip.exitStatus() == QProcess::NormalExit;
    }
    return false;
}

void Mitakuuluu::checkWebVersion()
{
    connect(nam->get(QNetworkRequest(QUrl("https://coderus.openrepos.net/mitakuuluu.json"))),
            SIGNAL(finished()), this, SLOT(onVersionReceived()));
}

void Mitakuuluu::setRecoveryToken(const QString &token)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "setRecoveryToken", token);
    }
}

void Mitakuuluu::deleteBroadcast(const QString &jid)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "deleteBroadcast", jid);
    }
}

QString Mitakuuluu::generateSalt()
{
    return QUuid::createUuid().toString().replace("-", "");
}
