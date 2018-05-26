import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    property int olutId
    property int panimoId

    function kirjoitaTiedot(jsonVastaus) {
        otsikko.title = jsonVastaus.response.beer.beer_name
        etiketti.source = jsonVastaus.response.beer.beer_label
        olutmerkki.text = jsonVastaus.response.beer.brewery.brewery_name
        olutmerkki.label = qsTr("abv") + " " + jsonVastaus.response.beer.beer_abv + " %, " +
                qsTr("ibu") + " " + jsonVastaus.response.beer.beer_ibu + ", " +
                jsonVastaus.response.beer.beer_style
        yhteismaara.text = jsonVastaus.response.beer.stats.total_count
        kuukausimaara.text = jsonVastaus.response.beer.stats.monthly_count
        juoneita.text = jsonVastaus.response.beer.stats.total_user_count
        kayttaja.text = jsonVastaus.response.beer.stats.user_count
        panimoId = jsonVastaus.response.beer.brewery.brewery_id
        kuvaus.text = jsonVastaus.response.beer.beer_description
        maa.text = jsonVastaus.response.beer.brewery.country_name + ", " +
                jsonVastaus.response.beer.brewery.location.brewery_state + ", " +
                jsonVastaus.response.beer.brewery.location.brewery_city
        www.text = jsonVastaus.response.beer.brewery.contact.url

        return
    }

    function lueOluenTiedot(bid) {
        var xhttp = new XMLHttpRequest();
        var kysely = ""

        if (bid == 0) {
            hetkinen.running = false
            otsikko.title = qsTr("no beer selected")
            return
        }

        kysely = UnTpd.getBeerInfo(bid, false) // bid, compact

        xhttp.onreadystatechange = function () {
            //console.log("lueOluenTiedot - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){
                var vastaus

                //console.log("lueOluenTiedot - " + xhttp.readyState + " - " + xhttp.status)

                if (xhttp.status == 200) {
                    vastaus = JSON.parse(xhttp.responseText)
                    //console.log(xhttp.responseText)
                    kirjoitaTiedot(vastaus)
                } else {
                    console.log("Beer Info: " + xhttp.status + ", " + xhttp.statusText)
                    kuvaus.text = "Beer Info: " + xhttp.status + ", " + xhttp.statusText
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return
    }

    SilicaFlickable {
        contentHeight: column.height
        anchors.fill: parent
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge

        Column {
            id: column
            anchors.fill: parent

            PageHeader {
                id: otsikko
                title: qsTr("getting beer info")
            }

            BusyIndicator {
                id: hetkinen
                size: BusyIndicatorSize.Medium
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
                visible: running
            }

            Row {
                Image {
                    id: etiketti
                    width: Theme.fontSizeMedium*4
                    height: width
                }

                TextField {
                    id: olutmerkki
                    readOnly: true
                    width: sivu.width - etiketti.width
                }
            } // row

            Row { // kirjausmäärät
                id:kirjausmaarat
                spacing: 0

                TextField {
                    id: kayttaja
                    readOnly: true
                    text: qsTr("me")
                    placeholderText: qsTr("me")
                    label: qsTr("me")
                    width: font.pixelSize*2 // ((kayttaja.text).length > 2) ? font.pixelSize*(kayttaja.text).length : font.pixelSize*2  //column.width/4
                }

                TextField {
                    id: juoneita
                    readOnly: true
                    placeholderText: qsTr("drinkers")
                    label: qsTr("drinkers")
                    width: ((juoneita.text).length > 4) ? font.pixelSize*(juoneita.text).length : font.pixelSize*4 // column.width/4
                }

                TextField {
                    id: kuukausimaara
                    readOnly: true
                    placeholderText: qsTr("monthly")
                    label: qsTr("monthly")
                    width: ((kuukausimaara.text).length > 4) ? font.pixelSize*(kuukausimaara.text).length : font.pixelSize*4
                }

                TextField {
                    id: yhteismaara
                    readOnly: true
                    placeholderText: qsTr("total")
                    label: qsTr("total")
                    width: ((yhteismaara.text).length > 4) ? font.pixelSize*(yhteismaara.text).length : font.pixelSize*4 //column.width/4
                }

            } //row

            TextArea {
                id: kuvaus
                width: sivu.width
                placeholderText: qsTr("description")
                readOnly: true
            }

            TextField {
                id: maa
                text: qsTr("location")
                readOnly: true
            }

            Button {
                id: www
                text: "http://url"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Qt.openUrlExternally(text)
                }
            }

        } // column

    } //flickable

    Component.onCompleted: {
        //console.log("tietojaOluesta " + sivu.width + " - " + column.width + ", " + kirjausmaarat.spacing)
        kayttaja.text = ""
        lueOluenTiedot(olutId)
    }
}
