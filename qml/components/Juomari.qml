import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: oletusLeveys
    height: oletusKorkeus

    // muutettavat
    property bool   alustus: false
    property string kelloMuoto: "HH:mm"
    property int kentanLeveys: (Theme.fontSizeMedium*0.5).toFixed(0)
    property alias  nakyma: juomaLista
    //property real   pohjat: 0.0 // ml alkoholia ensimmäisen juoman hetkellä (ennustin)

    // luettavat
    //property real   alkoholia: 0 // ml alkoholia kehossa
    property alias  annoksia: juomat.count
    property int    valittuJuoma: -1

    readonly property int  oletusKorkeus: 3*Theme.itemSizeSmall
    readonly property int  oletusLeveys: Theme.itemSizeExtraLarge
    readonly property int  msPaivassa: 24*msTunnissa // ms
    readonly property int  msTunnissa: 60*60*1000 // ms

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

        if (juomanKuvaus === undefined)
            juomanKuvaus = "";
        if (oluenId === undefined)
            oluenId = -1;

        juomat.lisaa(tkId, hetki, maara, vahvuus, juomanNimi, juomanKuvaus, oluenId);

        return;
    }

    function juodunAika(xid) {
        var ms = -1

        if (xid >= 0 && xid < juomat.count) {
            ms = juomat.get(xid).msPvm*msPaivassa + juomat.get(xid).kelloMs;
            //console.log("i " + xid + ", pvmMs " + juomat.get(xid).msPvm + " kelloMs " + juomat.get(xid).kelloMs + " ms " + ms)
        } else if (xid === undefined && juomat.count > 0) {
            ms = juomat.get(juomat.count-1).msPvm*msPaivassa + juomat.get(juomat.count-1).kelloMs;
        } else {
            console.log("index out of list");
        }

        return ms
    }

    function juodunNimi(xid) {
        var nimi = ""
        if (xid >= 0 && xid < juomat.count) {
            nimi = juomat.get(xid).juomanNimi;
        } else if (xid === undefined && juomat.count > 0) {
            nimi = juomat.get(juomat.count-1).juomanNimi;
        }

        return nimi
    }

    function juodunKuvaus(xid) {
        var mj = ""
        if (xid >= 0 && xid < juomat.count) {
            mj = juomat.get(xid).kuvaus;
        } else if (xid === undefined && juomat.count > 0) {
            mj = juomat.get(juomat.count-1).kuvaus;
        }
        return mj
    }

    function juodunOlutId(xid) {
        var olut = -1
        if (xid >= 0 && xid < juomat.count) {
            olut = juomat.get(xid).oluenId;
        } else if (xid === undefined && juomat.count > 0) {
            olut = juomat.get(juomat.count-1).oluendId;
        }

        return olut
    }

    function juodunPohjilla(xid) {
        var ml = -1
        if (xid >= 0 && xid < juomat.count) {
            ml = juomat.get(xid).mlVeressa;
        } else if (xid === undefined && juomat.count > 0) {
            ml = juomat.get(juomat.count-1).mlVeressa;
        }
        return ml
    }

    function juodunTilavuus(xid) {
        var ml = -1
        if (xid >= 0 && xid < juomat.count) {
            ml = juomat.get(xid).juomanTilavuus;
        } else if (xid === undefined && juomat.count > 0) {
            ml = juomat.get(juomat.count-1).juomanTilavuus;
        }
        return ml
    }

    function juodunTunnus(xid) {
        var mj = ""
        if (xid >= 0 && xid < juomat.count){
            mj = juomat.get(xid).tunnus;
        } else if (xid === undefined && juomat.count > 0) {
            mj = juomat.get(juomat.count-1).tunnus;
        }
        return mj
    }

    function juodunVahvuus(xid) {
        var pros = -1
        if (xid >= 0 && xid < juomat.count){
            pros = juomat.get(xid).juomanPros;
        } else if (xid === undefined && juomat.count > 0) {
            pros = juomat.get(juomat.count-1).juomanPros;
        }
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

    //sisäiseen käyttöön
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
        ajat = msPaiviksiJaTunneiksi(ms);
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
                mouse.accepted = false
            }

            onPressAndHold: {
                juomaLista.currentIndex = juomaLista.indexAt(mouseX,y+mouseY)
                mouse.accepted = false
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
                    width: 7*kentanLeveys //ExtraSmall*6
                    color: Theme.secondaryColor
                }

                Label {
                    text: juomanNimi
                    width: 14*kentanLeveys //ExtraSmall*8
                    truncationMode: TruncationMode.Fade
                    color: Theme.secondaryColor
                }

                Label {
                    text: juomanTilavuus
                    width: 5*kentanLeveys //ExtraSmall*3
                    color: Theme.secondaryColor
                }

                Label {
                    text: juomanPros
                    width: 5*kentanLeveys //ExtraSmall*3
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

            ajat = msPaiviksiJaTunneiksi(hetki);
            kloMs = ajat.kello;
            pv1970 = ajat.paivia;

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
            var paiva = new Date(hetki).toLocaleDateString(Qt.locale(), Locale.ShortFormat); // juomispäivä
            var kello = new Date(hetki).toLocaleTimeString(Qt.locale(), kelloMuoto); // kellonaika
            var ind = etsiSeuraava(hetki);
            var ajat, kloMs, pv1970;// = hetki%msPaivassa // ms vuorokauden vaihtumisesta
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
