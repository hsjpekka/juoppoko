import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: sivu
    property string baari: ""
    property int barId: 0

    function haeBaari(haku) {
        var xhttp = new XMLHttpRequest();

        if (haku.length >= 3) {
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width
            anchors.fill: parent

            DialogHeader {
                title: qsTr("Beer provider")
            }

            SearchField {
                id: etsiBaari
                placeholderText: qsTr("venue")
                onTextChanged: {
                    haeBaari(text)
                }
            }
        }
    }

    onAccepted: {
        baari = etsiBaari.text
    }
}
