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
    Q_INVOKABLE bool queryGet(QString path, QString definedQuery, QString parametersToAdd="");
    Q_INVOKABLE bool queryPost(QString path, QString definedQuery, QString parametersToAdd="");
    Q_INVOKABLE int setQueryParameter(QString key, QString value);
    Q_INVOKABLE bool setServer(QString protocol, QString address, QString path);
    Q_INVOKABLE bool storeQueryParameter(QString key, QString value);
    Q_INVOKABLE bool userInfoReguired(bool required);

signals:
    void finishedQuery();

private slots:
    void replyFromServer();

private:
    QString scheme, server, pathCommon;
    QString userName, userPassword;
    QString latestReply;
    QStringList errorList;
    bool isUserInfoRequired;

    enum QueryStatus {NetError, ParseError, ServiceError, Pending, Success} netQueryStatus;
    struct keyValuePair {QString key; QString value;};
    QList<keyValuePair> storedParameters;

    QNetworkAccessManager netManager;
    QNetworkReply *netReply;

    int addToQuery(QUrlQuery &query, QString keyList);
    void getQueryStatus(QJsonObject reply);
    bool isAppIdNeeded(QString authType);
    bool isAppSecretNeeded(QString authType);
    bool isUserAuthNeeded(QString authType);
    bool isTokenNeeded(QString authType);
    QJsonObject responseToJson(QNetworkReply *reply, QString *jsonStorage);
    bool sendRequest(QString path, QString parametersToAdd, QString definedQuery, bool isGet);
};

#endif // UNTPD_H
