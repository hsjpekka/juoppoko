#ifndef UNTPD_H
#define UNTPD_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

class unTpd : public QObject
{
    Q_OBJECT
public:
    explicit unTpd(QObject *parent = nullptr);
    Q_INVOKABLE bool searchBeer(QString searchString);
    Q_INVOKABLE bool setAppAuthority(QString id, QString secret);
    Q_INVOKABLE bool setUserAuthority(QString token);
    Q_INVOKABLE bool setApi(QString scheme, QString server, QString path);

signals:
    void finishedBeerSearch();

//private slots:
//
private:
    QString scheme, server, path;
    QString appId, appSecret, userToken;

};

#endif // UNTPD_H
