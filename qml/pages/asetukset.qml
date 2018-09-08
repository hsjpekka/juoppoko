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
        day2text.text = (massa*vetta*5.5*0.5).toFixed(0)

        // alempi naisten kohtuukäytöstä 7 annosta viikossa
        vk1txt.text = (massa*vetta*2.3).toFixed(0)
        day1text.text = (massa*vetta*2.3*0.5).toFixed(0)

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

            MenuItem {
                text: qsTr("set up unTappd")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("unTpKayttaja.qml"))
                }
            }


        }

        VerticalScrollDecorator {}

        Column {
            id: column

            DialogHeader {
                id: otsikko
                title: qsTr("My measures")
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
                    onTextChanged: {
                        massa = massaTxt.text*1
                        if (!oletusRajat.checked)
                            laskeRajat()
                    }
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
                    //onTextChanged: kunto = parseFloat(kuntoTxt.text/100)
                    onTextChanged: {
                        kunto = kuntoTxt.text/100
                        if (!oletusRajat.checked)
                            laskeRajat()
                    }
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
                    text: (palonopeus*0.7894*kuntoTxt.text/100*massaTxt.text).toFixed(1) + " g/h"
                    //text: (palonopeus*0.7894*parseFloat(kuntoTxt.text/100)*parseInt(massaTxt.text)).toFixed(1) + " g/h"
                    label: (palonopeus*kuntoTxt.text/100*massaTxt.text).toFixed(1) + " ml/h"
                    //label: (palonopeus*parseFloat(kuntoTxt.text/100)*parseInt(massaTxt.text)).toFixed(1) + " ml/h"
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
                    onTextChanged: {
                        vetta = nesteTxt.text/100
                        if (!oletusRajat.checked)
                            laskeRajat()
                    }
                    //onAccepted: {
                    //    nesteprosentti = kehonnesteprosentti.text
                    //}
                    //horizontalAlignment: textAlignment
                }

            } //nesteprosentti

            TextSwitch {
                id: oletusRajat
                checked: true
                text: checked ? qsTr("set limits") : qsTr("calculate limits")
                onClicked: {
                    if (!checked)
                        laskeRajat()
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row { //promilleraja 1
                //visible: oletusRajat.checked

                TextField {
                    id: ap23
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower limit")
                    label: qsTr("BAC - [‰]")
                }

                TextField {
                    id: prom1txt
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: Number(prom10).toLocaleString(Qt.locale())//prom10.toFixed(2)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    //onTextChanged: prom1 = parseFloat(text)
                    onTextChanged: prom1 = Number.fromLocaleString(Qt.locale(),text)
                }

            }

            Row { //promilleraja 2
                //visible: oletusRajat.checked

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper limit")
                    label: qsTr("BAC - [‰]")
                }

                TextField {
                    id: prom2txt
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: Number(prom20).toLocaleString(Qt.locale())
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    onTextChanged: prom2 = Number.fromLocaleString(Qt.locale(),text)
                }

            }

            Row { //paivaraja 1
                //visible: oletusRajat.checked

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower daily limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: day1text
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: paiva10
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 500}
                    onTextChanged: paiva1 = text*1
                }

            } // */

            Row { //paivaraja 2
                //visible: oletusRajat.checked

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper daily limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: day2text
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: paiva20
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 500}
                    onTextChanged: paiva2 = day2text.text
                }

            }
            // */

            Row { //viikkoraja 1
                //visible: oletusRajat.checked

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower weekly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vk1txt
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: viikko10
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 500}
                    onTextChanged: viikko1 = vk1txt.text
                }

            }

            Row { //viikkoraja 2
                //visible: oletusRajat.checked

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper weekly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vk2txt
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: viikko20
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 3500}
                    onTextChanged: viikko2 = vk2txt.text
                }

            }

            Row { //vuosiraja 1
                //visible: oletusRajat.checked

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("lower yearly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vs1txt
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: vuosi10
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 20000}
                    onTextChanged: vuosi1 = vs1txt.text
                }

            }

            Row { //vuosiraja 2
                //visible: oletusRajat.checked

                TextField {
                    width: leveysVasen*sivu.width
                    readOnly: true
                    text: qsTr("upper yearly limit")
                    label: qsTr("alcohol [ml]")
                }

                TextField {
                    id: vs2txt
                    width: leveysOikea*sivu.width
                    readOnly: !oletusRajat.checked
                    text: vuosi20
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 50000}
                    onTextChanged: vuosi2 = vs2txt.text
                }

            }

        }// column

    }

    Component.onCompleted: {
        alkutoimet()
    }
}
