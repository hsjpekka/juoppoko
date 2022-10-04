#include "untpd.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
//#include <QDebug>
#include <QUrlQuery>
//#include <QByteArray>
#include <oauth2.h>
#include <redirectlistener.h>

using namespace Amber::Web::Authorization;

unTpd::unTpd(QObject *parent) : QObject(parent)
{
    scheme = "https";
    server = "api.untappd.com";
    //pathCommon = "/v4";
    serverPort = -1;
    //keyError = "status";
}

int unTpd::addToQuery(QUrlQuery &query, QString keyList)
{
    QStringList keys;
    //QString result;
    int i, iN, j, jN, result;
    bool search;
    keyList.replace(" ", "");
    keys = keyList.split(",",QString::SkipEmptyParts);
    result = 0;
    i = 0;
    iN = keys.length();
    jN = storedParameters.length();
    while (i < iN) {
        j = 0;
        search = true;
        while (j < jN && search) {
            //qInfo() << storedParameters.at(j).id << keys.at(i);
            if (storedParameters.at(j).id == keys.at(i)) {
                search = false;
            } else {
                j++;
            }
        }
        if (j < jN) {
            query.addQueryItem(storedParameters.at(j).key, storedParameters.at(j).value);
            result++;
        }
        i++;
    }

    qInfo() << query.toString() << keyList << iN << jN;

    return result;
}

void unTpd::assembleUrl(QUrl &url, QString path, QString definedQuery, QString paramsToAdd)
{
    QUrlQuery query;

    url.setScheme(scheme);
    if (isUserInfoRequired) {
        url.setUserName(userName);
        if (!userPassword.isNull()) {
            url.setPassword(userPassword);
        }
    }
    url.setHost(server);
    if (serverPort > 0) {
        url.setPort(serverPort);
    }
    url.setPath(path);//(pathCommon + path);

    query = QUrlQuery(definedQuery);
    addToQuery(query, paramsToAdd);
    url.setQuery(query);

    return;
}

/*
void unTpd::download()
{
    QUrl url;
    QUrlQuery query;
    QNetworkRequest request;
    QString path;

    url.setScheme(scheme);
    url.setHost(server);
    url.setPath(path);
    //query.addQueryItem("access_token", userToken);
    url.setQuery(query);
    request.setUrl(url);

    //activityReply = netManager.get(request);
    //connect(activityReply, SIGNAL(finished()), this, SLOT(fromCloudActivity()));

    return;
} // */

QString unTpd::errorStatusToString(QueryStatus status)
{
    QString result;

    if (status == NetError) {
        result = "NetError";
    } else if (status == ParseError) {
        result = "ParseError";
    } else if (status == ServiceError) {
        result = "ServiceError";
    } else if (status == Pending) {
        result = "Pending";
    } else { // if (status == Success) {
        result = "Success";
    }

    return result;
}

int unTpd::findRequest(QNetworkReply *reply)
{
    int i, N, result = -1;
    sentRequest recent;
    i=0;
    N=requestHistory.length();
    while (i < N) {
        recent = requestHistory.at(i);
        if (reply == recent.reply) {
            result = i;
            i = N;
        }
        i++;
    }
    return result;
}

