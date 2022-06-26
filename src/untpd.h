#ifndef UNTPD_H
#define UNTPD_H

#include <QObject>
//#include <QJsonArray>
//#include <QJsonObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

class unTpd : public QObject
{
    Q_OBJECT
public:
    explicit unTpd(QObject *parent = nullptr);
    //Q_INVOKABLE bool acceptFriend(int targetId);
    //Q_INVOKABLE bool addToWishList(int targetId);
    //Q_INVOKABLE bool checkInBeer(int beerId, QString tzone, QString venueId, bool position, double lat, double lng, QString shout, double rating, bool fbook, bool twitter, bool fsquare);
    //Q_INVOKABLE bool getBadges(QString target, int offset, int limit);
    //Q_INVOKABLE bool getBeerFeed(int beerId, int maxId, int minId, int limit);
    //Q_INVOKABLE bool searchBeer(QString searchString);
    Q_INVOKABLE bool queryGet(QString path, QString parameters);
    Q_INVOKABLE bool queryPost(QString path, QString parameters);
    Q_INVOKABLE bool sendRequest(QString path, QString parameters, bool isGet);
    Q_INVOKABLE bool setAppAuthority(QString id, QString secret);
    //Q_INVOKABLE bool setUserAuthority(QString token);
    Q_INVOKABLE bool setServer(QString protocol, QString address, QString path);

signals:
    //void finishedBeerSearch();
    void finishedQuery();

private slots:
    void replyFromServer();

private:
    QString scheme, server, pathCommon;
    QString appId, appSecret;//, userToken;
    QString latestReply;
    QStringList errorList;

    enum QueryStatus {NetError, ParseError, ServiceError, Pending, Success} netQueryStatus;

    QNetworkAccessManager netManager;
    QNetworkReply *netReply;

    void getQueryStatus(QJsonObject reply);
    QJsonObject responseToJson(QNetworkReply *reply, QString *jsonStorage);
};

#endif // UNTPD_H
