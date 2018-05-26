import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd

Dialog {
    id: sivu
    property string olut: ""
    property string oluenEtiketti: ""
    property string panimo: ""
    property string olutTyyppi: ""
    property int olutId: 0
    property int hakunro: 0
    property int oluitaPerHaku: 25
    property int valittuOlut: 0
    property real vahvuus: 0

    function haeOluita(hakuteksti) {
        var xhttp = new XMLHttpRequest();
        var kysely = ""
        var lajittelu = jarjestysTapa.checked ? "checkin" : "name"

        if (hakuteksti == "")
            return

        hetkinen.running = true

        kysely = UnTpd.searchBeer(hakuteksti, hakunro*oluitaPerHaku, oluitaPerHaku, lajittelu)

        xhttp.onreadystatechange = function () {
            //console.log("haeOluita - " + xhttp.readyState + " - " + xhttp.status + " , " + hakunro)
            if (xhttp.readyState == 4){
                //console.log(xhttp.responseText)
                var vastaus = JSON.parse(xhttp.responseText);

                if (xhttp.status == 200) {
                    //console.log(xhttp.responseText)
                    paivitaHaetut(vastaus)
                } else {
                    console.log("search beer: " + xhttp.status + ", " + xhttp.statusText)
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return
    }

    function talletaJuoma() {
        UnTpd.oluenEtiketti = oluenEtiketti
        UnTpd.oluenNimi = olut
        UnTpd.oluenPanimo = panimo
        UnTpd.oluenId = olutId
        UnTpd.oluenTyyppi = olutTyyppi
        UnTpd.oluenVahvuus = vahvuus

        return
    }

    function naytaJuoma(olutQ, idQ, panimoQ, tyyppiQ, vahvuusQ, etikettiQ) {
        valittuOlutMerkki.text = olutQ
        valittuOlutMerkki.label = panimoQ
        if (idQ > 0)
            valitunTietoja.text = tyyppiQ + ", " + vahvuusQ + " %"
        valitunEtiketti.source = etikettiQ

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

            naytaJuoma(olut, olutId, panimo, olutTyyppi, vahvuus, oluenEtiketti)
        }

        return
    }

    function lisaaListaan(olut, panimo, voltit, tyyppi, tarra, unTpId) {

        loydetytOluet.append({"oluenMerkki": olut, "panimo": panimo, "olutTyyppi": tyyppi,
                             "etiketti": tarra, "unTpId": unTpId, "alkoholia": voltit});
        return
    }

    function paivitaHaetut(vastaus) { // vastaus = JSON(unTappd-vastaus)
        var i=0, n=loydetytOluet.count
        var merkki, panimo, tyyppi, etiketti, voltit, bid

        while (i<n) {
            loydetytOluet.remove(i)
            i++
        }

        i = 0
        n = vastaus.response.beers.count
        while (i<n) {
            merkki = vastaus.response.beers.items[i].beer.beer_name
            bid = vastaus.response.beers.items[i].beer.bid
            tyyppi = vastaus.response.beers.items[i].beer.beer_style
            voltit = vastaus.response.beers.items[i].beer.beer_abv
            etiketti = vastaus.response.beers.items[i].beer.beer_label
            panimo = vastaus.response.beers.items[i].brewery.brewery_name

            lisaaListaan(merkki, panimo, voltit, tyyppi, etiketti, bid)
            i++
        }

        return
    }

    function tyhjennaLista() {
        var i=0, n=loydetytOluet.count

        while (i<n) {
            loydetytOluet.remove(i)
            i++
        }

        return
    }

    Component {
        id: oluidenTiedot
        ListItem {
            id: oluenTiedot
            height: Theme.fontSizeMedium*3
            width: sivu.width
            onClicked: {
                valittuOlut = juomaLista.indexAt(mouseX,y+mouseY)
                kopioiJuoma(valittuOlut)
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
                    label: panimo
                    readOnly: true
                    width: sivu.width - x
                    onClicked: {
                        valittuOlut = juomaLista.indexAt(mouseX,oluenTiedot.y+0.5*height)
                        kopioiJuoma(valittuOlut)
                    }
                }

                Label {
                    text: unTpId
                    visible: false
                }

                Label {
                    text: olutTyyppi
                    visible: false
                }

                Label {
                    text: alkoholia
                    visible: false
                }
            } // row
        }

    } // oluidenTiedot

    Column {
        id: column
        spacing: Theme.paddingLarge
        width: sivu.width
        anchors.fill: parent

        DialogHeader {
            title: qsTr("Beers in unTappd")
        }

        TextSwitch {
            id: jarjestysTapa
            checked: true
            text: checked ? qsTr("order by popularity") : qsTr("alphabetical order")
        }

        Item { // valittu juoma
            id: valittuRivi
            x: Theme.paddingLarge
            width: sivu.width - 2*x
            height: valittuOlutMerkki.height + valitunTietoja.height

            Image {
                id: valitunEtiketti
                source: "./tuoppi.png"
                width: Theme.fontSizeMedium*3
                height: width
                x: valittuRivi.x
                //anchors.left: valittuRivi.anchors.left
                //anchors.top: valittuRivi.anchors.top
            }

            TextField {
                id: valittuOlutMerkki
                placeholderText: qsTr("selected beer")
                readOnly: true
                width: valittuRivi.width - valitunEtiketti.width
                x: valitunEtiketti.x + valitunEtiketti.width + Theme.paddingSmall
                y: valitunEtiketti.y
            }

            Label {
                id: valitunTietoja
                width: valittuRivi.width - valitunEtiketti.width
                text: " "
                x: valittuRivi.x
                y: valittuOlutMerkki.y + 3 +
                   (valittuOlutMerkki.height > valitunEtiketti.height ? valittuOlutMerkki.height : valitunEtiketti.height)
                //anchors.left: valitunEtiketti.anchors.right
                //anchors.top: valittuOlutMerkki.anchors.bottom
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("tietojaOluesta.qml"),{
                            "olutId": olutId } )
                }
            }

        } // valittu juoma

        Row {
            id: hakurivi
            spacing: Theme.paddingLarge

            TextField {
                id: haettava
                placeholderText: qsTr("search text")
                label: qsTr("search text")
                //text:
                width: sivu.width - hae.width - 2*hakurivi.spacing
            }

            // /*
            IconButton {
                id: hae
                icon.source: "image://theme/icon-m-search"
                width: Theme.fontSizeMedium*3
                onClicked: {
                    tyhjennaLista()
                    hakunro = 0
                    haeOluita(haettava.text)
                }
            }// */
        } // hakurivi

        BusyIndicator {
            id: hetkinen
            size: BusyIndicatorSize.Medium
            anchors.horizontalCenter: parent.horizontalCenter
            running: false
            visible: running
        }

        SilicaListView {
            id: juomaLista
            height: sivu.height - y
            width: sivu.width
            clip: true

            model: ListModel {
                id: loydetytOluet
            }

            delegate: oluidenTiedot

            VerticalScrollDecorator {}

            onMovementEnded: {
                //console.log("siirtyminen loppui")
                if (atYEnd) {
                    //console.log("siirtyminen loppui " + atYEnd)
                    hakunro = hakunro + 1
                    haeOluita(haettava.text)
                }

            }
        }

    }//Column

    Component.onCompleted: {
        haettava.text = olut
        naytaJuoma(UnTpd.oluenNimi, UnTpd.oluenId, UnTpd.oluenPanimo, UnTpd.oluenTyyppi,
                   UnTpd.oluenVahvuus, UnTpd.oluenEtiketti)
        olutId = UnTpd.oluenId

    }

    onAccepted: {
        talletaJuoma()
    }
}
