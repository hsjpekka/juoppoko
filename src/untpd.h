#ifndef UNTPD_H
#define UNTPD_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <oauth2.h>
#include <redirectlistener.h>

using namespace Amber::Web::Authorization;

class unTpd : public QObject
{
    Q_OBJECT
public:
    explicit unTpd(QObject *parent = nullptr);
    Q_INVOKABLE void authenticate();
    Q_INVOKABLE void authenticate(QString pathAuthorization, QString redirect, QString pathToken);
    Q_INVOKABLE void authenticateAmber();
    Q_INVOKABLE void authenticateAmber(QString pathAuthorization, QString redirect, QString pathToken);
    Q_INVOKABLE bool isNetworkAvailable();
    Q_INVOKABLE bool queryGet(QString queryId, QString url);
    Q_INVOKABLE bool queryGet(QString queryId, QString path, QString definedQuery, QString parametersToAdd = "");
    Q_INVOKABLE bool queryHeaderedGet(QString queryId, QString path, QString query, QString headers, QString parametersToAdd = "");
    Q_INVOKABLE bool queryHeaderedPost(QString queryId, QString path, QString query, QString headers, QString posting = "", QString parametersToAdd = "");
    //Q_INVOKABLE bool queryPost(QString queryId, QString url, QString posting = "");
    Q_INVOKABLE bool queryPost(QString queryId, QString path, QString query, QString posting = "", QString parametersToAdd = "");
    Q_INVOKABLE QString readOAuth2Token();
    Q_INVOKABLE bool setOAuthId(QString id);
    Q_INVOKABLE bool setOAuthPath(QString path);
    Q_INVOKABLE bool setOAuthRedirect(QString redirect);
    Q_INVOKABLE bool setOAuthSecret(QString secret);
    Q_INVOKABLE bool setOAuthToken(QString token);
    Q_INVOKABLE bool setOAuthTokenPath(QString path);
    Q_INVOKABLE int  setQueryParameter(QString id, QString value, QString key = "");
    Q_INVOKABLE bool setServer(QString protocol, QString address, int port = -1);
    Q_INVOKABLE bool setUserInfo(QString user, QString passwd);
    Q_INVOKABLE void setUserInfoReguired(bool required);//http://user:passwd@www.xx.yy
    Q_INVOKABLE bool singleGet(QString path, QString definedQuery, QString parametersToAdd = "");
    Q_INVOKABLE bool singlePost(QString path, QString posting, QString definedQuery = "", QString parametersToAdd = "");

    Q_INVOKABLE QString keyAppId();
    Q_INVOKABLE QString keyAppSecret();
    Q_INVOKABLE QString keyTokenRequest();
    Q_INVOKABLE QString keyToken();

signals:
    void finishedQuery(QString queryId, QString queryStatus, QString queryReply);
    void finishedAuthentication(QString token, QString error);

private slots:
    void replyFromServer(QNetworkReply *reply);

private:
    QString oauthPath, oauthId, oauthRedirect, oauthSecret, tokenPath, oauthToken;
    QString scheme, server, userName, userPassword;
    int serverPort;
    OAuth2 oauth2;
    RedirectListener listener;
    QStringList errorList;
    bool isUserInfoRequired;

    const QString oauthTokenRequest="OAuth2Token", tokenKey="access_token",
        appIdKey="client_id", appSecretKey="client_secret";
    enum QueryStatus {NetError, ParseError, ServiceError, Pending, Success};// netQueryStatus;
    struct keyValuePair {QString id; QString key; QString value;};
    QList<keyValuePair> storedParameters;
    struct sentRequest {QString queryId; QNetworkReply *reply; QUrl originalUrl; bool emitted;};
    QList<sentRequest> requestHistory;

    QNetworkAccessManager netManager;

    int addToQuery(QUrlQuery &query, QString keyList);
    void assembleUrl(QUrl &url, QString path, QString definedQuery, QString paramsToAdd);
    QString errorStatusToString(QueryStatus status);
    int findRequest(QNetworkReply *reply);
    QueryStatus getQueryStatus(QJsonObject reply);
    int parameterIndex(QString id);
    QString readResponse(QNetworkReply *reply);
    QJsonObject responseToJson(QNetworkReply *reply, QString *replyString);
    bool sendRequest(QString queryId, QUrl url, bool isGet, QString headers = "", QString posting = "");
    bool sendRequest(QString queryId, QString path, QString parametersToAdd, QString definedQuery, bool isGet, QString headers = "", QString posting = "");
    QString uriKey(QString uriStr, QString key, int n = -1);
};

#endif // UNTPD_H
