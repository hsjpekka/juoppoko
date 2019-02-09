import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: kooste
    height: kirjaus.height + 2*kirjaus.y

    property alias tunnus: kirjausId.text
    property alias olutId: oluenId.text
    property bool naytaTekija: true
    property alias kuva: naama.source
    property alias kayttis: kayttaja.text
    property alias juomari: juoja.text
    property alias pubi: baari.text
    property alias tarra: juomanEtiketti.source
    property alias kalja: juotu.text
    property alias valmistaja: panija.text
    property alias sanottu: saate.text
    property int nostoja: 0
    property bool omaNosto: false
    property int juttuja: 0
    property bool osallistunut: false

    property var keskustelu: [] //checkins.items[i].comments[0-(N-1)]

    Rectangle {
        id: kehys
        color: "transparent"
        border.color: Theme.secondaryColor
        border.width: 1
        radius: Theme.paddingMedium
        width: kooste.width
        height: kooste.height
        //y: 0
    } // */

    Column {
        id: kirjaus
        x: kehys.radius
        width: kehys.width - x
        y: 2

        spacing: Theme.paddingSmall

        Text {
            id: kirjausId
            visible: false
            text: "" //checkinId
        }

        Text {
            id: oluenId
            text: "" //bid
            visible: false
        }

        Row {// kuka, missä
            spacing: Theme.paddingMedium

            Image {
                id: naama
                source: ""
                height: Theme.fontSizeMedium*2.5
                width: height
                visible: naytaTekija
            }

            Column {
                id: kuka
                width: kirjaus.width - x - Theme.paddingSmall

                Text {
                    id: kayttaja
                    text: "" //userId
                    visible: false
                }

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
                }

            }

        }

        Row {// olut, kommentit
            id: kirjattuOlut
            //x: Theme.paddingLarge
            spacing: Theme.paddingMedium
            //x: Theme.paddingLarge

            Image {
                id: juomanEtiketti
                source: ""
                width: Theme.fontSizeMedium*3
                height: width
            }

            Column {
                id: mita
                width: sivu.width - kirjattuOlut.x - x

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
                }

                Row {
                    spacing: Theme.paddingMedium

                    IconButton {
                        id: peukku
                        icon.source: "image://theme/icon-m-like"
                        highlighted: omaNosto
                        height: peukkuja.height*1.5
                        propagateComposedEvents: true
                        //enabled: false
                        onClicked: {
                            valittu = kirjaukset.indexAt(mouseX, tietue.y + mouseY)
                            unTpdToast(kirjausId.text)
                            //console.log("hiiri " + valittu + " - " + mouseY + " tietue " + tietue.y)
                            mouse.accepted = true
                        }
                        onPressAndHold: {
                            valittu = kirjaukset.indexAt(mouseX, tietue.y + mouseY)
                            tietue.openMenu()
                            mouse.accepted = true
                        }
                    }

                    Label {
                        id: peukkuja
                        text: nostoja
                        color: Theme.secondaryHighlightColor
                    }

                    Rectangle {
                        height: 1
                        width: Theme.paddingLarge*2
                        color: "transparent"
                    }

                    IconButton {
                        id: kommentti
                        icon.source: "image://theme/icon-m-chat"
                        highlighted: osallistunut
                        height: kommentteja.height*1.5
                        //enabled: false
                        propagateComposedEvents: true
                        onClicked: {
                            //highlighted = !highlighted
                            valittu = kirjaukset.indexAt(mouseX, tietue.y + mouseY)
                            //console.log("oo " + valittu + ", hiiri " + mouseX.toFixed(1)
                            //            + " " + mouseY.toFixed(1) + " " +
                            //            (tietue.y).toFixed(1) )
                            unTpdJuttele()
                            mouse.accepted = true
                        }
                        onPressAndHold: {
                            mouse.accepted = true
                            valittu = kirjaukset.indexAt(mouseX, tietue.y + mouseY)
                            tietue.openMenu()
                        }

                        //anchors.top: (peukku.height > peukkuja.height) ? peukku.bottom : peukkuja.bottom
                        //anchors.left: peukku.left
                    }

                    Label {
                        id: kommentteja
                        text: juttuja
                        color: Theme.secondaryHighlightColor
                        //anchors.top: (peukku.height > peukkuja.height) ? peukku.bottom : peukkuja.bottom
                        //anchors.left: peukkuja.left
                    }


                }


            }

        }

    }

}
