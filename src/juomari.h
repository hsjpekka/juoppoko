#ifndef JUOMARI_H
#define JUOMARI_H

#include <QObject>
#include <QString>
#include <QDate>

class juomari : public QObject
{
    Q_OBJECT
public:
    explicit juomari(QObject *parent = nullptr);
    int asetaPaino(int kg, QDate pvm = QDate::currentDate());
    int asetaVesiMaara(int pros);
    int juo(QString juoma, int ml, double prosentteja);
    double promillet(QDate pvm = QDate::currentDate());

signals:

};

#endif // JUOMARI_H
