import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd
import "../components"

Page {
    id: sivu

    property int tunniste: 0

    XhttpYhteys {
        id: utYhteys
        anchors.top: parent.top
        width: parent.width
        onValmis: {
            var jsonVastaus;
            try {
                jsonVastaus = JSON.parse(httpVastaus);
                kirjoitaTiedot(jsonVastaus)
            } catch (err) {
                console.log("" + err)
            }
        }

        function haeBaari(pubi) {
            var kysely, compact = false;
            kysely = UnTpd.getVenueInfo(pubi, compact);
            xHttpGet(kysely[0], kysely[1], "baari");

            return;
        }
    }

    ListModel {
        id: myydyimmat
        ListElement {
            merkki: ""
            olutId: -1
            tarra: ""
            panimo: ""
            panimoId: -1
        }
        property bool tyhja: true

        function lisaa(olut, olutId, tarra, panimo, panimoId) {
            if (tyhja) {
                myydyimmat.clear();
                tyhja = false;
            }
            return myydyimmat.append({"merkki": olut, "olutId": olutId, "panimo": panimo,
                                 "panimoId": panimoId, "tarra": tarra });
        }
    }

    Component {
        id: tietojaOluista
        ListItem {
            id: tietue
            contentHeight: (etiketti.height > oluenTiedot.height)? etiketti.height : oluenTiedot.height
            x: Theme.horizontalPageMargin
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("beer info")
                    onClicked: {
                        pageContainer.push(Qt.resolvedUrl("unTpTietojaOluesta.qml"),
                                           {"olutId": tietue.olutTunnus })
                    }
                }
                MenuItem {
                    text: qsTr("brewery info")
                    onClicked: {
                        pageContainer.push(Qt.resolvedUrl("unTpPanimo.qml"),
                                           {"tunniste": tietue.panimoTunnus })
                    }
                }
            }
            Image {
                id: etiketti
                source: tarra
                height: Theme.iconSizeMedium
                width: height
            }
            TextField {
                id: oluenTiedot
                anchors {
                    left: etiketti.right
                    right: parent.right
                }
                text: merkki
                label: panimo
                color: Theme.highlightColor
                readOnly: true
                focusOnClick: false
                onClicked: tietue.focus = true
                onPressAndHold: tietue.openMenu()
            }
            property int olutTunnus: olutId
            property int panimoTunnus: panimoId
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("people here")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("unTpPub.qml"),
                                       {"kaljarinki": "kuppila",
                                       "tunniste": tunniste } )
                }
            }
        }

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader {
                id: otsikko
                title: qsTr("Beer provider")
            }
            Row {
                x: Theme.horizontalPageMargin
                Image {
                    id: kuvake
                    source: ""
                }
                TextField {
                    id: luokitus
                    text: ""
                    label: qsTr("category") //public_venue
                    color: Theme.highlightColor
                    readOnly: true
                    width: parent.width - x
                }
            }

            TextField {
                id: osoite
                text: ""
                label: "" // long, lat
                placeholderText: qsTr("address")
                focusOnClick: true
                readOnly: true
                width: parent.width
            }
            TextField {
                id: kaupunki
                text: "" // kaupunki, alue
                placeholderText: qsTr("city")
                label: "" // maa
                color: Theme.highlightColor
                readOnly: true
                width: parent.width
            }
            TextArea {
                id: twitter
                text: "" // twitter, facebook, insta, ...
                color: Theme.highlightColor
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                height: text > "" ? implicitHeight : 0
                readOnly: true
            }
            LinkedLabel {
                id: www
                plainText: "www: " + url
                visible: url > ""
                height: visible? implicitHeight: 0
                property string url: ""
            }

            SectionHeader {
                text: qsTr("statistics")
            }

            Label {
                id: tilastoja
                color: Theme.highlightColor
                text: ""
                x: Theme.horizontalPageMargin
                width: parent.width - x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            SectionHeader {
                text: qsTr("top beers")
            }

            Repeater {
                model: myydyimmat
                delegate: tietojaOluista
            }
        }
    }
    Component.onCompleted: {
        utYhteys.haeBaari(tunniste)
    }

    function kirjoitaTiedot(tiedot) {
        var vastaus=tiedot.response.venue, i=0, mj="", yhteystieto, solu;
        otsikko.title = vastaus.venue_name;
        if ("primary_category" in vastaus) {
            luokitus.text = vastaus.primary_category;
        } else if ("categories" in vastaus && vastaus.categories.count > 0) {
            luokitus.text = vastaus.categories.items[0].category_name;
        }
        if (vastaus.public_venue === "true") {
            luokitus.label = qsTr("public");
        } else {
            luokitus.label = qsTr("private");
        }
        if ("venue_icon" in vastaus) {
            if ("md" in vastaus.venue_icon) {
                kuvake.source = vastaus.venue_icon.md;
            } else if ("sm" in vastaus.venue_icon) {
                kuvake.source = vastaus.venue_icon.sm;
            } else {
                kuvake.source = vastaus.venue_icon.lg;
            }
        }

        if ("location" in vastaus) {
            if (vastaus.location.venue_address > "") {
                osoite.text = vastaus.location.venue_address;
                osoite.label = qsTr("lat: ") +  vastaus.location.lat + qsTr(", lng: ") +
                        vastaus.location.lng;
            } else {
                osoite.text = qsTr("lat: ") +  vastaus.location.lat + qsTr(", lng: ") +
                        vastaus.location.lng;
            }
            kaupunki.text = vastaus.location.venue_city;
            if (vastaus.location.venue_state > "")
                kaupunki.text += ", " + vastaus.location.venue_state;
            kaupunki.label = vastaus.location.venue_country;
        }

        if ("contact" in vastaus) {
            for (yhteystieto in vastaus.contact) {
                if (yhteystieto === "venue_url") {
                    www.text = vastaus.contact[yhteystieto];
                } else if (vastaus.contact[yhteystieto] > "") {
                    twitter.text += yhteystieto + ": " + vastaus.contact[yhteystieto] + ", ";
                }
            }
        }
        if ("foursquare" in vastaus && "foursquare_url" in vastaus.foursquare) {
            if (www.text > "")
                www.text += ", ";
            www.text += vastaus.foursquare.foursquare_url;
        }

        for (solu in vastaus.stats) {
            tilastoja.text += solu + ": " + vastaus.stats[solu] + ", ";
        }
        if ("top_beers" in vastaus) {
            i=0;
            while (i < vastaus.top_beers.count) {
                myydyimmat.lisaa(vastaus.top_beers.items[i].beer.beer_name,
                                 vastaus.top_beers.items[i].beer.bid,
                                 vastaus.top_beers.items[i].beer.beer_label,
                                 vastaus.top_beers.items[i].brewery.brewery_name,
                                 vastaus.top_beers.items[i].brewery.brewery_id);
                i++;
            }
        }

        return;
    }

}
