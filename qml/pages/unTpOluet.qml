import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd

Dialog {
    id: sivu
    property string olut: ""
    property int olutId: 0
    property int sivu: 0
    property int oluitaPerSivu: 25
    property int valittuOlut: 0

    function haeOluita(haettava) {
        var xhttp = new XMLHttpRequest();
        var kysely = ""
        var lajittelu = jarjestysTapa.checked ? "checkin" : "name"

        kysely = UnTpd.searchBeer(haettava, sivu*oluitaPerSivu, oluitaPerSivu, lajittelu)

        xhttp.onreadystatechange = function () {
            console.log("haeBaari - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){
                var vastaus = JSON.parse(xhttp.responseText);

                if (xhttp.status == 200) {
                    //console.log(xhttp.responseText)
                    paivitaHaetut(vastaus)
                } else {
                    console.log(qsTr("haeBaari - error: ") + xhttp.status + ", " + xhttp.statusText)
                }
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return
    }

    function kopioiJuoma(id) {

        if ((loydetytOluet.count > id) && (id >= 0)) {
            valittuOlutMerkki.text = loydetytOluet.get(id).oluenMerkki
            valittuOlutMerkki.label = loydetytOluet.get(id).panimo
            valitunEtiketti.source = loydetytOluet.get(id).etiketti
            olutId = loydetytOluet.get(id).unTpId
        }

        return
    }

    function lisaaListaan(olut, panimo, voltit, tyyppi, tarra, unTpId) {

        loydetytOluet.append({"oluenMerkki": olut, "panimo": panimo + ", " + tyyppi + "," + voltit,
                             "etiketti": tarra, "unTpId": unTpId});
        return
    }

    function paivitaHaetut(vastaus) { // vastaus = JSON(unTappd-vastaus)
        return
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width
            anchors.fill: parent

            DialogHeader {
                title: qsTr("Beers in unTappd")
            }

            TextSwitch {
                id: jarjestysTapa
                checked: true
                text: checked ? qsTr("order by popularity") : qsTr("alphabetical order")
            }

            Row { // valittu juoma
                Image {
                    id: valitunEtiketti
                    //source: etiketti
                    width: Theme.fontSizeMedium*2
                    height: width
                }

                TextField {
                    id: valittuOlutMerkki
                    placeholderText: qsTr("selected beer")
                    readOnly: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("tietojaOluesta.qml"),{
                            "olutId": olutId } )
                    }
                }
            } // valittu juoma

            Component {
                id: oluidenTiedot
                ListItem {
                    id: oluenTiedot
                    onClicked: {
                        valittuOlut = juomaLista.indexAt(mouseX,y+mouseY)
                        kopioiJuoma(valittuOlut)
                    }

                    Row {
                        x: Theme.paddingLarge
                        width: sivu.width - 2*x

                        Image {
                            source: etiketti
                            width: Theme.fontSizeMedium*2
                            height: width
                        }

                        TextField {
                            text: oluenMerkki
                            label: panimo
                        }

                        Label {
                            text: unTpId
                            visible: false
                        }
                    } // row
                }

            } // oluenTiedot

            SilicaListView {
                id: juomaLista
                height: sivu.height - y
                width: parent.width
                clip: true

                model: ListModel {
                    id: loydetytOluet
                }

                delegate: oluidenTiedot

                VerticalScrollDecorator {}

            }

        }//Column
    } //SilicaFlickable
}
