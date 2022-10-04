import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu

    function haunAloitus(hakuteksti) {
        loydetytPanimot.clear()
        unTpKysely.hakunro = 0
        unTpKysely.haePanimoita(hakuteksti)
        return
    }

    function kopioiPanimo(i) {
        valitunEtiketti.source = loydetytPanimot.get(i).merkki
        panimonNimi.text = loydetytPanimot.get(i).nimi
        panimonNimi.label = loydetytPanimot.get(i).tyyppi
        kaupunki.text = loydetytPanimot.get(i).paikka
        valittuPanimo.panimoId = loydetytPanimot.get(i).id

        if (loydetytPanimot.get(i).toimii) {
            panimonNimi.font.italic = false
            kaupunki.font.italic = false
        } else {
            panimonNimi.font.italic = true
            kaupunki.font.italic = true
        }
        return
    }

    function paivitaHaetut(jsonVastaus) {
        var i=0
        console.log(JSON.stringify(jsonVastaus))
        while (i<jsonVastaus.response.found) {
            i++
        }

        return
    }

    ListModel {
        id: loydetytPanimot

        function lisaa(nimi, luokitus, merkki, toiminnassa, sijainti, tunniste) {
            return append({"nimi": nimi, "tyyppi": luokitus, "merkki": merkki,
                              "toimii": toiminnassa, "paikka": sijainti, "id": tunniste });
        }
    }

    Component {
        id: panimoidenTiedot
        ListItem {
            id: ehdokas
            height: Theme.fontSizeMedium*3
            width: sivu.width
            opacity: toimii? 1 : Theme.opacityLow
            onClicked: {
                kopioiPanimo(juomaLista.indexAt(mouseX,y+mouseY))
            }

            Row {
                x: Theme.paddingLarge
                width: sivu.width - 2*x

                Image {
                    source: merkki
                    width: oluenTiedot.height
                    height: width
                }

                TextField {
                    text: nimi
                    color: Theme.secondaryColor
                    label: paikka
                    readOnly: true
                    width: sivu.width - x
                    onClicked: {
                        kopioiPanimo(juomaLista.indexAt(mouseX,oluenTiedot.y+0.5*height))
                    }
                }
            } // row
        }
    } // panimoidenTiedot

    Column {
        PageHeader {
            title: qsTr("Breweries")
        }

        Item { // valittu juoma
            id: valittuPanimo
            x: Theme.paddingLarge
            width: sivu.width - 2*x
            height: panimonNimi.height + kaupunki.height

            property int panimoId: -1

            Image {
                id: valitunEtiketti
                source: ""
                width: Theme.iconSizeMedium // etiketit 92*92 untappedin tietokannassa
                height: width
            }

            TextField {
                id: panimonNimi
                placeholderText: qsTr("selected brewery")
                color: Theme.primaryColor
                readOnly: true
                anchors {
                    left: valitunEtiketti.right
                    right: parent.right
                }
            }

            Label{
                id: kaupunki
                anchors {
                    top: panimonNimi.bottom
                    left: panimonNimi.left
                    leftMargin: Theme.horizontalPageMargin
                }

                width: valittuPanimo.width - valitunEtiketti.width
                color: Theme.primaryColor
                text: ""
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("unTpPanimo.qml"),
                                       {"tunniste": valittuPanimo.panimoId})
                }
            }

        } // valittu panimo

        SearchField {
            id: haettava
            width: parent.width
            text: ""
            placeholderText: qsTr("brewery")
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
            //unohdaVanhat: true
            //xhttp: untpdKysely
            onValmis: {
                var jsonVastaus;
                try {
                    jsonVastaus = JSON.parse(httpVastaus)
                    paivitaHaetut(jsonVastaus)
                } catch (err) {
                    console.log("" + err)
                }
            }

            property int hakunro: 0
            property int perHaku: 25

            function haePanimoita(hakuteksti) {
                var kysely = "";

                if (hakuteksti === "")
                    return;

                kysely = UnTpd.searchBrewery(hakuteksti, hakunro*perHaku, perHaku);

                xHttpGet(kysely[0], kysely[1], "panimot");

                return;
            }
        }

        SilicaListView {
            id: panimoLista
            height: sivu.height - y
            width: sivu.width
            clip: true

            model: loydetytPanimot

            delegate: panimoidenTiedot

            VerticalScrollDecorator {}

            onMovementEnded: {
                if (atYEnd) {
                    unTpKysely.hakunro++;
                    unTpKysely.haePanimoita(haettava.text)
                }
            }
        }
    }
}
