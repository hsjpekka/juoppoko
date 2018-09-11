import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: sivu
    width: parent.width
    anchors.leftMargin: 0.05*width

    property date alkuhetki: new Date()
    property string kelloMuoto: "HH:mm"
    property date msSelvana: new Date()
    property date msKunnossa: new Date()
    property int paino
    property real polttonopeus: 0.1267 // ml/kg/h -- 1 g/10 kg/h = 1.267 ml/10 kg/h
    property real promilleja // g alkoholia / g vettä
    property real promilleRaja1
    property date pvm: new Date()
    property real tiheys: 0.7897 // alkoholin tiheys, g/ml
    property int tunti: 60*60*1000 // ms
    property int valittu
    property real vetta: 0.65

    function alkoholiaVeressa(hetki0, ml0, mlJuoma, vahvuus, hetki1)     {
        var dt // tuntia
        var ml1

        dt = (hetki1 - hetki0)/tunti // ms -> h
        if (dt < 0) {
            dt = 0
        }

        ml1 = ml0 + mlJuoma*vahvuus/100 - palonopeus()*dt // vanhat pohjat + juotu - poltetut

        if (ml1 < 0)
            ml1 = 0

        return ml1
    }

    function etsiPaikka(hetki, ind0) {
        var edAika

        if (ind0 > juomat.count -1)
            ind0 = juomat.count -1
        else if (ind0 < 0)
            ind0 = 0

        if (juomat.count > 0) { // jos juomalista ei ole tyhjä
            edAika = lueJuomanAika(ind0)

            while (hetki <= edAika) {
                ind0 = ind0 - 1
                if (ind0 > -0.5)
                    edAika = lueJuomanAika(ind0)
                else
                    edAika = hetki - 1
            }

            while (hetki >= edAika) {
                ind0 = ind0 + 1
                if (ind0 < juomat.count) {
                    edAika = lueJuomanAika(ind0)
                } else {
                   edAika = hetki + 1
                }
            }

        } else
            ind0 = 0

        return ind0
    }

    function kopioiJuoma(qId) {
        txtJuoma.text = lueJuomanTyyppi(qId)
        txtMaara.text = lueJuomanMaara(qId)
        voltit.text = lueJuomanVahvuus(qId).toFixed(1)

        return
    }

    function laskePromillet(ms){
        var ml0 = promilleja*paino/tiheys, til = 0, pros = 0 //, edellinen = etsiPaikka(ms, juomat.count -1)
        var ms0 = alkuhetki.getTime(), ms1

        //console.log("laskePromillet " + ml0.toFixed(2) + " " + juomat.count + " " + ms)

        //ml0 = mlKehossa(edellinen-1, ms)

        if (ms < ms0) return promilleja;

        for (var i = 0; i < juomat.count; i++) {
            ms1 = lueJuomanAika(i);
            if (ms1 > ms){
                i = juomat.count
            } else {
                ml0 = alkoholiaVeressa(ms0, ml0, til, pros, ms1)
                til = lueJuomanMaara(i);
                pros = lueJuomanVahvuus(i);
                ms0 = ms1
            }

            //console.log("laskePromillet c i=" + i + " " + ml0.toFixed(2))

        }

        ml0 = alkoholiaVeressa(ms0, ml0, til, pros, ms)

        //console.log("laskePromillet i=" + i + " " + ml0.toFixed(2) + " " + ms0 + " " + til + " " + pros + " " + ms)

        return ml0*tiheys/(paino*vetta)
    }

    function lisaaListaan(hetki, mlVeressa, maara, vahvuus, juomanNimi) {
        var paiva = new Date(hetki).toLocaleDateString(Qt.locale(),Locale.ShortFormat) // juomispäivä
        var kello = new Date(hetki).toLocaleTimeString(Qt.locale(), kelloMuoto) // kellonaika
        var ind = etsiPaikka(hetki,juomat.count-1)

        if (ind < juomat.count) {
            juomat.insert(ind, {"aikaMs": hetki, //"mlVeressa": mlVeressa,
                                 "section": paiva, "juomaaika": kello, "juomatyyppi": juomanNimi,
                                 "juomamaara": maara, "juomapros": vahvuus});
            paivitaMlVeressa(hetki, ind);

        } else
            juomat.append({"aikaMs": hetki, //"mlVeressa": mlVeressa,
                                 "section": paiva, "juomaaika": kello, "juomatyyppi": juomanNimi,
                                 "juomamaara": maara, "juomapros": vahvuus});
        return
    }

    function lueJuomanAika(xid) {
        var ms = 0
        if ((juomat.count > xid) && (xid > -0.5)) {
            ms = juomat.get(xid).aikaMs
        } else {
            ms = alkuhetki.getTime()
        }

        return ms
    }

    function lueJuomanMaara(xid) {
        var ml = 0
        if ((xid < juomat.count) && (xid > -0.5)) {
            ml = juomat.get(xid).juomamaara
        }

        return ml
    }

    function lueJuomanTyyppi(xid){
        var tyyppi = ""
        if ((juomat.count > xid) && (xid > -0.5)) {
            tyyppi = juomat.get(xid).juomatyyppi
        }

        return tyyppi

    }

    function lueJuomanVahvuus(xid) {
        var vahvuus = -0.001
        if ((juomat.count > xid) && (xid > -0.5)) {
            vahvuus = juomat.get(xid).juomapros
        }

        return vahvuus
    }

    /*
    function lueMlVeressa(xid) {
        var ml = 0
        if ((juomat.count > xid) && (xid > -0.5)) {
            ml = juomat.get(xid).mlVeressa
        } else {
            ml = promilleja*paino*vetta/tiheys
        }

        return ml
    } // */

    /*
    function mlKehossa(xid, ms) {
        var ml1

        ml1 = alkoholiaVeressa(lueJuomanAika(xid), lueMlVeressa(xid), lueJuomanMaara(xid), lueJuomanVahvuus(xid), ms )

        return ml1
    } // */

    function msRajalle(ml0, koko0, vahvuus0, promillea){
        var mlRajalle, hRajalle

        mlRajalle = ml0 + koko0*vahvuus0/100 - promillea*paino*vetta/tiheys//*1000
        hRajalle = mlRajalle/palonopeus()

        return Math.round(hRajalle*tunti)
    }

    function muutaJuoma(id, ms, maara, vahvuus, juomanNimi, juomanKuvaus)     { //, mlAlkoholia
        var paiva = new Date(ms).toLocaleDateString(Qt.locale(), Locale.ShortFormat)
        var kello = new Date(ms).toLocaleTimeString(Qt.locale(), kelloMuoto)

        juomat.set(id, {"section": paiva,"juomaaika": kello, "aikaMs": ms, //"mlVeressa": mlAlkoholia,
                       "juomatyyppi": juomanNimi, "juomamaara": maara,
                          "juomapros": vahvuus});               

        return
    }

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

    function muutaValittu(qId) {
        var vanhaMaara = lueJuomanMaara(qId)
        var vanhaVahvuus = lueJuomanVahvuus(qId)
        var vanhaHetki = lueJuomanAika(qId)

        var dialog = pageStack.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                        "aika": new Date(lueJuomanAika(qId)),
                        "nimi": lueJuomanTyyppi(qId),
                        "maara": vanhaMaara,
                        "vahvuus": vanhaVahvuus,
                        "juomanKuvaus": ""
                     })

        dialog.accepted.connect(function() {
            muutaJuoma(qId, dialog.aika.getTime(), dialog.maara, //parseFloat(lueMlVeressa(qId)),
                        dialog.vahvuus, dialog.nimi, "")
            //paivitaMlVeressa(dialog.aika.getTime(), qId)
            paivitaPromillet()
            paivitaAjatRajoille()

        })

        return
    }

    function paivitaAjatRajoille() {
        var ms1, ms0, prom = 0, ml0, koko0, vahvuus0, ind = juomat.count

        var nytMs = pvm.getTime()        

        /*
        ms0 = lueJuomanAika(ind-1)
        ml0 = lueMlVeressa(ind-1)
        koko0 = lueJuomanMaara(ind-1)
        vahvuus0 = lueJuomanVahvuus(ind-1) // */

        if (ind > 0) {
            ms0 = lueJuomanAika(ind-1)
            prom = laskePromillet(ms0+1)
        } else {
            ms0 = alkuhetki.getTime()
            prom = promilleja
        }

        ml0 = prom2ml(prom)

        //console.log("paivitaAjatRajoille - alkoholia kehossa [ml]" + ml0 + " juomassa " + (lueJuomanMaara(ind-1)*lueJuomanVahvuus(ind-1)/100).toFixed(1))

        // selväksi
        ms1 = ms0 + msRajalle(ml0, 0, 0, 0) // msRajalle(ml0, koko0, vahvuus0, promillea)
        msSelvana = new Date(ms1)

        // ajokuntoon
        ms1 = ms0 + msRajalle(ml0, 0, 0, promilleRaja1) //msRajalle(ml0, koko0, vahvuus0, promilleRaja1)
        msKunnossa = new Date(ms1)

        if ( msSelvana.getTime() > new Date().getTime() )
            txtSelvana.text = msSelvana.toLocaleTimeString(Qt.locale(), kelloMuoto)
        else
            txtSelvana.text = " -"

        if ( msKunnossa.getTime() > new Date().getTime() ) {
            txtAjokunnossa.text = msKunnossa.toLocaleTimeString(Qt.locale(), kelloMuoto)
        }
        else {
            txtAjokunnossa.text = " -"
        }

        return
    }

    /*
    function paivitaMlVeressa(ms1, xInd) {
        var ind = etsiPaikka(ms1, xInd)
        var ms0, ml0, koko0, vahvuus0, id1, ml1, koko1, vahvuus1

        ms0 = lueJuomanAika(ind-1)
        ml0 = lueMlVeressa(ind-1)
        koko0 = lueJuomanMaara(ind-1)
        vahvuus0 = lueJuomanVahvuus(ind-1)

        while (ind < juomat.count) {
            ms1 = lueJuomanAika(ind)
            ml1 = alkoholiaVeressa(ms0, ml0, koko0, vahvuus0, ms1 ) // paljonko tälle juomalle oli pohjia
            if ( (ml1 > 0) || (lueMlVeressa(ind) > 0) ) {
                juomat.set(ind,{"mlVeressa": ml1})
                koko1 = lueJuomanMaara(ind)
                vahvuus1 = lueJuomanVahvuus(ind)
                ms0 = ms1
                ml0 = ml1
                koko0 = koko1
                vahvuus0 = vahvuus1
            } else
                ind = juomat.count

            ind++
        }

        return
    } // */

    function paivitaPromillet() {
        var nytMs = pvm.getTime()
        var ml0, prml

        //console.log("paivitaPromillet - pvm " + pvm.getTime() )

        prml = laskePromillet(nytMs)

        if (prml < 3.0){
            txtPromilleja.text = "" + prml.toFixed(2) + " ‰"
        } else {
            txtPromilleja.text = "> 3.0 ‰"
        }

        // huomion keräys, jos promilleRajat ylittyvät
        if ( prml < promilleRaja1 ) {
            txtPromilleja.color = Theme.primaryColor
            txtPromilleja.font.pixelSize = Theme.fontSizeMedium
        } else {
            txtPromilleja.color = Theme.highlightColor
            txtPromilleja.font.pixelSize = Theme.fontSizeLarge
        }        

        return prml
    }

    function palonopeus() {
        return polttonopeus*paino
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
                /*
                Label {
                    text: mlVeressa
                    visible: false
                    width: 0
                } // */
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
    } //rivityyppi

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
                    onTextChanged: {
                        vetta = text/100
                        paivitaPromillet()
                        paivitaAjatRajoille()
                    }
                    label: qsTr("water") + " [%]"
                    width: Theme.fontSizeExtraSmall*7
                }

                TextField {
                    text: paino
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 1; top: 1000}
                    onTextChanged: {
                        paino = text*1
                        paivitaPromillet()
                        paivitaAjatRajoille()
                    }

                    label: qsTr("weight") + " [kg]"
                    width: Theme.fontSizeExtraSmall*7
                }

                TextField {
                    text: Number(promilleRaja1).toLocaleString(Qt.locale())
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    onTextChanged: {
                        promilleRaja1 = Number.fromLocaleString(Qt.locale(),text)
                        paivitaAjatRajoille()
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
                    onTextChanged: {
                        promilleja = Number.fromLocaleString(Qt.locale(),text)
                        paivitaPromillet()
                        paivitaAjatRajoille()
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


        }

        Component.onCompleted: {
            paivitaPromillet()
            paivitaAjatRajoille()
        }
    }

}
