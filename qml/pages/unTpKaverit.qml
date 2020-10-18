import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu

    property string ilmoitukset: ""
    property string tunnus: "" //username
    property bool   _pyynnot: false
    //property int haku: 0
    //property int haettavia: 25
    //property bool hakuvirhe: false

    signal sulkeutuu

    /*
    function qqhaeKavereita() {
        var xhttp = new XMLHttpRequest();
        var kysely = ""

        hetkinen.running = true
        unTpdViestit.text = qsTr("posting query")

        kysely = UnTpd.getFriendsInfo(tunnus, haku*haettavia, haettavia)

        xhttp.onreadystatechange = function () {
            //console.log("haeKavereita - " + xhttp.readyState + " - " + xhttp.status + " , " + hakunro)
            if (xhttp.readyState == 0)
                unTpdViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
            else if (xhttp.readyState == 1)
                unTpdViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
            else if (xhttp.readyState == 2)
                unTpdViestit.text = qsTr("request received") + ", " + xhttp.statusText
            else if (xhttp.readyState == 3)
                unTpdViestit.text = qsTr("processing request") + ", " + xhttp.statusText
            else { //if (xhttp.readyState == 4){
                //console.log(xhttp.responseText)
                var vastaus = JSON.parse(xhttp.responseText);

                unTpdViestit.text = xhttp.statusText

                if (xhttp.status == 200) {
                    //console.log(xhttp.responseText)
                    hakuvirhe = false
                    paivitaHaetut(vastaus)
                } else {
                    console.log("search friends: " + xhttp.status + ", " + xhttp.statusText)
                    hakuvirhe = true
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)

        return xhttp.send()
    }
    // */

    function paivitaHaetut(olio, toiminta) { // vastaus = JSON(unTappd-vastaus)
        var i=0, vastaus, kuva, nimi, sijainti, kayttaja, hkId

        vastaus = olio.response
        while (i < vastaus.count) {
            kuva = vastaus.items[i].user.user_avatar
            nimi = vastaus.items[i].user.first_name + " "
                    + vastaus.items[i].user.last_name
            kayttaja = vastaus.items[i].user.user_name
            sijainti = vastaus.items[i].user.location
            hkId = vastaus.items[i].user.uid
            if (toiminta === "pyynnot")
                pyytajat.lisaa(kuva, nimi, sijainti, kayttaja, hkId)
            else
                loydetytKaverit.lisaa(kuva, nimi, sijainti, kayttaja, hkId)
            i++
        }

        console.log(toiminta + " " + vastaus.count)
        console.log(toiminta + " " + JSON.stringify(vastaus))

        return
    }

    ListModel {
        id: loydetytKaverit
        function lisaa(kuva, nimi, sijainti, kayttaja, hkId){
            return append({ "kuva": kuva, "nimi": nimi, "sijainti": sijainti,
                              "kayttaja": kayttaja, "hId": hkId })
        }
    }

    ListModel {
        id: pyytajat
        function lisaa(kuva, nimi, sijainti, kayttaja, hkId){
            return append({ "kuva": kuva, "nimi": nimi, "sijainti": sijainti,
                              "kayttaja": kayttaja, "hId": hkId })
        }
    }

    Component {
        id: kaveri
        ListItem {
            id: henkilo
            width: sivu.width
            contentHeight: tiedot.height + 4
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("accept request")
                    visible: _pyynnot
                    onClicked: {
                        var tama = kaverilista.indexAt(henkilo.x + mouseX, henkilo.y + mouseY)
                        console.log("nro " + tama)
                        peru.execute(henkilo, qsTr("accepting"), function () {
                            uTYhteys.hyvaksyKaveriksi(henkilo.kId)
                            loydetytKaverit.lisaa(naama.source, tiedot.text, tiedot.label,
                                                  henkilo.ktunnus, henkilo.kId)
                            pyytajat.remove(tama)
                        } )
                    }
                }
                MenuItem {
                    text: qsTr("reject request")
                    visible: _pyynnot
                    onClicked: {
                        var tama = kaverilista.indexAt(henkilo.x + mouseX, henkilo.y + mouseY)
                        console.log("nro " + tama)
                        peru.execute(henkilo, qsTr("rejecting"), function () {
                            uTYhteys.hylkaaPyynto(henkilo.kId)
                            pyytajat.remove(tama)
                        } )
                    }
                }
                MenuItem {
                    text: qsTr("show info")
                    visible: _pyynnot
                    onClicked: {
                        pageContainer.push(Qt.resolvedUrl("unTpKayttaja.qml"), {
                                    "kayttaja": henkilo.ktunnus })
                    }
                }
                MenuItem {
                    text: qsTr("remove friend")
                    visible: !_pyynnot
                    onClicked: {
                        var tama = kaverilista.indexAt(henkilo.x + mouseX, henkilo.y + mouseY)
                        console.log("nro " + tama)
                        peru.execute(henkilo, qsTr("removing friendship"), function () {
                            uTYhteys.poistaKaveri(henkilo.kId)
                            loydetytKaverit.remove(tama)
                        } )
                    }
                }
            }
            onClicked: toiminto()

            RemorseItem {
                id: peru
            }

            property string ktunnus: kayttaja
            property string kId: hId

            function toiminto() {
                if (!_pyynnot) {
                    tunnus = henkilo.ktunnus;
                    pageContainer.pop()
                } else {
                    //henkilo.openMenu()
                }

                return
            }

            Row {
                x: Theme.horizontalPageMargin
                width: sivu.width - x*2
                spacing: Theme.paddingMedium

                Image {
                    id: naama
                    source: kuva
                    height: tiedot.height
                    width: height
                }

                TextField {
                    id: tiedot
                    text: nimi
                    label: sijainti
                    readOnly: true
                    color: Theme.primaryColor
                    onClicked: {
                        henkilo.toiminto()
                    }
                    onPressAndHold: henkilo.openMenu()
                }
            }
        }
    }

    XhttpYhteys {
        id: uTYhteys
        anchors.top: parent.top
        z: 1
        onValmis: {
            var jsonVastaus, mj;
            try {
                jsonVastaus = JSON.parse(httpVastaus);
                if (toiminto === "kaverit" || toiminto === "pyynnot") {
                    paivitaHaetut(jsonVastaus, toiminto)
                } else {
                    if ("result" in jsonVastaus.response) {
                        if (jsonVastaus.response.result === "success") {
                            if (toiminto === "hyvaksy") {
                                mj = qsTr("friend request accepted")
                            }
                            if (toiminto === "hylkaa") {
                                mj = qsTr("friend request rejected")
                            }
                            if (toiminto === "poista") {
                                mj = qsTr("friend removed")
                            }
                        } else {
                            if (toiminto === "hyvaksy") {
                                mj = qsTr("accepting was not successfull")
                            }
                            if (toiminto === "hylkaa") {
                                mj = qsTr("rejecting was not successfull")
                            }
                            if (toiminto === "poista") {
                                mj = qsTr("removal was not successfull")
                            }
                        }
                        if ("target_user" in jsonVastaus.response) {
                            mj += ": " + jsonVastaus.response.target_user.first_name +
                                    " " + jsonVastaus.response.target_user.last_name
                        }
                    } else {
                        mj = qsTr("an error occurred")
                    }
                    nayta(mj)
                    console.log(mj + ", " + jsonVastaus.response.request_type)
                }
            } catch (err) {
                console.log("" + err)
                if (httpVastaus.length < 60) {
                    console.log("httpVastaus: " + httpVastaus)
                } else {
                    console.log("httpVastaus: " + httpVastaus.substring(0,60))
                }
            }
        }
        property int haku: 0
        property int pyynnot: 0
        property int haettavia: 25
        //property string toiminto: ""

        function haeKavereita() {
            var kysely = ""
            //toiminto = "kaverit"
            kysely = UnTpd.getFriendsInfo(tunnus, haku*haettavia, haettavia);
            xHttpGet(kysely, "kaverit")
            return
        }

        function kaveriKyselyt() {
            var kysely = ""
            //toiminto = "pyynnot"
            kysely = UnTpd.getPendingFriends(pyynnot*haettavia, haettavia)
            xHttpGet(kysely, "pyynnot")
            return
        }

        function hyvaksyKaveriksi(kohde) {
            var kysely = ""
            //toiminto = "hyvaksy"
            kysely = UnTpd.acceptFriend(kohde)
            xHttpGet(kysely, "hyvaksy")
            return
        }

        function hylkaaPyynto(kohde) {
            var kysely = ""
            //toiminto = "hylkaa"
            kysely = UnTpd.rejectFriend(kohde)
            xHttpGet(kysely, "hylkaa")
            return
        }

        function poistaKaveri(kohde) {
            var kysely = ""
            //toiminto = "poista"
            kysely = UnTpd.removeFriend(kohde)
            xHttpGet(kysely, "poista")
            return
        }
    }

    SilicaListView {
        id: kaverilista
        //height: sivu.height - otsikko.height
        //width: sivu.width
        anchors.fill: parent
        //anchors.leftMargin: Theme.horizontalPageMargin
        //anchors.rightMargin: Theme.horizontalPageMargin

        model: _pyynnot? pyytajat : loydetytKaverit
        header: PageHeader{
            title: _pyynnot ? qsTr("friend requests") : (tunnus == "") ? qsTr("my friends") : qsTr("%1's friends").arg(tunnus)
        }

        delegate: kaveri

        onMovementEnded: {
            if (atYEnd) {
                if (_pyynnot) {
                    uTYhteys.pyynnot++
                    uTYhteys.kaveriKyselyt()
                } else {
                    uTYhteys.haku++
                    uTYhteys.haeKavereita()
                }
            }
        }

        PullDownMenu {
            visible: tunnus === "" || tunnus === UnTpd.kayttaja
            MenuItem {
                text: _pyynnot? qsTr("show friends") : qsTr("show requests")
                onClicked: {
                    if (_pyynnot)
                        uTYhteys.pyynnot = 0
                    else
                        uTYhteys.haku = 0
                    _pyynnot = !_pyynnot
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        uTYhteys.haeKavereita()
        uTYhteys.kaveriKyselyt()
    }

    Component.onDestruction: {
        sulkeutuu()
    }
}