unTpd::QueryStatus unTpd::getQueryStatus(QJsonObject reply)
{
    QJsonObject obj;
    QJsonValue val;
    QString str;
    QueryStatus result;
    int statusCode; // 1xx not yet, 2xx success, 3xx redirect, 4xx client error, 5xx server error

    statusCode = -1;
    result = ParseError;

    if (reply.contains("meta")) {
        val = reply.value("meta");
        if (val.isObject()) {
            obj = val.toObject();
            if (obj.contains("code")) {
                val = reply.value("code");
                if (val.isDouble()) {
                    statusCode = val.toInt();
                }
                if (statusCode >= 200 && statusCode <= 299) {
                    result = Success;
                } else if (statusCode >= 400 && statusCode <= 599) {
                    result = ServiceError;
                }
                str.append(val.toString());
            } else {
                errorList.append("No Code in JSON.Meta");
                result = ParseError;
            }
            if (obj.contains("error_type")) {
                val = reply.value("error_type");
                str.append(", error_detail: ");
                str.append(val.toString());
            }
            if (obj.contains("error_detail")) {
                val = reply.value("error_detail");
                str.append(", error_detail: ");
                str.append(val.toString());
            }
            if (obj.contains("developer_friendly")) {
                val = reply.value("developer_friendly");
                str.append(", developer_friendly: ");
                str.append(val.toString());
            }
        } else {
            errorList.append("No Meta in JSON-response.");
            result = ParseError;
        }
    } else {
        errorList.append("No Meta in JSON-response.");
        result = ParseError;
    }

    if (result != Success && !str.isEmpty() && !str.isNull()) {
        errorList.append(str);
        qInfo() << str;
    }

    return result;
}

bool unTpd::isNetworkAvailable()
{
    return (netManager.networkAccessible() == QNetworkAccessManager::Accessible);
}

void unTpd::authenticate(QString pathAuthorization, QString redirect, QString pathToken)
{
    //OAuth2 oauth2;
    //RedirectListener listener;

    //QObject::connect(&listener, &RedirectListener::failed, this, [&listener]() {
    //    qWarning() << "Listener failed to listen!";
    //} );
    QObject::connect(&listener, &RedirectListener::failed, this, &unTpd::redirectListenerFailed);

    //QObject::connect(&oauth2, &OAuth2::errorChanged, this, [&oauth2]() {
    //    qWarning() << "Error! " << oauth2.error().code() << ":" << oauth2.error().message();
    //});
    QObject::connect(&oauth2, OAuth2::errorChanged, this, &unTpd::oauth2ErrorChanged);

    QObject::connect(&listener, &RedirectListener::uriChanged,
                     [&listener, &oauth2]() {
        qDebug() << "Listening for redirects on uri:" << listener.uri();
        oauth2.setRedirectUri(listener.uri());
        QDesktopServices::openUrl(oauth2.generateAuthorizationUrl());
    });

    QObject::connect(&listener, &RedirectListener::receivedRedirect,
                     this, [&listener, &oauth2](const QString &redirectUri) {
        const QVariantMap data = oauth2.parseRedirectUri(redirectUri);
        if (!data.value("code").toString().isEmpty()) {
            qDebug() << "Received auth code, about to request access token";
            oauth2.setCustomParameters(QVariantMap());
            oauth2.requestAccessToken(data.value("code").toString(),
                                      data.value("state").toString());
        } else {
            qWarning() << "Unable to parse authorization code from redirect: " << redirectUri;
        }
    });

    QObject::connect(&oauth2, &OAuth2::receivedAccessToken,
                     this, [&listener, &oauth2, &netManager](const QVariantMap &token) {
        qDebug() << "Received access token: " << token.value("access_token").toString();
        listener.stopListening();

        QUrl url(QStringLiteral("https://www.googleapis.com/oauth2/v2/userinfo"));
        QNetworkRequest request(url);
        request.setRawHeader(QString(QLatin1String("Authorization")).toUtf8(),
                             QString(QLatin1String("Bearer ") + token.value("access_token").toString()).toUtf8());
        QNetworkReply *reply = netManager.get(request);
        if (!reply) {
            qWarning() << "Failed to perform authenticated request";
            return;
        }

        qDebug() << "Performing authenticated request";
        QObject::connect(reply, &QNetworkReply::finished,
                         this, [&listener, &oauth2, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                qWarning() << "Authenticated request error: " << reply->errorString()
                           << " : " << reply->readAll();
            } else {
                qDebug() << reply->readAll();
            }
            app.quit();
        });
    });

    oauth2.setClientId(oauthId);
    oauth2.setClientSecret(oauthSecret);  // enter your app's clientSecret here
    oauth2.setTokenEndpoint(pathToken); // "https://untappd.com/oauth/authorize/", "https://accounts.google.com/o/oauth2/token"
    oauth2.setAuthorizationEndpoint(pathAuthorization); // "https://untappd.com/oauth/authenticate/", "https://accounts.google.com/o/oauth2/auth"
    //oauth2.setScope(); // "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"
    oauth2.setState(oauth2.generateState());
    oauth2.setCodeVerifier(oauth2.generateCodeVerifier());

    listener.startListening();

    return;
}

