import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd
import "../scripts/tietokanta.js" as Tkanta

Page {
    id: sivu

    signal sulkeutuu

    property string kayttaja: ""
    property bool avaaKirjautumissivu: true
    property bool haeKayttajatiedot: true
    property bool tilastotNakyvat: false
    property date pvm
    property int valittu

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

        //vaihdos.text = qsTr("sign in")
        tyhjennaKirjaukset()

        return
    }

    function tyhjennaKirjaukset() {
        return kirjausLista.clear()
    }

    function kirjaudu() {
        var sivu=pageStack.push(Qt.resolvedUrl("unTpKirjautuminen.qml"))
        sivu.muuttuu.connect( function() {
            tyhjennaKentat()
            if (UnTpd.unTpToken != ""){
                kayttaja = ""
                lueKayttajanTiedot(kayttaja)
                lueKayttajanKirjaukset(kayttaja, 0)
            }
        })
        return
    }

    function kirjoitaKirjaukset(jsonVastaus) {
        var vastaus = jsonVastaus.response.checkins
        //var kirjaus = jsonVastaus.response.checkins.items
        var id, aika = "", bid, etiketti, merkki, lausahdus, maljoja, omaMalja, huutoja, baari,
                panimo, osallistunut
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

            //if (lausahdus == "" ) {
            for (kentta in vastaus.items[i].venue) {
                if (kentta == "venue_name") {
                    //console.log(merkki + " - " + vastaus.items[i].venue.venue_name)
                    baari = vastaus.items[i].venue.venue_name
                } else {
                        //console.log(merkki + " + " + kentta)
                }
            }
                //if (baari != "")
                    //lausahdus = baari
                //else
            panimo = vastaus.items[i].brewery.brewery_name
            //}

            maljoja = vastaus.items[i].toasts.count
            omaMalja = vastaus.items[i].toasts.auth_toast
            huutoja = vastaus.items[i].comments.count
            osallistunut = olenkoJutellut(vastaus.items[i].comments)
            lisaaListaan(id, aika, bid, baari, etiketti, merkki, panimo, lausahdus, maljoja,
                         omaMalja, huutoja, vastaus.items[i].comments, osallistunut)
            i++
        }
    }

    function kirjoitaTiedot(jsonVastaus){
        var vastaus = jsonVastaus.response

        otsikko.title = vastaus.user.user_name + " @UnTappd"
        nimi.text = vastaus.user.first_name + " " + vastaus.user.last_name
        nimi.color = Theme.highlightColor

        kuva1.source = vastaus.user.user_avatar
        kuva2.source = vastaus.user.user_cover_photo

        if (vastaus.user.bio != "") {
            kuvaus.text = vastaus.user.bio
            kuvaus.label = vastaus.user.location + vastaus.user.url
        } else {
            kuvaus.text = vastaus.user.url
            kuvaus.label = vastaus.user.location
        }

        if (vastaus.user.stats.total_badges > 0){
            merkkeja.text = qsTr("badges") + " ..."
            merkkeja.color = Theme.primaryColor
        }
        merkkeja.label = vastaus.user.stats.total_badges

        if (vastaus.user.stats.total_friends > 0)
            kavereita.text = qsTr("friends")
        kavereita.label = vastaus.user.stats.total_friends

        if (vastaus.user.stats.total_checkins > 0)
            kirjauksia.text = qsTr("checkins")
        kirjauksia.label = vastaus.user.stats.total_checkins

        if (vastaus.user.stats.total_beers > 0)
            oluita.text = qsTr("beers")
        oluita.label = vastaus.user.stats.total_beers

        if (vastaus.user.stats.total_created_beers > 0)
            luodutOluet.text = qsTr("beers created")
        luodutOluet.label = vastaus.user.stats.total_created_beers

        if (vastaus.user.stats.total_photos > 0)
            kuvia.text = qsTr("photos")
        kuvia.label = vastaus.user.stats.total_photos

        if (vastaus.user.stats.total_followings > 0)
            seurattavia.text = qsTr("followed")
        seurattavia.label = vastaus.user.stats.total_followings

        //Tkanta.paivitaAsetus2(Tkanta.tunnusUnTappdToken, UnTpd.unTpToken)
    }

    function lisaaListaan(id, aika, bid, baari, etiketti, merkki, panimo, lausahdus, maljoja,
                          kohotinko, huutoja, keskustelu, jutellut) {
        //var maljoja = qsTr("%1 toasts").arg(mal), huutoja = qsTr("%1 comments").arg(huu)
        //console.log("" + id + ", " + etiketti + ", " + merkki + ", " + lausahdus + ", " + maljoja + ", " + huutoja)

        return kirjausLista.append({"section": aika, "checkinId": id, "bid": bid, "paikka": baari,
                                     "etiketti": etiketti, "oluenMerkki": merkki,
                                     "panimo": panimo, "lausahdus": lausahdus,
                                     "maljoja": maljoja, "nostinko": kohotinko,
                                     "huutoja": huutoja, "jutut": keskustelu,
                                     "mukana": jutellut
                                 })
    }

    function lueKayttajanTiedot(tunnus) { // jos tunnus = "" hakee käyttäjän tiedot
        var xhttp = new XMLHttpRequest();
        var kysely = UnTpd.getUserInfo(tunnus,"true");
        var async = true, sync = false;
        var vastaus

        hetkinen.running = true

        xhttp.onreadystatechange = function() {
            console.log("lueKayttajanTiedot - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){

                if (xhttp.status == 200) {
                    vastaus = JSON.parse(xhttp.responseText);
                    //console.log(xhttp.responseText)
                    kirjoitaTiedot(vastaus)
                } else {
                    console.log(xhttp.responseText)
                    if (xhttp.status == 500) {
                        nimi.text = vastaus.meta.error_detail
                    } else {
                        nimi.text = qsTr("user info: ") + xhttp.status + ", " + xhttp.statusText
                    }
                }

                hetkinen.running = false
            }
        }
        xhttp.open("GET",kysely,async);
        xhttp.send();

        //console.log("unTpKirjautuminen - lueKayttajanTiedot - xhttp.responseText")

    }

    function lueKayttajanKirjaukset(tunnus, eka) { // jos tunnus = "" hakee käyttäjän tiedot
        var xhttp = new XMLHttpRequest();
        var kysely = UnTpd.getUserFeed(tunnus, eka, 0, 0);
        var async = true, sync = false;

        //hetkinen.running = true

        xhttp.onreadystatechange = function() {
            //console.log("lueKayttajanKirjaukset - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){
                var vastaus = JSON.parse(xhttp.responseText);

                if (xhttp.status == 200) {
                    kirjoitaKirjaukset(vastaus)
                } else {
                    console.log(JSON.stringify(vastaus))
                }

                hetkinen.running = false

            }
        }
        xhttp.open("GET",kysely,async);
        xhttp.send();

        //console.log("unTpKirjautuminen - lueKayttajanTiedot - xhttp.responseText")

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

    function unTpdKohota(jsonVastaus) {
        var onnistunut = jsonVastaus.response.result
        var maljoja, kentta

        //console.log("> toast >\n" + JSON.stringify(jsonVastaus) + "\n< toast <")

        if (onnistunut) {
            kirjausLista.set(valittu, {"maljoja": jsonVastaus.response.toasts.count,
                               "nostinko": jsonVastaus.response.toasts.auth_toast
                           })
        }

        hetkinen.running = false

        return
    }

    function unTpdJuttele(){
        //console.log("===\n===\n " + JSON.stringify(kirjaustenTiedot[valittu]))
        //console.log(" - - valittu = " + valittu)
        var viestisivu, solu = kirjausLista.get(valittu)

        viestisivu = pageStack.push(Qt.resolvedUrl("unTpJuomispuheet.qml"), {
                                        "keskustelu": solu.jutut,
                                        //"viesteja": solu.huutoja,
                                        "user_avatar": kuva1.source, //solu.osoite
                                        "user_name": nimi.text,
                                        "venue_name": solu.paikka,
                                        "beer_label": solu.etiketti,
                                        "beer_name": solu.olut,
                                        "brewery_name": solu.panimo,
                                        "checkin_comment": solu.lausahdus,
                                        "ckdId": solu.checkinId
                                    })
        viestisivu.sulkeutuu.connect( function() {
            //console.log("sulkeutuu " + valittu + ", << " + viestisivu.viesteja + " >> "
            //            + viestisivu.keskustelu.count)
            kirjausLista.set(valittu,{"huutoja": viestisivu.viesteja,
                                 "jutut": viestisivu.keskustelu})
            if (olenkoJutellut(viestisivu.keskustelu)) {
                kirjausLista.set(valittu,{"mukana": true})
            } else {
                kirjausLista.set(valittu,{"mukana": false})
            }
        })

        return
    }

    function unTpdToast(ckId) {
        var xhttp = new XMLHttpRequest()
        var osoite = "", vastaus

        hetkinen.running = true

        osoite = UnTpd.toast(ckId)

        xhttp.onreadystatechange = function () {
            //console.log("checkIN - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){

                if (xhttp.status == 200) {
                    vastaus = JSON.parse(xhttp.responseText);

                    unTpdKohota(vastaus)

                } else {
                    console.log(xhttp.readyState + ", " + xhttp.statusText)
                }

            }

        }

        //unTpdViestit.text = qsTr("posting query")
        xhttp.open("POST", osoite, false)
        xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
        xhttp.send("");

        return
    }

    /*
    function tarkistaUnTp() {
        if (UnTpd.unTpToken != "")
            lueKayttajanTiedot("")
        else
            tyhjennaKentat()
        return
    }// */

    /*
    Timer {
        id: unTpTarkistus
        interval: 1*1000
        repeat: true
        running: false
        onTriggered: {
            if (sivu.status === PageStatus.Active || sivu.status === PageStatus.Activating) {
                repeat = false
                tarkistaUnTp()
            }
            //console.log("untptarkistus")
        }
    } // */

    Timer {
        id: alkuviivastys
        interval: 1*1000
        running: true
        repeat: true
        onTriggered: {
            repeat = avaaKirjautumissivu //|| haeKayttajatiedot
            if (avaaKirjautumissivu && (!pageStack.busy)){
                avaaKirjautumissivu = false
                kirjaudu()
                haeKayttajatiedot = true
            }
            //if ((UnTpd.unTpToken != "") && haeKayttajatiedot){
              //  lueKayttajanTiedot(kayttaja)
                //haeKayttajatiedot = false
            //}

        }
    }

    Component {
        id: kirjaustyyppi

        ListItem {
            id: tietue
            //contentHeight: alkioSarake.height + Theme.paddingMedium
            contentHeight: kirjaus.height + Theme.paddingMedium
            width: sivu.width
            onClicked: {
                console.log("valittu " + valittu)
                valittu = kirjaukset.indexAt(mouseX,y+mouseY)
                console.log("valittu taas " + valittu)
                mouse.accepted = false
            }
            onPressAndHold: {
                valittu = kirjaukset.indexAt(mouseX,y+mouseY)
                mouse.accepted = false
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("beer info")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("unTpTietojaOluesta.qml"),{
                                        "olutId": kirjaus.olutId } )
                    }
                }
                MenuItem {
                    text: kirjaus.omaNosto? qsTr("untoast") : qsTr("toast")
                    onClicked: {
                        unTpdToast(kirjaus.tunnus)
                    }
                }
                MenuItem {
                    text: qsTr("comment")
                    onClicked: {
                        unTpdJuttele() //kirjaus.tunnus
                    }
                }
            }

            UnTpKirjauksenKooste{
                id: kirjaus
                x: Theme.paddingSmall
                width: tietue.width - 2*x
                tunnus: checkinId
                olutId: bid
                naytaTekija: false
                //kuva: osoite
                //kayttis: kayttajatunnus
                //juomari: tekija
                pubi: paikka //
                tarra: etiketti
                kalja: oluenMerkki
                valmistaja: panimo //
                sanottu: lausahdus
                nostoja: maljoja
                omaNosto: nostinko
                juttuja: huutoja
                keskustelu: jutut
                osallistunut: mukana

            }

        }
    }

    SilicaFlickable{
        height: sivu.height
        contentHeight: column.height
        width: sivu.width
        anchors.fill: sivu

        PullDownMenu{

            MenuItem {
                id: vaihdos
                text: (UnTpd.unTpToken == "") ? qsTr("sign in") : qsTr("change user")
                onClicked: {
                    kirjaudu()
                }
            }

            MenuItem {
                text: qsTr("read my data")
                visible: (kayttaja != "" && UnTpd.unTpToken != "") ? true : false
                onClicked: {
                    kayttaja = ""
                    tyhjennaKentat()
                    lueKayttajanTiedot(kayttaja)
                    lueKayttajanKirjaukset(kayttaja, 0)
                }
            }

            MenuItem {
                text: "token"
                onClicked: {
                    UnTpd.unTpToken = "635B17D71F4E672C48705161948BDCE5A92F6F0C"
                    Tkanta.paivitaAsetus2(Tkanta.tunnusUnTappdToken, UnTpd.unTpToken)
                }
            }

        }

        Column {
            id: column
            width: sivu.width

            PageHeader {
                id: otsikko
                title: qsTr("UnTappd account")
            }

            BusyIndicator {
                id: hetkinen
                size: BusyIndicatorSize.Medium
                x: 0.5*(sivu.width - width)
                running: false
                visible: running
            }

            Item {
                id: logo
                width: sivu.width
                height: (kuva2.height > kuva1.height + Theme.paddingLarge) ? kuva2.height : kuva1.height + Theme.paddingLarge
                //x: 0.5*(sivu.width - width)

                Image { //taustakuva
                    id: kuva2
                    width: sivu.width
                    fillMode: Image.PreserveAspectFit
                    //anchors.bottomMargin: Theme.paddingMedium
                    //height: width
                    source: ""
                }

                Label {
                    id: nimi
                    text: qsTr("unidentified")
                    color: Theme.secondaryHighlightColor
                    x: Theme.paddingLarge
                    y: logo.height - height - Theme.paddingMedium
                }

                Image { //naama
                    id: kuva1
                    width: Theme.fontSizeMedium*3//sivu.width/3
                    anchors.bottom: nimi.bottom
                    x: sivu.width - width - Theme.paddingLarge
                    height: width
                    source: ""
                    //visible: false
                }
                //OpacityMask{
                //    anchors.fill: kuva1
                //    source: kuva1
                //    maskSource: kuva1
                //}

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
                            pageStack.push(Qt.resolvedUrl("unTpAnsiomerkit.qml"), {
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
                            var uusi = pageStack.push(Qt.resolvedUrl("unTpKaverit.qml"), {
                                                          "tunnus": kayttaja})
                            uusi.sulkeutuu.connect(function() {
                                if (uusi.tunnus != kayttaja) {
                                    kayttaja = uusi.tunnus
                                    tyhjennaKentat()
                                    lueKayttajanTiedot(kayttaja)
                                    lueKayttajanKirjaukset(kayttaja, 0)
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

                model: ListModel {
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
                        lueKayttajanKirjaukset(kayttaja, vikaKirjaus - 1)
                    }
                }

                VerticalScrollDecorator {}
            }
        }

        VerticalScrollDecorator{}
    }

    Component.onCompleted: {
        if (UnTpd.unTpToken != ""){
            avaaKirjautumissivu = false
            haeKayttajatiedot = false
            lueKayttajanTiedot(kayttaja)
            lueKayttajanKirjaukset(kayttaja, 0)
        }
    }

    Component.onDestruction: {
        sulkeutuu()
    }

}
