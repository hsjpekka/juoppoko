import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"
import "../scripts/tietokanta.js" as Tkanta

Page {
    id: sivu
    width: parent.width

    property string kelloMuoto: "HH:mm"
    property real   lahtoTaso // g alkoholia / g vettä
    property int    minMs: 60*1000
    property alias  paino: juoja.paino
    property alias  promilleRaja1: juoja.promilleRaja
    property date   pvm//: new Date(new Date().getTime()+2*minMs)
    property alias  vetta: juoja.vetta
    onPvmChanged: {
        kello.value = pvm.toLocaleTimeString(Qt.locale(), kelloMuoto);
        paivays.value = pvm.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
        txtAjokunnossa.teksti(pvm.getTime())
        txtSelvana.teksti(pvm.getTime())
    }

    function muutaUusi() {
        var pv0 = pvm.getDate(), kk0 = pvm.getMonth(), vs0 = pvm.getFullYear()
        var h0 = pvm.getHours(), m0 = pvm.getMinutes()

        var dialog = pageContainer.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
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

    function kokoaTiedot() {
        var dt, ml, msTunti = 60*60*1000;
        juoja.paino = massa.text*1;
        juoja.vetta = vesimaara.text/100;
        if (juoja.annoksia > 0) {
            if (alkutilanne.aika.getTime() > juoja.juodunAika(0)) {
                alkutilanne.aika = new Date(juoja.juodunAika(0));
                paivays0.value = alkutilanne.aika.toLocaleDateString(Qt.locale(),
                                                                     Locale.ShortFormat);
                kello0.value = alkutilanne.aika.toLocaleTimeString(Qt.locale(),
                                                                   kelloMuoto);
            }
            dt =  juoja.juodunAika(0) - alkutilanne.aika.getTime();
        } else
            dt = pvm.getTime() - alkutilanne.aika.getTime();
        //console.log("dt " + dt + ", annoksia " + juoja.annoksia + " " + pvm.getTime() + " " + alkutilanne.aika.getTime());
        if (dt < 0) dt = 0;
        ml = Number.fromLocaleString(Qt.locale(), pohjat.text)*paino*vetta/juoja.tiheys - juoja.palamisNopeus()*dt/msTunti;
        //console.log("ml " + ml );
        if (ml < 0) ml = 0;
        juoja.promilleja = ml*juoja.tiheys/(paino*vetta);
        juoja.pohjat = ml;
        return;
    }

    function laskeUudelleen() {
        kokoaTiedot();
        if (juoja.annoksia > 0 && pvm.getTime() >= juoja.juodunAika(0)) {
            juoja.laskeUudelleen(juoja.juodunAika(0)-1);
            juoja.paivita(pvm.getTime()+1);
        }
        txtSelvana.teksti(pvm.getTime()+1);
        txtAjokunnossa.teksti(pvm.getTime()+1);
        return;
    }

    function uusiJuoma(hetki, maara, vahvuus, juomanNimi) {
        juoja.juo(juoja.annoksia, hetki, maara, vahvuus, juomanNimi);
        juoja.paivita(hetki+1);
        pvm = new Date(pvm.getTime() + minMs);
        return;
    }

    SilicaFlickable {
        id: ylaosa
        height: column.height
        width: parent.width
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("recalculate")
                onClicked: {
                    laskeUudelleen()
                }
            }

            MenuItem {
                text: qsTr("cheers!")
                onClicked: {
                    uusiJuoma(pvm.getTime(), parseInt(txtMaara.text),
                             parseFloat(voltit.text), txtJuoma.text)
                }
            }
        }

        Column {
            id: column

            width: sivu.width
            //spacing: 2 //Theme.paddingSmall

            PageHeader {
                title: qsTr("Foreteller")
            }

            SectionHeader {
                text: qsTr("drinker")
            }

            // sukupuoli ja paino
            Row {

                TextField {
                    id: vesimaara
                    text: (vetta*100).toFixed(0)
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 0; top: 100}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    EnterKey.onClicked: {
                        laskeUudelleen()
                        focus = false
                    }
                    label: qsTr("water %1").arg("[%]")
                    width: Theme.fontSizeExtraSmall*7
                }

                TextField {
                    id: massa
                    text: paino
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator {bottom: 1; top: 1000}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    EnterKey.onClicked: {
                        laskeUudelleen()
                        focus = false
                    }

                    label: qsTr("weight %1").arg("[kg]")
                    width: Theme.fontSizeExtraSmall*8
                }

                TextField {
                    id: raja
                    text: Number(promilleRaja1).toLocaleString(Qt.locale())
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    EnterKey.onClicked: {
                        promilleRaja1 = Number.fromLocaleString(Qt.locale(), text)
                        txtAjokunnossa.teksti(pvm.getTime())
                        focus = false
                    }
                    label: qsTr("limit %1").arg("[‰]")
                    width: Theme.fontSizeExtraSmall*7
                }

            }            

            SectionHeader {
                text: qsTr("starting point")
            }

            // pohjat
            Row {
                id: alkutilanne
                width: parent.width
                property date aika

                TextField {
                    id: pohjat
                    text: Number(lahtoTaso).toLocaleString(Qt.locale())
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {bottom: 0.0; top: 5.0}
                    EnterKey.iconSource: "image://theme/icon-m-play"
                    onTextChanged: {
                        lahtoTaso = Number.fromLocaleString(Qt.locale(), text)
                        juoja.pohjat = juoja.prom2ml(lahtoTaso)
                    }
                    EnterKey.onClicked: {
                        laskeUudelleen()
                        focus = false
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
                    width: Theme.fontSizeMedium*5
                    value: alkutilanne.aika.toLocaleTimeString(Qt.locale(), kelloMuoto)
                    valueColor: Theme.primaryColor
                    onClicked: {
                            openTimeDialog0()
                    }
                    property int valittuTunti0
                    property int valittuMinuutti0

                    function openTimeDialog0() {
                        var dialog = pageContainer.push("Sailfish.Silica.TimePickerDialog", {
                                        hourMode: DateTime.TwentyFourHours,
                                        hour: alkutilanne.aika.getHours(),
                                        minute: alkutilanne.aika.getMinutes()
                                     })

                        dialog.accepted.connect(function() {
                            valittuTunti0 = dialog.hour;
                            valittuMinuutti0 = dialog.minute;
                            alkutilanne.aika = new Date(alkutilanne.aika.getFullYear(),
                                                        alkutilanne.aika.getMonth(),
                                                        alkutilanne.aika.getDate(),
                                                        valittuTunti0, valittuMinuutti0, 0, 0);
                            kello0.value = alkutilanne.aika.toLocaleTimeString(Qt.locale(),
                                                                               kelloMuoto);
                            //laskeUudelleen()
                        })
                    }

                }

                ValueButton {
                    id: paivays0
                    value: alkutilanne.aika.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
                    valueColor: Theme.primaryColor
                    width: Theme.fontSizeMedium*8 //sivu.width - kello.width - pohjat.width - Theme.fontSizeMedium*2 - 4*Theme.paddingSmall
                    onClicked: {
                        avaaPaivanValinta()
                    }

                    function avaaPaivanValinta() {
                        var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                        date: alkutilanne.aika
                                     })

                        dialog.accepted.connect(function() {
                            alkutilanne.aika = new Date(dialog.date.getFullYear(),
                                                        dialog.date.getMonth(),
                                                        dialog.date.getDate(),
                                                        alkutilanne.aika.getHours(),
                                                        alkutilanne.aika.getMinutes(), 0, 0);
                            value = alkutilanne.aika.toLocaleDateString(Qt.locale(),
                                                                        Locale.ShortFormat);
                            //laskeUudelleen()
                        })
                    }
                }
            }

            SectionHeader {
                text: qsTr("state at %1").arg(kello.value)
            }

            Row { // promillet
                spacing: 10

                TextField {
                    id: txtPromilleja
                    text: juoja.promilleja < 3.0 ? juoja.promilleja.toFixed(2) + " ‰" : "> 3.0 ‰"
                    label: qsTr("BAC")
                    readOnly: true
                    font.pixelSize: juoja.promilleja < promilleRaja1? Theme.fontSizeMedium : Theme.fontSizeLarge
                    font.bold: juoja.promilleja < promilleRaja1? false : true
                    color: Theme.highlightColor
                    width: Theme.fontSizeSmall*6
                }

                TextField {
                    id: txtSelvana
                    text: "?"
                    label: qsTr("sober at")
                    readOnly: true
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    width: Theme.fontSizeSmall*6

                    function teksti(aika) {
                        //console.log("selvänä " + juoja.selvana + ", " + juoja.selvana.valueOf());
                        if (juoja.selvana.toLocaleTimeString(Qt.locale(), kelloMuoto) == "" ||
                                aika > juoja.selvana.getTime())
                            text = " -"
                        else
                            text = juoja.selvana.toLocaleTimeString(Qt.locale(), kelloMuoto);
                        return;
                    }
                }

                TextField {
                    id: txtAjokunnossa
                    text: "?"
                    label: promilleRaja1.toFixed(1) + " ‰"
                    readOnly: true
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    width: Theme.fontSizeSmall*8

                    function teksti(aika) {
                        console.log("rajalla " + juoja.rajalla.getTime() + ", nyt " + aika);
                        if (juoja.rajalla.toLocaleTimeString(Qt.locale(), kelloMuoto) == "" ||
                                aika > juoja.rajalla.getTime())
                            text = " -"
                        else
                            text = juoja.rajalla.toLocaleTimeString(Qt.locale(), kelloMuoto);
                        return;
                    }
                }

            }

            Row { // nykyinen aika

                spacing: Theme.paddingSmall
                x: (parent.width - kello.width - paivays.width - spacing)/2

                ValueButton {
                    id: kello
                    width: Theme.fontSizeSmall*6
                    //value: pvm.toLocaleTimeString(Qt.locale(), kelloMuoto)
                    valueColor: Theme.primaryColor
                    onClicked: {
                            openTimeDialog()
                    }

                    property int   valittuTunti: pvm.getHours()
                    property int   valittuMinuutti: pvm.getMinutes()
                    property color tausta

                    function openTimeDialog() {
                        var dialog = pageContainer.push("Sailfish.Silica.TimePickerDialog", {
                                        hourMode: DateTime.TwentyFourHours,
                                        hour: pvm.getHours(),
                                        minute: pvm.getMinutes()
                                     })

                        dialog.accepted.connect(function() {
                            valittuTunti = dialog.hour;
                            valittuMinuutti = dialog.minute;
                            pvm = new Date(pvm.getFullYear(), pvm.getMonth(), pvm.getDate(), valittuTunti, valittuMinuutti, 0, 0);
                            if (pvm.getTime() < alkutilanne.aika.getTime()) {
                                kello._backgroundColor = Theme.highlightColor
                                paivays._backgroundColor = Theme.highlightColor
                            } else {
                                kello._backgroundColor = kello.tausta
                                paivays._backgroundColor = paivays.tausta
                            }
                            //value = pvm.toLocaleTimeString(Qt.locale(), kelloMuoto);
                            juoja.paivita(pvm.getTime()+1);
                            //console.log(valittuTunti + ":" + valittuMinuutti + " ")
                        })
                    }

                }

                ValueButton {
                    id: paivays
                    //value: pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    valueColor: Theme.primaryColor
                    width: Theme.fontSizeSmall*8 //sivu.width - kello.width - 3*Theme.paddingSmall
                    onClicked: {
                            avaaPaivanValinta()
                    }
                    property color tausta

                    function avaaPaivanValinta() {
                        var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                        "date": pvm
                                     })

                        dialog.accepted.connect(function() {
                            pvm = new Date(dialog.date.getFullYear(), dialog.date.getMonth(), dialog.date.getDate(),
                                           pvm.getHours(), pvm.getMinutes(), 0, 0)
                            //value = pvm.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
                            if (pvm.getTime() < alkutilanne.aika.getTime()) {
                                kello._backgroundColor = Theme.highlightColor
                                paivays._backgroundColor = Theme.highlightColor
                            } else {
                                kello._backgroundColor = kello.tausta
                                paivays._backgroundColor = paivays.tausta
                            }
                            juoja.paivita(pvm.getTime()+1);
                            //laskeUudelleen();
                        })
                    }

                }
            } // aika

            Row { //lisattava juoma
                //id: drinkData
                width: parent.width
                spacing: Theme.paddingMedium

                TextField {
                    id: txtJuoma
                    width: parent.width - 2*parent.spacing - txtMaara.width - voltit.width
                    readOnly: true
                    text: qsTr("beer")
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: txtMaara
                    label: "ml"
                    width: Theme.fontSizeMedium*5
                    readOnly: true
                    text: "500"
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: voltit
                    label: qsTr("vol-%")
                    width: Theme.fontSizeMedium*4
                    readOnly: true
                    text: "4.7"
                    onClicked: {
                        muutaUusi()
                    }
                }

                /*
                Button { //add
                    width: Theme.fontSizeMedium*4

                    text: qsTr("cheers!")
                    onClicked: {
                        uusiJuoma(pvm.getTime(), parseInt(txtMaara.text),
                                 parseFloat(voltit.text), txtJuoma.text)
                    }
                } // */
            }

            Separator{
                x: Theme.paddingLarge
                width: sivu.width - 2*x
                color: Theme.secondaryColor
            }

            Juomari {
                id: juoja
                pohjat: prom2ml(lahtoTaso)
                width: parent.width
                height: (sivu.height - y) > oletusKorkeus? sivu.height - y : oletusKorkeus
                promilleRaja: promilleRaja1
                onMuutaJuomanTiedot: {
                    var dialog = pageContainer.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                                    "aika": new Date(juodunAika(iMuutettava)),
                                    "nimi": juodunNimi(iMuutettava),
                                    "maara": juodunTilavuus(iMuutettava),
                                    "vahvuus": juodunVahvuus(iMuutettava),
                                    "juomanKuvaus": juodunKuvaus(iMuutettava),
                                    "tilavuusMitta": Tkanta.arvoTilavuusMitta,
                                    "olutId": juodunOlutId(iMuutettava)
                                 })

                    dialog.accepted.connect(function() {
                        var ms = dialog.aika.getTime();
                        muutaJuoma(iMuutettava, ms, dialog.maara, dialog.vahvuus, dialog.nimi,
                                   dialog.juomanKuvaus, dialog.olutId);
                        paivita();
                        juoja.paivitaAjatRajoille();
                    })
                }
                onRajallaChanged: {
                    txtAjokunnossa.teksti(pvm.getTime())
                }
                onSelvanaChanged: {
                    txtSelvana.teksti(pvm.getTime())
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
            var nyt = new Date()
            alkutilanne.aika = new Date(nyt.getFullYear(), nyt.getMonth(), nyt.getDate(), nyt.getHours(), nyt.getMinutes(), 0, 0)
            pvm = new Date(alkutilanne.aika.getTime() + minMs)
            kello0.valittuTunti0 = alkutilanne.aika.getHours()
            kello0.valittuMinuutti0 = alkutilanne.aika.getMinutes()
            juoja.paivita()
            kello.tausta = kello._backgroundColor
            paivays.tausta = paivays._backgroundColor
            //console.log("promilleja " + lahtoTaso + " ‰")
        }
    }
}
