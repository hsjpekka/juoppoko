.pragma library

var tkanta
//asetusten tunnukset ja oletusarvot
//hakusanat: ["ajoraja1", "ajoraja2", "paivaraja1", "paivaraja2", "viikkoraja1", "viikkoraja2", "vuosiraja1", "vuosiraja2"]
//alkuarvot: [    0.5,    1.0,        120,            320,        500,            1000,            5000,        10000]
var tunnusProm1 = "ajoraja1"
var promilleRaja1 = 0.5 // 0.5 = 0.5 promillea
var luettuPromilleRaja1 = false
var tunnusProm2 = "ajoraja2"
var promilleRaja2 = 1.0 // 1.0 = 1 promille
var luettuPromilleRaja2 = false
var tunnusVrkRaja1 = "paivaraja1"
var vrkRaja1 = 120 // ml alkoholia
var luettuVrkRaja1 = false
var tunnusVrkRaja2 = "paivaraja2"
var vrkRaja2 = 320 // ml alkoholia
var luettuVrkRaja2 = false
var tunnusVkoRaja1 = "viikkoraja1"
var vkoRaja1 = 150 // ml alkoholia
var luettuVkoRaja1 = false
var tunnusVkoRaja2 = "viikkoraja2"
var vkoRaja2 = 350 // ml alkoholia
var luettuVkoRaja2 = false
var tunnusVsRaja1 = "vuosiraja1"
var vsRaja1 = 7000 // ml alkoholia
var luettuVsRaja1 = false
var tunnusVsRaja2 = "vuosiraja2"
var vsRaja2 = 20000 // ml alkoholia
var luettuVsRaja2 = false
var tunnusTilavuusMitta = "tilavuusMitta"
var arvoTilavuusMitta = 1 // juoman tilavuusyksikkö juomien syöttöikkunassa, 1 = ml, 2 = us oz, 3 = imp oz, 4 = imp pint, 5 = us pint
var luettuYksikko = false
var tunnusUnTappdToken = "untappdtoken"
var arvoUnTpToken = ""
var luettuUnTpToken = false
var tunnusTalletaSijainti = "talletaSijainti"
var arvoTalletaSijainti = 0 // 0 - älä, 1 - vain jos baariId tiedossa, 2 - myös koordinaatit
var luettuTalletaSijainti = false
var tunnusJulkaiseFacebook = "julkaiseFacebook"
var arvoJulkaiseFacebook = 0 // 0 - älä, 1 - julkaise
var luettuJulkaiseFacebook = false
var tunnusJulkaiseTwitter = "julkaiseTwitter"
var arvoJulkaiseTwitter = 0 // 0 - älä, 1 - julkaise
var luettuJulkaiseTwitter = false
var tunnusJulkaiseFsqr = "julkaiseFsqr"
var arvoJulkaiseFsqr = 0 // 0 - älä, 1 - julkaise
var luettuJulkaiseFsqr = false
var tunnusKuvaaja = "kuvaaja"
var nakyvaKuvaaja = 0 // 0 - viikkokulutus, 1 - paivakulutus, oli 2 - paivaruudukko
var luettuNakyvaKuvaaja = false
var tunnusVrkVaihdos = "ryyppaysVrk"
var vrkVaihtuu = 0*60 // minuuttia puolen yön jälkeen
var luettuVrkVaihtuu = false
//var juotu // juodut-taulukko luetaan tähän

var virheet = ["havaitut virheet:"]

