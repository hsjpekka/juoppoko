import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu

    property string tunnus: "" //username
    property int haku: 0
    property int haettavia: 25
    property bool hakuvirhe: false

    signal sulkeutuu

    function haeKavereita() {
        var xhttp = new XMLHttpRequest();
        var kysely = ""

        hetkinen.running = true
        unTpdViestit.text = qsTr("posting query")

        kysely = UnTpd.getFriendsInfo(tunnus, haku*haettavia, haettavia)

        xhttp.onreadystatechange = function () {
            //console.log("haeKavereita - " + xhttp.readyState + " - " + xhttp.status + " , " + hakunro)
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
                    console.log("search friends: " + xhttp.status + ", " + xhttp.statusText)
                    hakuvirhe = true
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)

        return xhttp.send()
    }

    function paivitaHaetut(vastaus) { // vastaus = JSON(unTappd-vastaus)
        var i=0, n=vastaus.response.count
        var kuva, nimi, sijainti, kayttaja

        while (i<n) {
            kuva = vastaus.response.items[i].user.user_avatar
            nimi = vastaus.response.items[i].user.first_name + " "
                    + vastaus.response.items[i].user.last_name
            kayttaja = vastaus.response.items[i].user.user_name
            sijainti = vastaus.response.items[i].user.location

            lisaaListaan(kuva, nimi, sijainti, kayttaja)
            i++
        }

        return
    }

    function lisaaListaan(kuva, nimi, sijainti, kayttaja){
        return loydetytKaverit.append({ "kuva": kuva, "nimi": nimi, "sijainti": sijainti,
                                          "kayttaja": kayttaja })
    }

    Component {
        id: kaveri
        ListItem {
            width: sivu.width
            height: tiedot.height + 4
            Row {
                x: Theme.paddingLarge
                width: sivu.width - x*2
                spacing: Theme.paddingMedium

                Image {
                    id: naama
                    source: kuva
                    height: tiedot.height
                    width: height
                }

                TextField {
                    id: tiedot
                    text: nimi
                    label: sijainti
                    readOnly: true
                    color: Theme.primaryColor
                    onClicked: {
                        tunnus = kayttajatunnus.text
                        pageStack.pop()
                        //pageStack.push(Qt.resolvedUrl("unTpKayttaja.qml", {"kayttaja": kayttajatunnus.text}))
                    }
                }

                Label {
                    id: kayttajatunnus
                    text: kayttaja
                    visible: false
                }
            }
        }
    }

    Column {
        PageHeader{
            id: otsikko
            title: (tunnus == "") ? qsTr("my friends") : qsTr("%1's friends").arg(tunnus)
        }

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

        SilicaListView {
            height: sivu.height - otsikko.height
            width: sivu.width

            model: ListModel {
                id: loydetytKaverit
            }

            delegate: kaveri

            onMovementEnded: {
                if (atYEnd) {
                    haku++
                    haeKavereita()
                }

            }


            VerticalScrollDecorator {}
        }
    }

    Component.onCompleted: {
        haeKavereita()
    }

    Component.onDestruction: {
        sulkeutuu()
    }
}
