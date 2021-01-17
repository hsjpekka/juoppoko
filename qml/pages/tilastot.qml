import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/scripts.js" as Apuja

Dialog {
    id: sivu
    property var    juodut
    property real   mlKuussa
    property real   mlViikossa
    property real   mlVuodessa
    property int    paiva: 24*60*60*1000 // ms
    property int    ryyppyVrk
    property real   tanaan
    property int    valittuKuvaaja // 0 - viikkokulutus, 1 - paivakulutus, oli 2 - paivaruudukko

    function kellonAika(hh, mm) {
        var mj;

        if (hh < 10)
            mj = "0" + hh + ":"
        else
            mj = "" + hh + ":";

        if (mm < 10)
            mj = mj + "0" + mm
        else
            mj = mj + mm;

        return mj;
    }

    function korostukset() {

        if (tanaan > paaikkuna.vrkRaja1) {
            txtPaivassa.color = Theme.highlightColor;
            if( tanaan > paaikkuna.vrkRaja2 ) {
                txtPaivassa.font.bold = true;
            }
        }

        if (mlViikossa > paaikkuna.vkoRaja1) {
            txtViikossa.color = Theme.highlightColor;
            if( mlViikossa > paaikkuna.vkoRaja2 ) {
                txtViikossa.font.bold = true;
            }
        }

        if (mlKuussa > paaikkuna.vkoRaja1/7*30 ) {
            txtKuussa.color = Theme.highlightColor;
            if( mlKuussa > paaikkuna.vkoRaja2/7*30 ) {
                txtKuussa.font.bold = true;
            }
        }

        if (mlVuodessa > paaikkuna.vsRaja1/7*30 ) {
            txtVuodessa.color = Theme.highlightColor;
            if( mlVuodessa > paaikkuna.vsRaja2/7*30 ) {
                txtVuodessa.font.bold = true;
            }
        }

        return;
    }

    function mlAikana(kesto, loppu) { // jakso = ms nykyhetkestä (tai tulevasta juoman hetkestä)
        //var nyt = new Date().getTime()
        var ml = 0, i = juodut.length - 1, t0, t1 = loppu;
        //Apuja.juomienMaara() - 1
        if (t1 === undefined)
            t1 = new Date().getTime();
        if (t1 < juodut[i].ms)
            t1 = juodut[i].ms;
        t0 = t1 - kesto;
        while ( i >= 0 && juodut[i].ms > t1)
            i--;
        while (i >= 0 && juodut[i].ms >= t0) {
            ml += juodut[i].ml;
            i--;
        }

        //console.log(" zzz " + juodut[juodut.length-1].ms + ", " + juodut[juodut.length-1].ml)
        //if ( Apuja.juomanAika(i) > nyt)
        //    nyt = Apuja.juomanAika(i)

        //while ( (i >=0 ) && (Apuja.juomanAika(i) >= nyt - jakso)){
        //    ml = ml + Apuja.juomanTilavuus(i)*Apuja.juomanVahvuus(i)/100
        //    i--
        //}

        return ml;
    }

    function vuodessa() {
        var nyt = new Date().getTime();
        var suhde = 1, i = juodut.length - 1;

        if (juodut[i].ms > nyt)
            nyt = juodut[i].ms;

        if (juodut[0].ms > nyt - 365*paiva){
            suhde = (nyt-juodut[0].ms)/(365*paiva);
            if (suhde < 1/52)
                suhde = 1/52;
            txtVuodessa.font.italic = !txtVuodessa.font.italic;
        }

        //console.log("oo  " + suhde);

        return mlAikana(365*paiva)/suhde;
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
                    color: Theme.highlightColor
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
                    color: Theme.highlightColor
                    text: qsTr("%1 ml, equals to %2 l in year").arg(mlViikossa.toFixed(1)).arg((mlViikossa*52/1000).toFixed(1))
                    //text: mlViikossa.toFixed(1) + " ml"
                }
                /*
                Label {
                    color: Theme.highlightColor
                    text: qsTr(", equals to ")
                }

                Label {
                    color: Theme.highlightColor
                    text: (mlViikossa*52/1000).toFixed(1) + " l " + qsTr("in year")
                }// */

            } // viikossa


            SectionHeader {
                text: qsTr("last month")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    id: txtKuussa
                    color: Theme.highlightColor
                    text: qsTr("%1 ml, equals to %2 l in year").arg(mlKuussa.toFixed(1)).arg((mlKuussa/30*365/1000).toFixed(1))
                }
                /*
                Label {
                    color: Theme.highlightColor
                    text: qsTr(", equals to ")
                }

                Label {
                    color: Theme.highlightColor
                    text: (mlKuussa/30*365/1000).toFixed(1) + " l " + qsTr("in year")
                } //*/


            } // kuussa

            SectionHeader {
                text: qsTr("in year")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    id: txtVuodessa
                    color: Theme.highlightColor
                    text: qsTr("%1 l in year, equals to %2 ml in week").arg((mlVuodessa/1000).toFixed(1)).arg((mlVuodessa/52).toFixed(1))
                    //text: (mlVuodessa/1000).toFixed(1) + " l"
                }
                /*
                Label {
                    color: Theme.highlightColor
                    text: qsTr(", equals to ")
                }

                Label {
                    color: Theme.highlightColor
                    text: (mlVuodessa()/52).toFixed(1) + " ml " + qsTr("in week")
                }// */

            } // vuodessa

            SectionHeader {
                text: qsTr("drinking day ends at")
            }

            ValueButton {
                id: kello
                anchors.horizontalCenter: parent.horizontalCenter
                valueColor: Theme.primaryColor
                property int valittuTunti: Math.floor(ryyppyVrk/60)
                property int valittuMinuutti: ryyppyVrk - valittuTunti*60

                function valitseAika() {
                    var dialog = pageContainer.push("Sailfish.Silica.TimePickerDialog", {
                                    hourMode: DateTime.TwentyFourHours,
                                    hour: valittuTunti,
                                    minute: valittuMinuutti
                                 })

                    dialog.accepted.connect(function() {
                        valittuTunti = dialog.hour
                        valittuMinuutti = dialog.minute
                        value = kellonAika(valittuTunti, valittuMinuutti)
                        ryyppyVrk = valittuTunti*60 + valittuMinuutti
                    })
                }

                width: Theme.fontSizeExtraSmall*8
                value: kellonAika(valittuTunti, valittuMinuutti)
                onClicked: {
                        valitseAika()
                }
            }

        }

    }

    Component.onCompleted: {
        //console.log("vrk vaihtuu " + ryyppyVrk + " - " + kello.valittuTunti + ", " + kello.valittuMinuutti)
        tanaan = mlAikana(paiva)
        mlViikossa = mlAikana(7*paiva)
        mlKuussa = mlAikana(30*paiva)
        mlVuodessa = vuodessa()
        korostukset()
    }

}
