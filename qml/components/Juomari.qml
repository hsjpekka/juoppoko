import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: juoppo
    width: oletusLeveys
    height: oletusKorkeus

    // muutettavat
    property bool   alustus: false
    property string kelloMuoto: "HH:mm"
    property real   maksa: 1.0 // maksan toimintakyky (1.0 normaali)
    property alias  nakyma: juomaLista
    property real   paino: 80 // juomarin paino, kg
    property real   pohjat: 0.0 // ml alkoholia ensimmäisen juoman hetkellä (ennustin)
    property real   promilleRaja: 0.0 //
    property real   vetta: 0.65 // juomarin vesipitoisuus (miehet 75%, naiset 65%)

    // luettavat
    property real   alkoholia: 0 // ml alkoholia kehossa
    property alias  annoksia: juomat.count
    property real   promilleja: 0 // veren alkoholipitoisuus painopromilleina 0~3
    property date   rajalla
    property date   selvana
    property int    valittuJuoma: -1
    //property alias  kaynnissa: paivittaja.running
    //property alias  nykyinenRivi: juomaLista.currentIndex
    //property alias  paivitysTiheys: paivittaja.interval // ms
    //property string poistetunTunnus: ""
    //property string valitunNimi: ""
    //property int    valitunOlutId: 0 // mL
    //property int    valitunTilavuus: 0 // mL
    //property real   valitunVahvuus: 0.0 // til-%

    readonly property int  oletusKorkeus: 3*Theme.itemSizeSmall
    readonly property int  oletusLeveys: Theme.itemSizeExtraLarge
    readonly property int  msPaivassa: 24*msTunnissa // ms
    readonly property int  msTunnissa: 60*60*1000 // ms
    //readonly property real polttonopeusVakio: 0.1267 // ml/kg/h -- 1 g/10 kg/h = 1.267 ml/10 kg/h
    readonly property real tiheys: 0.7897 // alkoholin tiheys, g/ml

    // signal välittää kokonaisluvut qml:n 32 bittisinä, ei javascriptin 64 bittisinä
    signal juomaPoistettu(string tkTunnus, int paivia, int kello, real holia) // tktunnus, juoman aika, alkoholia
    signal muutaJuomanTiedot(int iMuutettava)

    function etsiSeuraava(hetki) {
        // palauttaa hetkeä hetki seuraavan juoman kohdan juomalistassa
        // jos hetkeä hetki ennen tai samaan aikaan juotu juoma on 5., palauttaa funktio arvon 5, eli kuudes juoma
        // 0 tyhjällä listalla ja jos hetki on aikaisempi kuin ensimmäisen listassa olevan
        // juomat.count, jos hetki on myöhempi tai yhtäsuuri kuin muiden juomien
        var i = juomat.count -1;

        if (!alustus) {
            if (hetki === undefined)
                i = -1;

            while (i >= 0 && hetki < juodunAika(i)) {
                i--;
            }
        }

        return i + 1;
    }

    function juo(tkId, hetki, maara, vahvuus, juomanNimi, juomanKuvaus, oluenId) {
        // tkId - juoman tunnus, hetki - juontiaika [ms], mlVeressa - ml alkoholia veressä hetkellä hetki,
        // maara - juoman tilavuus, vahvuus- juoman prosentit, juomanNimi - nimi, juomanKuvaus - tekstiä, lisayskohta - kohta listassa
        // pitäisikö juoman kuvaus lisätä???
        //var veressa;//, koskaSelvana, koskaRajalla
        //var paiva = new Date(hetki).toLocaleDateString(Qt.locale(),Locale.ShortFormat) // juomispäivä
        //var kello = new Date(hetki).toLocaleTimeString(Qt.locale(), kelloMuoto) // kellonaika

        // lasketaan paljonko veressä on alkoholia juomishetkellä
        //veressa = mlKehossa(hetki);

        if (juomanKuvaus === undefined)
            juomanKuvaus = "";
        if (oluenId === undefined)
            oluenId = -1;

        //juomat.lisaa(tkId, hetki, veressa, maara, vahvuus, juomanNimi, juomanKuvaus, oluenId);
        juomat.lisaa(tkId, hetki, maara, vahvuus, juomanNimi, juomanKuvaus, oluenId);

        //if (!alustus) {
            //selvana = new Date(msPromilleRajalle(veressa + maara*vahvuus/100, 0) + hetki)
            //rajalla = new Date(msPromilleRajalle(veressa + maara*vahvuus/100, promilleRaja) + hetki)

            //paivita(new Date().getTime())

            //juomaLista.positionViewAtEnd()
        //}

        return;
    }

    function juodunAika(xid) {
        var ms = -1

        if (xid >= 0 && xid < juomat.count) {
            ms = juomat.get(xid).msPvm*msPaivassa + juomat.get(xid).kelloMs
            //console.log("i " + xid + ", pvmMs " + juomat.get(xid).msPvm + " kelloMs " + juomat.get(xid).kelloMs + " ms " + ms)
        } else {
            console.log("index out of list")
        }

        return ms
    }

    function juodunNimi(xid) {
        var nimi = ""
        if (xid >= 0 && xid < juomat.count)
            nimi = juomat.get(xid).juomanNimi
        return nimi
    }

    function juodunKuvaus(xid) {
        var mj = ""
        if (xid >= 0 && xid < juomat.count)
            mj = juomat.get(xid).kuvaus
        return mj
    }

    function juodunOlutId(xid) {
        var olut = -1
        if (xid >= 0 && xid < juomat.count)
            olut = juomat.get(xid).oluenId
        return olut
    }

    function juodunPohjilla(xid) {
        var ml = -1
        if (xid >= 0 && xid < juomat.count)
            ml = juomat.get(xid).mlVeressa
        return ml
    }

    function juodunTilavuus(xid) {
        var ml = -1
        if (xid >= 0 && xid < juomat.count)
            ml = juomat.get(xid).juomanTilavuus
        return ml
    }

    function juodunTunnus(xid) {
        var mj = ""
        if (xid >= 0 && xid < juomat.count)
            mj = juomat.get(xid).tunnus
        return mj
    }

    function juodunVahvuus(xid) {
        var pros = -1
        if (xid >= 0 && xid < juomat.count)
            pros = juomat.get(xid).juomanPros
        return pros // %
    }

    function juotuAikana(kesto, loppuHetki) {
        var ml = 0, i = juomat.count, t0, ti, t1 = loppuHetki;
        if (t1 === undefined)
            t1 = new Date().getTime();
        t0 = t1 - kesto;
        while (juodunAika(i) > t1 && i >= 0)
            i--;
        while ( i >= 0 && juodunAika(i) >= t0 ) {
            ml = ml + juodunTilavuus(i)*juodunVahvuus(i)/100
            i--;
        }

        return ml;
    }

    function _mlKehossa(ms) {
        // laskee, paljonko alkoholia on veressä hetkellä ms
        // xid on edellisen juoman kohta
        var xid = etsiSeuraava(ms)-1;
        var ml1;

        if (xid < 0) {
            ml1 = pohjat;
        } else {
            //ml1 = alkoholiaVeressa(lueJuomanAika(xid), lueMlVeressa(xid), lueJuomanMaara(xid), lueJuomanVahvuus(xid), ms )
            ml1 = alkoholiaVeressa(juodunAika(xid), juodunPohjilla(xid),
                                        juodunTilavuus(xid), juodunVahvuus(xid), ms);
        }
        //console.log(xid + ", ml " + ml1 + ", pohjat " + pohjat)
        return ml1;
    }

    function muutaJuoma(id, hetki, maara, vahvuus, nimi, kuvaus, oId) {
        var ms0 = juodunAika(id);
        juomat.aseta(id, hetki, maara, vahvuus, nimi, kuvaus, oId);
        //juomat.set(id, { "msPvm": pv1970, "kelloMs": kloMs, "mlVeressa": veressa,
        //               "section": paiva, "juomanAika": kello,
        //               "juomanNimi": nimi, "juomanTilavuus": maara,
        //               "juomanPros": vahvuus, "oluenId": oId, "kuvaus": kuvaus })

        //if (hetki < ms0)
        //    laskeUudelleen(hetki+1)
        //else
        //    laskeUudelleen(ms0+1)

        return;
    }

    function _paivita(aika) { // jos aikaa ei määritetä, lasketaan nykyinen tila

        if (aika === undefined)
            aika = new Date().getTime();

        alkoholia = mlKehossa(aika);
        promilleja = alkoholia*tiheys/(paino*vetta);

        return;
    }

    function _palamisNopeus() {     // ml/h
        return polttonopeusVakio*paino*maksa;
    }

    function _promillejaHetkella(aika) { // g alkoholia/kg keho
        return mlKehossa(aika)*tiheys/(paino*vetta);
    }

    function _prom2ml(pro) {
        return pro*paino*vetta/tiheys;
    }

    //sisäiseen käyttöön
    function _alkoholiaVeressa(hetki0, ml0, mlJuoma, vahvuus, hetki1){
        //  hetki0 - int [ms], hetki, jolloin edellinen juoma juotiin
        //  ml0 - float [ml], alkoholia veressä hetkellä hetki0
        //  mlJuoma - int [ml], juoman koko
        //  vahvuus - float [%], alkoholin til-%
        //  hetki1 - int [ms], ajanhetki, jonka alkoholin määrä lasketaan
        //  jos hetki1 < hetki0, palauttaa ml0 + mlJuoma*vahvuus
        var ml1, dt; // tuntia

        dt = (hetki1 - hetki0)/msTunnissa; // ms -> h
        if (dt < 0) {
            dt = 0;
        }

        ml1 = ml0 + mlJuoma*vahvuus/100 - palamisNopeus()*dt; // vanhat pohjat + juotu - poltetut

        if (ml1 < 0)
            ml1 = 0;

        //console.log("edellinen " + hetki0 + ", pohjat " + ml0.toFixed(1) + ", V " + mlJuoma + ", % " + vahvuus + ", nyky " + hetki1 + ", ml " + ml1.toFixed(1))
        return ml1;
    }

    function _laskeUudelleen(aika) { // muuttaa ajan jälkeen juotujen juomien ml-arvot
        var i, ml0, ml1, ms0, ms1;

        if (aika === undefined)
            i = 0
        else {
            i = etsiSeuraava(aika) - 1;
            if (i<0)
                i = 0;
        }

        if (i < 0.5)
            ml0 = pohjat
        else
            ml0 = juodunPohjilla(i-1);

        //console.log("aika " + aika + ", i " + i + " = " + juodunAika(i) + " .. " + juodunPohjilla(i) + " .. " + ml0)

        while (i < juomat.count) {
            juomat.aseta(i, juodunAika(i), juodunTilavuus(i), juodunVahvuus(i),
                         juodunNimi(i), juodunKuvaus(i), juodunOlutId(i));
            i++;
        }

        i = juomat.count - 1;
        if (i >= 0) {
            ml1 = juodunPohjilla(i) + juodunTilavuus(i)*juodunVahvuus(i)/100;
            selvana = new Date( msPromilleRajalle(ml1, 0) + juodunAika(i) );
            rajalla = new Date( msPromilleRajalle(ml1, promilleRaja) + juodunAika(i) );
        } else {
            selvana = new Date( 0 );
            rajalla = new Date( 0 );
        }

        return;
    }

    function _msPromilleRajalle(mlVeressa, raja){
        // ml0 - alkoholia veressä ennen juotua juomaa koko0, vahvuus0
        var mlRajalle, hRajalle;

        mlRajalle = mlVeressa - raja*paino*vetta/tiheys;
        if (mlRajalle > 0)
            hRajalle = mlRajalle/palamisNopeus()
        else
            hRajalle = 0;

        return Math.round(hRajalle*msTunnissa);
    }

    function msPaiviksiJaTunneiksi(ms) {
        var paivat, kelloMs;
        kelloMs = ms%msPaivassa;
        paivat = (ms-kelloMs)/msPaivassa;
        return {"paivia": paivat, "kello": kelloMs};
    }

    function poistaJuotu(i) {
        var ms = juodunAika(i), tkTunnus = juodunTunnus(i), poistettavanML, ajat;
        poistettavanML = juodunTilavuus(i)*juodunVahvuus(i)/100;
        juomat.remove(i);
        //laskeUudelleen(ms-1);
        //paivita();
        //ajat = msPaiviksiJaTunneiksi(ms);
        juomaPoistettu(tkTunnus, ajat.paivia, ajat.kello, poistettavanML); // signaali
        return;
    }

    Component {
        id: riviJuodut
        ListItem {
            id: juotuJuoma
            width: juomaLista.width - 2*x
            x: Theme.horizontalPageMargin
            propagateComposedEvents: true
            onClicked: {
                valittuJuoma = juomaLista.indexAt(mouseX, y+mouseY)
                //valitseJuoma(valittuJuoma)
                mouse.accepted = false
                //console.log("juomaLista, nykyinen " + juomaLista.currentIndex + " - " + valittuJuoma)
            }

            onPressAndHold: {
                juomaLista.currentIndex = juomaLista.indexAt(mouseX,y+mouseY)
                mouse.accepted = false
                //console.log("onP&H, nykyinen " + juomaLista.currentIndex)
            }

            // contextmenu erillisenä komponenttina on ongelma remorseActionin kanssa
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("delete")
                    onClicked: {
                        var poistettava = juomaLista.currentIndex

                        juomaLista.currentItem.remorseAction(qsTr("deleting"), function () {
                            juomaLista.currentIndex = poistettava-1
                            poistaJuotu(poistettava)
                        })

                    }
                }

                MenuItem {
                    text: qsTr("modify")
                    onClicked: {
                        muutaJuomanTiedot(juomaLista.currentIndex)
                    }
                }

            }

            Row {

                Label {
                    text: juomanAika
                    width: (Theme.fontSizeMedium*3.5).toFixed(0) //ExtraSmall*6
                    color: Theme.secondaryColor
                }

                Label {
                    text: juomanNimi
                    width: Theme.fontSizeMedium*7 //ExtraSmall*8
                    truncationMode: TruncationMode.Fade
                    color: Theme.secondaryColor
                }

                Label {
                    text: juomanTilavuus
                    width: (Theme.fontSizeMedium*2.5).toFixed(0) //ExtraSmall*3
                    color: Theme.secondaryColor
                }

                Label {
                    text: juomanPros
                    width: (Theme.fontSizeMedium*2.5).toFixed(0) //ExtraSmall*3
                    color: Theme.secondaryColor
                }

            } //row


        } //listitem
    } //riviJuodut

    ListModel {
        //   int      int        real         int        string    string
        // {"msPvm", "kelloMs", "mlVeressa", "oluenId", "kuvaus", "tunnus",
        //   string        string        int               real
        //  "juomanAika", "juomanNimi", "juomanTilavuus", "juomanPros"}
        id: juomat

        //             int, int,  int,   real,    str,  str,    int
        function aseta(id, hetki, maara, vahvuus, nimi, kuvaus, oId) {
            var paiva = new Date(hetki).toLocaleDateString(Qt.locale(),Locale.ShortFormat); // juomispäivä
            var kello = new Date(hetki).toLocaleTimeString(Qt.locale(), kelloMuoto); // kellonaika
            var ajat, kloMs, pv1970, tkId = juodunTunnus(id);
            //var veressa = 0;
            //if (id > 0)
            //    veressa = alkoholiaVeressa(juodunAika(id-1), juodunPohjilla(id-1),
            //                               juodunTilavuus(id-1), juodunVahvuus(id-1), hetki) //mlKehossa(hetki-1);
            ajat = msPaiviksiJaTunneiksi(hetki);
            kloMs = ajat.kello;//hetki%msPaivassa
            pv1970 = ajat.paivia;//(hetki-kloMs)/msPaivassa

            juomat.set(id, { "tunnus": tkId, "msPvm": pv1970, "kelloMs": kloMs, //"mlVeressa": veressa,
                           "section": paiva, "juomanAika": kello,
                           "juomanNimi": nimi, "juomanTilavuus": maara,
                           "juomanPros": vahvuus, "oluenId": oId, "kuvaus": kuvaus});
            return
        }

        //             int,  int,   real,    real,  real,    str,        str,         int
        //function lisaa(tkId, hetki, veressa, maara, vahvuus, juomanNimi, juomanKuvaus, oluenId) {
        //             int,  int,    real,  real,    str,        str,         int
        function lisaa(tkId, hetki, maara, vahvuus, juomanNimi, juomanKuvaus, oluenId) {
            var paiva = new Date(hetki).toLocaleDateString(Qt.locale(),Locale.ShortFormat); // juomispäivä
            var kello = new Date(hetki).toLocaleTimeString(Qt.locale(), kelloMuoto); // kellonaika
            var ind = etsiSeuraava(hetki);
            var ajat, kloMs, pv1970;// = hetki%msPaivassa // ms vuorokauden vaihtumisesta
            //var pv1970 = (hetki - kloMs)/msPaivassa
            ajat = msPaiviksiJaTunneiksi(hetki);
            kloMs = ajat.kello;
            pv1970 = ajat.paivia;

            if (ind < juomat.count) {
                juomat.insert(ind, { "tunnus": tkId, "msPvm": pv1970, "kelloMs": kloMs, //"mlVeressa": veressa,
                                  "section": paiva, "juomanAika": kello,
                                  "juomanNimi": juomanNimi, "juomanTilavuus": maara,
                                  "juomanPros": vahvuus, "oluenId": oluenId,
                                  "kuvaus": juomanKuvaus });
            } else {
                juomat.append({ "tunnus": tkId, "msPvm": pv1970, "kelloMs": kloMs, //"mlVeressa": veressa,
                                  "section": paiva, "juomanAika": kello,
                                  "juomanNimi": juomanNimi, "juomanTilavuus": maara,
                                  "juomanPros": vahvuus, "oluenId": oluenId,
                                  "kuvaus": juomanKuvaus });
            }

            return;
        }

    }

    SilicaListView {
        id: juomaLista
        anchors.fill: parent
        highlightFollowsCurrentItem: !alustus
        clip: true

        model: juomat

        section {
            property: 'section'

            delegate: SectionHeader {
                text: section
            }
        }

        delegate: riviJuodut

        footer: Row {
            x: Theme.horizontalPageMargin
            //height: 70

            Label {
                text: qsTr("time")
                width: (Theme.fontSizeMedium*3.5).toFixed(0)
                color: Theme.secondaryHighlightColor
            }
            Label {
                text: qsTr("drink")
                width: Theme.fontSizeMedium*7
                color: Theme.secondaryHighlightColor
            }
            Label {
                text: "ml"
                width: (Theme.fontSizeMedium*2.5).toFixed(0)
                color: Theme.secondaryHighlightColor
            }
            Label {
                text: qsTr("vol-%")
                width: (Theme.fontSizeMedium*2.5).toFixed(0)
                color: Theme.secondaryHighlightColor
            }
        }

        VerticalScrollDecorator {}

    }

}
