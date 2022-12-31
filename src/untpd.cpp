#include "untpd.h"
#include <QDesktopServices>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QUrlQuery>
#include <oauth2.h>
#include <redirectlistener.h>

using namespace Amber::Web::Authorization;

unTpd::unTpd(QObject *parent) : QObject(parent)
{
    scheme = "https";
    server = "api.untappd.com";
    serverPort = -1;
}

int unTpd::addToQuery(QUrlQuery &query, QString keyList)
{
    QStringList keys;
    int i, iN, j, jN, result;
    //bool search;
    keyList.replace(" ", "");
    keys = keyList.split(",",QString::SkipEmptyParts);
    result = 0;
    i = 0;
    iN = keys.length();
    jN = storedParameters.length();
    while (i < iN) {
        j = parameterIndex(keys.at(i));
        if (j < jN) {
            query.addQueryItem(storedParameters.at(j).key, storedParameters.at(j).value);
            result++;
        }
        i++;
    }

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
    url.setPath(path);

    query = QUrlQuery(definedQuery);
    addToQuery(query, paramsToAdd);
    url.setQuery(query);

    return;
}

void unTpd::authenticate()
{
    QObject::connect(&listener, &RedirectListener::failed, this, [this]() {
        QString error = "Error: Listener failed to listen!";
        qWarning() << error;
        emit finishedAuthentication("", error);
    } );

    QObject::connect(&listener, &RedirectListener::uriChanged,
                     this, [this]() {
        QUrl loginUrl(oauthPath);

        QString qry("client_id=");
        qry += oauthId;
        qry += "&response_type=code&redirect_url=";
        qry += oauthRedirect;

        loginUrl.setQuery(qry);

        QDesktopServices::openUrl(loginUrl.toString());
    });

    QObject::connect(&listener, &RedirectListener::receivedRedirect,
                     this, [this](const QString &redirectUri) {
        QString error, code;
        QUrl tokenUrl(tokenPath);
        QUrlQuery query;

        code = uriKey(redirectUri, "code");
        if (!code.isEmpty()) {
            qDebug() << "Received auth code, about to request access token";
            // client_id=CLIENTID&client_secret=CLIENTSECRET&response_type=code&redirect_url=REDIRECT_URL&code=CODE
            query.clear();
            query.addQueryItem("client_id", oauthId);
            query.addQueryItem("client_secret", oauthSecret);
            query.addQueryItem("response_type", "code");
            query.addQueryItem("redirect_url", oauthRedirect);
            query.addQueryItem("code", code);
            tokenUrl.setQuery(query);
            sendRequest(oauthTokenRequest, tokenUrl, true);
        } else {
            error.append("Unable to parse authorization code from redirect: ");
            error.append(redirectUri);
            qWarning() << error;
            emit finishedAuthentication("", error);
        }
        listener.stopListening();
    });

    listener.startListening(); //generates uriChanged-signal

    return;
}

void unTpd::authenticate(QString pathAuthorization, QString redirect,
                         QString pathToken)
{
    setOAuthPath(pathAuthorization);
    setOAuthRedirect(redirect);
    setOAuthTokenPath(pathToken);
    return authenticate();
}

