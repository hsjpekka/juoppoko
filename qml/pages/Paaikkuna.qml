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
    anchors.leftMargin: 0.05*width
    property date pvm: new Date() // kello- ja päiväkohdissa oleva aika (sekunnit ja millisekunnit = 0.0, alustusta lukuunottamatta )
    property string kelloMuoto: "HH:mm"
    property real polttonopeus: 0.1267 // ml/kg/h -- 1 g/10 kg/h = 1.267 ml/10 kg/h
    property real tiheys: 0.7897 // alkoholin tiheys, g/ml
    property int tunti: 60*60*1000 // ms
    property int vrk: 24*tunti // ms

    property date msSelvana: new Date()
    property date msKunnossa: new Date()
    property string juomanKuvaus: ""
    property int kuvaajanKorkeus: 121

    property int valittu: 0

    property bool kelloKay: true // true - kellonaika ja päivämäärä juoksevat, false - pysyvät vakioina
    property bool paivyriKay: true

    property var db: null
    property string virheet: ""

    //hakusanat: ["ajoraja1", "ajoraja2", "paivaraja1", "paivaraja2", "viikkoraja1", "viikkoraja2", "vuosiraja1", "vuosiraja2"]
    //alkuarvot: [    0.5,    1.0,        120,            320,        500,            1000,            5000,        10000]
    property string tunnusProm1: "ajoraja1"
    property real promilleRaja1: 0.5 // 0.5 = 0.5 promillea
    property string tunnusProm2: "ajoraja2"
    property real promilleRaja2: 1.0 // 1.0 = 1 promille
    property string tunnusVrkRaja1: "paivaraja1"
    property int vrkRaja1: 120 // ml alkoholia
    property string tunnusVrkRaja2: "paivaraja2"
    property int vrkRaja2: 320 // ml alkoholia
    property string tunnusVkoRaja1: "viikkoraja1"
    property int vkoRaja1: 150 // ml alkoholia
    property string tunnusVkoRaja2: "viikkoraja2"
    property int vkoRaja2: 350 // ml alkoholia
    property string tunnusVsRaja1: "vuosiraja1"
    property int vsRaja1: 7000 // ml alkoholia
    property string tunnusVsRaja2: "vuosiraja2"
    property int vsRaja2: 20000 // ml alkoholia

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

        //console.log("juomien väli " + Math.round(dt*60) + " min " + mlJuoma*vahvuus/100 + " " + palonopeus()*dt)

        if (ml1 < 0)
            ml1 = 0

        return ml1
    }

    function alkutoimet() {
        var ehto = 0

        avaaDb();
        lueAsetukset();
        ehto = lueJuomari()

        lueSuosikit();
        lueJuodut();

        paivitaPromillet();
        paivitaAjatRajoille();
        //naytaTilastot();
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
    // hakee sarjasta ensimmäisen alkion, jonka pylvasTunnus on yhtä suuri tai suurempi kuin id
    // jos id < ensimmäisen alkion pylvasTunnus, palauttaa eron negatiivisena
    // jos id > viimeisen alkion pylvasTunnus, palauttaa alkioiden määrän + 1
    // jos sarja on tyhjä, palauttaa 0
    function etsiJakso(sarja, id) {
        var i=0

        if (sarja.count < 1) {
            return 0;
        }

        if (sarja.get(0).pylvasTunnus > id)
            return id - sarja.get(0).pylvasTunnus;

        while ( (i < sarja.count) && (sarja.get(i).pylvasTunnus < id) ) {
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

        //console.log("lisäyskohta " + listIndex )

        return ind0
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

    function laskePromillet(ms){
        var ml0, edellinen = etsiPaikka(ms, juomat.count -1)

        ml0 = mlKehossa(edellinen-1, ms)

        return ml0*tiheys/(massa*vetta)
    }

    // xid - juoman tunnus, hetki - juontiaika [ms], veressa - ml alkoholia veressä hetkellä hetki,
    // maara - juoman tilavuus, vahvuus- juoman prosentit, juomanNimi - nimi, juomanKuvaus - tekstiä
    function lisaaDbJuodut(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus) {

        if(db == null) return;

        var komento = "INSERT INTO juodut (id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus)" +
                " VALUES (" + xid + ", " + hetki + ", " + mlVeressa + ", " + maara + ", " +
                vahvuus + ", '" + juomanNimi + "', '" + juomanKuvaus + "')"

        try {
            db.transaction(function(tx){
                tx.executeSql(komento);

            });
        } catch (err) {
            //console.log("Error adding to juodut-table in database: " + err);
            virheet = virheet + "Error adding to juodut-table in database: " + err +" <br> "
        };

        return
    }    

    function jaksonVari(maara){
        //console.log("jaksonVari " + maara + " vkoRaja1 " + vkoRaja1 + " vkoRaja2 " + vkoRaja2)
        if (maara > vkoRaja2 )
            return "red"
        else if (maara > vkoRaja1)
            return "yellow"
        else
            return "green"
    }

    function juomienMaara() {
        return juomat.count
    }

    // sarja = kuvaajan id, monesko = 0-N - järjestys kuvaajassa, maara = piirrettavan pylvaan korkeus, merkki = pylvään alla näkyvä teksti,
    // id = piirrettävän pylvään tunnus, jakso = väliotsikko
    function lisaaJaksoon(sarja, monesko, maara, merkki, id, jakso) {
        var vari = "green"
        var skaala = kuvaajanKorkeus/(0.5*(vkoRaja2+vkoRaja1))
        var otsikkoNakyviin = false
        var leveys = 30

        if (merkki == 1) {
            otsikkoNakyviin = true
            leveys = 60
        }

        if ( (monesko >= sarja.count) || (sarja.count == 0) ) {
            vari = jaksonVari(maara)
            sarja.append({"pylvasArvo": maara*skaala, "pylvasAika": merkki, "pylvasTunnus": id, "pylvaanVari": vari, "aikaJakso": jakso,
                             "otsikko": jakso, "jaksoNakyvissa": otsikkoNakyviin, "pylvaanLeveys": leveys })
        } else {
            if (sarja.get(monesko).pylvasTunnus == id) {
                sarja.get(monesko).pylvasArvo = sarja.get(monesko).pylvasArvo + maara*skaala
                sarja.get(monesko).pylvaanVari = jaksonVari(sarja.get(monesko).pylvasArvo/skaala)                
            }
            else {
                vari = jaksonVari(maara)
                sarja.insert(monesko, {"pylvasArvo": maara*skaala, "pylvasAika": merkki, "pylvasTunnus": id, "pylvaanVari": vari, "aikaJakso": jakso,
                                 "otsikko": jakso, "jaksoNakyvissa": otsikkoNakyviin, "pylvaanLeveys": leveys})
            }
        }

        return
    }

    function lisaaKuvaajaan(hetki, maara, vahvuus) {
        var vk1, vkJuoma, i, pv1g, pvJuoma, alkoholia = maara*vahvuus/100, vuosi = new Date(hetki).getFullYear()

        // montako viikkoa hetkestä 1970.1.1. 00:00
        // varmistetaan, että ma = 0 ja su = 6
        if (new Date(2017,0,1,1,1,1).getDay() == 0) {
            pv1g = new Date(0).getDay() - 1
            if (pv1g < 0)
                pv1g = 6
        }

        vkJuoma = Math.floor((hetki+pv1g*vrk)/(7*vrk))

        i = etsiJakso(viikkoArvot, vkJuoma)

        // jos lisätty juoma on juotu ennen nykyistä taulukkoa
        if (i < 0) {
            vk1 = viikkoArvot.get(0).pylvasTunnus - 1
            while (vk1 > vkJuoma){
                lisaaJaksoon(viikkoArvot, 0, 0, viikonNumero(vk1*7*vrk), vk1, new Date(vk1*7*vrk).getFullYear())
                vk1--
            }
        }
        // jos lisätty juoma on juotu nykyisen taulukon jälkeen
        if ( (i >= viikkoArvot.count) && (viikkoArvot.count > 0) ) {
            vk1 = viikkoArvot.get(viikkoArvot.count-1).pylvasTunnus + 1
            while (vk1 < vkJuoma){
                //console.log("lisaaKuvaajaan 2: " +  viikonNumero(vk1*7*vrk) + " " + vk1)
                lisaaJaksoon(viikkoArvot, viikkoArvot.count, 0, viikonNumero(vk1*7*vrk), vk1, new Date(vk1*7*vrk).getFullYear())
                vk1++
            }
            i = viikkoArvot.count
        }

        lisaaJaksoon(viikkoArvot, i, alkoholia, viikonNumero(hetki), vkJuoma, new Date(vkJuoma*7*vrk).getFullYear())

        // päivittäiset määrät
        pvJuoma = Math.floor(hetki/vrk) // montako päivää hetkestä 1970.1.1. 00:00

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
                                 "juomamaara": maara, "juomapros": vahvuus, "kuvaus": juomanKuvaus});
            paivitaMlVeressa(hetki, ind);

        } else
            juomat.append({"tunnus": xid, "aikaMs": hetki, "mlVeressa": mlVeressa,
                                 "section": paiva, "juomaaika": kello, "juomatyyppi": juomanNimi,
                                 "juomamaara": maara, "juomapros": vahvuus, "kuvaus": juomanKuvaus});
        return
    }

    function lueAsetukset() {
        var luettu = 0

        if(db == null) return luettu;

        try {
            db.transaction(function(tx) {
                var taulukko  = tx.executeSql("SELECT asia, arvo FROM asetukset");

                for (var i = 0; i < taulukko.rows.length; i++ ) {
                    if (taulukko.rows[i].asia == tunnusProm1 )
                        promilleRaja1 = taulukko.rows[i].arvo;
                    else if (taulukko.rows[i].asia == tunnusProm2 )
                        promilleRaja2 = taulukko.rows[i].arvo;
                    else if (taulukko.rows[i].asia == tunnusVrkRaja1 )
                        vrkRaja1 = taulukko.rows[i].arvo;
                    else if (taulukko.rows[i].asia == tunnusVrkRaja2 )
                        vrkRaja2 = taulukko.rows[i].arvo;
                    else if (taulukko.rows[i].asia == tunnusVkoRaja1 )
                        vkoRaja1 = taulukko.rows[i].arvo;
                    else if (taulukko.rows[i].asia == tunnusVkoRaja2 )
                        vkoRaja2 = taulukko.rows[i].arvo;
                    else if (taulukko.rows[i].asia == tunnusVsRaja1 )
                        vsRaja1 = taulukko.rows[i].arvo;
                    else if (taulukko.rows[i].asia == tunnusVsRaja2 )
                        vsRaja2 = taulukko.rows[i].arvo;
                }

                if(taulukko.rows.length <= 0){
                    uusiAsetukset()
                } else {
                    luettu = i
                }

            });

        } catch (err) {
            console.log("Error adding to juodut-table in database: " + err);
            virheet = virheet + "Error adding to juodut-table in database: " + err +" <br> "

        }

        return luettu
    }

    function lueJuodut() {
        var nytMs = new Date().getTime()
        //var mlVko = 0
        //var mlVs = 0
        //var mlJuomassa

        //readingDb = 0

        try {
            db.transaction(function(tx) {
                var taulukko = tx.executeSql("SELECT * FROM juodut ORDER BY aika ASC");

                for (var i = 0; i < taulukko.rows.length; i++ ) {
                    lisaaListaan(taulukko.rows[i].id, taulukko.rows[i].aika, taulukko.rows[i].veressa,
                             taulukko.rows[i].tilavuus, taulukko.rows[i].prosenttia,
                             taulukko.rows[i].juoma, taulukko.rows[i].kuvaus);

                    lisaaKuvaajaan(taulukko.rows[i].aika, taulukko.rows[i].tilavuus, taulukko.rows[i].prosenttia);

                } // for

            });

        } catch (err) {
            console.log("lueJuodut: " + err);
        }

        return;
    }

    function lueJuomanAika(xid) {  // palauttaa ajan millisenkunteina
        var ms = 0
        if ((juomat.count > xid) && (xid > -0.5)) {
            //return new Date(juomat.get(index2).section + " " + juomat.get(index2).juomaaika)
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

        mlRajalle = ml0 + koko0*vahvuus0/100 - promillea*massa*vetta/tiheys//*1000
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
                          "juomapros": vahvuus, "kuvaus": juomanKuvaus});

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
                        "juomanKuvaus": juomanKuvaus
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
            txtMaara.text = dialog.maara
            voltit.text = dialog.vahvuus
            juomanKuvaus = dialog.juomanKuvaus

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
                        "juomanKuvaus": juomanKuvaus
                     })

        dialog.accepted.connect(function() {
            muutaJuoma(qId, dialog.aika.getTime(), parseFloat(lueMlVeressa(qId)), dialog.maara,
                        dialog.vahvuus, dialog.nimi, dialog.juomanKuvaus)
            juomanKuvaus = dialog.juomanKuvaus            
            paivitaMlVeressa(dialog.aika.getTime(), qId)
            paivitaTilastot()
            //naytaTilastot()
            paivitaPromillet()
            paivitaAjatRajoille()
            lisaaKuvaajaan(vanhaHetki, -vanhaMaara, vanhaVahvuus)
            lisaaKuvaajaan(dialog.aika.getTime(), dialog.maara, dialog.vahvuus)

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

    function paivitaAika() {
        var paiva = new Date()

        if ( (kelloKay == true) && (paivyriKay == true)) {
            pvm = paiva
            kello.valittuTunti = paiva.getHours()
            kello.valittuMinuutti = paiva.getMinutes()
            kello.value = kellonaika(paiva.getTime()) //pvm.toLocaleTimeString(Qt.locale(), kelloMuoto)
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
            });
        } catch (err) {
            console.log("Error modifying asetukset-table in database: " + err);
            virheet = virheet + "Error modifying asetukset-table in database: " + err +" <br> "
        };

        return
    }

    // etsii juomalistasta hetkeä nytMs edeltävän juoman tiedot ja laskee hetken nytMs promillemäärän
    function paivitaPromillet() {
        var nytMs = pvm.getTime()
        //var edell = etsiPaikka(nytMs, juomat.count -1)
        var ml0, prml
        //var edAika

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

    function tilastojenTarkastelu(){
        //var dialog = pageStack.push(Qt.resolvedUrl("tilastot.qml"), { })
        pageStack.push(Qt.resolvedUrl("tilastot.qml"))

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

    function tyhjennaTaulukko(taulukko) {

        if(db == null) return;

        if (taulukko == ""){
            taulukko = "juomari"
        }

        try {
            db.transaction(function(tx){
                    tx.executeSql('DELETE FROM ' + taulukko); // WHERE condition
            });
        } catch (err) {
            console.log("Error deleting table " + taulukko + " in database: " + err);
            virheet = virheet + "Error deleting tables in database: " + err +" <br> "
        };

        return
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

        //console.log("hetki " + hetki)

        // lasketaan paljonko veressä on alkoholia juomishetkellä
        mlVeressa = mlKehossa(lisayskohta-1, hetki)

        lisaaListaan(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus, lisayskohta)

        lisaaDbJuodut(xid, hetki, mlVeressa, maara, vahvuus, juomanNimi, juomanKuvaus);

        paivitaPromillet();

        paivitaAjatRajoille();

        kansi.update();

        return;
    }

    // hetki = ms
    // jos vuoden ensimmäinen päivä on ma-to, aloittaa se 1. viikon - muuten kyseessä edellisen vuoden 53. viikko
    function viikonNumero(hetki) {
        var pv = new Date(hetki)
        var vuosi = pv.getFullYear()
        var ekapvm = new Date(vuosi,0,1,0,0,0)
        var vkpaiva = ekapvm.getDay() //0-6
        var vk0, vknyt, erovk, eropv, eroms

        // varmistetaan, että ma = 0 ja su = 6
        if (new Date(2017,0,1,1,1,1).getDay() == 0) {
            vkpaiva = vkpaiva - 1
            if (vkpaiva < 0)
                vkpaiva = 6
        }

        if (vkpaiva > 3.5) // pe-su
            vk0 = 0        
        else //ma-to
            vk0 = 1

        eroms = hetki-ekapvm.getTime() // ms
        erovk = Math.floor((eroms)/(7*vrk)) // vko
        eropv = Math.floor((eroms-erovk*7*vrk)/vrk) // vrk

        //console.log("viikonNumero " + "vuosi " + vuosi + ", aloituspaiva " + vkpaiva + ", " + "vk0 " + vk0 + ", erovk " + erovk)

        if ( vkpaiva + eropv > 6.5) {
            vknyt = vk0 + erovk + 1
        } else {
            vknyt = vk0 + erovk
        }

        if (vknyt < 0.5 )
            vknyt = viikonNumero(new Date(vuosi-1,11,31,10,0,0).getTime())

        return vknyt
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
                    text: qsTr("poista")
                    onClicked: {
                        juomaLista.currentItem.remorseAction(qsTr("poistaa"), function () {
                            lisaaKuvaajaan(lueJuomanAika(valittu),-lueJuomanMaara(valittu),lueJuomanVahvuus(valittu))
                            tyhjennaDbJuodut(lueJuomanId(valittu))
                            juomat.remove(valittu)                            
                        })

                        paivitaMlVeressa(lueJuomanAika(valittu)-1, valittu); //-1 varmistaa, että usean samaan aikaan juodun juoman kohdalla päivitys toimii
                        paivitaPromillet();
                        paivitaAjatRajoille();

                    }
                }

                MenuItem {
                    text: qsTr("muokkaa")
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
                    //id: juomanTunnus
                    text: tunnus
                    visible: false
                    width: 0
                }
                Label {
                    //id: idDrinkTimeInMs
                    text: aikaMs
                    visible: false
                    width: 0
                }

                Label {
                    //id: idAlcInBlood
                    text: mlVeressa
                    visible: false
                    width: 0
                }
                Label {
                    //id: idDrinkTime
                    text: juomaaika
                    width: Theme.fontSizeExtraSmall*6
                }
                Label {
                    //id: idDrinkName
                    text: juomatyyppi
                    width: Theme.fontSizeExtraSmall*8
                }
                Label {
                    //id: idDrinkAmount
                    text: juomamaara
                    width: Theme.fontSizeExtraSmall*3
                }
                Label {
                    //id: idDrinkAlc
                    text: juomapros
                    width: Theme.fontSizeExtraSmall*3
                }
                Label {
                    //id: idDrinkDescription
                    text: kuvaus
                    visible: false
                    width: 0
                }

            } //row


        } //listitem
    } //rivityyppi

    Component {
        id: pylvas
        ListItem {
            id: pylvasOsio
            height: kuvaajanKorkeus + pylvaanNimi.height
            width: pylvaanLeveys
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
                        id: pylvaanY
                        height: kuvaajanKorkeus - pylvaanKorkeus.height
                        width: 31
                        border.width: 0
                        color: "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        id: pylvaanKorkeus
                        height: pylvasArvo
                        width: 23
                        //border.width: 1
                        //border.color: "transparent"
                        color: pylvaanVari //"red"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        id: pylvaanNimi
                        text: pylvasAika
                        //width: 31
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.horizontalCenter: pylvaanY.horizontalCenter
                    } //
                    Label {
                        //id: viivanTunnus //viikkoa, paivaa tai minuuttia ajankohdasta 1970.1.1 00:00
                        text: pylvasTunnus
                        visible: false
                        height: 0
                        width: parent.width
                    } //
                }//column
            } //row            
        }
    }

    SilicaFlickable {
        id: ylaosa
        height: column.height
        width: sivu.width
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("tietoja")
                onClicked:
                    pageStack.push(Qt.resolvedUrl("tietoja.qml"))
            }

            MenuItem {
                text: qsTr("asetukset")
                onClicked:
                    kysyAsetukset()
            }

        }

        Column {
            id: column

            width: sivu.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Juoppoko")
            }

            SilicaListView {
                id: kuvaaja
                height: kuvaajanKorkeus + Theme.fontSizeExtraSmall + 7
                width: sivu.width - 2*sivu.anchors.leftMargin //parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: ListView.Horizontal

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

                delegate: pylvas

                header: Column {
                    Label {
                        text: vkoRaja1 + " ml"
                        rotation: 90
                        //anchors.horizontalCenter: parent.horizontalCenter
                        verticalAlignment: Text.AlignVCenter
                        height: kuvaajanKorkeus*0.5*(vkoRaja2 - vkoRaja1)/(0.5*(vkoRaja2+vkoRaja1))
                        font.pixelSize: Theme.fontSizeExtraSmall
                        width: 31
                    }
                    Rectangle {
                        height: kuvaajanKorkeus*vkoRaja1/(0.5*(vkoRaja2+vkoRaja1))
                        width: 27
                        anchors.horizontalCenter: parent.horizontalCenter
                        //border.width: 1
                        //border.color: "transparent"
                        color: jaksonVari(0.5*vkoRaja1)
                        z: -1
                    }
                    Label {
                        id: kuvaajanXakseli
                        text: qsTr("vk")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                }                

                HorizontalScrollDecorator {}

            }

            Row { // promillet
                spacing: 10

                TextField {
                    id: txtPromilleja
                    text: "X ‰"
                    label: qsTr("veressä")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.primaryColor
                    readOnly: true
                }

                TextField {
                    id: txtSelvana
                    text: "?"
                    label: qsTr("selvänä")
                    font.pixelSize: Theme.fontSizeSmall
                    width: Theme.fontSizeSmall*6
                    readOnly: true
                }

                TextField {
                    id: txtAjokunnossa
                    text: "?"
                    label: promilleRaja1.toFixed(1) + qsTr(" ‰ klo")
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

                    width: Theme.fontSizeExtraSmall*8
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
                    width: sivu.width - kello.width - 3*Theme.paddingSmall
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

            Row { //arvot
                //id: drinkData
                spacing: 2

                TextField {
                    id: txtJuoma
                    width: Theme.fontSizeExtraSmall*8
                    readOnly: true
                    text: qsTr("olut")
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: txtMaara
                    label: "ml"
                    width: Theme.fontSizeExtraSmall*4
                    readOnly: true
                    text: "500"
                    onClicked: {
                        muutaUusi()
                    }
                }

                TextField {
                    id: voltit
                    label: qsTr("til-%")
                    width: Theme.fontSizeExtraSmall*5
                    readOnly: true
                    text: "4.7"
                    onClicked: {
                        muutaUusi()
                    }
                }

                Button { //add
                    width: 100

                    text: qsTr("skåål!")
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
                color: "black"
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
                        text: qsTr("aika")
                        width: Theme.fontSizeExtraSmall*6
                    }
                    Label {
                        text: qsTr("juoma")
                        width: Theme.fontSizeExtraSmall*8
                    }
                    Label {
                        text: "ml"
                        width: Theme.fontSizeExtraSmall*3
                    }
                    Label {
                        text: qsTr("til-%")
                        width: Theme.fontSizeExtraSmall*3
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


