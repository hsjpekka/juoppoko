import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: sivu
    width: parent.width

    property date alkuhetki: new Date()
    property string kelloMuoto: "HH:mm"
    property alias paino: juoja.paino
    property real promilleja // g alkoholia / g vettä
    property alias promilleRaja1: juoja.promilleRaja
    property date pvm: new Date()
    property alias vetta: juoja.vetta

    function muutaUusi() {
        var pv0 = pvm.getDate(), kk0 = pvm.getMonth(), vs0 = pvm.getFullYear()
        var h0 = pvm.getHours(), m0 = pvm.getMinutes()

        var dialog = pageStack.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                        "aika": pvm,
                        "nimi": txtJuoma.text,
                        "maara": txtMaara.text,
                        "vahvuus": voltit.text,
                        "juomanKuvaus": ""
                     })

        dialog.accepted.connect(function() {
            pvm = dialog.aika

            if ( (pvm.getDate() != pv0) || (pvm.getMonth() != kk0) || (pvm.getFullYear() != vs0)) {
                paivays.value = dialog.aika.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
            }

            if ((pvm.getHours() != h0) || (pvm.getMinutes() != m0)) {
                kello.value = dialog.aika.toLocaleTimeString(Qt.locale(), kelloMuoto)
            }

            txtJuoma.text = dialog.nimi
            txtMaara.text = dialog.maara
            voltit.text = dialog.vahvuus

            return
        })

        return
    }

    function prom2ml(pro) {
        return pro*paino*vetta/tiheys
    }

    function uusiJuoma(hetki, mlVeressa, maara, vahvuus, juomanNimi)     {
        //var lisayskohta = etsiPaikka(hetki, juomat.count -1) // mihin kohtaan uusi juoma kuuluu juomien historiassa?
        //var ml0
        //var apu

        // lasketaan paljonko veressä on alkoholia juomishetkellä
        //mlVeressa = mlKehossa(lisayskohta-1, hetki)

        lisaaListaan(hetki, mlVeressa, maara, vahvuus, juomanNimi) //

        paivitaPromillet();

        paivitaAjatRajoille();

        return;
    }

    /*
    Component {
        id: rivityyppi
        ListItem {
            id: juotuJuoma
            propagateComposedEvents: true
            onClicked: {
                valittu = juomaLista.indexAt(mouseX,y+mouseY)
                kopioiJuoma(valittu)
                mouse.accepted = false
            }

            onPressAndHold: {
                valittu = juomaLista.indexAt(mouseX,y+mouseY)
                juomaLista.currentIndex = valittu
                mouse.accepted = false
            }

            // contextmenu erillisenä komponenttina on ongelma remorseActionin kanssa
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("delete")
                    onClicked: {
                        juomaLista.currentItem.remorseAction(qsTr("deleting"), function () {
                            juomat.remove(valittu)
                            paivitaMlVeressa(lueJuomanAika(valittu)-1, valittu); //-1 varmistaa, että usean samaan aikaan juodun juoman kohdalla päivitys toimii
                            paivitaPromillet();
                            paivitaAjatRajoille();
                        })

                    }
                }

                MenuItem {
                    text: qsTr("modify")
                    onClicked: {
                        muutaValittu(valittu);

                        //paivitaMlVeressa(lueJuomanAika(valittu)-1, valittu);
                        paivitaPromillet();
                        paivitaAjatRajoille();

                    }
                }

            }

            // juodut-taulukko: id aika veri% tilavuus juoma% juoma kuvaus
            Row {
                width: sivu.width*0.9
                x: sivu.width*0.05

                Label {
                    text: aikaMs
                    visible: false
                    width: 0
                }
                Label {
                    text: juomaaika
                    width: (Theme.fontSizeMedium*3.5).toFixed(0)
                }
                Label {
                    text: juomatyyppi
                    width: Theme.fontSizeMedium*7
                }
                Label {
                    text: juomamaara
                    width: (Theme.fontSizeMedium*2.5).toFixed(0)
                }
                Label {
                    text: juomapros
                    width: (Theme.fontSizeMedium*2.5).toFixed(0)
                }

            } //row


        } //listitem
    } //rivityyppi //*/

    SilicaFlickable {
        id: ylaosa
        height: column.height
        width: parent.width
        contentHeight: column.height

        Column {
            id: column

            width: sivu.width
            spacing: 2 //Theme.paddingSmall

            PageHeader {
                title: qsTr("Demo")
            }

            /*
            SectionHeader {
                text: qsTr("values not saved, clock not running")
            } // */

            SectionHeader {
                text: qsTr("drinker") + " & " + qsTr("starting point")
            }

            // sukupuoli ja paino
            Row {

                TextField {
                    text: (vetta*100).toFixed(0)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 100}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    EnterKey.onClicked: {
                        vetta = text/100
                        juoja.laskeUudelleen()
                        juoja.paivita(pvm.getDate())
                    }
                    label: qsTr("water") + " [%]"
                    width: Theme.fontSizeExtraSmall*7
                }

                TextField {
                    text: paino
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 1; top: 1000}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    EnterKey.onClicked: {
                        paino = text*1
                        juoja.laskeUudelleen()
                        juoja.paivita(pvm.getDate())
                    }

                    label: qsTr("weight") + " [kg]"
                    width: Theme.fontSizeExtraSmall*7
                }

                TextField {
                    text: Number(promilleRaja1).toLocaleString(Qt.locale())
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    EnterKey.onClicked: {
                        promilleRaja1 = Number.fromLocaleString(Qt.locale(),text)
                        juoja.paivita(pvm.getDate())
                    }
                    label: qsTr("limit") + " [‰]"
                    width: Theme.fontSizeExtraSmall*7
                }

            }            

            // pohjat
            Row {

                TextField {
                    id: pohjat
                    text: Number(promilleja).toLocaleString(Qt.locale())
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    EnterKey.onClicked: {
                        promilleja = Number.fromLocaleString(Qt.locale(),text)
                        juoja.pohjat = prom2ml(promilleja)
                        juoja.laskeUudelleen()
                        juoja.paivita(pvm.getDate())
                    }
                    label: "[‰]"
                    width: (Theme.fontSizeMedium*3.5).toFixed(0) //Theme.fontSizeExtraSmall*5
                }                

                Label{
                    text: qsTr("at")
                    height: pohjat.height
                    verticalAlignment: TextInput.AlignVCenter
                }

                ValueButton {
                    id: kello0
                    property int valittuTunti0: alkuhetki.getHours()
                    property int valittuMinuutti0: alkuhetki.getMinutes()

                    function openTimeDialog0() {
                        var dialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                                        hourMode: DateTime.TwentyFourHours,
                                        hour: alkuhetki.getHours(),
                                        minute: alkuhetki.getMinutes()
                                     })

                        dialog.accepted.connect(function() {
                            valittuTunti0 = dialog.hour
                            valittuMinuutti0 = dialog.minute
                            alkuhetki = new Date(alkuhetki.getFullYear(), alkuhetki.getMonth(), alkuhetki.getDate(), valittuTunti0, valittuMinuutti0, 0, 0)
                            kello0.value = alkuhetki.toLocaleTimeString(Qt.locale(), kelloMuoto)

                            paivitaPromillet()
                            paivitaAjatRajoille()
                        })
                    }

                    width: Theme.fontSizeMedium*5
                    value: pvm.toLocaleTimeString(Qt.locale(), kelloMuoto)
                    onClicked: {
                            openTimeDialog0()
                    }
                }

                ValueButton {
                    id: paivays0
                    property date valittuPaiva0: alkuhetki

                    function avaaPaivanValinta() {
                        var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                                        date: alkuhetki
                                     })

                        dialog.accepted.connect(function() {
                            valittuPaiva0 = dialog.date
                            alkuhetki = new Date(valittuPaiva0.getFullYear(), valittuPaiva0.getMonth(), valittuPaiva0.getDate(),
                                           alkuhetki.getHours(), alkuhetki.getMinutes(), 0, 0)
                            value = alkuhetki.toLocaleDateString(Qt.locale(), Locale.ShortFormat)

                            paivitaPromillet()
                            paivitaAjatRajoille()
                        })
                    }

                    value: alkuhetki.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
                    width: Theme.fontSizeMedium*8 //sivu.width - kello.width - pohjat.width - Theme.fontSizeMedium*2 - 4*Theme.paddingSmall
                    onClicked: {
                            avaaPaivanValinta()
                    }
                }

            }

            SectionHeader {
                text: qsTr("current state at ") + " " + kello.value
            }

            Row { // promillet
                spacing: 10

                TextField {
                    id: txtPromilleja
                    text: "X ‰"
                    label: qsTr("BAC")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.primaryColor
                    width: Theme.fontSizeSmall*6
                    readOnly: true
                }

                TextField {
                    id: txtSelvana
                    text: "?"
                    label: qsTr("sober at")
                    font.pixelSize: Theme.fontSizeSmall
                    width: Theme.fontSizeSmall*6
                    readOnly: true
                }

                TextField {
                    id: txtAjokunnossa
                    text: "?"
                    label: promilleRaja1.toFixed(1) + " ‰"
                    font.pixelSize: Theme.fontSizeSmall
                    width: Theme.fontSizeSmall*8
                    readOnly: true
                }

            }

            Row { // nykyinen aika

                spacing: Theme.paddingSmall

                ValueButton {
                    id: kello
                    property int valittuTunti: pvm.getHours()
                    property int valittuMinuutti: pvm.getMinutes()

                    function openTimeDialog() {
                        var dialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                                        hourMode: DateTime.TwentyFourHours,
                                        hour: pvm.getHours(),
                                        minute: pvm.getMinutes()
                                     })

                        dialog.accepted.connect(function() {
                            valittuTunti = dialog.hour
                            valittuMinuutti = dialog.minute
                            pvm = new Date(pvm.getFullYear(), pvm.getMonth(), pvm.getDate(), valittuTunti, valittuMinuutti, 0, 0)

                            value = pvm.toLocaleTimeString(Qt.locale(), kelloMuoto)

                            paivitaPromillet()
                            paivitaAjatRajoille()
                        })
                    }

                    width: Theme.fontSizeSmall*6
                    value: pvm.toLocaleTimeString(Qt.locale(), kelloMuoto)
                    onClicked: {
                            openTimeDialog()
                    }
                }

                ValueButton {
                    id: paivays
                    property date valittuPaiva: pvm

                    function avaaPaivanValinta() {
                        var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                                        date: pvm
                                     })

                        dialog.accepted.connect(function() {
                            valittuPaiva = dialog.date
                            pvm = new Date(valittuPaiva.getFullYear(), valittuPaiva.getMonth(), valittuPaiva.getDate(),
                                           pvm.getHours(), pvm.getMinutes(), 0, 0)

                            value = pvm.toLocaleDateString(Qt.locale(), Locale.ShortFormat)

                            paivitaPromillet()
                            paivitaAjatRajoille()
                        })
                    }

                    value: pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    width: Theme.fontSizeSmall*8 //sivu.width - kello.width - 3*Theme.paddingSmall
                    onClicked: {
                            avaaPaivanValinta()
                    }
                }

            } // aika

            Row { //lisattava juoma
                //id: drinkData
                spacing: 2

                TextField {
                    id: txtJuoma
                    width: Theme.fontSizeMedium*6
                    readOnly: true
                    text: qsTr("beer")
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: txtMaara
                    label: "ml"
                    width: Theme.fontSizeMedium*3
                    readOnly: true
                    text: "500"
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: voltit
                    label: qsTr("vol-%")
                    width: (Theme.fontSizeMedium*3.5).toFixed(0)
                    readOnly: true
                    text: "4.7"
                    onClicked: {
                        muutaUusi()
                    }
                }

                Button { //add
                    width: Theme.fontSizeMedium*4

                    text: qsTr("cheers!")
                    onClicked: {
                        uusiJuoma(pvm.getTime(), 0.0, parseInt(txtMaara.text),
                                 parseFloat(voltit.text), txtJuoma.text)
                        juomaLista.positionViewAtEnd()

                        //console.log("cheers - " + pvm.getTime() )

                    }
                }
            }

            Separator{
                x: Theme.paddingLarge
                width: sivu.width - 2*x
                color: Theme.secondaryColor
            }

            Juomari {
                id: juoja
                pohjat: prom2ml(sivu.promilleja)
                width: parent.width
                height: (sivu.height - y) > oletusKorkeus? sivu.height - y : oletusKorkeus
                promilleRaja: promilleRaja1
                onJuomaPoistettu: {
                    paivita()
                }
                onMuutaJuomanTiedot: {
                    var dialog = pageStack.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                                    "aika": new Date(juodunAika(iMuutettava)),
                                    "nimi": juodunNimi(iMuutettava),
                                    "maara": juodunTilavuus(iMuutettava),
                                    "vahvuus": juodunVahvuus(iMuutettava),
                                    "juomanKuvaus": juodunKuvaus(iMuutettava),
                                    "tilavuusMitta": Tkanta.arvoTilavuusMitta,
                                    "olutId": juodunOlutId(iMuutettava)
                                 })

                    dialog.rejected.connect(function() {
                        return tarkistaUnTpd()
                    } )

                    dialog.accepted.connect(function() {
                        var ms = dialog.aika.getTime();
                        muutaJuoma(iMuutettava, ms, dialog.maara, dialog.vahvuus, dialog.nimi,
                                   dialog.juomanKuvaus, dialog.olutId);
                        paivita();
                        paivitaAjatRajoille();
                    })
                }
                onPromillejaChanged: {
                    var nytMs = pvm.getTime()
                    var prml = juoja.promilleja

                    if (prml < 3.0){
                        txtPromilleja.text = "" + prml.toFixed(2) + " ‰"
                    } else {
                        txtPromilleja.text = "> 3.0 ‰"
                    }

                    // huomion keräys, jos promilleRajat ylittyvät
                    if ( prml < promilleRaja1 ) {
                        //txtPromilleja.color = Theme.highlightDimmerColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeMedium
                        txtPromilleja.font.bold = false
                    } else {
                        //txtPromilleja.color = Theme.highlightColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeLarge
                        txtPromilleja.font.bold = true
                    }

                    if (nytMs > juoja.rajalla.getTime()) // msKunnossa.getTime() // verrataan hetkeä nytMs listan viimeisen juoman jälkeiseen hetkeen
                        txtAjokunnossa.text = " -"

                    if (nytMs > juoja.selvana.getTime()) // msSelvana.getTime()
                        txtSelvana.text = " -"

                }
                onValittuJuomaChanged: {
                    txtJuoma.text = juodunNimi(valittuJuoma) //valitunNimi //Apuja.juomanNimi(i)
                    txtMaara.text = juodunTilavuus(valittuJuoma) //valitunTilavuus //lueJuomanMaara(qId)
                    voltit.text = juodunVahvuus(valittuJuoma) //valitunVahvuus //lueJuomanVahvuus(qId)
                }

            }

            /*
            SilicaListView {
                id: juomaLista
                height: sivu.height - y
                width: parent.width
                clip: true

                model: ListModel {
                    id: juomat
                }

                section {
                    property: 'section'

                    delegate: SectionHeader {
                        text: section
                    }
                }

                delegate: rivityyppi

                footer: Row {
                    x: sivu.width*0.05
                    height: 70

                    Label {
                        text: qsTr("time")
                        width: (Theme.fontSizeMedium*3.5).toFixed(0)
                    }
                    Label {
                        text: qsTr("drink")
                        width: Theme.fontSizeMedium*7
                    }
                    Label {
                        text: "ml"
                        width: (Theme.fontSizeMedium*2.5).toFixed(0)
                    }
                    Label {
                        text: qsTr("vol-%")
                        width: (Theme.fontSizeMedium*2.5).toFixed(0)
                    }
                }

                VerticalScrollDecorator {}

            }
            // */

        }

        Component.onCompleted: {
            paivitaPromillet()
            paivitaAjatRajoille()
        }
    }

}
