.pragma library
/*
var juotu = []  //tkid: id, ms: aika, mlVeri: veressa, nimi: juoma, maara: tilavuus,
                //pros: prosenttia, teksti: kuvaus, juomaId: olutId

function asetaJuomanArvot(j, tkid, aika, veressa, juoma, tilavuus, vahvuus, kuvaus, juomaId){
    var mj = "j " + j
    var i = 0
    i += asetaJuotuTkId(j, tkid)
    mj += ", tkid " + i
    i += asetaJuotuAika(j, aika)
    mj += ", aika " + i
    i += asetaMlVeressa(j, veressa)
    mj += ", veressa " + i
    i += asetaJuotuJuoma(j, juoma)
    mj += ", juoma " + i
    i += asetaJuotuTilavuus(j, tilavuus)
    mj += ", tilavuus " + i
    i += asetaJuotuVahvuus(j, vahvuus)
    mj += ", vahvuus " + i
    i += asetaJuotuKuvaus(j, kuvaus)
    mj += ", kuvaus " + i
    i += asetaJuotuId(j, juomaId)
    mj += ", bid " + i

    //console.log(mj)

    return i
}

function asetaJuotuAika(i, arvo){
    if ((i >= 0) && (i < juotu.length)){
        juotu[i].ms = arvo
        return 1
    }
    else
        return -1
}

function asetaJuotuId(i, arvo){
    if ((i >= 0) && (i < juotu.length)) {
        juotu[i].juomaId = arvo
        return 1
    }
    else
        return -1
}

function asetaJuotuJuoma(i, arvo){
    if ((i >= 0) && (i < juotu.length)){
        juotu[i].nimi = arvo
        return 1
    }
    else
        return -1
}

function asetaJuotuKuvaus(i, arvo){
    if ((i >= 0) && (i < juotu.length)) {
        juotu[i].teksti = arvo
        return 1
    }
    else
        return -1
}

function asetaJuotuTilavuus(i, arvo){
    if ((i >= 0) && (i < juotu.length)){
        juotu[i].maara = arvo
        return 1
    }
    else
        return -1
}

function asetaJuotuTkId(i, arvo){
    if ((i >= 0) && (i < juotu.length)){
        juotu[i].tkid = arvo
        return 1
    }
    else
        return -1
}

function asetaJuotuVahvuus(i, arvo){
    if ((i >= 0) && (i < juotu.length)) {
        juotu[i].pros = arvo
        return 1
    }
    else
        return -1
}

function asetaMlVeressa(i, arvo){
    if ((i >= 0) && (i < juotu.length)) {
        juotu[i].mlVeri = arvo
        return 1
    }
    else
        return -1
}

function etsiPaikka(hetki) {
    // palauttaa hetkeä hetki seuraavan juoman kohdan juomalistassa
    // jos hetkeä hetki ennen tai samaan aikaan juotu juoma on 5., palauttaa funktio arvon 5, eli kuudes juoma
    // 0 tyhjällä listalla ja jos hetki on aikaisempi kuin ensimmäisen listassa olevan
    // juomat.count, jos hetki on myöhempi tai yhtäsuuri kuin muiden juomien
    // ind0 = aloituskohta
    var ind0 = juotu.length -1

    if (ind0 < 0)
        return 0

    //if (ind0 > 0) { // jos juomalista ei ole tyhjä

    while (hetki < juomanAika(ind0)) {
        ind0--
        if (ind0 < 0)
            return 0
    }

    return ind0 + 1
}

function juomanAika(i){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].ms
    else
        return -1
}

function juomanId(i){
    // unTappd bid
    var id = 0
    if ((i >= 0) && (i < juotu.length))
        id = juotu[i].juomaId
    //console.log("juoman id " + id)
    if (id === null)
        id = 0
    return id
}

function juomanKuvaus(i){
    var mj = ""
    if ((i >= 0) && (i < juotu.length))
        mj = juotu[i].teksti
    return mj
}

function juomanNimi(i){
    var mj = ""
    if ((i >= 0) && (i < juotu.length))
        mj = juotu[i].nimi
    //console.log("aika " + ms + " " + juoma)
    return mj
}

function juomanTilavuus(i){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].maara
    else
        return -1
}

function juomanTkId(i){
    // talletetun tiedoston juodut-taulukon juoman tunnus
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].tkid
    else
        return -1
}

function juomanVahvuus(i){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].pros
    else
        return -1
}

function juomienMaara(){
    return juotu.length
}

function lisaaJuotuihin(id, aika, veressa, tilavuus, pros, juoma, kuvaus, olutId){
    //id INTEGER, aika INTEGER, veressa REAL,
    //tilavuus INTEGER, prosenttia REAL, juoma TEXT, kuvaus TEXT, oluenId INTEGER
    if (juotu.length === 0 || aika >= juomanAika(juotu.length-1))
        lisaaJuotujenLoppuun(id, aika, veressa, tilavuus, pros, juoma, kuvaus, olutId)
    else
        lisaaValiin(id, aika, veressa, tilavuus, pros, juoma, kuvaus, olutId)

    //var i = juotu.length - 1
    //console.log("lisaaJuotuihin " + juomanNimi(i) + " " + juomanAika(i) + " " + juomanVahvuus(i).toFixed(2))
    return juotu.length
}

function lisaaJuotujenLoppuun(id, aika, veressa, tilavuus, pros, juoma, kuvaus, olutId){
    return juotu.push({"tkid": id, "ms": aika, "mlVeri": veressa, "nimi": juoma,
                          "maara": tilavuus, "pros": pros, "teksti": kuvaus,
                          "juomaId": olutId})
}

function lisaaValiin(id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus, olutId) {

    var i = 0, j
    //lisaaJuotujenLoppuun(id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus, olutId)

    while ((aika >= juomanAika(i)) && (i < juotu.length )){
        i++
    }

    return juotu.splice(i, 0 , {"tkid": id, "ms": aika, "mlVeri": veressa, "nimi": juoma,
                            "maara": tilavuus, "pros": prosenttia, "teksti": kuvaus,
                            "juomaId": olutId})
}

function mlVeressa(i){
    var ml = 0
    if ((i >= 0) && (i < juotu.length))
        ml = juotu[i].mlVeri
    //console.log("mlVeressa " + ml)
    return ml
}

function monesko(juomaId){
    var i = juotu.length - 1
    while (i>=0){
        if (juotu[i].tkid === juomaId){
            return i
        }

        i--
    }
    //console.log("lista id " + i + ", tkid " + juomaId + ", vikan tkid " + juotu[juotu.length -1].tkid)
    return -1
}

function poistaJuoma(juomaId) {
    var i = monesko(juomaId), j

    if (i>=0) {
        j = i
        while (j< juotu.length -1){
            asetaJuomanArvot(j, juomanTkId(i+1), juomanAika(j+1), mlVeressa(j+1),
                             juomanNimi(j+1), juomanTilavuus(j+1), juomanVahvuus(j+1),
                             juomanKuvaus(j+1), juomanId(j+1))
            j++
        }
        juotu.pop()
    }

    return i
}
// */

