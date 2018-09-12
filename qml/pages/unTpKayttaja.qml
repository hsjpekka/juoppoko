import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd
import "../scripts/tietokanta.js" as Tkanta

Dialog {
    id: sivu

    property string kayttaja: ""
    property bool avaaKirjautumissivu: true
    property bool haeKayttajatiedot: true

    function tyhjennaKentat() {
        nimi.text = ""
        nimi.label = ""
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

        return
    }

    function kirjoitaTiedot(jsonVastaus){
        var vastaus = jsonVastaus.response
        if (vastaus.user.first_name + vastaus.user.last_name != ""){
            nimi.label = vastaus.user.user_name
            nimi.text = vastaus.user.first_name + " " + vastaus.user.last_name
        } else
            nimi.text = vastaus.user.user_name

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
            merkkeja.color = Theme.highlightColor
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

    function lueKayttajanTiedot(tunnus) { // jos tunnus == "" hakee käyttäjän tiedot
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

    function kirjaudu() {
        unTpTarkistus.repeat = true
        unTpTarkistus.start()
        pageStack.push(Qt.resolvedUrl("unTpKirjautuminen.qml"))
        return
    }

    function tarkistaUnTp() {
        if (UnTpd.unTpToken != "")
            lueKayttajanTiedot("")
        else
            tyhjennaKentat()
        return
    }

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
    }

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

    SilicaFlickable{
        height: sivu.height
        contentHeight: column.height
        width: sivu.width
        anchors.fill: sivu

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

            Row {

                TextField {
                    id: nimi
                    //width: parent.width/3
                    label: qsTr("username")
                    //text: kayttaja
                    placeholderText: qsTr("unidentified")
                    readOnly: true
                }

                Image {
                    id: kuva1
                    width: Theme.fontSizeMedium*3//sivu.width/3
                    y: nimi.y + 0.5*(nimi.height - height)
                    height: width
                    source: ""
                }

                /*
                Image {
                    id: kuva2
                    width: sivu.width/3
                    height: width
                    source: ""
                }// */

            } //kayttaja-rivi

            TextField {
                id: kuvaus
                width: sivu.width
                placeholderText: qsTr("No biograph.")
                readOnly: true
            }

            Row {
                spacing: (column.width - kirjauksia.width - oluita.width - merkkeja.width)/2
                TextField {
                    id: kirjauksia
                    placeholderText: qsTr("No checkins!")
                    width: sivu.width*0.33
                    readOnly: true
                }

                TextField {
                    id: oluita
                    placeholderText: qsTr("NO BEERS!")
                    width: sivu.width*0.33
                    horizontalAlignment: TextInput.AlignHCenter
                    readOnly: true
                }

                TextField {
                    id: merkkeja
                    placeholderText: qsTr("No badges!")
                    width: sivu.width*0.33
                    readOnly: true
                    onClicked: {
                        if (text != "")
                            pageStack.push(Qt.resolvedUrl("unTpAnsiomerkit.qml"))
                    }
                }

            }

            Row {
                spacing: (column.width - kavereita.width - seurattavia.width)

                TextField {
                    id: kavereita
                    placeholderText: qsTr("No friends!")
                    width: sivu.width*0.45
                    readOnly: true
                }

                TextField {
                    id: seurattavia
                    placeholderText: qsTr("None followed.")
                    readOnly: true
                    width: sivu.width*0.45
                }

            }

            Row {
                spacing: (column.width - luodutOluet.width - kuvia.width)

                TextField {
                    id: luodutOluet
                    placeholderText: qsTr("No beers created.")
                    readOnly: true
                    width: sivu.width*0.45
                }

                TextField {
                    id: kuvia
                    placeholderText: qsTr("No photos.")
                    width: sivu.width*0.45
                    readOnly: true
                }

            }

            Image {
                id: kuva2
                width: sivu.width - 2*Theme.paddingLarge
                //anchors.bottomMargin: Theme.paddingMedium
                //height: width
                x: 0.5*(sivu.width - width)                
                source: ""
            }

            Rectangle{
                height: Theme.paddingMedium
                width: kuva2.width
                color: "transparent"
                border.color: "transparent"
            }

            Button {
                id: nappi
                //anchors.topMargin: Theme.paddingMedium
                text: (UnTpd.unTpToken == "") ? qsTr("sign in") : qsTr("change user")
                x: 0.5*(sivu.width - width)
                onClicked: {
                    if (UnTpd.unTpToken != "") {
                        UnTpd.unTpToken = ""
                        Tkanta.paivitaAsetus2(Tkanta.tunnusUnTappdToken, "")
                    }
                    //console.log("reset-nappi 1 - " + webView.url)
                    kirjaudu()
                }
            }

        }

        VerticalScrollDecorator{}
    }
    Component.onCompleted: {
        if (UnTpd.unTpToken != ""){
            avaaKirjautumissivu = false
            haeKayttajatiedot = false
            lueKayttajanTiedot(kayttaja)
        }
    }

}
