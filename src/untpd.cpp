#include "untpd.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
//#include <QDebug>
#include <QUrlQuery>
//#include <QByteArray>

unTpd::unTpd(QObject *parent) : QObject(parent)
{
    scheme = "https";
    server = "api.untappd.com";
    pathCommon = "/v4";
    //keyError = "status";
}

int unTpd::addToQuery(QUrlQuery &query, QString keyList)
{
    QStringList keys;
    //QString result;
    int i, iN, j, jN, result;
    bool search;
    keys = keyList.split(",",QString::SkipEmptyParts);
    result = 0;
    i = 0;
    iN = keys.length();
    jN = storedParameters.length();
    while (i < iN) {
        j = 0;
        search = true;
        while (j < jN && search) {
            if (storedParameters.at(j).key == keys.at(i)) {
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

    qInfo() << query.toString();

    return result;
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

void unTpd::getQueryStatus(QJsonObject reply)
{
    QJsonObject obj;
    QJsonValue val;
    QString str;
    int statusCode; // 1xx not yet, 2xx success, 3xx redirect, 4xx client error, 5xx server error

    statusCode = -1;

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
                    netQueryStatus = Success;
                } else if (statusCode >= 400 && statusCode <= 599) {
                    netQueryStatus = ServiceError;
                }
                str.append(val.toString());
            } else {
                errorList.append("No Code in JSON.Meta");
                netQueryStatus = ParseError;
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
            netQueryStatus = ParseError;
        }
    } else {
        errorList.append("No Meta in JSON-response.");
        netQueryStatus = ParseError;
    }

    if (netQueryStatus != Success && !str.isEmpty() && !str.isNull()) {
        errorList.append(str);
        qInfo() << str;
    }

    return;
}

bool unTpd::queryGet(QString path, QString definedQuery, QString parametersToAdd)
{
    return sendRequest(path, parametersToAdd, definedQuery, true);
}

bool unTpd::queryPost(QString path, QString definedQuery, QString parametersToAdd)
{
    return sendRequest(path, parametersToAdd, definedQuery, false);
}

void unTpd::replyFromServer()
{
    QJsonObject replyJson;
    QJsonValue cloudValue;

    latestReply.clear();

    replyJson = responseToJson(netReply, &latestReply);
    if (netQueryStatus != NetError && netQueryStatus != ParseError) {
        getQueryStatus(replyJson);
    }

    emit finishedQuery();

    return;
}

QJsonObject unTpd::responseToJson(QNetworkReply *reply, QString *jsonStorage)
{
    QByteArray data;
    QJsonParseError parseError;
    QJsonDocument document;
    QJsonObject result;
    QString str("");

    if (reply->error() == QNetworkReply::NoError) {
        data = reply->readAll();
        jsonStorage->append(data);
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
            netQueryStatus = ParseError;
            str.append("parse error: ");
            str.append(parseError.errorString() + " ::: ");
            str.append(data);
            errorList.append(str);
            qInfo() << str;
        }
    } else {
        netQueryStatus = NetError;
        jsonStorage->append(reply->errorString());
        str.append("network error: ");
        str.append(reply->errorString() + " ::: ");
        errorList.append(str);
        qInfo() << reply->errorString();
    }
    reply->deleteLater();

    return result;
}

bool unTpd::sendRequest(QString path, QString parametersToAdd, QString definedQuery, bool isGet)
{
    QUrl url;
    QUrlQuery query;
    QNetworkRequest request;

    url.setScheme(scheme);
    url.setHost(server);
    url.setPath(pathCommon + path);
    if (isUserInfoRequired) {
        url.setUserName(userName);
        if (!userPassword.isNull()) {
            url.setPassword(userPassword);
        }
    }

    query = QUrlQuery(definedQuery);
    addToQuery(query, parametersToAdd);
    url.setQuery(query);

    request.setUrl(url);

    netQueryStatus = Pending;
    if (isGet) {
        netReply = netManager.get(request);
    } else {
        netReply = netManager.post(request, "");
    }
    connect(netReply, SIGNAL(finished()), this, SLOT(replyFromServer()));

    return true;
}

int unTpd::setQueryParameter(QString key, QString value)
{
    int i, N;
    keyValuePair keyValue;
    if (key.isNull() || key.isEmpty() || value.isNull()) {
        return -1;
    }
    i = 0;
    N = storedParameters.length();
    keyValue.key = key;
    keyValue.value = value;
    while (i < N) {
        if (storedParameters.at(i).key == key) {
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

bool unTpd::setServer(QString protocol, QString address, QString path)
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
    if (!path.isNull()) {
        pathCommon = path;
    } else {
        result = false;
    }

    return result;
}

bool unTpd::userInfoReguired(bool required)
{
    isUserInfoRequired = required;
    return isUserInfoRequired;
}
