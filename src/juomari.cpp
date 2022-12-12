#include "juomari.h"
#include <QDebug>

juomari::juomari(QObject *parent) : QObject(parent)
{
    omaKeho oletusKeho;
    oletusKeho.aika = QDate(1,1,1);
    oletusKeho.maksa = oletusMaksa;
    oletusKeho.paino = oletusPaino;
    oletusKeho.vesiPros = oletusVesi;
    keho.append(oletusKeho);

    imeytymisaika = 0; // h
    vrkVaihtuu.setHMS(5,0,0,0); // 5:00-4:59 samaa päivää

    asetaPohjat(0, QDateTime(QDate(1, 1, 1)));

    raja1 = 0.5;
    tarkka = false;
    onkoOletusArvot = true;
}

juomari::mlMaarat juomari::alkoholiaMl(QDateTime nyt, int iJuoma, int iKeho) {
    // iJuoma, iKeho - hetkeä nyt edeltävät
    juotu edellinen;
    double eroTunti, mlImeytynyt, mlPalanut, mlVatsassa, mlVeressa, osuus;
    mlMaarat tulos;

    if (iJuoma < 0 || iJuoma >= juodut.length()) {
        edellinen = pohjat;
    } else {
        edellinen = juodut.at(iJuoma);
    }
    if (iKeho < 0) {
        iKeho = 0;
    }

    if (edellinen.aika.isValid()) {
        eroTunti = (double) edellinen.aika.msecsTo(nyt)/msTunti;
    } else { // ei juomia, mutta pohjat annettu
        eroTunti = 0;
    }

    mlVatsassa = edellinen.vatsassaEnnen + edellinen.ml*edellinen.pros;

    if (eroTunti < 0){
        osuus = 0.0;
    } else if (eroTunti < imeytymisaika) {
        osuus = eroTunti/imeytymisaika;
    } else {
        osuus = 1;
    }
    mlImeytynyt = osuus*mlVatsassa - edellinen.veressaEnnen;
    mlVeressa = edellinen.veressaEnnen + mlImeytynyt;

    mlPalanut = eroTunti*palonopeus(iKeho);
    if (mlPalanut > mlVeressa) {
        mlPalanut = mlVeressa;
    } else if (mlPalanut < 0) {
        mlPalanut = 0.0;
    }

    //qInfo() << iJuoma << edellinen.vatsassaEnnen << eroTunti << mlVatsassa << mlVeressa << mlImeytynyt << mlPalanut << juodut.length();
    tulos.vatsassa = mlVatsassa - mlPalanut;
    tulos.veressa = mlVeressa - mlPalanut;
    return tulos;
}

double juomari::alkoholia(QDateTime aika, bool veresta) {
    // ml alkoholia veressä hetkellä aika
    // alkoholi imeytyy vatsasta vereen siten, että veressä on korkeintaan yhtä paljon alkoholia kuin vatsassa
    // jos veresta = false, oletetaan kaiken juodun alkoholin imeytyvän heti
    int j, k;
    mlMaarat ml;
    double tulos;

    j = etsiJuomanJarjestys(aika) - 1;
    k = etsiKehonJarjestys(aika.date()) - 1;
    ml = alkoholiaMl(aika, j, k);
    if (veresta) {
        tulos = ml.veressa;
    } else {
        tulos = ml.vatsassa;
    }

    return tulos;
}

double juomari::alkoholia(qint64 aika, bool veresta) {
    return alkoholia(QDateTime::fromMSecsSinceEpoch(aika), veresta);
}

int juomari::asetaImeytymisaika(int minuuttia) {
    int onnistuiko = 0;

    if (minuuttia >= 0) {
        imeytymisaika = minuuttia/60;
    } else {
        onnistuiko = -1;
    }
    return onnistuiko;
}