void unTpd::authenticateAmber()
{
    oauth2.setFlowType(Amber::Web::Authorization::OAuth2::AuthorizationCodeFlow);
    oauth2.setAuthorizationEndpoint(oauthPath); // "https://untappd.com/oauth/authenticate/", "https://accounts.google.com/o/oauth2/auth"
    oauth2.setClientId(oauthId);
    oauth2.setClientSecret(oauthSecret);  // enter your app's clientSecret here
    oauth2.setScope(""); // "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"
    oauth2.setState(oauth2.generateState());
    oauth2.setCodeVerifier(oauth2.generateCodeVerifier());
    oauth2.setRedirectUri(oauthRedirect);
    oauth2.setTokenEndpoint(tokenPath); // "https://untappd.com/oauth/authorize/", "https://accounts.google.com/o/oauth2/token"

    QObject::connect(&listener, &RedirectListener::failed, this, [this]() {
        QString error = "[Amber] Error: Listener failed to listen!";
        qWarning() << error;
        emit finishedAuthentication("", error);
    } );

    QObject::connect(&oauth2, &OAuth2::errorChanged, this, [this]() {
        QString error;
        error.append("Error! ");
        error.append(oauth2.error().code());
        error.append(": ");
        error.append(oauth2.error().message());
        qWarning() << error;
        emit finishedAuthentication("", error);
    });

    QObject::connect(&listener, &RedirectListener::uriChanged,
                     this, [this]() {
        qDebug() << "[Amber] Listening for redirects on uri:" << listener.uri();
        oauth2.setRedirectUri(listener.uri());
        qDebug() << "opening url:" << oauth2.generateAuthorizationUrl().toString();
        QDesktopServices::openUrl(oauth2.generateAuthorizationUrl());
    });

    QObject::connect(&listener, &RedirectListener::receivedRedirect,
                     this, [this](const QString &redirectUri) {
        const QVariantMap data = oauth2.parseRedirectUri(redirectUri);
        QString error;
        if (!data.value("code").toString().isEmpty()) {
            qDebug() << "[Amber] Received auth code, about to request access token";
            oauth2.setCustomParameters(QVariantMap());
            oauth2.requestAccessToken(data.value("code").toString(),
                                      data.value("state").toString());
        } else {
            error.append("[Amber] Unable to parse authorization code from redirect: ");
            error.append(redirectUri);
            qWarning() << error;
            emit finishedAuthentication("", error);
        }
    });

    QObject::connect(&oauth2, &OAuth2::receivedAccessToken,
                     this, [this](const QVariantMap &token) {
        qDebug() << "Received access token: " << token.value("access_token").toString();
        listener.stopListening();
        setOAuthToken(token.value("access_token").toString());
        emit finishedAuthentication(readOAuth2Token(), "");
    });

    listener.startListening();

    return;
}

void unTpd::authenticateAmber(QString pathAuthorization, QString redirect, QString pathToken)
{
    setOAuthPath(pathAuthorization);
    setOAuthRedirect(redirect);
    setOAuthTokenPath(pathToken);
    return authenticateAmber();
}

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
    QString str("");
    QueryStatus result;
    int statusCode; // 1xx not yet, 2xx success, 3xx redirect, 4xx client error, 5xx server error

    statusCode = -1;
    result = ParseError;

    if (reply.contains("meta")) {
        val = reply.value("meta");
        if (val.isObject()) {
            obj = val.toObject();
            if (obj.contains("code")) {
                val = obj.value("code");
                if (val.isDouble()) {
                    statusCode = val.toInt();
                }
                if (statusCode >= 200 && statusCode <= 299) {
                    result = Success;
                } else if (statusCode >= 400 && statusCode <= 599) {
                    result = ServiceError;
                }
            } else {
                str.append("No Code in JSON.Meta.");
                errorList.append("No Code in JSON.Meta.");
                result = ParseError;
            }
            if (obj.contains("error_type")) {
                val = obj.value("error_type");
                str.append(", error_detail: ");
                str.append(val.toString());
            }
            if (obj.contains("error_detail")) {
                val = obj.value("error_detail");
                str.append(", error_detail: ");
                str.append(val.toString());
            }
            if (obj.contains("developer_friendly")) {
                val = obj.value("developer_friendly");
                str.append(", developer_friendly: ");
                str.append(val.toString());
            }
        } else {
            str.append("No Meta in JSON-response.");
            errorList.append("No Meta in JSON-response.");
            result = ParseError;
        }
    } else {
        str.append("No Meta in JSON-response.");
        errorList.append("No Meta in JSON-response.");
        result = ParseError;
    }

    if (result != Success) {
        errorList.append(str);
        qDebug() << "getQueryStatus:" << errorStatusToString(result) << str;
    }

    return result;
}

