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

Page {
    id: sivu

    anchors.fill: parent
    //anchors.leftMargin: 0.05*width
    property date pvm: new Date() // kello- ja päiväkohdissa oleva aika (sekunnit ja millisekunnit = 0.0, alustusta lukuunottamatta )
    property string kelloMuoto: "HH:mm"
    property real polttonopeus: 0.1267 // ml/kg/h -- 1 g/10 kg/h = 1.267 ml/10 kg/h
    property real tiheys: 0.7897 // alkoholin tiheys, g/ml
    property int tunti: 60*60*1000 // ms
    property int minuutti: 60*1000 // ms
    property int vrk: 24*tunti // ms    
    property int aikaVyohyke: 0 // aikavyöhykkeen ja GMT:n ero minuutteina

    //hakusana "kuvaaja"
    property string tunnusKuvaaja: "kuvaaja"
    property int nakyvaKuvaaja: 1 // 0 - paivaruudukko, 1 - viikkokulutus, 2 - paivakulutus
    property bool luettuNakyvaKuvaaja: false
    property string tunnusVrkVaihdos: "ryypaysVrk"
    property int vrkVaihtuu: 0*60 // minuuttia puolen yön jälkeen
    property bool luettuVrkVaihtuu: false

    property date msSelvana: new Date()
    property date msKunnossa: new Date()
    property string juomanKuvaus: ""
    property int kuvaajanKorkeus: height/8
    property int pikkuKirjainKoko: Theme.fontSizeExtraSmall //24
    property int isoKirjainKoko: Theme.fontSizeSmall //28

    property int valittu: 0

    property bool kelloKay: true // true - kellonaika ja päivämäärä juoksevat, false - pysyvät vakioina
    property bool paivyriKay: true

    property var db: null
    property string virheet: ""

    //hakusanat: ["ajoraja1", "ajoraja2", "paivaraja1", "paivaraja2", "viikkoraja1", "viikkoraja2", "vuosiraja1", "vuosiraja2"]
    //alkuarvot: [    0.5,    1.0,        120,            320,        500,            1000,            5000,        10000]
    property string tunnusProm1: "ajoraja1"
    property real promilleRaja1: 0.5 // 0.5 = 0.5 promillea
    property bool luettuPromilleRaja1: false
    property string tunnusProm2: "ajoraja2"
    property real promilleRaja2: 1.0 // 1.0 = 1 promille
    property bool luettuPromilleRaja2: false
    property string tunnusVrkRaja1: "paivaraja1"
    property int vrkRaja1: 120 // ml alkoholia
    property bool luettuVrkRaja1: false
    property string tunnusVrkRaja2: "paivaraja2"
    property int vrkRaja2: 320 // ml alkoholia
    property bool luettuVrkRaja2: false
    property string tunnusVkoRaja1: "viikkoraja1"
    property int vkoRaja1: 150 // ml alkoholia
    property bool luettuVkoRaja1: false
    property string tunnusVkoRaja2: "viikkoraja2"
    property int vkoRaja2: 350 // ml alkoholia
    property bool luettuVkoRaja2: false
    property string tunnusVsRaja1: "vuosiraja1"
    property int vsRaja1: 7000 // ml alkoholia
    property bool luettuVsRaja1: false
    property string tunnusVsRaja2: "vuosiraja2"
    property int vsRaja2: 20000 // ml alkoholia
    property bool luettuVsRaja2: false
    property string tunnusTilavuusMitta: "tilavuusMitta"
    property int arvoTilavuusMitta: 1 // juoman tilavuusyksikkö juomien syöttöikkunassa, 1 = ml, 2 = us oz, 3 = imp oz, 4 = imp pint, 5 = us pint
    property bool luettuYksikko: false


    //hakusana "paino"
    property int massa: 84
    //hakusana "vesi"
    property real vetta: 0.75
    //hakusana "maksa"
    property real kunto: 1.0

    //   TIETOKANNAT
    //
    //  juoppoko-tietokanta, aika = kokonaisluku = ms hetkestä 0:00:00.000, 1.1.1970
    //  juodut -    id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus
    //  asetukset - asia, arvo
    //  juomari -   aika, paino, neste, maksa
    //  suosikit -  id, juoma, suosio, kuvaus, tilavuus, prosentti (ei käytössä tällä hetkellä)
    //

    //  hetki0 - int [ms], hetki, jolloin edellinen juoma juotiin
    //  ml0 - float [ml], alkoholia veressä hetkellä hetki0
    //  mlJuoma - int [ml], juoman koko
    //  vahvuus - float [%], alkoholin til-%
    //  hetki1 - int [ms], ajanhetki, jonka alkoholin määrä lasketaan
    //  jos hetki1 < hetki0, palauttaa ml0 + mlJuoma*vahvuus
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

    function alkutoimet() {
        var ehto = 0               

//        console.log("alkutoimet: napin leveys " + kulautus.width + " / " + sivu.width)

        aikaVyohyke = new Date().getTimezoneOffset()

        avaaDb();
        lueAsetukset();
        ehto = lueJuomari();

        lueSuosikit();
        lueJuodut();

        paivitaKuvaaja();
        paivitaPromillet();
        paivitaAjatRajoille();
        juomaLista.positionViewAtEnd();        

        if (juomat.count > 0) {
            txtJuoma.text = lueJuomanTyyppi(juomat.count-1)
            txtMaara.text = lueJuomanMaara(juomat.count-1)
            voltit.text = lueJuomanVahvuus(juomat.count-1)
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

        luoDbAsetukset();
        luoDbJuomari();
        luoDbJuodut();
        luoDbSuosikit();

        return
    }

    // oletuksena, että sarja on nousevassa järjestyksessä id:n mukaan
    // hakee sarjasta ensimmäisen alkion, jonka mlViikkoPylvasTunnus on yhtä suuri tai suurempi kuin id
    // jos id < ensimmäisen alkion mlViikkoPylvasTunnus, palauttaa eron negatiivisena
    // jos id > viimeisen alkion mlViikkoPylvasTunnus, palauttaa alkioiden määrän + 1
    // jos sarja on tyhjä, palauttaa 0
    function etsiViikkoJakso(sarja, id) {
        var i=0

        if (sarja.count < 1) {
            return 0;
        }

        if (sarja.get(0).mlViikkoPylvasTunnus > id)
            return id - sarja.get(0).mlViikkoPylvasTunnus;

        while ( (i < sarja.count) && (sarja.get(i).mlViikkoPylvasTunnus < id) ) {
            i++;
        }


        return i;

    }

    function etsiPaivaJakso(sarja, id) {
        var i=0

        if (sarja.count < 1) {
            return 0;
        }

        if (sarja.get(0).mlPaivaPylvasTunnus > id)
            return id - sarja.get(0).mlPaivaPylvasTunnus;

        while ( (i < sarja.count) && (sarja.get(i).mlPaivaPylvasTunnus < id) ) {
            i++;
        }


        return i;

    }

    // oletuksena, että sarja on nousevassa järjestyksessä id:n mukaan
    // hakee sarjasta ensimmäisen alkion, jonka juomaPaiviaTunnus on yhtä suuri tai suurempi kuin id
    // jos id < ensimmäisen alkion juomaPaiviaTunnus, palauttaa eron negatiivisena
    // jos id > viimeisen alkion juomaPaiviaTunnus, palauttaa alkioiden määrän + 1
    // jos sarja on tyhjä, palauttaa 0
    function etsiPaiviaJakso(sarja, id) {
        var i=0

        if (sarja.count < 1) {
            return 0;
        }

        if (sarja.get(0).juomaPaiviaTunnus > id)
            return id - sarja.get(0).juomaPaiviaTunnus;

        while ( (i < sarja.count) && (sarja.get(i).juomaPaiviaTunnus < id) ) {
            i++;
        }


        return i;

    }

    // palauttaa hetkeä hetki seuraavan juoman kohdan juomalistassa
    // jos hetkeä hetki ennen tai samaan aikaan juotu juoma on 5., palauttaa funktio arvon 5, eli kuudes juoma
    // 0 tyhjällä listalla ja jos juoman juontihetki on aikaisempi kuin ensimmäisen listassa olevan
    // juomat.count, jos hetki on myöhempi tai yhtäsuuri kuin muiden juomien
    // ind0 = aloituskohta
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

    function jaksonVari(maara){
        var raja0, raja1, raja2
        if ( (nakyvaKuvaaja < 0.5) || (nakyvaKuvaaja > 1.5) ) {
            raja0 = 0.001*vrkRaja1
            raja1 = vrkRaja1
            raja2 = vrkRaja2
        } else {
            raja0 = 0.001*vkoRaja1
            raja1 = vkoRaja1
            raja2 = vkoRaja2
        }
        if (maara > raja2 )
            return "red"
        else if (maara > raja1)
            return "yellow"
        else if (maara > raja0)
            return "green"
        else
            return "transparent"
    }

    function juomienMaara() {
        return juomat.count
    }

    // kirjoittaa kellonajan halutussa muodossa
    function kellonaika(ms) {
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

    function kopioiJuoma(qId) {
        txtJuoma.text = lueJuomanTyyppi(qId)
        txtMaara.text = lueJuomanMaara(qId)
        voltit.text = lueJuomanVahvuus(qId)
        juomanKuvaus = lueJuomanKuvaus(qId)

        return
    }

    function kysyAsetukset() {
        var dialog = pageStack.push(Qt.resolvedUrl("asetukset.qml"), {
                                      "massa0": massa, "vetta0": vetta, "kunto0": kunto,
                                      "prom10": promilleRaja1, "prom20": promilleRaja2,
                                      "paiva10": vrkRaja1, "paiva20": vrkRaja2,
                                      "viikko10": vkoRaja1, "viikko20": vkoRaja2,
                                      "vuosi10": vsRaja1, "vuosi20": vsRaja2,
                                      "palonopeus": polttonopeus
                                    })
        dialog.accepted.connect(function() {
            var muutos = 0
            if (massa != dialog.massa || vetta != dialog.vetta || kunto != dialog.kunto ){
                muutos = 1
            }
            massa = dialog.massa
            vetta = dialog.vetta
            kunto = dialog.kunto
            if (muutos > 0.5)
                uusiJuomari()

            promilleRaja1 = dialog.prom1
            promilleRaja2 = dialog.prom2
            vrkRaja1 = dialog.paiva1
            vrkRaja2 = dialog.paiva2
            vkoRaja1 = dialog.viikko1
            vkoRaja2 = dialog.viikko2
            vsRaja1 = dialog.vuosi1
            vsRaja2 = dialog.vuosi2

            paivitaAsetukset()
        })

        return
    }

    // promillet painosuhteena
    function laskePromillet(ms){
        var ml0, edellinen = etsiPaikka(ms, juomat.count -1)

        ml0 = mlKehossa(edellinen-1, ms)

        return ml0*tiheys/(massa*vetta)
    }

    // xid - juoman tunnus, hetki - juontiaika [ms], veressa - ml alkoholia veressä hetkellä hetki,
    // maara - juoman tilavuus, vahvuus- juoman prosentit, juomanNimi - nimi, juomanKuvaus - tekstiä
    function lisaaDbJuodut(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus) {

        if(db == null) return;

        juomanNimi = vaihdaHipsut(juomanNimi)
        juomanKuvaus = vaihdaHipsut(juomanKuvaus)

        var komento = "INSERT INTO juodut (id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus)" +
                " VALUES (" + xid + ", " + hetki + ", " + mlVeressa + ", " + maara + ", " +
                vahvuus + ", '" + juomanNimi + "', '" + juomanKuvaus + "')"

        try {
            db.transaction(function(tx){
                tx.executeSql(komento);

            });
        } catch (err) {
            console.log("Error adding to juodut-table in database: " + err);
            virheet = virheet + "Error adding to juodut-table in database: " + err +" <br> "
        };

        return
    }    

    function lisaaMlViikkoKuvaajaan(hetki, maara, vahvuus) {
        var tunnus1, vkJuoma, i, pv1g = viikonPaiva(0), pvJuoma, tunnus, teksti
        var alkoholia = maara*vahvuus/100

        vkJuoma = Math.floor((hetki - aikaVyohyke*minuutti + (pv1g-1)*vrk)/(7*vrk)) // montako viikkoa hetkestä 1970.1.1. 00:00
        pvJuoma = Math.floor((hetki  - aikaVyohyke*minuutti)/vrk) // montako päivää hetkestä 1970.1.1. 00:00

        tunnus = vkJuoma

        i = etsiViikkoJakso(viikkoArvot, tunnus)

        // jos lisätty juoma on juotu ennen nykyisen taulukon ensimmäistä sarjaa
        if (i < 0) {
            tunnus1 = viikkoArvot.get(0).mlViikkoPylvasTunnus - 1
            while (tunnus1 > tunnus){
                teksti = new Date(tunnus1*7*vrk).getFullYear() + " "
                lisaaViikkoJaksoon(viikkoArvot, 0, 0, viikonNumero(tunnus1*7*vrk), tunnus1, teksti)
                tunnus1--
            }
            i = 0
        }
        // jos lisätty juoma on juotu nykyisen taulukon jälkeen
        if ( (i >= viikkoArvot.count) && (viikkoArvot.count > 0) ) {
            tunnus1 = viikkoArvot.get(viikkoArvot.count-1).mlViikkoPylvasTunnus + 1
            while (tunnus1 < tunnus){
                teksti = new Date(tunnus1*7*vrk).getFullYear() + " "
                lisaaViikkoJaksoon(viikkoArvot, viikkoArvot.count, 0, viikonNumero(tunnus1*7*vrk), tunnus1, teksti)
                tunnus1++
            }
            i = viikkoArvot.count
        }

        teksti = new Date(hetki).getFullYear() + " "
        lisaaViikkoJaksoon(viikkoArvot, i, alkoholia, viikonNumero(hetki), tunnus, teksti)

        return
}

    function lisaaMlPaivaKuvaajaan(hetki, maara, vahvuus) {
        var tunnus1, vkJuoma, i, pv1g = viikonPaiva(0), pvJuoma, tunnus, teksti
        var alkoholia = maara*vahvuus/100

        vkJuoma = Math.floor((hetki - aikaVyohyke*minuutti + (pv1g-1)*vrk)/(7*vrk)) // montako viikkoa hetkestä 1970.1.1. 00:00
        pvJuoma = Math.floor((hetki  - aikaVyohyke*minuutti)/vrk) // montako päivää hetkestä 1970.1.1. 00:00

        tunnus = pvJuoma

        i = etsiPaivaJakso(mlPaivaArvot, tunnus)

        // jos lisätty juoma on juotu ennen nykyisen taulukon ensimmäistä sarjaa
        if (i < 0) {
            tunnus1 = mlPaivaArvot.get(0).mlPaivaPylvasTunnus - 1
            while (tunnus1 > tunnus){
                teksti = new Date(tunnus1*vrk).getFullYear() + ", " + qsTr("wk") + viikonNumero(tunnus1*vrk)
                lisaaPaivaJaksoon(mlPaivaArvot, 0, 0, viikonPaiva(tunnus1*vrk), tunnus1, teksti)
                tunnus1--
            }
            i = 0
        }
        // jos lisätty juoma on juotu nykyisen taulukon jälkeen
        if ( (i >= mlPaivaArvot.count) && (mlPaivaArvot.count > 0) ) {
            tunnus1 = mlPaivaArvot.get(mlPaivaArvot.count-1).mlPaivaPylvasTunnus + 1
            while (tunnus1 < tunnus){
                teksti = new Date(tunnus1*vrk).getFullYear() + ", " + qsTr("wk") + viikonNumero(tunnus1*vrk)
                lisaaPaivaJaksoon(mlPaivaArvot, mlPaivaArvot.count, 0, viikonPaiva(tunnus1*vrk), tunnus1, teksti)
                tunnus1++
            }
            i = mlPaivaArvot.count
        }

        teksti = new Date(hetki).getFullYear() + ", " + qsTr("wk") + viikonNumero(hetki)
        lisaaPaivaJaksoon(mlPaivaArvot, i, alkoholia, viikonPaiva(hetki), tunnus, teksti)

        return
}

    function lisaaKuvaajaan(hetki, maara, vahvuus){
        if (nakyvaKuvaaja > 1.5)
            lisaaMlPaivaKuvaajaan(hetki - vrkVaihtuu*minuutti, maara, vahvuus)
        else if (nakyvaKuvaaja > 0.5)
            lisaaMlViikkoKuvaajaan(hetki - vrkVaihtuu*minuutti, maara, vahvuus)
        else
            lisaaPaiviaKuvaajaan(hetki - vrkVaihtuu*minuutti, maara, vahvuus)

        return
    }

    // xid - juoman tunnus, hetki - juontiaika [ms], mlVeressa - ml alkoholia veressä hetkellä hetki,
    // maara - juoman tilavuus, vahvuus- juoman prosentit, juomanNimi - nimi, juomanKuvaus - tekstiä, lisayskohta - kohta listassa
    function lisaaListaan(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus) {
        var paiva = new Date(hetki).toLocaleDateString(Qt.locale(),Locale.ShortFormat) // juomispäivä
        var kello = new Date(hetki).toLocaleTimeString(Qt.locale(), kelloMuoto) // kellonaika
        var ind = etsiPaikka(hetki,juomat.count-1)

        if (ind < juomat.count) {
            juomat.insert(ind, {"tunnus": xid, "aikaMs": hetki, "mlVeressa": mlVeressa,
                                 "section": paiva, "juomaaika": kello, "juomatyyppi": juomanNimi,
                                 "juomamaara": maara, "juomapros": vahvuus.toFixed(1), "kuvaus": juomanKuvaus});
            paivitaMlVeressa(hetki, ind);

        } else
            juomat.append({"tunnus": xid, "aikaMs": hetki, "mlVeressa": mlVeressa,
                                 "section": paiva, "juomaaika": kello, "juomatyyppi": juomanNimi,
                                 "juomamaara": maara, "juomapros": vahvuus.toFixed(1), "kuvaus": juomanKuvaus});
        return
    }

    // sarja = kuvaajan id, monesko = 0-N - järjestys kuvaajassa, maara = piirrettavan pylvaan korkeus, merkki = pylvään alla näkyvä teksti,
    // id = piirrettävän pylvään tunnus, jakso = väliotsikko
    function lisaaPaivaJaksoon(sarja, monesko, maara, merkki, id, jakso) {
        var vari = "green"
        var skaala = kuvaajanKorkeus/(0.5*(vrkRaja2+vrkRaja1))
        var otsikkoNakyviin = false
        var leveys, otsikonLeveys
        var nimi

        leveys = 20

        if (merkki == 1) {
            otsikkoNakyviin = true
            otsikonLeveys = leveys + 30
        } else
            otsikonLeveys = leveys

        if ( (monesko >= sarja.count) || (sarja.count == 0) ) {
            vari = jaksonVari(maara)
            sarja.append({"mlPaivaPylvasArvo": maara*skaala, "mlPaivaPylvasAika": merkki, "mlPaivaPylvasTunnus": id, "mlPaivaPylvaanVari": vari,
                            "otsikko": jakso, "jaksoNakyvissa": otsikkoNakyviin, "mlPaivaPylvaanLeveys": leveys,
                            "mlOtsikonLeveys": otsikonLeveys})
            kuvaaja3.positionViewAtEnd();
        } else {
            if (sarja.get(monesko).mlPaivaPylvasTunnus == id) {
                sarja.get(monesko).mlPaivaPylvasArvo = sarja.get(monesko).mlPaivaPylvasArvo + maara*skaala
                sarja.get(monesko).mlPaivaPylvaanVari = jaksonVari(sarja.get(monesko).mlPaivaPylvasArvo/skaala)
            } else {
                vari = jaksonVari(maara)
                sarja.insert(monesko, {"mlPaivaPylvasArvo": maara*skaala, "mlPaivaPylvasAika": merkki, "mlPaivaPylvasTunnus": id, "mlPaivaPylvaanVari": vari,
                                "otsikko": jakso, "jaksoNakyvissa": otsikkoNakyviin, "mlPaivaPylvaanLeveys": leveys,
                                "mlOtsikonLeveys": otsikonLeveys})
            }
        }

        return
    }

    // sarja = kuvaajan id, monesko = 0-N - järjestys kuvaajassa, merkki = pylvään alla näkyvä teksti,
    // id = piirrettävän pylvään tunnus, jakso = väliotsikko
    function lisaaPaiviaJaksoon(sarja, monesko, merkki, id, jakso, mlMa, mlTi, mlKe, mlTo, mlPe, mlLa, mlSu) {
        var otsikkoNakyviin = false
        var leveys = 30

        if (merkki == 1) {
            otsikkoNakyviin = true
            leveys = 60
        }

        if ( (monesko >= sarja.count) || (sarja.count == 0) ) {
            sarja.append({"juomaPaiviaTunnus": id, "juomaPaiviaAika": merkki, "otsikko": jakso,
                             "juomaPaiviaMa": paivanVari(mlMa), "juomaPaiviaTi": paivanVari(mlTi),
                             "juomaPaiviaKe": paivanVari(mlKe), "juomaPaiviaTo": paivanVari(mlTo),
                             "juomaPaiviaPe": paivanVari(mlPe), "juomaPaiviaLa": paivanVari(mlLa), "juomaPaiviaSu": paivanVari(mlSu),
                             "jaksoNakyvissa": otsikkoNakyviin, "juomaPaiviaLeveys": leveys })            
            kuvaaja2.positionViewAtEnd();
        } else {
            if (sarja.get(monesko).juomaPaiviaTunnus == id) {
                sarja.get(monesko).juomaPaiviaMa = paivanVari(mlMa)
                sarja.get(monesko).juomaPaiviaTi = paivanVari(mlTi)
                sarja.get(monesko).juomaPaiviaKe = paivanVari(mlKe)
                sarja.get(monesko).juomaPaiviaTo = paivanVari(mlTo)
                sarja.get(monesko).juomaPaiviaPe = paivanVari(mlPe)
                sarja.get(monesko).juomaPaiviaLa = paivanVari(mlLa)
                sarja.get(monesko).juomaPaiviaSu = paivanVari(mlSu)
            }
            else {
                sarja.insert(monesko, {"juomaPaiviaTunnus": id, "juomaPaiviaAika": merkki, "otsikko": jakso,
                                     "juomaPaiviaMa": paivanVari(mlMa), "juomaPaiviaTi": paivanVari(mlTi),
                                     "juomaPaiviaKe": paivanVari(mlKe), "juomaPaiviaTo": paivanVari(mlTo),
                                     "juomaPaiviaPe": paivanVari(mlPe), "juomaPaiviaLa": paivanVari(mlLa), "juomaPaiviaSu": paivanVari(mlSu),
                                     "jaksoNakyvissa": otsikkoNakyviin, "juomaPaiviaLeveys": leveys })
            }
        }

        return
    }

    function lisaaPaiviaKuvaajaan(hetki, maara, vahvuus){
        var vk1, vkJuoma, i, pv1g = viikonPaiva(0), pvJuoma, vuosi = new Date(hetki).getFullYear()
        var mlMa = 0, mlTi = 0, mlKe = 0, mlTo = 0, mlPe = 0, mlLa = 0, mlSu = 0
        var msMa

        vkJuoma = Math.floor((hetki - aikaVyohyke*minuutti + (pv1g-1)*vrk)/(7*vrk))

        i = etsiPaiviaJakso(paivaArvot, vkJuoma)

        // jos lisätty juoma on juotu ennen nykyistä taulukkoa
        if (i < 0) {
            vk1 = paivaArvot.get(0).juomaPaiviaTunnus - 1
            while (vk1 > vkJuoma){
                lisaaPaiviaJaksoon(paivaArvot, 0, viikonNumero(vk1*7*vrk), vk1, new Date(vk1*7*vrk).getFullYear(),
                                  mlMa,mlTi,mlKe,mlTo,mlPe,mlLa,mlSu)
                vk1--
            }
            i = 0
        }
        // jos lisätty juoma on juotu nykyisen taulukon jälkeen
        if ( (i >= paivaArvot.count) && (paivaArvot.count > 0) ) {
            vk1 = paivaArvot.get(paivaArvot.count-1).juomaPaiviaTunnus + 1
            while (vk1 < vkJuoma){                
                lisaaPaiviaJaksoon(paivaArvot, paivaArvot.count, viikonNumero(vk1*7*vrk), vk1, new Date(vk1*7*vrk).getFullYear(),
                                  mlMa,mlTi,mlKe,mlTo,mlPe,mlLa,mlSu)
                vk1++
            }
            i = paivaArvot.count            
        }

        msMa = (vkJuoma*7 - (pv1g-1))*vrk + aikaVyohyke*minuutti - vrkVaihtuu*minuutti

        mlMa = mlAikana(msMa,         msMa + vrk)
        mlTi = mlAikana(msMa + vrk,   msMa + 2*vrk)
        mlKe = mlAikana(msMa + 2*vrk, msMa + 3*vrk)
        mlTo = mlAikana(msMa + 3*vrk, msMa + 4*vrk)
        mlPe = mlAikana(msMa + 4*vrk, msMa + 5*vrk)
        mlLa = mlAikana(msMa + 5*vrk, msMa + 6*vrk)
        mlSu = mlAikana(msMa + 6*vrk, msMa + 7*vrk)

        lisaaPaiviaJaksoon(paivaArvot, i, viikonNumero(hetki), vkJuoma, new Date(vkJuoma*7*vrk).getFullYear(),
                          mlMa,mlTi,mlKe,mlTo,mlPe,mlLa,mlSu)

        return

    }

    // sarja = kuvaajan id, monesko = 0-N - järjestys kuvaajassa, maara = piirrettavan pylvaan korkeus, merkki = pylvään alla näkyvä teksti,
    // id = piirrettävän pylvään tunnus, jakso = väliotsikko
    function lisaaViikkoJaksoon(sarja, monesko, maara, merkki, id, jakso) {
        var vari = "green"
        var skaala = kuvaajanKorkeus/(0.5*(vkoRaja2+vkoRaja1))
        var otsikkoNakyviin = false
        var leveys, otsikonLeveys
        var nimi

        //leveys = (pikkuKirjainKoko*1.1).toFixed(0) //30
        leveys = pikkuKirjainKoko //30

        if (merkki == 1) {
            otsikkoNakyviin = true
            otsikonLeveys = ((leveys + pikkuKirjainKoko)*1.2).toFixed(0)*1.0 // leveys + 30
        } else
            otsikonLeveys = leveys

        if ( (monesko >= sarja.count) || (sarja.count == 0) ) {
            vari = jaksonVari(maara)
            sarja.append({"mlViikkoPylvasArvo": maara*skaala, "mlViikkoPylvasAika": merkki, "mlViikkoPylvasTunnus": id, "mlViikkoPylvaanVari": vari,
                            "otsikko": jakso, "jaksoNakyvissa": otsikkoNakyviin, "mlViikkoPylvaanLeveys": leveys,
                            "mlOtsikonLeveys": otsikonLeveys})
            kuvaaja.positionViewAtEnd();
        } else {
            if (sarja.get(monesko).mlViikkoPylvasTunnus == id) {
                sarja.get(monesko).mlViikkoPylvasArvo = sarja.get(monesko).mlViikkoPylvasArvo + maara*skaala
                sarja.get(monesko).mlViikkoPylvaanVari = jaksonVari(sarja.get(monesko).mlViikkoPylvasArvo/skaala)
            } else {
                vari = jaksonVari(maara)
                sarja.insert(monesko, {"mlViikkoPylvasArvo": maara*skaala, "mlViikkoPylvasAika": merkki, "mlViikkoPylvasTunnus": id, "mlViikkoPylvaanVari": vari,
                                "otsikko": jakso, "jaksoNakyvissa": otsikkoNakyviin, "mlViikkoPylvaanLeveys": leveys,
                                "mlOtsikonLeveys": otsikonLeveys})
            }
        }

        return
    }

    function lueAsetukset() {
        var luettu = 0

        if(db == null) return luettu;

        try {
            db.transaction(function(tx) {
                var taulukko  = tx.executeSql("SELECT asia, arvo FROM asetukset");

                for (var i = 0; i < taulukko.rows.length; i++ ) {
                    if (taulukko.rows[i].asia == tunnusProm1 ){
                        promilleRaja1 = taulukko.rows[i].arvo;
                        luettuPromilleRaja1 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusProm2 ){
                        promilleRaja2 = taulukko.rows[i].arvo;
                        luettuPromilleRaja2 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusVrkRaja1 ) {
                        vrkRaja1 = taulukko.rows[i].arvo;
                        luettuVrkRaja1 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusVrkRaja2 ){
                        vrkRaja2 = taulukko.rows[i].arvo;
                        luettuVrkRaja2 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusVkoRaja1 ) {
                        vkoRaja1 = taulukko.rows[i].arvo;
                        luettuVkoRaja1 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusVkoRaja2 ) {
                        vkoRaja2 = taulukko.rows[i].arvo;
                        luettuVkoRaja2 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusVsRaja1 ) {
                        vsRaja1 = taulukko.rows[i].arvo;
                        luettuVsRaja1 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusVsRaja2 ) {
                        vsRaja2 = taulukko.rows[i].arvo;
                        luettuVsRaja2 = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusKuvaaja ) {
                        nakyvaKuvaaja = taulukko.rows[i].arvo;
                        luettuNakyvaKuvaaja = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusVrkVaihdos ) {
                        vrkVaihtuu = taulukko.rows[i].arvo;
                        luettuVrkVaihtuu = true;
                    }
                    else if (taulukko.rows[i].asia == tunnusTilavuusMitta ) {
                        arvoTilavuusMitta = taulukko.rows[i].arvo;
                        luettuYksikko = true;
                    }
                }

                if(taulukko.rows.length <= 0){
                    uusiAsetukset()
                } else {
                    luettu = i
                    //varmistetaan, että kaikki asetukset ovat tietokannassa
                    if (!luettuPromilleRaja1)
                        uusiAsetus(tunnusProm1, promilleRaja1)
                    if (!luettuPromilleRaja2)
                        uusiAsetus(tunnusProm2, promilleRaja2)
                    if (!luettuVrkRaja1)
                        uusiAsetus(tunnusVrkRaja1, vrkRaja1)
                    if (!luettuVrkRaja2)
                        uusiAsetus(tunnusVrkRaja2, vrkRaja2)
                    if (!luettuVkoRaja1)
                        uusiAsetus(tunnusVkoRaja1, vkoRaja1)
                    if (!luettuVkoRaja2)
                        uusiAsetus(tunnusVkoRaja2, vkoRaja2)
                    if (!luettuVsRaja1)
                        uusiAsetus(tunnusVsRaja1, vsRaja1)
                    if (!luettuVsRaja2)
                        uusiAsetus(tunnusVsRaja2, vsRaja2)
                    if (!luettuNakyvaKuvaaja)
                        uusiAsetus(tunnusKuvaaja, nakyvaKuvaaja)
                    if (!luettuVrkVaihtuu)
                        uusiAsetus(tunnusVrkVaihdos, vrkVaihtuu)
                    if (!luettuYksikko)
                        uusiAsetus(tunnusTilavuusMitta, arvoTilavuusMitta)

                }

            });

        } catch (err) {
            console.log("Error adding to juodut-table in database: " + err);
            virheet = virheet + "Error adding to juodut-table in database: " + err +" <br> "

        }

        return luettu
    }

    function lueJuodut() {

        try {
            db.transaction(function(tx) {
                var taulukko = tx.executeSql("SELECT * FROM juodut ORDER BY aika ASC");

                for (var i = 0; i < taulukko.rows.length; i++ ) {
                    lisaaListaan(taulukko.rows[i].id, taulukko.rows[i].aika, taulukko.rows[i].veressa,
                             taulukko.rows[i].tilavuus, taulukko.rows[i].prosenttia,
                             taulukko.rows[i].juoma, taulukko.rows[i].kuvaus);

                } // for

            });

        } catch (err) {
            console.log("lueJuodut: " + err);
        }

        return;
    }

    // palauttaa ajan millisenkunteina
    function lueJuomanAika(xid) {
        var ms = 0
        if ((juomat.count > xid) && (xid > -0.5)) {            
            ms = juomat.get(xid).aikaMs
        }
        return ms
    }

    function lueJuomanId(xid) {
        var id = 0
        if ((juomat.count > xid) && (xid > -0.5)) {
            id = juomat.get(xid).tunnus
        }

        return id
    }

    function lueJuomanKuvaus(xid){
        var tyyppi = ""
        if ((juomat.count > xid) && (xid > -0.5)) {
            tyyppi = juomat.get(xid).kuvaus
        }

        return tyyppi

    }

    function lueJuomanMaara(xid) {
        var ml = -1
        if ((juomat.count > xid) && (xid > -0.5)) {
            ml = juomat.get(xid).juomamaara
        }

        return ml
    }

    function lueJuomanVahvuus(xid) {
        var vahvuus = -1
        if ((juomat.count > xid) && (xid > -0.5)) {
            vahvuus = juomat.get(xid).juomapros
        }

        return vahvuus
    }

    function lueJuomanTyyppi(xid){
        var tyyppi = ""
        if ((juomat.count > xid) && (xid > -0.5)) {
            tyyppi = juomat.get(xid).juomatyyppi
        }

        return tyyppi

    }

    function lueJuomari() {
        var tyhja = 0

        try {
            db.transaction(function(tx) {
                var taulukko  = tx.executeSql("SELECT * FROM juomari ORDER BY aika ASC");
                tyhja = taulukko.rows.length

                if (tyhja > 0) {
                    massa = taulukko.rows[tyhja - 1].paino;
                    vetta = taulukko.rows[tyhja - 1].neste;
                    kunto = taulukko.rows[tyhja - 1].maksa;
                };
            });
        } catch (err) {
            console.log("lueJuomari: " + err);
        }

        if (tyhja < 0.5)
            uusiJuomari()

        return tyhja
    }

    function lueMlVeressa(xid) {
        var ml = -1
        if ((juomat.count > xid) && (xid > -0.5)) {
            ml = juomat.get(xid).mlVeressa
        }

        return ml
    }

    function lueSuosikit() {

        db.transaction(function(tx) {
            var taulukko  = tx.executeSql("SELECT * FROM suosikit");
        });

        return;
    }

    // asetukset-tietokanta
    // asia,    arvo
    // string,  numeric
    function luoDbAsetukset() {

        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql('CREATE TABLE IF NOT EXISTS asetukset (asia TEXT, arvo NUMERIC)');
            });
        } catch (err) {
            console.log("Error creating asetukset-table in database: " + err);
            virheet = virheet + "Error creating asetukset-table in database: " + err +" <br> "
        };

        return
    }

    //juomari-taulukko
    // aika,     paino,      neste,                          maksa
    // int [ms], int [kg],   float - kehon nesteprosentti,   float - maksan tehokkuuskerroin
    function luoDbJuomari() {

        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql('CREATE TABLE IF NOT EXISTS juomari (aika INTEGER, paino INTEGER,
                        neste REAL, maksa REAL)');
            });

        } catch (err) {
            console.log("Error creating juomari-table in database: " + err);
            virheet = virheet + "Error creating asetukset-table in database: " + err +" <br> "
        };

        return
    }

    //juodut-taulukko
    // id,  aika,     veressa,                                      tilavuus, prosenttia, juoma,                kuvaus
    // int, int [ms], float [ml] - alkoholia veressä juomahetkellä, int [ml], float,      string - juoman nimi, string
    function luoDbJuodut() {

        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql('CREATE TABLE IF NOT EXISTS juodut (id INTEGER, aika INTEGER, veressa REAL,
                        tilavuus INTEGER, prosenttia REAL, juoma TEXT, kuvaus TEXT)');
            });
        } catch (err) {
            console.log("Error creating juodut-table in database: " + err);
            virheet = virheet + "Error creating asetukset-table in database: " + err +" <br> "
        };

        return
    }

    //suosikit-taulukko
    //id  juoma (nimi)  suosio kuvaus tilavuus prosentti
    //int string        int    string int      float
    function luoDbSuosikit() {

        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql('CREATE TABLE IF NOT EXISTS suosikit (id INTEGER, juoma TEXT, suosio INTEGER,
                        kuvaus TEXT, tilavuus INTEGER, prosentti REAL)');
            });
        } catch (err) {
            console.log("Error creating suosikit-table in database: " + err);
            virheet = virheet + "Error creating asetukset-table in database: " + err +" <br> "
        };

        return
    }

    function mlAikana(ms0, ms1) {
        var ml = 0
        var i0, i1

        i0 = etsiPaikka(ms0, juomaLista.count-1)
        i1 = etsiPaikka(ms1, i0+1)

        while ( (i0 < i1 ) && (lueJuomanAika(i0) < ms1)){
            ml = ml + lueJuomanMaara(i0)*lueJuomanVahvuus(i0)/100
            i0++
        }

        return ml
    }

    // laskee, paljonko alkoholia on veressä hetkellä ms
    // xid on edellisen juoman tunnus
    function mlKehossa(xid, ms) {
        var ml1

        ml1 = alkoholiaVeressa(lueJuomanAika(xid), lueMlVeressa(xid), lueJuomanMaara(xid), lueJuomanVahvuus(xid), ms )

        return ml1
    }

    // ml0 - alkoholia veressä ennen juotua juomaa koko0, vahvuus0
    function msRajalle(ml0, koko0, vahvuus0, promillea){
        var mlRajalle, hRajalle

        mlRajalle = ml0 + koko0*vahvuus0/100 - promillea*massa*vetta/tiheys
        hRajalle = mlRajalle/palonopeus()

        return Math.round(hRajalle*tunti)
    }

    function muutaAjanKirjasin() {

        if (kelloKay == false){
            kello.valueColor = Theme.secondaryHighlightColor

        } else {
            kello.valueColor = Theme.highlightColor
        }

        if (paivyriKay == false){
            paivays.valueColor = Theme.secondaryHighlightColor

        } else {
            paivays.valueColor = Theme.highlightColor
        }

        return
    }

    function muutaDbJuodut(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus) {
        juomanNimi = vaihdaHipsut(juomanNimi)
        juomanKuvaus = vaihdaHipsut(juomanKuvaus)

        var komento = "UPDATE juodut SET aika = " + hetki + ", veressa = " + mlVeressa + ", tilavuus = " + maara + ", prosenttia = " + vahvuus +", juoma = '"
                + juomanNimi + "', kuvaus = '" + juomanKuvaus +"'  WHERE id = " + xid
        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql(komento);
            });
        } catch (err) {
            console.log("Error modifying juodut-table in database: " + err);
            virheet = virheet + "Error modifying juodut-table in database: " + err +" <br> "
        };

        return
    }

    //                 int, int, float,      int,   float, string,     string
    function muutaJuoma(id, ms, mlAlkoholia, maara, vahvuus, juomanNimi, juomanKuvaus)     {
        var paiva = new Date(ms).toLocaleDateString(Qt.locale(),Locale.ShortFormat)
        var kello = new Date(ms).toLocaleTimeString(Qt.locale(), kelloMuoto)

        juomat.set(id, {"section": paiva,"juomaaika": kello, "aikaMs": ms,
                          "mlVeressa": mlAlkoholia, "juomatyyppi": juomanNimi, "juomamaara": maara,
                          "juomapros": vahvuus.toFixed(1), "kuvaus": juomanKuvaus});

        muutaDbJuodut(lueJuomanId(id), ms, mlAlkoholia, maara, vahvuus, juomanNimi, juomanKuvaus);

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
                        "juomanKuvaus": juomanKuvaus,
                        "tilavuusMitta": arvoTilavuusMitta
                     })

        dialog.accepted.connect(function() {
            pvm = dialog.aika

            if ( (pvm.getDate() != pv0) || (pvm.getMonth() != kk0) || (pvm.getFullYear() != vs0)) {
                paivays.value = dialog.aika.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                paivyriKay = false
                keskeytaAika.running = true
                muutaAjanKirjasin()
            }

            if ((pvm.getHours() != h0) || (pvm.getMinutes() != m0)) {
                kello.value = dialog.aika.toLocaleTimeString(Qt.locale(),kelloMuoto)
                kelloKay = false
                keskeytaAika.running = true
                muutaAjanKirjasin()
            }

            txtJuoma.text = dialog.nimi
            txtMaara.text = (dialog.maara).toFixed(0)
            voltit.text = (dialog.vahvuus).toFixed(1)
            juomanKuvaus = dialog.juomanKuvaus

            if (dialog.tilavuusMitta != arvoTilavuusMitta) {
                arvoTilavuusMitta = dialog.tilavuusMitta
                paivitaAsetukset()
            }

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
                        "juomanKuvaus": juomanKuvaus,
                        "tilavuusMitta": arvoTilavuusMitta
                     })

        dialog.accepted.connect(function() {            
            muutaJuoma(qId, dialog.aika.getTime(), parseFloat(lueMlVeressa(qId)), dialog.maara,
                        dialog.vahvuus, dialog.nimi, dialog.juomanKuvaus)
            juomanKuvaus = dialog.juomanKuvaus            
            paivitaMlVeressa(dialog.aika.getTime(), qId)
            paivitaPromillet()
            paivitaAjatRajoille()
            paivitaKuvaaja()
            if (dialog.tilavuusMitta != arvoTilavuusMitta) {
                arvoTilavuusMitta = dialog.tilavuusMitta
                paivitaAsetukset()
            }
        })

        return
    }

    // kansi käyttää tätä
    function nykyinenJuoma(){
        return txtJuoma.text
    }

    // kansi käyttää tätä
    function nykyinenMaara(){
        return parseInt(txtMaara.text)
    }

    // kansi käyttää tätä
    function nykyinenProsentti(){
        return parseFloat(voltit.text)
    }

    function paivanVari(mlPaivassa){
        var vari = "red"
        if (mlPaivassa < 1) {
            vari = "transparent"
        } else if (mlPaivassa < vrkRaja1){
            vari = "green"
        } else if (mlPaivassa < vrkRaja2){
            vari ="yellow"
        }
        return vari
    }

    function paivitaAika() {
        var paiva = new Date()

        if ( (kelloKay == true) && (paivyriKay == true)) {
            pvm = paiva
            kello.valittuTunti = paiva.getHours()
            kello.valittuMinuutti = paiva.getMinutes()
            kello.value = kellonaika(paiva.getTime())
            paivays.value = paiva.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
            paivays.valittuPaiva.setTime(paiva.getTime())
        }

        return;
    }

    // laskee, paljonko listan viimeisestä juomasta kuluu aikaa kaiken alkoholin palamiseen ja promilleRajalle 1
    function paivitaAjatRajoille() {
        var ms1, ms0, ml0, koko0, vahvuus0, ind = juomat.count

        ms0 = lueJuomanAika(ind-1)
        ml0 = lueMlVeressa(ind-1)
        koko0 = lueJuomanMaara(ind-1)
        vahvuus0 = lueJuomanVahvuus(ind-1)

        // selväksi
        ms1 = ms0 + msRajalle(ml0, koko0, vahvuus0, 0)
        msSelvana = new Date(ms1)

        // ajokuntoon
        ms1 = ms0 + msRajalle(ml0, koko0, vahvuus0, promilleRaja1)
        msKunnossa = new Date(ms1)

        if ( msSelvana.getTime() > new Date().getTime() )
            txtSelvana.text = kellonaika(msSelvana.getTime())
        else
            txtSelvana.text = " -"

        if ( msKunnossa.getTime() > new Date().getTime() ) {
            txtAjokunnossa.text = kellonaika(msKunnossa.getTime())
            kansi.update()
        }
        else {
            txtAjokunnossa.text = " -"
            kansi.update()
        }

        return
    }

    function paivitaAsetukset() {
        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql("UPDATE asetukset SET arvo = " + promilleRaja1 +
                              "  WHERE asia = '" + tunnusProm1 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + promilleRaja2 +
                              "  WHERE asia = '" + tunnusProm2 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + vrkRaja1 +
                              "  WHERE asia = '" + tunnusVrkRaja1 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + vrkRaja2 +
                              "  WHERE asia = '" + tunnusVrkRaja2 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + vkoRaja1 +
                              "  WHERE asia = '" + tunnusVkoRaja1 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + vkoRaja2 +
                              "  WHERE asia = '" + tunnusVkoRaja2 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + vsRaja1 +
                              "  WHERE asia = '" + tunnusVsRaja1 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + vsRaja2 +
                              "  WHERE asia = '" + tunnusVsRaja2 + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + nakyvaKuvaaja +
                              "  WHERE asia = '" + tunnusKuvaaja + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + vrkVaihtuu +
                              "  WHERE asia = '" + tunnusVrkVaihdos + "'");
                tx.executeSql("UPDATE asetukset SET arvo = " + arvoTilavuusMitta +
                              "  WHERE asia = '" + tunnusTilavuusMitta + "'");
            });
        } catch (err) {
            console.log("Error modifying asetukset-table in database: " + err);
            virheet = virheet + "Error modifying asetukset-table in database: " + err +" <br> "
        };

        return
    }

    function paivitaKuvaaja() {
        var i

        //tyhjennetään vanhat pois
        if (nakyvaKuvaaja > 1.5) {
            for (i = mlPaivaArvot.count-1; i >= 0; i--) {
                mlPaivaArvot.remove(i)
            }
        } else if (nakyvaKuvaaja > 0.5) {
            for (i = viikkoArvot.count-1; i >= 0; i--) {
                viikkoArvot.remove(i)
            }
        } else {
            for (i = paivaArvot.count-1; i >= 0; i--) {
                paivaArvot.remove(i)
            }
        }

        //täytetään uudelleen
        for (i=0; i < juomat.count; i++) {
            lisaaKuvaajaan(lueJuomanAika(i),lueJuomanMaara(i),lueJuomanVahvuus(i))
        }

        return
    }

    // päivittää juomishistorian tiedot alkoholin määrästä veressä hetkestä ms1 alkaen
    // (jos listasta poistetaan, lisätään tai muutetaan)
    function paivitaMlVeressa(ms1, xInd) {
        var ind = etsiPaikka(ms1, xInd)
        var ms0, ml0, koko0, vahvuus0, id1, ml1, koko1, vahvuus1

        if (ind > 0){ // ms1 on listan ensimmäisen jälkeen
            ms0 = lueJuomanAika(ind-1)
            ml0 = lueMlVeressa(ind-1)
            koko0 = lueJuomanMaara(ind-1)
            vahvuus0 = lueJuomanVahvuus(ind-1)
        } else { // ms1 on ennen listan ensimmäistä
            ms0 = 0
            ml0 = 0
            koko0 = 0
            vahvuus0 = 0
        }

        while (ind < juomat.count) {
            id1 = lueJuomanId(ind)
            ms1 = lueJuomanAika(ind)
            ml1 = alkoholiaVeressa(ms0, ml0, koko0, vahvuus0, ms1 ) // paljonko tälle juomalle oli pohjia
            if ( (ml1 > 0) || (lueMlVeressa(ind) > 0) ) {
                juomat.set(ind,{"mlVeressa": ml1})
                koko1 = lueJuomanMaara(ind)
                vahvuus1 = lueJuomanVahvuus(ind)
                muutaDbJuodut(id1, ms1, ml1, koko1, vahvuus1, lueJuomanTyyppi(ind), lueJuomanKuvaus(ind))
                ms0 = ms1
                ml0 = ml1
                koko0 = koko1
                vahvuus0 = vahvuus1
            } else
                ind = juomat.count

            ind++
        }

        return
    }

    // etsii juomalistasta hetkeä nytMs edeltävän juoman tiedot ja laskee hetken nytMs promillemäärän
    function paivitaPromillet() {
        var nytMs = pvm.getTime()
        var ml0, prml

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
        } else if( prml < promilleRaja2 ) {
            txtPromilleja.color = Theme.highlightColor
            txtPromilleja.font.pixelSize = Theme.fontSizeMedium
        } else {
            txtPromilleja.color = Theme.highlightColor
            txtPromilleja.font.pixelSize = Theme.fontSizeLarge
        }

        if (nytMs > msKunnossa.getTime()) // verrataan hetkeä nytMs listan viimeisen juoman jälkeiseen hetkeen
            txtAjokunnossa.text = " -"

        if (nytMs > msSelvana.getTime())
            txtSelvana.text = " -"

        return prml
    }

    // ml/h
    function palonopeus() {
        return polttonopeus*massa*kunto
    }

    function tilastojenTarkastelu(){
        var uusiTaulukko, uusiRyyppyVrk
        var dialog = pageStack.push(Qt.resolvedUrl("tilastot.qml"), {"valittuKuvaaja": nakyvaKuvaaja,
                                    "ryyppyVrk": vrkVaihtuu})

        dialog.accepted.connect(function() {           
            uusiTaulukko = dialog.valittuKuvaaja
            uusiRyyppyVrk = dialog.ryyppyVrk

            if ( (nakyvaKuvaaja != uusiTaulukko) || (vrkVaihtuu != uusiRyyppyVrk) ) {
                nakyvaKuvaaja = uusiTaulukko
                vrkVaihtuu = uusiRyyppyVrk
                paivitaKuvaaja()
                paivitaAsetukset()
            }

        })

        return
    }

    function tyhjennaDbJuodut(xid){

        try {
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM juodut WHERE id = ?", [xid]);
            });
        } catch (err) {
            console.log("tyhjennaDbJuodut: " + err);
        }

        return;
    }

    function uusiAsetukset() {

        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusProm1 + "', " + promilleRaja1 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusProm2 + "', " + promilleRaja2 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusVrkRaja1 + "', " + vrkRaja1 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusVrkRaja2 + "', " + vrkRaja2 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusVkoRaja1 + "', " + vkoRaja1 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusVkoRaja2 + "', " + vkoRaja2 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusVsRaja1 + "', " + vsRaja1 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusVsRaja2 + "', " + vsRaja2 +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusKuvaaja + "', " + nakyvaKuvaaja +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusVrkVaihdos + "', " + vrkVaihtuu +")" )
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnusTilavuusMitta + "', " + arvoTilavuusMitta +")" )
            })
        } catch (err) {
            console.log("Error adding to asetukset-table in database: " + err);
            virheet = virheet + "Error adding to asetukset-table in database: " + err +" <br> "
        }

        return

    }

    function uusiAsetus(tunnus, arvo){
        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql("INSERT INTO asetukset (asia, arvo)" +
                              " VALUES ('" + tunnus + "', " + arvo +")" )
            })
        } catch (err) {
            console.log("Error adding to asetukset-table in database: " + err);
            virheet = virheet + "Error adding to asetukset-table in database: " + err +" <br> "
        }
        return
    }

    function uusiJuomari() {

        if(db == null) return;

        try {
            db.transaction(function(tx){
                tx.executeSql("INSERT INTO juomari (aika, paino, neste, maksa)" +
                              " VALUES (" + pvm.getTime() + ", " + massa + ", " + vetta + ", " + kunto +")" )
            })
        } catch (err) {
            console.log("Error adding to asetukset-table in database: " + err);
            virheet = virheet + "Error adding to asetukset-table in database: " + err +" <br> "
        }

        return
    }

    function uusiJuoma(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus)     {
        var lisayskohta = etsiPaikka(hetki, juomat.count -1) // mihin kohtaan uusi juoma kuuluu juomien historiassa?
        var ml0
        var apu

        // lasketaan paljonko veressä on alkoholia juomishetkellä
        mlVeressa = mlKehossa(lisayskohta-1, hetki)

        lisaaListaan(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus, lisayskohta)

        lisaaDbJuodut(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus);

        paivitaPromillet();

        paivitaAjatRajoille();

        kansi.update();

        return;
    }

    //tuplaa merkit ' ja "
    function vaihdaHipsut(mj) {
        mj = mj.replace(/'/g,"''")
        mj = mj.replace(/"/g,'""')

        return mj
    }

    // hetki = ms GMT
    // jos vuoden ensimmäinen päivä on ma-to, aloittaa se 1. viikon - muuten kyseessä edellisen vuoden 53. viikko
    function viikonNumero(hetki) {
        var vuosi = new Date(hetki).getFullYear() // GMT:n mukaan
        var ekapvm = new Date(vuosi,0,1,0,0,0) // aikavyöhykkeen mukaan
        var vkpaiva = viikonPaiva(ekapvm.getTime() - aikaVyohyke*minuutti) //1-7, ma - su
        var vk0, vknyt, erovk, eropv, eroms

        // onko vuoden ensimmäinen päivä edellisen vuoden viikolla 52/53 vai tämän vuoden viikolla 1
        if (vkpaiva > 4.5) // pe-su -> vk 52/53
            vk0 = 0
        else //ma-to -> vk 1
            vk0 = 1

        eroms = hetki - ekapvm.getTime() // ms
        erovk = Math.floor(eroms/(7*vrk)) // vko
        eropv = Math.floor((eroms-erovk*7*vrk)/vrk) // vrk

        if ( vkpaiva + eropv > 7.5) {
            vknyt = vk0 + erovk + 1
        } else {
            vknyt = vk0 + erovk
        }

        if (vknyt < 0.5 )
            vknyt = viikonNumero(new Date(vuosi-1,11,31,10,0,0).getTime() - aikaVyohyke*minuutti )

        return vknyt
    }

    // palauttaa 1 - maanantai, 7 - sunnuntai
    // Date().getDay() palauttaa 0 - sunnuntai, 6 - lauantai
    // hetki - ms hetkestä 1970.1.1 00:00 GMT
    function viikonPaiva(hetki) {
        var paiva = new Date(hetki).getDay()

        if (paiva == 0)
            paiva = 7

        return paiva
    }

    Timer {
        id: paivitys
        interval: 6*1000
        running: true
        repeat: true
        onTriggered: {
            paivitaAika()
            paivitaPromillet()
        }
    }

    Timer {
        id: keskeytaAika
        interval: 20*1000 //
        running: false
        repeat: false
        onTriggered: {
            kelloKay = true
            paivyriKay = true
            muutaAjanKirjasin()
            paivitaAika()
            running = false
        }
    }


    // tunnus, aikaMs, mlVeressa, juomaaika, juomatyyppi, juomamaara, juomapros, kuvaus
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
                            tyhjennaDbJuodut(lueJuomanId(valittu))
                            juomat.remove(valittu)                            
                            paivitaMlVeressa(lueJuomanAika(valittu)-1, valittu); //-1 varmistaa, että usean samaan aikaan juodun juoman kohdalla päivitys toimii
                            paivitaPromillet();
                            paivitaAjatRajoille();
                            paivitaKuvaaja();

                        })

                    }
                }

                MenuItem {
                    text: qsTr("modify")
                    onClicked: {
                        muutaValittu(valittu);

                        paivitaMlVeressa(lueJuomanAika(valittu)-1, valittu);
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
                    text: tunnus
                    visible: false
                    width: 0
                }
                Label {
                    text: aikaMs
                    visible: false
                    width: 0
                }

                Label {
                    text: mlVeressa
                    visible: false
                    width: 0
                }
                Label {
                    text: juomaaika
                    width: (Theme.fontSizeMedium*3.5).toFixed(0) //ExtraSmall*6
                }
                Label {
                    text: juomatyyppi
                    width: Theme.fontSizeMedium*7 //ExtraSmall*8
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    text: juomamaara
                    width: (Theme.fontSizeMedium*2.5).toFixed(0) //ExtraSmall*3
                }
                Label {
                    text: juomapros
                    width: (Theme.fontSizeMedium*2.5).toFixed(0) //ExtraSmall*3
                }
                Label {
                    text: kuvaus
                    visible: false
                    width: 0
                }

            } //row


        } //listitem
    } //rivityyppi

    Component {
        id: mlViikkoPylvas
        ListItem {
            id: mlViikkoPylvasOsio
            height: kuvaajanKorkeus + mlViikkoPylvaanNimi.height
            width: mlOtsikonLeveys
            propagateComposedEvents: true
            onClicked: {
                mouse.accepted = false
                tilastojenTarkastelu()
            }

            Row {
                Label {
                    id: idOtsikko
                    text: otsikko // vuosi
                    rotation: 90
                    visible: jaksoNakyvissa
                    width: font.pixelSize
                }

                Column {

                    Rectangle {
                        id: mlViikkoPylvaanY
                        height: kuvaajanKorkeus - mlViikkoPylvaanKorkeus.height
                        width: (mlViikkoPylvaanLeveys*1.2).toFixed() //mlViikkoPylvaanLeveys
                        border.width: 0
                        border.color: "transparent"
                        color: "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        id: mlViikkoPylvaanKorkeus
                        height: mlViikkoPylvasArvo
                        width: (mlViikkoPylvaanLeveys*0.8).toFixed() //mlViikkoPylvaanLeveys-8
                        //border.width: (mlViikkoPylvaanLeveys*0.4).toFixed() //0
                        //border.color: "transparent"
                        color: mlViikkoPylvaanVari //"red"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        id: mlViikkoPylvaanNimi
                        text: mlViikkoPylvasAika
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.horizontalCenter: parent.horizontalCenter
                        //width: (mlViikkoPylvaanLeveys*2.5).toFixed() //mlViikkoPylvaanLeveys
                        horizontalAlignment: Text.AlignHCenter
                    } //

                    Label {                        
                        text: mlViikkoPylvasTunnus //viikkoa tai paivaa ajankohdasta 1970.1.1 00:00
                        visible: false
                        height: 0
                        width: (mlViikkoPylvaanLeveys*1.2).toFixed() //mlViikkoPylvaanLeveys
                    } //

                }//column
            } //row            
        }//listitem
    }

    Component {
        id: mlViikkoPylvasOtsikko

        Column {
            Label {
                text: vkoRaja1 + " ml"
                rotation: 90
                //anchors.horizontalCenter: parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                height: kuvaajanKorkeus*0.5*(vkoRaja2 - vkoRaja1)/(0.5*(vkoRaja2+vkoRaja1))
                font.pixelSize: Theme.fontSizeExtraSmall
                width: (pikkuKirjainKoko*1.2).toFixed() //31
            }
            Rectangle {
                height: kuvaajanKorkeus*vkoRaja1/(0.5*(vkoRaja2+vkoRaja1))
                width: pikkuKirjainKoko //27
                anchors.horizontalCenter: parent.horizontalCenter
                //border.width: 1
                //border.color: "transparent"
                color: jaksonVari(0.5*vkoRaja1)
                z: -1
            }
            Label {
                text: qsTr("wk")
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

    }

    Component {
        id: mlPaivaPylvas
        ListItem {
            id: mlViikkoPylvasOsio
            height: kuvaajanKorkeus + mlPaivaPylvaanNimi.height
            width: mlOtsikonLeveys
            propagateComposedEvents: true
            onClicked: {
                mouse.accepted = false
                tilastojenTarkastelu()
            }

            Row {
                Label {
                    id: idOtsikko
                    text: otsikko
                    rotation: 90
                    visible: jaksoNakyvissa
                    width: font.pixelSize
                }

                Column {
                    Rectangle { // asettaa väripylvään yläreunan oikealle tasalle
                        id: mlPaivaPylvaanY
                        height: kuvaajanKorkeus - mlPaivaPylvaanKorkeus.height
                        width: mlPaivaPylvaanLeveys
                        border.width: 0
                        color: "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        id: mlPaivaPylvaanKorkeus
                        height: mlPaivaPylvasArvo
                        width: mlPaivaPylvaanLeveys-8
                        //border.width: 1
                        //border.color: "transparent"
                        color: mlPaivaPylvaanVari //"red"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        id: mlPaivaPylvaanNimi
                        text: mlPaivaPylvasAika
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.horizontalCenter: parent.horizontalCenter
                    } //
                    Label {
                        text: mlPaivaPylvasTunnus //viikkoa tai paivaa ajankohdasta 1970.1.1 00:00
                        visible: false
                        height: 0
                        width: mlPaivaPylvaanLeveys
                    } //
                }//column
            } //row
        }//listitem
    }

    Component {
        id: mlPaivaPylvasOtsikko

        Column {
            Label {
                text: vrkRaja1 + " ml"
                rotation: 90
                //anchors.horizontalCenter: parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                height: kuvaajanKorkeus*0.5*(vrkRaja2 - vrkRaja1)/(0.5*(vrkRaja2+vrkRaja1))
                font.pixelSize: Theme.fontSizeExtraSmall
                width: pikkuKirjainKoko //25
            }
            Rectangle {
                height: kuvaajanKorkeus*vrkRaja1/(0.5*(vrkRaja2+vrkRaja1))
                width: pikkuKirjainKoko //22
                anchors.horizontalCenter: parent.horizontalCenter
                //border.width: 1
                //border.color: "transparent"
                color: jaksonVari(0.5*vrkRaja1)
                z: -1
            }
            Label {
                text: ""
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

    }

    Component {
        id: juomaPaivia
        ListItem {
            id: juomaPaiviaOsio
            height: kuvaajanKorkeus + juomaPaiviaNimi.height
            width: juomaPaiviaLeveys
            propagateComposedEvents: true
            onClicked: {
                mouse.accepted = false
                tilastojenTarkastelu()
            }

            Row {
                Label {
                    id: idOtsikko
                    text: otsikko
                    rotation: 90
                    visible: jaksoNakyvissa
                    width: font.pixelSize
                }

                Column {
                    Rectangle {
                        height: kuvaajanKorkeus*1/7
                        width: 23
                        border.width: 1
                        border.color: "transparent"
                        color: juomaPaiviaSu
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        height: kuvaajanKorkeus*1/7
                        width: 23
                        border.width: 1
                        border.color: "transparent"
                        color: juomaPaiviaLa
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        height: kuvaajanKorkeus*1/7
                        width: 23
                        border.width: 1
                        border.color: "transparent"
                        color: juomaPaiviaPe
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        height: kuvaajanKorkeus*1/7
                        width: 23
                        border.width: 1
                        border.color: "transparent"
                        color: juomaPaiviaTo
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        height: kuvaajanKorkeus*1/7
                        width: 23
                        border.width: 1
                        border.color: "transparent"
                        color: juomaPaiviaKe
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        height: kuvaajanKorkeus*1/7
                        width: 23
                        border.width: 1
                        border.color: "transparent"
                        color: juomaPaiviaTi
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        height: kuvaajanKorkeus*1/7
                        width: 23
                        border.width: 1
                        border.color: "transparent"
                        color: juomaPaiviaMa
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        id: juomaPaiviaNimi
                        text: juomaPaiviaAika //viikon numero
                        //width: 31
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.horizontalCenter: parent.horizontalCenter
                    } //
                    Label {
                        //id: viivanTunnus //viikkoa, paivaa tai minuuttia ajankohdasta 1970.1.1 00:00
                        text: juomaPaiviaTunnus
                        visible: false
                        height: 0
                        width: parent.width
                    } //
                }//column
            } //row
        }
    }

    Component {
        id: juomaPaiviaOtsikko

        Column {
            Label {
                text: qsTr("su fr we mo")
                font.pixelSize: Theme.fontSizeExtraSmall
                width: 31
                rotation: 90
            }

        }

    }


    SilicaFlickable {
        id: ylaosa
        height: column.height
        width: sivu.width
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("info")
                onClicked:
                    pageStack.push(Qt.resolvedUrl("tietoja.qml"))
            }

            MenuItem {
                text: qsTr("settings")
                onClicked:
                    kysyAsetukset()
            }

            MenuItem {
                text: qsTr("demo")
                onClicked:
                    pageStack.push(Qt.resolvedUrl("demolaskuri.qml"), {
                                   "promilleRaja1": promilleRaja1,
                                   "promilleja": laskePromillet(new Date().getTime()),
                                   "vetta": vetta, "paino": massa
                                   })
            }

        }

        Column {
            id: column

            width: sivu.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Drunkard?")
            }

            SilicaListView {
                id: kuvaaja
                height: kuvaajanKorkeus + Theme.fontSizeExtraSmall + 7
                //width: sivu.width - 2*sivu.anchors.leftMargin //parent.width
                width: sivu.width - 2*Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: ListView.Horizontal
                visible: (nakyvaKuvaaja < 0.5 || nakyvaKuvaaja > 1.5) ? false : true

                model: ListModel {
                    id: viikkoArvot
                }

                //section { //section ei jostain syystä toimi
                    //property: 'section'
                    //delegate: SectionHeader {
                        //text: aikaJakso
                        //rotation: 90
                        //transform: Rotation { angle: 90 }
                    //}
                //}

                delegate: mlViikkoPylvas

                header: mlViikkoPylvasOtsikko

                HorizontalScrollDecorator {}

            }

            SilicaListView {
                id: kuvaaja3
                height: kuvaajanKorkeus + Theme.fontSizeExtraSmall + 7
                width: sivu.width - 2*sivu.anchors.leftMargin //parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: ListView.Horizontal
                visible: (nakyvaKuvaaja < 1.5) ? false : true

                model: ListModel {
                    id: mlPaivaArvot
                }

                //section { //section ei jostain syystä toimi
                    //property: 'section'
                    //delegate: SectionHeader {
                        //text: aikaJakso
                        //rotation: 90
                        //transform: Rotation { angle: 90 }
                    //}
                //}

                delegate: mlPaivaPylvas

                header: mlPaivaPylvasOtsikko

                HorizontalScrollDecorator {}

            }

            SilicaListView {
                id: kuvaaja2
                height: kuvaajanKorkeus + Theme.fontSizeExtraSmall + 7
                width: sivu.width - 2*sivu.anchors.leftMargin //parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: ListView.Horizontal
                visible: (nakyvaKuvaaja < 0.5) ? true : false

                model: ListModel {
                    id: paivaArvot
                }

                delegate: juomaPaivia

                header: juomaPaiviaOtsikko

                HorizontalScrollDecorator {}

            }

            Row { // promillet
                spacing: 10

                TextField {
                    id: txtPromilleja
                    text: "X ‰"
                    label: qsTr("BAC")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.primaryColor
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
                    label: promilleRaja1.toFixed(1) + qsTr(" ‰ at")
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

                            kelloKay = false
                            keskeytaAika.running = true
                            muutaAjanKirjasin()

                            paivitaPromillet()
                        })
                    }

                    width: Theme.fontSizeSmall*6
                    value: pvm.toLocaleTimeString(Qt.locale(),kelloMuoto)
                    onClicked: {
                        if (kelloKay == true)
                            openTimeDialog()
                        else {
                            kelloKay = true
                            paivyriKay = true
                            muutaAjanKirjasin()
                            paivitaAika()
                        }
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
                            value = pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat)

                            paivyriKay = false
                            keskeytaAika.running = true
                            muutaAjanKirjasin()

                            paivitaPromillet()
                        })
                    }

                    value: pvm.toLocaleDateString(Qt.locale(),Locale.ShortFormat)
                    width: Theme.fontSizeSmall*8//sivu.width - kello.width - 3*Theme.paddingSmall
                    onClicked: {
                        if (paivyriKay == true)
                            avaaPaivanValinta()
                        else {
                            paivyriKay = true
                            kelloKay = true
                            muutaAjanKirjasin()
                            paivitaAika()
                        }
                    }
                }

            } // aika

            Row { //lisattava juoma
                spacing: 0

                TextField {
                    id: txtJuoma
                    width: Theme.fontSizeMedium*5.8 //Theme.fontSizeExtraSmall*8
                    readOnly: true
                    text: qsTr("beer")
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: txtMaara
                    label: "ml"
                    width: Theme.fontSizeMedium*3 //Theme.fontSizeExtraSmall*4
                    readOnly: true
                    text: "500"
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: voltit
                    label: qsTr("vol-%")
                    width: (Theme.fontSizeMedium*3.7).toFixed(0) //Theme.fontSizeExtraSmall*5
                    readOnly: true
                    text: "4.7"
                    onClicked: {
                        muutaUusi()
                    }
                }

                Button { //add
                    id: kulautus
                    width: Theme.fontSizeMedium*4 //sivu.width - txtJuoma.width - txtMaara.width - voltit.width - 8 //100

                    text: qsTr("cheers!")
                    onClicked: {
                        uusiJuoma(new Date().getTime(), pvm.getTime(), 0.0, parseInt(txtMaara.text),
                                 parseFloat(voltit.text), txtJuoma.text, juomanKuvaus)
                        juomaLista.positionViewAtEnd()

                        lisaaKuvaajaan(pvm.getTime(), parseInt(txtMaara.text), parseFloat(voltit.text))
                        paivyriKay = true
                        kelloKay = true
                        muutaAjanKirjasin()
                        paivitaAika()
                        juomanKuvaus = ""
                    }
                }
            }

            Rectangle {
                height: 1
                width: 0.9*parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                color: "dimgray"
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

        } //column

    }// SilicaFlickable

    Component.onCompleted: {
        alkutoimet()
    }
}