int juomari::asetaKeho(int paino, double pros, double teho, QDateTime pvm) {
    omaKeho uusiKeho;
    QDate paiva = pvm.date();
    int i;

    if (!pvm.isValid() || pros <= 0 || teho <= 0 || paino < 1) {
        return -1;
    }
    onkoOletusArvot = false;

    if (pros > 1) {
        qInfo() << "pros > 100%, => pros/100";
        uusiKeho.vesiPros = pros/100;
    } else {
        uusiKeho.vesiPros = pros;
    }
    if (teho > 10) {
        qInfo() << "teho > 1000%, => teho/100";
        uusiKeho.maksa = teho/100;
    } else {
        uusiKeho.maksa = teho;
    }
    uusiKeho.paino = paino;
    uusiKeho.aika = paiva;

    i = etsiKehonJarjestys(paiva);
    if (i >= keho.count()) {
        keho.append(uusiKeho);
    } else {
        if (!keho.at(i).aika.isValid() && keho.at(i).aika == paiva) {
            keho.replace(i, uusiKeho);
        } else {
            keho.insert(i, uusiKeho);
        }
    }

    return keho.length();
}

int juomari::asetaKeho(int paino, double pros, double teho, qint64 ms1970) {
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return asetaKeho(paino, pros, teho, aika);
}

int juomari::asetaMaksa(double teho, QDateTime pvm) {
    omaKeho uusiKeho;
    QDate paiva = pvm.date();
    int i;

    if (!pvm.isValid() || teho <= 0) {
        return -1;
    }
    onkoOletusArvot = false;

    uusiKeho.maksa = teho;
    uusiKeho.aika = paiva;

    if (keho.isEmpty()) {
        uusiKeho.paino = oletusPaino;
        uusiKeho.vesiPros = oletusVesi;
        keho.append(uusiKeho);
    } else {
        i = etsiKehonJarjestys(paiva);
        if (i >= keho.count()) {
            uusiKeho.paino = keho.last().paino;
            uusiKeho.vesiPros = keho.last().vesiPros;
            keho.append(uusiKeho);
        } else {
            uusiKeho.paino = keho.at(i).paino;
            uusiKeho.vesiPros = keho.at(i).vesiPros;
            if (!keho.at(i).aika.isValid() && keho.at(i).aika == paiva) {
                keho.replace(i, uusiKeho);
            } else {
                keho.insert(i, uusiKeho);
            }
        }
    }

    return keho.length();
}

int juomari::asetaMaksa(double teho, qint64 ms1970) {
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return asetaMaksa(teho, aika);
}

int juomari::asetaPaino(double kg, QDateTime pvm){
    omaKeho uusiKeho;
    QDate paiva = pvm.date();
    int i;

    if (!pvm.isValid() || kg < 1) {
        return -1;
    }
    onkoOletusArvot = false;

    uusiKeho.paino = kg;
    uusiKeho.aika = paiva;

    if (keho.isEmpty()) {
        uusiKeho.maksa = oletusMaksa;
        uusiKeho.vesiPros = oletusVesi;
        keho.append(uusiKeho);
    } else {
        i = etsiKehonJarjestys(paiva);
        if (i >= keho.count()) {
            uusiKeho.maksa = keho.last().maksa;
            uusiKeho.vesiPros = keho.last().vesiPros;
            keho.append(uusiKeho);
        } else {
            uusiKeho.maksa = keho.at(i).maksa;
            uusiKeho.vesiPros = keho.at(i).vesiPros;
            if (!keho.at(i).aika.isValid() && keho.at(i).aika == paiva) {
                keho.replace(i, uusiKeho);
            } else {
                keho.insert(i, uusiKeho);
            }
        }
    }

    return keho.length();
}

int juomari::asetaPaino(double kg, qint64 ms1970) {
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return asetaPaino(kg, aika);
}

int juomari::asetaPohjaPromillet(double prom, QDateTime aika) {
    double ml;
    ml = promilletMlitroiksi(prom, aika);
    return asetaPohjat(ml, aika);
}

int juomari::asetaPohjaPromillet(double prom, qint64 ms1970) {
    return asetaPohjaPromillet(prom, QDateTime::fromMSecsSinceEpoch(ms1970));
}