bool unTpd::isNetworkAvailable()
{
    return (netManager.networkAccessible() == QNetworkAccessManager::Accessible);
}

QString unTpd::keyAppId()
{
    return appIdKey;
}

QString unTpd::keyAppSecret()
{
    return appSecretKey;
}

QString unTpd::keyTokenRequest()
{
    return oauthTokenRequest;
}

QString unTpd::keyToken()
{
    return tokenKey;
}

bool unTpd::queryGet(QString queryId, QString url) {
    QUrl u(url);
    return sendRequest(queryId, u, true);
}

bool unTpd::queryGet(QString queryId, QString path, QString definedQuery, QString parametersToAdd)
{
    return sendRequest(queryId, path, parametersToAdd, definedQuery, true);
}

bool unTpd::queryHeaderedGet(QString queryId, QString path, QString query, QString headers, QString parametersToAdd)
{
    return sendRequest(queryId, path, parametersToAdd, query, true, headers);
}

bool unTpd::queryHeaderedPost(QString queryId, QString path, QString query, QString headers, QString posting, QString parametersToAdd)
{
    return sendRequest(queryId, path, parametersToAdd, query, false, headers, posting);
}

/*
bool unTpd::queryPost(QString queryId, QString url) {
    QUrl u(url);
    return sendRequest(queryId, u, false);
}
//*/

bool unTpd::queryPost(QString queryId, QString path, QString query, QString posting, QString parametersToAdd)
{
    return sendRequest(queryId, path, parametersToAdd, query, false, "", posting);
}

int unTpd::parameterIndex(QString id)
{
    int i=0, result = storedParameters.length();
    while (i < storedParameters.length()) {
        if (storedParameters.at(i).id == id) {
            result = i;
            i = storedParameters.length();
        }
        i++;
    }
    return result;
}

QString unTpd::readOAuth2Token() {
    return oauthToken;
}

void unTpd::replyFromServer(QNetworkReply *reply)
{
    QJsonValue cloudValue;
    sentRequest currentRequest;
    int iReply;
    QJsonObject replyJson;
    QueryStatus status;
    QString replyString;

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

    status = getQueryStatus(replyJson);
    if (currentRequest.queryId == oauthTokenRequest) {
        if (replyJson.contains("response")) {
            if (replyJson.value("response").toObject().contains("access_token")) {
                setOAuthToken(replyJson.value("response").toObject().value("access_token").toString());
                qDebug() << "Received access token: " << readOAuth2Token();
            }
        }
        emit finishedAuthentication(readOAuth2Token(), "");
    } else {
        emit finishedQuery(currentRequest.queryId, errorStatusToString(status), replyString);
    }

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
                qDebug() << result.value("status") << ":";
                if (result.contains("title"))
                    qDebug() << result.value("title");
                if (result.contains("detail"))
                    qDebug() << "\n" << result.value("detail") << "\n";
            }
        } else {
            //netQueryStatus = ParseError;
            str.append("parse error: ");
            str.append(parseError.errorString() + " ::: ");
            str.append(data);
            errorList.append(str);
            qDebug() << str;
        }
    } else {
        //netQueryStatus = NetError;
        //replyString->append("");//append(reply->errorString())
        str.append("network error: ");
        str.append(reply->errorString() + " ::: ");
        errorList.append(str);
        qDebug() << reply->error() << ":" << reply->errorString();
    }

    return result;
}

bool unTpd::sendRequest(QString queryId, QString path, QString parametersToAdd, QString definedQuery, bool isGet, QString headers, QString posting)
{
    QUrl url;
    assembleUrl(url, path, definedQuery, parametersToAdd);
    return sendRequest(queryId, url, isGet, headers, posting);
}

