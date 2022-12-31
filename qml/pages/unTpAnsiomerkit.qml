import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    Component.onCompleted: {
        if (haeKaikki)
            uTYhteys.haeMerkit()
        else
            naytaUudet()
    }

    property bool   haeKaikki: true
    property bool   kaikkiHaettu: false
    property string kayttajaTunnus: "" // itse, jos ""
    property bool   naytaKuvaus: false

    ListModel {
        id: isotMerkit

        function lisaaIsoMerkki(merkki, nimi, kuvaus, paivays){
            var mj= kuvaus + "\n \n" + paivays;
            isotMerkit.append({"nimi": nimi, "merkinUrl": merkki,
                                  "kuvaus": mj });
            valitutMerkit.positionViewAtBeginning();

            return;
        }
    }

    Component {
        id: ansiomerkki
        Item {
            id: ansio1
            width: sivu.width - Theme.horizontalPageMargin
            x: 0.5*(sivu.width - width)
            height: merkkinaytto.height + Theme.paddingLarge

            Connections {
                target: sivu
                onNaytaKuvausChanged: {
                    merkinKuvaus.visible = sivu.naytaKuvaus
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: border.width
                anchors.rightMargin: anchors.leftMargin
                border.width: 2
                border.color: Theme.secondaryHighlightColor
                radius: Theme.paddingMedium
                color: "transparent"
            }

            Column {
                id: merkkinaytto
                width: parent.width - 2*Theme.horizontalPageMargin
                x: 0.5*(parent.width - width)
                y: 0.5*Theme.paddingLarge

                Label {
                    id: merkinNimi
                    text: nimi
                    width: parent.width
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }

                Image {
                    id: merkki
                    source: merkinUrl
                    width: parent.width
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                }

                LinkedLabel {
                    id: merkinKuvaus
                    text: kuvaus
                    width: parent.width
                    color: Theme.highlightColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    visible: naytaKuvaus
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

    XhttpYhteys {
        id: uTYhteys
        anchors.top: parent.top
        z: 1
        onValmis: {
            var jsonVastaus, merkkitiedot
            try {
                jsonVastaus = JSON.parse(httpVastaus)
                if (jsonVastaus.response.count < merkkejaPerHaku){
                    kaikkiHaettu = true
                }
                lueMerkit(jsonVastaus.response)

            } catch (err) {
                console.log("" + err)
            }
            hakuNro++
        }

        property int hakuNro: 0
        property int merkkejaPerHaku: 25
        property string toiminto: ""

        function haeMerkit() {
            var kysely = ""
            kysely = UnTpd.getBadges(kayttajaTunnus, hakuNro*merkkejaPerHaku,
                                              merkkejaPerHaku);
            xHttpGet(kysely[0], kysely[1], "merkit");

            return
        }

    }

    SilicaListView {
        id: valitutMerkit
        anchors.fill: parent

        model: isotMerkit
        header: PageHeader {
            title: qsTr("Badges")
        }

        delegate: ansiomerkki
        onMovementEnded: {
            if (atYEnd && !kaikkiHaettu) {
                uTYhteys.haeMerkit()
            }
        }

        PullDownMenu {
            MenuItem {
                text: haeKaikki? qsTr("show new ones") : qsTr("show all")
                onClicked: {
                    haeKaikki = !haeKaikki;
                    tyhjennaIsotMerkit();
                    if (haeKaikki) {
                        naytaKuvaus = false;
                        uTYhteys.haeMerkit()
                    } else
                        naytaUudet()
                }
            }

            MenuItem {
                text: naytaKuvaus? qsTr("hide descriptions") : qsTr("show descriptions")
                onClicked: {
                    naytaKuvaus = !naytaKuvaus
                }
            }
        }

        VerticalScrollDecorator {}

    } // valitutMerkit-lista

    function lueMerkit(merkkiTiedot) {
        var i = 0, taso = "", mj = "";

        while (i < merkkiTiedot.count){
            if (merkkiTiedot.items[i].is_level) {
                taso = merkkiTiedot.items[i].levels.count + "";
            }

            isotMerkit.lisaaIsoMerkki(merkkiTiedot.items[i].media.badge_image_lg,
                           merkkiTiedot.items[i].badge_name,
                            merkkiTiedot.items[i].badge_description,
                            merkkiTiedot.items[i].created_at);

            i++;
        }
        return;
    }

    function naytaUudet(){
        var i = 0, mj = "", merkit = UnTpd.newBadges;
        if (UnTpd.newBadgesSet) {
            while (i < merkit.count) {
                if (merkit.items[i].is_local_badge) {
                    mj = qsTr("Local Badge");
                }

                if (merkit.items[i].venue_name > ""){
                    if (mj !== "") {
                        mj += "\n";
                    }
                    mj += merkit.items[i].venue_name;
                }

                isotMerkit.lisaaIsoMerkki(merkit.items[i].badge_image.lg,
                               merkit.items[i].badge_name,
                               merkit.items[i].badge_description,
                               mj);
                i++;
            }
        }
        else {
            isotMerkit.lisaaIsoMerkki("",qsTr("No badges during this session!"), "", qsTr("Depressing."));
        }

        return;
    }

    function tyhjennaIsotMerkit(){
        isotMerkit.clear();
        uTYhteys.hakuNro = 0;

        return;
    }
}
