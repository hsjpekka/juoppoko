import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd
import "../scripts/tietokanta.js" as Tkanta

Page {
    id: sivu

    signal sulkeutuu

    property bool   avaaKirjautumissivu: true
    property bool   haeKayttajatiedot: true
    property string ilmoitukset: ""
    property string kayttaja: ""
    property bool   lueUudelleen: false
    property date   pvm
    property bool   tilastotNakyvat: false
    //property int    valittu

    function kirjaudu() {
        var sivu=pageContainer.push(Qt.resolvedUrl("unTpKirjautuminen.qml"))
        sivu.muuttuu.connect( function() {
            tyhjennaKentat()
            if (UnTpd.unTpToken != ""){
                kayttaja = ""
                uTYhteys.lueKayttajanTiedot(kayttaja)
                uTYhteys.lueKayttajanKirjaukset(kayttaja, 0)
            }
        })
        return
    }

    function kirjoitaKirjaukset(jsonVastaus) {
        var vastaus = jsonVastaus.response.checkins
        var id, aika = "", bid, etiketti, merkki, lausahdus, maljoja, omaMalja, huutoja, baari,
                panimo, osallistunut, pubId
        var i=0, N = vastaus.count, aikams, paivays = new Date()
        var kentta
        while (i < N) {
            lausahdus = ""
            baari = ""
            //paikka = ""
            panimo = ""

            id = vastaus.items[i].checkin_id
            bid = vastaus.items[i].beer.bid
            etiketti = vastaus.items[i].beer.beer_label
            merkki = vastaus.items[i].beer.beer_name

            lausahdus = vastaus.items[i].checkin_comment

            aikams = Date.parse(vastaus.items[i].created_at)
            paivays.setTime(aikams)
            pvm = paivays
            aika = pvm.toLocaleDateString(Qt.locale(), Locale.ShortFormat)

            if ("venue_name" in vastaus.items[i].venue) {
                baari = vastaus.items[i].venue.venue_name
                //if (baari === "kotsaa") {
                    //console.log("" + JSON.stringify(vastaus.items[i]))
                //}
            } else
                baari = ""
            if ("venue_id" in vastaus.items[i].venue)
                pubId = vastaus.items[i].venue.venue_id
            else
                pubId = -1
            /* for (kentta in vastaus.items[i].venue) {
                if (kentta === "venue_name") {
                    baari = vastaus.items[i].venue.venue_name
                } else if (kentta === "venue_id") {
                    pubId = vastaus.items[i].venue.venue_id
                }
            } // */
            panimo = vastaus.items[i].brewery.brewery_name
            //}

            maljoja = vastaus.items[i].toasts.count
            omaMalja = vastaus.items[i].toasts.auth_toast
            huutoja = vastaus.items[i].comments.count
            osallistunut = olenkoJutellut(vastaus.items[i].comments)
            kirjausLista.lisaa(id, bid, aika, "", kayttaja, "", etiketti, merkki, panimo,
                                      baari, pubId, maljoja, omaMalja, lausahdus, huutoja,
                                      vastaus.items[i].comments, osallistunut)
            i++
        }
    }

    function kirjoitaTiedot(jsonVastaus){
        var vastaus
        if ("user" in jsonVastaus.response) {
            vastaus = jsonVastaus.response.user
        } else {
            return
        }

        kayttaja = vastaus.user_name
        otsikko.title = vastaus.user_name + " @UnTappd"
        nimi.text = vastaus.first_name + " " + vastaus.last_name
        nimi.color = Theme.highlightColor
        logo.kId = vastaus.uid

        kuva1.source = vastaus.user_avatar
        kuva2.source = vastaus.user_cover_photo

        if (vastaus.bio != "") {
            kuvaus.text = vastaus.bio
            kuvaus.label = vastaus.location + vastaus.url
        } else {
            kuvaus.text = vastaus.url
            kuvaus.label = vastaus.location
        }

        if (vastaus.stats.total_badges > 0){
            merkkeja.text = qsTr("badges") + " ..."
            merkkeja.color = Theme.primaryColor
        }
        merkkeja.label = vastaus.stats.total_badges

        if (vastaus.stats.total_friends > 0)
            kavereita.text = qsTr("friends")
        kavereita.label = vastaus.stats.total_friends

        if (vastaus.stats.total_checkins > 0)
            kirjauksia.text = qsTr("checkins")
        kirjauksia.label = vastaus.stats.total_checkins

        if (vastaus.stats.total_beers > 0)
            oluita.text = qsTr("beers")
        oluita.label = vastaus.stats.total_beers

        if (vastaus.stats.total_created_beers > 0)
            luodutOluet.text = qsTr("beers created")
        luodutOluet.label = vastaus.stats.total_created_beers

        if (vastaus.stats.total_photos > 0)
            kuvia.text = qsTr("photos")
        kuvia.label = vastaus.stats.total_photos

        if (vastaus.stats.total_followings > 0)
            seurattavia.text = qsTr("followed")
        seurattavia.label = vastaus.stats.total_followings

        return
    }

    function olenkoJutellut(jutut) {
        var juttuja = jutut.count, i = 0
        while(i < juttuja){
            if (jutut.items[i].comment_editor == true)
                return true
            i++
        }

        return false
    }

    function tyhjennaKentat() {
        otsikko.title = qsTr("UnTappd account")
        nimi.text = qsTr("")
        //nimi.color = Theme.secondaryHighlightColor
        //nimi.label = ""
        kuva1.source = ""
        kuva2.source = ""
        kuvaus.text = ""
        kuvaus.label = ""
        merkkeja.text = ""
        merkkeja.label = ""
        kavereita.text = ""
        kavereita.label = ""
        kirjauksia.text = ""
        kirjauksia.label = ""
        oluita.text = ""
        oluita.label = ""
        luodutOluet.text = ""
        luodutOluet.label = ""
        kuvia.text = ""
        kuvia.label = ""
        seurattavia.text = ""
        seurattavia.label = ""

        tyhjennaKirjaukset()

        return
    }

    function tyhjennaKirjaukset() {
        return kirjausLista.clear()
    }

    Component {
        id: kirjaustyyppi
        UnTpKirjauksenKooste{
            id: kirjaus
            x: Theme.paddingSmall
            width: parent.width - 2*x
            kirjausId: checkinId
            olutId: bid
            naytaTekija: false
            //kuva: osoite
            //kayttis: kayttajatunnus
            //juomari: tekija
            pubi: paikka //
            pubiId: baariId
            tarra: etiketti
            kalja: olut
            valmistaja: panimo //
            sanottu: lausahdus
            nostoja: maljoja
            omaNosto: kohotinko
            juttuja: jutteluita
            keskustelu: jutut
            osallistunut: mukana
        }
    }

    SilicaFlickable{
        height: sivu.height
        contentHeight: column.height
        width: sivu.width
        anchors.fill: sivu

        PullDownMenu{
            MenuItem {
                text: (UnTpd.unTpToken === "") ? qsTr("sign in") : qsTr("change user")
                visible: kayttaja === "" || kayttaja === UnTpd.kayttaja
                onClicked: {
                    kirjaudu()
                }
            }

            MenuItem {
                text: juojanHaku.active? qsTr("hide search") : qsTr("search user")
                //visible: !juojanHaku.active
                onClicked: {
                    juojanHaku.active = !juojanHaku.active
                    juojanHaku.focus = juojanHaku.active
                }
            }

            MenuItem {
                text: qsTr("send friend request")
                visible: kayttaja !== "" && kayttaja !== UnTpd.kayttaja
                onClicked: {
                    var varmistus
                    varmistus = pageContainer.push(Qt.resolvedUrl("unTpKaveripyynto.qml"),
                                                {"kaveri": kayttaja, "nimi": nimi.text,
                                                    "kuva": kuva1.source })
                    varmistus.accepted.connect( function() {
                        uTYhteys.pyydaKaveriksi(logo.kId)
                    } )
                }
            }

            MenuItem {
                text: qsTr("read my data")
                visible: kayttaja !== "" && kayttaja !== UnTpd.kayttaja
                onClicked: {
                    kayttaja = ""
                    tyhjennaKentat()
                    uTYhteys.lueKayttajanTiedot(kayttaja)
                    uTYhteys.lueKayttajanKirjaukset(kayttaja, 0)
                }
            }

            MenuItem {
                text: qsTr("notifications")
                visible: kayttaja === "" || kayttaja === UnTpd.kayttaja
                onClicked: {
                    //console.log("pitäisi välittyä " + uTYhteys.ilmoitukset.length + " merkkiä")
                    //console.log(uTYhteys.ilmoitukset.substring(0, 40))
                    if (lueUudelleen)
                        uTYhteys.lueIlmoitukset()
                    else {
                        pageContainer.push(Qt.resolvedUrl("unTpIlmoitukset.qml"),
                                           {"ilmoitukset": ilmoitukset})
                        lueUudelleen = true
                    }
                }
            }

        }

        XhttpYhteys {
            id: uTYhteys
            anchors.top: parent.top
            //xhttp: untpdKysely
            z: 1
            onValmis: {
                var jsonVastaus;
                try {
                    jsonVastaus = JSON.parse(httpVastaus);
                    if (toiminto === "tiedot") {
                        if ("user" in jsonVastaus.response)
                            console.log(jsonVastaus.response.user.user_name + ", " + jsonVastaus.response.user.uid)
                        else {
                            console.log("ei user-tietoja")
                            console.log("  ===  " + JSON.stringify(jsonVastaus))
                        }
                        kirjoitaTiedot(jsonVastaus)
                    } else if (toiminto === "kirjaukset")
                        kirjoitaKirjaukset(jsonVastaus)
                    else if (toiminto === "uutiset")
                        unTpdIlmoitaUutisista(httpVastaus)
                } catch (err) {
                    console.log("" + err)
                }
            }
            onVirhe: {
                var jsonVastaus;
                try {
                    jsonVastaus = JSON.parse(httpVastaus);
                    if (toiminto === "tiedot") {
                        if ("user" in jsonVastaus.response)
                            console.log(jsonVastaus.response.user.user_name + ", " + jsonVastaus.response.user.uid)
                        else {
                            console.log("ei user-tietoja")
                            console.log("  ===  " + JSON.stringify(jsonVastaus))
                        }
                        kirjoitaTiedot(jsonVastaus)
                    } else if (toiminto === "kirjaukset")
                        kirjoitaKirjaukset(jsonVastaus)
                    else if (toiminto === "uutiset")
                        unTpdIlmoitaUutisista(httpVastaus)
                } catch (err) {
                    console.log("" + err)
                }
            }

            //property string toiminto: ""

            function lueKayttajanTiedot(tunnus) { // jos tunnus = "" hakee omat tiedot
                var kysely;
                //toiminto = "tiedot";
                kysely = UnTpd.getUserInfo(tunnus,"true");
                xHttpGet(kysely[0], kysely[1], "tiedot");
                return;
            }

            function lueKayttajanKirjaukset(tunnus, eka) { // jos tunnus = "" hakee omat tiedot
                var kysely;
                //toiminto = "kirjaukset";
                kysely = UnTpd.getUserFeed(tunnus, eka);
                xHttpGet(kysely[0], kysely[1], "kirjaukset");
                return;
            }

            function lueIlmoitukset() {
                var kysely;
                //toiminto = "uutiset";

                kysely = UnTpd.getNotifications();//(offset, limit)

                xHttpGet(kysely[0], kysely[1], "uutiset");

                return;
            }

            function unTpdIlmoitaUutisista(vastaus) {
                var maara;

                ilmoitukset = vastaus;
                pageContainer.push(Qt.resolvedUrl("unTpIlmoitukset.qml"),
                                   {"ilmoitukset": ilmoitukset});

                return;
            }

            function unTpdToast(ckId) {
                var kysely = "";
                //toiminto = "kippis";
                kysely = UnTpd.toast(ckId);
                xHttpPost(kysely[0], kysely[1], "kippis");
                return;
            }

            function pyydaKaveriksi(kid) {
                var kysely = "";
                //toiminto = "kaveriksi"
                kysely = UnTpd.requestFriend(kid);
                xHttpGet(kysely[0], kysely[1], "kaveriksi")
                console.log("kaveripyyntö: " + kysely);
                return;
            }
        }

        Column {
            id: column
            width: sivu.width

            PageHeader {
                id: otsikko
                title: qsTr("UnTappd account")
            }

            Item {
                id: logo
                width: sivu.width
                height: (kuva2.height > kuva1.height + Theme.paddingLarge) ? kuva2.height : kuva1.height + Theme.paddingLarge

                property int kId: -1 // uid

                Image { //taustakuva
                    id: kuva2
                    width: sivu.width
                    fillMode: Image.PreserveAspectFit
                    source: ""
                }

                Label {
                    id: nimi
                    text: qsTr("unidentified")
                    x: Theme.paddingLarge
                    y: logo.height - height
                }

                Image { //naama
                    id: kuva1
                    width: Theme.fontSizeMedium*3//sivu.width/3
                    anchors.bottom: nimi.bottom
                    x: sivu.width - width - Theme.paddingLarge
                    height: width
                    source: ""
                }
            }

            SearchField {
                id: juojanHaku
                active: false
                canHide: true
                EnterKey.iconSource: "image://theme/icon-m-search"
                EnterKey.onClicked: {
                    tyhjennaKentat()
                    uTYhteys.lueKayttajanTiedot(text)
                    uTYhteys.lueKayttajanKirjaukset(text, 0)
                    focus = false
                }
                placeholderText: qsTr("username")
                width: parent.width
                onHideClicked: {
                    active = false
                    text = ""
                }
            }

            Row { // alaotsikot
                id: alaotsikkorivi
                height: tilastotNakyvat ? tilastot.height : juodut.height// + Theme.paddingLarge
                //anchors.topMargin: Theme.paddingMedium
                x: (sivu.width - tilastot.width - juodut.width)/3
                spacing: x
                //width: sivu.width - 2*x

                Label {
                    id: tilastot
                    text: qsTr("statistics")
                    color: tilastotNakyvat ? Theme.highlightColor : Theme.secondaryColor
                    font.pixelSize: tilastotNakyvat ? Theme.fontSizeLarge : Theme.fontSizeMedium
                    leftPadding: Theme.paddingMedium
                    rightPadding: Theme.paddingMedium
                    topPadding: Theme.paddingMedium
                    //bottomPadding: Theme.paddingSmall

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            tilastotNakyvat = true
                        }
                    }
                }

                Label {
                    id: juodut
                    text: qsTr("check-ins")
                    color: tilastotNakyvat ? Theme.secondaryColor : Theme.highlightColor
                    font.pixelSize: tilastotNakyvat ? Theme.fontSizeMedium : Theme.fontSizeLarge
                    leftPadding: Theme.paddingMedium
                    rightPadding: Theme.paddingMedium
                    topPadding: Theme.paddingMedium
                    //bottomPadding: Theme.paddingSmall

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            tilastotNakyvat = false
                        }
                    }
                }
            }

            Row {
                id: lehdenReuna
                spacing: 0

                Rectangle {
                    height: 1
                    width: alaotsikkorivi.spacing
                    color: Theme.secondaryHighlightColor
                }
                Rectangle {
                    height: 1
                    width: tilastot.width
                    color: tilastotNakyvat? "transparent" : Theme.secondaryHighlightColor
                }
                Rectangle {
                    height: 1
                    width: alaotsikkorivi.spacing
                    color: Theme.secondaryHighlightColor
                }

                Rectangle {
                    height: 1
                    width: juodut.width
                    color: tilastotNakyvat? Theme.secondaryHighlightColor : "transparent"
                }

                Rectangle {
                    height: 1
                    width: alaotsikkorivi.spacing
                    color: Theme.secondaryHighlightColor
                }

            }

            TextArea {
                id: kuvaus
                width: sivu.width
                placeholderText: qsTr("No biograph.")
                placeholderColor: Theme.secondaryHighlightColor
                color: Theme.highlightColor
                readOnly: true
                visible: tilastotNakyvat
            }

            Row { // juotuja
                spacing: (column.width - kirjauksia.width - oluita.width - merkkeja.width)/2
                visible: tilastotNakyvat

                TextField {
                    id: kirjauksia
                    placeholderText: qsTr("No checkins!")
                    placeholderColor: Theme.secondaryHighlightColor
                    width: sivu.width*0.33
                    color: Theme.highlightColor
                    readOnly: true
                }

                TextField {
                    id: oluita
                    placeholderText: qsTr("NO BEERS!")
                    placeholderColor: Theme.secondaryHighlightColor
                    width: sivu.width*0.33
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Theme.highlightColor
                    readOnly: true
                }

                TextField {
                    id: merkkeja
                    placeholderText: qsTr("No badges!")
                    width: sivu.width*0.33
                    placeholderColor: Theme.secondaryHighlightColor
                    readOnly: true
                    onClicked: {
                        if (text != "")
                            pageContainer.push(Qt.resolvedUrl("unTpAnsiomerkit.qml"), {
                                                              "kayttajaTunnus": kayttaja})
                    }
                }

            }

            Row { // kaverit
                spacing: (column.width - kavereita.width - seurattavia.width)
                visible: tilastotNakyvat

                TextField {
                    id: kavereita
                    placeholderText: qsTr("No friends!")
                    placeholderColor: Theme.secondaryHighlightColor
                    width: sivu.width*0.45
                    color: Theme.primaryColor
                    readOnly: true
                    onClicked: {
                        if (text != "") {
                            var uusi = pageContainer.push(Qt.resolvedUrl("unTpKaverit.qml"), {
                                                          "tunnus": kayttaja})
                            uusi.sulkeutuu.connect(function() {
                                if (uusi.tunnus != kayttaja) {
                                    kayttaja = uusi.tunnus;
                                    tyhjennaKentat();
                                    uTYhteys.lueKayttajanTiedot(kayttaja);
                                    uTYhteys.lueKayttajanKirjaukset(kayttaja, 0)
                                }

                                if (uusi._muuttunut) {
                                    uTYhteys.lueKayttajanTiedot(kayttaja);
                                }
                            })
                        }
                    }
                }

                TextField {
                    id: seurattavia
                    placeholderText: qsTr("None followed.")
                    placeholderColor: Theme.secondaryHighlightColor
                    color: Theme.highlightColor
                    readOnly: true
                    width: sivu.width*0.45
                }

            }

            Row { // muuta
                spacing: (column.width - luodutOluet.width - kuvia.width)
                visible: tilastotNakyvat

                TextField {
                    id: luodutOluet
                    placeholderText: qsTr("No beers created.")
                    placeholderColor: Theme.secondaryHighlightColor
                    color: Theme.highlightColor
                    readOnly: true
                    width: sivu.width*0.45
                }

                TextField {
                    id: kuvia
                    placeholderText: qsTr("No photos.")
                    placeholderColor: Theme.secondaryHighlightColor
                    width: sivu.width*0.45
                    color: Theme.highlightColor
                    readOnly: true
                }

            }

            // kirjaukset-lehti
            SilicaListView {
                id: kirjaukset
                height: (y < 0.5*sivu.height) ? sivu.height - y : 0.5*sivu.height
                width: sivu.width
                visible: !tilastotNakyvat
                clip: true

                model: UnTpKirjauslista {
                    id: kirjausLista
                }

                delegate: kirjaustyyppi

                // /*
                section {
                    property: "section"

                    delegate: SectionHeader {
                        text: section
                    }
                } // */

                onMovementEnded: {
                    if (atYEnd) {
                        var vikaKirjaus = kirjausLista.get(kirjausLista.count-1).checkinId
                        uTYhteys.lueKayttajanKirjaukset(kayttaja, vikaKirjaus - 1)
                    }
                }

                VerticalScrollDecorator {}
            }
        }

        VerticalScrollDecorator{}
    }

    Component.onCompleted: {
        if (UnTpd.unTpToken > ""){
            avaaKirjautumissivu = false
            haeKayttajatiedot = false
            uTYhteys.lueKayttajanTiedot(kayttaja)
            uTYhteys.lueKayttajanKirjaukset(kayttaja)
        }
    }

    Component.onDestruction: {
        sulkeutuu()
    }

}
