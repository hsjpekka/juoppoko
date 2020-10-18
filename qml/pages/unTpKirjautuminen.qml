import QtQuick 2.0
import Sailfish.Silica 1.0
import QtWebKit 3.0
import "../scripts/unTap.js" as UnTpd
import "../scripts/tietokanta.js" as Tkanta
import "../components"

Page {
    id: sivu

    signal muuttuu
    property bool muuttunut: false

    readonly property string unTappdLoginUrl: "https://untappd.com/oauth/authenticate/?client_id=" +
                                     UnTpd.unTpdId + "&response_type=code&redirect_url=" +
                                     UnTpd.callbackURL
    readonly property string accTokenAddress: "https://untappd.com/oauth/authorize/?client_id=" +
            UnTpd.unTpdId + "&client_secret=" + UnTpd.unTpdSecret +
            "&response_type=code&redirect_url=" + UnTpd.callbackURL + "&code="

    function vaihdaTunnus(tunnus) {
        muuttunut = true
        UnTpd.unTpToken = tunnus
        Tkanta.paivitaAsetus2(Tkanta.tunnusUnTappdToken, tunnus)
        return
    }

    function lueToken() {
        var i = urlTunnus.text.indexOf("?code=")
        if (i < 0) {
            uTpYhteys.tunnus = urlTunnus.text
        } else {
            uTpYhteys.tunnus = urlTunnus.text.substring(i+6)
        }
        uTpYhteys.haeToken()
        return
    }

    Component {
        id: valikko
        PullDownMenu {
            MenuItem {
                text: qsTr("sign out")
                visible: (UnTpd.unTpToken != "") ? true : false
                onClicked: {
                    vaihdaTunnus("")
                    pageContainer.pop()
                }
            }
            MenuItem {
                text: qsTr("cancel")
                onClicked: {
                    muuttunut = false
                    pageContainer.pop()
                }
            }
            MenuItem {
                text: qsTr("open in external browser")
                onClicked: {
                    Qt.openUrlExternally(unTappdLoginUrl)
                    webView.visible = !webView.visible
                }
            }
            MenuItem {
                text: qsTr("use SilicaWebView")
                visible: !webView.visible
                onClicked: {
                    webView.visible = !webView.visible
                }
            }
        }
    }

    XhttpYhteys {
        id: uTpYhteys
        onValmis: {
            var jsonVastaus, accessToken
            try {
                jsonVastaus = JSON.parse(httpVastaus)
                if ("response" in jsonVastaus && "access_token" in jsonVastaus.response)
                    accessToken = jsonVastaus.response.access_token
                else if ("meta" in jsonVastaus && "error_detail" in jsonVastaus.meta)
                    nayta(jsonVastaus.meta.error_detail)
                if (jsonVastaus.meta.http_code != 200)
                    console.log("unTappd-response: " + httpVastaus)
                if (accessToken) {
                    vaihdaTunnus(accessToken)
                    pageContainer.pop()
                }
            } catch (err) {
                console.log("error while fetching unTappd access token: " + err)
            }
        }

        property string tunnus

        function haeToken() {
            var kysely = accTokenAddress + tunnus
            xHttpGet(kysely)
            return
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        pullDownMenu: valikko
        visible: !webView.visible

        Column {
            id: column
            spacing: Theme.paddingMedium

            Label {
                color: Theme.highlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin

                text: qsTr("To allow this app to use your unTappd-profile, use either " +
                           "an external browser (pull down menu) and follow the instructions " +
                           "below, or use the webview.")
            }

            Label {
                id: ohje
                color: Theme.highlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin

                text: qsTr("After logging in, the browser will redirect you to a non-existing " +
                           "url %1. Copy the url, or just the CODE, to the text field below, " +
                           "and press enter.").arg(cbu)
                property string cbu: ".../juoppoko.untpd.tunnistus?code=CODE"
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
                    lueToken()
                    focus = false
                }

                label: qsTr("CODE or url containing CODE")
                placeholderText: ohje.cbu

            }

            Label {
                id: lisaOhje
                color: Theme.highlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin

                text: qsTr("If you have problems with the default browser, paste the login url " +
                           "below to the address field of another browser.")
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
        }
    }

    SilicaWebView {
        id: webView
        anchors.fill: parent
        url: visible? unTappdLoginUrl : ""
        visible: false

        property real suurennos: (Screen.width < 550) ? 1.5 : ((Screen.width < 825) ? 2 : 3)

        experimental.customLayoutWidth: Screen.width / suurennos // tekee unTappdin kirjautumisruudun sopivan kokoiseksi

        onLoadingChanged: {
            var vertailu = new RegExp(UnTpd.callbackURL.replace(/\//g, '\\/') + "\\?code=(.*)")
            //var xhttp = new XMLHttpRequest()
            var replyUrl = ""//, code = ""

            if (vertailu.test(loadRequest.url.toString())) {
                replyUrl = loadRequest.url.toString()
                /*
                code = replyUrl.slice(replyUrl.indexOf("?code=")+6)
                accTokenAddress += code
                xhttp.onreadystatechange = function() {
                    if (xhttp.readyState === 4 && xhttp.status === 200 ){
                        var reply = JSON.parse(xhttp.responseText)
                        experimental.deleteAllCookies()
                        vaihdaTunnus(reply.response.access_token)
                        pageContainer.pop()
                    }
                }
                xhttp.open("GET", accTokenAddress, true)
                xhttp.send()
                // */
                uTpYhteys.tunnus = replyUrl.slice(replyUrl.indexOf("?code=")+6)
                uTpYhteys.haeToken()
            }
        }
    }

    Component.onDestruction:
        if (muuttunut)
            muuttuu()
}
