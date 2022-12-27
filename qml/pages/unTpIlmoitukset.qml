import QtQuick 2.0
import Sailfish.Silica 1.0
import "../scripts/unTap.js" as UnTpd
import "../components/"

Page {
    id: sivu
    Component.onCompleted: {
        ilmoituksetListaan()
    }

    property string ilmoitukset: ""

    ListModel {
        id: tiedot
        ListElement {
            osio: qsTr("No notifications")
            otsake: ""
            linkki: ""
            sisalto: ""
            avattava: ""
            liite: ""
            uusi: false
        }

        property int kutsuja: -1

        function lisaaViesti(luokka, otsikko, teksti, linkki, liite, uusi) {
            return lisaa(luokka, "", otsikko, teksti, linkki, liite, uusi);
        }

        function lisaaLinkki(luokka, avattava, teksti) {
            return lisaa(luokka, avattava, teksti);
        }

        function lisaa(luokka, avattava, otsikko, teksti, linkki, liite, uusi) {
            if (luokka === undefined) {
                console.log("No category for the notification - ignoring.");
                return;
            }

            if (kutsuja === -1) {
                tiedot.clear();
                console.log("tyhjennetty");
                kutsuja++;
            }

            if (avattava === undefined) avattava = "";
            if (otsikko === undefined) otsikko = "";
            if (teksti === undefined) teksti = "";
            if (linkki === undefined) linkki = "";
            if (liite === undefined) liite = "";
            if (uusi === undefined) uusi = false;

            tiedot.append({"osio": luokka, "otsake": otsikko, "linkki": linkki,
                              "sisalto": teksti, "liite": liite,
                              "uusi": uusi, "avattava": avattava
                          });
            return;
        }

        function nayta(i) {
            tiedot.set(i, {"uusi": true});
            return;
        }

        function piilota(i) {
            tiedot.set(i, {"uusi": false});
            return;
        }
    }

    Component {
        id: ilmoitusLuokat
        ListItem {
            id: uutinen
            contentHeight: auki? ots.height + juttu.height + lnk.height : minKorkeus
            x: Theme.horizontalPageMargin
            width: parent.width - x - Theme.paddingMedium
            onClicked: {
                if (sivulle === "unTpKaverit.qml")
                    pageContainer.push(Qt.resolvedUrl(sivulle), {"ilmoitukset": ilmoitukset,
                                       "_pyynnot": true })
                if (sivulle > "")
                    pageContainer.push(Qt.resolvedUrl(sivulle), {"ilmoitukset": ilmoitukset })
                else
                    auki = !auki
            }
            property string sivulle: avattava
            property bool auki: uusi
            property int minKorkeus: ots.height > Theme.iconSizeMedium ? ots.height : Theme.iconSizeMedium

            Label {
                id: ots
                color: (uutinen.sivulle > "") ? Theme.primaryColor : Theme.secondaryColor
                font.bold: (uutinen.sivulle > "") ? false : true
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    rightMargin: (uutinen.sivulle > "") ? kuvake.width + Theme.paddingSmall : kuva.width + Theme.paddingSmall
                }
                text: otsake
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            LinkedLabel {
                id: lnk
                anchors {
                    top: ots.bottom
                    left: ots.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                }
                horizontalAlignment: Text.AlignHCenter
                shortenUrl: true
                plainText: linkki
                visible: uutinen.auki
            }

            Label {
                id: juttu
                color: Theme.secondaryColor //Theme.secondaryHighlightColor
                anchors {
                    top: lnk.bottom
                    topMargin: Theme.paddingSmall
                    left: lnk.left
                    right: lnk.right
                }
                text: sisalto
                visible: uutinen.auki
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Image {
                id: kuva
                source: liite
                anchors.top: parent.top
                anchors.right: parent.right
                height: Theme.iconSizeMedium
                width: height
                visible: !kuvake.visible
                z: -1
            }

            Icon {
                id: kuvake
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                source: "image://theme/icon-m-right"
                height: Theme.iconSizeMedium
                visible: uutinen.sivulle > ""
            }
        }
    }

    SilicaListView {
        id: ilmoitusListat
        anchors.fill: parent
        header: PageHeader {
            title: qsTr("Notifications")
        }
        model: tiedot
        delegate: ilmoitusLuokat
        spacing: Theme.paddingSmall
        section {
            property: "osio"
            delegate: SectionHeader {
                text: section
            }
        }
        PullDownMenu {
            MenuItem {
                text: qsTr("Show titles only")
                onClicked: {
                    var i = 0;
                    while (i < tiedot.count) {
                        tiedot.piilota(i)
                        i++
                    }
                }
            }
            MenuItem {
                text: qsTr("Show details")
                onClicked: {
                    var i = 0;
                    while (i < tiedot.count) {
                        tiedot.nayta(i)
                        i++
                    }
                }
            }
        }
    }

    function ilmoituksetListaan() {
        var ilmo, maljoja = -1, kommentteja = -1, kavereita = -1, viesteja = -1, uutisia = -1,
            tarjoajia = -1, veunes = -1, muita = -1, teksti = "", i=0, uusi;
        try {
            ilmo = JSON.parse(ilmoitukset);
        } catch (err) {
            console.log(err);
            return;
        }
        if ("notifications" in ilmo && "unread_count" in ilmo.notifications ) {
            if ("comments" in ilmo.notifications.unread_count)
                kommentteja = ilmo.notifications.unread_count.comments;
            if ("toasts" in ilmo.notifications.unread_count)
                maljoja = ilmo.notifications.unread_count.toasts;
            if ("friends" in ilmo.notifications.unread_count)
                kavereita = ilmo.notifications.unread_count.friends;
            if ("messages" in ilmo.notifications.unread_count)
                viesteja = ilmo.notifications.unread_count.messages;
            if ("venues" in ilmo.notifications.unread_count)
                tarjoajia = ilmo.notifications.unread_count.venues;
            if ("veunes" in ilmo.notifications.unread_count)
                veunes = ilmo.notifications.unread_count.veunes;
            if ("others" in ilmo.notifications.unread_count)
                muita = ilmo.notifications.unread_count.others;
            if ("news" in ilmo.notifications.unread_count)
                uutisia = ilmo.notifications.unread_count.news;

            teksti = qsTr("new comments - %1, new toasts %2").arg(kommentteja).arg(maljoja);
            tiedot.lisaaLinkki( qsTr("Comments & Toasts"), "unTpKayttaja.qml", teksti);
            teksti = qsTr("new friend requests - %1").arg(kavereita);
            tiedot.lisaaLinkki( qsTr("Friend requests"), "unTpKaverit.qml", teksti);

            if ("response" in ilmo) {
                if ("messages" in ilmo.response) {
                    i = 0;
                    while (i < ilmo.response.messages.count) {
                        if (i < viesteja) {
                            uusi = true;
                        } else {
                            uusi = vanha;
                        }
                        tiedot.lisaaViesti( qsTr("Messages"),
                                     ilmo.response.messages.items[i].messages_title,
                                     ilmo.response.messages.items[i].messages_text,
                                     ilmo.response.messages.items[i].messages_link, "", uusi
                                     );
                        i++;
                    }
                }
                if ("venues" in ilmo.response) {
                    i = 0;
                    while (i < ilmo.response.venues.count) {
                        if (i < tarjoajia) {
                            uusi = true;
                        } else {
                            uusi = vanha;
                        }
                        tiedot.lisaaViesti( qsTr("Venues"),
                                           ilmo.response.venues.items[i].venues_title,
                                           ilmo.response.venues.items[i].venues_text,
                                           ilmo.response.venues.items[i].venues_link, "", uusi
                                     );
                        i++;
                    }
                }
                if ("veunes" in ilmo.response) {
                    i = 0;
                    while (i < ilmo.response.veunes.count) {
                        if (i < veunes) {
                            uusi = true;
                        } else {
                            uusi = vanha;
                        }
                        tiedot.lisaaViesti( qsTr("Veunes"),
                                     ilmo.response.veunes.items[i].veunes_title,
                                     ilmo.response.veunes.items[i].veunes_text,
                                     ilmo.response.veunes.items[i].veunes_link, "", uusi
                                     );
                        i++;
                    }
                }
                if ("news" in ilmo.response) {
                    i = 0;
                    while (i < ilmo.response.news.count) {
                        if (i < uutisia) {
                            uusi = true;
                        } else {
                            uusi = false;
                        }
                        tiedot.lisaa( qsTr("News"), "", ilmo.response.news.items[i].news_title,
                                     ilmo.response.news.items[i].news_text,
                                     ilmo.response.news.items[i].news_link,
                                     ilmo.response.news.items[i].news_image_link, uusi
                                     );
                        i++;
                    }
                }
                if ("others" in ilmo.response) {
                    i = 0;
                    while (i < muita) {
                        tiedot.lisaa( qsTr("Others"), ilmo.response.others.items[i].others_title,
                                     ilmo.response.others.items[i].others_text,
                                     ilmo.response.others.items[i].others_link, "", ""
                                     );
                        i++;
                    }
                }
            }

        }

        return;
    }

}