void unTpd::oauth2ErrorChanged()
{
    qWarning() << "Error! " << oauth2.error().code() << ":" << oauth2.error().message();
}

void unTpd::redirectListenerFailed()
{
    qWarning() << "Redirect listener failed to listen!";
    //emit failed();
    return;
}

bool unTpd::queryGet(QString queryId, QString path, QString definedQuery, QString parametersToAdd)
{
    return sendRequest(queryId, path, parametersToAdd, definedQuery, true);
}

bool unTpd::queryPost(QString queryId, QString path, QString definedQuery, QString parametersToAdd)
{
    return sendRequest(queryId, path, parametersToAdd, definedQuery, false);
}

void unTpd::replyFromServer(QNetworkReply *reply)
{
    QJsonValue cloudValue;
    sentRequest currentRequest;
    int iReply;
    QJsonObject replyJson;
    QueryStatus status;
    QString replyString;

    //latestReply.clear();

    iReply = findRequest(reply);
    if (iReply < 0 || iReply >= requestHistory.length()) {
        return;
    }
    currentRequest = requestHistory.at(iReply);

    if (currentRequest.reply->isRunning()) {
        return;
    }
    replyJson = responseToJson(reply, &replyString);
    reply->deleteLater();
    requestHistory.removeAt(iReply);

    //if (currentRequest.reply->error() == QNetworkReply::NoError && !replyJson.isEmpty()) {
        //status = getQueryStatus(replyJson);
        //emit finishedQuery(currentRequest.queryId, errorStatusToString(status), replyString);
    //}
    status = getQueryStatus(replyJson);
    emit finishedQuery(currentRequest.queryId, errorStatusToString(status), replyString);

    return;
}

QJsonObject unTpd::responseToJson(QNetworkReply *reply, QString *replyString)
{
    // returns an empty QJsonObject if any errors are detected
    QByteArray data;
    QJsonParseError parseError;
    QJsonDocument document;
    QJsonObject result;
    QString str("");

    if (reply->error() == QNetworkReply::NoError) {
        data = reply->readAll();
        replyString->append(data);
        document = QJsonDocument::fromJson(data, &parseError);
        if (parseError.error == QJsonParseError::NoError) {
            result = document.object();
            if (result.contains("status")) {
                qInfo() << result.value("status") << ":";
                if (result.contains("title"))
                    qInfo() << result.value("title");
                if (result.contains("detail"))
                    qInfo() << "\n" << result.value("detail") << "\n";
            }
        } else {
            //netQueryStatus = ParseError;
            str.append("parse error: ");
            str.append(parseError.errorString() + " ::: ");
            str.append(data);
            errorList.append(str);
            qInfo() << str;
        }
    } else {
        //netQueryStatus = NetError;
        //replyString->append("");//append(reply->errorString())
        str.append("network error: ");
        str.append(reply->errorString() + " ::: ");
        errorList.append(str);
        qInfo() << reply->error() << ":" << reply->errorString();
    }

    return result;
}

