import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"
import "../scripts/tietokanta.js" as Tkanta

Page {
    id: sivu

    property real   kunto: 1
    property real   lahtoTaso: 0 // g alkoholia / g vettä
    property real   paino: 77
    property real   promilleRaja1: 0.5
    property date   pvm: new Date()
    property real   vetta: 0.7
    property bool   valmista: false
    readonly property string kelloMuoto: "HH:mm"
    readonly property int    minMs: 60*1000

    onPvmChanged: {
        //console.log("pvm vaihtui ")
        if (valmista) {
            paivita()
        }
    }
    Component.onCompleted: {
        console.log("testaajan alustus " + lahtoTaso)
        testaaja.asetaKeho(paino, vetta, kunto, 0)
        testaaja.asetaPohjaPromillet(lahtoTaso, pvm.getTime())
        testaaja.asetaPromilleraja(promilleRaja1)
        paivita()
        valmista = true
        console.log("testaaja alustettu")
    }

    SilicaFlickable {
        id: ylaosa
        anchors.fill: parent
        contentHeight: sisalto.height

        Component.onCompleted: {
            kello.tausta = kello._backgroundColor
            paivays.tausta = paivays._backgroundColor
            //console.log("promilleja " + lahtoTaso + " ‰")
        }

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
            id: sisalto

            width: parent.width

            PageHeader {
                title: qsTr("Foreteller")
            }

            ModExpandingSection {
                id: alku
                title: qsTr("drinker")
                width: parent.width
                //font.pixelSize: Theme.fontSizeMedium
                content.sourceComponent: Column {
                    width: alku.width - x
                    x: Theme.horizontalPageMargin

                    TextField {
                        id: vesimaara
                        text: (vetta*100).toFixed(0)
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: IntValidator {bottom: 0; top: 100}
                        EnterKey.iconSource: "image://theme/icon-m-play"
                        EnterKey.onClicked: {
                            vetta = text*0.01
                            testaaja.asetaVesimaara(vetta, 0);
                            laskeUudelleen()
                            focus = false
                        }
                        label: qsTr("water %1").arg("[%]")
                        width: parent.width
                        placeholderText: qsTr("body water content")
                    }

                    TextField {
                        id: massa
                        text: paino
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: IntValidator {bottom: 1; top: 1000}
                        EnterKey.iconSource: "image://theme/icon-m-play"
                        EnterKey.onClicked: {
                            paino = text*1.0
                            testaaja.asetaPaino(paino, 0)
                            laskeUudelleen()
                            focus = false
                        }

                        label: qsTr("weight %1").arg("[kg]")
                        width: parent.width
                        placeholderText: qsTr("weight of the drinker")
                    }

                    TextField {
                        id: maksa
                        text: (kunto*100).toFixed(0)
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: IntValidator {bottom: 1; top: 200}
                        EnterKey.iconSource: "image://theme/icon-m-play"
                        EnterKey.onClicked: {
                            kunto = text*0.01
                            testaaja.asetaMaksa(kunto, 0)
                            laskeUudelleen()
                            focus = false
                        }

                        label: qsTr("lever condition %1").arg("[%]")
                        width: parent.width
                        placeholderText: qsTr("lever condition %1").arg("[%]")
                    }

                    TextField {
                        id: raja
                        text: Number(promilleRaja1).toLocaleString(Qt.locale())
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator {bottom: 0.0; top: 5.0}
                        EnterKey.iconSource: "image://theme/icon-m-play"
                        EnterKey.onClicked: {
                            promilleRaja1 = Number.fromLocaleString(Qt.locale(), text)
                            txtAjokunnossa.teksti()
                            focus = false
                        }
                        label: qsTr("limit %1").arg("[‰]")
                        width: parent.width
                        placeholderText: qsTr("blood alcohol content limit")
                    }

                    SectionHeader {
                        text: qsTr("starting point")
                    }

                    // pohjat
                    Row {
                        //id: alkutilanne
                        width: parent.width

                        TextField {
                            id: pohjat
                            text: Number(lahtoTaso).toLocaleString(Qt.locale())
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator {bottom: 0.0; top: 5.0}
                            EnterKey.iconSource: "image://theme/icon-m-play"
                            EnterKey.onClicked: {
                                testaaja.asetaPohjaPromillet(Number.fromLocaleString(Qt.locale(), text), alku.alkuaika.getTime())
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
                            value: alku.alkuaika.toLocaleTimeString(Qt.locale(), kelloMuoto)
                            valueColor: Theme.primaryColor
                            onClicked: {
                                    openTimeDialog0()
                            }
                            property int valittuTunti0: alku.alkuaika.getHours()
                            property int valittuMinuutti0: alku.alkuaika.getMinutes()

                            function openTimeDialog0() {
                                var dialog = pageContainer.push("Sailfish.Silica.TimePickerDialog", {
                                                hourMode: DateTime.TwentyFourHours,
                                                hour: kello0.valittuTunti0,
                                                minute: kello0.valittuMinuutti0
                                             })

                                dialog.accepted.connect(function() {
                                    valittuTunti0 = dialog.hour;
                                    valittuMinuutti0 = dialog.minute;
                                    alku.alkuaika = new Date(alku.alkuaika.getFullYear(),
                                                                alku.alkuaika.getMonth(),
                                                                alku.alkuaika.getDate(),
                                                                valittuTunti0, valittuMinuutti0, 0, 0);
                                    kello0.value = alku.alkuaika.toLocaleTimeString(Qt.locale(), kelloMuoto);
                                    testaaja.asetaPohjaPromillet(Number.fromLocaleString(Qt.locale(), pohjat.text), alku.alkuaika.getTime());
                                    laskeUudelleen();
                                })
                            }

                        }

                        ValueButton {
                            id: paivays0
                            value: alku.alkuaika.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
                            valueColor: Theme.primaryColor
                            width: Theme.fontSizeMedium*8 //sivu.width - kello.width - pohjat.width - Theme.fontSizeMedium*2 - 4*Theme.paddingSmall
                            onClicked: {
                                avaaPaivanValinta()
                            }

                            function avaaPaivanValinta() {
                                var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                                date: alku.alkuaika
                                             })

                                dialog.accepted.connect(function() {
                                    alku.alkuaika = new Date(dialog.date.getFullYear(),
                                                                dialog.date.getMonth(),
                                                                dialog.date.getDate(),
                                                                alku.alkuaika.getHours(),
                                                                alku.alkuaika.getMinutes(), 0, 0);
                                    value = alku.alkuaika.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
                                    testaaja.asetaPohjaPromillet(Number.fromLocaleString(Qt.locale(), text), alku.alkuaika.getTime());
                                    laskeUudelleen();
                                })
                            }
                        }
                    }

                }

                property date alkuaika: new Date(pvm.getTime())
            }

            Row { // promillet
                spacing: 10

                TextField {
                    text: juomari.promilleja < 3.0 ? juomari.promilleja.toFixed(2) + " ‰" : "> 3.0 ‰"
                    label: qsTr("BAC")//qsTr("BAC at %1").arg(kello.value)
                    readOnly: true
                    font.pixelSize: juomari.promilleja < promilleRaja1? Theme.fontSizeMedium : Theme.fontSizeLarge
                    font.bold: juomari.promilleja < promilleRaja1? false : true
                    color: Theme.highlightColor
                    width: Theme.fontSizeSmall*8
                }

                TextField {
                    id: txtSelvana
                    text: "?"
                    label: qsTr("sober at")
                    readOnly: true
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    width: Theme.fontSizeSmall*6

                    function teksti() {
                        if (testaaja.selvana().toLocaleTimeString(Qt.locale(), kelloMuoto) == "" ||
                                pvm.getTime() > testaaja.selvana().getTime()) {
                            text = " -";
                        } else {
                            text = testaaja.selvana().toLocaleTimeString(Qt.locale(), kelloMuoto);
                        }
                        console.log("selvänä " + testaaja.selvana().toLocaleTimeString(Qt.locale(), kelloMuoto) + " -- " + testaaja.selvana().getTime());
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

                    function teksti() {
                        if (testaaja.rajalla().toLocaleTimeString(Qt.locale(), kelloMuoto) == "" ||
                                pvm.getTime() > testaaja.rajalla().getTime()) {
                            text = " -";
                        } else {
                            text = testaaja.rajalla().toLocaleTimeString(Qt.locale(), kelloMuoto);
                        }
                        //console.log("rajalla " + testaaja.rajalla().toLocaleTimeString(Qt.locale(), kelloMuoto) + " " + testaaja.rajalla().getTime());

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
                    value: pvm.toLocaleTimeString(Qt.locale(), kelloMuoto)
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
                                     });

                        dialog.accepted.connect(function() {
                            valittuTunti = dialog.hour;
                            valittuMinuutti = dialog.minute;
                            pvm = new Date(pvm.getFullYear(), pvm.getMonth(), pvm.getDate(), valittuTunti, valittuMinuutti, 0, 0);
                            if (pvm.getTime() < alku.alkuaika.getTime()) {
                                kello._backgroundColor = Theme.highlightColor;
                                paivays._backgroundColor = Theme.highlightColor;
                            } else {
                                kello._backgroundColor = kello.tausta;
                                paivays._backgroundColor = paivays.tausta;
                            }
                        })
                    }

                }

                ValueButton {
                    id: paivays
                    value: pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
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
                            //paivita();
                            //laskeUudelleen();
                        })
                    }

                }
            } // aika

            Row { //lisattava juoma
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

            }

            SectionHeader {
                text: qsTr("juodut")
            }

            Juomari {
                id: juomari
                width: parent.width
                height: (sivu.height - y) > oletusKorkeus? sivu.height - y : oletusKorkeus
                property int jId: 0
                property real promilleja: 0
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
                        testaaja.muutaJuoma(juodunTunnus(iMuutettava), dialog.maara, dialog.vahvuus*0.01,
                                            new Date(ms));
                        paivita();
                    })
                }
                onJuomaPoistettu: {
                    testaaja.poistaJuoma(tkTunnus)
                    paivita()
                }

                onValittuJuomaChanged: {
                    txtJuoma.text = juodunNimi(valittuJuoma) //valitunNimi //Apuja.juomanNimi(i)
                    txtMaara.text = juodunTilavuus(valittuJuoma) //valitunTilavuus //lueJuomanMaara(qId)
                    voltit.text = juodunVahvuus(valittuJuoma) //valitunVahvuus //lueJuomanVahvuus(qId)
                }
            }

        }

    }

    function muutaUusi() {
        var pv0 = pvm.getDate(), kk0 = pvm.getMonth(), vs0 = pvm.getFullYear();
        var h0 = pvm.getHours(), m0 = pvm.getMinutes();

        var dialog = pageContainer.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                        "aika": pvm,
                        "nimi": txtJuoma.text,
                        "maara": txtMaara.text,
                        "vahvuus": voltit.text,
                        "juomanKuvaus": ""
                     });

        dialog.accepted.connect(function() {
            pvm = dialog.aika;

            if ( (pvm.getDate() != pv0) || (pvm.getMonth() != kk0) || (pvm.getFullYear() != vs0)) {
                paivays.value = dialog.aika.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
            }

            if ((pvm.getHours() != h0) || (pvm.getMinutes() != m0)) {
                kello.value = dialog.aika.toLocaleTimeString(Qt.locale(), kelloMuoto);
            }

            txtJuoma.text = dialog.nimi;
            txtMaara.text = dialog.maara;
            voltit.text = dialog.vahvuus;

            return;
        })

        return;
    }

    function laskeUudelleen() {
        testaaja.laskeUudelleen();
        paivita();
        return;
    }

    function paivita() {
        //console.log(pvm.toLocaleTimeString() + "=" + pvm.getTime() + " -||- " + testaaja.promilleja(pvm.getTime()))
        juomari.promilleja = testaaja.promilleja(pvm.getTime());
        txtSelvana.teksti();
        txtAjokunnossa.teksti();
        return;
    }

    function uusiJuoma(hetki, maara, vahvuus, juomanNimi) {
        console.log("tää ");
        juomari.jId++;
        testaaja.juo(juomari.jId, maara, vahvuus, hetki);
        juomari.juo(juomari.jId, hetki, maara, vahvuus, juomanNimi);
        paivita();
        pvm = new Date(pvm.getTime() + minMs);
        return;
    }
}
