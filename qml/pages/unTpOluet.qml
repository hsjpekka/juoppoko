import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Dialog {
    id: sivu
    property string olut: ""
    property string oluenEtiketti: ""
    property string panimo: ""
    property string olutTyyppi: ""
    property int olutId: 0
    property real vahvuus: 0
    property int happamuus: 0
    property bool toiveissa: false

    property bool hakuMuuttuu: false
    property int qqhakunro: 0
    //property bool hakuvirhe: false
    //property int valittuOlut: 0

    property bool jarjestysTapa: true

    /*
    function qqhaeOluita(hakuteksti) {
        var xhttp = new XMLHttpRequest();
        var kysely = ""
        var lajittelu = jarjestysTapa ? "checkin" : "name"

        if (hakuteksti == "")
            return

        hetkinen.running = true
        unTpdViestit.text = qsTr("posting query")

        kysely = UnTpd.searchBeer(hakuteksti, hakunro*oluitaPerHaku, oluitaPerHaku, lajittelu)

        xhttp.onreadystatechange = function () {
            //console.log("haeOluita - " + xhttp.readyState + " - " + xhttp.status + " , " + hakunro)
            if (xhttp.readyState == 0)
                unTpdViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
            else if (xhttp.readyState == 1)
                unTpdViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
            else if (xhttp.readyState == 2)
                unTpdViestit.text = qsTr("request received") + ", " + xhttp.statusText
            else if (xhttp.readyState == 3)
                unTpdViestit.text = qsTr("processing request") + ", " + xhttp.statusText
            else { //if (xhttp.readyState == 4){
                //console.log(xhttp.responseText)
                var vastaus = JSON.parse(xhttp.responseText);

                unTpdViestit.text = xhttp.statusText

                if (xhttp.status == 200) {
                    //console.log(xhttp.responseText)
                    hakuvirhe = false
                    paivitaHaetut(vastaus)
                } else {
                    console.log("search beer: " + xhttp.status + ", " + xhttp.statusText)
                    hakuvirhe = true
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return xhttp.status
    }
    // */

    /*
    function qqkunOluetHaettu(vastaus) {
        hakuvirhe = false
        hetkinen.running = false
        paivitaHaetut(vastaus)
        return
    }

    function qqjosOluenHaussaVirhe(vastaus) {
        hakuvirhe = true
        hetkinen.running = false
        return
    }
    // */

    function haunAloitus(hakuteksti) {
        tyhjennaLista()
        unTpKysely.hakunro = 0
        unTpKysely.haeOluita(hakuteksti)
        return
    }

    function kopioiJuoma(id) {

        if ((loydetytOluet.count > id) && (id >= 0)) {
            oluenEtiketti = loydetytOluet.get(id).etiketti
            olut = loydetytOluet.get(id).oluenMerkki
            olutId = loydetytOluet.get(id).unTpId
            olutTyyppi = loydetytOluet.get(id).olutTyyppi
            panimo = loydetytOluet.get(id).panimo
            vahvuus = loydetytOluet.get(id).alkoholia
            happamuus = loydetytOluet.get(id).hapot
            toiveissa = loydetytOluet.get(id).toive

            naytaJuoma(olut, olutId, panimo, olutTyyppi, vahvuus, happamuus,
                       oluenEtiketti)
        }

        return
    }

    /*
    function josLisattyToiveisiin(vastaus) {
        if (vastaus.response.result === "success") {
            if (vastaus.response.action === "add")
                toiveissa = true
            else // (vastaus.response.action === "remove")
                toiveissa = false
        }

        return
    }

    function josLisaysEpaonnistui(vastaus) {
        sekunti.start()
        return
    } // */

    /*
    function qqlisaaToiveisiin(lisaysVaiPoisto) {
        var kysely = ""
        hetkinen.running = true

        if (olutId < 1) {
            unTpdViestit.text = qsTr("no beer selected")
            sekunti.start()
            return
        }

        if (lisaysVaiPoisto)
            kysely = UnTpd.addToWishList(olutId)
        else
            kysely = UnTpd.removeFromWishList(olutId)

        UnTpd.xHttpUnTpd(UnTpd.GET, kysely, "", unTpdViestit.text, josLisattyToiveisiin,
                         josLisaysEpaonnistui)

        return

    }
    // */

    function naytaJuoma(olutQ, idQ, panimoQ, tyyppiQ, vahvuusQ, hapotQ, etikettiQ) {
        valittuOlut.text = olutQ
        valittuOlut.label = panimoQ
        if (idQ > 0) {
            valitunTietoja.text = tyyppiQ
            valitunTietoja.label =  vahvuusQ + " %, " + qsTr("ibu %1").arg(hapotQ)
        }
        valitunEtiketti.source = etikettiQ

        return
    }

    function paivitaHaetut(vastaus) { // vastaus = JSON(unTappd-vastaus)
        var i=0, n=vastaus.response.beers.count
        var merkki, panimo, tyyppi, etiketti, voltit, bid, ibu, toive

        while (i<n) {
            merkki = vastaus.response.beers.items[i].beer.beer_name
            bid = vastaus.response.beers.items[i].beer.bid
            tyyppi = vastaus.response.beers.items[i].beer.beer_style
            voltit = vastaus.response.beers.items[i].beer.beer_abv
            etiketti = vastaus.response.beers.items[i].beer.beer_label
            panimo = vastaus.response.beers.items[i].brewery.brewery_name
            ibu = vastaus.response.beers.items[i].beer.beer_ibu
            toive = vastaus.response.beers.items[i].beer.wish_list

            loydetytOluet.lisaa(merkki, panimo, voltit, ibu, tyyppi, etiketti, bid, toive)
            i++
        }

        return
    }

    /*
    function poistaToiveista() {
        var xhttp = new XMLHttpRequest();
        var kysely = ""
        hetkinen.running = true

        if (olutId < 1) {
            unTpdViestit.text = qsTr("no beer selected")
            sekunti.start()
            return
        }

        kysely = UnTpd.removeFromWishList(olutId)
        xhttp.onreadystatechange = function () {
            if (xhttp.readyState == 0)
                unTpdViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
            else if (xhttp.readyState == 1)
                unTpdViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
            else if (xhttp.readyState == 2)
                unTpdViestit.text = qsTr("request received") + ", " + xhttp.statusText
            else if (xhttp.readyState == 3)
                unTpdViestit.text = qsTr("processing request") + ", " + xhttp.statusText
            else { //if (xhttp.readyState == 4){
                var vastaus

                if (xhttp.status == 200) {
                    vastaus = JSON.parse(xhttp.responseText)
                    unTpdViestit.text = vastaus.response.result
                    if (vastaus.response.result == "success")
                        toiveissa = false
                } else {
                    console.log("Remove from Wishlist: bid " + bid + "; " + xhttp.status + ", " + xhttp.statusText)
                    unTpdViestit.text = xhttp.status + ", " + xhttp.statusText
                }

                sekunti.start()
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return

    } //*/

    function talletaJuoma() {
        UnTpd.oluenEtiketti = oluenEtiketti
        UnTpd.oluenNimi = olut
        UnTpd.oluenPanimo = panimo
        UnTpd.oluenId = olutId
        UnTpd.oluenTyyppi = olutTyyppi
        UnTpd.oluenVahvuus = vahvuus
        UnTpd.oluenHappamuus = happamuus

        return
    }

    function tyhjennaLista() {
        return loydetytOluet.clear()
    }

    /*
    Timer{
        id: sekunti
        interval: 1*1000
        running: false
        repeat: false
        onTriggered: {
            hetkinen.running = false
        }
    }
    // */

    ListModel {
        id: loydetytOluet

        function lisaa(olut, panimo, voltit, hapokkuus, tyyppi, tarra, unTpId, toive) {
            return append({"oluenMerkki": olut, "panimo": panimo, "olutTyyppi": tyyppi,
                                 "etiketti": tarra, "unTpId": unTpId, "alkoholia": voltit,
                                 "hapot": hapokkuus, "toive": toive });
        }
    }

    Component {
        id: oluidenTiedot
        ListItem {
            id: oluenTiedot
            height: Theme.fontSizeMedium*3
            width: sivu.width
            onClicked: {
                //valittuOlut =
                kopioiJuoma(juomaLista.indexAt(mouseX,y+mouseY))
            }

            Row {
                x: Theme.paddingLarge
                width: sivu.width - 2*x

                Image {
                    source: etiketti
                    width: oluenTiedot.height
                    height: width
                }

                TextField {
                    text: oluenMerkki
                    color: Theme.secondaryColor
                    label: panimo
                    readOnly: true
                    width: sivu.width - x
                    onClicked: {
                        //valittuOlut =
                        kopioiJuoma(juomaLista.indexAt(mouseX,oluenTiedot.y+0.5*height))
                    }
                }

                /*
                Label {
                    text: unTpId
                    color: Theme.secondaryColor
                    visible: false
                }

                Label {
                    text: olutTyyppi
                    color: Theme.secondaryColor
                    visible: false
                }

                Label {
                    text: alkoholia
                    color: Theme.secondaryColor
                    visible: false
                }

                Label {
                    text: happamuus
                    color: Theme.secondaryColor
                    visible: false
                }

                Label {
                    text: toive
                    color: Theme.secondaryColor
                    visible: false
                } // */
            } // row
        }

    } // oluidenTiedot

    SilicaFlickable {
        id: ylaosa
        anchors.fill: sivu
        height: sivu.height
        contentHeight: column.height

        PullDownMenu{
            MenuItem {
                text: qsTr("search breweries")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("unTpHaePanimoita.qml"))
                }
            }

            MenuItem {
                text: jarjestysTapa ? qsTr("change to alphabetical order") : qsTr("change to order by popularity")
                onClicked: {
                    jarjestysTapa = !jarjestysTapa
                    if (haettava.text != "")
                        haunAloitus(haettava.text)
                }
            }

            MenuItem {
                text: toiveissa? qsTr("remove from wish-list") : qsTr("add to wish-list")
                visible: (UnTpd.unTpToken > "" && olutId > 0)? true : false
                onClicked: {
                    unTpKysely.lisaaToiveisiin(!toiveissa)
                }
            }

            MenuItem {
                text: qsTr("sign in UnTappd")
                visible: (UnTpd.unTpToken == "") ? true : false
                onClicked: pageContainer.push(Qt.resolvedUrl("unTpKayttaja.qml"))
            }

        }

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width
            //anchors.fill: parent

            DialogHeader {
                title: qsTr("Beers in unTappd")
            }

            Row {
                id: huomatusRivi
                x: Theme.paddingMedium
                spacing: Theme.paddingMedium
                visible: (UnTpd.unTpToken == "")? true : false

                IconButton {
                    id: suljeHuomautus
                    icon.source: "image://theme/icon-m-clear"
                    onClicked: huomatusRivi.visible = false
                }

                TextArea {
                    width: sivu.width - 2*huomatusRivi.x - huomatusRivi.spacing - suljeHuomautus.width
                    color: Theme.secondaryHighlightColor
                    text: qsTr("Seems like you haven't logged in UnTappd. " +
                               "That may limit the number of queries per day.")
                    readOnly: true
                }
            }

            /*
            BusyIndicator {
                id: hetkinen
                size: BusyIndicatorSize.Medium
                anchors.horizontalCenter: parent.horizontalCenter
                running: false
                visible: running
            }

            Label {
                id: unTpdViestit
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("starting search")
                color: Theme.secondaryColor
                visible: (hetkinen.running || hakuvirhe)
            }
            // */

            Item { // valittu juoma
                id: valittuRivi
                x: Theme.paddingLarge
                width: sivu.width - 2*x
                height: valittuOlut.height + valitunTietoja.height

                Image {
                    id: valitunEtiketti
                    source: "tuoppi.png"
                    width: valittuOlut.height // etiketit 92*92 untappedin tietokannassa
                    height: width
                    //x: valittuRivi.x
                    //anchors.left: valittuRivi.anchors.left // ei toimi
                    //anchors.top: valittuRivi.anchors.top // ei toimi
                }

                TextField {
                    id: valittuOlut
                    placeholderText: qsTr("selected beer")
                    color: Theme.primaryColor
                    readOnly: true
                    width: valittuRivi.width - valitunEtiketti.width
                    x: valitunEtiketti.x + valitunEtiketti.width + Theme.paddingSmall
                    y: valitunEtiketti.y
                }

                TextField{
                    id: valitunTietoja
                    width: valittuRivi.width - valitunEtiketti.width
                    color: Theme.primaryColor
                    readOnly: true
                    text: " "
                    x: valittuOlut.x
                    y: valittuOlut.y + 3 +
                       (valittuOlut.height > valitunEtiketti.height ? valittuOlut.height : valitunEtiketti.height)
                    //anchors.left: valitunEtiketti.anchors.right
                    //anchors.top: valittuOlutMerkki.anchors.bottom
                }

                MouseArea {
                    anchors.fill: valittuRivi// parent
                    onClicked: {
                        if (panimo != "")
                            pageContainer.push(Qt.resolvedUrl("unTpTietojaOluesta.qml"),{
                                            "olutId": olutId } )
                    }
                }

            } // valittu juoma

            /*
            Row {
                id: hakurivi
                spacing: Theme.paddingSmall

                IconButton {
                    id: tyhjennaHaku
                    icon.source: "image://theme/icon-m-clear"
                    //width: Theme.fontSizeMedium*3
                    onClicked: {
                        haettava.text = ""
                    }
                }

                TextField {
                    id: haettava
                    placeholderText: qsTr("search text")
                    //label: qsTr("search text")
                    //text:
                    width: sivu.width - tyhjennaHaku.width - hae.width - 2*hakurivi.spacing
                    EnterKey.iconSource: "image://theme/icon-m-search"
                    EnterKey.onClicked: haunAloitus(text)
                }

                // /*
                IconButton {
                    id: hae
                    icon.source: "image://theme/icon-m-search"
                    width: Theme.fontSizeMedium*3
                    onClicked: {
                        haunAloitus(haettava.text)
                    }
                }//
            } // hakurivi */

            SearchField {
                id: haettava
                width: parent.width
                text: ""
                placeholderText: qsTr("beer")
                EnterKey.iconSource: "image://theme/icon-m-search"
                EnterKey.onClicked: {
                    focus = false
                    minTauko.stop();
                    haunAloitus(text);
                }
                onTextChanged: {
                    if (text.length > 2)
                        minTauko.restart()
                }

                Timer {
                    id: minTauko
                    interval: 1000
                    running: false
                    repeat: false
                    onTriggered: haunAloitus(haettava.text)
                }
            }

            XhttpYhteys {
                id: unTpKysely
                width: parent.width
                unohdaVanhat: true
                onValmis: {
                    var jsonVastaus;
                    try {
                        jsonVastaus = JSON.parse(httpVastaus)
                        if (toiminto === "oluidenHaku") {
                            paivitaHaetut(jsonVastaus)
                        } else if (toiminto === "toiveet") {
                            if (jsonVastaus.response.result === "success") {
                                if (jsonVastaus.response.action === "add")
                                    toiveissa = true
                                else // (vastaus.response.action === "remove")
                                    toiveissa = false
                            }
                        }
                    } catch (err) {
                        console.log("" + err)
                    }
                }

                property int hakunro: 0
                property int oluitaPerHaku: 25
                //property string toiminto: ""

                function haeOluita(hakuteksti) {
                    var lajittelu = jarjestysTapa ? "checkin" : "name"
                    var kysely = "";

                    if (hakuteksti === "")
                        return

                    //toiminto = "oluidenHaku";
                    kysely = UnTpd.searchBeer(hakuteksti, hakunro*oluitaPerHaku, oluitaPerHaku,
                                              lajittelu);

                    xHttpGet(kysely, "oluidenHaku");

                    return
                }

                function lisaaToiveisiin(lisaysVaiPoisto) {
                    var kysely = ""
                    if (olutId < 1) {
                        viesti = qsTr("no beer selected")
                        naytaViesti = true
                        return
                    }

                    //toiminto = "toiveet";
                    if (lisaysVaiPoisto)
                        kysely = UnTpd.addToWishList(olutId)
                    else
                        kysely = UnTpd.removeFromWishList(olutId);

                    xHttpGet(kysely, "toiveet");

                    return
                }
            }

            SilicaListView {
                id: juomaLista
                height: sivu.height - y
                width: sivu.width
                clip: true

                model: loydetytOluet

                delegate: oluidenTiedot

                VerticalScrollDecorator {}

                onMovementEnded: {
                    //console.log("siirtyminen loppui")
                    if (atYEnd) {
                        //console.log("siirtyminen loppui " + atYEnd)
                        unTpKysely.hakunro++;
                        unTpKysely.haeOluita(haettava.text)
                    }
                }
            }

        }//Column

    }

    Component.onCompleted: {
        haettava.text = olut
        panimo = UnTpd.oluenPanimo
        if (panimo != "") {
            naytaJuoma(UnTpd.oluenNimi, UnTpd.oluenId, UnTpd.oluenPanimo, UnTpd.oluenTyyppi,
                        UnTpd.oluenVahvuus, UnTpd.oluenHappamuus, UnTpd.oluenEtiketti)
            vahvuus = UnTpd.oluenVahvuus
        }
        olutId = UnTpd.oluenId

        //console.log("onCompleted: olutId = " + olutId)

    }

    onAccepted: {
        if (olutId > 0) {
            olut = valittuOlut.text
        }

        talletaJuoma()
    }
}