bool unTpd::sendRequest(QString queryId, QUrl url, bool isGet, QString headers, QString posting)
{
    QNetworkRequest request;
    QNetworkReply *netReply;
    sentRequest currentRequest;
    QStringList hdrs, value;
    int i, j;

    if (!headers.isEmpty()) {
        hdrs = headers.split(";");
        i = 0;
        while (i < hdrs.length()) {
            value = hdrs.at(i).split(":");
            if (value.length() > 1) {
                request.setRawHeader(value.at(0).toLatin1(), value.at(1).toLatin1());
            } else {
                j = parameterIndex(value.at(0));
                if (j < storedParameters.length()) {
                    request.setRawHeader(storedParameters.at(j).key.toLatin1(),
                                         storedParameters.at(j).value.toLatin1());
                } else {
                    request.setRawHeader(value.at(0).toLatin1(), "");
                }
            }
            i++;
        }
    }
    request.setUrl(url);

    //netQueryStatus = Pending;
    if (isGet) {
        netReply = netManager.get(request);
    } else {
        netReply = netManager.post(request, posting.toLatin1());
    }

    currentRequest.queryId = queryId;
    currentRequest.originalUrl = url;
    currentRequest.reply = netReply;
    currentRequest.emitted = false;
    requestHistory.append(currentRequest);
    connect(&netManager, SIGNAL(finished(QNetworkReply *)), this, SLOT(replyFromServer(QNetworkReply *)));

    return true;
}

bool unTpd::setOAuthId(QString id)
{
    bool result;
    oauthId = id;
    if (id.isEmpty()) {
        result = false;
    } else {
        setQueryParameter(appIdKey, id, appIdKey);
        result = true;
    }
    return result;
}

bool unTpd::setOAuthPath(QString path)
{
    oauthPath = path;
    return !oauthPath.isEmpty();
}

bool unTpd::setOAuthRedirect(QString redirect)
{
    bool result = true;
    oauthRedirect = redirect;
    if (redirect.isEmpty() || redirect.isNull()) {
        result = false;
    }
    return result;
}

bool unTpd::setOAuthSecret(QString secret)
{
    bool result = true;
    oauthSecret = secret;
    if (secret.isEmpty()) {
        result = false;
    } else {
        setQueryParameter(appSecretKey, secret, appSecretKey);
        result = true;
    }
    return result;
}

bool unTpd::setOAuthToken(QString token)
{
    bool result;
    oauthToken = token;
    if (token.isEmpty()) {
        result = false;
    } else {
        setQueryParameter(tokenKey, token, tokenKey);
        result = true;
    }
    return result;
}

bool unTpd::setOAuthTokenPath(QString path)
{
    tokenPath = path;
    return !tokenPath.isEmpty();
}

int unTpd::setQueryParameter(QString id, QString value, QString key)
{
    int i, N;
    keyValuePair keyValue;
    if (id.isEmpty()) {
        return -1;
    }
    if (key.isEmpty()) {
        key = id;
    }
    if (value.isNull()) {
        value = "";
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

bool unTpd::singlePost(QString path, QString posting, QString definedQuery, QString parametersToAdd)
{
    return sendRequest("", path, parametersToAdd, definedQuery, false, "", posting);
}

QString unTpd::uriKey(QString uriStr, QString key, int n)
{
    int i, j, k, lk, lv, m;
    QUrl url(uriStr);
    QString query = url.query(), result;

    if (n > 1) {
        m = n;
    } else {
        m = 1;
    }
    i = 0;
    lv = query.length(); //"code=a#": 7
    lk = key.length(); //"code": 4
    while (i >= 0 && m > 0) {
        if (m < n) {
            result.append("&"); //use & as the value list separator
        }
        i = query.indexOf(key + "=", i); //"code=a#": 0
        if (i >= 0) {
            j = query.indexOf("&",i); //"code=a#": -1
            if (j >= 0) {
                lv = j;
            }
            k = query.indexOf("#",i); //"code=a#": 6
            if (k >= 0 && k < lv) {
                    lv = k;
            }
            result.append(query.mid(i+lk+1, lv-(i+lk+1))); //"code=a#": (5, 1)
            m--;
            i++; // don't read twice
        }
    }
    return result;
}
