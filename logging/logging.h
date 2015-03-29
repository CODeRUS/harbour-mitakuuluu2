#ifndef LOGGING_H
#define LOGGING_H

#include <QFile>
#include <QDebug>
#include <QStandardPaths>
#include <QDateTime>
//#include <systemd/sd-journal.h>

static QString logPath = "/tmp/mitakuuluu2.log";

const char* msgTypeToString(QtMsgType type)
{
    switch (type) {
    case QtDebugMsg:
        return "D";
    case QtWarningMsg:
        return "W";
    case QtCriticalMsg:
        return "C";
    case QtFatalMsg:
        return "F";
        //abort();
    default:
        return "D";
    }
}

QString infoLog(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    return QString("[%1 %2] %3:%4 (%5 %6) %7\n").arg(msgTypeToString(type))
                                                   .arg(QDateTime::currentDateTime().toString("hh:mm:ss"))
                                                   .arg(context.file)
                                                   .arg(context.line)
                                                   .arg(context.category)
                                                   .arg(context.function)
                                                   .arg(message);
}

QString simpleLog(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    Q_UNUSED(context);
    return QString("[%1 %2] %3\n").arg(msgTypeToString(type))
                                     .arg(QDateTime::currentDateTime().toString("hh:mm:ss"))
                                     .arg(message);
}

void writeLog(const QString &message)
{
    QFile file(logPath);
    if (file.open(QIODevice::Append | QIODevice::Text))
    {
        QTextStream out(&file);
        out << message;
        file.close();
    }
}

void printLog(const QString &message)
{
    QTextStream(stdout) << message;
}

void journalLog(const QString &message)
{
    Q_UNUSED(message);
    //sd_journal_print(0, "test", NULL);
    //sd_journal_send(message.toUtf8().constData(), NULL);
}

void fileHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    writeLog(infoLog(type, context, msg));
    printLog(simpleLog(type, context, msg));
    if (type == QtFatalMsg)
        abort();
}

void stdoutHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    printLog(simpleLog(type, context, msg));
    if (type == QtFatalMsg)
        abort();
}

void journalHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    //journalLog(infoLog(type, context, msg));
    printLog(simpleLog(type, context, msg));
    if (type == QtFatalMsg)
        abort();
}

#endif // LOGGING_H