function lisaaSarake(taulukko, sarake) {
    var mj = "ALTER TABLE '" + taulukko + "' ADD COLUMN '" + sarake + "' " + "INTEGER"

    if(tkanta === null) return;

    try {
        tkanta.transaction(function(tx) {
            var taulukko3  = tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error tietokanta.js: " + err);
        virheet.push(err + " >> " + mj + " <<")
    }

    //console.log(mj)

    return mj
}

// poistettu , mlVeressa
function lisaaTkJuodut(xid, hetki, maara, vahvuus, juoma, kuvaus, olutId) {
    // xid - juoman tunnus, hetki - juontiaika [ms], veressa - ml alkoholia veressä hetkellä hetki,
    // maara - juoman tilavuus, vahvuus- juoman prosentit, juomanNimi - nimi, juomanKuvaus - tekstiä
    // olutId - unTappd bid

    if(tkanta === null) return;

    juoma = vaihdaHipsut(juoma)
    kuvaus = vaihdaHipsut(kuvaus)

    var komento = "INSERT INTO juodut (id, aika, tilavuus, prosenttia, juoma, kuvaus, oluenId)" +
            " VALUES (" + xid + ", " + hetki + ", " + maara + ", " +
            vahvuus + ", '" + juoma + "', '" + kuvaus + "', " + olutId + ")"

    //var vanhaKomento = "INSERT INTO juodut (id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus, oluenId)" +
    //        " VALUES (" + xid + ", " + hetki + ", " + mlVeressa + ", " + maara + ", " +
    //        vahvuus + ", '" + juoma + "', '" + kuvaus + "', " + olutId + ")"

    try {
        tkanta.transaction(function(tx){
            tx.executeSql(komento);
        });
    } catch (err) {
        console.log("Error adding to juodut-table in database: " + err);
        virheet.push(err + " >> " + komento + " <<");
        //virheet = virheet + "Error adding to juodut-table in database: " + err +" <br> "
    };

    return
}

function lueTkAsetukset() {
    var luettu = 0, vanhaVaihdosTunnus = false, mj;

    if(tkanta === null) return luettu;

    mj = "SELECT asia, arvo FROM asetukset";
    try {
        tkanta.transaction(function(tx) {
            var taulukko  = tx.executeSql(mj);

            for (var i = 0; i < taulukko.rows.length; i++ ) {
                if (taulukko.rows[i].asia === tunnusProm1 ){
                    promilleRaja1 = taulukko.rows[i].arvo;
                    luettuPromilleRaja1 = true;
                }
                else if (taulukko.rows[i].asia === tunnusProm2 ){
                    promilleRaja2 = taulukko.rows[i].arvo;
                    luettuPromilleRaja2 = true;
                }
                else if (taulukko.rows[i].asia === tunnusVrkRaja1 ) {
                    vrkRaja1 = taulukko.rows[i].arvo;
                    luettuVrkRaja1 = true;
                }
                else if (taulukko.rows[i].asia === tunnusVrkRaja2 ){
                    vrkRaja2 = taulukko.rows[i].arvo;
                    luettuVrkRaja2 = true;
                }
                else if (taulukko.rows[i].asia === tunnusVkoRaja1 ) {
                    vkoRaja1 = taulukko.rows[i].arvo;
                    luettuVkoRaja1 = true;
                }
                else if (taulukko.rows[i].asia === tunnusVkoRaja2 ) {
                    vkoRaja2 = taulukko.rows[i].arvo;
                    luettuVkoRaja2 = true;
                }
                else if (taulukko.rows[i].asia === tunnusVsRaja1 ) {
                    vsRaja1 = taulukko.rows[i].arvo;
                    luettuVsRaja1 = true;
                }
                else if (taulukko.rows[i].asia === tunnusVsRaja2 ) {
                    vsRaja2 = taulukko.rows[i].arvo;
                    luettuVsRaja2 = true;
                }
                else if (taulukko.rows[i].asia === tunnusKuvaaja ) {
                    nakyvaKuvaaja = taulukko.rows[i].arvo;
                    luettuNakyvaKuvaaja = true;
                }
                else if (taulukko.rows[i].asia === tunnusVrkVaihdos ||
                         taulukko.rows[i].asia === "ryypaysVrk") {
                    vrkVaihtuu = taulukko.rows[i].arvo;
                    luettuVrkVaihtuu = true;
                    if (taulukko.rows[i].asia === "ryypaysVrk")
                        vanhaVaihdosTunnus = true;
                }
                else if (taulukko.rows[i].asia === tunnusTilavuusMitta ) {
                    arvoTilavuusMitta = taulukko.rows[i].arvo;
                    luettuYksikko = true;
                }
                else if (taulukko.rows[i].asia === tunnusTalletaSijainti ) {
                    arvoTalletaSijainti = taulukko.rows[i].arvo;
                    luettuTalletaSijainti = true;
                }
                else if (taulukko.rows[i].asia === tunnusJulkaiseFacebook ) {
                    arvoJulkaiseFacebook = taulukko.rows[i].arvo;
                    luettuJulkaiseFacebook = true;
                }
                else if (taulukko.rows[i].asia === tunnusJulkaiseFsqr ) {
                    arvoJulkaiseFsqr = taulukko.rows[i].arvo;
                    luettuJulkaiseFsqr = true;
                }
                else if (taulukko.rows[i].asia === tunnusJulkaiseTwitter ) {
                    arvoJulkaiseTwitter = taulukko.rows[i].arvo;
                    luettuJulkaiseTwitter = true;
                }
            }

            luettu = i;
         });
    } catch (err1) {
        console.log("Error reading asetukset-table in database: " + err1);
        //virheet = virheet + "Error reading asetukset-table in database: " + err +" <br> "
        virheet.push(err1 + " >[ " + mj + " ]<");
    }

    mj = "SELECT asia, arvo FROM asetukset2";
    try {
        tkanta.transaction(function(tx) {
            var taulukko2  = tx.executeSql(mj);
            var luettu2 = 0;

            //console.log("lueAsetukset2: rivejä " + taulukko2.rows.length)
            while (luettu2 < taulukko2.rows.length) {
                //console.log("asetukset2: " + taulukko2.rows[luettu2].asia + " " + taulukko2.rows[luettu2].arvo)
                if (taulukko2.rows[luettu2].asia === tunnusUnTappdToken ){
                    arvoUnTpToken = taulukko2.rows[luettu2].arvo;
                    console.log("unTappdToken: " + arvoUnTpToken);
                    if (arvoUnTpToken === null || arvoUnTpToken === undefined)
                        arvoUnTpToken = "";
                    if (arvoUnTpToken !== "")
                        luettuUnTpToken = true;
                }

                luettu++;
                luettu2++;
            }

            //console.log("lueAsetukset2 - " + tunnusUnTappdToken + ": " + arvoUnTpToken)

        });
    } catch (err) {
        console.log("Error reading asetukset2-table in database: " + err);
        //virheet = virheet + "Error reading asetukset2-table in database: " + err +" <br> "
        virheet.push(err + " >> " + mj + " <<");
    }

    //varmistetaan, että kaikki asetukset ovat tietokannassa
    if (!luettuPromilleRaja1)
        uusiAsetus(tunnusProm1, promilleRaja1);
    if (!luettuPromilleRaja2)
        uusiAsetus(tunnusProm2, promilleRaja2);
    if (!luettuVrkRaja1)
        uusiAsetus(tunnusVrkRaja1, vrkRaja1);
    if (!luettuVrkRaja2)
        uusiAsetus(tunnusVrkRaja2, vrkRaja2);
    if (!luettuVkoRaja1)
        uusiAsetus(tunnusVkoRaja1, vkoRaja1);
    if (!luettuVkoRaja2)
        uusiAsetus(tunnusVkoRaja2, vkoRaja2);
    if (!luettuVsRaja1)
        uusiAsetus(tunnusVsRaja1, vsRaja1);
    if (!luettuVsRaja2)
        uusiAsetus(tunnusVsRaja2, vsRaja2);
    if (!luettuNakyvaKuvaaja)
        uusiAsetus(tunnusKuvaaja, nakyvaKuvaaja);
    if (!luettuVrkVaihtuu)
        uusiAsetus(tunnusVrkVaihdos, vrkVaihtuu);
    if (!luettuYksikko)
        uusiAsetus(tunnusTilavuusMitta, arvoTilavuusMitta);
    if (!luettuTalletaSijainti)
        uusiAsetus(tunnusTalletaSijainti, arvoTalletaSijainti);
    if (!luettuJulkaiseFacebook)
        uusiAsetus(tunnusJulkaiseFacebook, arvoJulkaiseFacebook);
    if (!luettuJulkaiseFsqr)
        uusiAsetus(tunnusJulkaiseFsqr, arvoJulkaiseFsqr);
    if (!luettuJulkaiseTwitter)
        uusiAsetus(tunnusJulkaiseTwitter, arvoJulkaiseTwitter);
    if (!luettuUnTpToken)
        uusiAsetus2(tunnusUnTappdToken, "");

    if (vanhaVaihdosTunnus)
        poistaAsetus("ryypaysVrk");

    return luettu;
}

function lueTkJuodut(kaikkiko, alkuAika, loppuAika) {
    var taulukko;
    var i = 0;
    var hakuteksti = "SELECT * FROM juodut";

    if (tkanta === null)
        return;

    /*
    //console.log("alku " + alkuAika + " loppu " + loppuAika + " summa " + (alkuAika+loppuAika).toFixed(0))

    if (Number.isInteger(alkuAika)) {
        console.log("lueTkJuodut: alkuaika " + alkuAika)
    }
    else
        alkuAika = 0

    if (Number.isInteger(loppuAika)) {
        console.log("lueTkJuodut: loppuaika " + loppuAika)
        if (loppuAika <= alkuAika){
            loppuAika = Date.now()
        }
    }
    else
        loppuAika = Date.now()
    // */

    if (!kaikkiko)
        hakuteksti += " WHERE aika >= " + alkuAika + " AND aika <= " + loppuAika;

    hakuteksti += " ORDER BY aika ASC";
    //console.log(hakuteksti)

    try {
        tkanta.transaction(function(tx) {
            taulukko = tx.executeSql(hakuteksti);
        });

        if (taulukko.rows.length > 0 ) {
            if (onkoSarake("juodut" ,"oluenId")){
                for (i = 0; i < taulukko.rows.length; i++){
                    //console.log("lueTkJuodut: " + taulukko.rows[i].aika + " " + taulukko.rows[i].juoma)
                    if (taulukko.rows[i].oluenId === null)
                        taulukko.rows[i].oluenId = 0;
                }
            } else {
                //for (i = 0; i < taulukko.rows.length; i++){
                //    taulukko.rows[i].oluenId = 0
                //}
            }
        }
    } catch (err) {
        console.log("lueJuodut: " + err + " //// " + hakuteksti);
        virheet.push(err + " >> " + hakuteksti + " << ");
    }

    return taulukko;
}

function lueTkJuomari() {
    var riveja = 0, massa = -1, vetta = -1, kunto = -1, keho = [], mj;

    mj = "SELECT * FROM juomari ORDER BY aika ASC";
    try {
        tkanta.transaction(function(tx) {
            var taulukko  = tx.executeSql(mj);
            riveja = taulukko.rows.length;

            if (riveja > 0) {
                //massa = taulukko.rows[riveja - 1].paino;
                //vetta = taulukko.rows[riveja - 1].neste;
                //kunto = taulukko.rows[riveja - 1].maksa;
                keho = taulukko.rows;
                console.log("riveja juomarissa " + riveja)
            };
        });
    } catch (err) {
        console.log("lueJuomari: " + err);
        virheet.push(err + " >> " + mj + " <<");
    }

    //keho[0] = massa
    //keho[1] = vetta
    //keho[2] = kunto

    return keho;
}

function luoTaulukot() {

    luoTkAsetukset();
    luoTkAsetukset2();
    luoTkJuomari();
    luoTkJuodut();
    if (!onkoSarake("juodut", "oluenId"))
        lisaaSarake("juodut", "oluenId")
    //luoTkSuosikit();

    return;
}

function luoTkAsetukset() {
    // asetukset-tietokanta
    // asia,    arvo
    // string,  numeric
    var mj;

    if(tkanta === null) return;

    mj = "CREATE TABLE IF NOT EXISTS asetukset (asia TEXT, arvo NUMERIC)";
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error creating asetukset-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    };

    return;
}

function luoTkAsetukset2() {
    // asetukset2-tietokanta
    // asia,    arvo
    // string,  string
    var mj;

    if(tkanta === null) return;

    mj = "CREATE TABLE IF NOT EXISTS asetukset2 (asia TEXT, arvo TEXT)";
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error creating asetukset2-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    };

    return;
}

