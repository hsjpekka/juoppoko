#include "juomari.h"

juomari::juomari(QObject *parent) : QObject(parent)
{
    omaKeho oletusKeho;
    oletusKeho.aika = QDate(0,0,0);
    oletusKeho.maksa = oletusMaksa;
    oletusKeho.paino = oletusPaino;
    oletusKeho.vesiPros = oletusVesi;
    keho.append(oletusKeho);

    imeytymisaika = 0; // h
    vrkVaihtuu.setHMS(5,0,0,0); // 5:00-4:59 samaa päivää

    juotu pohjat;
    pohjat.aika = QDateTime(QDate(-88888, 0, 0));
    pohjat.id = 0;
    pohjat.ml = 0;
    pohjat.pros = 0;
    pohjat.vatsassaEnnen = 0;
    pohjat.veressaEnnen = 0;
    raja1 = 0.5;
    tarkka = false;
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

int juomari::asetaKeho(int paino, double pros, double teho, QDate pvm) {
    omaKeho uusiKeho;
    int i;

    if (!pvm.isValid() || pros <= 0 || teho <= 0 || paino < 1) {
        return -1;
    }

    uusiKeho.vesiPros = pros;
    uusiKeho.maksa = teho;
    uusiKeho.paino = paino;
    uusiKeho.aika = pvm;

    i = etsiKehonJarjestys(pvm);
    if (i >= keho.count()) {
        keho.append(uusiKeho);
    } else {
        if (!keho.at(i).aika.isValid() && keho.at(i).aika == pvm) {
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
    return asetaKeho(paino, pros, teho, aika.date());
}

int juomari::asetaMaksa(double teho, QDate pvm) {
    omaKeho uusiKeho;
    int i;

    if (!pvm.isValid() || teho <= 0) {
        return -1;
    }

    uusiKeho.maksa = teho;
    uusiKeho.aika = pvm;

    if (keho.isEmpty()) {
        uusiKeho.paino = oletusPaino;
        uusiKeho.vesiPros = oletusVesi;
        keho.append(uusiKeho);
    } else {
        i = etsiKehonJarjestys(pvm);
        if (i >= keho.count()) {
            uusiKeho.paino = keho.last().paino;
            uusiKeho.vesiPros = keho.last().vesiPros;
            keho.append(uusiKeho);
        } else {
            uusiKeho.paino = keho.at(i).paino;
            uusiKeho.vesiPros = keho.at(i).vesiPros;
            if (!keho.at(i).aika.isValid() && keho.at(i).aika == pvm) {
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
    return asetaMaksa(teho, aika.date());
}

int juomari::asetaPaino(double kg, QDate pvm){
    omaKeho uusiKeho;
    int i;

    if (!pvm.isValid() || kg < 1) {
        return -1;
    }

    uusiKeho.paino = kg;
    uusiKeho.aika = pvm;

    if (keho.isEmpty()) {
        uusiKeho.maksa = oletusMaksa;
        uusiKeho.vesiPros = oletusVesi;
        keho.append(uusiKeho);
    } else {
        i = etsiKehonJarjestys(pvm);
        if (i >= keho.count()) {
            uusiKeho.maksa = keho.last().maksa;
            uusiKeho.vesiPros = keho.last().vesiPros;
            keho.append(uusiKeho);
        } else {
            uusiKeho.maksa = keho.at(i).maksa;
            uusiKeho.vesiPros = keho.at(i).vesiPros;
            if (!keho.at(i).aika.isValid() && keho.at(i).aika == pvm) {
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
    return asetaPaino(kg, aika.date());
}

int juomari::asetaPohjat(double po, QDateTime aika) {
    int onnistuiko = 0;
    juotu ryyppy;

    if (po >= 0 && aika.isValid()) {
        ryyppy.aika = aika;
        ryyppy.id = 0;
        ryyppy.ml = 0;
        ryyppy.pros = 0;
        ryyppy.vatsassaEnnen = po;
        ryyppy.veressaEnnen = po;
        if (juodut.count() > 0 && juodut.at(0).id == 0) {
            juodut.replace(0, ryyppy);
            laskeUudelleen();
            milloinRajalla = milloinPromilleja(raja1, aika);
            milloinSelvana = milloinPromilleja(0, aika);
        } else {
            juodut.insert(0, ryyppy);
        }
    } else {
        onnistuiko = -1;
    }

    return onnistuiko;
}

int juomari::asetaPohjat(double po, qint64 ms1970) {
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return asetaPohjat(po, aika);
}

int juomari::asetaVesimaara(int pros, QDate pvm) {
    omaKeho uusiKeho;
    int i;

    if (!pvm.isValid() || pros <= 0) {
        return -1;
    }

    uusiKeho.vesiPros = pros;
    uusiKeho.aika = pvm;

    if (keho.isEmpty()) {
        uusiKeho.maksa = oletusMaksa;
        uusiKeho.paino = oletusPaino;
        keho.append(uusiKeho);
    } else {
        i = etsiKehonJarjestys(pvm);
        if (i >= keho.count()) {
            uusiKeho.maksa = keho.last().maksa;
            uusiKeho.paino = keho.last().paino;
            keho.append(uusiKeho);
        } else {
            uusiKeho.maksa = keho.at(i).maksa;
            uusiKeho.paino = keho.at(i).paino;
            if (!keho.at(i).aika.isValid() && keho.at(i).aika == pvm) {
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
    return asetaVesimaara(pros, aika.date());
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

int juomari::etsiKehonJarjestys(QDate aika){
    // ominaisuudet aikajärjestyksessä
    // etsii ensimmäisen kohdan, jossa aika <= keho[i].aika
    int i = keho.count();
    while (i > 0 && (!keho.at(i-1).aika.isValid() || keho.at(i-1).aika >= aika) ) {
        i--;
    }
    return i;
}

int juomari::etsiJuomanJarjestys(QDateTime aika){
    // juomat aikajärjestyksessä
    // etsii ensimmäisen kohdan, jossa aika <= juodut[i].aika
    // jos juodut[i-1].aika == aika, palauttaa i
    int i = juodut.count();
    while (i > 0 && juodut.at(i-1).aika > aika ) {
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

int juomari::juo(int id, int ml, double prosentteja, QDateTime aika, bool paivitaRajat){
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

    if (paivitaRajat) {
        milloinRajalla = milloinPromilleja(raja1, aika);
        milloinSelvana = milloinPromilleja(0, aika);
    }

    return juodut.count();
}

int juomari::juo(int id, int ml, double prosentteja, qint64 ms1970, bool paivitaRajat){
    QDateTime aika;
    aika.setMSecsSinceEpoch(ms1970);
    return juo(id, ml, prosentteja, aika, paivitaRajat);
}

juomari::omaKeho juomari::kehonOminaisuudet(int iKeho) {
    omaKeho juoja;

    if (iKeho >= 0 && iKeho < keho.count()) {
        juoja = keho.at(iKeho);
    } else if (iKeho < 0 && keho.count() > 0) {
        juoja = keho.last();
    } else {
        juoja.maksa = oletusMaksa;
        juoja.paino = oletusPaino;
        juoja.vesiPros = oletusVesi;
        juoja.aika = QDate(0,0,0);
    }

    return juoja;
}

void juomari::laskeUudelleen(int i) {
    // laskee juodut-taulukon arvot vatsassa ja veressa uudelleen alkaen juomasta i
    juotu ryyppy;
    if (i < 1) {
        i = 1;
    }
    while (i < juodut.count()) {
        ryyppy = juodut.at(i);
        paljonkoPohjia(ryyppy, ryyppy.aika, i);
        juodut.replace(i, ryyppy);
        i++;
    }
    return;
}

double juomari::lueMaksa(QDate pvm) {
    int i;
    double tulos;
    tulos = keho.at(0).maksa;
    i = keho.count() - 1;
    while (i > 0) {
        if (keho.at(i).aika.daysTo(pvm) >= 0) {
            tulos = keho.at(i).maksa;
            i = -1;
        }
        i--;
    }
    return tulos;
}

double juomari::luePaino(QDate pvm) {
    int i;
    double tulos;
    tulos = keho.at(0).paino;
    i = keho.count() - 1;
    while (i > 0) {
        if (keho.at(i).aika.daysTo(pvm) >= 0) {
            tulos = keho.at(i).paino;
            i = -1;
        }
        i--;
    }
    return tulos;
}

double juomari::lueVesimaara(QDate pvm) {
    int i;
    double tulos;
    tulos = keho.at(0).vesiPros;
    i = keho.count() - 1;
    while (i > 0) {
        if (keho.at(i).aika.daysTo(pvm) >= 0) {
            tulos = keho.at(i).vesiPros;
            i = -1;
        }
        i--;
    }
    return tulos;
}

QDateTime juomari::milloinPromilleja(double promilleja, QDateTime aika) {
    double alkoholia, alkoholiaRajalla, nopeus, vetta, tunteja;
    juotu ryyppy;
    omaKeho juoppo;

    ryyppy = juodut.last();
    alkoholia = ryyppy.ml*ryyppy.pros + ryyppy.vatsassaEnnen;
    juoppo = keho.last();
    vetta = juoppo.paino*juoppo.vesiPros;
    alkoholiaRajalla = vetta*promilleja/tiheys;
    nopeus = palonopeus();
    tunteja = (alkoholia - alkoholiaRajalla)/nopeus;

    return aika.addMSecs(tunteja*msTunti);
}

int juomari::muutaJuoma(int id, int ml, double prosentteja, QDateTime aika, bool paivitaRajat) {
    int i;
    juotu ryyppy;
    i = muutettavaJuoma(id);
    if (i < 0 || i >= juodut.count()) {
        return -1;
    }

    ryyppy = juodut.at(i);
    ryyppy.ml = ml;
    ryyppy.pros = prosentteja;
    if (ryyppy.aika.msecsTo(aika) != 0) {
        ryyppy.aika = aika;
        juodut.replace(i, ryyppy);
        if (etsiJuomanJarjestys(aika) != i + 1) {
            jarjestaJuomat(i);
        }
    } else {
        juodut.replace(i, ryyppy);
    }

    if (paivitaRajat) {
        milloinRajalla = milloinPromilleja(raja1, aika);
        milloinSelvana = milloinPromilleja(0, aika);
    }

    return 0;
}

double juomari::paljonkoAikana(QDate pvmAlku, QDate pvmLoppu){
    QDateTime alku, loppu;
    double tulos;
    int i, nPaivia, iPaivia;

    alku = QDateTime(pvmAlku, vrkVaihtuu);
    loppu = QDateTime(pvmLoppu, vrkVaihtuu).addDays(1);
    nPaivia = juodut.at(0).aika.daysTo(juodut.last().aika);
    iPaivia = juodut.at(0).aika.daysTo(alku);
    i = juodut.count() * iPaivia / nPaivia;
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
    while (i < juodut.count() && juodut.at(i).aika < loppu) {
        tulos += juodut.at(i).ml*juodut.at(i).pros;
        i++;
    }

    return tulos;
}

void juomari::paljonkoPohjia(juotu &ryyppy, QDateTime aika, int i){
    // ryyppy, aika, i - tarkasteltavan juoman tiedot
    juotu edellinen;
    double imeytynyt, palanut, vatsassa, veressa; // ml alkoholia
    double eroTunti, osuus;
    int j;

    if (i < 1 || i > juodut.count()) {
        ryyppy.vatsassaEnnen = 0;
        ryyppy.veressaEnnen = 0;
        return;
    }

    edellinen = juodut.at(i-1);
    if (edellinen.aika.isValid()) {
        eroTunti = edellinen.aika.msecsTo(aika)/msTunti;
    } else {
        eroTunti = imeytymisaika*60 + 1;
    }
    vatsassa = edellinen.vatsassaEnnen + edellinen.ml*edellinen.pros;

    if (eroTunti < 0){
        osuus = 0.0;
    } else if (eroTunti < imeytymisaika) {
        osuus = eroTunti/imeytymisaika;
    } else {
        osuus = 1;
    }
    imeytynyt = osuus*vatsassa;
    veressa = edellinen.veressaEnnen + imeytynyt;

    if (tarkka) {
        j = etsiKehonJarjestys(aika.date());
    } else {
        j = keho.count() - 1;
    }
    palanut = eroTunti*palonopeus(j);
    if (palanut > veressa) {
        palanut = veressa;
    } else if (palanut < 0) {
        palanut = 0.0;
    }

    ryyppy.veressaEnnen = veressa - palanut;
    ryyppy.vatsassaEnnen = vatsassa - palanut;

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
    int i, tulos;
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
        tulos = juodut.count();
    } else {
        tulos = -juodut.count();
    }
    return tulos;
}

double juomari::promilleja(QDateTime aika) {
    return promilleja(false, aika);
}

double juomari::promilleja(bool veresta, QDateTime aika) {
    // painopromilleja alkoholia veressä
    // oletuksena alkoholin jakautuminen tasaisesti kehon nesteisiin
    int i, j;
    juotu viimeisin;
    omaKeho juoja;
    double mlAlkoholia, nopeus, tulos;
    bool tallenne;

    tallenne = tarkka;

    i = etsiJuomanJarjestys(aika);
    tarkka = true;
    paljonkoPohjia(viimeisin, aika, i);
    j = etsiKehonJarjestys(aika.date());
    juoja = kehonOminaisuudet(j);
    nopeus = palonopeus(j);
    tarkka = tallenne;

    if (veresta) {
        mlAlkoholia = viimeisin.veressaEnnen;
    } else {
        mlAlkoholia = viimeisin.vatsassaEnnen;
    }
    tulos = mlAlkoholia*tiheys/(juoja.paino*juoja.vesiPros);

    return tulos;
}