bool unTpd::sendRequest(QString queryId, QString path, QString parametersToAdd, QString definedQuery, bool isGet)
{
    QUrl url;
    QNetworkRequest request;
    QNetworkReply *netReply;
    sentRequest currentRequest;

    assembleUrl(url, path, definedQuery, parametersToAdd);
    request.setUrl(url);

    //netQueryStatus = Pending;
    if (isGet) {
        netReply = netManager.get(request);
    } else {
        netReply = netManager.post(request, "");
    }

    currentRequest.queryId = queryId;
    currentRequest.originalUrl = url;
    currentRequest.reply = netReply;
    currentRequest.emitted = false;
    requestHistory.append(currentRequest);
    connect(&netManager, SIGNAL(finished(QNetworkReply *)), this, SLOT(replyFromServer(QNetworkReply *)));

    return true;
}

bool unTpd::setClientId(QString id)
{
    bool result = true;
    oauthId = id;
    if (id.isEmpty() || id.isNull()) {
        result = false;
    }
    return result;
}

bool unTpd::setClientRedirect(QString redirect)
{
    bool result = true;
    oauthRedirect = redirect;
    if (redirect.isEmpty() || redirect.isNull()) {
        result = false;
    }
    return result;
}

bool unTpd::setClientSecret(QString secret)
{
    bool result = true;
    oauthSecret = secret;
    if (secret.isEmpty() || secret.isNull()) {
        result = false;
    }
    return result;
}

int unTpd::setQueryParameter(QString id, QString value, QString key)
{
    int i, N;
    keyValuePair keyValue;
    if (id.isNull() || id.isEmpty() || value.isNull()) {
        return -1;
    }
    if (key.isNull() || key.isEmpty()) {
        key = id;
    }
    i = 0;
    N = storedParameters.length();
    keyValue.id = id;
    keyValue.key = key;
    keyValue.value = value;
    while (i < N) {
        if (storedParameters.at(i).id == id) {
            storedParameters.replace(i, keyValue);
            i = N + 2;
        }
        i++;
    }
    if (i == N) {
        storedParameters.append(keyValue);
    }

    return storedParameters.length();
}

/*
bool unTpd::setAuthorityToken(QString key, QString token)
{
    bool result = true;
    if(!key.isNull()) {
        authTokenKey = key;
    } else {
        result = false;
    }
    if (!token.isNull()) {
        authToken = token;
    } else {
        result = false;
    }

    return result;
}

bool unTpd::setQueryAuthority(QString idKey, QString id, QString secretKey, QString secret)
{
    bool tulos = true;
    if (!id.isNull() && !idKey.isNull()) {
        appIdKey = idKey;
        appId = id;
    } else {
        tulos = false;
    }
    if (!secret.isNull() && !secretKey.isNull()) {
        appSecret = secret;
        appSecretKey = secretKey;
    } else {
        tulos = false;
    }

    return tulos;
}

bool unTpd::setUserAuthority(QString user, QString passwd)
{
    bool result = true;
    if (!user.isNull()) {
        userName = user;
    } else {
        result = false;
    }
    if (!passwd.isNull()) {
        userPassword = passwd;
    } else {
        result = false;
    }
    return result;
}
//*/

bool unTpd::setServer(QString protocol, QString address, int port)
{
    bool result = true;
    if (!protocol.isNull()) {
        scheme = protocol;
    } else {
        result = false;
    }
    if (!address.isNull()) {        
        server = address;
    } else {
        result = false;
    }
    //if (!path.isNull()) {
    //    pathCommon = path;
    //} else {
    //    result = false;
    //}
    serverPort = port;

    return result;
}

bool unTpd::setUserInfo(QString user, QString passwd) {
    userName = user;
    userPassword = passwd;
    return true;
}

void unTpd::setUserInfoReguired(bool required)
{
    isUserInfoRequired = required;
    return;
}

bool unTpd::singleGet(QString path, QString definedQuery, QString parametersToAdd)
{
    return sendRequest("", path, parametersToAdd, definedQuery, true);
}

bool unTpd::singlePost(QString path, QString definedQuery, QString parametersToAdd)
{
    return sendRequest("", path, parametersToAdd, definedQuery, false);
}