function paivaEro(aika1, aika2) {
    var pvm1 = new Date(aika1), pvm2 = new Date(aika2);
    var vyohykeEro, msVrk, tulos, msPv1, msPv2;
    msVrk = 24*60*60*1000;
    vyohykeEro = pvm2.getTimezoneOffset() - pvm1.getTimezoneOffset();
    tulos = Math.floor((aika2 - aika1 + vyohykeEro*60*1000)/msVrk);
    msPv1 = ((pvm1.getHours()*60 + pvm1.getMinutes())*60 + pvm1.getSeconds())*1000 + pvm1.getMilliseconds();
    msPv2 = ((pvm2.getHours()*60 + pvm2.getMinutes() + vyohykeEro)*60 + pvm2.getSeconds())*1000 + pvm1.getMilliseconds();
    if (msPv2 < msPv1) {
        tulos += 1;
    }

    return tulos;
}

function vyohyke(aika) {
    var m0, m1
    var tunnus

    m0 = aika.indexOf("(");
    if (m0 >=0) {
        m1 = aika.indexOf(")")
    } else {
        m0 = aika.lastIndexOf(" ")
        m1 = aika.length
    }

    tunnus = (m0 > 0) ? aika.slice(m0+1,m1) : "GMT";

    return tunnus
}
