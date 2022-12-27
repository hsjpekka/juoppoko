import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Dialog {
    id: sivu
    Component.onCompleted: {
        haettava.text = olut;
        panimo = UnTpd.oluenPanimo;
        if (panimo != "") {
            naytaJuoma(UnTpd.oluenNimi, UnTpd.oluenId, UnTpd.oluenPanimo, UnTpd.oluenTyyppi,
                        UnTpd.oluenVahvuus, UnTpd.oluenHappamuus, UnTpd.oluenEtiketti);
            vahvuus = UnTpd.oluenVahvuus;
        }
        olutId = UnTpd.oluenId;
    }
    onAccepted: {
        if (olutId > 0) {
            olut = valittuOlut.text
        }

        talletaJuoma();
    }

    property string olut: ""
    property string oluenEtiketti: ""
    property string panimo: ""
    property string olutTyyppi: ""
    property int olutId: -1
    property real vahvuus: -1
    property int happamuus: -1
    property bool toiveissa: false
    property bool jarjestysTapa: true

    Connections {
        target: untpdKysely
        onFinishedQuery: {
            //finishedQuery(QString queryId, QString queryStatus, QString queryReply)
            var jsonVastaus;
            try {
                jsonVastaus = JSON.parse(queryReply)
                if (queryId === "oluidenHaku") {
                    paivitaHaetut(jsonVastaus)
                } else if (queryId === "toiveet") {
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
    }

    XhttpYhteys {
        id: unTpKysely
        width: parent.width
        anchors.top: parent.top
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

        function haeOluita(hakuteksti) {
            var lajittelu = jarjestysTapa ? "checkin" : "name";
            var kysely = "", lisattavat = "";

            if (hakuteksti === "")
                return;

            kysely = UnTpd.searchBeer(hakuteksti, hakunro*oluitaPerHaku, oluitaPerHaku,
                                      lajittelu);

            xHttpGet(kysely[0], kysely[1], "oluidenHaku");

            return;
        }

        function lisaaToiveisiin(lisaysVaiPoisto) {
            var kysely = "";
            if (olutId < 1) {
                viesti = qsTr("no beer selected");
                naytaViesti = true;
                return;
            }

            if (lisaysVaiPoisto) {
                kysely = UnTpd.addToWishList(olutId);
            } else {
                kysely = UnTpd.removeFromWishList(olutId);
            }

            xHttpGet(kysely[0], kysely[1], "toiveet");

            return;
        }
    }

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
                        kopioiJuoma(juomaLista.indexAt(mouseX,oluenTiedot.y+0.5*height))
                    }
                }
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

            SilicaListView {
                id: juomaLista
                height: sivu.height - y
                width: sivu.width
                clip: true

                model: loydetytOluet

                delegate: oluidenTiedot

                VerticalScrollDecorator {}

                onMovementEnded: {
                    if (atYEnd) {
                        unTpKysely.hakunro++;
                        unTpKysely.haeOluita(haettava.text)
                    }
                }
            }

        }//Column

    }

    function haunAloitus(hakuteksti) {
        tyhjennaLista();
        unTpKysely.hakunro = 0;
        unTpKysely.haeOluita(hakuteksti);
        return;
    }

    function kopioiJuoma(id) {
        if ((loydetytOluet.count > id) && (id >= 0)) {
            oluenEtiketti = loydetytOluet.get(id).etiketti;
            olut = loydetytOluet.get(id).oluenMerkki;
            olutId = loydetytOluet.get(id).unTpId;
            olutTyyppi = loydetytOluet.get(id).olutTyyppi;
            panimo = loydetytOluet.get(id).panimo;
            vahvuus = loydetytOluet.get(id).alkoholia;
            happamuus = loydetytOluet.get(id).hapot;
            toiveissa = loydetytOluet.get(id).toive;

            naytaJuoma(olut, olutId, panimo, olutTyyppi, vahvuus, happamuus,
                       oluenEtiketti);
        }

        return;
    }

    function naytaJuoma(olutQ, idQ, panimoQ, tyyppiQ, vahvuusQ, hapotQ, etikettiQ) {
        valittuOlut.text = olutQ;
        valittuOlut.label = panimoQ;
        if (idQ > 0) {
            valitunTietoja.text = tyyppiQ;
            valitunTietoja.label =  vahvuusQ + " %, " + qsTr("ibu %1").arg(hapotQ);
        }
        valitunEtiketti.source = etikettiQ;

        return;
    }

    function paivitaHaetut(vastaus) { // vastaus = JSON(unTappd-vastaus)
        var i=0, n=vastaus.response.beers.count;
        var merkki, panimo, tyyppi, etiketti, voltit, bid, ibu, toive;

        while (i<n) {
            merkki = vastaus.response.beers.items[i].beer.beer_name;
            bid = vastaus.response.beers.items[i].beer.bid;
            tyyppi = vastaus.response.beers.items[i].beer.beer_style;
            voltit = vastaus.response.beers.items[i].beer.beer_abv;
            etiketti = vastaus.response.beers.items[i].beer.beer_label;
            panimo = vastaus.response.beers.items[i].brewery.brewery_name;
            ibu = vastaus.response.beers.items[i].beer.beer_ibu;
            toive = vastaus.response.beers.items[i].beer.wish_list;

            loydetytOluet.lisaa(merkki, panimo, voltit, ibu, tyyppi, etiketti, bid, toive);
            i++;
        }

        return;
    }

    function talletaJuoma() {
        UnTpd.oluenEtiketti = oluenEtiketti;
        UnTpd.oluenHappamuus = happamuus;
        UnTpd.oluenId = olutId;
        UnTpd.oluenNimi = olut;
        UnTpd.oluenPanimo = panimo;
        UnTpd.oluenTyyppi = olutTyyppi;
        UnTpd.oluenVahvuus = vahvuus;

        return;
    }

    function tyhjennaLista() {
        return loydetytOluet.clear();
    }
}
