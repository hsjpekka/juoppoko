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
//import "../scripts/scripts.js" as Apuja

CoverBackground {
    id: kansi

    function naytaPromillet() {
        var pro = juoja.promilleja() //qqlaskePromillet(new Date().getTime())
        var str = ""

        str = pro.toFixed(2)  + " ‰"

        return str
    }

    function paivita() {
        promilleja.text = naytaPromillet()
        if (paaikkuna.juomari.rajalla === undefined) {
            kunnossa.text = ""
        } else if (paaikkuna.juomari.rajalla.getTime() < new Date().getTime()){
            kunnossa.text = ""
        } else {
            kunnossa.text = paaikkuna.juomari.promilleRaja + qsTr(" ‰ at ") + paaikkuna.juomari.rajalla.toLocaleTimeString(Qt.locale(),"HH:mm")
        }

        return
    }

    Image {
        id: taustakuva
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: parent.width*0.8
        height: width
        source: "tuoppi.png"
    }

    Label {
        id: promilleja
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.fontSizeLarge
        color: Theme.highlightColor
        //text: naytaPromillet() //paaikkuna.calculatePermille(new Date().getTime()).toFixed(2) + " ‰"
        //font.pixelSize: Theme.fontSizeMedium
    }

    Label {
        id: kunnossa
        anchors.top: promilleja.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.fontSizeLarge
        color: Theme.highlightColor
    }

    TextField {
        id: juoma
        anchors.top: kunnossa.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.fontSizeLarge
        horizontalAlignment: TextInput.AlignHCenter
        text: paaikkuna.nykyinenJuoma
        label: maara + " ml"
        width: parent.width*0.8
        readOnly: true
        property string maara: paaikkuna.nykyinenMaara
        property string pros: paaikkuna.nykyinenProsentti
    }

    Timer {
        id: updateTimer
        interval: 5*60*1000 // min*s*ms
        running: status === Cover.Active
        repeat: true
        onTriggered: {
            paivita()
            //console.log("kansi näkyy " + kansi.visible)
        }
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                var nyt = new Date().getTime()
                paaikkuna.uusiJuoma(nyt, nyt, parseInt(juoma.maara), parseFloat(juoma.pros),
                                    juoma.text, "", paaikkuna.olutId)
                paaikkuna.paivitaAjatRajoille()
                paivita()
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            //paivita()
        }
    }

    //Component.onCompleted: paivita()
    onStatusChanged: {
        if (status === Cover.Activating || status === Cover.Active) {
            paivita()
        }
    }
}
