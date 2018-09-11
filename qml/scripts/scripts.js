.pragma library

var juotu = []  //tkid: id, ms: aika, mlVeri: veressa, nimi: juoma, maara: tilavuus,
                //pros: prosenttia, teksti: kuvaus, juomaId: olutId

function asetaJuomanArvot(j, aika, veressa, juoma, tilavuus, vahvuus, kuvaus, juomaId){
    var mj = "j " + j
    mj += ", aika " + asetaJuotuAika(j, aika)
    mj += ", veressa " + asetaMlVeressa(j, veressa)
    mj += ", juoma " + asetaJuotuJuoma(j, juoma)
    mj += ", tilavuus " + asetaJuotuTilavuus(j, tilavuus)
    mj += ", vahvuus " + asetaJuotuVahvuus(j, vahvuus)
    mj += ", kuvaus " + asetaJuotuKuvaus(j, kuvaus)
    mj += ", bid " + asetaJuotuId(j, juomaId)

    //console.log(mj)

    return
}

function asetaJuotuAika(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].ms = arvo
    else
        return -1
}

function asetaJuotuId(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].juomaId = arvo
    else
        return -1
}

function asetaJuotuJuoma(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].nimi = arvo
    else
        return -1
}

function asetaJuotuKuvaus(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].teksti = arvo
    else
        return -1
}

function asetaJuotuTilavuus(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].maara = arvo
    else
        return -1
}

function asetaJuotuTkId(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].tkid = arvo
    else
        return -1
}

function asetaJuotuVahvuus(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].pros = arvo
    else
        return -1
}

function asetaMlVeressa(i, arvo){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].mlVeri = arvo
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

    /*
    while (hetki >= edAika) {
        ind0 = ind0 + 1
        if (ind0 < juotu.length) {
            edAika = juomanAika(ind0)
        } else {
            edAika = hetki + 1
        }
    } // */

    return ind0 + 1
}

function juomanAika(i){
    if ((i >= 0) && (i < juotu.length))
        return juotu[i].ms
    else
        return -1
}

function juomanId(i){
    var id = 0
    if ((i >= 0) && (i < juotu.length))
        id = juotu[i].juomaId
    //console.log("aika " + ms + " " + id)
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
    return juotu.push({tkid: id, ms: aika, mlVeri: veressa, nimi: juoma,
                          maara: tilavuus, pros: pros, teksti: kuvaus,
                          juomaId: olutId})
}

function lisaaValiin(id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus, olutId) {
    var i = 0, j
    lisaaJuotujenLoppuun(id, aika, veressa, tilavuus, prosenttia, juoma, kuvaus, olutId)

    while ((aika <= juomanAika(i)) && (i < juotu.length )){
        i++
    }

    j = juotu.length - 1
    while (j > i ){
        asetaJuomanArvot(j, juomanAika(j-1), mlVeressa(j-1),
                         juomanNimi(j-1), juomanTilavuus(j-1), juomanVahvuus(j-1),
                         juomanKuvaus(j-1), juomanId(j-1))
        j--
    }

    return juotu.length
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
    console.log("lista id " + i + ", tkid " + juomaId + ", vikan tkid " + juotu[juotu.length -1].tkid)
    return -1
}
// */

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
