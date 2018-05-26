import QtQuick 2.0
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../scripts/unTap.js" as UnTpd

Dialog {
    id: sivu
    anchors.leftMargin: Theme.paddingLarge
    anchors.rightMargin: Theme.paddingLarge

    //property string shout: ""
    //property string olut: ""
    //property int olutId: 0
    //property int tahtia: 0
    property int baariId: 0
    property string baari: ""
    property bool face: false
    property bool foursq: false
    property bool tweet: false

    Position {
        id: sijainti
    }

    PositionSource {
        id: paikkatieto
    }

    function printableMethod(method) {
        if (method === PositionSource.SatellitePositioningMethods)
            return "Satellite";
        else if (method === PositionSource.NoPositioningMethods)
            return "Not available"
        else if (method === PositionSource.NonSatellitePositioningMethods)
            return "Non-satellite"
        else if (method === PositionSource.AllPositioningMethods)
            return "Multiple"
        return "source error";
    }

    Column {
        id: column
        anchors.fill: parent

        DialogHeader {
            title: qsTr("check-in details")
        }

        /*
        TextField {
            text: olut
            placeholderText: qsTr("beer")
            readOnly: true
        }

        TextArea {
            id: muuta
            text: shout
            width: column.width
            height: font.pixelSize*4
            placeholderText: qsTr("comment")
            label: qsTr("comment")
        } // */

        TextField {
            id: asema
            text: qsTr("location") + ", " + qsTr("lat") + ": " + sijainti.coordinate.latitude +
                  ", " + qsTr("long") + ": " + sijainti.coordinate.longitude +
                  ", " + qsTr("alt") + ": " + sijainti.coordinate.altitude
            label: printableMethod(paikkatieto.supportedPositioningMethods) +
                   " " + sijainti.latitudeValid + " " + sijainti.longitudeValid +
                   " " + sijainti.altitudeValid
            readOnly: true
        }

        TextField {
            id: juomala
            placeholderText: qsTr("pub")
            readOnly: true
            visible: false
        }

        TextSwitch {
            id: facebook
            checked: false
            text: checked ? qsTr("post to facebook") : qsTr("not to facebook")
        }

        TextSwitch {
            id: twitter
            checked: false
            text: checked ? qsTr("post to twitter") : qsTr("no tweeting")
        }

        TextSwitch {
            id: foursquare
            checked: false
            text: checked ? qsTr("post to foursquare") : qsTr("not to foursquare")
        }

    }

    onAccepted: {
        //shout = muuta.text
        UnTpd.postFacebook = facebook.checked
        UnTpd.postTwitter = twitter.checked
        UnTpd.postFoursquare = foursquare.checked
        console.log("untpcheckin " + arvostelu1.width)
    }

    Component.onCompleted: {
        //asema.label = printableMethod(paikkatieto.supportedPositioningMethods)
    }
}
