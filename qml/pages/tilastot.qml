import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/scripts.js" as Apuja

Dialog {
    id: sivu
    property int paiva: 24*60*60*1000 // ms
    property real tanaan: mlAikana(paiva) // paaikkuna.mlAikana(paiva)
    property real mlViikossa: mlAikana(7*paiva)
    property real mlKuussa: mlAikana(30*paiva) // paaikkuna.mlAikana(30*paiva)
    property int valittuKuvaaja // 0 - viikkokulutus, 1 - paivakulutus, oli 2 - paivaruudukko
    property int ryyppyVrk

    function mlAikana(jakso) { // jakso = ms nykyhetkestä (tai tulevasta juoman hetkestä)
        var nyt = new Date().getTime()
        var ml = 0
        var i = Apuja.juomienMaara() - 1

        if ( Apuja.juomanAika(i) > nyt)
            nyt = Apuja.juomanAika(i)

        while ( (i >=0 ) && (Apuja.juomanAika(i) >= nyt - jakso)){
            ml = ml + Apuja.juomanTilavuus(i)*Apuja.juomanVahvuus(i)/100
            i--
        }

        return ml
    }

    function mlVuodessa() {
        var nyt = new Date().getTime()
        var suhde = 1
        var i = Apuja.juomienMaara() - 1

        if (Apuja.juomanAika(i) > nyt)
            nyt = Apuja.juomanAika(i)

        if (Apuja.juomanAika(0) > nyt - 365*paiva){
            suhde = (nyt-Apuja.juomanAika(0))/(365*paiva)
            if (suhde < 1/52)
                suhde = 1/52

            txtVuodessa.font.italic = !txtVuodessa.font.italic
        }

        return mlAikana(365*paiva)/suhde

    }

    function kellonAika(hh,mm) {
        var mj

        if (hh < 10)
            mj = "0" + hh + ":"
        else
            mj = "" + hh + ":"

        if (mm <10 )
            mj = mj + "0" + mm
        else
            mj = mj + mm

        return mj
    }

    //
    function korostukset() {

        if (tanaan > paaikkuna.vrkRaja1) {
            txtPaivassa.color = Theme.highlightColor
            if( tanaan > paaikkuna.vrkRaja2 ) {
                txtPaivassa.font.bold = true
            }
        }

        if (mlViikossa > paaikkuna.vkoRaja1) {
            txtViikossa.color = Theme.highlightColor
            if( mlViikossa > paaikkuna.vkoRaja2 ) {
                txtViikossa.font.bold = true
            }
        }

        if (mlKuussa > paaikkuna.vkoRaja1/7*30 ) {
            txtKuussa.color = Theme.highlightColor
            if( mlKuussa > paaikkuna.vkoRaja2/7*30 ) {
                txtKuussa.font.bold = true
            }
        }

        if (mlVuodessa > paaikkuna.vsRaja1/7*30 ) {
            txtVuodessa.color = Theme.highlightColor
            if( mlVuodessa > paaikkuna.vsRaja2/7*30 ) {
                txtVuodessa.font.bold = true
            }
        }

        return
    }

    SilicaFlickable {
        height: sivu.height
        contentHeight: column.height
        width: sivu.width

        Column {
            id: column
            width: sivu.width

            DialogHeader {
                title: qsTr("Statistics")
            }

            SectionHeader {
                text: qsTr("chart")
            }

            ComboBox {
                label: qsTr("chart")
                x: parent.width*0.2

                menu: ContextMenu {
                    id: drinkMenu
                    //MenuItem { text: qsTr("day grid") }
                    MenuItem { text: qsTr("weekly consumption") }
                    MenuItem { text: qsTr("daily consumption") }
                }

                currentIndex: (valittuKuvaaja > 1.5) ? 0 : valittuKuvaaja

                onCurrentIndexChanged: {
                    switch (currentIndex) {
                    case 0:
                        valittuKuvaaja = 0
                        break
                    case 1:
                        valittuKuvaaja = 1
                        break
                    //case 2:
                      //  valittuKuvaaja = 2
                        //break
                    }
                }

            } //combobox

            SectionHeader {
                text: qsTr("last 24 h")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    id: txtPaivassa
                    color: Theme.primaryColor
                    text: tanaan.toFixed(1) + " ml"                    
                }

            } // päivässä


            SectionHeader {
                text: qsTr("last week")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    id: txtViikossa
                    color: Theme.primaryColor
                    text: mlViikossa.toFixed(1) + " ml"
                }

                Label {
                    color: Theme.primaryColor
                    text: qsTr(", equals to ")
                }

                Label {
                    color: Theme.primaryColor
                    text: (mlViikossa*52/1000).toFixed(1) + " l " + qsTr("in year")
                }

            } // viikossa


            SectionHeader {
                text: qsTr("last month")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    id: txtKuussa
                    color: Theme.primaryColor
                    text: mlKuussa.toFixed(1) + " ml"
                }

                Label {
                    color: Theme.primaryColor
                    text: qsTr(", equals to ")
                }

                Label {
                    color: Theme.primaryColor
                    text: (mlKuussa/30*365/1000).toFixed(1) + " l " + qsTr("in year")
                }


            } // kuussa

            SectionHeader {
                text: qsTr("in year")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    id: txtVuodessa
                    color: Theme.primaryColor
                    text: (mlVuodessa()/1000).toFixed(1) + " l"
                }

                Label {
                    //color: Theme.primaryColor
                    text: qsTr(", equals to ")
                }

                Label {
                    color: Theme.primaryColor
                    text: (mlVuodessa()/52).toFixed(1) + " ml " + qsTr("in week")
                }                

            } // vuodessa

            SectionHeader {
                text: qsTr("drinking day ends at")
            }

            ValueButton {
                id: kello
                anchors.horizontalCenter: parent.horizontalCenter
                property int valittuTunti: Math.floor(ryyppyVrk/60)
                property int valittuMinuutti: ryyppyVrk - valittuTunti*60

                function valitseAika() {
                    var dialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                                    hourMode: DateTime.TwentyFourHours,
                                    hour: valittuTunti,
                                    minute: valittuMinuutti
                                 })

                    dialog.accepted.connect(function() {
                        valittuTunti = dialog.hour
                        valittuMinuutti = dialog.minute
                        value = kellonAika(valittuTunti,valittuMinuutti)
                        ryyppyVrk = valittuTunti*60 + valittuMinuutti
                    })
                }

                width: Theme.fontSizeExtraSmall*8
                value: kellonAika(valittuTunti,valittuMinuutti)
                onClicked: {
                        valitseAika()
                }
            }

        }

    }

    Component.onCompleted: {
        korostukset()
    }

}
