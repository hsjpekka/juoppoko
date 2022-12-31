import QtQuick 2.0
import QtQml 2.0
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    Component.onCompleted: {
        if (kaljarinki === "lahisto")
            _otsikko = qsTr("Pints")
        else if (kaljarinki === "kaverit")
            _otsikko = qsTr("Friends")
        else if (kaljarinki === "olut")
            _otsikko = qsTr("Beer activity")
        else if (kaljarinki === "panimo")
            _otsikko = qsTr("Brewery activity")
        else if (kaljarinki === "kuppila")
            _otsikko = qsTr("Venue activity")

        aloitaHaku();
    }

    property date   pvm
    property int    uusinCheckin: 0 // max_int, uusimman haettavan tunnus. Ei rajoita, jos 0.
    property string kaljarinki: "" // "kaverit", "lahisto", "olut", "panimo", "kuppila"
    property string _otsikko: "kirjaukset"
    property int    tunniste: 0

    PositionSource {
        id: paikkatieto
        active: true
        updateInterval: 5*60*1000 // 5 min
    }

    Component {
        id: kirjausTiedot
        UnTpKirjauksenKooste{
            id: kirjaus
            x: Theme.paddingSmall
            width: parent.width - 2*x
            kirjausId: checkinId
            olutId: bid
            kuva: osoite
            kayttis: kayttajatunnus
            juomari: tekija
            pubi: paikka
            pubiId: baariId
            tarra: etiketti
            kalja: olut
            valmistaja: panimo
            sanottu: lausahdus
            nostoja: maljoja
            omaNosto: kohotinko
            juttuja: jutteluita
            keskustelu: jutut
            osallistunut: mukana
            onMalja: uTYhteys.kippis(kirjausId)
            pubSivulla: true
        }
    }

    XhttpYhteys {
        id: uTYhteys
        anchors.top: parent.top
        z: 1
        onValmis: {
            var jsonVastaus;
            try {
                jsonVastaus = JSON.parse(httpVastaus);
                paivitaLista(jsonVastaus)
            } catch (err) {
                console.log("" + err)
                console.log("" + httpVastaus)
            }
        }

        property int hakujaSivulle: 0 // jos = 0, unTappdin oletusmäärä = 25, max 50

        function haeKirjauksia() {
            var lp, pp, sade=0, yksikko = "km";
            var kysely = "";

            if (kaljarinki === "kaverit")
                kysely = UnTpd.getFriendsActivityFeed(uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
            else if (kaljarinki === "lahisto") {
                if (paikkatieto.position.longitudeValid && paikkatieto.position.latitudeValid) {
                    pp = paikkatieto.position.coordinate.longitude;
                    lp = paikkatieto.position.coordinate.latitude;
                } else {
                    lp = 60.28;
                    pp = 24.85;
                }
                kysely = UnTpd.getPubFeed(lp, pp, sade, yksikko, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
            } else if (kaljarinki === "olut") {
                kysely = UnTpd.getBeerFeed(tunniste, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
            } else if (kaljarinki === "panimo") {
                kysely = UnTpd.getBreweryFeed(tunniste, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
            } else if (kaljarinki === "kuppila") {
                kysely = UnTpd.getVenueFeed(tunniste, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
            }
            xHttpGet(kysely[0], kysely[1], "toiminta");
            return;
        }

        function kippis(ckId) {
            var kysely = "";
            kysely = UnTpd.toast(ckId);
            xHttpPost(kysely[0], kysely[1], "", "kippis");
            return;
        }
    }

    SilicaFlickable {
        width: sivu.width
        height: sivu.height
        contentHeight: nakyma.height

        PullDownMenu {
            MenuItem {
                text: "↻ " + qsTr("refresh")
                onClicked:
                    aloitaHaku()
            }

            MenuItem {
                text: kaljarinki === "kaverit" ? qsTr("check pubs nearby") : qsTr("check friends")
                visible: UnTpd.unTpToken > ""
                onClicked: {
                    if (kaljarinki === "kaverit")
                        kaljarinki = "lahisto"
                    else
                        kaljarinki = "kaverit"
                    aloitaHaku()
                }
            }
        }

        Label {
            id: eiKirjauksia
            width: parent.width - 2*Theme.horizontalPageMargin
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            horizontalAlignment: Text.AlignHCenter
            color: Theme.highlightColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: Theme.fontSizeLarge
            visible: kirjaukset.count < 0.5
        }

        Column {
            id: nakyma
            width: sivu.width

            Row {
                id: huomatusRivi
                x: Theme.paddingMedium
                spacing: Theme.paddingMedium
                visible: (UnTpd.unTpToken == "")? true : false

                IconButton {
                    id: suljeHuomautus
                    icon.source: "image://theme/icon-m-clear"
                    onClicked: huomatusRivi.visible = false
                }

                TextArea {
                    width: sivu.width - 2*huomatusRivi.x - huomatusRivi.spacing - suljeHuomautus.width
                    color: Theme.secondaryHighlightColor
                    text: qsTr("Seems like you haven't logged in UnTappd. " +
                               "That may limit the number of queries per day.")
                    readOnly: true
                }
            }

            SilicaListView {
                id: kirjaukset
                height: sivu.height - y
                width: sivu.width

                model: UnTpKirjauslista{
                    id: kirjausLista
                }

                header: PageHeader {                    
                    title: _otsikko
                }
                delegate: kirjausTiedot

                section {
                    property: "section"

                    delegate: SectionHeader {
                        text: section
                    }
                }

                VerticalScrollDecorator {}

                onMovementEnded: {
                    if (atYEnd) {
                        uusinCheckin = kirjausLista.get(kirjausLista.count-1).checkinId - 1
                        uTYhteys.haeKirjauksia();
                    }
                }
            }
        }
    }

    function aloitaHaku() {
        tyhjennaLista();
        uusinCheckin = 0;

        return uTYhteys.haeKirjauksia();
    }

    function olenkoJutellut(jutut) {
        var juttuja = jutut.count, i = 0;
        while(i < juttuja){
            if (jutut.items[i].comment_editor == true)
                return true;
            i++;
        }

        return false;
    }

    function paivitaLista(vastaus) {
        var kirjatut = vastaus.response.checkins.items;
        var i=0, n = vastaus.response.checkins.count;
        var paivays = new Date(), kentta;
        var kirjaus = -1, bid = -1, aikams = -1, aika = "", kuva = "", nimi = "", etiketti = "",
            olut = "", panimo = "", baari = "", baariId = -1, maljoja = -1, omaMalja = false,
            puheita = -1, puheLista = [], kayttajatunnus = "", huuto = "", osallistunut = false;

        if (kaljarinki === "lahisto") {
            _otsikko = qsTr("Pints around");
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("no check-ins nearby! ??");
        } else if (kaljarinki === "kaverit") {
            _otsikko = qsTr("Checking friends");
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("no activity");
        }
        else if (kaljarinki === "olut") {
            _otsikko = kirjatut[0].beer.beer_name;
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("nobody's drinking this?");
        } else if (kaljarinki === "panimo") {
            _otsikko = kirjatut[0].brewery.brewery_name;
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("This brewery is tapped. No check-ins.");
        } else if (kaljarinki === "kuppila") {
            _otsikko = kirjatut[0].venue.venue_name;
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("Nobody here!");
        }

        while (i<n) {
            kirjaus = kirjatut[i].checkin_id;
            aikams = Date.parse(kirjatut[i].created_at);
            paivays.setTime(aikams);
            pvm = paivays;
            aika = pvm.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
            kuva = kirjatut[i].user.user_avatar;
            kayttajatunnus = kirjatut[i].user.user_name;
            if (kirjatut[i].user.first_name != "" || kirjatut[i].user.last_name != "") {
                nimi = kirjatut[i].user.first_name + " " + kirjatut[i].user.last_name;
            } else {
                nimi = kayttajatunnus;
            }

            bid = kirjatut[i].beer.bid;
            etiketti = kirjatut[i].beer.beer_label;
            olut = kirjatut[i].beer.beer_name;
            panimo = kirjatut[i].brewery.brewery_name;
            maljoja = kirjatut[i].toasts.count; // mikä ero on välillä total_count ja count?
            omaMalja = kirjatut[i].toasts.auth_toast; // onko
            puheita = kirjatut[i].comments.count;
            puheLista = kirjatut[i].comments;
            huuto = kirjatut[i].checkin_comment;
            osallistunut = olenkoJutellut(kirjatut[i].comments);

            baari = "";
            for (kentta in kirjatut[i].venue) {
                if (kentta == "venue_name") {
                    baari = kirjatut[i].venue.venue_name;
                }
                if (kentta == "venue_id") {
                    baariId = kirjatut[i].venue.venue_id;
                }
            }

            kirjausLista.lisaa(kirjaus, bid, aika, kuva, kayttajatunnus, nimi, etiketti,
                                      olut, panimo, baari, baariId, maljoja, omaMalja, huuto,
                                      puheita, puheLista, osallistunut);
            i++;
        }

        return i;
    }

    function tyhjennaLista() {
        return kirjausLista.clear();
    }

}
