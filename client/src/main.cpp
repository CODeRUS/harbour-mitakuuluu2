/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <QtQuick>
#include <sailfishapp.h>

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <grp.h>
#include <pwd.h>

#include <QFile>
#include <QTextStream>
#include <QDateTime>

#include "constants.h"

#include "contactsbasemodel.h"
#include "contactsfiltermodel.h"
#include "conversationmodel.h"
#include "conversationfiltermodel.h"
#include "mitakuuluu.h"
#include "audiorecorder.h"
#include "../dconf/dconfvalue.h"

#include <QDebug>

#include <QLocale>
#include <QTranslator>

#include <gst/gst.h>
#include <gst/gstpreset.h>

#include <QSqlDatabase>
#include <QSqlQuery>

#include <mlite5/MGConfItem>

#include "../dconf/dconfmigration.h"
#include "../logging/logging.h"

static QObject *mitakuuluu_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    static Mitakuuluu *mitakuuluu_singleton = NULL;
    if (!mitakuuluu_singleton) {
        mitakuuluu_singleton = new Mitakuuluu();
    }
    return mitakuuluu_singleton;
}

static QObject *contactsmodel_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    static ContactsBaseModel *contactsmodel_singleton = NULL;
    if (!contactsmodel_singleton) {
        contactsmodel_singleton = new ContactsBaseModel();
    }
    return contactsmodel_singleton;
}

