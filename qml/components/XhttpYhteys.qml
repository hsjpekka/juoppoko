import QtQuick 2.0
import Sailfish.Silica 1.0
//import org.freedesktop.contextkit 1.0
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
                //height: contentHeight
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

    //property string httpVastaus: ""
    //property bool   keskeyta: false
    property int    hakuja: 0
    property alias  kesto: viestinNaytto.muuKesto // jos muuKesto > 0, sitä käytetään
    property int    kokoKorkeus: hetkinen.height + viestit.height + 3*Theme.paddingMedium
    property bool   naytaVainVirheet: true
    property alias  naytaViesti: viestinNaytto.running
    property bool   onnistui: true
    property alias  peita: tausta.visible
    //property bool   unohdaVanhat: false // reagoiko vain viimeisimpään kyselyyn
    property alias  viesti: viestit.text
    //property int    viimeisinYhteys: 0 // jos useampi haku samaan aikaan käynnissä
    //property string yhteysTila: ""
    property var    xhttp: untpdKysely

    readonly property int _get: 1
    readonly property int _post: 0

    Connections {
        target: xhttp
        onFinishedQuery: { //QString: queryId, queryStatus, queryResponse
            valmis(queryId, queryStatus, queryReply)
            hakuja--
            if (!naytaVainVirheet && hakuja <= 0) {
                piiloon()
            }
            console.log("haku valmis, queryStatus " + queryStatus)
            if (queryStatus != "Success") {
                nayta(queryStatus)
            }
            if (hakuja <= 0) {
                viestinNaytto.running = true
            }
        }
    }

    //ContextProperty {
    //    id: verkko
        // /run/state/namespaces/
        //key: "Internet.NetworkState"
    //}

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

    /*
    Timer {
        id: naytaKeskeytys
        interval: 4*1000
        running: false
        repeat: false
        onTriggered: {
            viestit.text = qsTr("press 'x' to interrupt")
            keskeytys.visible = true
        }
    }// */

    /*
    ListModel {
        id: yhteydet
        function lisaa(toiminto, get, kysely, osoite, yhteysNro, unohda) {
            if (unohda && yhteydet.count > 0)
                yhteydet.set(0, {"gVaiP": get, "kysely": kysely, "pOsoite": osoite,
                        "yhteysNro": yhteysNro, "toiminto": toiminto })
            else
                yhteydet.insert(0, {"gVaiP": get, "kysely": kysely, "pOsoite": osoite,
                       "yhteysNro": yhteysNro, "toiminto": toiminto })
            return
        }
    }

    Timer {
        id: yhteydenOtto
        interval: 100
        repeat: true
        running: false
        onTriggered: {
            kutsu += 1
            tila = tarkistaVerkko()
            if (tila === "connected" ) {
                running = false
                kutsu = yhteydet.count -1
                while (yhteydet.count > 0) {
                    xHttpYhteys(yhteydet.get(kutsu).toiminto, yhteydet.get(kutsu).gVaiP,
                                yhteydet.get(kutsu).kysely, yhteydet.get(kutsu).pOsoite,
                                yhteydet.get(kutsu).yhteysNro)
                    yhteydet.remove(kutsu)
                    kutsu--
                }
                kutsu = 0
            } else if (kutsu > 9) {
                running = false
                kutsu = 0
                viestit.text = qsTr("error: ") + tila
                nakyville()
                console.log(viestit.text)
                kunVirhe(qsTr("no net"), viestit.text, -1)
            }
        }

        property int    kutsu: 0
        property string tila: ""
    }
    // */

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
            //yhteys.keskeyta = true
            visible = false
            piiloon()
            //console.log("keskeyta = " + yhteys.keskeyta)
        }
    }

    /*
    function kunValmis(toiminto, vst, yhteysTunnus) {
        if (vst.length > 20)
            console.log("vastaus " + ", " + viimeisinYhteys + ", " + unohdaVanhat + ", " +
                        yhteysTunnus + ", " + vst.substring(0,20))
        else
            console.log("vastaus " + ", " + viimeisinYhteys + ", " + unohdaVanhat + ", " +
                        yhteysTunnus + ", " + vst)

        if (yhteysTunnus === viimeisinYhteys || !unohdaVanhat) {
            onnistui = true;
            yhteysTila = "";
            viestinNaytto.restart();
            httpVastaus = vst;
            naytaKeskeytys.stop();
            valmis(toiminto);
        }
        return
    }

    function kunVirhe(toiminto, tila, vst, yhteysTunnus) {
        if (!unohdaVanhat || yhteysTunnus === viimeisinYhteys) {
            onnistui = false;
            //yhteysTila = tila;
            //httpVastaus = vst;
            viestinNaytto.restart();
            naytaKeskeytys.stop();
            virhe(toiminto);
        }
        return
    }// */

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
        // <<<<<<< >>>>>>>>>
        var tulos = xhttp.isNetworkAvailable();//"connected"
        // <<<<<<< >>>>>>>>>
        //console.log("tarkistetaan")
        if (tulos !== true) {
            console.log(qsTr("not connected"));
        }
        //console.log("tarkistettu")
        return tulos;
    }

    function xHttpGet(polku, kysely, tunniste, lisattavat) {
        xHttpYhteys(tunniste, _get, polku, kysely, lisattavat);
        return;
    }

    function xHttpPost(polku, kysely, tunniste, lisattavat) {
        xHttpYhteys(tunniste, _post, polku, kysely, lisattavat);
        return;
    }

    /*
    function xHttpYhteysVanha(toiminto, haku, kysely, postOsoite, kutsu) {
        //var xhttp = new XMLHttpRequest();
        var async = true, sync = false;
        var yhteysNro // funktion kutsuhetkellä        

        if (!naytaVainVirheet)
            yhteys.nakyville(); //yhteys.state = "nakyvilla";
        if (unohdaVanhat && kutsu === undefined)
            viimeisinYhteys++;
        yhteysNro = viimeisinYhteys;

        if (tarkistaVerkko() !== "connected") {
            yhteydet.lisaa(toiminto, haku, kysely, postOsoite, yhteysNro, unohdaVanhat);
            console.log("lisätty listaan " + kysely + " " + yhteysNro);
            if (!yhteydenOtto.running)
                yhteydenOtto.start();
            return;
        }

        xhttp.onreadystatechange = function () {
            var vst=toiminto, tilaNro="", tila="";
            naytaKeskeytys.restart();
            if (!naytaVainVirheet)
                yhteys.nakyville(); //yhteys.state = "nakyvilla";
            if (yhteys.keskeyta) {
                xhttp.abort();
                yhteys.piiloon();
                console.log("query aborted by user")
            }
            if ("readyState" in xhttp)
                tilaNro = "" + xhttp.readyState
            if ("status" in xhttp)
                tila = "" + xhttp.status
            //console.log(vst + " - " + tilaNro + " - " + tila);
            if (xhttp.readyState === 0)
                viestit.text = qsTr("request not initialized")
            else if (xhttp.readyState === 1)
                viestit.text = qsTr("server connection established")
            else if (xhttp.readyState === 2)
                viestit.text = qsTr("request received")
            else if (xhttp.readyState === 3)
                viestit.text = qsTr("processing request")
            else if (xhttp.readyState === 4){
                //console.log(xhttp.responseText)
                viestit.text = qsTr("request finished");
                vst = xhttp.responseText;

                //if (vst.length > 20)
                //    console.log("vastaus " + vst.substring(0,20))
                //else
                //    console.log("vastaus " + vst)
                //

                if (xhttp.status === 200 ) {
                    kunValmis(toiminto, vst, yhteysNro);
                } else {
                    yhteys.nakyville();
                    try {
                        var vastausJson = JSON.parse(xhttp.responseText);
                        if ("developer_friendly" in vastausJson.meta &&
                                vastausJson.meta.developer_friendly > "") {
                            viestit.text = vastausJson.meta.developer_friendly;
                        } else if ("error_detail" in vastausJson.meta &&
                                   vastausJson.meta.error_detail > "") {
                            viestit.text = vastausJson.meta.error_detail;
                        } else {
                            viestit.text = "error: " + xhttp.responseText;
                        }
                        onnistui = false;
                        console.log(viestit.text);
                    } catch (err) {
                        viestit.text = "error: " + xhttp.status + ", " + xhttp.responseText;
                        onnistui = false;
                        console.log(err);
                        vst = err;
                    }
                    kunVirhe(toiminto, xhttp.statusText, vst, yhteysNro);
                }
            } else {
                yhteys.nakyville();
                viestit.text = "error: " + xhttp.readyState + ", " + xhttp.statusText;
                console.log(viestit.text);
                onnistui = false;
                kunVirhe(toiminto, xhttp.statusText, viestit.text, yhteysNro);
            }
        }

        naytaKeskeytys.restart();

        if (haku === _get) {
            //viestit.text = qsTr("posting GET-query");
            xhttp.open("GET", kysely, async);
            xhttp.send();
        } else if (haku === _post) {
            //viestit.text = qsTr("posting POST-query");
            xhttp.open("POST", postOsoite, sync);
            xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            xhttp.send(kysely);
        }

        //console.log(">>> " + kysely)

        return
    }
    // */
    function xHttpYhteys(tunniste, haku, polku, kysely, lisattavat) {
        //var xhttp = new XMLHttpRequest();
        //var async = true, sync = false;
        //var yhteysNro // funktion kutsuhetkellä

        if (tunniste === undefined) {
            tunniste = "";
        }
        if (!naytaVainVirheet)
            yhteys.nakyville(); //yhteys.state = "nakyvilla";
        if (lisattavat === undefined) {
            lisattavat = "";
        }

        if (UnTpd.unTpToken > "") {
            lisattavat += "utpToken";
        } else {
            lisattavat += "utpClientId, utpClientSecret";
        }

        //naytaKeskeytys.restart();

        if (haku === _get) {
            //viestit.text = qsTr("posting GET-query");
            //console.log("nyt lähtee GET: " + polku + " ? " + kysely + " & " + lisattavat)
            // <<<<<<< >>>>>>>>>
            xhttp.queryGet(tunniste, polku, kysely, lisattavat);
            // <<<<<<< >>>>>>>>>
            hakuja++;
        } else if (haku === _post) {
            //viestit.text = qsTr("posting POST-query");
            //console.log("nyt lähtee POST: " + polku + " ? " + kysely + " & " + lisattavat)
            // <<<<<<< >>>>>>>>>
            xhttp.queryPost(tunniste, polku, kysely, lisattavat);
            // <<<<<<< >>>>>>>>>
            hakuja++;
        }

        //console.log(">>> " + kysely)
        return;
    }
}
