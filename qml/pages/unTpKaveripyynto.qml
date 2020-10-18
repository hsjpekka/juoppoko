import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: sivu
    property alias tunnus: kayttis.text
    property alias nimi: kuka.text
    property alias kuva: naama.source

    Column {
        width: parent.width
        DialogHeader {
            title: qsTr("Send friend request?")
        }
        Image {
            id: naama
            source: ""
            height: Theme.iconSizeExtraLarge
            width: height
            anchors.horizontalCenter: parent.horizontalCenter
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (height < sivu.width)
                        parent.height = 2*height
                    else
                        parent.height = Theme.iconSizeExtraLarge
                }
            }
        }
        Label {
            id: kuka
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            color: Theme.highlightColor
        }
        Label {
            id: kayttis
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.highlightColor
            text: ""
        }
    }
}
