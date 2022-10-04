#ifndef UNTPD_H
#define UNTPD_H

#include <QObject>
//#include <QJsonArray>
//#include <QJsonObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QScopedPointer>
#include <sailfishapp.h>
#include <oauth2.h>
#include <redirectlistener.h>

class unTpd : public QObject
{
    Q_OBJECT
public:
    explicit unTpd(QObject *parent = nullptr);
    Q_INVOKABLE bool isNetworkAvailable();
    Q_INVOKABLE void authenticate(QString pathAuthorization, QString redirect, QString pathToken);
    Q_INVOKABLE bool queryGet(QString queryId, QString path, QString definedQuery, QString parametersToAdd="");
    Q_INVOKABLE bool queryPost(QString queryId, QString path, QString definedQuery, QString parametersToAdd="");
    Q_INVOKABLE int  setQueryParameter(QString id, QString value, QString key="");
    Q_INVOKABLE bool setClientId(QString id);
    Q_INVOKABLE bool setClientSecret(QString secret);
    Q_INVOKABLE bool setClientRedirect(QString redirect);
    Q_INVOKABLE bool setServer(QString protocol, QString address, int port = -1);
    Q_INVOKABLE bool setUserInfo(QString user, QString passwd);
    Q_INVOKABLE void setUserInfoReguired(bool required);//http://user:passwd@www.xx.yy
    Q_INVOKABLE bool singleGet(QString path, QString definedQuery, QString parametersToAdd="");
    Q_INVOKABLE bool singlePost(QString path, QString definedQuery, QString parametersToAdd="");
    //Q_INVOKABLE bool storeQueryParameter(QString key, QString value);

signals:
    void finishedQuery(QString queryId, QString queryStatus, QString queryReply);

private slots:
    void replyFromServer(QNetworkReply *reply);
    void redirectListenerFailed();
    void oauth2ErrorChanged();
    void oauth2UriChanged();
    void oauth2ReceivedAccessToken();
    void oauth2ReceivedRedirect();

private:
    //QGuiApplication *prgrm;
    OAuth2 oauth2;
    RedirectListener listener;
    QString oauthId, oauthSecret, oauthRedirect;
    QString scheme, server;//, pathCommon;
    QString userName, userPassword;
    int serverPort;
    //QString latestReply;
    QStringList errorList;
    bool isUserInfoRequired;

    enum QueryStatus {NetError, ParseError, ServiceError, Pending, Success};// netQueryStatus;
    struct keyValuePair {QString id; QString key; QString value;};
    QList<keyValuePair> storedParameters;
    struct sentRequest {QString queryId; QNetworkReply *reply; QUrl originalUrl; bool emitted;};
    QList<sentRequest> requestHistory;

    QNetworkAccessManager netManager;
    //QNetworkReply *netReply;

    int addToQuery(QUrlQuery &query, QString keyList);
    void assembleUrl(QUrl &url, QString path, QString definedQuery, QString paramsToAdd);
    int findRequest(QNetworkReply *reply);
    QueryStatus getQueryStatus(QJsonObject reply);
    bool isAppIdNeeded(QString authType);
    bool isAppSecretNeeded(QString authType);
    bool isUserAuthNeeded(QString authType);
    bool isTokenNeeded(QString authType);
    QString readResponse(QNetworkReply *reply);
    QJsonObject responseToJson(QNetworkReply *reply, QString *replyString);
    bool sendRequest(QString queryId, QString path, QString parametersToAdd, QString definedQuery, bool isGet);
    QString errorStatusToString(QueryStatus status);
};

#endif // UNTPD_H