int juomari::asetaPohjat(double mlAlkoholia, QDateTime aika) {
    int onnistuiko = 0;

    if (mlAlkoholia >= 0 && aika.isValid()) {
        pohjat.aika = aika;
        pohjat.id = 0;
        pohjat.ml = 0;
        pohjat.pros = 0;
        pohjat.vatsassaEnnen = mlAlkoholia;
        pohjat.veressaEnnen = mlAlkoholia;
        laskeUudelleen();
        milloinRajalla = milloinPromilleja(raja1, aika);
        milloinSelvana = milloinPromilleja(0, aika);
    } else {
        qInfo() << "pohjat epäonnistui" << mlAlkoholia << aika.isValid();
        onnistuiko = -1;
    }

    return onnistuiko;
}

int juomari::asetaPohjat(double mlAlkoholia, qint64 ms1970) {
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return asetaPohjat(mlAlkoholia, aika);
}

int juomari::asetaPromilleraja(double prom) {
    int tulos = -1;
    if (prom >= 0) {
        raja1 = prom;
        tulos = 0;
    }
    return tulos;
}

int juomari::asetaVesimaara(int pros, QDateTime pvm) {
    omaKeho uusiKeho;
    QDate paiva = pvm.date();
    int i;

    if (!pvm.isValid() || pros <= 0) {
        return -1;
    }

    uusiKeho.vesiPros = pros;
    uusiKeho.aika = paiva;

    if (keho.isEmpty()) {
        uusiKeho.maksa = oletusMaksa;
        uusiKeho.paino = oletusPaino;
        keho.append(uusiKeho);
    } else {
        i = etsiKehonJarjestys(paiva);
        if (i >= keho.count()) {
            uusiKeho.maksa = keho.last().maksa;
            uusiKeho.paino = keho.last().paino;
            keho.append(uusiKeho);
        } else {
            uusiKeho.maksa = keho.at(i).maksa;
            uusiKeho.paino = keho.at(i).paino;
            if (!keho.at(i).aika.isValid() && keho.at(i).aika == paiva) {
                keho.replace(i, uusiKeho);
            } else {
                keho.insert(i, uusiKeho);
            }
        }
    }

    return keho.length();
}

int juomari::asetaVesimaara(int pros, qint64 ms1970) {
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return asetaVesimaara(pros, aika);
}

int juomari::asetaVrkVaihdos(int minuutti) {
    int h, min;
    if (minuutti > -24*60 && minuutti < 24*60) {
        h = minuutti/60;
        min = minuutti - h*60;
        vrkVaihtuu.setHMS(h, min, 0, 0);
    }
    return vrkVaihtuu.hour()*60 + vrkVaihtuu.minute();
}

int juomari::etsiJuomanJarjestys(QDateTime aika){
    // juomat aikajärjestyksessä
    // palauttaa suurimman i:n, jossa aika <= juodut[i].aika
    int i = juodut.length();
    while (i > 0 && juodut.at(i-1).aika > aika ) {
        i--;
    }
    return i;
}

int juomari::etsiKehonJarjestys(QDate aika){
    // ominaisuudet aikajärjestyksessä
    // etsii ensimmäisen kohdan, jossa aika <= keho[i].aika
    int i = keho.count();
    while (i > 0 && (!keho.at(i-1).aika.isValid() || keho.at(i-1).aika >= aika) ) {
        i--;
    }
    return i;
}

int juomari::jarjestaJuomat(int i) {
    // jos i < 0, käy koko listan läpi, muuten hakee juomalle i oikean paikan
    // palauttaa juoman i uuden paikan, tai -1, jos mitään ei muutettu
    QDateTime aika;
    juotu ryyppy1, ryyppy2;
    int j;
    bool viela;

    j = -1;
    viela = true;
    if (i >= 0) {
        if (i >= juodut.count()) {
            i = juodut.count() - 1;
        }
        ryyppy1 = juodut.at(i);
        j = i;
        // taaksepäin
        while (j > 0 && viela) {
            if (juodut.at(j-1).aika.msecsTo(ryyppy1.aika) > 0) {
                viela = false;
            } else {
                j--;
            }
        }
        // eteenpäin
        if (j == i) {
            viela = true;
            while (j < juodut.count() - 1 && viela) {
                if (juodut.at(j + 1).aika.msecsTo(ryyppy1.aika) < 0) {
                    viela = false;
                } else {
                    j++;
                }
            }
        }
        if (j != i) {
            juodut.move(i, j);
        }
    } else {
        i = 0;
        while (i < juodut.count() - 1) {
            if (juodut.at(i).aika > juodut.at(i+1).aika) {
                jarjestaJuomat(i+1);
                j = i;
            }
            i++;
        }
    }

    return j;
}

