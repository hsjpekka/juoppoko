import QtQuick 2.0
import QtQml 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    signal sulkeutuu

    //property var kirjaus //json-olio
    property var keskustelu //json-olio
    property bool hakuvirhe: false
    property int viesteja: 0
    property int ckdId: 0
    property alias user_avatar: naama.source
    property alias user_name: kuka.text
    property alias venue_name: paikka.text
    property alias beer_label: juomanEtiketti.source
    property alias beer_name: olut.text
    property alias brewery_name: panimo.text
    property alias checkin_comment: huuto.text
    //property int valittu

    function kirjoitaSanotut(juttu){
        var kuva = juttu.user.user_avatar, kayttajaTunnus = juttu.user.user_name
        var sanottu = juttu.comment, puhuja = juttu.user.first_name + " " + juttu.user.last_name
        var commentId = juttu.comment_id, oikeudet = false

        //console.log("oikeudet owner " + juttu.comment_owner + " editor " + juttu.comment_editor)
        if (juttu.comment_owner || juttu.comment_editor)
            oikeudet = true

        sanotut.append({"commentId": commentId, "oikeudet": oikeudet,
                           "kayttajaTunnus": kayttajaTunnus, "puhuja": puhuja,
                           "sanottu": sanottu, "kuva": kuva })

        viesteja++

        return
    }

    function kirjoitaTiedot() {
        var nimi = "", i = 0

        //naama.source = kirjaus.user.user_avatar
        //if(kirjaus.user.first_name != "" || kirjaus.user.last_name != ""){
        //    nimi = kirjaus.user.first_name + " " + kirjaus.user.last_name
        //} else
        //    nimi = kirjaus.user.user_name
        //kuka.text = nimi

        //if (onkoTietoa(kirjaus.venue, "venue_name"))
        //    paikka.text = kirjaus.venue.venue_name

        //juomanEtiketti.source = kirjaus.beer.beer_label
        //olut.text =  kirjaus.beer.beer_name
        //panimo.text = kirjaus.brewery.brewery_name

        //huuto.text = kirjaus.checkin_comment

        //while (i < kirjaus.comments.count) {
        while (i < keskustelu.count) {
            //console.log("sanottu: " + JSON.stringify(kirjaus.comments.items[i]))
            //kirjoitaSanotut(kirjaus.comments.items[i])
            kirjoitaSanotut(keskustelu.items[i])
            i++
        }

        //console.log("tehty")
        return
    }

    /*
    function qqkommentoi() {
        var xhttp = new XMLHttpRequest();
        var osoite, kysely

        osoite = UnTpd.addCommentAddress(ckdId)
        kysely = UnTpd.addCommentString(juttuni.text)

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
                //console.log(xhttp.responseText)
                unTpdViestit.text = qsTr("request finished") + ", " + xhttp.statusText

                var vastaus = JSON.parse(xhttp.responseText);
                var vika = vastaus.response.comments.count - 1

                //console.log(" " +  vastaus.response.result + ", <==> " + vika)

                keskustelu = vastaus.response.comments

                kirjoitaSanotut(vastaus.response.comments.items[vika])

                juttuni.text = ""


            } else {
                hakuvirhe = true
                console.log(xhttp.readyState + ", " + xhttp.statusText)
                unTpdViestit.text = xhttp.readyState + ", " + xhttp.statusText
            }

        }

        unTpdViestit.text = qsTr("posting query")
        xhttp.open("POST", osoite, false)
        xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
        xhttp.send(kysely);

        return
    }
    // */

    function onkoTietoa(tietue, kentta){
        var kentat = Object.keys(tietue)
        var i = 0, n = kentat.length
        var onko = false

        while ( i<n && !onko ){
            if (kentat[i] === kentta) // oli ==
                onko = true
            i++
        }

        return onko
    }

    /*
    function qqpoistaSanottu(valittu) {
        var id = sanotut.get(valittu).commentId
        var sanoja = sanotut.get(valittu).kayttajaTunnus
        var xhttp = new XMLHttpRequest();
        var osoite, kysely = ""

        osoite = UnTpd.removeComment(id)

        xhttp.onreadystatechange = function () {
            //console.log("" + xhttp.readyState + " - " + xhttp.status)
            if (xhttp.readyState == 0)
                unTpdViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
            else if (xhttp.readyState == 1)
                unTpdViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
            else if (xhttp.readyState == 2)
                unTpdViestit.text = qsTr("request received") + ", " + xhttp.statusText
            else if (xhttp.readyState == 3)
                unTpdViestit.text = qsTr("processing request") + ", " + xhttp.statusText
            else if (xhttp.readyState == 4){
                //console.log(xhttp.responseText)
                unTpdViestit.text = qsTr("request finished") + ", " + xhttp.statusText

                var vastaus = JSON.parse(xhttp.responseText);

                //console.log(" " +  vastaus.response.result)

                if (vastaus.response.result == "success") {
                    keskustelu = vastaus.response.comments
                    sanotut.remove(valittu)
                    viesteja--
                }

            } else {
                hakuvirhe = true
                console.log(xhttp.readyState + ", " + xhttp.statusText)
                unTpdViestit.text = xhttp.readyState + ", " + xhttp.statusText
            }

        }

        unTpdViestit.text = qsTr("posting query")
        xhttp.open("POST", osoite, false)
        xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
        xhttp.send(kysely);

        return
    }
    // */

    Component {
        id: puhekupla
        ListItem{
            id: kupla
            x: Theme.paddingMedium
            contentHeight: kuplanTekstit.height + Theme.paddingMedium

            onPressAndHold: {
                //console.log("- :" + sanotutLista.currentIndex + ", " + sanotutLista.indexAt(mouseX,y+mouseY))
                sanotutLista.currentIndex = sanotutLista.indexAt(mouseX,y+mouseY)
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("delete")
                    enabled: kupla.muokkausOikeudet
                    onClicked: {
                        //console.log("valittu1 " + valittu + ", aika " + lueJuomanAika(valittu-1))                        
                        sanotutLista.currentItem.remorseAction(qsTr("deleting"), function () {
                            var valittu = sanotutLista.currentIndex
                            uTYhteys.poistaSanottu(valittu)
                        })

                    }
                }

            }

            property bool muokkausOikeudet: oikeudet

            Row {
                id: kuplarivi
                spacing: Theme.paddingMedium

                Image{
                    id: kasvot
                    source: kuva
                    height: 2.5*Theme.fontSizeMedium
                    width: height
                }

                Column {
                    id: kuplanTekstit
                    spacing: Theme.paddingSmall

                    Label{
                        id: puheenpitaja
                        text: puhuja
                        width: sivu.width - kupla.x - kasvot.width - 2*kuplarivi.spacing
                        color: Theme.secondaryHighlightColor
                    }

                    Label {
                        id: puhe
                        text: sanottu
                        width: puheenpitaja.width - (x - puheenpitaja.x)
                        color: Theme.highlightColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        x: Theme.paddingMedium
                    }

                }

                /*
                Text{
                    id: kayttaja
                    text: kayttajaTunnus
                    visible: false
                }

                Text{
                    id: tunniste
                    text: commentId
                    visible: false
                }

                Text{
                    id: muokkausOikeudet
                    text: oikeudet
                    visible: false
                }
                // */

            }
        }
    }

    SilicaFlickable{
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator{}

        XhttpYhteys {
            id: uTYhteys
            anchors.top: parent.top
            z: 1
            onValmis: {
                var jsonVastaus;
                //console.log("yhteydenotto valmis: " + httpVastaus.length)
                try {
                    jsonVastaus = JSON.parse(httpVastaus);
                    if (toiminto === "poistaKommentti") {
                        if (jsonVastaus.response.result == "success") {
                            keskustelu = jsonVastaus.response.comments
                            sanotut.remove(valittu)
                            viesteja--
                        }
                    } else if (toiminto === "kommentoi") {
                        var vika = jsonVastaus.response.comments.count - 1

                        keskustelu = jsonVastaus.response.comments
                        kirjoitaSanotut(jsonVastaus.response.comments.items[vika])
                        if (jsonVastaus.response.result === "success") {
                            juttuni.label = qsTr("posted")
                            juttuni.text = ""
                        }
                    }
                } catch (err) {
                    console.log("" + err)
                }
            }

            property string toiminto: ""
            property int    valittu: -1

            function kommentoi() {
                var posoite, kysely
                //oiminto = "kommentoi";

                posoite = UnTpd.addCommentAddress(ckdId)
                kysely = UnTpd.addCommentString(juttuni.text)

                xHttpPost(kysely, posoite, "kommentoi");

                return
            }

            function poistaSanottu(nro) {
                var id = sanotut.get(nro).commentId;
                //var sanoja = sanotut.get(nro).kayttajaTunnus;
                var po = UnTpd.removeComment(id), kysely="";

                //toiminto = "poistaKommentti";
                valittu = nro;
                //haku = _post;
                //kysely = ""
                //postOsoite = UnTpd.removeComment(id);

                xHttpPost(kysely, po, "poistaKommentti");

                return

            }
        }

        Column{
            id: column
            x: Theme.paddingMedium
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Comments")
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

            Row {// kuka ja missä
                id: juojaRivi
                spacing: Theme.paddingMedium
                height:

                Image {
                    id: naama
                    source: ""
                    height: Theme.fontSizeMedium*2.5
                    width: height
                }

                Column {
                    id: henkilo
                    width: sivu.width - column.x - x - Theme.paddingSmall

                    Label {
                        id: kuka
                        text: "" //
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        color: Theme.highlightColor
                        width: henkilo.width
                    }

                    Label {
                        id: paikka
                        text: ""
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        width: henkilo.width
                        color: Theme.secondaryHighlightColor
                    }
                }
            }

            Row { // tuopin tiedot
                id: juomaRivi
                //x: Theme.paddingLarge
                spacing: Theme.paddingMedium
                //x: Theme.paddingLarge

                Image {
                    id: juomanEtiketti
                    source: ""
                    width: Theme.fontSizeMedium*3
                    height: width
                }

                Column {
                    id: mita
                    width: sivu.width - 2*juomaRivi.x - juomaRivi.spacing - juomanEtiketti.width

                    Label {
                        id: olut
                        text: ""
                        color: Theme.highlightColor
                        width: mita.width - Theme.paddingSmall
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    Label {
                        id: panimo
                        text: ""
                        color: Theme.secondaryHighlightColor
                        width: mita.width - Theme.paddingSmall
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                }

            }

            Label {
                id: huuto
                text: ""
                color: Theme.highlightColor
                font.bold: true
                font.italic: true
                font.pixelSize: Theme.fontSizeLarge
                width: sivu.width - 2*column.x - x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.paddingSmall
            }

            Separator {
                width: (sivu.width - column.x)*0.8
                x: 0.5*(sivu.width - column.x - width)
                color: Theme.highlightColor
            }

            SilicaListView{
                id: sanotutLista
                height: sivu.height - y - juttuni.height - column.spacing
                width: parent.width
                clip: true

                model: ListModel {
                    id: sanotut
                }

                delegate: puhekupla

            }

            TextField{
                id: juttuni
                width: sivu.width
                placeholderText: qsTr("my comment")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    if (text > "") uTYhteys.kommentoi()
                    juttuni.focus = false
                }
                text: ""
                label: (text > "") ? qsTr("my comment") : qsTr("empty strings not posted")
            }
        }
    }

    Component.onCompleted: {
        //console.log("-> \n \n " + JSON.stringify(keskustelu))
        viesteja = 0
        kirjoitaTiedot()
        //console.log("\n\n valmis")
    }

    Component.onDestruction: {
        sulkeutuu()
    }
}
