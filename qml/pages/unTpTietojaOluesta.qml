import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    allowedOrientations: Orientation.All

    property int olutId
    property int panimoId
    property bool toive: false
    property bool kirjautunut: false

    function kirjoitaTiedot(jsonVastaus) {
        var arvio, mj, mj2
        otsikko.title = jsonVastaus.response.beer.beer_name
        etiketti.source = jsonVastaus.response.beer.beer_label
        //UnTpd.oluenEtiketti = jsonVastaus.response.beer.beer_label
        txtPanimo.text = jsonVastaus.response.beer.brewery.brewery_name
        oluenArvot.text = qsTr("abv %1 %, ").arg(jsonVastaus.response.beer.beer_abv) +
                qsTr("ibu %1").arg(jsonVastaus.response.beer.beer_ibu)
        olutTyyppi.text = jsonVastaus.response.beer.beer_style

        arvio = jsonVastaus.response.beer.auth_rating
        if (arvio > 0)
            arviot.text = arviot.text + " " + arvio
        else
            arviot.text = arviot.text + " _"

        arvio = jsonVastaus.response.beer.rating_score
        if (arvio > 0)
            arviot.label = arviot.label + " " + arvio
        else
            arviot.label = arviot.label + " _"

        toive = jsonVastaus.response.beer.wish_list
        kayttaja.text = jsonVastaus.response.beer.stats.user_count
        yhteismaara.text = jsonVastaus.response.beer.stats.total_count
        kuukausimaara.text = jsonVastaus.response.beer.stats.monthly_count
        juoneita.text = jsonVastaus.response.beer.stats.total_user_count
        panimoId = jsonVastaus.response.beer.brewery.brewery_id
        kuvaus.text = jsonVastaus.response.beer.beer_description

        mj = jsonVastaus.response.beer.brewery.country_name
        mj2 = jsonVastaus.response.beer.brewery.location.brewery_state
        if ((mj2 != "") && (mj2 != " "))
            mj += ", " + mj2
        maa.text =  mj + ", " + jsonVastaus.response.beer.brewery.location.brewery_city
        www.text = jsonVastaus.response.beer.brewery.contact.url

        return
    }

    function lisaaToiveisiin() {
        var xhttp = new XMLHttpRequest();
        var kysely = ""
        hetkinen.running = true

        if (olutId < 1) {
            unTpdViestit.text = qsTr("no beer selected")
            sekunti.start()
            return
        }

        kysely = UnTpd.addToWishList(olutId)
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
                        toive = true
                } else {
                    console.log("Add to Wishlist: bid " + bid + "; " + xhttp.status + ", " + xhttp.statusText)
                    unTpdViestit.text = xhttp.status + ", " + xhttp.statusText
                }

                sekunti.start()
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return

    }

    function lueOluenTiedot(bid) {
        var xhttp = new XMLHttpRequest();
        var kysely = ""

        if (bid < 0.5) {
            hetkinen.running = false
            otsikko.title = qsTr("no beer selected")
            return
        }

        kysely = UnTpd.getBeerInfo(bid, false) // bid, compact
        //console.log("kyselyOluesta " + bid)

        xhttp.onreadystatechange = function () {
            //console.log("lueOluenTiedot - " + xhttp.readyState + " - " + xhttp.status)
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
                //console.log("lueOluenTiedot - " + xhttp.readyState + " - " + xhttp.status)

                if (xhttp.status == 200) {
                    vastaus = JSON.parse(xhttp.responseText)
                    //console.log(xhttp.responseText)
                    kirjoitaTiedot(vastaus)
                } else {
                    console.log("Beer Info: bid " + bid + "; " + xhttp.status + ", " + xhttp.statusText)
                    kuvaus.text = "Beer Info: bid " + bid + "; " + xhttp.status + ", " + xhttp.statusText
                    txtPanimo.text = ""
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return
    }

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
                        toive = false
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

    }

    Timer{
        id: sekunti
        interval: 1*1000
        running: false
        repeat: false
        onTriggered: {
            hetkinen.running = false
        }
    }

    SilicaFlickable {
        height: sivu.height
        contentHeight: column.height
        anchors.fill: sivu //parent
        //anchors.leftMargin: Theme.paddingLarge
        //anchors.rightMargin: Theme.paddingLarge

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: toive ? qsTr("remove from wish-list") : qsTr("add to wish-list")
                visible: kirjautunut
                onClicked: {
                    if (toive)
                        poistaToiveista()
                    else
                        lisaaToiveisiin()
                }
            }
        }

        Column {
            id: column


            PageHeader {
                id: otsikko
                title: qsTr("getting beer info")
            }

            Label {
                id: leveystesti
                text: otsikko.title
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightDimmerColor
                visible: false
            }

            Label {
                id: txtOluenNimi
                x: Theme.paddingMedium
                width: sivu.width - 2*x
                text: otsikko.title // + " " + (sivu.width/(otsikko.title.length*Theme.fontSizeLarge)).toFixed(2)
                //visible: ( sivu.width < 0.37*(otsikko.title.length*Theme.fontSizeLarge) ) ? true : false
                color: Theme.highlightColor
                visible: (leveystesti.width > sivu.width) ? true : false
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Rectangle {
                height: Theme.paddingSmall
                width: 4
                color: "transparent"
                visible: txtOluenNimi.visible
            }

            /*
            Label {
                x: Theme.paddingMedium
                width: sivu.width - 2*x
                text: txtPanimo.text
                visible: (txtPanimo.width > sivu.width - etiketti.width) ? true : false
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
            // */

            BusyIndicator {
                id: hetkinen
                size: BusyIndicatorSize.Medium
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
                visible: running
            }

            Label {
                id: unTpdViestit
                color: Theme.secondaryHighlightColor
                visible: hetkinen.running
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                id: etikettiRivi
                x: Theme.paddingMedium
                spacing: Theme.paddingMedium

                Image {
                    id: etiketti
                    height: 3*oluenArvot.height //92 unTappedin tietokannassa
                    width: height
                }

                Column {

                    Label {
                        id: olutTyyppi
                        //readOnly: true
                        text: "oluen tyyppi"
                        color: Theme.highlightColor
                        width: sivu.width - etikettiRivi.x - etiketti.width - etikettiRivi.spacing - Theme.paddingSmall
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        //x: txtPanimo.x + Theme.paddingLarge
                    }

                    Label {
                        id: oluenArvot
                        text: "prosentit ja happamuus"
                        color: Theme.secondaryHighlightColor
                    }

                    Label {
                        id: txtPanimo
                        //readOnly: true
                        width: sivu.width - etikettiRivi.x - etiketti.width - etikettiRivi.spacing
                        text: "panimo"
                        color: Theme.highlightColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                }
            } // row

            Row { // kirjausmäärät
                id: omatKirjaukset
                spacing: 0

                TextField {
                    id: kayttaja
                    readOnly: true
                    visible: kirjautunut
                    text: qsTr("me")
                    label: qsTr("me")
                    color: Theme.highlightColor
                    width: sivu.width*0.3
                }

                TextField {
                    id: toiveissa
                    readOnly: true
                    visible: kirjautunut
                    text: toive ? qsTr("is in my") : qsTr("is not in")
                    label: qsTr("wishlist")
                    color: Theme.highlightColor
                    width: sivu.width*0.3
                }

                TextField {
                    id: arviot
                    readOnly: true
                    color: Theme.highlightColor
                    text: qsTr("my rating")
                    label: qsTr("others")
                    width: sivu.width*0.4
                }

            } //row

            Row { // kirjausmäärät
                id: muidenKirjaukset
                spacing: 0

                TextField {
                    id: juoneita
                    readOnly: true
                    text: qsTr("drinkers")
                    label: qsTr("drinkers")
                    color: Theme.highlightColor
                    width: sivu.width*0.3
                }

                TextField {
                    id: kuukausimaara
                    readOnly: true
                    text: qsTr("monthly")
                    label: qsTr("monthly")
                    color: Theme.highlightColor
                    width: sivu.width*0.3
                }

                TextField {
                    id: yhteismaara
                    readOnly: true
                    text: qsTr("total")
                    label: qsTr("total")
                    color: Theme.highlightColor
                    width: sivu.width*0.4
                }

            } //row

            TextArea {
                id: kuvaus
                width: sivu.width
                text: qsTr("description")
                color: Theme.highlightColor
                readOnly: true
                horizontalAlignment: TextEdit.AlignHCenter
                //anchors.horizontalCenter: sivu.horizontalCenter
            }

            Label {
                id: maa
                text: " "
                color: Theme.highlightColor
                x: 0.5*(sivu.width - width)
            }

            Rectangle {
                width: 12
                height: 4
                color: "transparent"
            }

            Button {
                id: www
                text: "http://url"
                x: 0.5*(sivu.width - width)
                onClicked: {
                    Qt.openUrlExternally(text)
                }
            }

        } // column

    } //flickable

    Component.onCompleted: {
        //console.log("tietojaOluesta " + sivu.width + " - " + column.width + ", " + kirjausmaarat.spacing)
        kayttaja.text = ""
        if (UnTpd.unTpToken != "")
            kirjautunut = true
        lueOluenTiedot(olutId)
    }

}