int juomari::juo(int id, int ml, double prosentteja, QDateTime aika, bool paivita){
    //tallentaa juoman listaan ja päivittää ajat promillerajoille
    juotu ryyppy;
    int i;

    if (ml <= 0 || prosentteja < 0 || !aika.isValid()) {
        return -1;
    }

    i = etsiJuomanJarjestys(aika);

    ryyppy.aika = aika;
    ryyppy.id = id;
    ryyppy.ml = ml;
    ryyppy.pros = prosentteja/100;
    paljonkoPohjia(ryyppy, aika, i);

    juodut.insert(i, ryyppy);

    if (paivita) {
        paivitaRajat();
    }

    return juodut.length();
}

int juomari::juo(int id, int ml, double prosentteja, qint64 ms1970, bool paivita){
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return juo(id, ml, prosentteja, aika, paivita);
}

qint64 juomari::juodunAika(int id) {
    qint64 tulos = -1;
    if (juodut.count() > 0) {
        if (id < 0 || id >= juodut.count()) {
            id = juodut.count() - 1;
        }
        tulos = juodut.at(id).aika.toMSecsSinceEpoch();
    }

    return tulos;
}

qint64 juomari::juodunPaiva(int id) {
    qint64 tulos = -1;
    QDate nolla(1970,1,1);
    if (juodut.count() > 0) {
        if (id < 0 || id >= juodut.count()) {
            id = juodut.count() - 1;
        }
        tulos = nolla.daysTo(juodut.at(id).aika.date());
    }

    return tulos;
}

int juomari::juotuja() {
    return juodut.count();
}

juomari::omaKeho juomari::kehonOminaisuudet(int iKeho) {
    omaKeho juoja;

    if (keho.length() <= 0) {
        juoja.maksa = oletusMaksa;
        juoja.paino = oletusPaino;
        juoja.vesiPros = oletusVesi;
        juoja.aika = QDate(0,0,0);
    } else if (iKeho < 0 || iKeho >= keho.length()) {
        juoja = keho.last();
    } else {
        juoja = keho.at(iKeho);
    }

    return juoja;
}

void juomari::laskeUudelleen(int i) {
    // laskee juodut-taulukon arvot vatsassa ja veressa uudelleen alkaen juomasta i
    juotu ryyppy;
    if (i < 0) {
        i = 0;
    }
    while (i < juodut.length()) {
        ryyppy = juodut.at(i);
        paljonkoPohjia(ryyppy, ryyppy.aika, i);
        juodut.replace(i, ryyppy);
        i++;
    }
    return;
}

double juomari::lueMaksa(QDateTime pvm) {
    int i;
    double tulos;
    QDate paiva = pvm.date();

    tulos = keho.at(0).maksa;
    i = keho.count() - 1;
    while (i > 0) {
        if (keho.at(i).aika.daysTo(paiva) >= 0) {
            tulos = keho.at(i).maksa;
            i = -1;
        }
        i--;
    }
    return tulos;
}

double juomari::luePaino(QDateTime pvm) {
    int i;
    double tulos;
    QDate paiva = pvm.date();

    tulos = keho.at(0).paino;
    i = keho.count() - 1;
    while (i > 0) {
        if (keho.at(i).aika.daysTo(paiva) >= 0) {
            tulos = keho.at(i).paino;
            i = -1;
        }
        i--;
    }
    return tulos;
}

double juomari::lueVesimaara(QDateTime pvm) {
    int i;
    double tulos;
    QDate paiva = pvm.date();

    tulos = keho.at(0).vesiPros;
    i = keho.count() - 1;
    while (i > 0) {
        if (keho.at(i).aika.daysTo(paiva) >= 0) {
            tulos = keho.at(i).vesiPros;
            i = -1;
        }
        i--;
    }
    return tulos;
}

