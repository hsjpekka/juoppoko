import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    allowedOrientations: Orientation.All
    Component.onCompleted: {
        kayttaja.text = ""
        if (UnTpd.unTpToken != "")
            kirjautunut = true
        unTpKysely.lueOluenTiedot(olutId)
    }

    property int olutId
    property int panimoId
    property bool toive: false
    property bool kirjautunut: false

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

        function lisaaToiveisiin() {
            var kysely = "";
            if (olutId < 1) {
                viesti = qsTr("no beer selected");
                naytaViesti = true;
                return;
            }

            kysely = UnTpd.addToWishList(olutId);
            xHttpGet(kysely[0], kysely[1], "toive");
            return;
        }

        function lueOluenTiedot(bid) {
            var kysely = "";
            if (bid < 0.5) {
                viesti = qsTr("no beer selected");
                naytaViesti = true;
                return;
            }

            kysely = UnTpd.getBeerInfo(bid, false); // bid, compact
            xHttpGet(kysely[0], kysely[1], "tiedot");
            return;
        }

        function poistaToiveista() {
            var kysely = "";
            if (olutId < 1) {
                viesti = qsTr("no beer selected");
                naytaViesti = true;
                return;
            }

            kysely = UnTpd.removeFromWishList(olutId);
            xHttpGet(kysely[0], kysely[1], "toive");
            return;
        }
    }

    SilicaFlickable {
        height: sivu.height
        contentHeight: column.height
        anchors.fill: sivu //parent

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
                text: otsikko.title
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
                        text: "oluen tyyppi"
                        color: Theme.highlightColor
                        width: sivu.width - etikettiRivi.x - etiketti.width - etikettiRivi.spacing - Theme.paddingSmall
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    Label {
                        id: oluenArvot
                        text: "prosentit ja happamuus"
                        color: Theme.secondaryHighlightColor
                    }

                    Label {
                        id: txtPanimo
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

    function kirjoitaTiedot(jsonVastaus) {
        var arvio, mj, mj2;
        otsikko.title = jsonVastaus.response.beer.beer_name;
        etiketti.source = jsonVastaus.response.beer.beer_label;
        txtPanimo.text = jsonVastaus.response.beer.brewery.brewery_name;
        oluenArvot.text = qsTr("abv %1 %, ").arg(jsonVastaus.response.beer.beer_abv) +
                qsTr("ibu %1").arg(jsonVastaus.response.beer.beer_ibu);
        olutTyyppi.text = jsonVastaus.response.beer.beer_style;

        arvio = jsonVastaus.response.beer.auth_rating;
        if (arvio > 0) {
            arviot.text = arviot.text + " " + arvio;
        } else {
            arviot.text = arviot.text + " _";
        }

        arvio = jsonVastaus.response.beer.rating_score;
        if (arvio > 0) {
            arviot.label = arviot.label + " " + arvio;
        } else {
            arviot.label = arviot.label + " _";
        }

        toive = jsonVastaus.response.beer.wish_list;
        kayttaja.text = jsonVastaus.response.beer.stats.user_count;
        yhteismaara.text = jsonVastaus.response.beer.stats.total_count;
        kuukausimaara.text = jsonVastaus.response.beer.stats.monthly_count;
        juoneita.text = jsonVastaus.response.beer.stats.total_user_count;
        panimoId = jsonVastaus.response.beer.brewery.brewery_id;
        kuvaus.text = jsonVastaus.response.beer.beer_description;

        mj = jsonVastaus.response.beer.brewery.country_name;
        mj2 = jsonVastaus.response.beer.brewery.location.brewery_state;
        if ((mj2 != "") && (mj2 != " "))
            mj += ", " + mj2;
        maa.text =  mj + ", " + jsonVastaus.response.beer.brewery.location.brewery_city;
        www.plainText = jsonVastaus.response.beer.brewery.contact.url;

        return;
    }

}
