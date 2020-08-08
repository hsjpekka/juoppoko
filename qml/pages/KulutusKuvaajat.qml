import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: pohja
    width: parent.width
    height: Theme.itemSizeLarge

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

    signal pylvasValittu(int pylvasNro, real valitunArvo, string valitusNimike)
    signal pitkaPainanta(int pylvasNro, real valitunArvo, string valitusNimike)

    onTyyppiChanged: {
        console.log("uusi tyyppi " + tyyppi)
    }
    onVrkVaihtuuChanged: {
        // vuorokauden vaihtumisaika ei vaikuta jo piirrettyihin pylväisiin
        console.log("vrk vaihtuu " + (vrkVaihtuu - vrkVaihtuu%60)/60 + ":" + vrkVaihtuu%60 )
    }

    function etsiPaiva(vuosi, viikko, paiva) {
        var i = pvKulutus.count-1, nro = -1
        while (i >= 0) {
            if ((pvKulutus.get(i).vuosi == vuosi) && (pvKulutus.get(i).vkoNro == viikko) &&
                    (pvKulutus.get(i).paiva == paiva)) {
                nro = i
                i = -1
            }

            i--
        }

        //if (nro === -1)
        //    console.log("ei tietoja päivältä " + vuosi + " - vko " + viikko + " - " + paiva)

        return nro
    }

    function etsiViikko(vuosi, viikko) {
        // palauttaa ko. viikon järjestysnumeron vkoKulutus-taulukossa
        // palauttaa arvon -1, jos viikkoa ei löydy
        var i = vkoKulutus.count-1, nro = -1
        while (i >= 0) {
            if ((vkoKulutus.get(i).vuosi == vuosi) && (vkoKulutus.get(i).vkoNro == viikko)) {
                nro = i
                i = -1
            }

            i--
        }

        //if (nro === -1)
        //    console.log("ei tietoja viikolta " + vuosi + "-" + viikko)

        return nro
    }

    function juotuPaivalla(vuosi, viikko, paiva) {
        var i = etsiPaiva(vuosi, viikko, paiva), ml = 0

        if (i >=0 && i < pvKulutus.count) {
            ml = pvKulutus.get(i).barValue
        }

        return ml
    }

    function juotuViikolla(vuosi, viikko) {
        var i = etsiViikko(vuosi, viikko), ml = 0

        if (i >=0 && i < vkoKulutus.count) {
            ml = vkoKulutus.get(i).barValue
        }

        return ml
    }

    function lisaa(aikaMs, alkoholiaMl) {
        var ml0, msJuoma, nyt, paiva, vuosi, viikko, ajat

        msJuoma = aikaMs - vrkVaihtuu*60*1000

        ajat = maaritaAjat(msJuoma)
        vuosi = ajat[0] // vuosi = nyt.getFullYear() tai +/- 1 viikolla 1/53
        viikko = ajat[1] // viikonNumero(msJuoma)
        paiva = ajat[2] // date.getDay() = 0 (su) - 6 (la) => 1 (ma) - 7 (su)

        console.log("uusin " + vuosi + " " + viikko + "-" + paiva + " skaalat " + skaalaVko + " " + skaalaPv)

        lisaaTyhjiaPaivia(vuosi, viikko, paiva)

        // viikkokuvaajan päivitys
        ml0 = juotuViikolla(vuosi, viikko)
        talletaViikonArvo(vuosi, viikko, ml0 + alkoholiaMl)

        console.log("juotu viikolla " + ml0 + " ja " + alkoholiaMl)

        // paivakuvaajan päivitys
        ml0 = juotuPaivalla(vuosi, viikko, paiva)
        talletaPaivanArvo(vuosi, viikko, paiva, ml0 + alkoholiaMl)

        return
    }

    function lisaaTyhjiaPaivia(vuosi, viikko, paiva) {
        // vuosi, viikko ja päivä ovat uuden juoman ajankohta
        // lisätään peräkkäisten kirjausten väliin jäävät päivät kuvaajiin
        var iPv, iVko, iVs, nVko
        if (pvKulutus.count === 0) // ensimmäinen juoma
            return

        iPv = pvKulutus.get(pvKulutus.count-1).paiva + 1
        iVko = pvKulutus.get(pvKulutus.count-1).vkoNro
        iVs = pvKulutus.get(pvKulutus.count-1).vuosi

        //console.log("iPv " + iPv + "-" + paiva + ", iVko " + iVko + "-" + viikko + ", iVs " + iVs + "-" + vuosi)

        while (iVs < vuosi) {
            nVko = viikonNumero(new Date(iVs,11,31,22,54,53,990).getTime())
            if (nVko === 1) // jos vuoden viimeinen viikko jää kovin vajaaksi
                nVko = 52
            while (iVko <= nVko) {
                if (iPv === 1)
                    lisaaVkoArvo(iVs, iVko, 0, riskiAlhainen)//talletaViikonArvo(iVs, iVko, 0)
                while (iPv <= 7) {
                    lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen)//talletaPaivanArvo(iVs, iVko, iPv, 0)
                    iPv++
                }
                iPv=1
                iVko++
            }
            iPv = 1
            iVko = 1
            iVs++
        }

        while (iVko < viikko) {
            if (iPv === 1)
                lisaaVkoArvo(iVs, iVko, 0, riskiAlhainen)
            while (iPv <= 7) {
                lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen)
                iPv++
            }
            iPv=1
            iVko++
        }

        while (iPv < paiva) {
            lisaaPvArvo(iVs, iVko, iPv, 0, riskiAlhainen)
            iPv++
        }

        return
    }

    function lisaaPvArvo(vuosi, viikko, paiva, maara, vari) {
        //console.log(" -- " + paiva + " - " + maara + " -- " + vari)
        return pvKulutus.append({ "vuosi": vuosi, "vkoNro": viikko, "paiva": paiva, "barValue": maara,
                                    "barLabel": paiva, "barColor": vari, "sect": vuosi + "-" + viikko })
    }

    function lisaaVkoArvo(vuosi, viikko, maara, vari) {
        //console.log(" -- " + viikko + " - " + maara + " -- " + vari)
        return vkoKulutus.append({ "vuosi": vuosi, "vkoNro": viikko, "barValue": maara,
                              "barLabel": viikko, "barColor": vari, "sect": vuosi })
    }

    // return [vuosi, viikko, paiva]
    function maaritaAjat(ms){
        var pvm = new Date(ms), ajat = []
        var vuosi, vuosi0 = pvm.getFullYear(), vk = viikonNumero(ms), pv = viikonPaiva(ms)

        vuosi = vuosi0
        if (vk === 1) { // menevätkö vuoden viimeiset päivät seuraavan vuoden ensimmäiselle viikolle
            if (pvm.getMonth() === 11)
                vuosi = vuosi0 + 1
        } else if (vk > 51.5) { // entä ensimmäiset päivät edellisen vuoden viimeiselle viikolle
            if (pvm.getMonth() === 0)
                vuosi = vuosi0 - 1
        }

        //console.log(" " + vuosi + ", " + vk + ", " + pv)

        ajat[0] = vuosi
        ajat[1] = vk
        ajat[2] = pv

        return ajat
    }

    function msVko(vuosi,viikko) {
        var ms = new Date(vuosi,0,1,0,0,0,0).getTime()
        ms += (viikko-1)*7*24*60*60*1000

        return ms
    }

    function muutaPvArvo(i, arvo, vari) {
        //console.log(" -- " + i + " - " + arvo + " -- " + vari)
        return pvKulutus.set(i, {"barValue": arvo, "barColor": vari})
    }

    function muutaVkoArvo(i, arvo, vari) {
        //console.log(" -- " + i + " - " + arvo + " -- " + vari)
        return vkoKulutus.set(i, {"barValue": arvo, "barColor": vari})
    }

    function talletaPaivanArvo(vuosi, viikko, paiva, maara) {
        var i = etsiPaiva(vuosi, viikko, paiva), vari
        if (maara < 0)
            maara = 0
        vari = variPaivalle(maara)

        //console.log("talleta " + i + ", " + maara + ", " + vari)

        if (pvKulutus.count === 0 || i < 0) {
            lisaaPvArvo(vuosi, viikko, paiva, maara, vari)
        } else {
            muutaPvArvo(i, maara, vari)
        }

        return
    }

    function talletaViikonArvo(vuosi, viikko, maara) {
        var i = etsiViikko(vuosi, viikko), vari
        if (maara < 0)
            maara = 0
        vari = variViikolle(maara)

        //console.log("talleta viikko " + i + ", " + maara + ", " + vari)

        if (vkoKulutus.count === 0 || i < 0) {
            lisaaVkoArvo(vuosi, viikko, maara, vari)
        } else {
            muutaVkoArvo(i, maara, vari)
        }

        return
    }

    function vaihdaKuvaaja(uusiTyyppi) {
        var i=0
        //pylvaikko.model.clear() // tyhjentää myös vkoKulutus- tai pvKulutus-tietueet
        if (uusiTyyppi === 0) {
            pylvaikko.model = vkoKulutus
            tyyppi = uusiTyyppi
            /*while (i < vkoKulutus.count) {
                pylvaikko.model.append({"vuosi": vkoKulutus.get(i).vuosi, "vkoNro": vkoKulutus.get(i).vkoNro,
                                           "barValue": vkoKulutus.get(i).barValue,
                                           "barColor": vkoKulutus.get(i).barColor,
                                           "barLabel": vkoKulutus.get(i).barLabel,
                                           "sect": vkoKulutus.get(i).sect})
                i++
            }// */
        } else if (uusiTyyppi === 1) {
            pylvaikko.model = pvKulutus
            tyyppi = uusiTyyppi
        }

        return
    }

    function variPaivalle(maara) {
        var vari
        if (maara < riskiPvAlempi)
            vari = riskiAlhainen
        else if (maara < riskiPvYlempi)
            vari = riskiKohonnut
        else
            vari = riskiKorkea
        return vari
    }

    function variViikolle(maara) {
        var vari
        if (maara < riskiVkoAlempi)
            vari = riskiAlhainen
        else if (maara < riskiVkoYlempi)
            vari = riskiKohonnut
        else
            vari = riskiKorkea
        return vari
    }

    function viikonNumero(hetki) {
        // hetki = ms GMT
        // jos vuoden ensimmäinen päivä on ma-to, aloittaa se 1. viikon - muuten kyseessä edellisen vuoden 53. viikko
        var vuosi = new Date(hetki).getFullYear() // hetki GMT:n mukaan, vuosi aikavyöhykkeen mukaan
        var ekaPvm = new Date(vuosi,0,1,0,0,0) // aikavyöhykkeen mukaan
        var vikaPvm = new Date(vuosi,11,31,1,2,3)
        var vkpaiva = viikonPaiva(ekaPvm.getTime()) //1-7, ma - su
        var vikaVkPaiva = viikonPaiva(vikaPvm.getTime())
        var vk0, vknyt, erovk, eropv, eroms, vrk = 24*60*60*1000

        // onko vuoden ensimmäinen päivä edellisen vuoden viikolla 52/53 vai tämän vuoden viikolla 1
        if (vkpaiva > 4.5) // pe-su -> vk 52/53
            vk0 = 0
        else //ma-to -> vk 1
            vk0 = 1

        eroms = hetki - ekaPvm.getTime() // ms vuoden alusta
        erovk = Math.floor(eroms/(7*vrk)) // kokonaisia viikkoja vuoden alusta - ei viikon 1. alusta
        eropv = Math.floor((eroms-erovk*7*vrk)/vrk) //

        if ( vkpaiva + eropv > 7.5) { // jos vuosi alkaa keskiviikkona vkpaiva = 3, erovk = 1 ja eropv = 5, ollaan kolmannella viikolla
            vknyt = vk0 + erovk + 1
        } else {
            vknyt = vk0 + erovk
        }

        if (vknyt < 0.5 ) // onko edellisen vuoden viimeinen päivä viikolla 52 vai 53?
            vknyt = viikonNumero(new Date(vuosi-1,11,31,12,0,0).getTime())

        if (vknyt > 52.5) { // onko vuoden viimeiset päivät jo seuraavan vuoden ensimmäisellä viikolla?
            if (vikaVkPaiva < 3.5)
                vknyt = 1
        }

        return vknyt
    }

    function viikonPaiva(hetki) {
        // palauttaa 1 - maanantai, 7 - sunnuntai
        // Date().getDay() palauttaa 0 - sunnuntai, 6 - lauantai
        // hetki - ms hetkestä 1970.1.1 00:00 GMT
        var paiva = new Date(hetki).getDay()

        if (paiva === 0)
            paiva = 7

        return paiva
    }

    ListModel {
        id: vkoKulutus
        //
        //{"vuosi", "vkoNro", "barValue", "barColor", "barLabel", "sect"}
    }

    ListModel {
        id: pvKulutus
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
            console.log("pylvään " + barNr + " korkeus " + barValue + " skaala " + scale)
        }
        onBarPressAndHold: {
            pitkaPainanta(barNr, barValue, barLabel)
        }
    }

}