QDateTime juomari::milloinPromilleja(double prom, QDateTime aika) {
    double alkoholia, alkoholiaRajalla, vetta, tunteja;
    juotu ryyppy;
    omaKeho juoppo;
    int i;

    if (!aika.isValid()) {
        aika = QDateTime::currentDateTime();
    }

    i = etsiJuomanJarjestys(aika) - 1;
    if (i >= juodut.length()) {
        i = juodut.length() - 1;
    }
    if (i < 0) {
        ryyppy = pohjat;
    } else {
        ryyppy = juodut.at(i);
    }

    alkoholia = ryyppy.ml*ryyppy.pros + ryyppy.vatsassaEnnen;

    i = etsiKehonJarjestys(aika.date()) - 1;
    if (i >= keho.length()) {
        i = keho.length() - 1;
    } else if (i < 0) {
        i = 0;
    }
    juoppo = keho.at(i);
    vetta = juoppo.paino*juoppo.vesiPros;
    alkoholiaRajalla = vetta*prom/tiheys;

    tunteja = (alkoholia - alkoholiaRajalla)/palonopeus(i);

    return ryyppy.aika.addMSecs(tunteja*msTunti);
}

double juomari::mlPromilleiksi(double ml, QDateTime aika) {
    double promillet;
    if (aika.isValid()) {
        promillet = ml*tiheys/(luePaino(aika)*lueVesimaara(aika));
    } else {
        qInfo() << "Invalid time in mlPromilleiksi().";
        promillet = ml*tiheys/(luePaino()*lueVesimaara());
    }
    return promillet;
}

int juomari::muutaJuoma(int id, int ml, double prosentteja, QDateTime aika) {
    int i;
    juotu ryyppy;

    i = muutettavaJuoma(id);
    if (i < 0 || i >= juodut.count()) {
        return -1;
    }

    ryyppy = juodut.at(i);
    ryyppy.ml = ml;
    ryyppy.pros = prosentteja;
    ryyppy.aika = aika;
    juodut.replace(i, ryyppy);
    if ((i > 0 && juodut.at(i-1).aika > aika) ||
        (i < juodut.length() - 1 && juodut.at(i+1).aika < aika)) {
        i = jarjestaJuomat(i);
    }

    laskeUudelleen(i);

    paivitaRajat();

    return 0;
}

int juomari::muutettavaJuoma(int id) {
    int i, tulos;
    i = juodut.length();
    tulos = -1;
    while (i > 0) {
        i--;
        if (juodut.at(i).id == id) {
            tulos = i;
        }
    }
    return tulos;
}

bool juomari::onkoOletukset() {
    return onkoOletusArvot;
}

void juomari::paivitaRajat() {
    if (juodut.length() > 0) {
        milloinRajalla = milloinPromilleja(raja1, juodut.last().aika);
        milloinSelvana = milloinPromilleja(0, juodut.last().aika);
    } else {
        milloinRajalla = milloinPromilleja(raja1, pohjat.aika);
        milloinSelvana = milloinPromilleja(0, pohjat.aika);
    }
    return;
}

double juomari::paljonkoAikana(QDateTime alku, QDateTime loppu, bool paivittain){
    double tulos;
    int i, nPaivia, iPaivia;

    if (paivittain) {
        alku.setTime(vrkVaihtuu);
        loppu.setTime(vrkVaihtuu);
        loppu.setDate(loppu.addDays(1).date());
    }
    nPaivia = juodut.at(0).aika.daysTo(juodut.last().aika);
    iPaivia = juodut.at(0).aika.daysTo(alku);
    if (nPaivia == 0) {
        i = juodut.count() - 1;
    } else {
        i = juodut.count() * iPaivia / nPaivia;
    }
    if (i >= juodut.count()) {
        i = juodut.count() - 1;
    } else if (i < 0) {
        i = 0;
    }
    while (i > 0 && i < juodut.count() && juodut.at(i).aika > alku) {
        i--;
    }
    while (i < juodut.count() && juodut.at(i).aika < alku) {
        i++;
    }
    tulos = 0;
    while (i < juodut.count() && juodut.at(i).aika <= loppu) {
        tulos += juodut.at(i).ml*juodut.at(i).pros;
        i++;
    }

    return tulos;
}

