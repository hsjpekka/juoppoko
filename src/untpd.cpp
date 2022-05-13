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
    }

    return;
}

bool unTpd::queryGet(QString path, QString parameters)
{
    return sendRequest(path, parameters, true);
}

bool unTpd::queryPost(QString path, QString parameters)
{
    return sendRequest(path, parameters, false);
}

bool unTpd::sendRequest(QString path, QString parameters, bool isGet)
{
    QUrl url;
    QUrlQuery query;
    QNetworkRequest request;

    url.setScheme(scheme);
    url.setHost(server);
    url.setPath(pathCommon + path);
    query = QUrlQuery(parameters);
    //query.addQueryItem("access_token", userToken);
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

bool unTpd::setAppAuthority(QString id, QString secret)
{
    bool tulos = false;
    if (!id.isNull()) {
        appId = id;
        tulos = true;
    }
    if (!secret.isNull()) {
        appSecret = secret;
        tulos = true;
    }
    return tulos;
}