function luoTkJuodut() {
    //juodut-taulukko
    // id,  aika,     tilavuus, prosenttia, juoma,                kuvaus, oluenId
    // int, int [ms], int [ml], float,      string - juoman nimi, string, int - unTappd-id
    // poistettu veressa -- float [ml] - alkoholia veressä juomahetkellä
    var mj;

    if(tkanta === null) return;

    mj = "CREATE TABLE IF NOT EXISTS juodut (id INTEGER, aika INTEGER, " +
            "tilavuus INTEGER, prosenttia REAL, juoma TEXT, kuvaus TEXT, " +
            "oluenId INTEGER)";
    try { // veressa REAL, poistettu
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error creating juodut-table in database: " + err);
        virheet.push(err + " >> " + err + " <<");
    };

    return;
}

function luoTkJuomari() {
    //juomari-taulukko
    // aika,     paino,      neste,                          maksa
    // int [ms], int [kg],   float - kehon nesteprosentti,   float - maksan tehokkuuskerroin
    var mj;

    if(tkanta === null) return;

    mj = "CREATE TABLE IF NOT EXISTS juomari (aika INTEGER, paino INTEGER, " +
            "neste REAL, maksa REAL)";
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });

    } catch (err) {
        console.log("Error creating juomari-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    };

    return;
}

function luoTkSuosikit() {
    //suosikit-taulukko
    //id  juoma (nimi)  suosio kuvaus tilavuus prosentti
    //int string        int    string int      float
    var mj;

    if(tkanta === null) return;

    mj = "CREATE TABLE IF NOT EXISTS suosikit (id INTEGER, juoma TEXT, " +
            "suosio INTEGER, kuvaus TEXT, tilavuus INTEGER, prosentti REAL, " +
            "oluenId INTEGER)"
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error creating suosikit-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    };

    return;
}