double juomari::paljonkoPaivassa(QDateTime loppu, int paivia) {
    QDateTime alku;
    if (paivia == 0) {
        paivia = 1;
    }
    alku = loppu.addDays(-(paivia-1));
    return paljonkoAikana(alku, loppu);
}

double juomari::paljonkoPaivassa(qint64 loppu, int paivia) {
    return paljonkoPaivassa(QDateTime::fromMSecsSinceEpoch(loppu), paivia);
}

void juomari::paljonkoPohjia(juotu &ryyppy, QDateTime aika, int i){
    // ryyppy, aika, i - tarkasteltavan juoman tiedot
    int k;
    mlMaarat pohjalla;

    if (i < 1 || juodut.count() < 1) {
        ryyppy.vatsassaEnnen = pohjat.vatsassaEnnen;
        ryyppy.veressaEnnen = pohjat.veressaEnnen;
        return;
    }

    k = etsiKehonJarjestys(aika.date()) - 1;
    pohjalla = alkoholiaMl(aika, i-1, k);

    ryyppy.veressaEnnen = pohjalla.veressa;
    ryyppy.vatsassaEnnen = pohjalla.vatsassa;

    return;
}

double juomari::palonopeus(int i){
    omaKeho juoja;

    juoja = kehonOminaisuudet(i);

    return polttonopeus(juoja.paino, juoja.maksa);
}

double juomari::polttonopeus(double paino, double maksa) {
    double nopeus; // ml/h
    nopeus = polttonopeusVakio*maksa*paino;

    return nopeus;
}

int juomari::poistaJuoma(int id, bool tarkistaKaikki) {
    int i, tulos = juodut.length();
    i = juodut.count() - 1;
    while (i >= 0) {
        if (juodut.at(i).id == id) {
            juodut.remove(i);
            if (!tarkistaKaikki) {
                i = -2;
            }
        }
        i--;
    }
    if (i < -1) {
        tulos = -juodut.count();
    } else {
        //tulos = juodut.count();
    }

    laskeUudelleen(i);
    paivitaRajat();

    //qInfo() << tulos << juodut.length();

    return tulos;
}

double juomari::promilleja(QDateTime aika, bool veresta) {
    // painopromilleja alkoholia veressä
    // oletuksena alkoholin jakautuminen tasaisesti kehon nesteisiin (veresta = false)
    int j, k;
    juotu viimeisin;
    omaKeho juoja;
    double mlAlkoholia, tulos;

    j = etsiJuomanJarjestys(aika) - 1;
    k = etsiKehonJarjestys(aika.date()) - 1;

    if (veresta) {
        mlAlkoholia = alkoholiaMl(aika, j, k).veressa;
    } else {
        mlAlkoholia = alkoholiaMl(aika, j, k).vatsassa;
    }

    juoja = kehonOminaisuudet(k);

    tulos = mlAlkoholia*tiheys/(juoja.paino*juoja.vesiPros);
    //qInfo() << aika.time().toString() << j << k << mlAlkoholia << juoja.paino;

    return tulos;
}

double juomari::promilleja(qint64 ms1970, bool veresta) {
    return promilleja(QDateTime::fromMSecsSinceEpoch(ms1970), veresta);
}

double juomari::promilletMlitroiksi(double promillet, QDateTime aika) {
    double ml;
    if (aika.isValid()) {
        ml = promillet*luePaino(aika)*lueVesimaara(aika)/tiheys;
    } else {
        qInfo() << "Invalid time in promilletMlitroiksi().";
        ml = promillet*luePaino()*lueVesimaara()/tiheys;
    }
    return ml;
}

QDateTime juomari::rajalla() {
    if (!milloinRajalla.isValid()) {
        milloinRajalla = milloinPromilleja(raja1, juodut.last().aika);
    }
    qDebug() << "rajalla " << milloinRajalla.toLocalTime();
    return milloinRajalla;
}

QDateTime juomari::selvana() {
    if (!milloinSelvana.isValid()) {
        milloinSelvana = milloinPromilleja(0, juodut.last().aika);
    }
    qDebug() << "selvänä " << milloinSelvana.toLocalTime();
    return milloinSelvana;
}
