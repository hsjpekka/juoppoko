import QtQuick 2.0
import Sailfish.Silica 1.0
import QtWebKit 3.0
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    anchors.fill: parent

    property int ddum: 0
    property bool naytaSelain: false

    function unTappdLoginUrl() {
        return "https://untappd.com/oauth/authenticate/?client_id=" + UnTpd.unTpdId +
                "&response_type=code&redirect_url=" + UnTpd.callbackURL

    }

    function lueKayttajanTiedot() {
        var xhttp = new XMLHttpRequest();
        var kysely = UnTpd.getUserInfo("","true");
        var async = true, sync = false;

        xhttp.onreadystatechange = function() {
            console.log("lueKayttajanTiedot - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){
                var vastaus = JSON.parse(xhttp.responseText);

                if (xhttp.status == 200) {
                    //console.log(xhttp.responseText)
                    label1.text = vastaus.response.user.user_name
                } else if (xhttp.status == 500) {
                    label1.text = vastaus.meta.error_detail
                } else {
                    label1.text = qsTr("error: ") + xhttp.status + ", " + xhttp.statusText
                }
            }
        }
        xhttp.open("GET",kysely,async);
        xhttp.send();

        console.log("unTpKirjautuminen - lueKayttajanTiedot - xhttp.responseText")

    }

    Column {
        id: column
        anchors.fill: parent

        TextField {
            id: label1
            width: parent.width
            label: qsTr("username")
            text: UnTpd.unTpToken
            placeholderText: qsTr("unidentified")
            readOnly: true
            visible: !naytaSelain
        }

        Button {
            id: nappi
            text: (UnTpd.unTpToken == "") ? qsTr("sign in") : qsTr("change user")
            visible: !naytaSelain
            onClicked: {
                naytaSelain = true
                UnTpd.unTpToken = ""
                //console.log("reset-nappi 1 - " + webView.url)
                webView.url = unTappdLoginUrl()
                console.log("unTpKirjautuminen - nappi - " + webView.url)
            }
        }

        // /*
        SilicaWebView {
            id: webView
            width: parent.width
            height: parent.height - label1.height - nappi.height
            //url: "https://untappd.com/oauth/authenticate/?client_id=" + UnTpd.unTpdId +
            //     "&response_type=code&redirect_url=" + UnTpd.callbackURL
            url: "" // "http://www.google.fi"
            visible: naytaSelain

            onLoadingChanged: {
                var vertailu = new RegExp(UnTpd.callbackURL.replace(/\//g, '\\/') + "\\?code=(.*)");
                var accTokenAddress = "https://untappd.com/oauth/authorize/?client_id=" + UnTpd.unTpdId +
                        "&client_secret=" + UnTpd.unTpdSecret + "&response_type=code&redirect_url=" +
                        UnTpd.callbackURL + "&code="
                var xhttp = new XMLHttpRequest();
                var code = "", replyUrl = "";

                //console.log("onLoadingCanged - " + ddum + " - " + webView.url)
                //ddum = ddum + 1
                //var reg2 = new RegExp("google");
                //var code

                //console.log("DDDD - " + loadRequest.status + " - " + loadRequest.errorString)

                if (vertailu.test(loadRequest.url.toString())) {
                    replyUrl = loadRequest.url.toString();
                    code = replyUrl.slice(replyUrl.indexOf("?code=")+6);
                    accTokenAddress += code;
                    xhttp.onreadystatechange = function() {
                        if (xhttp.readyState == 4 && xhttp.status == 200 ){
                            var reply = JSON.parse(xhttp.responseText);
                            UnTpd.unTpToken = reply.response.access_token;
                            experimental.deleteAllCookies();
                            //pageStack.pop();
                            naytaSelain = false;
                            lueKayttajanTiedot();
                            webView.url = "";
                        }
                    }
                    xhttp.open("GET",accTokenAddress,true);
                    xhttp.send();

                } else {
                    console.log("unTpKirjautuminen - rivi 117")
                }
            }
        } // */

    }

    Component.onCompleted: {
        if (UnTpd.unTpToken == "" ) {
            console.log("unTpKirjautuminen - ei unTappd tunnusta")
        } else {
            lueKayttajanTiedot()
        }
    }
}
