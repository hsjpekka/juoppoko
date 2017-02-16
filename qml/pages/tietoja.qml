import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    function tyhjennaAsetukset() {

    }

    TextArea {
        readOnly: true
        anchors.fill: parent
        //width: page.width
        wrapMode: TextEdit.WordWrap

        text: "Juoppoko 0.1" + "\n \n" + qsTr("The default limits are from ") +
              "http://www.paihdelinkki.fi/fi/tietopankki/tietoiskut/alkoholi/liikakayton-tunnistaminen \n" +
              qsTr("according to which a safe limit for women is 7 portions weekly, for men 14. Limit of increased risk is 16 portions for women and 24 for men. ") +
              qsTr("Here the values are expected to depend only on the amount of water in body, not on sex.") +
              "\n \n" +
              qsTr("Alcohol burning rate is also from the same site.") + "\n \n" +
              qsTr("Blood alcohol content above 4.0 ‰ may cause coma or be deadly. To discourage competing, shown alcohol content is limited to 3.0 ‰.")
    }

}


