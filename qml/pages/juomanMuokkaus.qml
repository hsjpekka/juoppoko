/*
  Published under New BSD license
  Copyright (C) 2017 Pekka Marjamäki <pekka.marjamaki@iki.fi>

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may
     be used to endorse or promote products derived from this software without specific
     prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.freedesktop.contextkit 1.0
import "../scripts/unTap.js" as UnTpd

Dialog {
    id: sivu    

    property date aika
    property bool alkutoimet: true
    property int i1: 0
    property string juomanKuvaus
    property real maara
    property int maaraDesimaaleja: 0
    property real maaraMuutos : 1
    property real mlLisays
    property string nimi
    property string nimi0
    property int olutId: 0
    property real ozImp: 28.413
    property real ozUs: 29.574
    property real pintUs: 16*ozUs
    property real pintImp: 20*ozImp
    property real prosLisays
    property int tahtia: 0
    property int tauko0 : 0.8*1000 // ms
    property int tauko: tauko0
    property int tilavuusMitta//: 1 // juoman tilavuusyksikkö, 1 = ml, 2 = us oz, 3 = imp oz, 4 = imp pint, 5 = us pint
    property real vahvuus
    property real yksikko: 1.0
    property string yksikkoTunnus: " ml"

    function asetaYksikotMl() {
        maara = maara*yksikko
        yksikko = 1
        yksikkoTunnus = " mL"
        maaraMuutos = 1
        maaraDesimaaleja = 0
        tilavuusMitta = 1
        return
    }

    function asetaYksikotImpOz() {
        maara = maara*yksikko/ozImp
        yksikko = ozImp
        yksikkoTunnus = " oz"
        maaraMuutos = 0.1
        maaraDesimaaleja = 1
        tilavuusMitta = 3
        return
    }

    function asetaYksikotImpPint() {
        maara = maara*yksikko/pintImp
        yksikko = pintImp
        yksikkoTunnus = " pt"
        maaraMuutos = 0.1
        maaraDesimaaleja = 1
        tilavuusMitta = 4
        return
    }

    function asetaYksikotUsOz() {
        maara = maara*yksikko/ozUs
        yksikko = ozUs
        yksikkoTunnus = " oz"
        maaraMuutos = 0.1
        maaraDesimaaleja = 1
        tilavuusMitta = 2
        return
    }

    function asetaYksikotUsPint() {
        maara = maara*yksikko/pintUs
        yksikko = pintUs
        yksikkoTunnus = " pt"
        maaraMuutos = 0.1
        maaraDesimaaleja = 1
        tilavuusMitta = 5
        return
    }

    function avaaUnTappdHaku() {
        var dialog = pageStack.push(Qt.resolvedUrl("unTpOluet.qml"),{
            "olut": juoma.text, "vahvuus": vahvuus} )
        dialog.accepted.connect( function() {
            juoma.text = dialog.olut
            nimi0 = dialog.olut
            vahvuus = dialog.vahvuus
            olutId = dialog.olutId
            valitunEtiketti.source = UnTpd.oluenEtiketti
            //tahtiaRivi.visible = ( > 0) ? true : false
            //console.log("avaaUnTappd: olutId " + olutId)
        })

        return
    }

    function laskeMuutos(mX, x0, Lx){ // mouseX, mouseArea.x, mouseArea.width
        var arvo = 0, dx1
        dx1 = mX-x0
        if (dx1 < 0.17*Lx){
            arvo = -100
            tauko = tauko0*(0.3 + 0.8*dx1/(0.17*Lx))
        } else if (dx1 < 0.34*Lx){
            arvo = -10
            tauko = tauko0*(0.3 + 0.8*(dx1-0.17*Lx)/(0.17*Lx))
        } else if (dx1 < 0.5*Lx){
            arvo = -1
            tauko = tauko0*(0.3 + 0.8*(dx1-0.34*Lx)/(0.16*Lx))
        } else if (dx1 < 0.66*Lx){
            arvo = 1
            tauko = tauko0*(1 - 0.8*(dx1-0.5*Lx)/(0.16*Lx))
        } else if (dx1 < 0.83*Lx){
            arvo = 10
            tauko = tauko0*(1 - 0.8*(dx1-0.66*Lx)/(0.17*Lx))
        } else {
            arvo = 100
            tauko = tauko0*(1 - 0.8*(dx1-0.83*Lx)/(0.17*Lx))
        }

        return arvo
    }

    function muutaTilavuus() {
        var tarkkuus = 0.005

        maara = Math.floor(maara/mlLisays + tarkkuus)*mlLisays
        maara = maara + mlLisays
        if (maara < 0)
            maara = 0

        //maaranNaytto.value = maara.toFixed(1) + yksikkoTunnus
        maaranNaytto.text = maara.toFixed(maaraDesimaaleja) // + yksikkoTunnus

        return
    }

    function muutaProsentit() {
        var tarkkuus = 0.005
        vahvuus = Math.floor(vahvuus/prosLisays + tarkkuus)*prosLisays // floor(34.999999995 + tarkkuus) = floor(35.00000001 + tarkkuus)
        vahvuus = vahvuus + prosLisays
        if (vahvuus < 0)
            vahvuus = 0
        if (vahvuus > 100)
            vahvuus = 100

        prosenttienNaytto.value = vahvuus.toFixed(1) + " vol-%"

        return
    }

    ContextProperty {
        id: networkOnline
        key: 'Internet.NetworkState'
    }

    Timer {
        id: mlAjastin
        interval: tauko
        running: false
        repeat: true
        onTriggered: {
            muutaTilavuus()
        }
    }

    Timer {
        id: prosAjastin
        interval: tauko
        running: false
        repeat: true
        onTriggered: {
            muutaProsentit()
        }
    }

    SilicaFlickable {
        //anchors.fill: parent
        width: sivu.width
        height: sivu.height
        //height: column.height
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width
            //anchors.fill: parent

            DialogHeader {
                title: qsTr("Drink")
            } // */

            Row { //etsi untappedistä
                x: Theme.paddingLarge
                spacing: Theme.paddingLarge

                Image {
                    id: valitunEtiketti
                    source: "./tuoppi.png"
                    width: Theme.fontSizeMedium*3
                    height: width
                }

                Button {
                    id: avaaUnTappd
                    text: qsTr("search UnTappd")
                    onClicked: {
                        if (networkOnline.value === 'connected') {
                            /*var dialog = pageStack.push(Qt.resolvedUrl("unTpOluet.qml"),{
                                "olut": juoma.text, "vahvuus": vahvuus} )
                            dialog.accepted.connect( function() {
                                juoma.text = dialog.olut
                                nimi0 = dialog.olut
                                vahvuus = dialog.vahvuus
                                olutId = dialog.olutId
                                valitunEtiketti.source = UnTpd.oluenEtiketti
                                //tahtiaRivi.visible = ( > 0) ? true : false
                                //console.log("avaaUnTappd: olutId " + olutId)
                            })//*/
                            avaaUnTappdHaku()
                        } else {
                            var dialog = pageStack.push(Qt.resolvedUrl("eiVerkkoa.qml") )
                            dialog.accepted.connect( avaaUnTappdHaku )
                        }
                    }

                    }
                //}
            }

            Row {
                TextField {
                    id: juoma
                    text: nimi0
                    labelVisible: false
                    placeholderText: qsTr("Drink")
                    readOnly: false
                    width: sivu.width - tyhjennaHaku.width - sivu.anchors.leftMargin - sivu.anchors.rightMargin
                    onTextChanged: {
                        if (!alkutoimet)
                            olutId = 0
                        //tahtiaRivi.visible = false
                        //console.log("nimi muuttunut")
                    }
                    EnterKey.onClicked: tahtiaRivi.focus = true
                }

                IconButton {
                    id: tyhjennaHaku
                    icon.source: "image://theme/icon-m-clear"
                    //width: Theme.fontSizeMedium*3
                    onClicked: {
                        //juoma.text = ""
                        nimi0 = ""
                        olutId = 0
                        //tahtiaRivi.visible = false
                        valitunEtiketti.source = "tuoppi.png"
                    }
                }

            }

            Row { //arvostelu
                id: tahtiaRivi
                visible: (olutId > 0) ? true : false
                x: Theme.paddingLarge
                spacing: (sivu.width - 2*x - 5*arvostelu1.width - 4*arvostelu15.width)/8

                IconButton {
                    id: arvostelu1
                    highlighted: (tahtia >= 1) ? true : false
                    icon.source: (tahtia >= 1) ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                    onClicked: {
                        if (tahtia == 1)
                            tahtia = 0
                        else
                            tahtia = 1
                    }
                }
                IconButton {
                    id: arvostelu15
                    highlighted: (tahtia >= 2) ? true : false
                    icon.source: "image://theme/icon-s-favorite"
                    onClicked: {
                        if (tahtia == 2)
                            tahtia = 0
                        else
                            tahtia = 2
                    }
                }
                IconButton {
                    id: arvostelu2
                    highlighted: (tahtia >= 3) ? true : false
                    icon.source: (tahtia >= 3) ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                    onClicked: {
                        if (tahtia == 3)
                            tahtia = 0
                        else
                            tahtia = 3

                    }
                }
                IconButton {
                    id: arvostelu25
                    highlighted: (tahtia >= 4) ? true : false
                    icon.source: "image://theme/icon-s-favorite"
                    onClicked: {
                        if (tahtia == 4)
                            tahtia = 0
                        else
                            tahtia = 4

                    }
                }
                IconButton {
                    id: arvostelu3
                    highlighted: (tahtia >= 5) ? true : false
                    icon.source: (tahtia >= 5) ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                    onClicked: {
                        if (tahtia == 5)
                            tahtia = 0
                        else
                            tahtia = 5

                    }
                }
                IconButton {
                    id: arvostelu35
                    highlighted: (tahtia >= 6) ? true : false
                    icon.source: "image://theme/icon-s-favorite"
                    onClicked: {
                        if (tahtia == 6)
                            tahtia = 0
                        else
                            tahtia = 6
                    }
                }
                IconButton {
                    id: arvostelu4
                    highlighted: (tahtia >= 7) ? true : false
                    icon.source: (tahtia >= 7) ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                    onClicked: {
                        if (tahtia == 7)
                            tahtia = 0
                        else
                            tahtia = 7

                    }
                }
                IconButton {
                    id: arvostelu45
                    highlighted: (tahtia >= 8) ? true : false
                    icon.source: "image://theme/icon-s-favorite"
                    onClicked: {
                        if (tahtia == 8)
                            tahtia = 0
                        else
                            tahtia = 8

                    }
                }
                IconButton {
                    id: arvostelu5
                    highlighted: (tahtia == 9) ? true : false
                    icon.source: (tahtia >= 9) ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                    onClicked: {
                        if (tahtia == 9)
                            tahtia = 0
                        else
                            tahtia = 9

                    }
                }

            } //arvostelu

            Row { // time

                spacing: Theme.paddingSmall
                x: 0.5*(sivu.width - kello.width - paivaotsikko.width - spacing)

                ValueButton {
                    id: kello

                    function openTimeDialog() {
                        var dialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                                    hourMode: DateTime.TwentyFourHours,
                                    hour: aika.getHours(),
                                    minute: aika.getMinutes()
                        })

                        dialog.accepted.connect(function() {
                                aika = new Date(aika.getFullYear(),aika.getMonth(),aika.getDate(),dialog.hour,
                                               dialog.minute,0,0)
                                value = aika.toLocaleTimeString(Qt.locale(),"HH:mm")
                                aika.setMinutes(dialog.minute)
                        })
                    }


                    // label: "clock"
                    width: Theme.fontSizeSmall*6 //ExtraSmall*6 //font.pixelSize*5 //
                    value: aika.toLocaleTimeString(Qt.locale(),"HH:mm")
                    valueColor: Theme.primaryColor
                    //readOnly: true
                    onClicked: openTimeDialog()
                }

                ValueButton {
                    id: paivaotsikko
                    property date selectedDate

                    function openDateDialog() {
                        var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                                    date: aika
                                 })

                        dialog.accepted.connect(function() {
                            selectedDate = dialog.date
                            aika = new Date(selectedDate.getFullYear(),selectedDate.getMonth(),selectedDate.getDate(),
                                           aika.getHours(), aika.getMinutes(), 0, 0)
                            value = aika.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                        })
                    }

                    //label: "Date"
                    value: aika.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    valueColor: Theme.primaryColor
                    //text: aika.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    width: Theme.fontSizeSmall*8 //font.pixelSize*8
                    //readOnly: true
                    //font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: openDateDialog()
                }//

            }

            Row { // määrä
                spacing: Theme.paddingMedium
                x: 0.5*(sivu.width - maaraLabel.width - maaranNaytto.width - yksikonValinta.width - 2*spacing) //
                //padding: Theme.paddingMedium

                Label {
                    id: maaraLabel
                    text: qsTr("volume")
                    color: Theme.secondaryHighlightColor //Theme.highlightColor
                    //width: font.pixelSize*4
                    //anchors.verticalCenterOffset: 4
                    height: yksikonValinta.height
                    verticalAlignment: Text.AlignVCenter
                }

                Label {
                    id: maaranNaytto
                    //width: font.pixelSize*3 //ExtraSmall*6
                    text: maara.toFixed(maaraDesimaaleja)// + yksikkoTunnus
                    color: Theme.highlightColor
                    //anchors.verticalCenterOffset: 0.3*font.pixelSize
                    height: yksikonValinta.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                ComboBox { //tilavuusyksikkö
                    id: yksikonValinta
                    //width: sivu.width - sivu.anchors.leftMargin - sivu.anchors.rightMargin - maaraLabel.width - maaranNaytto.width - 2*Theme.paddingMedium
                    width: Theme.fontSizeSmall*7// font.pixelSize*8
                    //height: Theme.fontSizeSmall
                    valueColor: Theme.primaryColor

                    menu: ContextMenu {
                        //id: drinkMenu
                        MenuItem { text: "mL" }
                        MenuItem { text: "oz (US)" }
                        MenuItem { text: "oz (EN)" }
                        MenuItem { text: "pint (EN)" }
                        MenuItem { text: "pint (US)" }
                    }

                    currentIndex: 0

                    onCurrentIndexChanged: {
                        switch (currentIndex) { // juoman tilavuusyksikkö, 1 = ml, 2 = us oz, 3 = imp oz, 4 = imp pint, 5 = us pint
                        case 0:
                            asetaYksikotMl()
                            break
                        case 1:
                            asetaYksikotUsOz()
                            break
                        case 2:
                            asetaYksikotImpOz()
                            break
                        case 3:
                            asetaYksikotImpPint()
                            break
                        case 4:
                            asetaYksikotUsPint()
                            break
                        }

                        //yksikkoTxt.text = yksikko + " mL"
                        //maaranNaytto.value = maara.toFixed(maaraDesimaaleja) + yksikkoTunnus
                        maaranNaytto.text = maara.toFixed(maaraDesimaaleja) // + yksikkoTunnus

                        //prosenttienNaytto.value = vahvuus.toFixed(1) + " vol-%"
                    }

                } //combobox

            }

            Item { // määrän muutos
                width: sivu.width
                height: txtTilavuusMuutos1.height

                Row {
                    x: sivu.anchors.leftMargin > 0 ? sivu.anchors.leftMargin : Theme.paddingLarge
                    spacing: (sivu.width - 2*x - 6*txtTilavuusMuutos1.width)/5

                    Label {
                        id: txtTilavuusMuutos1
                        text: "<<<"
                        font.pixelSize: Theme.fontSizeLarge
                        width: font.pixelSize*2
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        //id: txtTilavuusMuutos2
                        text: "<<"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtTilavuusMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        //id: txtTilavuusMuutos3
                        text: "<"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtTilavuusMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        //id: txtTilavuusMuutos4
                        text: ">"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtTilavuusMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        //id: txtTilavuusMuutos5
                        text: ">>"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtTilavuusMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        //id: txtTilavuusMuutos6
                        text: ">>>"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtTilavuusMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                }// volumeChange */

                MouseArea {
                    anchors.fill: parent
                    width: sivu.width
                    height: txtTilavuusMuutos1.height
                    preventStealing: true

                    onEntered: {
                        mlLisays = laskeMuutos(mouseX, x, width)*maaraMuutos
                        muutaTilavuus()
                        mlAjastin.running = true
                        mlAjastin.start
                    }
                    onExited: {
                        mlAjastin.running = false
                        mlAjastin.stop
                    }

                    onPositionChanged: {
                        mlLisays = laskeMuutos(mouseX, x, width)*maaraMuutos
                    }

                }

            }

            DetailItem {
                id: prosenttienNaytto
                label: qsTr("alcohol")
                value: vahvuus.toFixed(1) + " vol-%"
            }

            Item { // prosenttien muutos
                width: sivu.width
                height: txtProsMuutos1.height

                Row { //tilavuus
                    x: sivu.anchors.leftMargin > 0 ? sivu.anchors.leftMargin : Theme.paddingLarge
                    spacing: (sivu.width - 2*x - 6*txtProsMuutos1.width)/5

                    Label {
                        id: txtProsMuutos1
                        text: "<<<"
                        font.pixelSize: Theme.fontSizeLarge
                        width: font.pixelSize*2
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: "<<"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtProsMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: "<"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtProsMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: ">"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtProsMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: ">>"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtProsMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: ">>>"
                        font.pixelSize: Theme.fontSizeLarge
                        width: txtProsMuutos1.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true

                    onEntered: {
                        prosLisays = laskeMuutos(mouseX, x, width)/10
                        muutaProsentit()
                        prosAjastin.running = true
                        prosAjastin.start
                    }
                    onExited: {
                        prosAjastin.running = false
                        prosAjastin.stop
                    }
                    onPositionChanged: {
                        prosLisays = laskeMuutos(mouseX, x, width)/10
                    }

                }

            }// alcChange */

            TextField {
                id: kuvaus
                text: juomanKuvaus
                readOnly: false
                width: parent.width
                label: (olutId > 0) ? qsTr("shout!") : qsTr("some notes?")
                placeholderText: label
            }

        }//column
    }

    Component.onCompleted: {
        if (tilavuusMitta == 2) { // juoman tilavuusyksikkö, 1 = ml, 2 = us oz, 3 = imp oz, 4 = imp pint, 5 = us pint
            asetaYksikotUsOz()
            yksikonValinta.currentIndex = tilavuusMitta - 1
        } else if (tilavuusMitta == 3) {
            asetaYksikotImpOz()
            yksikonValinta.currentIndex = tilavuusMitta - 1
        } else if (tilavuusMitta == 4) {
            asetaYksikotImpPint()
            yksikonValinta.currentIndex = tilavuusMitta - 1
        } else if (tilavuusMitta == 5) {
            asetaYksikotUsPint()
            yksikonValinta.currentIndex = tilavuusMitta - 1
        } else
            asetaYksikotMl()

        //console.log("olutId + tahtia: " + olutId + " " + tahtia + " " + nimi)

        //if (olutId > 0)
        //    tahtiaRivi.visible = true

        valitunEtiketti.source = UnTpd.oluenEtiketti
        nimi0 = nimi

        alkutoimet = false

        console.log("oluen id " + olutId)

    }

    onDone: {
        if (result == DialogResult.Accepted) {
            nimi = juoma.text
            juomanKuvaus = kuvaus.text
            if (nimi0 != nimi){ // nimi0 = joko juodut-tietokantaan talletettu tai untappedista haettu
                console.log("nimi muuttunut")
                olutId = 0
                UnTpd.setBeer(olutId)
            }

            if (olutId > 0)
                UnTpd.shout = kuvaus.text
            maara = maara*yksikko
        }
    }

}
