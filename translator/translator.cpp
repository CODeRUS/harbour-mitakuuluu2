#include "translator.h"

#include <QGuiApplication>
#include <QStringList>
#include <QLocale>
#include <QDebug>
#include <mlite5/MGConfItem>

Translator::Translator(QObject *parent) :
    QObject(parent)
{
    MGConfItem dconf("/apps/harbour-mitakuuluu2/settings/locale");
    QString currentLocale = dconf.value(QString("%1.qm").arg(QLocale::system().name().split(".").first())).toString();

    translator = new QTranslator(this);
    qDebug() << "loading translation" << currentLocale;
    if (translator->load(currentLocale, "/usr/share/harbour-mitakuuluu2/locales", QString(), ".qm")) {
        qDebug() << "translation loaded";
        QGuiApplication::installTranslator(translator);
    }
    else {
        qDebug() << "translation not available";
    }
}
