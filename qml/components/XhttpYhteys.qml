import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd

Item {
    id: yhteys
    width: parent.width
    state: "piilossa"
    height: 0
    clip: true
    states: [
        State {
            name: "piilossa"
            PropertyChanges {
                target: yhteys
                height: 0
            }
        },
        State {
            name: "nakyvilla"
            PropertyChanges {
                target: yhteys
                height: kokoKorkeus
            }
        }
    ]
    transitions: [
        Transition {
            from: "piilossa"
            to: "nakyvilla"
            PropertyAnimation {
                properties: "height"
                duration: 200
            }
        },
        Transition {
            from: "nakyvilla"
            to: "piilossa"
            PropertyAnimation {
                properties: "height"
                duration: 300
            }
        }
    ]

    signal valmis(string toiminto, string yhteystila, string httpVastaus) //queryId, status, queryResponse
    signal virhe(string toiminto, string yhteystila, string httpVastaus)

    property int    hakuja: 0
    property alias  kesto: viestinNaytto.muuKesto // jos muuKesto > 0, sitä käytetään
    property int    kokoKorkeus: hetkinen.height + viestit.height + 3*Theme.paddingMedium
    property bool   naytaVainVirheet: true
    property alias  naytaViesti: viestinNaytto.running
    property bool   onnistui: true
    property alias  peita: tausta.visible
    property alias  viesti: viestit.text
    property var    xhttp: untpdKysely // yhteyksien

    readonly property int _get: 1
    readonly property int _post: 0

    Connections {
        target: xhttp
        onFinishedQuery: {
            //QString: queryId, queryStatus, queryResponse
            valmis(queryId, queryStatus, queryReply)
            hakuja--
            if (!naytaVainVirheet && hakuja <= 0) {
                piiloon()
            }

            if (queryStatus != "Success") {
                nayta(queryStatus)
            }
            if (hakuja <= 0) {
                viestinNaytto.running = true
            }
        }
    }

    Timer {
        id: viestinNaytto
        interval: kesto
        running: false
        repeat: false
        onTriggered: {
            if (naytaVainVirheet)
                piiloon()
        }

        property int kesto: muuKesto > 0 ? muuKesto : (onnistui? kestoOnnistui : kestoVirhe)
        property int kestoOnnistui: 100
        property int kestoVirhe: 4*1000 // virheviestejä näytetään kauemmin
        property int muuKesto: 0
    }

    Rectangle {
        id: tausta
        anchors.fill: parent
        color: Theme.overlayBackgroundColor
        opacity: Theme.opacityHigh
    }

    BusyIndicator {
        id: hetkinen
        size: BusyIndicatorSize.Medium
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        running: false
    }

    Label {
        id: viestit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: hetkinen.bottom
        anchors.topMargin: Theme.paddingMedium
        horizontalAlignment: Text.AlignHCenter
        color: Theme.secondaryHighlightColor
        width: parent.width - 2*Theme.horizontalPageMargin
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    }

    IconButton {
        id: keskeytys
        icon.source: "image://theme/icon-m-cancel?Theme.highlightColor"
        z:-1
        anchors.centerIn: hetkinen
        visible: false
        onClicked: {
            visible = false
            piiloon()
        }
    }

    function jsCheckIn(beer) {
        var https = new XMLHttpRequest(), sync = false;
        var osoite = "https://api.untappd.com/v4/checkin/add?";
        var kysely = "gmt_offset=2.0&timezone=EET";
        osoite += "access_token=" + untpdKysely.readOAuth2Token();
        https.open("POST", osoite, sync);
        https.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
        https.send(kysely);
        return;
    }

    function nakyville() {
        yhteys.state = "nakyvilla";
        hetkinen.running = true;
        return
    }

    function nayta(ilmo) {
        viestit.text = ilmo
        onnistui = false
        viestinNaytto.restart()
        return
    }

    function piiloon() {
        yhteys.state = "piilossa";
        hetkinen.running = false;
        return
    }

    function tarkistaVerkko() {
        var tulos = xhttp.isNetworkAvailable();//"connected"
        if (tulos !== true) {
            console.log(qsTr("not connected"));
        }
        return tulos;
    }

    function xHttpGet(polku, kysely, yhteysId, lisattavat) {
        xHttpYhteys(yhteysId, _get, polku, kysely, lisattavat);
        return;
    }

    function xHttpGetOtsikoilla(polku, kysely, otsikkoon, yhteysId, lisattavat) {
        return xHttpYhteysOtsikoilla(yhteysId, _get, polku, kysely, otsikkoon, lisattavat);
    }

    function xHttpPost(polku, julkaisu, kysely, yhteysId, lisattavat) {
        if (lisattavat === undefined) {
            lisattavat = "";
        }
        xHttpYhteysOtsikoilla(yhteysId, _post, polku, kysely, "Content-type:application/x-www-form-urlencoded", julkaisu, lisattavat);
        return;
    }

    function xHttpPostOtsikoilla(polku, julkaisu, otsikkoon, kysely, yhteysId, lisattavat) {
        if (lisattavat === undefined) {
            lisattavat = "";
        }

        return xHttpYhteysOtsikoilla(yhteysId, _post, polku, kysely, otsikkoon, julkaisu, lisattavat);
    }

    function xHttpYhteys(yhteysId, haku, polku, kysely, julkaisu, lisattavat) {
        if (yhteysId === undefined) {
            yhteysId = "";
        }
        if (!naytaVainVirheet)
            yhteys.nakyville(); //yhteys.state = "nakyvilla";

        if (lisattavat === undefined) {
            lisattavat = "";
        }
        if (UnTpd.unTpToken > "") {
            lisattavat += untpdKysely.keyToken();
        } else {
            lisattavat += untpdKysely.keyAppId() + ", "
                    + untpdKysely.keyAppSecret();
        }

        if (haku === _get) {
            xhttp.queryGet(yhteysId, polku, kysely, lisattavat);
            hakuja++;
        } else if (haku === _post) {
            xhttp.queryPost(yhteysId, polku, kysely, julkaisu, lisattavat);
            hakuja++;
        }

        return;
    }

    function xHttpYhteysOtsikoilla(yhteysId, getVaiPost, polku, kysely, otsikot, julkaisu, lisattavat) {
        if (yhteysId === undefined) {
            yhteysId = "";
        }
        if (!naytaVainVirheet)
            yhteys.nakyville();

        if (julkaisu === undefined) {
            julkaisu = "";
        }
        if (lisattavat === undefined) {
            lisattavat = "";
        }
        if (UnTpd.unTpToken > "") {
            lisattavat += untpdKysely.keyToken();
        } else {
            lisattavat += untpdKysely.keyAppId() + ", "
                    + untpdKysely.keyAppSecret();
        }

        if (getVaiPost === _get) {
            xhttp.queryHeaderedGet(yhteysId, polku, kysely, otsikot, lisattavat);
            hakuja++;
        } else if (getVaiPost === _post) {
            xhttp.queryHeaderedPost(yhteysId, polku, kysely, otsikot, julkaisu, lisattavat);
            hakuja++;
        }

        return;
    }

}
