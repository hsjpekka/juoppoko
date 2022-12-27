import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/scripts.js" as Apuja

Item {
    id: pohja
    width: parent.width
    height: Theme.itemSizeLarge

    property bool   kesken: false
    property alias  nykyinen: pylvaikko.currentIndex
    property alias  pylvasKuvaaja: pylvaikko
    property string riskiAlhainen: "green"
    property string riskiKohonnut: "yellow"
    property string riskiKorkea: "red"
    property int    riskiPvAlempi: 150 // alhaisen kulutuksen yläraja
    property int    riskiPvYlempi: 450 // alhaisen kulutuksen yläraja
    property int    riskiVkoAlempi: 150 // alhaisen kulutuksen yläraja
    property int    riskiVkoYlempi: 450 // alhaisen kulutuksen yläraja
    property int    skaalaPv: (1.6*riskiPvYlempi).toFixed(0) // millä arvolla pylvään korkeus on sama kuin kuvaajan
    property int    skaalaVko: (1.3*riskiVkoYlempi).toFixed(0) // millä arvolla pylvään korkeus on sama kuin kuvaajan
    property int    tyyppi: 0 // 0 - viikkokulutus, 1 - päiväkulutus
    property int    vrkVaihtuu: 0 // minuutteina, arvo vähennetään juoman ajasta - lasketaanko 01:12 juotu juoma edelliselle päivälle?

    readonly property int msVrk: 24*60*60*1000
    readonly property int viikonEkaPaiva: Qt.locale().firstDayOfWeek // 0 - sunnuntai, 1 - maanantai, ...

    signal pylvasValittu(int pylvasNro, real valitunArvo, string valitusNimike)
    signal pitkaPainanta(int pylvasNro, real valitunArvo, string valitusNimike)
    signal alussa()

    ListModel {
        id: vkoKulutus
        property int viimeisin: -1
        //{"vuosi", "vkoNro", "barValue", "barColor", "barLabel", "sect"}
    }

    ListModel {
        id: pvKulutus
        property int viimeisin: -1
        //{"vuosi", "vkoNro", "paiva", "barValue", "barColor", "barLabel", "sect"}
    }

    BarChart {
        id: pylvaikko
        anchors.fill: parent
        orientation: ListView.Horizontal
        model: (tyyppi === 0) ? vkoKulutus : pvKulutus
        scale: tyyppi === 0 ? height/skaalaVko : height/skaalaPv
        onBarSelected: { //(int barNr, real barValue, string barLabel)
            pylvasValittu(barNr, barValue, barLabel)
        }
        onBarPressAndHold: {
            pitkaPainanta(barNr, barValue, barLabel)
        }
        onMovementEnded: {
            if (atXBeginning)
                alussa()
        }
    }

    BusyIndicator {
        size: BusyIndicatorSize.Medium
        anchors.centerIn: parent
        running: kesken
    }

    function aikaVertailu(vuosi, viikko, paiva) {
        if (paiva === undefined)
            paiva = 0;
        if (viikko === undefined)
            viikko = 0;
        if (vuosi === undefined)
            vuosi = 0;
        return vuosi*1000 + viikko*10 + paiva;
    }

    function aikaVertailuPv(i) {
        var vertailuAika;
        if (i < 0 || i > pvKulutus.count -1 ) {
            vertailuAika = -1;
        } else {
            vertailuAika = aikaVertailu(pvKulutus.get(i).vuosi, pvKulutus.get(i).vkoNro,
                                        pvKulutus.get(i).paiva);
        }

        return vertailuAika;
    }

    function aikaVertailuVko(i) {
        var vertailuAika;
        if (i < 0 || i > vkoKulutus.count -1 ) {
            vertailuAika = -1;
        } else {
            vertailuAika = aikaVertailu(vkoKulutus.get(i).vuosi, vkoKulutus.get(i).vkoNro);
        }

        return vertailuAika;
    }

    function alusta(alkuMs, loppuMs) { // paivia hetkestä 1970.1.1
        if (alkuMs === undefined) {
            return;
        }
        lisaa(alkuMs, 0);

        if (loppuMs === undefined) {
            loppuMs = new Date().getTime();
        }
        lisaa(loppuMs, 0);

        return;
    }

    function etsiPaiva(vuosi, viikko, paiva) {
        var aika = aikaVertailu(vuosi, viikko, paiva), i = pvKulutus.viimeisin, nro = -1;
        if (i < 0)
            i = pvKulutus.count-1;
        while (i < pvKulutus.count-1 && aikaVertailuPv(i) < aika)
            i++;

        while (i >= 0) {
            if (aikaVertailuPv(i) === aika) {
                nro = i;
                pvKulutus.viimeisin = nro;
                i = -1;
            }
            i--;
        }

        return nro;
    }

    function etsiViikko(vuosi, viikko) {
        // palauttaa ko. viikon järjestysnumeron vkoKulutus-taulukossa
        // palauttaa arvon -1, jos viikkoa ei löydy
        var aika = aikaVertailu(vuosi, viikko), i = vkoKulutus.viimeisin, nro = -1;
        if (i < 0)
            i = vkoKulutus.count-1;
        while (i < vkoKulutus.count-1 && aikaVertailuVko(i) < aika)
            i++;
        while (i >= 0) {
            if (aikaVertailuVko(i) === aika) {
                nro = i;
                vkoKulutus.viimeisin = nro;
                i = -1;
            }
            i--;
        }

        return nro;
    }

    function juotuPaivalla(vuosi, viikko, paiva) {
        var i = etsiPaiva(vuosi, viikko, paiva), ml = 0;

        if (i >=0 && i < pvKulutus.count) {
            ml = pvKulutus.get(i).barValue;
        }

        return ml;
    }

    function juotuViikolla(vuosi, viikko) {
        var i = etsiViikko(vuosi, viikko), ml = 0;

        if (i >=0 && i < vkoKulutus.count) {
            ml = vkoKulutus.get(i).barValue;
        }

        return ml;
    }

    function lisaa(aikaMs, alkoholiaMl) {
        var ml0, msJuoma, nyt, paiva, vuosi, viikko, ajat;

        msJuoma = aikaMs - vrkVaihtuu*60*1000;

        ajat = maaritaAjat(msJuoma);
        vuosi = ajat[0]; // vuosi = nyt.getFullYear() tai +/- 1 viikolla 1/53
        viikko = ajat[1]; // viikonNumero(msJuoma)
        paiva = ajat[2]; // date.getDay() = 0 (su/ma) - 6 (la/su)

        lisaaTyhjiaPaivia(vuosi, viikko, paiva);

        // viikkokuvaajan päivitys
        ml0 = juotuViikolla(vuosi, viikko);
        talletaViikonArvo(vuosi, viikko, ml0 + alkoholiaMl);

        // paivakuvaajan päivitys
        ml0 = juotuPaivalla(vuosi, viikko, paiva);
        talletaPaivanArvo(vuosi, viikko, paiva, ml0 + alkoholiaMl);

        return;
    }

    function lisaaTyhjiaPaivia(vuosi, viikko, paiva) {
        // vuosi, viikko ja päivä ovat uuden juoman ajankohta
        // lisätään peräkkäisten kirjausten väliin jäävät päivät kuvaajiin
        var iPv, iVko, iVs, nVko, tvanha, tuusi;
        if (pvKulutus.count === 0) // ensimmäinen juoma
            return;

        iPv = pvKulutus.get(pvKulutus.count-1).paiva;
        iVko = pvKulutus.get(pvKulutus.count-1).vkoNro;
        iVs = pvKulutus.get(pvKulutus.count-1).vuosi;

        tvanha = iVs*1000 + iVko*10 + iPv;
        tuusi = vuosi*1000 + viikko*10 + paiva;

        // lisättävä päivä on myöhempi kuin aiemmin talletetut
        if (tuusi > tvanha) {
            iPv++;
            while (iVs < vuosi) {
                nVko = viikonNumero(new Date(iVs,11,31,12,4,53,990).getTime());
                if (nVko === 1) // jos vuoden viimeinen viikko jää kovin vajaaksi
                    nVko = 52;
                while (iVko <= nVko) {
                    if (iPv === 1)
                        lisaaVkoArvo(iVs, iVko, 0, riskiAlhainen);
                    while (iPv <= 6) {
                        lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen);
                        iPv++;
                    }
                    iPv = 0;
                    iVko++;
                }
                iPv = 0;
                iVko = 1;
                iVs++;
            }

            while (iVko < viikko) {
                if (iPv === 0)
                    lisaaVkoArvo(iVs, iVko, 0, riskiAlhainen);
                while (iPv <= 6) {
                    lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen);
                    iPv++;
                }
                iPv = 0;
                iVko++;
            }

            while (iPv < paiva) {
                lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen);
                iPv++;
            }

        } else if (tuusi < tvanha) { // lisättävä päivä on aiempi kuin aiemmin talletetut
            iVs = pvKulutus.get(0).vuosi;
            iVko = pvKulutus.get(0).vkoNro;
            iPv = pvKulutus.get(0).paiva-1;
            tvanha = iVs*1000 + iVko*10 + iPv;
            if (tuusi > tvanha)
                return;
            while (vuosi < iVs) {
                while (iVko > 0) {
                    if (iPv === 6)
                        lisaaVkoArvo(iVs, iVko, 0, riskiAlhainen);
                    while (iPv >= 0) {
                        lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen);
                        iPv--;
                    }
                    iPv = 6;
                    iVko--;
                }
                iVs--;
                iVko = viikonNumero(new Date(iVs,11,31,22,54,53,990).getTime());
                iPv = 6;
            }
            while (viikko < iVko) {
                if (iPv === 6)
                    lisaaVkoArvo(iVs, iVko, 0, riskiAlhainen);
                while (iPv >= 0) {
                    lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen);
                    iPv--;
                }
                iPv = 6;
                iVko--;
            }
            while (paiva < iPv) {
                lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen);
                iPv--;
            }
        }

        return;
    }

    function lisaaPvArvo(vuosi, viikko, paiva, maara, vari) {
        var t1 = vuosi*1000 + viikko*10 + paiva, t2, vika;
        var pvMj = vkPaivaMj(paiva);
        if (pvKulutus.count > 0) {
            vika = pvKulutus.get(pvKulutus.count-1);
            t2 = vika.vuosi*1000 + vika.vkoNro*10 + vika.paiva;
        }
        if (t1 > t2) {
            return pvKulutus.append({ "vuosi": vuosi, "vkoNro": viikko, "paiva": paiva,
                                        "barValue": maara, "barLabel": pvMj, "barColor": vari,
                                        "sect": vuosi + "-" + viikko });
        } else {
            return pvKulutus.insert(0, { "vuosi": vuosi, "vkoNro": viikko, "paiva": paiva,
                                        "barValue": maara, "barLabel": pvMj, "barColor": vari,
                                        "sect": vuosi + "-" + viikko });
        }
    }

    function lisaaVkoArvo(vuosi, viikko, maara, vari) {
        var t1 = vuosi*100 + viikko, t2 = 0;
        if (vkoKulutus.count > 0)
            t2 = vkoKulutus.get(vkoKulutus.count-1).vuosi*100 +
                    vkoKulutus.get(vkoKulutus.count-1).vkoNro;
        if (t1 > t2) {
            return vkoKulutus.append({ "vuosi": vuosi, "vkoNro": viikko, "barValue": maara,
                              "barLabel": viikko, "barColor": vari, "sect": vuosi });
        } else {
            return vkoKulutus.insert(0, { "vuosi": vuosi, "vkoNro": viikko, "barValue": maara,
                              "barLabel": viikko, "barColor": vari, "sect": vuosi });
        }
    }

    // return [vuosi, viikko, paiva]
    function maaritaAjat(ms){
        var pvm = new Date(ms), ajat = [];
        var vuosi, vuosi0 = pvm.getFullYear(), vk = viikonNumero(ms), pv = viikonPaiva(ms);

        vuosi = vuosi0;
        if (vk === 1 && pvm.getMonth() === 11) { // menevätkö vuoden viimeiset päivät seuraavan vuoden ensimmäiselle viikolle
            vuosi = vuosi0 + 1;
        } else if (vk > 51.5 && pvm.getMonth() === 0) { // entä ensimmäiset päivät edellisen vuoden viimeiselle viikolle
            vuosi = vuosi0 - 1;
        }

        ajat[0] = vuosi;
        ajat[1] = vk;
        ajat[2] = pv;

        return ajat;
    }

    function muutaPvArvo(i, arvo, vari) {
        return pvKulutus.set(i, {"barValue": arvo, "barColor": vari});
    }

    function muutaVkoArvo(i, arvo, vari) {
        return vkoKulutus.set(i, {"barValue": arvo, "barColor": vari});
    }

    function talletaPaivanArvo(vuosi, viikko, paiva, maara) {
        var i = etsiPaiva(vuosi, viikko, paiva), vari;
        if (maara < 0)
            maara = 0;
        vari = variPaivalle(maara);

        if (pvKulutus.count === 0 || i < 0) {
            lisaaPvArvo(vuosi, viikko, paiva, maara, vari);
        } else {
            muutaPvArvo(i, maara, vari);
        }

        return;
    }

    function talletaViikonArvo(vuosi, viikko, maara) {
        var i = etsiViikko(vuosi, viikko), vari;
        if (maara < 0)
            maara = 0;
        vari = variViikolle(maara);

        if (vkoKulutus.count === 0 || i < 0) {
            lisaaVkoArvo(vuosi, viikko, maara, vari);
        } else {
            muutaVkoArvo(i, maara, vari);
        }

        return;
    }

    function vaihdaKuvaaja(uusiTyyppi) {
        var i=0;
        if (uusiTyyppi === 0) {
            pylvaikko.model = vkoKulutus;
            tyyppi = uusiTyyppi;
        } else if (uusiTyyppi === 1) {
            pylvaikko.model = pvKulutus;
            tyyppi = uusiTyyppi;
        }

        return;
    }

    function variPaivalle(maara) {
        var vari;
        if (maara < riskiPvAlempi)
            vari = riskiAlhainen
        else if (maara < riskiPvYlempi)
            vari = riskiKohonnut
        else
            vari = riskiKorkea;
        return vari;
    }

    function variViikolle(maara) {
        var vari;
        if (maara < riskiVkoAlempi) {
            vari = riskiAlhainen;
        } else if (maara < riskiVkoYlempi) {
            vari = riskiKohonnut;
        } else {
            vari = riskiKorkea;
        }
        return vari;
    }

    function viikonNumero(hetki) {
        // hetki = ms hetkestä 1970-1-1 0:0:0.000 GMT
        // jos vuoden ensimmäinen päivä on ma-to, aloittaa se 1. viikon - muuten kyseessä edellisen vuoden 53. viikko
        var vuosi = new Date(hetki).getFullYear();
        var ekaPvm = new Date(vuosi,0,1,0,0,1);
        var vikaPvm = new Date(vuosi,11,31,1,2,3);
        var vikaVkPaiva = viikonPaiva(vikaPvm.getTime());
        var vkpaiva = viikonPaiva(ekaPvm.getTime()); //0-6, ma - su tai su-la
        var vknyt, eroms, vrk = 24*60*60*1000;
        var vk1Ma; // maanantai viikolla 1

        // onko vuoden ensimmäinen päivä edellisen vuoden viikolla 52/53 vai tämän vuoden viikolla 1
        if (vkpaiva > 3.5) { // pe-su -> vk 52/53
            vk1Ma = new Date(vuosi, 0, 1 + (7-vkpaiva), 0, 0, 0, 0); // viikko 1 alkaa seuraavana maanantaina
        } else { //ma-to -> vk 1
            if (vkpaiva === 0) { // vuosi alkaa maanantaina
                vk1Ma = new Date(vuosi, 0, 1, 0, 0, 0, 0);
            } else {// viikko 1 alkaa edellisenä vuotena
                vk1Ma = new Date(vuosi-1, 11, 31 - (vkpaiva-2), 0, 0, 0, 0);
            }
        }

        eroms = hetki - vk1Ma.getTime(); // ms viikon 1 maanantaista
        if (eroms < 0) {
            vknyt = viikonNumero(new Date(vuosi-1,11,31,12,0,0).getTime());
        } else {
            vknyt = Math.floor(eroms/(7*vrk)) + 1;
        }

        return vknyt;
    }

    function viikonPaiva(aikaMs) {
        // 0 - viikon ensimmäinen päivä (Sun/Ma), 6 - viikon viimeinen päivä (Sat/Su)
        var pv = new Date(aikaMs).getDay();

        pv -= viikonEkaPaiva;
        if (pv < 0) {
            pv += 7;
        }

        return pv;
    }

    function vkPaivaMj(paiva){
        var tulos;
        paiva += viikonEkaPaiva;
        if (paiva > 6) {
            paiva -= 7;
        }

        if (paiva === 0) {
            tulos = qsTr("Sun");
        } else if (paiva === 1) {
            tulos = qsTr("Mon");
        } else if (paiva === 2) {
            tulos = qsTr("Tue");
        } else if (paiva === 3) {
            tulos = qsTr("Wed");
        } else if (paiva === 4) {
            tulos = qsTr("Thu");
        } else if (paiva === 5) {
            tulos = qsTr("Fri");
        } else if (paiva === 6) {
            tulos = qsTr("Sat");
        }
        return tulos;
    }
}
