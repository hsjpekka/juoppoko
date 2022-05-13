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
import QtPositioning 5.2
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
    //property alias juomari: juoja

    property var db: null
    property string virheet: ""

    property alias olutId: tuoppi.olutId // oluen unTappd-tunnus

    property alias nykyinenJuoma: txtJuoma.text
    property alias nykyinenMaara: txtMaara.text
    property alias nykyinenProsentti: voltit.text

    property bool unTpdKaytossa: false

    //   TIETOKANNAT
    //
    //  juoppoko-tietokanta, aika = kokonaisluku = ms hetkestä 0:00:00.000, 1.1.1970
    //  juodut -    id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus, oluenId
    //  asetukset - asia, arvo
    //  juomari -   aika, paino, neste, maksa
    //  suosikit -  id, juoma, suosio, kuvaus, tilavuus, prosentti (ei käytössä tällä hetkellä)
    //

    function alkutoimet(){
        juoja.muutaPromillet();
        paivitaAjatRajoille();
        juoja.nakyma.positionViewAtEnd();

        if (!juoja.luettu)
            kysyAsetukset()
        else if (unTpdKaytossa) {
            uTYhteys.unTpdKayttaja()
            uTYhteys.unTpdOnkoUutisia()
        }
        return
    }

    function avaaDb() {

        if(db == null) {
            try {
                db = LocalStorage.openDatabaseSync("juoppoko", "0.1", "juodun alkoholin paivyri", 10000);
            } catch (err) {
                console.log("Error in opening the database: " + err);
                virheet = virheet + "Error in opening the database: " + err +" <br> "
            };
        }

        Tkanta.tkanta = db;
        Tkanta.luoTaulukot();
        return;
    }

    function kellonaika(ms) {
        // kirjoittaa kellonajan halutussa muodossa
        var tunnit = new Date(ms).getHours();
        var minuutit = new Date(ms).getMinutes();
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

    function kysyAsetukset() {
        var dialog = pageContainer.push(Qt.resolvedUrl("asetukset.qml"), {
                                        "massa0": juomari.luePaino(), "vetta0": juomari.lueVesimaara(),
                                        "kunto0": juomari.lueMaksa(),
                                        "prom10": Tkanta.promilleRaja1, "prom20": Tkanta.promilleRaja2,
                                        "paiva10": Tkanta.vrkRaja1, "paiva20": Tkanta.vrkRaja2,
                                        "viikko10": Tkanta.vkoRaja1, "viikko20": Tkanta.vkoRaja2,
                                        "vuosi10": Tkanta.vsRaja1, "vuosi20": Tkanta.vsRaja2,
                                        "palonopeus": juomari.polttonopeus(1.0,1.0)//juoja.polttonopeusVakio
                                    })
        dialog.accepted.connect(function() {
            if (juomari.luePaino() != dialog.massa || juomari.lueVesiMaara() != dialog.vetta ||
                    juomari.lueMaksa() != dialog.kunto ){
                juomari.asetaKeho(dialog.massa, dialog.vetta, dialog.kunto, pvm.getTime() - Tkanta.vrkVaihtuu*60*1000)
                // Tkanta.uusiJuomari(juoja.paino, juoja.vetta, juoja.maksa, pvm.getTime())
            }
            juoja.luettu = true

            Tkanta.promilleRaja1 = dialog.prom1
            Tkanta.paivitaAsetus(Tkanta.tunnusProm1, Tkanta.promilleRaja1)
            Tkanta.promilleRaja2 = dialog.prom2
            Tkanta.paivitaAsetus(Tkanta.tunnusProm2, Tkanta.promilleRaja2)
            Tkanta.vrkRaja1 = dialog.paiva1
            Tkanta.paivitaAsetus(Tkanta.tunnusVrkRaja1, Tkanta.vrkRaja1)
            Tkanta.vrkRaja2 = dialog.paiva2
            Tkanta.paivitaAsetus(Tkanta.tunnusVrkRaja2, Tkanta.vrkRaja2)
            Tkanta.vkoRaja1 = dialog.viikko1
            Tkanta.paivitaAsetus(Tkanta.tunnusVkoRaja1, Tkanta.vkoRaja1)
            Tkanta.vkoRaja2 = dialog.viikko2
            Tkanta.paivitaAsetus(Tkanta.tunnusVkoRaja2, Tkanta.vkoRaja2)
            Tkanta.vsRaja1 = dialog.vuosi1
            Tkanta.paivitaAsetus(Tkanta.tunnusVsRaja1, Tkanta.vsRaja1)
            Tkanta.vsRaja2 = dialog.vuosi2
            Tkanta.paivitaAsetus(Tkanta.tunnusVsRaja2, Tkanta.vsRaja2)

            juomari.asetaPromilleraja(dialog.prom1)
            juoja.promilleRaja = Tkanta.promilleRaja1

            tarkistaUnTpd()
            if (unTpdKaytossa) {
                uTYhteys.unTpdKayttaja()
                uTYhteys.unTpdOnkoUutisia()
            }
            //juoja.paivita()
        })

        dialog.rejected.connect(function() {
            tarkistaUnTpd()
            if (unTpdKaytossa) {
                uTYhteys.unTpdKayttaja()
                uTYhteys.unTpdOnkoUutisia()
            }
        })

        return
    }

    function lueAsetukset() {
        var luettu = Tkanta.lueTkAsetukset();

        UnTpd.unTpToken = Tkanta.arvoUnTpToken;
        kuvaaja.tyyppi = Tkanta.nakyvaKuvaaja;
        kuvaaja.riskiPvAlempi = Tkanta.vrkRaja1;
        kuvaaja.riskiPvYlempi = Tkanta.vrkRaja2;
        kuvaaja.riskiVkoAlempi = Tkanta.vkoRaja1;
        kuvaaja.riskiVkoYlempi = Tkanta.vkoRaja2;
        kuvaaja.vrkVaihtuu = Tkanta.vrkVaihtuu;
        juomari.asetaVrkVaihdos(Tkanta.vrkVaihtuu);
        juoja.promilleRaja = Tkanta.promilleRaja1;
        juomari.asetaPromilleraja(Tkanta.promilleRaja1);

        return luettu
    }

    function lueJuodut(kaikki, alkuAika, loppuAika) { //jos kaikki=true, alku- ja loppuajalla ei merkitystä
        var taulukko = Tkanta.lueTkJuodut(kaikki, alkuAika, loppuAika).rows;
        var i = 0, maara, tmp;

        console.log(qsTr("%1 drinks, latest %2").arg(taulukko.length).arg(taulukko[taulukko.length-1].juoma))

        //tmp = new Date()
        while (i < taulukko.length) {
            juoja.juo(taulukko[i].id, taulukko[i].aika,
                      taulukko[i].tilavuus, taulukko[i].prosenttia,
                      taulukko[i].juoma, taulukko[i].kuvaus, taulukko[i].oluenId);
            juomari.juo(taulukko[i].id, taulukko[i].tilavuus,
                        taulukko[i].prosenttia, taulukko[i].aika, false);
            i++;
        }

        return;
    }

    function lueTiedostot() {
        var ehto = 0, i, nyt = new Date().getTime(); //, vkoNyt
        var keho = [], paino, vetta, maksa;
        var vrk = 24*60*60*1000; // t0 = new Date(0).getTimezoneOffset()*minuutti,

        avaaDb();
        lueAsetukset();

        if (UnTpd.unTpToken > "")
            unTpdKaytossa = true
        else
            unTpdKaytossa = false;

        keho = Tkanta.lueTkJuomari();
        if (keho.length > 0){
            i = 0;
        } else {
            i = -1;
        }

        while (i < keho.length) {
            paino = keho[i].paino;
            vetta = keho[i].neste;
            maksa = keho[i].maksa;
            if (paino < 1) {
                console.log("mass < 1 kg, changed to 75 kg");
                paino = 75;
            }
            if (vetta < 0.01) {
                console.log("body water content < 1 %, changed to 70%");
                vetta = 0.7;
            }
            if (maksa < 0.01) {
                console.log("lever condition < 1 %, changed to 100%");
                maksa = 1.0;
            }
            juomari.asetaKeho(paino, vetta, maksa, keho[i].aika);
            i++;
        }
        if (i >= 0) {
            juoja.luettu = true;
        }

        /*
        if (keho[0] > 1 ){
            juomari.asetaKeho(keho[0], keho[1], keho[2]); //juoja.paino = keho[0] //massa = keho[0];
            juoja.vetta = keho[1]; //vetta = keho[1];
            juoja.maksa = keho[2]; //kunto = keho[2];
            if (juoja.paino < 1) {
                console.log("mass < 1 kg, changed to 75 kg")
                juoja.paino = 75
            }
            if (juoja.vetta < 0.01) {
                console.log("body water content < 1 %, changed to 70%")
                juoja.vetta = 0.7
            }
            if (juoja.maksa < 0.01) {
                console.log("lever condition < 1 %, changed to 100%")
                juoja.maksa = 1.0
            }
            juoja.luettu = true;
            juomari.asetaKeho(keho[0], keho[1], keho[2]);

        } // */

        lueJuodut(true, pvm.getTime() - 365*vrk, pvm.getTime()); // true = kaikki, false = aikarajojen välissä olevat

        if (juoja.annoksia > 0) {
            txtJuoma.text = juoja.juodunNimi(juoja.annoksia-1); //lueJuomanNimi(juomat.count-1)
            txtMaara.text = juoja.juodunTilavuus(juoja.annoksia-1); //lueJuomanMaara(juomat.count-1)
            voltit.text = juoja.juodunVahvuus(juoja.annoksia-1); //lueJuomanVahvuus(juomat.count-1)
            olutId = juoja.juodunOlutId(juoja.annoksia-1); //lueOluenId(juomat.count-1)
        }

        return;
    }

    function muutaAjanKirjasin() {

        if (kello.kay == false){
            kello.valueColor = Theme.secondaryColor
            //kello.valueColor = Theme.highlightColor

        } else {
            kello.valueColor = Theme.primaryColor
            //kello.valueColor = Theme.highlightColor
        }

        if (paivays.kay == false){
            //paivays.valueColor = Theme.highlightColor
            paivays.valueColor = Theme.secondaryColor
        } else {
            //paivays.valueColor = Theme.highlightColor
            paivays.valueColor = Theme.primaryColor
        }

        return
    }

    function paivitaAika() {
        var paiva = new Date()

        if ( (kello.kay == true) && (paivays.kay == true)) {
            pvm = paiva
            kello.valittuTunti = paiva.getHours()
            kello.valittuMinuutti = paiva.getMinutes()
            kello.value = kellonaika(paiva.getTime())
            paivays.value = paiva.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
            paivays.valittuPaiva.setTime(paiva.getTime())
        }

        return;
    }

    function paivitaAjatRajoille() {
        //var juomaAika //, ms0, ml0, koko0, vahvuus0, i = Apuja.juotu.length - 1
        var ms2, ms1, nyt = new Date().getTime()

        ms1 = juoja.selvana.getTime()
        if ( nyt <= ms1 )
            txtSelvana.text = kellonaika(ms1)
        else
            txtSelvana.text = " -"

        ms2 = juoja.rajalla.getTime()
        if ( nyt <= ms2 ) {
            txtAjokunnossa.text = kellonaika(ms2)
        }
        else {
            txtAjokunnossa.text = " -"
        }

        return
    }

    function tarkistaUnTpd() {
        if (UnTpd.unTpToken > "")
            unTpdKaytossa = true
        else
            unTpdKaytossa = false

        return unTpdKaytossa
    } // */

    function uusiJuoma(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId) {
        Tkanta.lisaaTkJuodut(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId);

        juoja.juo(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId);
        juomari.juo(tkId, tilavuus, vahvuus, hetki);

        kuvaaja.lisaa(hetki, tilavuus*vahvuus/100)

        paivitaAjatRajoille();

        return;
    }

    Timer {
        id: paivitys
        interval: 10*1000 //ms
        running: true
        repeat: true
        onTriggered: {
            paivitaAika()
            i0++
            if (i0 >= iN) {
                juoja.paivita()
                i0 = 0
            }
        }
        property int i0: 0
        property int iN: 2*6 // promillet päivitetään kahden minuutin välein
    }

    Timer {
        id: keskeytaAika
        interval: 20*1000 //
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
        interval: 5*1000
        running: false
        repeat: true
        onTriggered: {
            var jakso = kuvaaja.vkMs, t1, i0;
            if (eka) {
                alkutoimet();
                kuvaaja.iJuoma = juoja.annoksia-1;
                t1 = new Date().getTime();
                kuvaaja.lisaa(juoja.juodunAika(0),0);
                kuvaaja.lisaa(t1,0);
                kuvaaja.pylvasKuvaaja.positionViewAtEnd();
                jakso = kuvaaja.viikkoja*kuvaaja.vkMs;
                eka = false;
                interval = 200
            } else {
                if (kuvaaja.iJuoma > 0)
                    t1 = juoja.juodunAika(kuvaaja.iJuoma);
            }

            if (kuvaaja.iJuoma > 0) {
                i0 = kuvaaja.iJuoma;
                kuvaaja.lisaaJakso(t1 - jakso, t1);
                if (i0 === kuvaaja.iJuoma){
                    kuvaaja.lisaaJakso(juomari.juodunAika(i0-1)-1, t1)
                }
            } else {
                repeat = false;
                running = false;
            }
            j++;
        }
        property bool eka: true
        property int j:0
        //property int kerralla: 100
    }

    PositionSource {
        id: paikkatieto
        active: true
        updateInterval: 15*60*1000 // 15 min
    }

    XhttpYhteys {
        id: uTYhteys
        anchors.top: parent.top
        width: parent.width
        z: 1
        onValmis: {
            var jsonVastaus;
            try {
                jsonVastaus = JSON.parse(httpVastaus);
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
        onVirhe: {
            console.log("yhteydenottovirhe: " + httpVastaus)
        }

        //property string toiminto: ""
        property string ilmoitukset: ""

        function unTpdCheckIn() {
            var barId = "", naytaSijainti = false, leveys, pituus, huuto, tahtia;
            var osoite, kysely, face = "", twit = "", fsqr = "", vyohyketunnus;

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

            osoite = UnTpd.checkInAddress();
            kysely = UnTpd.checkInData(olutId, vyohyketunnus, barId, naytaSijainti,
                                              leveys, pituus, huuto, tahtia, face, twit, fsqr);

            xHttpPost(kysely, osoite, "checkIn");

            return
        }

        function unTpdKayttaja() {
            var kysely
            //toiminto = "kayttaja"
            //console.log("kysy käyttäjä")
            kysely = UnTpd.getUserInfo("", "true")
            xHttpGet(kysely, "kayttaja")
            return
        }

        function unTpdKirjausTehty(jsonVastaus) {
            //console.log(JSON.stringify(vastaus))
            if ("meta" in jsonVastaus) {
                if (jsonVastaus.meta.code === 200){
                    onnistui = true;
                    viesti = jsonVastaus.response.result;

                    if (jsonVastaus.response.badges.count > 0) {
                        UnTpd.newBadges = jsonVastaus.response.badges;
                        UnTpd.newBadgesSet = true;
                        pageContainer.push(Qt.resolvedUrl("unTpAnsiomerkit.qml"), {
                                           "haeKaikki": false, "naytaKuvaus": true })
                    }
                } else {
                    onnistui = false;
                    viesti = jsonVastaus.meta.error_detail
                }
            } else {
                onnistui = false;
                viesti = qsTr("some error in transmission")
            }

            naytaViesti = true;

            return
        }

        function unTpdIlmoitaUutisista(jsonVastaus) {
            var maara
            //console.log(JSON.stringify(jsonVastaus))
            //console.log(" ilmoita uutisista !!")
            ilmoitukset = JSON.stringify(jsonVastaus)
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

        function unTpdOnkoUutisia() {
            var kysely;
            //toiminto = "uutiset";
            //console.log("onko uutisia " + unTpdKaytossa)
            if (!unTpdKaytossa)
                return;

            kysely = UnTpd.getNotifications();//(offset, limit)

            xHttpGet(kysely, "uutiset");

            return
        }
    }

    SilicaFlickable {
        id: ylaosa
        height: column.height
        width: sivu.width
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("info")
                onClicked:
                    pageContainer.push(Qt.resolvedUrl("tietoja.qml"), {
                                       "versioNro": juoppoko.versioNro})
            }

            MenuItem {
                text: qsTr("settings")
                onClicked:
                    kysyAsetukset()
            }

            MenuItem {
                text: qsTr("foreteller")
                onClicked:
                    pageContainer.push(Qt.resolvedUrl("demolaskuri.qml"), {
                                   "promilleRaja1": Tkanta.promilleRaja1,
                                   "lahtoTaso": juoja.promillejaHetkella(new Date().getTime()),
                                   "vetta": juoja.vetta, "paino": juoja.paino
                                   })
            }

        }

        PushUpMenu {
            id: utValikko
            visible: unTpdKaytossa
            onActiveChanged: {
                busy = false
            }

            MenuItem {
                id: uTvalinta
                text: qsTr("unTappd %1").arg(_ilmoitus)                
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
            width: sivu.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Drunkard?")
            }

            KulutusKuvaajat {
                id: kuvaaja
                width: parent.width - 2*x
                height: sivu.height/8
                alustus: alustusKaynnissa
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
                            lisaaJakso(ti - viikkoja*vkMs, ti)
                        }
                        kertojaAlussa++
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -2
                    onPressAndHold: kuvaaja.tilastojenTarkastelu()
                }

                BusyIndicator {
                    id: kesken
                    size: BusyIndicatorSize.Medium
                    anchors.centerIn: parent
                    running: false
                }

                property int iJuoma: -1
                property int kertojaAlussa: 0
                property int vkMs: 7*24*60*60*1000
                property int viikkoja: 20

                function lisaaJakso(alkuAika, loppuAika) {
                    var maara, vp, pv, pp, hh, mm, ss, ms;

                    if (alkuAika === undefined)
                        alkuAika = juoja.juodunAika(0)

                    if (loppuAika === undefined)
                        loppuAika = juoja.juodunAika(juoja.annoksia-1)

                    kesken.running = true;
                    //kuvaaja.lisaa(alkuAika, 0);
                    //kuvaaja.lisaa(loppuAika, 0);
                    while (iJuoma > -1 && juoja.juodunAika(iJuoma) > loppuAika) {
                        iJuoma--;
                    }
                    while (iJuoma > -1 && juoja.juodunAika(iJuoma) >= alkuAika) {
                        maara = juoja.juodunTilavuus(iJuoma)*juoja.juodunVahvuus(iJuoma)/100;
                        kuvaaja.lisaa(juoja.juodunAika(iJuoma), maara, iJuoma);
                        iJuoma--;
                    }
                    kesken.running = false;
                    return;
                }

                function tilastojenTarkastelu(){
                    var uusiTaulukko, uusiRyyppyVrk, aika, ml, juodut = [], dialog, i = 0;
                    while (i < juoja.annoksia) {
                        aika = juoja.juodunAika(i);
                        ml = juoja.juodunTilavuus(i)*juoja.juodunVahvuus(i)/100;
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

            }

            Row { // promillet
                spacing: 10

                TextField {
                    id: txtPromilleja
                    text: "X ‰"
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
                    width: Theme.fontSizeSmall*6
                    color: Theme.highlightColor
                    readOnly: true
                }

                TextField {
                    id: txtAjokunnossa
                    text: "?"
                    label: Tkanta.promilleRaja1.toFixed(1) + qsTr(" ‰ at")
                    font.pixelSize: Theme.fontSizeSmall
                    width: Theme.fontSizeSmall*8
                    color: Theme.highlightColor
                    readOnly: true
                }

            }

            Row { // nykyinen aika
                x: (column.width - kello.width - paivays.width)/3

                spacing: (column.width - x - kello.width - paivays.width - sivu.anchors.rightMargin)

                ValueButton {
                    id: kello
                    property int valittuTunti: pvm.getHours()
                    property int valittuMinuutti: pvm.getMinutes()
                    property bool kay: true

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
                            value = pvm.toLocaleTimeString(Qt.locale(), kelloMuoto);

                            kello.kay = false;
                            keskeytaAika.running = true;
                            muutaAjanKirjasin();

                            juoja.paivita(pvm.getTime());
                        })
                    }

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
                }

                ValueButton {
                    id: paivays
                    property date valittuPaiva: pvm
                    property bool kay: true

                    valueColor: Theme.primaryColor

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

                            juoja.paivita(pvm.getTime());
                        })
                    }

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
                } // button

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
                } // */

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
                id: juoja
                height: (sivu.height - y > oletusKorkeus) ? sivu.height - y : oletusKorkeus
                width: parent.width
                alustus: alustusKaynnissa
                onJuomaPoistettu: { // signaali (string tkTunnus, int paivia, int kello, real holia)
                    Tkanta.poistaTkJuodut(tkTunnus);
                    kuvaaja.lisaa(paivia*msPaivassa + kello, -holia);
                }
                onLuettuChanged: { // ensimmäisellä kerralla ohjelma kysyy käyttäjän tiedot, uutisten kysely sotkee tätä
                    if (!alustusKaynnissa && unTpdKaytossa)
                        uTYhteys.unTpdOnkoUutisia()
                }
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
                        paivitaAjatRajoille();
                        kuvaaja.lisaa(vanhaHetki, -vanhanAlkoholi);
                        kuvaaja.lisaa(ms, dialog.tilavuus*dialog.vahvuus/100);
                        tarkistaUnTpd();
                    })
                }
                onPromillejaChanged: {
                    if (!alustusKaynnissa) {
                        muutaPromillet()
                    }
                }
                onValittuJuomaChanged: {
                    txtJuoma.text = juoja.juodunNimi(valittuJuoma) //valitunNimi //Apuja.juomanNimi(i)
                    txtMaara.text = juoja.juodunTilavuus(valittuJuoma) //valitunTilavuus //lueJuomanMaara(qId)
                    voltit.text = juoja.juodunVahvuus(valittuJuoma) //valitunVahvuus //lueJuomanVahvuus(qId)
                    tuoppi.olutId = juoja.juodunOlutId(valittuJuoma) //valitunOlutId //Apuja.juomanId(i)
                    UnTpd.olutVaihtuu(tuoppi.olutId)
                    tuoppi.arvostelu = 0
                }

                property bool luettu: false

                function muutaPromillet() {
                    //var nytMs = pvm.getTime();
                    var prml = juomari.promilleja(); // juoja.promilleja;

                    if (prml < 3.0){
                        txtPromilleja.text = "" + prml.toFixed(2) + " ‰";
                    } else {
                        txtPromilleja.text = "> 3.0 ‰";
                    }

                    // huomion keräys, jos promilleRajat ylittyvät
                    if ( prml < Tkanta.promilleRaja1 ) {
                        //txtPromilleja.color = Theme.highlightDimmerColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeMedium;
                        txtPromilleja.font.bold = false;
                    } else if( prml < Tkanta.promilleRaja2 ) {
                        //txtPromilleja.color = Theme.highlightColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeMedium;
                        txtPromilleja.font.bold = true;
                    } else {
                        //txtPromilleja.color = Theme.highlightColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeLarge;
                        txtPromilleja.font.bold = true;
                    }

                    if (prml < Tkanta.promilleRaja1)//nytMs > juoja.rajalla.getTime()) // msKunnossa.getTime() // verrataan hetkeä nytMs listan viimeisen juoman jälkeiseen hetkeen
                        txtAjokunnossa.text = " -";

                    if (prml <= 0) // msSelvana.getTime()
                        txtSelvana.text = " -";

                    return;
                }

            }

        } //column

    }// SilicaFlickable

    Component.onCompleted: {
        lueTiedostot()
        // --> virtualbox
        if (kone === "i486")
            juoja.luettu = true
        // <--
        alustusKaynnissa = false
        aloitus.start()
        //juoja.paivita()
        paivitaAjatRajoille()

    }

}
