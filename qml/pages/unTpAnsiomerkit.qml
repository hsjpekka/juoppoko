import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    property int sivuNro: 0
    property int merkkejaSivulla: 50
    property int reunus: Theme.paddingLarge
    property string kayttajaTunnus: "" // itse, jos ""
    property bool haeKaikki: true
    property bool kaikkiHaettu: false
    property bool naytaKuvaus: false

    function haeMerkit() {
        var xhttp = new XMLHttpRequest();
        var kysely = ""

        hetkinen.running = true

        kysely = UnTpd.getBadges(kayttajaTunnus, sivuNro*merkkejaSivulla, merkkejaSivulla)

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
                    //console.log(xhttp.responseText)
                    kirjoitaTiedot(vastaus)
                } else {
                    console.log("Badges Info: " + xhttp.status + ", " + xhttp.statusText)
                    unTpdViestit.text = "Badges Info: " + xhttp.status + ", " + xhttp.statusText
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return
    }

    function kirjoitaTiedot(jsonVastaus) { // JSON.parse()
        var merkkiTiedot = jsonVastaus.response
        var i = 0, taso = "", mj = ""

        if (merkkiTiedot.count < merkkejaSivulla){
            kaikkiHaettu = true
        }

        while (i < merkkiTiedot.count){
            if (merkkiTiedot.items[i].is_level)
                taso = merkkiTiedot.items[i].levels.count + ""

            //lisaaPieniMerkki(merkkiTiedot.items[i].media.badge_image_lg,
              //                  merkkiTiedot.items[i].media.badge_image_sm,
                //                merkkiTiedot.items[i].badge_description,
                  //              merkkiTiedot.items[i].badge_name,
                    //            taso, merkkiTiedot.items[i].created_at)
            lisaaIsoMerkki(merkkiTiedot.items[i].media.badge_image_lg,
                           merkkiTiedot.items[i].badge_name,
                            merkkiTiedot.items[i].badge_description,
                            merkkiTiedot.items[i].created_at)

            i++
        }

        return
    }

    /*
    function kuvaustenNaytto(arvo) {
        var i = 0, N = isotMerkit.count
        while (i < N) {
            //console.log("ansiomerkit, kuvaustenNaytto " + i + ", " + arvo + ", " + isotMerkit.get(i).merkinKuvaus.visible)
            //isotMerkit.get(i).merkinKuvaus.visible = arvo
            i++
        }

        return
    } // */

    function lisaaIsoMerkki(merkki, nimi, kuvaus, paivays){
        var mj= kuvaus + "\n \n" + paivays
        isotMerkit.append({"nimi": nimi, "merkinUrl": merkki, "kuvaus": mj })
        valitutMerkit.positionViewAtBeginning()

        return
    }

    /*
    function lisaaPieniMerkki(iso, pieni, kuvaus, nimi, taso, paivays){
        pienetMerkit.append({"merkinUrl": iso, "pikkuMerkinUrl": pieni, "kuvaus": kuvaus,
                                "merkinNimi": nimi, "taso": taso, "ansaittu": paivays })
        kaikkiMerkit.positionViewAtBeginning()
        return
    }
    // */

    function naytaUudet(){
        var i = 0, mj = ""
        if (UnTpd.newBadgesSet) {
            while (i < UnTpd.newBadges.count) {
                if (UnTpd.newBadges.items[i].is_local_badge)
                    mj = qsTr("Local Badge")
                //else
                    //mj = qsTr("not Local Badge")

                if (UnTpd.newBadges.items[i].venue_name != ""){
                    if (mj !== "")
                        mj += "\n"
                    mj += UnTpd.newBadges.items[i].venue_name
                }

                lisaaIsoMerkki(UnTpd.newBadges.items[i].badge_image.lg,
                               UnTpd.newBadges.items[i].badge_name,
                               UnTpd.newBadges.items[i].badge_description,
                               mj)
                i++
            }
        }
        else {
            lisaaIsoMerkki("",qsTr("No badges during this session!"), "", qsTr("Depressing."))
        }

        return
    }

    function tyhjennaIsotMerkit(){
        var i = isotMerkit.count
        while (i>0) {
            isotMerkit.remove(0)
            i--
        }

        return
    }

    /*
    function tyhjennaPienetMerkit(){
        var i = pienetMerkit.count
        while (i>0) {
            pienetMerkit.remove(0)
            i--
        }

        return
    }
    // */

    Component {
        id: ansiomerkki
        Item {
            id: ansio1
            width: sivu.width
            height: merkkinaytto.height + Theme.paddingLarge

            Rectangle {
                height: ansio1.height
                width: ansio1.width - 2*(reunus + border.width)
                x: 0.5*(sivu.width - width)
                border.width: 2
                border.color: "gray"
                radius: Theme.paddingMedium
                color: "transparent"
            }

            Column {
                id: merkkinaytto
                y: 0.5*Theme.paddingLarge
                Label {
                    id: merkinNimi
                    text: nimi
                    x: 0.5*(sivu.width - width)
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.highlightColor
                }

                Image {
                    id: merkki
                    source: merkinUrl                   
                    x: 0.5*(sivu.width - width)
                    //width: 400
                }

                TextArea {
                    id: merkinKuvaus
                    text: kuvaus
                    width: sivu.width - reunus*2
                    readOnly: true
                    visible: naytaKuvaus
                    color: Theme.highlightColor
                    horizontalAlignment: TextEdit.AlignHCenter
                    x: 0.5*(sivu.width - width)
                }
            }

            MouseArea {
                anchors.fill: ansio1
                onClicked: {
                    merkinKuvaus.visible = !merkinKuvaus.visible
                }
            }

        }
    }

    /*
    Component {
        id: pikkumerkki

        ListItem {
            id: pikkulista
            contentHeight: pikkukuva.height > pikkuNimi.height ? pikkukuva.height : pikkuNimi.height

            onClicked: {
                tyhjennaIsotMerkit()
                lisaaIsoMerkki(isoKuva.text, pikkuNimi.text, pikkuKuvaus.text, paivamaara.text)
            }

            Row {
                Image {
                    id: pikkukuva
                    source: pikkuMerkinUrl
                    width: 92
                    height: 92
                }

                TextField {
                    id: pikkuNimi
                    text: merkinNimi
                    width: sivu.width - pikkukuva.width - ansiotaso.width - 2*reunus
                    label: qsTr("name")
                    readOnly: true
                    onClicked: {
                        tyhjennaIsotMerkit()
                        lisaaIsoMerkki(isoKuva.text, pikkuNimi.text, pikkuKuvaus.text,
                                       paivamaara.text)
                    }
                    //visible: false
                }

                TextArea {
                    id: pikkuKuvaus
                    text: kuvaus
                    visible: false
                    readOnly: true
                }

                TextField {
                    id: ansiotaso
                    text: taso
                    width: font.pixelSize*4
                    label: qsTr("level")
                    readOnly: true
                    onClicked: {
                        //tyhjennaIsotMerkit()
                        //lisaaIsoMerkki(isoKuva.text, pikkuNimi.text, pikkuKuvaus.text,
                          //             paivamaara.text)
                    }
                    //visible: false
                }

                Label {
                    id: isoKuva
                    text: merkinUrl
                    visible: false
                }

                Label {
                    id: paivamaara
                    text: ansaittu
                    visible: false
                }

            }

        }
    }
    // */

    SilicaFlickable {
        id: alue
        anchors.fill: parent
        height: sarake.height
        width: sivu.width
        contentHeight: sarake.height

        PullDownMenu {
            MenuItem {
                text: haeKaikki? qsTr("show new ones") : qsTr("show all")
                onClicked: {
                    haeKaikki = !haeKaikki
                    tyhjennaIsotMerkit()
                    //tyhjennaPienetMerkit()
                    if (haeKaikki) {
                        naytaKuvaus = false
                        haeMerkit()
                    }
                    else
                        naytaUudet()
                }
            }

            MenuItem {
                text: naytaKuvaus? qsTr("hide descriptions") : qsTr("show descriptions")
                onClicked: {
                    naytaKuvaus = !naytaKuvaus
                    //kuvaustenNaytto(naytaKuvaus)
                }
            }
        }

        Column {
            id: sarake
            width: sivu.width
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge

            PageHeader {
                id: otsikko
                title: qsTr("Badges")
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
                text: "..."
                color: Theme.secondaryHighlightColor
                visible: hetkinen.running
                anchors.horizontalCenter: sarake.horizontalCenter
                //x: 0.5*(sivu.width - width)
            }

            /*
            SilicaListView {
                id: kaikkiMerkit
                height: 0.3*sivu.height
                width: sivu.width
                clip: false //true

                model: ListModel {
                    id: pienetMerkit
                }

                delegate: pikkumerkki

                onMovementEnded: {
                    //console.log("siirtyminen loppui")
                    if (atYEnd && !kaikkiHaettu) {
                        //console.log("siirtyminen loppui " + atYEnd)
                        sivuNro = sivuNro + 1
                        haeMerkit()
                    }
                }

                VerticalScrollDecorator {}

            } // valitutMerkit-lista
            // */

            /*
            Rectangle {
                height: 1
                width: alue.width - 2*reunus
                color: "grey"
            } // */

            SilicaListView {
                id: valitutMerkit
                height: sivu.height - y
                width: sivu.width
                clip: true

                model: ListModel {
                    id: isotMerkit
                }

                delegate: ansiomerkki

                VerticalScrollDecorator {}

            } // valitutMerkit-lista

        } // column

        VerticalScrollDecorator {}
    } // flickable

    Component.onCompleted: {
        if (haeKaikki)
            haeMerkit()
        else
            naytaUudet()
    }
}
