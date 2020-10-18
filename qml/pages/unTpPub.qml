import QtQuick 2.0
import QtQml 2.0
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu

    property date   pvm
    property int    uusinCheckin: 0 // max_int, uusimman haettavan tunnus. Ei rajoita, jos 0.
    property string kaljarinki: "" // "kaverit", "lahisto", "olut", "panimo", "kuppila"
    property string _otsikko: "kirjaukset"
    property int    tunniste: 0

    //property bool hakuvirhe: false
    //property var kirjaustenTiedot: []
    //property bool ensimmainenHaku: true

    function aloitaHaku() {
        //hakuvirhe = false
        tyhjennaLista();
        uusinCheckin = 0;

        return uTYhteys.haeKirjauksia();
    }

    /*
    function qqkirjauksiaLahistolla() {
        var xhttp = new XMLHttpRequest();
        var lp, pp, sade=0, yksikko = "km"
        var kysely = "", vastaus

        hetkinen.running = true
        unTpdViestit.text = qsTr("posting query")

        if (paikkatieto.position.longitudeValid && paikkatieto.position.latitudeValid) {
            pp = paikkatieto.position.coordinate.longitude
            lp = paikkatieto.position.coordinate.latitude
        } else {
            lp = 60.28
            pp = 24.85

        }

        if (vainKaverit)
            kysely = UnTpd.getFriendsActivityFeed(uusinCheckin, 0, hakujaSivulle) // uusin, vanhin, per sivu
        else
            kysely = UnTpd.getPubFeed(lp, pp, sade, yksikko, uusinCheckin, 0, hakujaSivulle) // uusin, vanhin, per sivu

        xhttp.onreadystatechange = function () {
            //console.log("kaverienKirjauksia - " + xhttp.readyState + " - " + xhttp.status + " , " + hakunro)
            if (xhttp.readyState == 0)
                unTpdViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
            else if (xhttp.readyState == 1)
                unTpdViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
            else if (xhttp.readyState == 2)
                unTpdViestit.text = qsTr("request received") + ", " + xhttp.statusText
            else if (xhttp.readyState == 3)
                unTpdViestit.text = qsTr("processing request") + ", " + xhttp.statusText
            else { //if (xhttp.readyState == 4){
                unTpdViestit.text = xhttp.statusText
                //if (!vainKaverit)
                    //console.log("vastaus: " + xhttp.statusText)

                if (xhttp.status == 200) {
                    vastaus = JSON.parse(xhttp.responseText);
                    //console.log(xhttp.responseText)
                    hakuvirhe = false
                    paivitaLista(vastaus)
                } else {
                    //console.log("kaverienKirjauksia: " + xhttp.status + ", " + xhttp.statusText)
                    console.log(xhttp.status + " " + xhttp.responseText)
                    hakuvirhe = true
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return xhttp.status
    }
    // */

    function olenkoJutellut(jutut) {
        var juttuja = jutut.count, i = 0
        while(i < juttuja){
            if (jutut.items[i].comment_editor == true)
                return true
            i++
        }

        return false
    }

    function paivitaLista(vastaus) {
        var kirjatut = vastaus.response.checkins.items
        var i=0, n = vastaus.response.checkins.count
        var paivays = new Date(), kentta
        var kirjaus = -1, bid = -1, aikams = -1, aika = "", kuva = "", nimi = "", etiketti = "",
            olut = "", panimo = "", baari = "", baariId = -1, maljoja = -1, omaMalja = false,
            puheita = -1, puheLista = [], kayttajatunnus = "", huuto = "", osallistunut = false

        if (kaljarinki === "lahisto") {
            _otsikko = qsTr("Pints around")
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("no check-ins nearby! ??")
        } else if (kaljarinki === "kaverit") {
            _otsikko = qsTr("Checking friends")
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("no activity")
        }
        else if (kaljarinki === "olut") {
            _otsikko = kirjatut[0].beer.beer_name
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("nobody's drinking this?")
        } else if (kaljarinki === "panimo") {
            _otsikko = kirjatut[0].brewery.brewery_name
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("This brewery is tapped. No check-ins.")
        } else if (kaljarinki === "kuppila") {
            _otsikko = kirjatut[0].venue.venue_name
            if (n === 0 && uusinCheckin === 0)
                eiKirjauksia.text = qsTr("Nobody here!")
        }

        while (i<n) {
            kirjaus = kirjatut[i].checkin_id
            aikams = Date.parse(kirjatut[i].created_at)
            paivays.setTime(aikams)
            pvm = paivays
            aika = pvm.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
            kuva = kirjatut[i].user.user_avatar
            kayttajatunnus = kirjatut[i].user.user_name
            if (kirjatut[i].user.first_name != "" || kirjatut[i].user.last_name != "") {
                nimi = kirjatut[i].user.first_name + " " + kirjatut[i].user.last_name
            } else {
                nimi = kayttajatunnus
            }

            bid = kirjatut[i].beer.bid
            etiketti = kirjatut[i].beer.beer_label
            olut = kirjatut[i].beer.beer_name
            panimo = kirjatut[i].brewery.brewery_name
            maljoja = kirjatut[i].toasts.count // mikä ero on välillä total_count ja count?
            omaMalja = kirjatut[i].toasts.auth_toast // onko
            //console.log("toasts.count " + maljoja + ", total_count " + kirjatut[i].toasts.count + ", auth_toast " + omaMalja)
            puheita = kirjatut[i].comments.count
            puheLista = kirjatut[i].comments
            huuto = kirjatut[i].checkin_comment
            osallistunut = olenkoJutellut(kirjatut[i].comments)

            baari = ""
            for (kentta in kirjatut[i].venue) {
                //console.log("kentta " + kentta)
                if (kentta == "venue_name") {
                    //console.log(" == " + JSON.stringify(kirjatut[i].venue))
                    baari = kirjatut[i].venue.venue_name
                    //console.log(" == " + baari + " == ")
                }
                if (kentta == "venue_id") {
                    //console.log(" == " + JSON.stringify(kirjatut[i].venue))
                    baariId = kirjatut[i].venue.venue_id
                    //console.log(" == " + baari + " == ")
                }
            }

            /*console.log("" + i + "= " +  + kirjaus + ", " + aika + ", " + kuva + ", " + nimi
                        + "- " + bid + "- " + etiketti + "- " + olut + "; " + panimo + "; "
                        + maljoja + "; " + jutteluita + ", " + baari)// */
            //console.log("" + i + "= " + JSON.stringify(kirjatut[i]))
            kirjausLista.lisaaListaan(kirjaus, bid, aika, kuva, kayttajatunnus, nimi, etiketti,
                                      olut, panimo, baari, baariId, maljoja, omaMalja, huuto,
                                      puheita, puheLista, osallistunut)

            //if (!ensimmainenHaku) {
                //kirjaustenTiedot.push(kirjatut[i])
            //}

            i++
        }

        //if (ensimmainenHaku) {
            //kirjaustenTiedot = kirjatut
            //ensimmainenHaku = false
        //}

        //console.log("kirjaustenTiedot " + kirjaustenTiedot.length + " " + kirjaustenTiedot[kirjaustenTiedot.length-3].beer.beer_name)
        return i
    }

    /*
    function qqunTpdKohota(jsonVastaus) {
        var onnistunut = jsonVastaus.response.result
        var maljoja

        //console.log("> toast >\n" + JSON.stringify(jsonVastaus) + "\n< toast <")

        if (onnistunut == "success"){
            kirjausLista.set(valittu, {"maljoja": jsonVastaus.response.toasts.count,
                                 "kohotinko": jsonVastaus.response.toasts.auth_toast
                             })
        }

        hetkinen.running = false

        return
    }

    function qqunTpdJuttele(){
        //console.log("===\n===\n " + JSON.stringify(kirjaustenTiedot[valittu]))
        //console.log(" - - valittu = " + valittu)
        var viestisivu, solu = kirjausLista.get(valittu), nimi = ""
        if (solu.tekija != "") {
            nimi = solu.tekija
        } else {
            nimi = solu.kayttajatunnus
        }

        viestisivu = pageContainer.push(Qt.resolvedUrl("unTpJuomispuheet.qml"), {
                                        "keskustelu": solu.jutut,
                                        //"viesteja": solu.juttuja,
                                        "user_avatar": solu.osoite,
                                        "user_name": nimi,
                                        "venue_name": solu.paikka,
                                        "beer_label": solu.etiketti,
                                        "beer_name": solu.olut,
                                        "brewery_name": solu.panimo,
                                        "checkin_comment": solu.huuto,
                                        "ckdId": solu.checkinId
                                    })
        //viestisivu.sulkeutuu.connect( function() {
        //    if (viestisivu.viesteja != kirjausLista.get(valittu).jutteluita )
        //        kirjausLista.set(valittu,{"jutteluita":viestisivu.viesteja })
        //    })
        viestisivu.sulkeutuu.connect( function() {
            //console.log("sulkeutuu " + valittu + ", << " + viestisivu.viesteja + " >> "
            //            + viestisivu.keskustelu)
            kirjausLista.set(valittu,{//"maljoja": viestisivu.nostoja,
                                 //"kohotinko": viestisivu.omaNosto,
                                 "jutteluita": viestisivu.viesteja,
                                 "jutut": viestisivu.keskustelu})
            if (olenkoJutellut(viestisivu.keskustelu)) {
                kirjausLista.set(valittu,{"mukana": true})
            } else {
                kirjausLista.set(valittu,{"mukana": false})
            }

        })

        return
    }
    // */
    function tyhjennaLista() {

        return kirjausLista.clear()
    }

    /*
    function qqunTpdToast(ckId) {
        var xhttp = new XMLHttpRequest()
        var osoite = "", vastaus

        hetkinen.running = true

        osoite = UnTpd.toast(ckId)

        xhttp.onreadystatechange = function () {
            //console.log("checkIN - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 0)
                unTpdViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
            else if (xhttp.readyState == 1)
                unTpdViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
            else if (xhttp.readyState == 2)
                unTpdViestit.text = qsTr("request received") + ", " + xhttp.statusText
            else if (xhttp.readyState == 3)
                unTpdViestit.text = qsTr("processing request") + ", " + xhttp.statusText
            else if (xhttp.readyState == 4){
                unTpdViestit.text = qsTr("request finished") + ", " + xhttp.statusText

                vastaus = JSON.parse(xhttp.responseText);

                unTpdKohota(vastaus)

            } else {
                console.log(xhttp.readyState + ", " + xhttp.statusText)
                unTpdViestit.text = xhttp.readyState + ", " + xhttp.statusText
                viestinNaytto.start()
            }

        }

        unTpdViestit.text = qsTr("posting query")
        xhttp.open("POST", osoite, false)
        xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
        xhttp.send("");

        return
    }
    // */

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
                onClicked: {
                    if (kaljarinki === "kaverit")
                        kaljarinki = "lahisto"
                    else
                        kaljarinki = "kaverit"
                    aloitaHaku()
                }
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
                    kysely = UnTpd.getFriendsActivityFeed(uusinCheckin, 0, hakujaSivulle) // uusin, vanhin, per sivu
                else if (kaljarinki === "lahisto") {
                    if (paikkatieto.position.longitudeValid && paikkatieto.position.latitudeValid) {
                        pp = paikkatieto.position.coordinate.longitude
                        lp = paikkatieto.position.coordinate.latitude
                    } else {
                        lp = 60.28
                        pp = 24.85
                    }
                    kysely = UnTpd.getPubFeed(lp, pp, sade, yksikko, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
                } else if (kaljarinki === "olut")
                    kysely = UnTpd.getBeerFeed(tunniste, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
                else if (kaljarinki === "panimo")
                    kysely = UnTpd.getBreweryFeed(tunniste, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu
                else if (kaljarinki === "kuppila")
                    kysely = UnTpd.getVenueFeed(tunniste, uusinCheckin, 0, hakujaSivulle); // uusin, vanhin, per sivu

                console.log(kaljarinki + "-kirjaukset: " + kysely)
                xHttpGet(kysely)
                return
            }

            function kippis(ckId) {
                var kysely = "", posoite = ""
                //toiminto = "kippis";
                posoite = UnTpd.toast(ckId);
                xHttpPost(kysely, posoite, "kippis");
                return
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

            /*
            BusyIndicator {
                id: hetkinen
                size: BusyIndicatorSize.Medium
                anchors.horizontalCenter: parent.horizontalCenter
                running: false
                visible: running
            }

            Label {
                id: unTpdViestit
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("starting search")
                //width: sivu.width - 2*x
                color: Theme.secondaryColor
                visible: (hetkinen.running || hakuvirhe)
                wrapMode: Text.WordWrap
            }
            // */

            SilicaListView {
                id: kirjaukset
                height: sivu.height - y
                width: sivu.width
                //clip: true

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
                    //console.log("" + uusinCheckin)
                }
            }
        }
    }

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
        //console.log("tietoja >" + kirjaustenTiedot.length + "<")
    }
}