// poistettu , mlVeressa
function muutaTkJuodut(xid, hetki, maara, vahvuus, nimi, kuvaus, olutId) {
    //juomanNimi = vaihdaHipsut(juomanNimi)
    //juomanKuvaus = vaihdaHipsut(juomanKuvaus)

    var komento = "UPDATE juodut SET aika = " + hetki + //+ ", veressa = " + mlVeressa
            ", tilavuus = " + maara + ", prosenttia = " + vahvuus +", juoma = '" +
            vaihdaHipsut(nimi) + "', kuvaus = '" + vaihdaHipsut(kuvaus) +
            "', oluenId = " + olutId + "  WHERE id = " + xid
    if(tkanta === null) return;

    try {
        tkanta.transaction(function(tx){
            tx.executeSql(komento);
        });
    } catch (err) {
        console.log("Error modifying juodut-table in database: " + err);
        virheet.push(err + " >> " + komento + " <<");
    };

    return;
}

function onkoSarake(taulukko, tunnus) {
    //var mj = "SELECT sql FROM sqlite_master WHERE type = 'table' AND tbl_name = 'juodut'"
    var mj3 = "PRAGMA table_info('" + taulukko + "')"
    var onko = false

    try {
        tkanta.transaction(function(tx) {
            var taulukko3  = tx.executeSql(mj3);

            for (var i = 0; i < taulukko3.rows.length; i++ ) {
                if (taulukko3.rows[i].name === tunnus) {
                    onko = true
                }
            }

        });

    } catch (err) {
        console.log("Error tietokanta.js: " + err);
        virheet.push(err + " >> " + mj3 + " <<");
    }

    /*
    if (!onko)
        console.log("taulukossa " + taulukko + " ei ole saraketta " + tunnus)
    else
        console.log("taulukossa " + taulukko + " on sarake " + tunnus)
    // */

    return onko;
}

