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

        text: "Juoppoko 0.9" + "\n \n" + qsTr("Oletusrajat ovat sivulta ") +
                   "http://www.paihdelinkki.fi/fi/tietopankki/tietoiskut/alkoholi/liikakayton-tunnistaminen \n" +
                   qsTr("jonka mukaan kohtuukäytön raja on naisille 7 annosta viikossa ja miehille 14, ja riskiraja naisille 16 ja miehille 24 annosta. Arvojen oletetaan tässä ohjelmassa riippuvan vain kehon nesteen määrästä.") +
                   "\n \n" +
                   qsTr("Alkoholin palamisnopeus samalta sivustolta.")
    }

}


