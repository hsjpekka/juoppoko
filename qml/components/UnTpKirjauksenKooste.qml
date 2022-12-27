import QtQuick 2.0
import Sailfish.Silica 1.0
import "../pages"

//Item {
ListItem {
    id: kooste
    contentHeight: kirjaus.height + 4
    propagateComposedEvents: true
    width: parent.width
    menu: ContextMenu {
        MenuItem {
            text: qsTr("user data")
            visible: kayttis > ""
            onClicked: {
                pageContainer.push(Qt.resolvedUrl("../pages/unTpKayttaja.qml"),{
                                "kayttaja": kayttis } )
            }
        }
        MenuItem {
            text: qsTr("beer info")
            onClicked: {
                pageContainer.push(Qt.resolvedUrl("../pages/unTpTietojaOluesta.qml"),{
                                "olutId": olutId } )
            }
        }
        MenuItem {
            text: qsTr("venue info")
            visible: pubiId > -1
            onClicked: {
                pageContainer.push(Qt.resolvedUrl("../pages/unTpTarjoaja.qml"),
                                   {"tunniste": pubiId })
            }
        }
        MenuItem {
            text: qsTr("venue activity")
            visible: pubiId > -1
            onClicked: {
                if (pubSivulla) {
                    kaljarinki = "kuppila"
                    tunniste = pubiId
                    aloitaHaku()
                } else
                    pageContainer.push(Qt.resolvedUrl("../pages/unTpPub.qml"),
                                       {"tunniste": pubiId, "kaljarinki": "kuppila" })
            }
        }
    }

    signal malja
    signal juteltu

    property alias  juomari: juoja.text //nimi tai kayttajatunnus
    property int    juttuja: 0
    property alias  kalja: juotu.text
    property string kayttis: "" //unTappd-kayttajatunnus
    property var    keskustelu: [] //checkins.items[i].comments[0-(N-1)]
    property int    kirjausId: -1// kirjausId.text
    property alias  kuva: naama.source
    property bool   naytaTekija: true
    property int    nostoja: 0
    property int    olutId: -1// oluenId.text
    property bool   omaNosto: false
    property bool   osallistunut: false
    property alias  pubi: baari.text
    property int    pubiId: -1
    property alias  sanottu: saate.text
    property alias  tarra: juomanEtiketti.source
    property alias  valmistaja: panija.text
    property bool   pubSivulla: false

    function juttele() {
        var viestisivu, nimi = ""
        if (juomari != "") {
            nimi = juomari
        } else {
            nimi = kayttis
        }

        viestisivu = pageContainer.push(Qt.resolvedUrl("../pages/unTpJuomispuheet.qml"), {
                                        "keskustelu": keskustelu,
                                        "user_avatar": kuva,
                                        "user_name": nimi,
                                        "venue_name": pubi,
                                        "beer_label": tarra,
                                        "beer_name": kalja,
                                        "brewery_name": valmistaja,
                                        "checkin_comment": sanottu,
                                        "ckdId": kirjausId
                                    })
        viestisivu.sulkeutuu.connect( function() {
            juttuja = viestisivu.viesteja
            keskustelu = viestisivu.keskustelu
            olenkoJutellut(viestisivu.keskustelu)
            return
        })

        return
    }

    function olenkoJutellut() {
        var juttuja = keskustelu.count, i = 0
        while(i < juttuja){
            if (keskustelu.items[i].comment_editor === true){
                osallistunut = true
                return true
            }
            i++
        }
        osallistunut = false
        return false
    }

    Rectangle {
        id: kehys
        color: "transparent"
        border.color: Theme.secondaryColor
        border.width: 1
        radius: Theme.paddingMedium
        anchors.fill: parent
    }

    Column {
        id: kirjaus
        x: kehys.radius
        width: kehys.width - 2*x
        y: 2

        spacing: Theme.paddingSmall

        Row {// kuka, missä
            spacing: Theme.paddingMedium

            Image {
                id: naama
                source: ""
                height: Theme.iconSizeLarge
                width: height
                visible: naytaTekija
            }

            Column {
                id: kuka
                width: kirjaus.width - x - Theme.paddingSmall

                Label {
                    id: juoja
                    text: ""
                    color: Theme.highlightColor
                    visible: naytaTekija
                }

                Label {
                    id: baari
                    text: ""
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    width: kuka.width
                    color: Theme.secondaryHighlightColor
                    font.bold: !naytaTekija
                    visible: (text === "") ? false : true
                    x: naytaTekija? 0 : Theme.iconSizeLarge + Theme.paddingMedium
                }

            }

        }

        Row {// olut
            id: kirjattuOlut
            spacing: Theme.paddingMedium

            Image {
                id: juomanEtiketti
                source: ""
                width: Theme.iconSizeLarge
                height: width
            }

            Column {
                id: mita
                width: kirjaus.width - x - Theme.paddingSmall
                spacing: Theme.paddingSmall

                Label {
                    id: juotu
                    text: ""
                    color: Theme.highlightColor
                    width: mita.width - Theme.paddingSmall
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                Label {
                    id: panija
                    text: ""
                    color: Theme.secondaryHighlightColor
                    width: mita.width - Theme.paddingSmall
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                Label {
                    id: saate
                    text: ""
                    color: Theme.highlightColor
                    font.bold: true
                    font.italic: true
                    width: mita.width - Theme.paddingSmall
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    visible: text > ""
                }
            }
        }

        Item {// kommentit
            width: parent.width
            height: (peukku.height > peukkuja.height? peukku.height : peukkuja.height) +
                    Theme.paddingSmall

            IconButton {
                id: peukku
                anchors {
                    left: parent.left
                    leftMargin: 0.25*parent.width - width - Theme.paddingSmall
                }
                icon.source: "kippis.png" //"image://theme/icon-m-like"
                highlighted: omaNosto
                height: Theme.iconSizeSmall
                width: 1.5*height
                propagateComposedEvents: true
                onClicked: {
                    if (omaNosto)
                        nostoja--
                    else
                        nostoja++
                    omaNosto = !omaNosto
                    malja()
                    mouse.accepted = true
                }
                onPressAndHold: {
                    kooste.openMenu()
                    mouse.accepted = true
                }
            }

            Label {
                id: peukkuja
                text: nostoja
                color: Theme.secondaryHighlightColor
                anchors {
                    left: peukku.right
                    leftMargin: 2*Theme.paddingSmall
                }
            }

            IconButton {
                id: kommentti
                anchors {
                    right: kommentteja.left
                    rightMargin: 2*Theme.paddingSmall
                }
                icon.source: "image://theme/icon-m-chat"
                highlighted: osallistunut
                height: Theme.iconSizeSmall
                propagateComposedEvents: true
                onClicked: {
                    juttele()
                    mouse.accepted = true
                }
                onPressAndHold: {
                    mouse.accepted = true
                    kooste.openMenu()
                }
            }

            Label {
                id: kommentteja
                text: juttuja
                color: Theme.secondaryHighlightColor
                anchors {
                    right: parent.right
                    rightMargin: 0.25*parent.width - width - Theme.paddingSmall
                }
            }
        }
    }
}
