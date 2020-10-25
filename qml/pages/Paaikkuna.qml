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
//import org.freedesktop.contextkit 1.0
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
    property alias juomari: juoja

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

        if(db == null)
            try {
                db = LocalStorage.openDatabaseSync("juoppoko", "0.1", "juodun alkoholin paivyri", 10000);
            } catch (err) {
                console.log("Error in opening the database: " + err);
                virheet = virheet + "Error in opening the database: " + err +" <br> "
            };

        Tkanta.tkanta = db;
        Tkanta.luoTaulukot();
        return
    }

    function kellonaika(ms) {
        // kirjoittaa kellonajan halutussa muodossa
        var tunnit = new Date(ms).getHours()
        var minuutit = new Date(ms).getMinutes()
        var teksti
        if (tunnit < 10)
            teksti = "0" + tunnit + ":"
        else
            teksti = "" + tunnit + ":"
        if (minuutit < 10)
            teksti = teksti + "0" + minuutit
        else
            teksti = teksti + minuutit

        return teksti
    }

    function kysyAsetukset() {
        console.log("kysely " + juoja.paino + ", " + juoja.vetta)
        var dialog = pageContainer.push(Qt.resolvedUrl("asetukset.qml"), {
                                        "massa0": juoja.paino, "vetta0": juoja.vetta,
                                        "kunto0": juoja.maksa,
                                        "prom10": Tkanta.promilleRaja1, "prom20": Tkanta.promilleRaja2,
                                        "paiva10": Tkanta.vrkRaja1, "paiva20": Tkanta.vrkRaja2,
                                        "viikko10": Tkanta.vkoRaja1, "viikko20": Tkanta.vkoRaja2,
                                        "vuosi10": Tkanta.vsRaja1, "vuosi20": Tkanta.vsRaja2,
                                        "palonopeus": juoja.polttonopeusVakio
                                    })
        dialog.accepted.connect(function() {
            var muutos = 0
            if (juoja.paino != dialog.massa || juoja.vetta != dialog.vetta ||
                    juoja.maksa != dialog.kunto ){
                muutos = 1
            }
            juoja.paino = dialog.massa
            juoja.vetta = dialog.vetta
            juoja.maksa = dialog.kunto
            if (muutos > 0.5)
                Tkanta.uusiJuomari(juoja.paino, juoja.vetta, juoja.maksa, pvm.getTime())
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

            juoja.promilleRaja = Tkanta.promilleRaja1
            //console.log("kohta1 ")
            //paivitaAsetukset()
            //console.log("kohta2 ")

            //paivitaAsetus2(Tkanta.tunnusUnTappdToken, UnTpd.unTpToken)

            tarkistaUnTpd()
            if (unTpdKaytossa) {
                uTYhteys.unTpdKayttaja()
                uTYhteys.unTpdOnkoUutisia()
            }
            //paivitaAsetus2(Tkanta.tunnusUnTappdToken, UnTpd.unTpToken)
            //}
            juoja.paivita()
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
        var luettu = Tkanta.lueTkAsetukset()

        UnTpd.unTpToken = Tkanta.arvoUnTpToken

        kuvaaja.tyyppi = Tkanta.nakyvaKuvaaja

        return luettu
    }

    function lueJuodut(kaikki, alkuAika, loppuAika) { //jos kaikki=true, alku- ja loppuajalla ei merkitystä

        var taulukko = Tkanta.lueTkJuodut(kaikki, alkuAika, loppuAika)
        var i = 0, maara

        //console.log("juomia " + taulukko.rows.length + ", viimeisin " + taulukko.rows[taulukko.rows.length-1].juoma)
        console.log(qsTr("%1 drinks, latest %2").arg(taulukko.rows.length).arg(taulukko.rows[taulukko.rows.length-1].juoma))
        //console.log("rivi " + typeof taulukko.rows[i].id + ", " + typeof taulukko.rows[i].aika
        //            + ", " + typeof taulukko.rows[i].tilavuus + ", "
        //            + typeof taulukko.rows[i].prosenttia + ", " + typeof taulukko.rows[i].juoma
        //             + ", " + typeof taulukko.rows[i].kuvaus + ", " + typeof taulukko.rows[i].oluenId)

        maara = new Date()
        console.log("juodut listaan " + maara.getHours() + ":" +  maara.getMinutes() + ":" +  maara.getSeconds() + "." +  maara.getMilliseconds())
        while (i < taulukko.rows.length) {
            juoja.juo(taulukko.rows[i].id, taulukko.rows[i].aika, //taulukko.rows[i].veressa,
                      taulukko.rows[i].tilavuus, taulukko.rows[i].prosenttia,
                      taulukko.rows[i].juoma, taulukko.rows[i].kuvaus, taulukko.rows[i].oluenId);
            i++
        }

        maara = new Date()
        console.log("juodut kuvaajaan " + maara.getHours() + ":" +  maara.getMinutes() + ":" +  maara.getSeconds() + "." +  maara.getMilliseconds())
        i=0
        while (i < taulukko.rows.length) {
            maara = taulukko.rows[i].tilavuus*taulukko.rows[i].prosenttia/100
            kuvaaja.lisaa(taulukko.rows[i].aika, maara)
            i++
        }

        maara = new Date()
        console.log("valmista " + maara.getHours() + ":" +  maara.getMinutes() + ":" +  maara.getSeconds() + "." +  maara.getMilliseconds())
        return;
    }

    function lueTiedostot() {
        var ehto = 0, nyt = new Date().getTime() //, vkoNyt
        var keho = []
        var vrk = 24*60*60*1000 // t0 = new Date(0).getTimezoneOffset()*minuutti,

        avaaDb();
        lueAsetukset();

        if (UnTpd.unTpToken > "")
            unTpdKaytossa = true
        else
            unTpdKaytossa = false

        console.log("untappd " + unTpdKaytossa)

        keho = Tkanta.lueTkJuomari()

        if (keho[0] > 1 ){
            juoja.paino = keho[0] //massa = keho[0];
            juoja.vetta = keho[1]//vetta = keho[1];
            juoja.maksa = keho[2]//kunto = keho[2];
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
        }

        lueJuodut(true, pvm.getTime() - 365*vrk, pvm.getTime()) // true = kaikki, false = aikarajojen välissä olevat

        if (juoja.annoksia > 0) {
            console.log("annoksia " + juoja.annoksia)
            txtJuoma.text = juoja.juodunNimi(juoja.annoksia-1) //lueJuomanNimi(juomat.count-1)
            txtMaara.text = juoja.juodunTilavuus(juoja.annoksia-1)//lueJuomanMaara(juomat.count-1)
            voltit.text = juoja.juodunVahvuus(juoja.annoksia-1)//lueJuomanVahvuus(juomat.count-1)
            olutId = juoja.juodunOlutId(juoja.annoksia-1) //lueOluenId(juomat.count-1)
        }

        return
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
        //console.log(" - " + luettuUnTpToken)

        return unTpdKaytossa
    } // */

    function uusiJuoma(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId) {
        //var lisayskohta = etsiPaikka(hetki, juomat.count -1) // mihin kohtaan uusi juoma kuuluu juomien historiassa?

        //lisaaListoihin(xid, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId);
        Tkanta.lisaaTkJuodut(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId);

        juoja.juo(tkId, hetki, tilavuus, vahvuus, juomanNimi, juomanKuvaus, oluenId)

        kuvaaja.lisaa(hetki, tilavuus*vahvuus/100)

        //paivitaMlVeressa(hetki);

        //paivitaPromillet();

        paivitaAjatRajoille();

        //kansi.update();

        //console.log("uusiJuoma: oluenId " + oluenId)

        return;
    }

    /*
    Notification {
        id: ilmoitus
        onClicked: {
            if (avattava === "unTpIlmoitukset.qml") {
                pageContainer.push(Qt.resolvedUrl("unTpIlmoitukset.qml"),
                                                  {"ilmoitukset": uTYhteys.ilmoitukset
                                                  })
            } else if (avattava > "") {
                pageContainer.push(Qt.resolvedUrl(avattava))
            }

            avattava = ""
        }

        property string avattava: ""
    }
    // */

    Timer {
        id: paivitys
        interval: 10*1000 //ms
        running: true
        repeat: true
        onTriggered: {
            paivitaAika()
            //paivitaPromillet()
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
        id: asetustenKysely
        interval: 200
        running: false
        repeat: false
        onTriggered: {
            alkutoimet()
            //if (!juoja.luettu)
                //kysyAsetukset()
            //else if (unTpdKaytossa)
                //uTYhteys.unTpdOnkoUutisia()
        }
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
            //console.log("yhteydenotto valmis: " + httpVastaus.length)
            try {
                jsonVastaus = JSON.parse(httpVastaus);
                if (toiminto === "checkIn") {
                    unTpdKirjausTehty(jsonVastaus)
                } else if (toiminto === "uutiset") {
                    unTpdIlmoitaUutisista(jsonVastaus)
                } else if (toiminto === "kayttaja") {
                    //console.log(" --- " + httpVastaus)
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
            //var xhttp = new XMLHttpRequest()
            //var aika, m0, m1;// ;

            //console.log("tiedot: " + olutId + ", " + baariId + ", " + juomanKuvaus + ", "
            //            + arvostelu)
            //toiminto = "checkIn";

            if (!unTpdKaytossa)
                return

            if (tuoppi.olutId == 0)
                return

            if (!kirjaus.kirjaaUnTp)
                return

            vyohyketunnus = Apuja.vyohyke(pvm.toLocaleTimeString());
            //console.log("vyöhyketunnus " + vyohyketunnus)

            //hetkinen.running = true

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

            if (Tkanta.arvoJulkaiseFacebook)
                face = "on";
            if (Tkanta.arvoJulkaiseFsqr)
                fsqr = "on";
            if (Tkanta.arvoJulkaiseTwitter)
                twit = "on";

            // checkIn(beerId, tzone, venueId, position, lat, lng, shout, rating, fbook, twitter, fsquare)
            //osoite = UnTpd.checkInAddress()
            //kysely = UnTpd.checkInData(olutId, vyohyketunnus, barId, naytaSijainti, leveys,
            //                            pituus, huuto, tahtia, face, twit, fsqr)
            //UnTpd.xHttpUnTpd(UnTpd.POST, kysely, osoite, unTpdViestit.text,
            //                 unTpdKirjausTehty, viestinNaytto.start)
            //haku = ;
            osoite = UnTpd.checkInAddress();
            kysely = UnTpd.checkInData(olutId, vyohyketunnus, barId, naytaSijainti,
                                              leveys, pituus, huuto, tahtia, face, twit, fsqr);
            /*
            xhttp.onreadystatechange = function () {
                //console.log("checkIN - " + xhttp.readyState + " - " + xhttp.status)
                if (xhttp.readyState == 0)
                    unTpdViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
                else if (xhttp.readyState == 1)
                    unTpdViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
                else if (xhttp.readyState == 2)
                    unTpdViestit.text = qsTr("request received") + ", " + xhttp.statusText
                else if (xhttp.readyState == 3)
                    unTpdViestit.text = qsTr("processing request") + ", " + xhttp.statusText
                else if (xhttp.readyState == 4){
                    //console.log(xhttp.responseText)
                    unTpdViestit.text = qsTr("request finished") + ", " + xhttp.statusText

                    var vastaus = JSON.parse(xhttp.responseText);

                    unTpdKirjausTehty(vastaus)

                } else {
                    console.log("tuntematon " + xhttp.readyState + ", " + xhttp.statusText)
                    unTpdViestit.text = xhttp.readyState + ", " + xhttp.statusText
                    viestinNaytto.start()
                }

            }

            unTpdViestit.text = qsTr("posting query")
            xhttp.open("POST", osoite, false)
            xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
            xhttp.send(kysely);
            // */

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
            console.log(" ilmoita uutisista !!")
            ilmoitukset = JSON.stringify(jsonVastaus)
            if ("notifications" in jsonVastaus && "unread_count" in jsonVastaus.notifications) {
                maara = jsonVastaus.notifications.unread_count.friends
                if (maara > 0) {
                    nayta(qsTr("new friend requests: %1").arg(maara))
                    //ilmoitus.previewSummary = qsTr("new notifications : %1").arg(maara)
                    //ilmoitus.avattava = "unTpIlmoitukset.qml"
                    //ilmoitus.publish()
                }

                console.log(jsonVastaus.response.news.count + " notes" )
            }
            return
        }

        function unTpdOnkoUutisia() {
            var kysely;
            //toiminto = "uutiset";
            console.log("onko uutisia " + unTpdKaytossa)
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
                text: qsTr("demo")
                onClicked:
                    pageContainer.push(Qt.resolvedUrl("demolaskuri.qml"), {
                                   "promilleRaja1": Tkanta.promilleRaja1,
                                   //"promilleja": laskePromillet(new Date().getTime()),
                                   "promilleja": juoja.promillejaHetkella(new Date().getTime()),
                                   "vetta": juoja.vetta, "paino": juoja.paino
                                   })
            }

        }

        PushUpMenu {
            visible: unTpdKaytossa
            MenuItem {
                text: qsTr("unTappd")
                onClicked: {
                    //if (tarkistaVerkko()) {
                    var s = pageContainer.push(Qt.resolvedUrl("unTpKayttaja.qml"),
                                               {"ilmoitukset": uTYhteys.ilmoitukset})
                    s.sulkeutuu.connect(function() {
                        tarkistaUnTpd() })
                    //}
                }

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
            /*
            MenuItem {
                text: qsTr("Notifications")
                onClicked: {
                    console.log("pitäisi välittyä " + uTYhteys.ilmoitukset.length + " merkkiä")
                    console.log(uTYhteys.ilmoitukset.substring(0, 40))
                    pageContainer.push(Qt.resolvedUrl("unTpIlmoitukset.qml"),
                                       {"ilmoitukset": uTYhteys.ilmoitukset}
                                       )
                }
            }
            // */
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
                tyyppi: Tkanta.nakyvaKuvaaja
                riskiPvAlempi: Tkanta.vrkRaja1
                riskiPvYlempi: Tkanta.vrkRaja2
                riskiVkoAlempi: Tkanta.vkoRaja1
                riskiVkoYlempi: Tkanta.vkoRaja2
                vrkVaihtuu: Tkanta.vrkVaihtuu
                pylvasKuvaaja.barWidth: Theme.fontSizeExtraSmall
                pylvasKuvaaja.labelWidth: pylvasKuvaaja.barWidth + 0.5*Theme.paddingSmall
                x: Theme.horizontalPageMargin
                onAlustusChanged: {
                    if (!alustus) {
                        //nykyinen = pylvasKuvaaja.count - 1
                        //pylvasKuvaaja.positionViewAtEnd()
                    }
                }
                onPitkaPainanta: {
                    tilastojenTarkastelu()
                }

                MouseArea {
                    anchors.fill: parent
                    z: -2
                    onPressAndHold: kuvaaja.tilastojenTarkastelu()
                }

                function tilastojenTarkastelu(){
                    var uusiTaulukko, uusiRyyppyVrk, aika, ml, juodut = [], dialog, i = 0;
                    while (i < juoja.annoksia) {
                        aika = juoja.juodunAika(i);
                        ml = juoja.juodunTilavuus(i)*juoja.juodunVahvuus(i)/100;
                        juodut[i] = {"ms": aika, "ml": ml};
                        i++
                    }

                    console.log("vika " + juodut[i-1].ms)
                    dialog = pageContainer.push(Qt.resolvedUrl("tilastot.qml"), {
                                                    "valittuKuvaaja": tyyppi,
                                                    "ryyppyVrk": vrkVaihtuu,
                                                    "juodut": juodut })

                    dialog.accepted.connect(function() {
                        uusiTaulukko = dialog.valittuKuvaaja
                        uusiRyyppyVrk = dialog.ryyppyVrk
                        //console.log("kohta2 ")

                        if ( (tyyppi != uusiTaulukko) || (vrkVaihtuu != uusiRyyppyVrk) ) {
                            tyyppi = uusiTaulukko
                            vrkVaihtuu = uusiRyyppyVrk
                            //nakyvaKuvaaja = uusiTaulukko
                            //vrkVaihtuu = uusiRyyppyTkanta.paivitaAsetus
                            console.log("kohta a " + tyyppi + ", " + vrkVaihtuu)
                            //paivitaKuvaaja()
                            //kuvaaja.paivita()
                            //console.log("kohtab ")
                            Tkanta.paivitaAsetus(Tkanta.tunnusKuvaaja, uusiTaulukko)
                            //console.log("kohtac ")
                            Tkanta.paivitaAsetus(Tkanta.tunnusVrkVaihdos, uusiRyyppyVrk)
                        }

                    })
                    //console.log("kohtaL ")

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
                                     })

                        dialog.accepted.connect(function() {
                            valittuTunti = dialog.hour
                            valittuMinuutti = dialog.minute
                            pvm = new Date(pvm.getFullYear(), pvm.getMonth(), pvm.getDate(), valittuTunti, valittuMinuutti, 0, 0)
                            value = pvm.toLocaleTimeString(Qt.locale(), kelloMuoto)

                            kello.kay = false
                            keskeytaAika.running = true
                            muutaAjanKirjasin()

                            juoja.paivita(pvm.getTime())

                            //paivitaPromillet()
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
                                     })

                        dialog.accepted.connect(function() {
                            valittuPaiva = dialog.date
                            pvm = new Date(valittuPaiva.getFullYear(), valittuPaiva.getMonth(), valittuPaiva.getDate(),
                                           pvm.getHours(), pvm.getMinutes(), 0, 0)
                            value = pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat)

                            paivays.kay = false
                            keskeytaAika.running = true
                            muutaAjanKirjasin()

                            juoja.paivita(pvm.getTime())
                            //paivitaPromillet()
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
                    var pv0 = pvm.getDate(), kk0 = pvm.getMonth(), vs0 = pvm.getFullYear()
                    var h0 = pvm.getHours(), m0 = pvm.getMinutes()

                    var dialog = pageContainer.push(Qt.resolvedUrl("juomanMuokkaus.qml"), {
                                    "aika": pvm,
                                    "nimi": txtJuoma.text,
                                    "tilavuus": txtMaara.text,
                                    "vahvuus": voltit.text,
                                    "juomanKuvaus": tuoppi.kuvaus,
                                    "tilavuusMitta": Tkanta.arvoTilavuusMitta,
                                    "olutId": olutId,
                                    "tahtia": tuoppi.arvostelu
                                 })

                    dialog.rejected.connect(function() {
                        return tarkistaUnTpd()
                    })

                    dialog.accepted.connect(function() {
                        pvm = dialog.aika

                        if ( (pvm.getDate() != pv0) || (pvm.getMonth() != kk0) || (pvm.getFullYear() != vs0)) {
                            paivays.value = dialog.aika.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                            paivays.kay = false
                            keskeytaAika.running = true
                            muutaAjanKirjasin()
                        }

                        if ((pvm.getHours() != h0) || (pvm.getMinutes() != m0)) {
                            kello.value = dialog.aika.toLocaleTimeString(Qt.locale(),kelloMuoto)
                            kello.kay = false
                            keskeytaAika.running = true
                            muutaAjanKirjasin()
                        }

                        txtJuoma.text = dialog.nimi
                        txtMaara.text = dialog.tilavuus
                        voltit.text = (dialog.vahvuus).toFixed(1)
                        tuoppi.kuvaus = dialog.juomanKuvaus

                        //if (dialog.tilavuusMitta != Tkanta.arvoTilavuusMitta) {
                        //    Tkanta.arvoTilavuusMitta = dialog.tilavuusMitta
                        //    Tkanta.paivitaAsetus(Tkanta.tunnusTilavuusMitta,Tkanta.arvoTilavuusMitta)
                        //}

                        tarkistaUnTpd()

                        olutId = dialog.olutId
                        if (olutId <= 0){
                            kirjaus.kirjaaUnTp = false
                        }

                        tuoppi.arvostelu = dialog.tahtia

                        //console.log("" + juomanKuvaus + ", " + arvostelu)

                        return
                    })

                    return
                }

                TextField {
                    id: txtJuoma
                    width: sivu.width - txtMaara.width - voltit.width
                    //width: Theme.fontSizeMedium*5.8 //Theme.fontSizeExtraSmall*8
                    readOnly: true
                    color: Theme.primaryColor
                    text: qsTr("beer")
                    label: tuoppi.arvostelu > 0 ? "" + (tuoppi.arvostelu/2+0.5).toFixed(1) + "/5" : " "
                    onClicked: {
                        tuoppi.muutaUusi()
                        //console.log("-- " + juomanKuvaus)
                    }

                }

                TextField {
                    id: txtMaara
                    label: "ml"
                    //width: Theme.fontSizeMedium*4 //Theme.fontSizeExtraSmall*4
                    readOnly: true
                    color: Theme.primaryColor
                    text: "500"
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
                    width: Theme.fontSizeMedium*4
                    onClicked: {
                        tuoppi.muutaUusi()
                    }
                }

            }

            Row { // lisäys
                id: kirjaus
                x: unTpdKaytossa? Theme.paddingSmall : 0.5*(sivu.width - kulautus.width)
                //spacing: (column.width - checkinUnTappd.width - kulautus.width - Theme.paddingMedium)
                //spacing: (column.width - 2*x - txtBaari.width - kirjataankoUnTpd.width - kirjausAsetukset.width)/2
                spacing: (column.width - 2*x - txtBaari.width - kulautus.width - kirjausAsetukset.width)/2
                //spacing: 0

                property bool kirjaaUnTp: true
                //property int arvoTalletaSijainti: 0 // 0 - älä, 1 - pelkät koordinaatit riittää, 2 - vain, jos baari valittu

                //*
                IconButton {
                    id: kirjausAsetukset
                    //icon.source: "image://theme/icon-s-setting"
                    icon.source: "image://theme/icon-m-whereami"
                    //visible: unTpdKaytossa
                    //enabled: olutId > 0 ? true : false
                    onClicked: {
                        var dialog = pageContainer.push(Qt.resolvedUrl("unTpCheckIn.qml"))

                        dialog.accepted.connect(function() {
                            baariNimi = dialog.baari
                            baariNr = dialog.baarinTunnus
                            if (baariNr != "")
                                Tkanta.arvoTalletaSijainti = 2
                            if (dialog.naytaSijainti){
                                FourSqr.lastLat = dialog.lpiiri
                                FourSqr.lastLong = dialog.ppiiri
                                if (Tkanta.arvoTalletaSijainti == 0)
                                    Tkanta.arvoTalletaSijainti = 1
                            } else
                                Tkanta.arvoTalletaSijainti = 0

                        })
                    }

                    property string baariNr: "-1"
                    property string baariNimi: ""

                } // button
                // */

                /*
                IconButton {
                    id: kirjataankoUnTpd
                    icon.source: kirjaaUnTp? "image://theme/icon-m-certificates" : "image://theme/icon-m-tabs"
                    highlighted: kirjaaUnTp? true : false
                    onClicked:
                        kirjaaUnTp = !kirjaaUnTp
                } // */

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
                    //width: Theme.fontSizeMedium*4 //sivu.width - txtJuoma.width - txtMaara.width - voltit.width - 8 //100
                    //anchors.horizontalCenter: parent.horizontalCenter
                    y: txtBaari.y + 0.5*(txtBaari.height - height)
                    text: qsTr("cheers!")
                    onClicked: {
                        var nyt = new Date().getTime(), juomaAika = pvm.getTime();
                        uusiJuoma(nyt, juomaAika, parseInt(txtMaara.text),
                                 parseFloat(voltit.text), txtJuoma.text, tuoppi.kuvaus, olutId);

                        //lisaaKuvaajaan(juomaAika, parseInt(txtMaara.text), parseFloat(voltit.text))
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
                promilleRaja: Tkanta.promilleRaja1
                onJuomaPoistettu: { // signaali (string tkTunnus, int paivia, int kello, real holia)
                    Tkanta.poistaTkJuodut(tkTunnus);
                    console.log("aika " + paivia*msPaivassa + kello + ", ml " + holia)
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
                        //var i = etsiSeuraava(ms) - 1;
                        var vanhaHetki = juodunAika(iMuutettava)
                        var vanhanAlkoholi = juodunTilavuus(iMuutettava)*juodunVahvuus(iMuutettava)/100
                        muutaJuoma(iMuutettava, ms, dialog.tilavuus, dialog.vahvuus, dialog.nimi,
                                   dialog.juomanKuvaus, dialog.olutId);
                        Tkanta.muutaTkJuodut(juodunTunnus(iMuutettava), ms, dialog.tilavuus,
                                             dialog.vahvuus, dialog.nimi, dialog.juomanKuvaus,
                                             dialog.olutId); //, juodunPohjilla(iMuutettava)
                        paivita();
                        //tuoppi.kuvaus = dialog.juomanKuvaus
                        //paivitaMlVeressa(i);
                        //paivitaPromillet();
                        paivitaAjatRajoille();
                        //paivitaKuvaaja();
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

                /*
                function qqmuutaJuoma(id, ms, maara, vahvuus, juoma, kuvaus, juomaId){
                    //             int, int, float,      int,   float,    string,     string
                    //var qqpaiva = new Date(ms).toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    //var qqkello = new Date(ms).toLocaleTimeString(Qt.locale(), kelloMuoto)
                    var mlAlkoholia = juoja.juodunPohjilla(id)
                    //var i = Apuja.monesko(lueJuomanTunnus(id))
                    //var i = Apuja.monesko(id)


                    //Apuja.asetaJuomanArvot(i, lueJuomanTunnus(id), ms, mlAlkoholia, juoma, maara, vahvuus,
                    //                       kuvaus, juomaId)

                    //juomat.set(id, {"section": paiva,"juomaaika": kello,
                    //                  "juomanimi": juoma, "juomamaara": maara,
                    //                  "juomapros": vahvuus.toFixed(1)});


                    //juomat.set(id, {"section": paiva,"juomaaika": kello, "aikaMs": ms,
                    //                  "mlVeressa": mlAlkoholia, "juomanimi": juomanNimi, "juomamaara": maara,
                    //                  "juomapros": vahvuus.toFixed(1), "kuvaus": juomanKuvaus});


                    juoja.muutaJuoma(id, ms, mlAlkoholia, maara, vahvuus, juoma, kuvaus, juomaId)

                    Tkanta.muutaTkJuodut(juoja.juodunTunnus(id), ms, maara, vahvuus,
                                         juoma, kuvaus, juomaId); // , mlAlkoholia

                    return
                }
                // */

                function muutaPromillet() {
                    var nytMs = pvm.getTime()
                    var prml = juoja.promilleja

                    //prml = laskePromillet(nytMs)
                    //prml = juoja.promillejaHetkella(nytMs)

                    if (prml < 3.0){
                        txtPromilleja.text = "" + prml.toFixed(2) + " ‰"
                    } else {
                        txtPromilleja.text = "> 3.0 ‰"
                    }

                    // huomion keräys, jos promilleRajat ylittyvät
                    if ( prml < Tkanta.promilleRaja1 ) {
                        //txtPromilleja.color = Theme.highlightDimmerColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeMedium
                        txtPromilleja.font.bold = false
                    } else if( prml < Tkanta.promilleRaja2 ) {
                        //txtPromilleja.color = Theme.highlightColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeMedium
                        txtPromilleja.font.bold = true
                    } else {
                        //txtPromilleja.color = Theme.highlightColor
                        txtPromilleja.font.pixelSize = Theme.fontSizeLarge
                        txtPromilleja.font.bold = true
                    }

                    if (nytMs > juoja.rajalla.getTime()) // msKunnossa.getTime() // verrataan hetkeä nytMs listan viimeisen juoman jälkeiseen hetkeen
                        txtAjokunnossa.text = " -"

                    if (nytMs > juoja.selvana.getTime()) // msSelvana.getTime()
                        txtSelvana.text = " -"

                    return
                }

            }

        } //column

    }// SilicaFlickable

    Component.onCompleted: {
        lueTiedostot()
        // --> pois
        if (kone === "i486")
            juoja.luettu = true
        // <-- pois
        alustusKaynnissa = false
        asetustenKysely.start()
        paivitaAjatRajoille()

        console.log("alkutoimet ohi, juoja.luettu=" + juoja.luettu )
    }

}
