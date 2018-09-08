import QtQuick 2.0
import Sailfish.Silica 1.0
import QtWebKit 3.0
import "../scripts/unTap.js" as UnTpd
import "../scripts/tietokanta.js" as Tkanta

Page {
    id: sivu

    function unTappdLoginUrl() {
        return "https://untappd.com/oauth/authenticate/?client_id=" + UnTpd.unTpdId +
                "&response_type=code&redirect_url=" + UnTpd.callbackURL
    }

    SilicaWebView {
        id: webView
        anchors.fill: parent
        url: unTappdLoginUrl()

        onLoadingChanged: {
            var vertailu = new RegExp(UnTpd.callbackURL.replace(/\//g, '\\/') + "\\?code=(.*)");
            var accTokenAddress = "https://untappd.com/oauth/authorize/?client_id=" + UnTpd.unTpdId +
                    "&client_secret=" + UnTpd.unTpdSecret + "&response_type=code&redirect_url=" +
                    UnTpd.callbackURL + "&code="
            var xhttp = new XMLHttpRequest();
            var code = "", replyUrl = "";

            if (vertailu.test(loadRequest.url.toString())) {
                replyUrl = loadRequest.url.toString();
                code = replyUrl.slice(replyUrl.indexOf("?code=")+6);
                accTokenAddress += code;
                xhttp.onreadystatechange = function() {
                    if (xhttp.readyState == 4 && xhttp.status == 200 ){
                        var reply = JSON.parse(xhttp.responseText);
                        UnTpd.unTpToken = reply.response.access_token;
                        experimental.deleteAllCookies();
                        Tkanta.paivitaAsetus2(Tkanta.tunnusUnTappdToken, UnTpd.unTpToken)
                        pageStack.pop();
                    }
                }
                xhttp.open("GET",accTokenAddress,true);
                xhttp.send();

            }
        }

    }

}
