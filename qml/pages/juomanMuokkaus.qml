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

Dialog {
    id: sivu

    property date aika
    property string nimi
    property string juomanKuvaus
    property int maara
    property real vahvuus
    property int mlLisays
    property real prosLisays
    property int tauko : 1.0*1000 // ms
    property int i1: 0
    //anchors.fill: parent

    function laskeMuutos(mX, x0, Lx){ // mouseX, mouseArea.x, mouseArea.width
        var arvo = 0, dx1
        dx1 = mX-x0
        if (dx1 < 0.17*Lx){
            arvo = -100
        } else if (dx1 < 0.34*Lx){
            arvo = -10
        } else if (dx1 < 0.5*Lx){
            arvo = -1
        } else if (dx1 < 0.66*Lx){
            arvo = 1
        } else if (dx1 < 0.83*Lx){
            arvo = 10
        } else
            arvo = 100

        return arvo
    }

    function muutaTilavuus() {
        maara = Math.floor(maara/mlLisays)*mlLisays
        maara = maara + mlLisays
        if (maara < 0)
            maara = 0

        maaranNaytto.value = maara + " ml"

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

        prosenntienNaytto.value = vahvuus.toFixed(1) + " vol-%"

        return
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
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width

            DialogHeader {
                title: qsTr("Juoma")
            } // */

            Row {
                //anchors.fill: parent

                ComboBox {
                    //id: juoma
                    width: sivu.width*0.4

                    menu: ContextMenu {
                        //id: drinkMenu
                        MenuItem { text: qsTr("-juomia-") }
                        MenuItem { text: qsTr("olut") }
                        MenuItem { text: qsTr("viini") }
                        MenuItem { text: qsTr("cocktail") }
                        MenuItem { text: qsTr("paukku") }
                    }

                    currentIndex: 0

                    onCurrentIndexChanged: {
                        switch (currentIndex) {
                        case 0:
                            break
                        case 1:
                            juoma.text = qsTr("olut")
                            maara = 500
                            vahvuus = 4.7
                            break
                        case 2:
                            juoma.text = qsTr("viini")
                            maara = 180
                            vahvuus = 13
                            break
                        case 3:
                            juoma.text = qsTr("cocktail")
                            maara = 250
                            vahvuus = 6.4
                            break
                        case 4:
                            juoma.text = qsTr("paukku")
                            maara = 40
                            vahvuus = 40
                            break
                        }

                        maaranNaytto.value = maara + " ml"

                        prosenntienNaytto.value = vahvuus.toFixed(1) + " vol-%"
                    }

                } //combobox

                TextField {
                    id: juoma
                    text: nimi
                    readOnly: false
                    width: sivu.width*0.4
                    //anchors.leftMargin: Theme.paddingLarge
                    //anchors.rightMargin: Theme.paddingLarge
                    //x: drink.x + drink.width + parent.spacing
                }

            } //row


            Row { // time

                spacing: Theme.paddingSmall

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
                    width: Theme.fontSizeExtraSmall*6
                    value: aika.toLocaleTimeString(Qt.locale(),"HH:mm")
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
                    //text: aika.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    width: sivu.width - kello.width - 3*Theme.paddingSmall
                    //readOnly: true
                    //font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: openDateDialog()
                }//
            }

            DetailItem {
                id: maaranNaytto
                label: qsTr("tilavuus")
                value: maara + " ml"
            }

            Label {
                //id: volumeChange
                //width: volumeLabel.width
                text: "<<<    <<     <         >     >>    >>>"
                font.pixelSize: Theme.fontSizeLarge
                //anchors.fill: parent
                anchors.horizontalCenter: parent.horizontalCenter

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true

                    onEntered: {
                        mlLisays = laskeMuutos(mouseX, x, width)
                        muutaTilavuus()
                        mlAjastin.running = true
                        mlAjastin.start
                    }
                    onExited: {
                        mlAjastin.running = false
                        mlAjastin.stop
                    }

                    onPositionChanged: {
                        mlLisays = laskeMuutos(mouseX, x, width)
                    }

                }

            }// volumeChange */

            DetailItem {
                id: prosenntienNaytto
                label: qsTr("prosentteja")
                value: vahvuus.toFixed(1) + " vol-%"
            }

            Label {
                //id: alcChange
                //width: volumeLabel.width
                text: "<<<    <<     <         >     >>    >>>"
                font.pixelSize: Theme.fontSizeLarge
                //anchors.fill: parent
                anchors.horizontalCenter: parent.horizontalCenter

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
                placeholderText: qsTr("muuta?")
            }


        }//column
    }

    onDone: {
        if (result == DialogResult.Accepted) {
            nimi = juoma.text
            juomanKuvaus = kuvaus.text

        }
    }

}

