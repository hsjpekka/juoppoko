import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: sivu
    property string paihdelinkki: "http://www.paihdelinkki.fi/fi/tietopankki/tietoiskut/alkoholi/liikakayton-tunnistaminen \n"

    SilicaFlickable {
        anchors.fill: sivu
        height: sivu.height
        contentHeight: sarake.height

        VerticalScrollDecorator {}

        Column {
            id: sarake

            PageHeader {
                title: "Juoppoko 2.0"
            }

            TextArea {
                readOnly: true
                //anchors.fill: parent
                width: sivu.width
                wrapMode: TextEdit.WordWrap

                text: qsTr("The default limits are from \n %1 according to which a safe limit for women is 7 portions weekly, for men 14. The limit of increased risk is 16 portions for women and 24 for men. ").arg(paihdelinkki) +
                      qsTr("Here the values are expected to depend only on the amount of water in body, not on sex.") +
                      "\n \n" +
                      qsTr("Alcohol burning rate is also from the same site.") + "\n \n" +
                      qsTr("High blood alcohol content may cause coma or be deadly. To discourage competing, shown alcohol content is limited to 3.0 ‰.") + "\n \n" +
                      qsTr("Info about UnTappd: ") + "www.untappd.com"
            }
        }
    }

}
