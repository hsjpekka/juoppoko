import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/tietokanta.js" as Tkanta

Item {
    id: juoppo
    width: parent.width
    height: Theme.itemSizeLarge

    property string kelloMuoto: "HH:mm"
    property real   maksa: 0 // maksan toimintakyky (1.0 normaali)
    property real   paino: 0 // juomarin paino, kg
    property alias  paivitysTiheys: paivittaja.interval // ms
    property alias  toimii: paivittaja.running
    property real   vetta: 0 // juomarin vesipitoisuus (miehet 75%, naiset 65%)
    property int    valittuJuoma: -1

    readonly property real   alkoholia: 0 // ml alkoholia kehossa
    readonly property int    minuutti: 60*1000 // ms
    readonly property int    paiva: 24*tunti // ms
    readonly property real   polttonopeus: 0.1267 // ml/kg/h -- 1 g/10 kg/h = 1.267 ml/10 kg/h
    readonly property string poistetunTunnus: ""
    readonly property real   promilleja: 0 // veren alkoholipitoisuus painopromilleina
    readonly property real   tiheys: 0.7897 // alkoholin tiheys, g/ml
    readonly property int    tunti: 60*minuutti // ms
    readonly property string valitunNimi: ""
    readonly property int    valitunOlutId: 0 // mL
    readonly property int    valitunTilavuus: 0 // mL
    readonly property real   valitunVahvuus: 0.0 // til-%

    signal juomaPoistettu

    function alkoholiaVeressa(hetki0, ml0, mlJuoma, vahvuus, hetki1){
        //  hetki0 - int [ms], hetki, jolloin edellinen juoma juotiin
        //  ml0 - float [ml], alkoholia veressä hetkellä hetki0
        //  mlJuoma - int [ml], juoman koko
        //  vahvuus - float [%], alkoholin til-%
        //  hetki1 - int [ms], ajanhetki, jonka alkoholin määrä lasketaan
        //  jos hetki1 < hetki0, palauttaa ml0 + mlJuoma*vahvuus
        var dt // tuntia
        var ml1

        dt = (hetki1 - hetki0)/tunti // ms -> h
        if (dt < 0) {
            dt = 0
        }

        ml1 = ml0 + mlJuoma*vahvuus/100 - palamisNopeus()*dt // vanhat pohjat + juotu - poltetut

        if (ml1 < 0)
            ml1 = 0

        return ml1
    }

    function etsiPaikka(hetki) {
        // palauttaa hetkeä hetki seuraavan juoman kohdan juomalistassa
        // jos hetkeä hetki ennen tai samaan aikaan juotu juoma on 5., palauttaa funktio arvon 5, eli kuudes juoma
        // 0 tyhjällä listalla ja jos hetki on aikaisempi kuin ensimmäisen listassa olevan
        // juomat.count, jos hetki on myöhempi tai yhtäsuuri kuin muiden juomien
        // ind0 = aloituskohta
        var ind0 = juomat.length -1

        if (ind0 < 0) // tyhjä lista
            return 0

        while (hetki < juodunAika(ind0)) {
            ind0--
            if (ind0 < 0)
                return 0
        }

        return ind0 + 1
    }

    function juodunAika(xid) {
        var ms

        if (xid < 0)
            ms = -1
        else
            ms = juomat.get(xid).pvmMs*paiva + juomat.get(xid).kelloMs

        return ms
    }

    function juodunPohjilla(xid) {
        if (xid < 0) return 0
        return juomat.get(xid).veressa
    }

    function juodunTilavuus(xid) {
        if (xid < 0) return 0
        return juomat.get(xid).juomamaara
    }

    function juodunVahvuus(xid) {
        if (xid < 0) return 0
        return juomat.get(xid).juomapros
    }

    function juo(tkId, hetki, maara, vahvuus, juomanNimi, juomanKuvaus, oluenId) {
        // tkId - juoman tunnus, hetki - juontiaika [ms], mlVeressa - ml alkoholia veressä hetkellä hetki,
        // maara - juoman tilavuus, vahvuus- juoman prosentit, juomanNimi - nimi, juomanKuvaus - tekstiä, lisayskohta - kohta listassa
        // pitäisikö juoman kuvaus lisätä???
        var veressa
        var paiva = new Date(hetki).toLocaleDateString(Qt.locale(),Locale.ShortFormat) // juomispäivä
        var kello = new Date(hetki).toLocaleTimeString(Qt.locale(), kelloMuoto) // kellonaika
        var ind = etsiPaikka(hetki)
        var paivaMs = hetki%paiva
        var paivia1970 = (hetki - paivaMs)/paiva

        // lasketaan paljonko veressä on alkoholia juomishetkellä
        veressa = mlKehossa(hetki)

        if (ind < juomat.count) {
            juomat.insert(ind, { "tunnus": tkId, "msPvm": paivia1970, "kelloMs": paivaMs,
                              "mlVeressa": veressa, "section": paiva, "juomanAika": kello,
                              "juomanNimi": juomanNimi, "juomanTilavuus": maara,
                              "juomanPros": vahvuus.toFixed(1), "oluenId": oluenId });
            //console.log("lisaaListaanB: kohtaan " + ind + " aika " + hetki + " juoma " + juomanNimi)
        } else {
            juomat.append({ "tunnus": tkId, "msPvm": paivia1970, "kelloMs": paivaMs,
                              "mlVeressa": veressa, "section": paiva, "juomaaika": kello,
                              "juomanimi": juomanNimi, "juomamaara": maara,
                              "juomapros": vahvuus.toFixed(1), "oluenId": oluenId });
            //console.log("lisaaListaanB: loppuun " + " aika " + hetki + " juoma " + juomanNimi)
        }

        paivita()

        return
    }

    function laskeUudelleen(aika) {
        var i, ml1, ms1
        i = etsiPaikka(aika)
        while (i < juomat.count-1) { //(hetki0, ml0, mlJuoma, vahvuus, hetki1)
            ms1 = juodunAika(i+1)
            ml1 = alkoholiaVeressa(juodunAika(i), juomat.get(i).mlVeressa, juodunTilavuus(i),
                                  juodunVahvuus(i), ms1)
            muutaJuotu(i, ms1, ml1, juodunTilavuus(i+1), juodunVahvuus(i+1), juomat.get(i).juomanNimi,
                       juomat.get(i).kuvaus, juomat.get(i).oluenId)
            i++
        }

        return
    }

    function mlKehossa(ms) {
        // laskee, paljonko alkoholia on veressä hetkellä ms
        // xid on edellisen juoman kohta
        var xid = etsiPaikka(ms)-1
        var ml1

        //ml1 = alkoholiaVeressa(lueJuomanAika(xid), lueMlVeressa(xid), lueJuomanMaara(xid), lueJuomanVahvuus(xid), ms )
        ml1 = alkoholiaVeressa(juodunAika(xid), juodunPohjilla(xid), juodunTilavuus(xid),
                               juodunVahvuus(xid), ms)

        //console.log("alkoholia " + ml1 + " ml")
        return ml1
    }

    function muutaJuotu(i, ms, ml, tilavuus, nimi, kuvaus, olutId) {

    }

    function paivita() {
        var ms = new Date().getTime()
        alkoholia = mlKehossa(ms)
        promilleja = alkoholia*tiheys/(paino*vetta)

        return
    }

    function palamisNopeus() {     // ml/h
        return polttonopeus*paino*maksa
    }

    function valitseJuoma(id) {
        if (id < 0)
            id = 0
        if (id > juomat.count - 1)
            id = juomat.count - 1
        valitunNimi = juomat.get(id).juomanNimi
        valitunOlutId = juomat.get(id).oluenId
        valitunTilavuus = juomat.get(id).juomanTilavuus
        valitunVahvuus = juomat.get(id).juomanPros

        return
    }

    Timer {
        id: paivittaja
        running: true
        repeat: true
        interval: 6*1000 // ms
        onTriggered: {
            paivita()
        }
    }

    // tunnus, msPvm, kelloMs, mlVeressa, juomanAika, juomanNimi, juomanTilavuus, juomanPros, oluenId, kuvaus
    Component {
        id: rivityyppi
        ListItem {
            id: juotuJuoma
            propagateComposedEvents: true
            onClicked: {
                valittuJuoma = juomaLista.indexAt(mouseX, y+mouseY)
                valitseJuoma(valittuJuoma)
                mouse.accepted = false
                console.log("juomaLista, nykyinen " + juomaLista.currentIndex)

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
                        //console.log("valittu1 " + valittu + ", aika " + lueJuomanAika(valittu-1))

                        juomaLista.currentItem.remorseAction(qsTr("deleting"), function () {
                            juomaPoistettu()
                            var ms = juodunAika(poistettava)
                            juomat.remove(poistettava)
                            laskeUudelleen(ms)

                            //Tkanta.poistaTkJuodut(lueJuomanTunnus(poistettava))
                            //Apuja.poistaJuoma(lueJuomanTunnus(poistettava))
                            //paivitaMlVeressa(lueJuomanAika(poistettava-1)-1); //-1 varmistaa, että usean samaan aikaan juodun juoman kohdalla päivitys toimii
                            //paivitaPromillet();
                            //paivitaAjatRajoille();
                            //paivitaKuvaaja();
                            //console.log("poisto " + (valittu-1) + ", aika " + lueJuomanAika(valittu-1))

                        })

                    }
                }

                MenuItem {
                    text: qsTr("modify")
                    onClicked: {
                        muutaValittu(valittu);

                        paivitaMlVeressa(lueJuomanAika(valittu)-1);
                        paivitaPromillet();
                        paivitaAjatRajoille();

                    }
                }

            }

            property int paivia1970: msPvm // hetki, jolloin juoma juotiin on paivia1970*24*60*60*1000 + msPaiva
            property int msPaiva: kelloMs // qml:ssä kokonaisluku on 2^32, mikä ei riitä millisekunneille
            property int veressa: mlVeressa
            property int juomanId: oluenId
            property string teksti: kuvaus
            property string tkId: tunnus

            // juodut-taulukko: id aika veri% tilavuus juoma% juoma kuvaus
            Row {
                width: sivu.width*0.9
                x: sivu.width*0.05

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
                    text: juomanMaara
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
    } //rivityyppi

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