Q_DECL_EXPORT
int main(int argc, char *argv[])
{
    setuid(getpwnam("nemo")->pw_uid);
    setgid(getgrnam("privileged")->gr_gid);

    migrate_dconf();

    MDConfItem ready("/apps/harbour-mitakuuluu2/migrationIsDone");
    if (!ready.value(false).toBool()) {
        qDebug() << "QSettings was migrated to dconf!";
        ready.set(true);
    }

    MDConfItem keepLogs("/apps/harbour-mitakuuluu2/settings/keepLogs");
    if (keepLogs.value(true).toBool())
        qInstallMessageHandler(fileHandler);
    else
        qInstallMessageHandler(stdoutHandler);

    qDebug() << "Init gst presets";
    gst_init(0, 0);
    gst_preset_set_app_dir("/usr/share/harbour-mitakuuluu2/presets");

    qDBusRegisterMetaType<MyStructure>();
    qDBusRegisterMetaType<QList<MyStructure > >();

    qDebug() << "Starting application";
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName("harbour-mitakuuluu2");
    app->setApplicationName("harbour-mitakuuluu2");

    // copying old mitakuuluu database to new place
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::DataLocation);
    QString dataFile = QString("%1/database.db").arg(dataDir);
    QString oldFile = QString("%1/.whatsapp/whatsapp.db").arg(QDir::homePath());

    QFile newDBFile(dataFile);
    QFile oldDBFile(oldFile);

    if (!newDBFile.exists() && oldDBFile.exists()) {
        qDebug() << "Should transfer old database";
        oldDBFile.copy(dataFile);

        QSqlDatabase db = QSqlDatabase::database();
        if (!db.isOpen()) {
            qDebug() << "QE Opening database";
            db = QSqlDatabase::addDatabase("QSQLITE");
            QDir dir(dataDir);
            if (!dir.exists())
                dir.mkpath(dataDir);
            qDebug() << "DB Dir:" << dataDir;
            db.setDatabaseName(dataFile);
            qDebug() << "DB Name:" << db.databaseName();
            if (db.open())
                qDebug() << "QE opened database";
            else
                qWarning() << "QE failed to open database";
        }
        else {
            qWarning() << "QE used existing DB connection!";
        }

        if (db.isOpen()) {
            qDebug() << "database open";
            if (db.tables().contains("contacts")) {
                qDebug() << "Begin transfer old database";

                qDebug() << "Tweaking database contacts table";
                db.exec("UPDATE contacts SET contacttype=1;");

                foreach (QString table, db.tables()) {
                    if (table.startsWith("u")) {
                        QString tmpTable = table;
                        tmpTable.replace("u", "x");
                        QString jid = table;
                        jid.replace("g", "-").replace("u", "");
                        jid.append(table.contains("g") ? "@g.us" : "@s.whatsapp.net");
                        qDebug() << "Transfer database table" << table << "started";
                        db.exec(QString("ALTER TABLE %1 RENAME TO %2;").arg(table).arg(tmpTable));
                        db.exec(QString("CREATE TABLE %1 (msgid TEXT, jid TEXT, author TEXT, timestamp INTEGER, data TEXT, status INTEGER, watype INTEGER, url TEXT, name TEXT, latitude TEXT, longitude TEXT, size INTEGER, duration INTEGER, width INTEGER, height INTEGER, hash TEXT, mime TEXT, broadcast INTEGER, live INTEGER, local TEXT);").arg(table));
                        QSqlQuery query(db);
                        query.prepare(QString("SELECT msgid, author, timestamp, message, msgstatus FROM %1 WHERE msgtype=(:msgtype);").arg(tmpTable));
                        query.bindValue(":msgtype", 2);
                        query.exec();
                        while (query.next()) {
                            QSqlQuery transfer(db);
                            transfer.prepare(QString("INSERT INTO %1 VALUES (:msgid, :jid, :author, :timestamp, :data, :status, :watype, :url, :name, :latitude, :longitude, :size, :duration, :width, :height, :hash, :mime, :broadcast, :live, :local);").arg(table));
                            transfer.bindValue(":msgid", query.value("msgid"));
                            transfer.bindValue(":jid", jid);
                            transfer.bindValue(":author", query.value("author"));
                            transfer.bindValue(":timestamp", query.value("timestamp"));
                            transfer.bindValue(":data", query.value("message"));
                            transfer.bindValue(":status", query.value("msgstatus"));
                            transfer.bindValue(":watype", 0);
                            transfer.bindValue(":url", "");
                            transfer.bindValue(":name", "");
                            transfer.bindValue(":latitude", "");
                            transfer.bindValue(":longitude", "");
                            transfer.bindValue(":size", 0);
                            transfer.bindValue(":duration", 0);
                            transfer.bindValue(":width", 0);
                            transfer.bindValue(":height", 0);
                            transfer.bindValue(":mime", "");
                            transfer.bindValue(":broadcast", 0);
                            transfer.bindValue(":live", 0);
                            transfer.bindValue(":local", "");
                            transfer.exec();
                        }
                        db.exec(QString("DROP TABLE %1;").arg(tmpTable));
                        qDebug() << "Transfer database table" << table << "complete";
                    }
                    else if (table == "login") {
                        // drop old login information from table
                        db.exec("DROP TABLE login;");
                    }
                    else if (table == "muted") {
                        // drop unused table
                        db.exec("DROP TABLE muted;");
                    }
                }
            }
            db.close();
        }
        else {
            qWarning() << "who closed database connection!?";
        }
    }

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setTitle("Mitakuuluu");

    view->rootContext()->setContextProperty("view", view.data());
    view->rootContext()->setContextProperty("app", app.data());

    view->rootContext()->setContextProperty("emojiPath", "/usr/share/harbour-mitakuuluu2/emoji/");

    view->engine()->addImportPath("/usr/share/harbour-mitakuuluu2/qml");

    qDebug() << "Registering QML types";
    qmlRegisterType<ContactsFilterModel>("harbour.mitakuuluu2.client", 1, 0, "ContactsFilterModel");
    qmlRegisterType<ConversationModel>("harbour.mitakuuluu2.client", 1, 0, "ConversationModel");
    qmlRegisterType<AudioRecorder>("harbour.mitakuuluu2.client", 1, 0, "AudioRecorder");
    qmlRegisterType<ConversationFilterModel>("harbour.mitakuuluu2.client", 1, 0, "ConversationFilterModel");

    qmlRegisterSingletonType<ContactsBaseModel>("harbour.mitakuuluu2.client", 1, 0, "ContactsBaseModel", contactsmodel_singleton_provider);
    qmlRegisterSingletonType<Mitakuuluu>("harbour.mitakuuluu2.client", 1, 0, "Mitakuuluu", mitakuuluu_singleton_provider);

    qmlRegisterType<DConfValue>("harbour.mitakuuluu2.client", 1, 0, "DConfValue");

    qDebug() << "Showing main widow";
    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->showFullScreen();

    qDebug() << "View showed";;

    int retVal = app->exec();
    qDebug() << "App exiting with code:" << QString::number(retVal);
    return retVal;
}

