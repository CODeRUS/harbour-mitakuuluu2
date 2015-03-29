#ifndef TRANSLATOR_H
#define TRANSLATOR_H

#include <QObject>
#include <QTranslator>

class Translator : public QObject
{
    Q_OBJECT
public:
    explicit Translator(QObject *parent = 0);

private:
    QTranslator *translator;

};

#endif // TRANSLATOR_H
