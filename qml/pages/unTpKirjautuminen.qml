import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd
import "../scripts/tietokanta.js" as Tkanta
import "../components"

Page {
    id: sivu
    Component.onDestruction: {
        if (muuttunut) {
            vaihdaTunnus(uusiTunnus)
            muuttuu()
        }
    }

    signal muuttuu
    property bool muuttunut: false
    property string uusiTunnus: ""

    readonly property string unTappdLoginUrl:
        "https://untappd.com/oauth/authenticate/?client_id=" +
        UnTpd.unTpdId + "&response_type=code&redirect_url=" +
        UnTpd.callbackURL

    Connections {
        target: untpdKysely
        onFinishedAuthentication: {
            if (token > "") {
                uusiTunnus = token
                muuttunut = true
            } else {
                console.log("error in getting authentication token: " + error + " " + untpdKysely.readOAuth2Token())
            }
            pageContainer.pop()
        }
        onFinishedQuery: {
            lueToken(queryReply)
            pageContainer.pop()
        }
    }

    RemorsePopup {
        id: remorse
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("sign out")
                visible: (UnTpd.unTpToken != "") ? true : false
                onClicked: {
                    remorse.execute(qsTr("signing out"), function () {
                        uusiTunnus = ""
                        muuttunut = true
                        pageContainer.pop()
                    } )
                }
            }
            MenuItem {
                text: qsTr("authenticate")
                onClicked: {
                    untpdKysely.authenticate()
                }
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader{
                title: qsTr("Sign in unTappd")
            }

            LinkedLabel {
                color: Theme.highlightColor
                shortenUrl: true
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin

                plainText: qsTr("To use your unTappd-profile, choose " +
                                "'authenticate' in the pull down " +
                                "menu, or follow " +
                                "the instructions below.")
            }

            SectionHeader {
                text: qsTr("Problems with the browser?")
            }

            Label {
                id: lisaOhje
                color: Theme.highlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin

                text: qsTr("If you have problems with the default " +
                           "browser, paste the login url below to " +
                           "the address field of another browser.")
            }

            TextField {
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-clipboard"
                EnterKey.onClicked: {
                    Clipboard.text = text
                    focus = false
                }
                label: qsTr("unTappd login url")
                text: unTappdLoginUrl
            }

            SectionHeader {
                text: qsTr("After signing in")
            }

            Label {
                id: ohje
                color: Theme.highlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin

                text: qsTr("After signing in, the browser will " +
                           "redirect you to a non-existing address " +
                           "%1. Copy the address, or just the CODE, " +
                           "to the text field below, and press enter.").arg(cbu)
                property string cbu: UnTpd.callbackURL + "/?code=CODE"
            }

            TextField {
                id: urlTunnus
                width: parent.width
                onTextChanged: {
                    if (text.indexOf("?code=") < 0)
                        label = qsTr("plain CODE")
                    else
                        label = "xxxx?code=CODE"
                }

                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    kysyToken()
                    focus = false
                }

                label: qsTr("CODE or url containing CODE")
                placeholderText: ohje.cbu

            }

        }
    }

    function vaihdaTunnus(tunniste) {
        console.log("oauth2 tunniste vaihtuu: " + tunniste)
        UnTpd.unTpToken = tunniste;
        Tkanta.paivitaAsetus2(Tkanta.tunnusUnTappdToken, tunniste);
        return;
    }

    function kysyToken() {
        var i, polku, kysely, lisattavat;
        // https://untappd.com/oauth/authorize/?client_id=CLIENTID
        // &client_secret=CLIENTSECRET&response_type=code
        // &redirect_url=REDIRECT_URL&code=CODE
        polku = "oauth/authorize/";
        lisattavat = untpdKysely.keyAppId() + ", " + untpdKysely.keyAppSecret();
        kysely = "response_type=code&redirect_url=" + UnTpd.callbackURL;

        i = urlTunnus.text.indexOf("?code=");
        if (i < 0 && urlTunnus.text.length > 0) {
            kysely += "&code=" + urlTunnus.text;
        } else {
            kysely += "&code=" + urlTunnus.text.substring(i+6);
        }

        untpdKysely.queryGet(untpdKysely.oauthTokenRequest, polku, kysely, lisattavat);
        return;
    }

    function lueToken(mj) {
        // {
        //"meta": {
        //  "http_code": 200
        //},
        //"response": {
        //  "access_token": "TOKEHERE"
        //}
        var vJson = JSON.parse(mj), tulos;
        if (!vJson["meta"]) {
            console.log("META puuttuu")
        } else if (vJson["meta"]["http_code"] != 200) {
            console.log("http_code = " + vJson["meta"]["http_code"])
        }

        if (vJson["response"]) {
            tulos = vJson["response"]["access_token"];
            console.log("uusi ")
        } else {
            console.log("RESPONSE puuttuu")
        }

        if (tulos > "") {
            uusiTunnus = tulos;
            muuttunut = true;
        }

        return tulos;
    }
}
