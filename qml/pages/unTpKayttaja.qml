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
        return kirjaukset.clear()
    }

    function kirjaudu() {
        var sivu=pageStack.push(Qt.resolvedUrl("unTpKirjautuminen.qml"))
        sivu.muuttuu.connect( function() {
            if (UnTpd.unTpToken == ""){
                tyhjennaKentat()
            } else {
                lueKayttajanTiedot("")
            }
        })
        return
    }

    function kirjoitaKirjaukset(jsonVastaus) {
        var vastaus = jsonVastaus.response.checkins
        var id, bid, etiketti, merkki, lausahdus, maljoja, huutoja, baari
        var i=0, N = vastaus.count
        var kentta
        while (i < N) {
            lausahdus = ""
            baari = ""

            id = vastaus.items[i].checkin_id
            bid = vastaus.items[i].beer.bid
            etiketti = vastaus.items[i].beer.beer_label
            merkki = vastaus.items[i].beer.beer_name

            lausahdus = vastaus.items[i].checkin_comment

            if (lausahdus == "" ) {
                for (kentta in vastaus.items[i].venue) {
                    if (kentta == "venue_name") {
                        //console.log(merkki + " - " + vastaus.items[i].venue.venue_name)
                        baari = vastaus.items[i].venue.venue_name
                    } else {
                        //console.log(merkki + " + " + kentta)
                    }
                }
                if (baari != "")
                    lausahdus = baari
                else
                    lausahdus = vastaus.items[i].brewery.brewery_name
            }

            maljoja = vastaus.items[i].toasts.count
            huutoja = vastaus.items[i].comments.count
            lisaaListaan(id, bid, etiketti, merkki, lausahdus, maljoja, huutoja)
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

    function lisaaListaan(id, bid, etiketti, merkki, lausahdus, maljoja, huutoja) {
        //var maljoja = qsTr("%1 toasts").arg(mal), huutoja = qsTr("%1 comments").arg(huu)
        //console.log("" + id + ", " + etiketti + ", " + merkki + ", " + lausahdus + ", " + maljoja + ", " + huutoja)

        return kirjaukset.append({"checkinId": id, "bid": bid, "etiketti": etiketti, "oluenMerkki": merkki,
                          "lausahdus": lausahdus, "maljoja": maljoja, "huutoja": huutoja })
    }

    function lueKayttajanTiedot(tunnus) { // jos tunnus = "" hakee käyttäjän tiedot
        var xhttp = new XMLHttpRequest();
        var kysely = UnTpd.getUserInfo(tunnus,"true");
        var async = true, sync = false;

        hetkinen.running = true

        xhttp.onreadystatechange = function() {
            console.log("lueKayttajanTiedot - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){
                var vastaus = JSON.parse(xhttp.responseText);

                if (xhttp.status == 200) {
                    //console.log(xhttp.responseText)
                    kirjoitaTiedot(vastaus)
                } else if (xhttp.status == 500) {
                    nimi.text = vastaus.meta.error_detail
                } else {
                    nimi.text = qsTr("user info: ") + xhttp.status + ", " + xhttp.statusText
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
            console.log("lueKayttajanKirjaukset - " + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 4){
                var vastaus = JSON.parse(xhttp.responseText);

                if (xhttp.status == 200) {
                    kirjoitaKirjaukset(vastaus)
                } else if (xhttp.status == 500) {
                    //nimi.text = vastaus.meta.error_detail
                } else {
                    //nimi.text = qsTr("user info: ") + xhttp.status + ", " + xhttp.statusText
                }

                hetkinen.running = false
            }
        }
        xhttp.open("GET",kysely,async);
        xhttp.send();

        //console.log("unTpKirjautuminen - lueKayttajanTiedot - xhttp.responseText")

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
            id: listanOsa
            contentHeight: alkioSarake.height + Theme.paddingSmall
            width: sivu.width
            menu: ContextMenu {
                //MenuItem {
                  //  text: qsTr("toast")
                    //onClicked: {
                        //toast(kirjausId.text)
                    //}
                //}
                //MenuItem {
                  //  text: qsTr("comment")
                    //onClicked: {
                        //comment(kirjausId.text)
                    //}
                //}
                MenuItem {
                    text: qsTr("beer info")
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("unTpTietojaOluesta.qml"),{
                                        "olutId": oluenId.text } )
                    }
                }
            }

            Row {
                spacing: Theme.paddingSmall
                x: Theme.paddingLarge

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

                Image {
                    id: listanEtiketti
                    source: etiketti
                    height: oluenNimi.height + oluenPanimo.height
                    width: height
                    //x: Theme.paddingLarge
                    //y: 2
                }

                    Column {
                        id: alkioSarake

                        Label{
                            id: oluenNimi
                            text: oluenMerkki
                            color: Theme.highlightColor
                            x: Theme.paddingMedium
                        }

                        Label{
                            id: oluenPanimo
                            text: lausahdus
                            color: Theme.secondaryHighlightColor
                            x: Theme.paddingMedium
                        }

                        /*
                        TextField {
                            id: oluenTiedot
                            text: oluenMerkki
                            readOnly: true
                            color: Theme.highlightColor
                            label: lausahdus
                            width: sivu.width - x
                            onClicked: {
                                listanOsa.menuOpen
                                mouse.accepted = false
                            }
                            onPressAndHold: {
                                listanOsa.menuOpen
                                mouse.accepted = false
                            }

                            //anchors.left: listanEtiketti.right
                            //anchors.right: peukku.left
                            //y: 2
                        } // */

                        Row {
                            spacing: Theme.paddingMedium
                            IconButton {
                                id: peukku
                                icon.source: "image://theme/icon-s-like"
                                highlighted: (maljoja > 0) ? true : false
                                height: peukkuja.height
                                enabled: false
                                onClicked: {
                                    //toast(kirjausId.text)
                                }

                                //anchors.right: peukkuja.left
                                //y: 2
                            }

                            Label {
                                id: peukkuja
                                text: maljoja
                                color: Theme.highlightDimmerColor
                                //color: (maljoja > 0) ? Theme.secondaryHighlightColor : Theme.highlightColor
                                //x: listanOsa.width - ( (width > kommentteja.width) ? width : kommentteja.width ) - Theme.paddingLarge
                                //y: 2
                            }

                            Rectangle {
                                height: 1
                                width: Theme.paddingLarge*2
                                color: "transparent"
                            }

                            IconButton {
                                id: kommentti
                                icon.source: "image://theme/icon-s-chat"
                                highlighted: (huutoja > 0) ? true : false
                                height: kommentteja.height
                                enabled: false
                                onClicked: {
                                    highlighted = !highlighted
                                    //comment(kirjausId.text)
                                }

                                //anchors.top: (peukku.height > peukkuja.height) ? peukku.bottom : peukkuja.bottom
                                //anchors.left: peukku.left
                            }

                            Label {
                                id: kommentteja
                                text: huutoja
                                color: Theme.highlightDimmerColor
                                //color: (huutoja > 0) ? Theme.highlightColor : Theme.secondaryHighlightColor
                                //anchors.top: (peukku.height > peukkuja.height) ? peukku.bottom : peukkuja.bottom
                                //anchors.left: peukkuja.left
                            }


                        }

                    }

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

                Image {
                    id: kuva2
                    width: sivu.width
                    //anchors.bottomMargin: Theme.paddingMedium
                    //height: width
                    source: ""
                }

                /*
                TextField {
                    id: nimi
                    //width: parent.width/3
                    //label: qsTr("username")
                    //text: kayttaja
                    placeholderText: qsTr("unidentified")
                    placeholderColor: Theme.secondaryHighlightColor
                    color: Theme.highlightColor
                    readOnly: true
                    qsTr("unidentified")
                } // */

                Label {
                    id: nimi
                    text: qsTr("unidentified")
                    color: Theme.secondaryHighlightColor
                    x: Theme.paddingLarge
                    y: logo.height - height - Theme.paddingMedium
                }

                Image {
                    id: kuva1
                    width: Theme.fontSizeMedium*3//sivu.width/3
                    anchors.bottom: nimi.bottom
                    x: sivu.width - width - Theme.paddingLarge
                    height: width
                    source: ""
                    visible: false
                }
                OpacityMask{
                    anchors.fill: kuva1
                    source: kuva1
                    maskSource: kuva1
                }

            }

            Row { // alaotsikot
                height: tilastot.height// + Theme.paddingLarge
                //anchors.topMargin: Theme.paddingMedium
                x: (sivu.width - tilastot.width - juodut.width)/3
                spacing: x
                width: sivu.width - 2*x

                Label {
                    id: tilastot
                    text: qsTr("statistics")
                    color: tilastotNakyvat ? Theme.highlightColor : Theme.secondaryHighlightColor
                    font.pixelSize: tilastotNakyvat ? Theme.fontSizeLarge : Theme.fontSizeMedium
                    leftPadding: Theme.paddingMedium
                    topPadding: Theme.paddingMedium
                    bottomPadding: Theme.paddingSmall

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
                    color: tilastotNakyvat ? Theme.secondaryHighlightColor : Theme.highlightColor
                    font.pixelSize: tilastotNakyvat ? Theme.fontSizeMedium : Theme.fontSizeLarge
                    leftPadding: Theme.paddingMedium
                    topPadding: Theme.paddingMedium
                    bottomPadding: Theme.paddingSmall

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            tilastotNakyvat = false
                        }
                    }
                }
            }

            TextField {
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
                            pageStack.push(Qt.resolvedUrl("unTpAnsiomerkit.qml"))
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
                            var uusi = pageStack.push(Qt.resolvedUrl("unTpKaverit.qml"), {"tunnus": kayttaja})
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

            SilicaListView {
                id: kirjauslista
                height: sivu.height - y
                width: sivu.width
                visible: !tilastotNakyvat
                clip: true

                model: ListModel {
                    id: kirjaukset
                }

                delegate: kirjaustyyppi

                onMovementEnded: {
                    if (atYEnd) {
                        var vikaKirjaus = kirjaukset.get(kirjaukset.count-1).checkinId
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
