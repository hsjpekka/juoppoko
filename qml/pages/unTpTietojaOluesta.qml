import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
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
        www.plainText = jsonVastaus.response.beer.brewery.contact.url

        return
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

    SilicaFlickable {
        height: sivu.height
        contentHeight: column.height
        anchors.fill: sivu //parent
        //anchors.leftMargin: Theme.paddingLarge
        //anchors.rightMargin: Theme.paddingLarge

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTr("brewery info")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("unTpPanimo.qml"),
                                       {"kaljarinki": "panimo",
                                           "tunniste": panimoId } )
                }
            }
            MenuItem {
                text: qsTr("pints around")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("unTpPub.qml"),
                                       {"kaljarinki": "olut",
                                       "tunniste": olutId } )
                }
            }
            MenuItem {
                text: toive ? qsTr("remove from wish-list") : qsTr("add to wish-list")
                visible: kirjautunut
                onClicked: {
                    if (toive)
                        unTpKysely.poistaToiveista()
                    else
                        unTpKysely.lisaaToiveisiin()
                }
            }
        }

        XhttpYhteys {
            id: unTpKysely
            anchors.top: parent.top
            z: 1
            onValmis: {
                var jsonVastaus = JSON.parse(httpVastaus);
                try {
                    if (toiminto === "toive") {
                        if (jsonVastaus.response.result === "success") {
                            if (jsonVastaus.response.action === "add")
                                toive = true
                            else
                                toive = false
                        }
                    } else if (toiminto === "tiedot") {
                        kirjoitaTiedot(jsonVastaus)
                    }
                } catch (err) {
                    console.log("" + err)
                }
            }
            onVirhe: {
                console.log("yhteydenottovirhe: " + vastaus)
            }

            //property string toiminto: ""

            function lisaaToiveisiin() {
                var kysely = ""
                if (olutId < 1) {
                    viesti = qsTr("no beer selected")
                    naytaViesti = true
                    return
                }
                //toiminto = "toive";

                kysely = UnTpd.addToWishList(olutId);
                xHttpGet(kysely, "toive");
                return
            }

            function lueOluenTiedot(bid) {
                var kysely = ""
                if (bid < 0.5) {
                    viesti = qsTr("no beer selected")
                    naytaViesti = true
                    return
                }

                //toiminto = "tiedot";
                kysely = UnTpd.getBeerInfo(bid, false); // bid, compact
                xHttpGet(kysely, "tiedot");
                return
            }

            function poistaToiveista() {
                var kysely = ""
                if (olutId < 1) {
                    viesti = qsTr("no beer selected")
                    naytaViesti = true
                    return
                }

                //toiminto = "toive";
                kysely = UnTpd.removeFromWishList(olutId);
                xHttpGet(kysely, "toive");
                return
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

            /*
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
            // */

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
                visible: text > ""
                //anchors.horizontalCenter: sivu.horizontalCenter
            }

            Label {
                id: maa
                text: " "
                color: Theme.highlightColor
                x: 0.5*(sivu.width - width)
                padding: Theme.paddingMedium
            }

            LinkedLabel {
                id: www
                plainText: "http://url"
                width: parent.width - 2*Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
                padding: Theme.paddingMedium
            }

        } // column

    } //flickable

    Component.onCompleted: {
        //console.log("tietojaOluesta " + sivu.width + " - " + column.width + ", " + kirjausmaarat.spacing)
        kayttaja.text = ""
        if (UnTpd.unTpToken != "")
            kirjautunut = true
        unTpKysely.lueOluenTiedot(olutId)
    }

}
