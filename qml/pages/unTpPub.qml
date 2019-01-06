import QtQuick 2.0
import QtQml 2.0
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu

    property bool vainKaverit: false
    property int uusinCheckin: 0 // max_int, uusimman haettavan tunnus. Ei rajoita, jos 0.
    property int hakujaSivulle: 0 // jos = 0, unTappdin oletusmäärä = 25, max 50
    property int valittu: 0
    property bool hakuvirhe: false
    property date pvm
    property var kirjaustenTiedot: []
    property bool ensimmainenHaku: true

    function haunAloitus() {
        hakuvirhe = false
        tyhjennaLista()
        uusinCheckin = 0

        return haeKirjauksia()
    }

    function haeKirjauksia() {
        var tulos

        if (vainKaverit)
            tulos = kirjauksiaLahistolla() //kaverienKirjauksia()
        else
            tulos = kirjauksiaLahistolla()

        return tulos
    }

    function lisaaListaan(kirjaus, bid, aika, kuva, kayttajatunnus, nimi, etiketti, olut,
                          panimo, baari, maljoja, kohotinko, huuto, jutteluita){

        return kirjausLista.append({"checkinId": kirjaus, "bid": bid, "section": aika,
                                       "osoite": kuva, "kayttajatunnus": kayttajatunnus,
                                       "tekija": nimi, "paikka": baari,
                                       "etiketti": etiketti, "olut": olut, "panimo": panimo,
                                       "maljoja": maljoja, "kohotinko": kohotinko,
                                       "huuto": huuto, "jutteluita": jutteluita })
    }

    function tyhjennaLista() {

        while (kirjaustenTiedot.length > 0){
            kirjaustenTiedot.pop()
        }

        console.log("kirjauksia " + kirjaustenTiedot.length)
        return kirjausLista.clear()
    }

    function kirjauksiaLahistolla() {
        var xhttp = new XMLHttpRequest();
        var lp, pp, sade=0, yksikko = "km"
        var kysely = "", vastaus

        hetkinen.running = true
        unTpdViestit.text = qsTr("posting query")

        if (paikkatieto.position.longitudeValid && paikkatieto.position.latitudeValid) {
            pp = paikkatieto.position.coordinate.longitude
            lp = paikkatieto.position.coordinate.latitude
        } else {
            /*
            if (!vainKaverit) {
                unTpdViestit.text = qsTr("Location not known. Can't search for nearby activity.")
                hakuvirhe = true
                hetkinen.running = false

                return 0
            }
            // */
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
                    console.log("kaverienKirjauksia: " + xhttp.status + ", " + xhttp.statusText)
                    console.log(xhttp.responseText)
                    hakuvirhe = true
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return xhttp.status
    }

    /*function kaverienKirjauksia() {
        var xhttp = new XMLHttpRequest();
        var kysely = "", vastaus

        hetkinen.running = true
        unTpdViestit.text = qsTr("posting query")

        kysely = UnTpd.getFriendsActivityFeed(uusinCheckin, 0, hakujaSivulle) // uusin, vanhin, per sivu

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
                //if(uusinCheckin > 0) console.log(xhttp.responseText)

                unTpdViestit.text = xhttp.statusText

                if (xhttp.status == 200) {
                    vastaus = JSON.parse(xhttp.responseText);
                    //console.log(xhttp.responseText)
                    hakuvirhe = false
                    paivitaLista(vastaus)
                } else {
                    console.log("kaverienKirjauksia: " + xhttp.status + ", " + xhttp.statusText)
                    hakuvirhe = true
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        //console.log(" kysely: " + kysely)

        return
    } // */

    function paivitaLista(vastaus) {
        var kirjatut = vastaus.response.checkins.items
        var i=0, n = vastaus.response.checkins.count
        var paivays = new Date(), kentta
        var kirjaus, bid, aikams, aika, kuva, nimi, etiketti, olut, panimo, baari,
                maljoja, omaMalja, jutteluita, kayttajatunnus, huuto

        if ( n === 0 && uusinCheckin === 0 ) {
            hakuvirhe = true
            if (!vainKaverit)
                unTpdViestit.text = qsTr("no check-ins nearby! ??")
            else
                unTpdViestit.text = qsTr("no activity")
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
            jutteluita = kirjatut[i].comments.count
            huuto = kirjatut[i].checkin_comment

            baari = ""
            for (kentta in kirjatut[i].venue) {
                //console.log("kentta " + kentta)
                if (kentta == "venue_name") {
                    //console.log(" == " + JSON.stringify(kirjatut[i].venue))
                    baari = kirjatut[i].venue.venue_name
                    //console.log(" == " + baari + " == ")
                }
            }

            /*console.log("" + i + "= " +  + kirjaus + ", " + aika + ", " + kuva + ", " + nimi
                        + "- " + bid + "- " + etiketti + "- " + olut + "; " + panimo + "; "
                        + maljoja + "; " + jutteluita + ", " + baari)// */
            //console.log("" + i + "= " + JSON.stringify(kirjatut[i]))
            lisaaListaan(kirjaus, bid, aika, kuva, kayttajatunnus, nimi, etiketti, olut, panimo,
                         baari, maljoja, omaMalja, huuto, jutteluita)

            //if (!ensimmainenHaku) {
                kirjaustenTiedot.push(kirjatut[i])
            //}

            i++
        }

        if (ensimmainenHaku) {
            //kirjaustenTiedot = kirjatut
            ensimmainenHaku = false
        }

        //console.log("kirjaustenTiedot " + kirjaustenTiedot.length + " " + kirjaustenTiedot[kirjaustenTiedot.length-3].beer.beer_name)
        return i
    }

    function unTpdKohota(jsonVastaus) {
        var onnistunut = jsonVastaus.response.result
        var maljoja, kentta

        //console.log("" + JSON.stringify(jsonVastaus))

        if (onnistunut)
            kirjausLista.set(valittu, {"maljoja": jsonVastaus.response.toasts.count})

        hetkinen.running = false

        return
    }

    function unTpJuttele(){
        //console.log("===\n===\n " + JSON.stringify(kirjaustenTiedot[valittu]))
        //console.log(" - - valittu = " + valittu)
        var viestisivu
        viestisivu = pageStack.push(Qt.resolvedUrl("unTpJuomispuheet.qml"),
                       { "kirjaus": kirjaustenTiedot[valittu] })
        viestisivu.sulkeutuu.connect( function() {
            if (viestisivu.viesteja != kirjausLista.get(valittu).jutteluita )
                kirjausLista.set(valittu,{"jutteluita":viestisivu.viesteja })
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
                console.log("tuntematon " + xhttp.readyState + ", " + xhttp.statusText)
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

    Timer {
        id: viestinNaytto
        interval: 2*1000
        running: false
        repeat: false
        onTriggered: {
            hetkinen.running = false
        }
    }

    PositionSource {
        id: paikkatieto
        active: true
        updateInterval: 5*60*1000 // 5 min
    }

    Component {
        id: kirjausTiedot

        ListItem {
            id: tietue
            width: sivu.width
            contentHeight: kirjaus.height + Theme.paddingMedium
            propagateComposedEvents: true
            onClicked: {
                valittu = kirjaukset.indexAt(mouseX,y+mouseY)
                console.log("__ " + valittu + ", hiiri " + mouseX.toFixed(1)
                            + " " + mouseY.toFixed(1) + " " +
                            (tietue.y).toFixed(1) )
                mouse.accepted = false
            }
            onPressAndHold: {
                valittu = kirjaukset.indexAt(mouseX,y+mouseY)
                mouse.accepted = false
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("user data")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("unTpKayttaja.qml"),{
                                        "kayttaja": kirjaus.kayttis } )
                    }
                }
                MenuItem {
                    text: qsTr("beer")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("unTpTietojaOluesta.qml"),{
                                        "olutId": kirjaus.olutId } )
                    }
                }
                MenuItem {
                    text: qsTr("toast")
                    onClicked: {
                        unTpdToast(kirjaus.tunnus)
                    }
                }
                MenuItem {
                    text: qsTr("comment")
                    onClicked: {                        
                        unTpJuttele()
                    }
                }

            }

            /*
            Rectangle {
                color: "transparent"
                border.color: Theme.secondaryColor
                border.width: 1
                radius: Theme.paddingMedium
                width: tietue.width - 2*x
                x: Theme.paddingMedium/2
                height: kirjaus.height
                //y: 0
            } // */

            UnTpKirjauksenKooste{
                id: kirjaus
                x: Theme.paddingSmall
                width: tietue.width - 2*x
                tunnus: checkinId
                olutId: bid
                kuva: osoite
                kayttis: kayttajatunnus
                juomari: tekija
                pubi: paikka
                tarra: etiketti
                kalja: olut
                valmistaja: panimo
                sanottu: huuto
                nostoja: maljoja                
                juttuja: jutteluita
                omaNosto: kohotinko

            }

            /*
            Column {
                id: kirjaus
                x: Theme.paddingLarge
                width: sivu.width - x

                Text {
                    id: kirjausId
                    visible: false
                    text: checkinId
                }

                Text {
                    id: oluenId
                    text: bid
                    visible: false
                }

                Row {// kuka, missä
                    spacing: Theme.paddingMedium

                    Image {
                        id: naama
                        source: osoite
                        height: Theme.fontSizeMedium*2.5
                        width: height
                    }

                    Column {
                        id: kuka
                        width: kirjaus.width - x - Theme.paddingSmall

                        Text {
                            id: kayttaja
                            text: kayttajatunnus
                            visible: false
                        }

                        Label {
                            text: tekija
                            color: Theme.highlightColor
                        }

                        Label {
                            text: paikka
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            width: kuka.width
                            color: Theme.secondaryHighlightColor
                        }

                    }

                }

                Row {// olut, kommentit
                    id: kirjattuOlut
                    //x: Theme.paddingLarge
                    spacing: Theme.paddingMedium
                    //x: Theme.paddingLarge

                    Image {
                        id: juomanEtiketti
                        source: etiketti
                        width: Theme.fontSizeMedium*3
                        height: width
                    }

                    Column {
                        id: mita
                        width: sivu.width - kirjattuOlut.x - x

                        Label {
                            text: olut
                            color: Theme.highlightColor
                            width: mita.width - Theme.paddingSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Label {
                            text: panimo
                            color: Theme.secondaryHighlightColor
                            width: mita.width - Theme.paddingSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Label {
                            text: huuto
                            color: Theme.highlightColor
                            font.bold: true
                            font.italic: true
                            width: mita.width - Theme.paddingSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Row {
                            spacing: Theme.paddingMedium

                            IconButton {
                                id: peukku
                                icon.source: "image://theme/icon-s-like"
                                highlighted: (maljoja > 0) ? true : false
                                height: peukkuja.height
                                //enabled: false
                                onClicked: {
                                    var ykoord = tietue.y + mouseY
                                    //valittu = kirjaukset.indexAt(mouseX, tietue.y + mouseY)
                                    unTpdToast(kirjausId.text)
                                }
                            }

                            Label {
                                id: peukkuja
                                text: maljoja
                                color: (maljoja > 0) ? Theme.secondaryHighlightColor : Theme.highlightColor
                            }

                            Rectangle {
                                height: 1
                                width: Theme.paddingLarge*2
                                color: "transparent"
                            }

                            IconButton {
                                id: kommentti
                                icon.source: "image://theme/icon-s-chat"
                                highlighted: (jutteluita > 0) ? true : false
                                height: kommentteja.height
                                //enabled: false
                                onClicked: {
                                    highlighted = !highlighted
                                    valittu = kirjaukset.indexAt(mouseX, tietue.y + mouseY)
                                    console.log("oo " + valittu + ", hiiri " + mouseX.toFixed(1)
                                                + " " + mouseY.toFixed(1) + " " +
                                                (tietue.y).toFixed(1) )
                                    unTpJuttele()
                                }

                                //anchors.top: (peukku.height > peukkuja.height) ? peukku.bottom : peukkuja.bottom
                                //anchors.left: peukku.left
                            }

                            Label {
                                id: kommentteja
                                text: jutteluita
                                color: (jutteluita > 0) ? Theme.highlightColor : Theme.secondaryHighlightColor
                                //anchors.top: (peukku.height > peukkuja.height) ? peukku.bottom : peukkuja.bottom
                                //anchors.left: peukkuja.left
                            }


                        }


                    }

                }

            }
            // */
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
                    haunAloitus()
            }

            MenuItem {
                text: vainKaverit? qsTr("check pubs nearby") : qsTr("check friends")
                onClicked: {
                    vainKaverit = !vainKaverit
                    haunAloitus()
                }
            }
        }

        Column {
            id: nakyma
            width: sivu.width

            PageHeader {
                title: vainKaverit ? qsTr("pints by friends") : qsTr("pints nearby")
            }

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

            SilicaListView {
                id: kirjaukset
                height: sivu.height - y
                width: sivu.width
                clip: true

                model: ListModel {
                    id: kirjausLista
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
                        haeKirjauksia()
                    }
                    //console.log("" + uusinCheckin)
                }

            }

        }
    }

    Component.onCompleted: {
        haeKirjauksia()
        console.log("tietoja >" + kirjaustenTiedot.length + "<")
    }
}
