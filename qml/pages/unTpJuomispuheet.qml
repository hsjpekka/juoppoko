import QtQuick 2.0
import QtQml 2.0
import Sailfish.Silica 1.0
import "../components"
import "../scripts/unTap.js" as UnTpd

Page {
    id: sivu
    Component.onCompleted: {
        viesteja = 0
        kirjoitaTiedot()
    }

    Component.onDestruction: {
        sulkeutuu()
    }

    signal sulkeutuu

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

    Component {
        id: puhekupla
        ListItem{
            id: kupla
            x: Theme.paddingMedium
            contentHeight: kuplanTekstit.height + Theme.paddingMedium
            onPressAndHold: {
                sanotutLista.currentIndex = sanotutLista.indexAt(mouseX,y+mouseY)
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("delete")
                    enabled: kupla.muokkausOikeudet
                    onClicked: {
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
            var kysely;
            kysely = UnTpd.addComment(ckdId, juttuni.text);

            xHttpPost(kysely[0], kysely[1], "", "kommentoi");

            return;
        }

        function poistaSanottu(nro) {
            var id = sanotut.get(nro).commentId;
            var kysely = UnTpd.removeComment(id);

            valittu = nro;

            xHttpPost(kysely[0], kysely[1], "", "poistaKommentti");

            return

        }
    }

    SilicaFlickable{
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator{}

        Column{
            id: column
            x: Theme.paddingMedium
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Comments")
            }

            Row {// kuka ja missä
                id: juojaRivi
                spacing: Theme.paddingMedium
                height: naama.height > henkilo.height ? naama.height : henkilo.height

                Image {
                    id: naama
                    source: ""
                    height: Theme.itemSizeMedium
                    //height: Theme.fontSizeMedium*2.5
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
                spacing: Theme.paddingMedium

                Image {
                    id: juomanEtiketti
                    source: ""
                    height: Theme.itemSizeMedium
                    width: height
                    //width: Theme.fontSizeMedium*3
                    //height: width
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

    function kirjoitaSanotut(juttu){
        var kuva = juttu.user.user_avatar, kayttajaTunnus = juttu.user.user_name;
        var sanottu = juttu.comment, puhuja = juttu.user.first_name + " " + juttu.user.last_name;
        var commentId = juttu.comment_id, oikeudet = false;

        if (juttu.comment_owner || juttu.comment_editor)
            oikeudet = true;

        sanotut.append({"commentId": commentId, "oikeudet": oikeudet,
                           "kayttajaTunnus": kayttajaTunnus, "puhuja": puhuja,
                           "sanottu": sanottu, "kuva": kuva });

        viesteja++;

        return;
    }

    function kirjoitaTiedot() {
        var nimi = "", i = 0;

        while (i < keskustelu.count) {
            kirjoitaSanotut(keskustelu.items[i]);
            i++;
        }

        return;
    }

    function onkoTietoa(tietue, kentta){
        var kentat = Object.keys(tietue);
        var i = 0, n = kentat.length;
        var onko = false;

        while ( i<n && !onko ){
            if (kentat[i] === kentta)
                onko = true;
            i++;
        }

        return onko;
    }
}
