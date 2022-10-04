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
import QtQuick.LocalStorage 2.0
import Nemo.Notifications 1.0

import "../scripts/unTap.js" as UnTpd
import "../scripts/scripts.js" as Apuja
import "../scripts/tietokanta.js" as Tkanta
import "../scripts/foursqr.js" as FourSqr
import "../components/"

Page {
    id: sivu

    property bool alustusKaynnissa: true
    property date pvm: new Date() // kello- ja päiväkohdissa oleva aika (sekunnit ja millisekunnit = 0.0, alustusta lukuunottamatta )
    property string kelloMuoto: "HH:mm"
    //property alias kuvaaja: kuvaaja
    property alias juomari: juomari

    //property var db: null
    property string virheet: ""

    property alias olutId: tuoppi.olutId // oluen unTappd-tunnus

    property alias nykyinenJuoma: txtJuoma.text
    property alias nykyinenMaara: txtMaara.text
    property alias nykyinenProsentti: voltit.text

    property bool unTpdKaytossa: false

    readonly property int msMinuutti: 60*1000
    readonly property int msPaiva: 24*60*msMinuutti
    readonly property int msVk: 7*msPaiva

    signal kysyAsetukset()

    Component.onCompleted: {
        //promillerivi.muutaPromillet()
        uTYhteys.unTpdOnkoUutisia()
    }
    onPvmChanged: {
        if (!alustusKaynnissa) {
            promillerivi.muutaPromillet();
        }
    }

    Connections {
        target: juoppoko
        onTiedotLuettu: {
            kuvaaja.alusta(juoja.juodunAika(0))
            aloitus.start()
            promillerivi.muutaPromillet()
            tuoppi.olutId = juomari.juodunOlutId()
            txtJuoma.text = juomari.juodunNimi()
            txtMaara.text = juomari.juodunTilavuus()
            voltit.text = juomari.juodunVahvuus()
        }
    }

    /*
    Connections {
        target: untpdKysely
        onFinishedQuery: { //QString: queryId, status, queryResponse
            var jsonVastaus;
            if (sivu.status === PageStatus.Active ) {
                console.log("Paaikkuna aktiivinen")
                console.log("vastaus tullut: " + queryId + ", " + queryStatus)
                try {
                    jsonVastaus = JSON.parse(queryResponse);
                    if (toiminto === "checkIn") {
                        unTpdKirjausTehty(jsonVastaus)
                    } else if (toiminto === "uutiset") {
                        unTpdIlmoitaUutisista(jsonVastaus)
                    } else if (toiminto === "kayttaja") {
                        if ("user" in jsonVastaus.response)
                            UnTpd.kayttaja = jsonVastaus.response.user.user_name
                    }
                } catch (err) {
                    console.log("" + err)
                }
            }
        }
    } // */

    Timer { // kellon ja promillien päivitys
        id: paivitys
        interval: 10*1000 //ms
        running: true
        repeat: true
        onTriggered: {
            paivitaAika()
        }
    }

    Timer { // keskeyttää kellon muuttumisen hetkeksi juoman tietoja syötettäessä
        id: keskeytaAika
        interval: 30*1000 // ms
        running: false
        repeat: false
        onTriggered: {
            kello.kay = true
            paivays.kay = true
            muutaAjanKirjasin()
            paivitaAika()
            running = false
        }
    }

    Timer {
        id: aloitus
        interval: 200 //5*1000
        running: false
        repeat: true
        onTriggered: {
            var jakso = kuvaaja.viikkoja*7, t0, t1, paiva1, h1, m1;
            if (eka) {
                m1 = Tkanta.vrkVaihtuu % 60;
                h1 = (Tkanta.vrkVaihtuu - m1)/60;
                nytPvm = new Date(nytPvm.getFullYear(), nytPvm.getMonth(), nytPvm.getDate(), h1, m1, 0);
                t1 = juoja.juodunAika() - Tkanta.vrkVaihtuu*msMinuutti;
                paiva1 = new Date(t1).getDay() - Qt.locale().firstDayOfWeek;
                if (paiva1 < 0) {
                    paiva1 += 7;
                }
                jakso = kuvaaja.viikkoja*7 + paiva1 + Apuja.paivaEro(t1, nytPvm.getTime());
                nPaivia = jakso;
                eka = false;
                interval = 200;
            } else {
                t1 = nytPvm.getTime() - nPaivia*msPaiva;
                nPaivia += jakso;
            }

            if ( t1 - jakso*msPaiva <= juoja.juodunAika(0)) {
                kuvaaja.lisaaJakso(juoja.juodunAika(0), t1);
                repeat = false;
                running = false;
                console.log("juodut lisätty")
            } else {
                kuvaaja.lisaaJakso(t1 - jakso*msPaiva, t1);
            }

            j++;
        }
        property bool eka: true
        property int j:0
        property int nPaivia: 0
        property date nytPvm: new Date()
        //property int kerralla: 100
    }

    XhttpYhteys {
        id: uTYhteys
        anchors.top: parent.top
        width: parent.width
        z: 1
        onValmis: {
            var jsonVastaus;
            try {
                if (toiminto === "checkIn") {
                    jsonVastaus = JSON.parse(httpVastaus);
                    unTpdKirjausTehty(jsonVastaus)
                } else if (toiminto === "uutiset") {
                    jsonVastaus = JSON.parse(httpVastaus);
                    unTpdIlmoitaUutisista(jsonVastaus)
                } else if (toiminto === "kayttaja") {
                    jsonVastaus = JSON.parse(httpVastaus);
                    if ("user" in jsonVastaus.response)
                        UnTpd.kayttaja = jsonVastaus.response.user.user_name
                }
            } catch (err) {
                console.log("" + err)
            }
        }

        property string ilmoitukset: ""

        function unTpdCheckIn() {
            var barId = "", naytaSijainti = false, leveys, pituus, huuto, tahtia;
            var osoite, kysely, face = "", twit = "", fsqr = "", vyohyketunnus;
            var vastaus;

            if (!unTpdKaytossa)
                return

            if (tuoppi.olutId == 0)
                return

            if (!kirjaus.kirjaaUnTp)
                return

            vyohyketunnus = Apuja.vyohyke(pvm.toLocaleTimeString());

            if (Tkanta.arvoTalletaSijainti > 0.5) {
                naytaSijainti = true;
                pituus = FourSqr.lastLong;
                leveys = FourSqr.lastLat;
                barId = kirjausAsetukset.baariNr
            }

            huuto = tuoppi.kuvaus;

            if (tuoppi.arvostelu > 0)
                tahtia = tuoppi.arvostelu/2 + 0.5
            else
                tahtia = 0;

            if (kirjausAsetukset.facebook)
                face = "on";
            if (kirjausAsetukset.foursqr)
                fsqr = "on";
            if (kirjausAsetukset.twitter)
                twit = "on";

            kysely = UnTpd.checkIn(olutId, vyohyketunnus, barId, naytaSijainti,
                                    leveys, pituus, huuto, tahtia, face, twit, fsqr);
            //osoite = vastaus[0];
            //kysely = vastaus[1];
            //osoite = UnTpd.checkInAddress();
            //kysely = UnTpd.checkInData(olutId, vyohyketunnus, barId, naytaSijainti,
            //                                  leveys, pituus, huuto, tahtia, face, twit, fsqr);

            xHttpPost(kysely[0], kysely[1], "checkIn");

            return
        }

        function unTpdKayttaja() {
            var kysely
            //toiminto = "kayttaja"
            //console.log("kysy käyttäjä")
            kysely = UnTpd.getUserInfo("", "true")
            xHttpGet(kysely[0], kysely[1], "kayttaja")
            return
        }

        function unTpdOnkoUutisia() {
            var kysely;
            //toiminto = "uutiset";
            //console.log("onko uutisia " + unTpdKaytossa)
            if (!unTpdKaytossa)
                return;

            kysely = UnTpd.getNotifications();//(offset, limit)

            xHttpGet(kysely[0], kysely[1], "uutiset");

            return
        }
    }

    SilicaFlickable {
        id: ylaosa
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("info")
                onClicked:
                    pageContainer.push(Qt.resolvedUrl("tietoja.qml"))
            }

            MenuItem {
                text: qsTr("settings")
                onClicked:
                    kysyAsetukset()
            }

            MenuItem {
                text: qsTr("foreteller")
                onClicked: {
                    console.log(juoja.lueMaksa(pvm) + ", lahtoTaso " +
                                juoja.promilleja(pvm) + ", paino " +
                                juoja.luePaino(pvm) + ", vetta " +
                                juoja.lueVesimaara(pvm))
                    pageContainer.push(Qt.resolvedUrl("demolaskuri.qml"), {
                                   "kunto": juoja.lueMaksa(pvm),
                                   "lahtoTaso": juoja.promilleja(pvm),
                                   "paino": juoja.luePaino(pvm),
                                   "pvm": pvm,
                                   "promilleRaja1": Tkanta.promilleRaja1,
                                   "vetta": juoja.lueVesimaara(pvm)
                                   })
                }
            }

        }

        PushUpMenu {
            id: utValikko
            //visible: unTpdKaytossa
            onActiveChanged: {
                busy = false
            }

            MenuItem {
                id: uTvalinta
                text: qsTr("unTappd %1").arg(_ilmoitus)
                visible: unTpdKaytossa
                onClicked: {
                    var s = pageContainer.push(Qt.resolvedUrl("unTpKayttaja.qml"),
                                               {"ilmoitukset": uTYhteys.ilmoitukset})
                    s.sulkeutuu.connect(function() {
                        tarkistaUnTpd() })
                }
                property string _ilmoitus: uutisia + pyyntoja === 0 ? "" : "("+ pyyntoja + " - " + uutisia + ")"
                property int uutisia: 0
                property int pyyntoja: 0
            }
            MenuItem {
                text: qsTr("Pints nearby")
                onClicked: {
                    var s = pageContainer.push(Qt.resolvedUrl("unTpPub.qml"),
                                               {"kaljarinki": "lahisto"} )
                    s.aloitaHaku()
                }
            }
            MenuItem {
                text: qsTr("Active friends")
                visible: unTpdKaytossa
                onClicked: {
                    var s = pageContainer.push(Qt.resolvedUrl("unTpPub.qml"),
                                           {"kaljarinki": "kaverit"} )
                    s.aloitaHaku()
                }
            }
        }

        Column {
            id: column
            anchors.fill: parent
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Drunkard?")
            }

            KulutusKuvaajat {
                id: kuvaaja
                width: parent.width - 2*x
                height: sivu.height/8
                pylvasKuvaaja.barWidth: Theme.fontSizeExtraSmall
                pylvasKuvaaja.labelWidth: pylvasKuvaaja.barWidth + 0.5*Theme.paddingSmall
                x: Theme.horizontalPageMargin
                onPitkaPainanta: {
                    tilastojenTarkastelu()
                }
                onAlussa: {
                    var ti
                    if (iJuoma >= 0) {
                        ti = juomari.juodunAika(iJuoma)
                        if (kertojaAlussa === 1) {
                            lisaaJakso(juomari.juodunAika(0), ti)
                        } else {
                            lisaaJakso(ti - viikkoja*msVk, ti)
                        }
                        kertojaAlussa++
                    }
                }

                property int iJuoma: -1
                property int kertojaAlussa: 0
                property int viikkoja: 20

                MouseArea {
                    anchors.fill: parent
                    z: -2
                    onPressAndHold: kuvaaja.tilastojenTarkastelu()
                }

                BusyIndicator {
                    id: kesken
                    size: BusyIndicatorSize.Medium
                    anchors.centerIn: parent
                    running: alustusKaynnissa//false
                }

                function lisaaJakso(alkuAika, loppuAika) {
                    //var maara, paivia;//, vp, pv, pp, hh, mm, ss, ms;
                    var alkuPaiva = new Date(alkuAika);
                    var loppuPaiva = new Date(loppuAika);

                    if (alkuAika === undefined) {
                        alkuAika = juoja.juodunAika(0);
                        alkuPaiva.setTime(alkuAika);
                    }
                    if (alkuPaiva.getHours() > Math.floor(Tkanta.vrkVaihtuu/60)) {
                        alkuPaiva.setHours(Math.floor(Tkanta.vrkVaihtuu/60));
                        alkuPaiva.setMinutes(Tkanta.vrkVaihtuu%60);
                        alkuPaiva.setSeconds(1);
                        alkuPaiva.setMilliseconds(0);
                        alkuAika = alkuPaiva.getTime();
                    }

                    if (loppuAika === undefined) {
                        loppuAika = juoja.juodunAika();
                        loppuPaiva.setTime(loppuAika);
                    }
                    if (loppuPaiva.getHours() > Math.floor(Tkanta.vrkVaihtuu/60)) {
                        loppuPaiva.setHours(Math.floor(Tkanta.vrkVaihtuu/60));
                        loppuPaiva.setMinutes(Tkanta.vrkVaihtuu%60);
                        loppuPaiva.setSeconds(1);
                        loppuPaiva.setMilliseconds(0);
                        loppuAika = loppuPaiva.getTime();
                    }

                    kesken.running = true;

                    //console.log("lisätään jaksoja " + alkuPaiva.getHours() + "." + (alkuPaiva.getMonth() + 1) + "." + alkuPaiva.getDate() + " - " + loppuPaiva.getFullYear() + "." + (loppuPaiva.getMonth() + 1) + "." + loppuPaiva.getDate())

                    while (loppuAika >= alkuAika) {
                        lisaa(loppuAika, juoja.paljonkoPaivassa(loppuAika, 1));
                        loppuAika -= msPaiva;
                    }

                    kesken.running = false;
                    return;
                }

                function tilastojenTarkastelu(){
                    var uusiTaulukko, uusiRyyppyVrk, aika, ml, juodut = [], dialog, i = 0;
                    while (i < juomari.annoksia) {
                        aika = juomari.juodunAika(i);
                        ml = juomari.juodunTilavuus(i)*juomari.juodunVahvuus(i)/100;
                        juodut[i] = {"ms": aika, "ml": ml};
                        i++
                    }

                    dialog = pageContainer.push(Qt.resolvedUrl("tilastot.qml"), {
                                                    "valittuKuvaaja": tyyppi,
                                                    "ryyppyVrk": vrkVaihtuu,
                                                    "juodut": juodut })

                    dialog.accepted.connect(function() {
                        uusiTaulukko = dialog.valittuKuvaaja;
                        uusiRyyppyVrk = dialog.ryyppyVrk;

                        if (tyyppi !== uusiTaulukko) {
                            tyyppi = uusiTaulukko;
                            Tkanta.nakyvaKuvaaja = uusiTaulukko;
                            Tkanta.paivitaAsetus(Tkanta.tunnusKuvaaja, uusiTaulukko);
                            kuvaaja.pylvasKuvaaja.positionViewAtEnd();
                        }
                        if (vrkVaihtuu !== uusiRyyppyVrk ) {
                            vrkVaihtuu = uusiRyyppyVrk;
                            Tkanta.vrkVaihtuu = uusiRyyppyVrk;
                            Tkanta.paivitaAsetus(Tkanta.tunnusVrkVaihdos, uusiRyyppyVrk);
                        }
                    })

                    return
                }

                function lisaaPaivat(loppuAika, paivia) {
                    var ajat, i = 0, iViikko = 0, vkoNro, vkPaiva, vuosi;
                    var paivassa, viikossa = 0;
                    if (loppuAika.getHours()*60 + loppuAika.getMinutes() < Tkanta.vrkVaihtuu) {
                        loppuAika.setTime(loppuAika.getTime() - vrkVaihtuu*msMinuutti);
                    }
                    ajat = maaritaAjat(loppuAika.getTime());
                    vuosi = ajat[0];
                    vkoNro = ajat[1];
                    vkPaiva = ajat[2];
                    while (i < paivia) {
                        paivassa = juoja.paljonkoPaivassa(loppuAika);
                        talletaPaivanArvo(vuosi, vkoNro, vkPaiva, paivassa);
                        loppuAika.setTime(loppuAika.getTime() - msPaiva);
                        viikossa += paivassa;
                        vkPaiva--;
                        if (vkPaiva <= 0) {
                            talletaViikonArvo(vuosi, vkoNro, viikossa);
                            vkPaiva = 7;
                            vkoNro--;
                            viikossa = 0;
                            if (vkoNro <= 0) {
                                ajat = maaritaAjat(loppuAika.getTime());
                                vuosi = ajat[0];
                                vkoNro = ajat[1];
                                vkPaiva = ajat[2];
                            }
                        }
                        i++;
                    }
                    return;
                }
            }

            Row { // promillet
                id: promillerivi
                spacing: 10
                width: parent.width
                property int luvunLeveys: (width - 2*spacing)/3

                TextField {
                    id: txtPromilleja
                    text: "X ‰"
                    width: parent.luvunLeveys
                    label: qsTr("BAC")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                    readOnly: true
                }

                TextField {
                    id: txtSelvana
                    text: "?"
                    label: qsTr("sober at")
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.luvunLeveys
                    color: Theme.highlightColor
                    readOnly: true
                }

                TextField {
                    id: txtAjokunnossa
                    text: "?"
                    label: qsTr("%1 ‰ at").arg(Tkanta.promilleRaja1.toFixed(1))
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.luvunLeveys
                    color: Theme.highlightColor
                    readOnly: true
                }

                function muutaPromillet() {
                    var prml = juoja.promilleja(pvm.getTime());

                    console.log("selvänä " + kellonaika(juoja.selvana()) +
                                ", rajalla " + kellonaika(juoja.rajalla()))

                    if (prml < 3.0){
                        txtPromilleja.text = "" + prml.toFixed(2) + " ‰";
                    } else {
                        txtPromilleja.text = "> 3.0 ‰";
                    }

                    // huomion keräys, jos promilleRajat ylittyvät
                    if ( prml < Tkanta.promilleRaja1 ) {
                        txtPromilleja.font.pixelSize = Theme.fontSizeMedium;
                        txtPromilleja.font.bold = false;
                    } else if( prml < Tkanta.promilleRaja2 ) {
                        txtPromilleja.font.pixelSize = Theme.fontSizeMedium;
                        txtPromilleja.font.bold = true;
                    } else {
                        txtPromilleja.font.pixelSize = Theme.fontSizeLarge;
                        txtPromilleja.font.bold = true;
                    }

                    if (pvm.getTime() > juoja.rajalla().getTime()) {//prml < Tkanta.promilleRaja1 //nytMs > juomari.rajalla.getTime()) // msKunnossa.getTime() // verrataan hetkeä nytMs listan viimeisen juoman jälkeiseen hetkeen
                        txtAjokunnossa.text = " -";
                    } else {
                        console.log("ajokunnossa " + kellonaika(juoja.rajalla()))
                        txtAjokunnossa.text = kellonaika(juoja.rajalla())
                    }

                    if (pvm.getTime() > juoja.selvana().getTime()) { //prml <= 0 // msSelvana.getTime()
                        txtSelvana.text = " -";
                    } else {
                        console.log("selvänä " + kellonaika(juoja.selvana()))
                        txtSelvana.text = kellonaika(juoja.selvana());
                    }

                    return;
                }

                /*
                function _paivitaAjatRajoille() {
                    //var juomaAika //, ms0, ml0, koko0, vahvuus0, i = Apuja.juotu.length - 1
                    var ms2, ms1, nyt = new Date().getTime();
                    var selvana, rajalla;

                    selvana = juoja.milloinPromilleja(0);
                    if ( nyt <= ms1 )
                        txtSelvana.text = kellonaika(ms1)
                    else
                        txtSelvana.text = " -"

                    ms2 = juomari.rajalla.getTime()
                    if ( nyt <= ms2 ) {
                        txtAjokunnossa.text = kellonaika(ms2)
                    }
                    else {
                        txtAjokunnossa.text = " -"
                    }

                    return
                } // */
            }

            Row { // nykyinen aika
                x: (column.width - kello.width - paivays.width)/3

                spacing: (column.width - x - kello.width - paivays.width - sivu.anchors.rightMargin)

                ValueButton {
                    id: kello
                    valueColor: Theme.primaryColor
                    width: Theme.fontSizeSmall*6
                    value: pvm.toLocaleTimeString(Qt.locale(),kelloMuoto)
                    onClicked: {
                        if (kello.kay == true)
                            openTimeDialog()
                        else {
                            kello.kay = true
                            paivays.kay = true
                            muutaAjanKirjasin()
                            paivitaAika()
                        }
                    }

                    property int valittuTunti: pvm.getHours()
                    property int valittuMinuutti: pvm.getMinutes()
                    property bool kay: true

                    function openTimeDialog() {
                        var dialog = pageContainer.push("Sailfish.Silica.TimePickerDialog", {
                                        hourMode: DateTime.TwentyFourHours,
                                        hour: valittuTunti,
                                        minute: valittuMinuutti
                                     });

                        dialog.accepted.connect(function() {
                            valittuTunti = dialog.hour;
                            valittuMinuutti = dialog.minute;
                            pvm = new Date(pvm.getFullYear(), pvm.getMonth(), pvm.getDate(), valittuTunti, valittuMinuutti, 0, 0);
                            value = pvm.toLocaleTimeString(Qt.locale(), kelloMuoto);

                            kello.kay = false;
                            keskeytaAika.running = true;
                            muutaAjanKirjasin();

                        })
                    }

                }

                ValueButton {
                    id: paivays
                    property date valittuPaiva: pvm
                    property bool kay: true

                    valueColor: Theme.primaryColor

                    value: pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    width: Theme.fontSizeSmall*8//sivu.width - kello.width - 3*Theme.paddingSmall
                    onClicked: {
                        if (paivays.kay == true)
                            avaaPaivanValinta()
                        else {
                            paivays.kay = true
                            kello.kay = true
                            muutaAjanKirjasin()
                            paivitaAika()
                        }
                    }

                    function avaaPaivanValinta() {
                        var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                        date: pvm
                                     });

                        dialog.accepted.connect(function() {
                            valittuPaiva = dialog.date;
                            pvm = new Date(valittuPaiva.getFullYear(), valittuPaiva.getMonth(), valittuPaiva.getDate(),
                                           pvm.getHours(), pvm.getMinutes(), 0, 0);
                            value = pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat);

                            paivays.kay = false;
                            keskeytaAika.running = true;
                            muutaAjanKirjasin();

                            //juomari.paivita(pvm.getTime());
                        })
                    }

                }

            } // aika

            Row { //lisattava juoma
                id: tuoppi
                property string kuvaus: ""
                property int olutId: 0 // oluen unTappd-tunnus
                property int arvostelu: 0
                //spacing: (sivu.width - txtJuoma.width - txtMaara.width - voltit.width - Theme.paddingMedium)/2

                function muutaUusi() {
                    var pv0 = pvm.getDate(), kk0 = pvm.getMonth(), vs0 = pvm.getFullYear();
                    var h0 = pvm.getHours(), m0 = pvm.getMinutes();

                    var dialog = pageContainer.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                                    "aika": pvm,
                                    "nimi": txtJuoma.text,
                                    "tilavuus": txtMaara.text,
                                    "vahvuus": voltit.text,
                                    "juomanKuvaus": tuoppi.kuvaus,
                                    "tilavuusMitta": Tkanta.arvoTilavuusMitta,
                                    "olutId": olutId,
                                    "tahtia": tuoppi.arvostelu
                                 });

                    dialog.rejected.connect(function() {
                        return tarkistaUnTpd();
                    })

                    dialog.accepted.connect(function() {
                        pvm = dialog.aika;

                        if ( (pvm.getDate() != pv0) || (pvm.getMonth() != kk0) || (pvm.getFullYear() != vs0)) {
                            paivays.value = dialog.aika.toLocaleDateString(Qt.locale(),Locale.ShortFormat);
                            paivays.kay = false;
                            keskeytaAika.running = true;
                            muutaAjanKirjasin();
                        }

                        if ((pvm.getHours() != h0) || (pvm.getMinutes() != m0)) {
                            kello.value = dialog.aika.toLocaleTimeString(Qt.locale(),kelloMuoto);
                            kello.kay = false;
                            keskeytaAika.running = true;
                            muutaAjanKirjasin();
                        }

                        txtJuoma.text = dialog.nimi;
                        txtMaara.text = dialog.tilavuus;
                        voltit.text = (dialog.vahvuus).toFixed(1);
                        tuoppi.kuvaus = dialog.juomanKuvaus;

                        tarkistaUnTpd();

                        olutId = dialog.olutId;
                        if (olutId <= 0){
                            kirjaus.kirjaaUnTp = false;
                        }

                        tuoppi.arvostelu = dialog.tahtia;

                        return;
                    })

                    return;
                }

                TextField {
                    id: txtJuoma
                    width: sivu.width - txtMaara.width - voltit.width
                    readOnly: true
                    color: Theme.primaryColor
                    placeholderText: qsTr("beer")
                    label: tuoppi.arvostelu > 0 ? "" + (tuoppi.arvostelu/2+0.5).toFixed(1) + "/5" : " "
                    onClicked: {
                        tuoppi.muutaUusi()
                    }

                }

                TextField {
                    id: txtMaara
                    label: "ml"
                    readOnly: true
                    color: Theme.primaryColor
                    text: "500"
                    width: font.pixelSize*4
                    onClicked: {
                        tuoppi.muutaUusi()
                    }
                }

                TextField {
                    id: voltit
                    label: qsTr("vol-%")
                    readOnly: true
                    color: Theme.primaryColor
                    text: "4.7"
                    width: font.pixelSize*4//Theme.fontSizeMedium*4
                    onClicked: {
                        tuoppi.muutaUusi()
                    }
                }

            }

            Row { // lisäys
                id: kirjaus
                x: unTpdKaytossa? Theme.paddingSmall : 0.5*(sivu.width - kulautus.width)
                spacing: (column.width - 2*x - txtBaari.width - kulautus.width - kirjausAsetukset.width)/2

                property bool kirjaaUnTp: true

                IconButton {
                    id: kirjausAsetukset
                    icon.source: "image://theme/icon-m-whereami"
                    onClicked: {
                        var dialog = pageContainer.push(Qt.resolvedUrl("unTpCheckIn.qml"), {
                                                            "face": facebook,
                                                            "foursq": foursqr,
                                                            "tweet": twitter
                                                        })

                        dialog.accepted.connect(function() {
                            baariNimi = dialog.baari;
                            baariNr = dialog.baarinTunnus;
                            if (baariNr != "")
                                Tkanta.arvoTalletaSijainti = 2;
                            if (dialog.naytaSijainti){
                                FourSqr.lastLat = dialog.lpiiri
                                FourSqr.lastLong = dialog.ppiiri
                                if (Tkanta.arvoTalletaSijainti == 0)
                                    Tkanta.arvoTalletaSijainti = 1
                            } else
                                Tkanta.arvoTalletaSijainti = 0;
                            if (facebook !== dialog.face)
                                Tkanta.paivitaAsetus(Tkanta.tunnusJulkaiseFacebook, dialog.face);
                            facebook = dialog.face;
                            if (foursqr !== dialog.foursq)
                                Tkanta.paivitaAsetus(Tkanta.tunnusJulkaiseFsqr, dialog.foursq);
                            foursqr = dialog.foursq;
                            if (twitter !== dialog.tweet)
                                Tkanta.paivitaAsetus(Tkanta.tunnusJulkaiseTwitter, dialog.tweet);
                            twitter = dialog.tweet;
                        })
                    }

                    property string baariNr: "-1"
                    property string baariNimi: ""
                    property bool   foursqr: false
                    property bool   facebook: false
                    property bool   twitter: false
                }

                TextField {
                    id: txtBaari
                    text: kirjaus.kirjaaUnTp? qsTr("check in") : qsTr("don't check in")
                    label: (kirjausAsetukset.baariNr == "")? qsTr("no location") : kirjausAsetukset.baariNimi
                    color: !enabled? Theme.highlightDimmerColor : (kirjaus.kirjaaUnTp? Theme.primaryColor : Theme.secondaryColor)
                    readOnly: true
                    visible: unTpdKaytossa
                    enabled: olutId > 0 ? true : false

                    width: column.width - kulautus.width -
                           kirjausAsetukset.width - 2*kirjaus.x

                    onClicked: kirjaus.kirjaaUnTp = !kirjaus.kirjaaUnTp
                }

                Button { //add
                    id: kulautus
                    y: txtBaari.y + 0.5*(txtBaari.height - height)
                    text: qsTr("cheers!")
                    onClicked: {
                        var nyt = new Date().getTime(), juomaAika = pvm.getTime();
                        uusiJuoma(nyt, juomaAika, parseInt(txtMaara.text),
                                 parseFloat(voltit.text), txtJuoma.text, tuoppi.kuvaus, olutId);
                        paivays.kay = true;
                        kello.kay = true;
                        muutaAjanKirjasin();
                        paivitaAika();
                        uTYhteys.unTpdCheckIn();
                        tuoppi.kuvaus = ""
                    }
                }

            } // untappd

            Separator {
                width: 0.9*sivu.width
                x: 0.05*sivu.width
                color: Theme.highlightDimmerColor
            }

            Juomari {
                id: juomari
                height: (sivu.height - y > oletusKorkeus) ? sivu.height - y : oletusKorkeus
                width: parent.width
                alustus: alustusKaynnissa
                onJuomaPoistettu: { // signaali (string tkTunnus, int paivia, int kello, real holia)
                    Tkanta.poistaTkJuodut(tkTunnus);
                    juoja.poistaJuoma(tkTunnus);
                    promillerivi.muutaPromillet();
                    kuvaaja.lisaa(paivia*msPaivassa + kello, -holia);
                }
                //onLuettuChanged: { // ensimmäisellä kerralla ohjelma kysyy käyttäjän tiedot, uutisten kysely sotkee tätä
                //    if (!alustusKaynnissa && unTpdKaytossa)
                //        uTYhteys.unTpdOnkoUutisia()
                //}
                onMuutaJuomanTiedot: { // signaali (int iMuutettava) // hetki, maara, vahvuus, nimi, kuvaus, oId
                    var dialog = pageContainer.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                                    "aika": new Date(juodunAika(iMuutettava)),
                                    "nimi": juodunNimi(iMuutettava),
                                    "tilavuus": juodunTilavuus(iMuutettava),
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
                        var vanhaHetki = juodunAika(iMuutettava)
                        var vanhanAlkoholi = juodunTilavuus(iMuutettava)*juodunVahvuus(iMuutettava)/100
                        muutaJuoma(iMuutettava, ms, dialog.tilavuus, dialog.vahvuus, dialog.nimi,
                                   dialog.juomanKuvaus, dialog.olutId);
                        Tkanta.muutaTkJuodut(juodunTunnus(iMuutettava), ms, dialog.tilavuus,
                                             dialog.vahvuus, dialog.nimi, dialog.juomanKuvaus,
                                             dialog.olutId); //, juodunPohjilla(iMuutettava)
                        //paivita();
                        //paivitaAjatRajoille();
                        juoja.muutaJuoma(juodunTunnus(iMuutettava), dialog.maara,
                                         dialog.vahvuus*0.01, new Date(ms));
                        promillerivi.muutaPromillet();
                        kuvaaja.lisaa(vanhaHetki, -vanhanAlkoholi);
                        kuvaaja.lisaa(ms, dialog.tilavuus*dialog.vahvuus/100);
                        tarkistaUnTpd();
                    })
                }
                //onPromillejaChanged: {
                //    if (!alustusKaynnissa) {
                //        muutaPromillet()
                //    }
                //}
                onValittuJuomaChanged: {
                    txtJuoma.text = juomari.juodunNimi(valittuJuoma) //valitunNimi //Apuja.juomanNimi(i)
                    txtMaara.text = juomari.juodunTilavuus(valittuJuoma) //valitunTilavuus //lueJuomanMaara(qId)
                    voltit.text = juomari.juodunVahvuus(valittuJuoma) //valitunVahvuus //lueJuomanVahvuus(qId)
                    tuoppi.olutId = juomari.juodunOlutId(valittuJuoma) //valitunOlutId //Apuja.juomanId(i)
                    UnTpd.olutVaihtuu(tuoppi.olutId)
                    tuoppi.arvostelu = 0
                }

                //property bool luettu: false

            }

        } //column

    }// SilicaFlickable

    //   TIETOKANNAT
    //
    //  juoppoko-tietokanta, aika = kokonaisluku = ms hetkestä 0:00:00.000, 1.1.1970
    //  juodut -    id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus, oluenId
    //  asetukset - asia, arvo
    //  juomari -   aika, paino, neste, maksa
    //  suosikit -  id, juoma, suosio, kuvaus, tilavuus, prosentti (ei käytössä tällä hetkellä)
    //

    function kellonaika(aika) { // aika = Date()
        // kirjoittaa kellonajan halutussa muodossa
        var tunnit = aika.getHours();
        var minuutit = aika.getMinutes();
        var teksti;
        if (tunnit < 10) {
            teksti = "0" + tunnit + ":";
        } else {
            teksti = "" + tunnit + ":";
        }
        if (minuutit < 10) {
            teksti = teksti + "0" + minuutit;
        } else {
            teksti = teksti + minuutit;
        }

        return teksti;
    }

    function muutaAjanKirjasin() {

        if (kello.kay == false){
            kello.valueColor = Theme.secondaryColor;
        } else {
            kello.valueColor = Theme.primaryColor;
        }

        if (paivays.kay == false){
            paivays.valueColor = Theme.secondaryColor;
        } else {
            paivays.valueColor = Theme.primaryColor;
        }

        return;
    }

    function paivitaAika() {
        var paiva = new Date();

        if ( (kello.kay === true) && (paivays.kay === true)) {
            pvm = paiva;
            kello.valittuTunti = paiva.getHours();
            kello.valittuMinuutti = paiva.getMinutes();
            kello.value = kellonaika(paiva);
            paivays.value = paiva.toLocaleDateString(Qt.locale(),Locale.ShortFormat);
            paivays.valittuPaiva.setTime(paiva.getTime());
        }

        return;
    }

    function tarkistaUnTpd() {
        if (UnTpd.unTpToken > "") {
            unTpdKaytossa = true;
        } else {
            unTpdKaytossa = false;
        }

        return unTpdKaytossa;
    }

    function uusiJuoma(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId) {
        Tkanta.lisaaTkJuodut(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId);

        juomari.juo(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId);
        juoja.juo(tkId, tilavuus, vahvuus, hetki);

        kuvaaja.lisaa(hetki, tilavuus*vahvuus/100);

        promillerivi.muutaPromillet();

        return;
    }

    function unTpdKirjausTehty(jsonVastaus) {
        //console.log(JSON.stringify(vastaus))
        if ("meta" in jsonVastaus) {
            if (jsonVastaus.meta.code === 200){
                uTYhteys.onnistui = true;
                uTYhteys.viesti = jsonVastaus.response.result;

                if (jsonVastaus.response.badges.count > 0) {
                    UnTpd.newBadges = jsonVastaus.response.badges;
                    UnTpd.newBadgesSet = true;
                    pageContainer.push(Qt.resolvedUrl("unTpAnsiomerkit.qml"), {
                                       "haeKaikki": false, "naytaKuvaus": true })
                }
            } else {
                uTYhteys.onnistui = false;
                uTYhteys.viesti = jsonVastaus.meta.error_detail
            }
        } else {
            uTYhteys.onnistui = false;
            uTYhteys.viesti = qsTr("some error in transmission")
        }

        uTYhteys.naytaViesti = true;

        return
    }

    function unTpdIlmoitaUutisista(jsonVastaus) {
        var maara
        //console.log(JSON.stringify(jsonVastaus))
        //console.log(" ilmoita uutisista !!")
        uTYhteys.ilmoitukset = JSON.stringify(jsonVastaus)
        if ("notifications" in jsonVastaus && "unread_count" in jsonVastaus.notifications) {
            maara = jsonVastaus.notifications.unread_count.friends
            if (maara > 0) {
                uTvalinta.pyyntoja = maara*1
                utValikko.busy = true
            }
            maara = jsonVastaus.notifications.unread_count.news
            if (maara > 0) {
                uTvalinta.uutisia = maara*1
            }
            //console.log(jsonVastaus.response.news.count + " notes" )
        }
        return
    }

}
