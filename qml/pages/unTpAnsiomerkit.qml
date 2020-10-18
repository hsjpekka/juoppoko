import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    //property int hakuNro: 0
    //property int merkkejaSivulla: 50
    property bool   haeKaikki: true
    property bool   kaikkiHaettu: false
    property string kayttajaTunnus: "" // itse, jos ""
    property bool   naytaKuvaus: false

    function lueMerkit(merkkiTiedot) {
        var i = 0, taso = "", mj = ""
        console.log("merkkejä " + merkkiTiedot.count)

        while (i < merkkiTiedot.count){
            if (merkkiTiedot.items[i].is_level)
                taso = merkkiTiedot.items[i].levels.count + ""

            isotMerkit.lisaaIsoMerkki(merkkiTiedot.items[i].media.badge_image_lg,
                           merkkiTiedot.items[i].badge_name,
                            merkkiTiedot.items[i].badge_description,
                            merkkiTiedot.items[i].created_at)

            i++
        }
        return
    }

    function naytaUudet(){
        var i = 0, mj = "", merkit = UnTpd.newBadges
        if (UnTpd.newBadgesSet) {
            while (i < merkit.count) {
                if (merkit.items[i].is_local_badge)
                    mj = qsTr("Local Badge")
                //else
                    //mj = qsTr("not Local Badge")

                if (merkit.items[i].venue_name > ""){
                    if (mj !== "")
                        mj += "\n"
                    mj += merkit.items[i].venue_name
                }

                isotMerkit.lisaaIsoMerkki(merkit.items[i].badge_image.lg,
                               merkit.items[i].badge_name,
                               merkit.items[i].badge_description,
                               mj)
                i++
            }
        }
        else {
            isotMerkit.lisaaIsoMerkki("",qsTr("No badges during this session!"), "", qsTr("Depressing."))
        }

        return
    }

    function tyhjennaIsotMerkit(){
        //var i = isotMerkit.count
        //while (i>0) {
        //    isotMerkit.remove(0)
        //    i--
        //}
        isotMerkit.clear()
        uTYhteys.hakuNro = 0

        return
    }

    ListModel {
        id: isotMerkit
        function lisaaIsoMerkki(merkki, nimi, kuvaus, paivays){
            var mj= kuvaus + "\n \n" + paivays
            console.log("erkki " + nimi + ", " + isotMerkit.count)
            isotMerkit.append({"nimi": nimi, "merkinUrl": merkki, "kuvaus": mj })
            valitutMerkit.positionViewAtBeginning()

            return
        }
    }

    Component {
        id: ansiomerkki
        Item {
            id: ansio1
            width: sivu.width
            height: merkkinaytto.height + Theme.paddingLarge
            property int reunus: Theme.paddingLarge

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: reunus + border.width
                anchors.rightMargin: anchors.leftMargin
                //height: ansio1.height
                //width: ansio1.width - 2*(reunus + border.width)
                //x: 0.5*(sivu.width - width)
                border.width: 2
                border.color: Theme.secondaryHighlightColor
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

    SilicaListView {
        id: valitutMerkit
        anchors.fill: parent
        //anchors.leftMargin: Theme.horizontalPageMargin
        //anchors.rightMargin: Theme.horizontalPageMargin
        //height: sivu.height// - y
        //width: sivu.width
        //clip: true

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
                    //tyhjennaPienetMerkit()
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
                    //kuvaustenNaytto(naytaKuvaus)
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
                xHttpGet(kysely);

                return
            }

        }

        VerticalScrollDecorator {}

    } // valitutMerkit-lista

    Component.onCompleted: {
        console.log("kayttaja: " + kayttajaTunnus + ", " + haeKaikki)
        if (haeKaikki)
            uTYhteys.haeMerkit()
        else
            naytaUudet()
    }
}
