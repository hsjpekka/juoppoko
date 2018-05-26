import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: sivu
    property int massa0
    property int massa
    property real vetta0
    property real vetta
    property real kunto0
    property real kunto
    property real prom10 // promilleraja
    property real prom1
    property real prom20
    property real prom2
    property int paiva10 // ml-raja alkoholille päivässä
    property int paiva1
    property int paiva20
    property int paiva2
    property int viikko10 // ml-raja alkoholille viikossa
    property int viikko1
    property int viikko20
    property int viikko2
    property int vuosi10 // ml-raja alkoholille vuodessa
    property int vuosi1
    property int vuosi20
    property int vuosi2
    property real palonopeus

    property real leveysVasen: 0.7
    property real leveysOikea: 0.3

    property bool untapped: false

    function alkutoimet() {
        massa = massa0
        vetta = vetta0
        kunto = kunto0
        prom1 = prom10
        prom2 = prom20
        paiva1 = paiva10
        paiva2 = paiva20
        viikko1 = viikko10
        viikko2 = viikko20
        vuosi1 = vuosi10
        vuosi2 = vuosi20

        //nesteCombo( vetta )

        return
    }

    function palautaAlkuarvot() {

        nesteTxt.text = (vetta0*100).toFixed(0)
        vetta = vetta0
        kuntoTxt.text = (kunto0*100).toFixed(0)
        kunto = kunto0
        massaTxt.text = massa0
        massa = massa0

    }

    function laskeRajat(){
        // http://www.paihdelinkki.fi/fi/tietopankki/tietoiskut/alkoholi/liikakayton-tunnistaminen
        // miehillä riskiraja 24 annosta viikossa, naisilla 16
        // miesten keskipaino 86 kg, naisten 70 kg
        // 24 annosta ~ 364 ml,  85.5 kg * 75% * 5.5 = 352 ml
        // 16 annosta ~ 243 ml,  70.4 kg * 65% * 5.5 = 251 ml
        vk2txt.text = (massa*vetta*5.5).toFixed(0)

        // alempi naisten kohtuukäytöstä 7 annosta viikossa
        vk1txt.text = (massa*vetta*2.3).toFixed(0)

        vs1txt.text = (massa*vetta*2.3*52).toFixed(0)

        vs2txt.text = (massa*vetta*5.5*52).toFixed(0)

    }

    SilicaFlickable {
        id: ylaosa
        anchors.fill: parent
        height: sivu.height
        contentHeight: column.height


        PullDownMenu {
            MenuItem {
                text: qsTr("info")
                onClicked: pageStack.push(Qt.resolvedUrl("tietoja.qml"))

            }

            MenuItem {
                text: qsTr("restore")
                onClicked: palautaAlkuarvot()
            }
        }

        VerticalScrollDecorator {}

        Column {
            id: column

            DialogHeader {
                id: otsikko
                title: qsTr("Data")
            }

            Button {
                text: qsTr("set up unTappd")
                x: 0.5*sivu.width-0.5*width
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("unTpKirjautuminen.qml"))
                }
            }

            Row { //paino

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("weight")
                    label: "kg"
                }

                TextField {
                    id: massaTxt
                    width: leveysOikea*sivu.width
                    text: massa
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 1; top: 1000}
                    onTextChanged: massa = massaTxt.text*1
                }
            }

            Row { //maksa
                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lever %")
                    label: qsTr("100% - healthy")
                }

                TextField {
                    id: kuntoTxt
                    width: leveysOikea*sivu.width
                    text: (kunto*100).toFixed(0)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 1; top: 1000}
                    onTextChanged: kunto = parseFloat(kuntoTxt.text/100)
                }
            } //maksa

            Row { //palonopeus
                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("alcohol burning rate")
                    label: "1 g/h /10 kg"
                }

                TextField {
                    id: paloTxt
                    width: leveysOikea*sivu.width
                    readOnly: true
                    text: (palonopeus*0.7894*parseFloat(kuntoTxt.text/100)*parseInt(massaTxt.text)).toFixed(1) + " g/h"
                    label: (palonopeus*parseFloat(kuntoTxt.text/100)*parseInt(massaTxt.text)).toFixed(1) + " ml/h"
                }
            } //palonopeus

            Row { //nesteprosentti

                ComboBox {
                    id: cbNeste
                    width: leveysVasen*sivu.width
                    label: qsTr("body water content")

                    currentIndex: {
                        switch (parseInt(vetta*100)){
                        case 65:
                            currentIndex = 1
                            break
                        case 75:
                            currentIndex = 0
                            break
                        currentIndex = 2
                        }
                    }

                    onCurrentIndexChanged: {
                        switch (currentIndex) {
                        case 0:
                            nesteTxt.text = 75 //mies
                            nesteTxt.readOnly = true
                            break
                        case 1:
                            nesteTxt.text = 65 //nainen
                            nesteTxt.readOnly = true
                            break
                        case 2:
                            nesteTxt.readOnly = false
                            break
                        }
                    }

                    menu: ContextMenu {
                        MenuItem { text: qsTr("man") }
                        MenuItem { text: qsTr("woman") }
                        MenuItem { text: qsTr("other") }
                    }
                }

                TextField {
                    id: nesteTxt
                    //anchors.bottom: parent.bottom
                    //anchors.baselineOffset: 60
                    width: leveysOikea*sivu.width
                    validator: IntValidator {bottom: 1; top: 100}
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    readOnly: true
                    text: (vetta*100).toFixed(0)
                    onTextChanged: vetta = nesteTxt.text/100
                    //onAccepted: {
                    //    nesteprosentti = kehonnesteprosentti.text
                    //}
                    //horizontalAlignment: textAlignment
                }

            } //nesteprosentti

            Button {
                text: qsTr("calculate limits")
                onClicked: {
                    laskeRajat()
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row { //promilleraja 1

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower limit")
                    label: qsTr("BAC - [‰]")
                }

                TextField {
                    id: prom1txt
                    width: leveysOikea*sivu.width
                    text: prom10.toFixed(2)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    onTextChanged: prom1 = parseFloat(text)
                }


            }

            Row { //promilleraja 2

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper limit")
                    label: qsTr("BAC - [‰]")
                }

                TextField {
                    id: prom2txt
                    width: leveysOikea*sivu.width
                    text: prom20.toFixed(2)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    onTextChanged: prom2 = parseFloat(text)
                }

            }

            Row { //paivaraja 1

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower daily limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: day1text
                    width: leveysOikea*sivu.width
                    text: paiva10
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 500}
                    onTextChanged: paiva1 = day1text.text*1
                }

            } // */

            Row { //paivaraja 2

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper daily limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: day2text
                    width: leveysOikea*sivu.width
                    text: paiva20
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 500}
                    onTextChanged: paiva2 = day2text.text
                }

            }
            // */

            Row { //viikkoraja 1

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower weekly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vk1txt
                    width: leveysOikea*sivu.width
                    text: viikko10
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 500}
                    onTextChanged: viikko1 = vk1txt.text
                }

            }

            Row { //viikkoraja 2

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper weekly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vk2txt
                    width: leveysOikea*sivu.width
                    text: viikko20
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 3500}
                    onTextChanged: viikko2 = vk2txt.text
                }

            }

            Row { //vuosiraja 1

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower yearly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vs1txt
                    width: leveysOikea*sivu.width
                    text: vuosi10
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 20000}
                    onTextChanged: vuosi1 = vs1txt.text
                }

            }

            Row { //vuosiraja 2

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper yearly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vs2txt
                    width: leveysOikea*sivu.width
                    text: vuosi20
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 50000}
                    onTextChanged: vuosi2 = vs2txt.text
                }

            }

        }// column

        Component.onCompleted: {
            alkutoimet()
        }
    }
}