function paivitaAsetus(tunnus, arvo) {
    var mj;
    // tunnus string, arvo numeric
    if (arvo === true)
        arvo = 1
    else if (arvo === false)
        arvo = 0;

    if(tkanta === null) return;

    mj = "UPDATE asetukset SET arvo = " + arvo + "  WHERE asia = '" + tunnus + "'";
    //console.log("" + mj);

    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error modifying asetukset-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    };
    //console.log("kohta1 ")

    return;
}

function paivitaAsetus2(tunnus, arvo) {
    var mj = "UPDATE asetukset2 SET arvo = '" + arvo +
            "'  WHERE asia = '" + tunnus + "'"
    // tunnus string, arvo string
    if(tkanta === null) return;
    if (tunnus === tunnusUnTappdToken) {
        console.log("paivitaAsetus2: " + tunnus + ", " + arvo);
        if (arvo === null || arvo === "" || arvo === undefined)
            luettuUnTpToken = false;
        else
            luettuUnTpToken = true;
    }

    //console.log(mj)
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error modifying asetukset2-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    };

    //console.log("paivitaAsetus2: " + mj)
    return;
}

function poistaAsetus(tunnus) {
    var mj = "DELETE FROM asetukset WHERE asia = '" + tunnus + "'";
    // tunnus string, arvo string
    if(tkanta === null) return;

    console.log(mj);
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("Error when deleting from asetukset-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    };

    //console.log("paivitaAsetus2: " + mj)
    return;
}

function poistaTkJuodut(xid){
    var mj = "DELETE FROM juodut WHERE id = ?";
    if(tkanta === null) return;

    try {
        tkanta.transaction(function(tx) {
            tx.executeSql(mj, [xid]);
        });
    } catch (err) {
        console.log("poistaTkJuodut: " + err);
        virheet.push(err + " >> " + mj + " [" + xid + "] <<");
    }

    return;
}

function tyhjennaTaulukko(taulukko){
    var mj = "DELETE FROM " + taulukko;
    if(tkanta === null || taulukko == "") return;

    try {
        tkanta.transaction(function(tx) {
            tx.executeSql(mj);
        });
    } catch (err) {
        console.log("tyhjennaTaulukko: " + err);
        virheet.push(err + " >> " + mj + " <<");
    }

    return;
}

function uusiAsetus(tunnus, arvo){
    // tunnus string, arvo numeric
    var mj;
    if(tkanta === null) return;

    mj = "INSERT INTO asetukset (asia, arvo) VALUES ('" + tunnus + "', " +
            arvo + ")";
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj)
        })
    } catch (err) {
        console.log("Error adding to asetukset-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    }
    return;
}

function uusiAsetus2(tunnus, arvo){
    // tunnus string, arvo string
    var mj;
    if(tkanta === null) return;
    if (tunnus === tunnusUnTappdToken) {
        if (arvo === null || arvo === "" || arvo === undefined) {
            luettuUnTpToken = false
            arvo = ""
        } else
            luettuUnTpToken = true
    }

    //console.log("uusiAsetus2 " + tunnus + " = " + arvo)
    mj = "INSERT INTO asetukset2 (asia, arvo) VALUES ('" + tunnus + "', '" +
            arvo + "')";
    try {
        tkanta.transaction(function(tx){
            tx.executeSql(mj);
        })
    } catch (err) {
        console.log("Error adding to asetukset2-table in database: " + err);
        virheet.push(err + " >> " + mj + " <<");
    }
    return;
}

function uusiJuomari(massa, vetta, kunto, aika) {
    var komento
    komento = "INSERT INTO juomari (aika, paino, neste, maksa) VALUES (" +
            aika + ", " + massa + ", " + vetta + ", " + kunto +")";

    if(tkanta === null) return;
    //console.log("uusi ms, kg, L, %:" + aika + ", " + massa + ", " + vetta + ", " + kunto)

    try {
        tkanta.transaction(function(tx){
            tx.executeSql(komento)
        })
    } catch (err) {
        console.log("Error adding to juomari-table in database -- query " + komento + " -- error: " + err);
        virheet.push(err + " >> " + komento + " <<");
    }

    return;
}

function vaihdaHipsut(mj) {
    //tuplaa merkit ' ja "
    mj = mj.replace(/'/g,"''");
    mj = mj.replace(/"/g,'""');

    return mj;
}
