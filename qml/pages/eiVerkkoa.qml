import QtQuick 2.0
import Sailfish.Silica 1.0
import org.freedesktop.contextkit 1.0

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    ContextProperty {
        id: networkOnline
        key: 'Internet.NetworkState'
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader{
                title: qsTr("No network")
            }

            Label {
                text: qsTr("You don't seem to have network connection. Internet.NetworkState %1").arg(networkOnline.value)
                color: Theme.highlightColor
                x: Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Label {
                text: qsTr("Do you want to try to search UnTappd anyway?")
                color: Theme.highlightColor
                x: Theme.horizontalPageMargin
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

        }
    }

}
