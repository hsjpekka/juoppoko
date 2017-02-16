import QtQuick 2.0
import Sailfish.Silica 1.0

//Dialog {
Page {

    property int paiva: 24*60*60*1000 // ms
    property real tanaan: mlAikana(paiva) // paaikkuna.mlAikana(paiva)
    property real mlViikossa: mlAikana(7*paiva)
    property real mlKuussa: mlAikana(30*paiva) // paaikkuna.mlAikana(30*paiva)
    //property real mlVuodessa:

    function mlAikana(jakso) {
        var nyt = new Date().getTime()
        var ml = 0
        var i = paaikkuna.juomienMaara() - 1

        if (paaikkuna.lueJuomanAika(i) > nyt)
            nyt = paaikkuna.lueJuomanAika(i)

        while ( (i >=0 ) && (paaikkuna.lueJuomanAika(i) >= nyt - jakso)){
            ml = ml + paaikkuna.lueJuomanMaara(i)*paaikkuna.lueJuomanVahvuus(i)/100
            i--
        }

        return ml
    }

    function mlVuodessa() {
        var nyt = new Date().getTime()
        var suhde = 1
        var i = paaikkuna.juomienMaara() - 1

        if (paaikkuna.lueJuomanAika(i) > nyt)
            nyt = paaikkuna.lueJuomanAika(i)

        if (paaikkuna.lueJuomanAika(0) > nyt - 365*paiva){
            suhde = (nyt-paaikkuna.lueJuomanAika(0))/(365*paiva)
            if (suhde < 1/52)
                suhde = 1/52

            txtVuodessa.font.italic = !txtVuodessa.font.italic
        }

        return mlAikana(365*paiva)/suhde

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
        height: column.height
        width: parent.width

        Column {
            id: column
            width: parent.width
            //anchors.leftMargin:

//            DialogHeader {
            PageHeader {
                title: qsTr("Statistics")
            }

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
                    text: mlViikossa + " ml"
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

        }

    }

    Component.onCompleted: {
        korostukset()
    }

}

