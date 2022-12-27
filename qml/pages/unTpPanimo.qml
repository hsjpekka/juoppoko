import QtQuick 2.0
import QtQml 2.0
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu

    property int tunniste: -1

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

        function haePanimo(panimo) {
            var kysely, compact = false
            if (panimo > 0) {
                kysely = UnTpd.getBreweryInfo(panimo, compact)
                xHttpGet(kysely[0], kysely[1], "panimo")
            } else {
                osoite.text = qsTr("no brewery selected (brewery id < 1)")
            }

            return
        }
    }

    ListModel {
        id: tuotteet
        ListElement {
            merkki: ""
            olutId: -1
            tyyppi: ""
            tarra: ""
        }
        property bool tyhja: true

        function lisaa(olut, olutId, tyyppi, tarra) {
            if (tyhja) {
                tuotteet.clear()
                tyhja = false
            }
            return tuotteet.append({"merkki": olut, "olutId": olutId, "tyyppi": tyyppi,
                                   "tarra": tarra })
        }
    }

    Component {
        id: tietojaOluista
        ListItem {
            id: tietue
            contentHeight: etiketti.height
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("beer info")
                    onClicked: {
                        pageContainer.push(Qt.resolvedUrl("unTpTietojaOluesta.qml"),
                                           {"olutId": tietue.olutTunnus })
                    }
                }
                MenuItem {
                    text: qsTr("pints around")
                    onClicked: {
                        pageContainer.push(Qt.resolvedUrl("unTpPub.qml"),
                                           {"kaljarinki": "olut",
                                           "tunniste": tietue.olutTunnus } )
                    }
                }
            }
            Image {
                id: etiketti
                source: tarra
                height: Theme.iconSizeLarge
                width: height
            }
            Label {
                anchors {
                    left: etiketti.right
                    leftMargin: Theme.paddingMedium
                    top: etiketti.top
                }
                text: merkki
                color: Theme.highlightColor
            }
            Label {
                anchors {
                    left: etiketti.right
                    leftMargin: Theme.paddingMedium
                    bottom: etiketti.bottom
                }
                text: tyyppi
                color: Theme.secondaryHighlightColor
            }

            property int olutTunnus: olutId
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("search breweries")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("unTpHaePanimoita.qml"))
                }
            }

            MenuItem {
                text: qsTr("pints around")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("unTpPub.qml"),
                                       {"kaljarinki": "panimo",
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
                title: qsTr("Brewery")
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                //width: parent.width
                Image {
                    id: juliste
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
                color: Theme.secondaryColor
                focusOnClick: true
                readOnly: true
                width: parent.width
            }
            TextField {
                id: kaupunki
                text: "" // kaupunki, alue
                placeholderText: qsTr("city")
                label: "" // maa
                readOnly: true
                color: Theme.highlightColor
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
                height: visible? implicitHeight : 0
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
                model: tuotteet
                delegate: tietojaOluista
            }
        }
    }
    Component.onCompleted: {
        utYhteys.haePanimo(tunniste)
    }

    function kirjoitaTiedot(tiedot) {
        var vastaus=tiedot.response.brewery, i=0, mj="", yhteystieto, solu;
        otsikko.title = vastaus.brewery_name;
        if ("brewery_label" in vastaus) {
            juliste.source = vastaus.brewery_label;
        }

        luokitus.text = vastaus.brewery_type;
        if (vastaus.brewery_in_production === 0) {
            luokitus.label = ""; //qsTr("brewing")
        } else {
            luokitus.label = qsTr("not producing");
            luokitus.color = Theme.secondaryHighlightColor;
        }

        if ("location" in vastaus) {
            if (vastaus.location.brewery_address > "") {
                osoite.text = vastaus.location.brewery_address;
                osoite.label = qsTr("lat: ") +  vastaus.location.brewery_lat + qsTr(", lng: ") +
                        vastaus.location.brewery_lng;
            } else {
                osoite.text = qsTr("lat: ") +  vastaus.location.brewery_lat + qsTr(", lng: ") +
                        vastaus.location.brewery_lng;
            }
            kaupunki.text = vastaus.location.brewery_city;
            if (vastaus.location.brewery_state > "")
                kaupunki.text += ", " + vastaus.location.brewery_state;
            kaupunki.label = vastaus.country_name;
        }

        if ("contact" in vastaus) {
            for (yhteystieto in vastaus.contact) {
                if (yhteystieto === "url" || yhteystieto === "facebook" ||
                        yhteystieto === "instagram") {
                    if (www.text.length > 0)
                        www.text += "\n";
                    www.text += vastaus.contact[yhteystieto];
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

        if ("beer_list" in vastaus) {
            i=0;
            while (i < vastaus.beer_list.count) {
                tuotteet.lisaa(vastaus.beer_list.items[i].beer.beer_name,
                               vastaus.beer_list.items[i].beer.bid,
                               vastaus.beer_list.items[i].beer.beer_style,
                               vastaus.beer_list.items[i].beer.beer_label);
                i++;
            }
        }

        return;
    }
}
