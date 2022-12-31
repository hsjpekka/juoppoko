import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../components"
import "../scripts/unTap.js" as UnTpd
import "../scripts/foursqr.js" as FourSqr

Dialog {
    id: sivu
    onAccepted: {
        UnTpd.postFacebook = face; //facebook.checked
        UnTpd.postTwitter = tweet; //twitter.checked
        UnTpd.postFoursquare = foursq; //foursquare.checked
    }
    Component.onCompleted: {
        paikkatieto.start()
        koordinaatit()
        sijaintiTuore = false
    }

    property string baari: ""
    property string baarinTunnus: ""
    property bool   haettu: false
    property int    hakutunnus: 0 // foursquare session_token = "haku" + hakunro
    property int    hakusade: 500
    property int    ikoninKoko: 88 // 32, 44, 64 ja 88 saatavilla

    property string aikaaSitten: ""
    property alias  lpiiri: leveyspiiri.text
    property bool   naytaSijainti: true
    property alias  ppiiri: pituuspiiri.text
    property bool   sijaintiTuore: false

    property alias  face: facebook.checked
    property alias  foursq: foursquare.checked
    property alias  tweet: twitter.checked

    property bool   asetuksetNakyvat: false
    property bool   julkaisutNakyvat: false

    Timer {
        id: jokoHaetaan
        interval: 1*1000 // ms
        running: true
        repeat: true
        onTriggered: {
            if (paikkatieto.position.latitudeValid){
                koordinaatit()
                if (haettu || haettava.activeFocus) {
                    repeat = false
                } else {
                    haunAloitus("")
                }
            }
        }
    }

    PositionSource {
        id: paikkatieto
        active: true
        updateInterval: 5*60*1000 // 5 min
        onPositionChanged: {
            koordinaatit()
        }
    }

    Component {
        id: baarienTiedot
        ListItem {
            id: baarinTiedot
            contentHeight: baarinNimi.height
            width: sivu.width
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("venue info")
                    visible: baarinTiedot.frsqId > ""
                    onClicked: {
                        fsYhteys.haeUnTpdId(baarinTiedot.frsqId, "tiedot")
                    }
                }
                MenuItem {
                    text: qsTr("venue activity")
                    visible: baarinTiedot.frsqId > ""
                    onClicked: {
                        fsYhteys.haeUnTpdId(baarinTiedot.frsqId, "toiminta")
                    }
                }
            }

            onClicked: {
                var kuppilaNr = baariLista.indexAt(mouseX,y+mouseY)
                kopioiBaari(kuppilaNr)
            }

            property string frsqId: baariId

            Row {
                x: Theme.paddingLarge
                width: sivu.width - 2*x

                Rectangle {
                    height: baarinIkoni.height + 2*border.width
                    width: height
                    border.width: 1
                    radius: 5
                    color: "transparent"
                    border.color: (baarinTiedot.frsqId == baarinTunnus) ? Theme.highlightColor :
                                                                            "transparent"
                    Image {
                        id: baarinIkoni
                        source: kuvake
                    }
                }

                TextField {
                    id: baarinNimi
                    text: nimi
                    label: tyyppi
                    readOnly: true
                    width: sivu.width - baarinIkoni.width - 2*Theme.paddingLarge
                    color: (baarinTiedot.frsqId == baarinTunnus) ? Theme.highlightColor :
                                                                     Theme.primaryColor
                    onClicked: {
                        var kuppilaNr = baariLista.indexAt(mouseX,baarinTiedot.y+0.5*height)
                        kopioiBaari(kuppilaNr)
                    }
                    onPressAndHold: {
                        baarinTiedot.openMenu()
                    }
                }
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width

            DialogHeader {
                title: qsTr("Check-in location")
            }

            Row { // facebook, foursquare, twitter
                property string hakemisto: "./"
                width: parent.width
                x: Theme.horizontalPageMargin
                spacing: (width - 3*facebook.width - 2*x)/2
                IconTextSwitch {
                    id: facebook
                    checked: false
                    width: icon.width + Theme.itemSizeExtraSmall + Theme.paddingMedium
                    icon.source: parent.hakemisto + "f_logo_RGB-Blue_58.png"
                    icon.height: Theme.iconSizeMedium
                    icon.width: height*0.8
                }
                IconTextSwitch {
                    id: foursquare
                    checked: false
                    width: facebook.width
                    icon.source: parent.hakemisto + "foursquare.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: height*0.8
                }
                IconTextSwitch {
                    id: twitter
                    checked: false
                    width: facebook.width
                    icon.source: parent.hakemisto + "Twitter_Social_Icon_Circle_Color.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: height*0.8
                }
            }

            IconTextSwitch {
                id: asemanTalletus
                icon.source: "image://theme/icon-m-location"
                checked: true
                text: checked ? qsTr("shows place") : qsTr("hides place")
                onCheckedChanged: {
                    if (checked == false) {
                        asetuksetNakyvat = false
                    }
                    naytaSijainti = checked
                    //baarinTunnus = ""
                    //kuvaBaari.source = ""
                    //txtBaari.text = ""
                }
            }

            Item {
                id: piilotusRivi
                x: Theme.paddingMedium
                width: sivu.width - 2*x
                height: (piilotus.height > Theme.fontSizeMedium)? piilotus.height : Theme.fontSizeMedium

                IconButton {
                    id: piilotus
                    icon.source: asetuksetNakyvat? "image://theme/icon-m-down" : "image://theme/icon-m-right"
                    onClicked: {
                        asetuksetNakyvat = !asetuksetNakyvat
                    }
                }

                Label {
                    y: piilotus.y + 0.5*(piilotus.height - height)
                    x: piilotus.x + piilotus.width + Theme.paddingMedium
                    text: qsTr("search settings")
                    color: asemanTalletus.checked ? Theme.secondaryColor : Theme.highlightDimmerColor
                }

                MouseArea {
                    anchors.fill: piilotusRivi
                    onClicked: {
                        asetuksetNakyvat = !asetuksetNakyvat
                    }
                }

            }

            Row { // hakuasetukset
                id: asetuksetRivi
                x: Theme.paddingLarge
                spacing: Theme.paddingMedium
                visible: asetuksetNakyvat

                Rectangle {
                    width: 1
                    height: hakuasetukset.height
                    color: Theme.secondaryColor
                }

                Column {
                    id: hakuasetukset                    

                    Label {
                        id: sijainninTila
                        text: paikkatieto.position.latitudeValid ? aikaaSitten : "(" + qsTr("location not determined") + ")"
                        visible: !sijaintiTuore
                        color: naytaSijainti? Theme.highlightColor : Theme.highlightDimmerColor
                        x: Theme.paddingLarge*3
                    }

                    Row { //asema
                        id: asemaRivi

                        IconButton{
                            id: syotaKoordinaatit
                            icon.source: "image://theme/icon-m-edit"
                            highlighted: false
                            onClicked: {
                                highlighted = !highlighted
                                sijainninTila.visible = !highlighted
                            }
                        }

                        TextField {
                            id: pituuspiiri
                            text: Number(FourSqr.lastLong).toLocaleString(Qt.locale())
                            label: qsTr("lng")
                            color: readOnly ? (sijaintiTuore? Theme.highlightColor : Theme.secondaryHighlightColor) : Theme.primaryColor
                            readOnly: !syotaKoordinaatit.highlighted
                            width: (sivu.width - 2*asetuksetRivi.x - 2*asemaRivi.spacing - syotaKoordinaatit.width )/2
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator {bottom: -180.0; top: 180.0}
                            onTextChanged: {
                                if (!readOnly)
                                    FourSqr.lastLong = Number.fromLocaleString(Qt.locale(), text)
                            }
                            EnterKey.onClicked: {
                                leveyspiiri.focus = true
                            }
                        }

                        TextField {
                            id: leveyspiiri
                            text: Number(FourSqr.lastLat).toLocaleString(Qt.locale())
                            label: qsTr("lat")
                            color: readOnly ? (sijaintiTuore? Theme.highlightColor : Theme.secondaryHighlightColor) : Theme.primaryColor
                            readOnly: !syotaKoordinaatit.highlighted
                            width: pituuspiiri.width
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator {bottom: -180.0; top: 180.0}
                            onTextChanged: {
                                if (!readOnly)
                                    FourSqr.lastLat = Number.fromLocaleString(Qt.locale(), text)
                            }
                            EnterKey.onClicked: {
                                focus = false
                            }
                        }
                    }

                    ComboBox {
                        id: etaisyys
                        width: sivu.width - hakuasetukset.x
                        label: qsTr("radius")

                        menu: ContextMenu {
                            MenuItem { text: "50 m" }
                            MenuItem { text: "500 m" }
                            MenuItem { text: "2 km" }
                            MenuItem { text: qsTr("not limited") }
                        }

                        currentIndex: sijaintiTuore ? 1 : 3

                        onCurrentIndexChanged: {
                            switch (currentIndex) { // juoman tilavuusyksikkö, 1 = ml, 2 = us oz, 3 = imp oz, 4 = imp pint, 5 = us pint
                            case 0:
                                hakusade = 50
                                break
                            case 1:
                                hakusade = 500
                                break
                            case 2:
                                hakusade = 2000
                                break
                            case 3:
                                hakusade = 0
                                break
                            }

                        }

                    }

                    TextSwitch {
                        id: tyyppiRajaus
                        checked: true
                        text: checked? qsTr("limits to Foursquare categories %1").arg("Dining and Drinking") :
                                       qsTr("searches in all categories")
                    }
                }
            }

            ListItem {
                id: valittuKuppila
                width: parent.width
                contentHeight: kuvaBaari.height > kuppila.height ? kuvaBaari.height : kuppila.height
                //x: Theme.paddingMedium
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("venue info")
                        visible: baarinTunnus > ""
                        onClicked: {
                            fsYhteys.haeUnTpdId(baarinTunnus, "tiedot")
                        }
                    }
                    MenuItem {
                        text: qsTr("venue activity")
                        visible: baarinTunnus > ""
                        onClicked: {
                            fsYhteys.haeUnTpdId(baarinTunnus, "toiminta")
                        }
                    }
                    MenuItem {
                        text: qsTr("clear")
                        onClicked: {
                            baarinTunnus = ""
                            valittuKuppila.nimi = ""
                        }
                    }
                }

                property string nimi: tyhja
                property string osoite: ""
                readonly property string tyhja: qsTr("check-in pub")
                onNimiChanged: {
                    if (nimi === "" && tyhja !== "") {
                        nimi = tyhja
                        osoite = ""
                        kuvaBaari.source = ""
                    }
                }

                Image {
                    id: kuvaBaari
                    width: Theme.iconSizeMedium
                    height: width
                    x: Theme.paddingMedium
                }

                Column {
                    id: kuppila
                    anchors {
                        left: kuvaBaari.right
                        leftMargin: Theme.paddingSmall
                        right: parent.right
                    }
                    spacing: Theme.paddingSmall

                    Label {
                        color: asemanTalletus.checked ? Theme.highlightColor : Theme.highlightDimmerColor
                        text: valittuKuppila.nimi
                    }
                    Label {
                        color: asemanTalletus.checked ? Theme.secondaryHighlightColor : Theme.highlightDimmerColor
                        text: valittuKuppila.osoite
                    }
                }
            }

            SearchField {
                id: haettava
                canHide: false
                width: parent.width
                placeholderText: qsTr("place")
                EnterKey.iconSource: "image://theme/icon-m-search"
                EnterKey.onClicked: {
                    focus = false
                    minTauko.stop();
                    haunAloitus(text);
                }
                onTextChanged: {
                    if (text.length > 2)
                        minTauko.restart()
                    if (text.length === 0) {
                        hakutunnus++
                    }
                }

                Timer {
                    id: minTauko
                    interval: 1000
                    running: false
                    repeat: false
                    onTriggered: haunAloitus(haettava.text)
                }
            }

            SilicaListView {
                id: baariLista
                property int minKorkeus: 4*Theme.fontSizeMedium
                property int vapaana: sivu.height - y + valittuKuppila.height
                                      - valittuKuppila.contentHeight
                height: vapaana > minKorkeus ? vapaana : minKorkeus
                width: parent.width
                clip: true
                highlightFollowsCurrentItem: true

                model: ListModel {
                    id: loydetytBaarit
                    function lisaa(id, nimi, osoite, tyyppi, kuvake, levpii, pitpii) {
                        return append({"baariId": id, "nimi": nimi, "osoite": osoite,
                                          "tyyppi": tyyppi, "kuvake": kuvake,
                                          "baarinPituusPiiri": pitpii,
                                          "baarinLeveysPiiri": levpii
                                      });
                    }
                }

                delegate: baarienTiedot

                VerticalScrollDecorator {}

                onMovementEnded: {
                    if (atYEnd) {
                        fsYhteys.haeBaareja(haettava.text)
                    }
                }

                XhttpYhteys {
                    id: fsYhteys
                    y: sivu.isPortrait ? Theme.itemSizeLarge : Theme.itemSizeSmall //DialogHeader.qml
                    z: 1
                    onValmis: {
                        var jsonVastaus
                        try {
                            jsonVastaus = JSON.parse(httpVastaus)
                            if (toiminto === "baareja") {
                                //console.log("baarihaku: " + httpVastaus)
                                paivitaHaetut(jsonVastaus)
                            } else if (toiminto === "tiedot") {
                                naytaKapakanTiedot(jsonVastaus)
                            } else if (toiminto === "toiminta") {
                                naytaKapakanKirjaukset(jsonVastaus)
                            }
                        } catch (err) {
                            console.log("error: " + err)
                        }
                    }

                    property int hakuNro: 0

                    function haeBaareja(haku) {
                        var pp, lp, maara=25, luokat = "", sijainti = "";
                        var kysely = "", tunnus = "haku", otsikko = "";

                        if (paikkatieto.position.longitudeValid &&
                                paikkatieto.position.latitudeValid) {
                            pp = paikkatieto.position.coordinate.longitude;
                            lp = paikkatieto.position.coordinate.latitude
                        } else {
                            pp = FourSqr.lastLong;
                            lp = FourSqr.lastLat;
                        }

                        if (naytaSijainti) {
                            sijainti = lp + "," + pp;
                        }

                        // pilgrim api
                        // 4d4b7105d754a06374d81259 - food
                        // 4d4b7105d754a06376d81259 - nightlife spot
                        // places api
                        // 13000 - Dining and drinking
                        if (tyyppiRajaus.checked) {
                            luokat = "13000"
                        } else {
                            luokat = "";
                        }

                        xhttp.setServer(FourSqr.apiProtocol, FourSqr.apiServer);
                        kysely = FourSqr.searchVenue(haku, sijainti, hakusade,
                                                     luokat, maara, tunnus + hakutunnus);
                        otsikko = "fsqAPIkey";
                        //otsikko += "Accept:application/json";
                        xHttpGetOtsikoilla(kysely[0], kysely[1], otsikko, "baareja");
                        //xHttpGet(kysely[0], kysely[1], "baareja");
                        xhttp.setServer(UnTpd.apiProtocol, UnTpd.apiServer);

                        console.log("baarihaku:" + kysely[0] + ", " + kysely[1] + ", " + otsikko);

                        return;
                    }

                    function haeUnTpdId(frSqrId, toiminto) {
                        var kysely = UnTpd.lookupFoursquare(frSqrId);
                        xHttpGet(kysely[0], kysely[1], toiminto);
                        return;
                    }
                }
            }
        }
    }

    function haunAloitus(hakuteksti) {
        loydetytBaarit.clear();
        fsYhteys.hakuNro = 0;
        haettu = true;
        kuvaBaari.source = "";
        return fsYhteys.haeBaareja(hakuteksti);
    }

    function kopioiBaari(nro) {
        baari = loydetytBaarit.get(nro).nimi;
        valittuKuppila.nimi = baari;
        valittuKuppila.osoite = (loydetytBaarit.get(nro).osoite == "") ?
                    loydetytBaarit.get(nro).tyyppi :
                    loydetytBaarit.get(nro).osoite;
        kuvaBaari.source = loydetytBaarit.get(nro).kuvake;
        baarinTunnus = loydetytBaarit.get(nro).baariId;
        pituuspiiri.text = loydetytBaarit.get(nro).baarinPituusPiiri;
        leveyspiiri.text = loydetytBaarit.get(nro).baarinLeveysPiiri;
        asemanTalletus.checked = true;
        return;
    }

    function koordinaatit() {
        var pvm = new Date(paikkatieto.position.timestamp);
        var aikaero = 1000*60*60*24*10, minEro = 10*60*1000;

        if (paikkatieto.position.longitudeValid ||
                paikkatieto.position.latitudeValid) {
            if (paikkatieto.position.longitudeValid) {
                pituuspiiri.text = paikkatieto.position.coordinate.longitude;
            }
            if (paikkatieto.position.latitudeValid) {
                leveyspiiri.text = paikkatieto.position.coordinate.latitude;
            }
            aikaero = new Date().getTime() - pvm.getTime();
            if (aikaero < 60*60*1000){
                aikaaSitten = "(" + qsTr("location determined %1 min ago").arg(Math.round(aikaero/(60*1000))) + ")";
            } else {
                aikaaSitten = "(" + qsTr("location determined %1 hours ago").arg(Math.round(aikaero/(60*60*1000))) + ")";
            }
        }

        if (aikaero < minEro) {
            sijaintiTuore = true;
        } else {
            sijaintiTuore = false;
        }

        return;
    }

    function onkoTietoa(tietue, kentta){
        var kentat = Object.keys(tietue);
        var i = 0, n = kentat.length;
        var onko = false;

        while ( i<n && !onko ){
            if (kentat[i] === kentta){
                onko = true;
            }
            i++;
        }

        return onko;
    }

    function naytaKapakanTiedot(jsonVastaus) {
        var kapakkaId, mj="", i=0;
        try {
            kapakkaId = jsonVastaus.response.venue.items[0].venue_id;
            if (jsonVastaus.response.venue.count > 1) {
                while (i<jsonVastaus.response.venue.count) {
                    mj += jsonVastaus.response.venue.items[i].venue_name + ", ";
                    i++;
                }
            }
            pageContainer.push(Qt.resolvedUrl("../pages/unTpTarjoaja.qml"),
                               {"tunniste": kapakkaId });
        } catch (err) {
            console.log("error: " + err);
        }

        return;
    }

    function naytaKapakanKirjaukset(jsonVastaus) {
        var kapakkaId, mj="", i=0;
        try {
            kapakkaId = jsonVastaus.response.venue.items[0].venue_id;
            if (jsonVastaus.response.venue.count > 1) {
                while (i<jsonVastaus.response.venue.count) {
                    mj += jsonVastaus.response.venue.items[i].venue_name + ", ";
                    i++;
                }
            }
            pageContainer.push(Qt.resolvedUrl("unTpPub.qml"), {"tunniste": kapakkaId,
                                   "kaljarinki": "kuppila" });
        } catch (err) {
            console.log("error: " + err);
        }

        return
    }

    function paivitaHaetut(vastaus) { // vastaus = JSON(fourSqr-vastaus)
        var haetut = vastaus.results;
        var i=0, n=haetut.length, j, m;
        var tunnus, nimi, osoite, etaisyys, tyyppi, pitpii, levpii;
        var kuvake = "";

        while (i<n) {
            tyyppi = "";
            if ("categories" in haetut[i]) {
                var luokat = haetut[i].categories;
                tyyppi = luokat[0].name;
                if ("icon" in luokat[0] && "prefix" in luokat[0].icon) {
                    kuvake = luokat[0].icon.prefix + ikoninKoko +
                            luokat[0].icon.suffix;
                }
                /*
                j = 1;
                m = luokat.length;
                while (j<m) {
                    if (luokat[j].primary == true) {
                        tyyppi = luokat[j].name;
                        j = m;
                        if ("icon" in luokat[i] && "prefix" in luokat[i].icon) {
                            kuvake = luokat[j].icon.prefix + ikoninKoko +
                                    luokat[j].icon.suffix;
                        }
                    }
                    j++;
                }
                // */
            }

            nimi = "";
            if ("name" in haetut[i]) {
                nimi = haetut[i].name;
            }

            osoite = "";
            if (onkoTietoa(haetut[i].location,"address")){
                osoite = haetut[i].location.address;
            }
            if ("distance" in haetut[i]){
                if (osoite != "") {
                    osoite += ", ";
                }
                osoite += haetut[i].distance + " m";
            }
            if (onkoTietoa(haetut[i].geocodes,"latitude")) {
                levpii = haetut[i].geocodes.latitude;
            } else {
                levpii = leveyspiiri.text;
            }
            if (onkoTietoa(haetut[i].geocodes,"longitude")) {
                pitpii = haetut[i].geocodes.longitude;
            } else {
                pitpii = pituuspiiri.text;
            }

            loydetytBaarit.lisaa(haetut[i].fsq_id, nimi, osoite, tyyppi,
                                 encodeURI(kuvake), levpii, pitpii);
            i++;
        }

        if (n === 0) {
            valittuKuppila.nimi = qsTr("None found.");
            valittuKuppila.osoite = qsTr("Better luck next time.");
            asetuksetNakyvat = true;
        }

        return;
    }

    /*
    function printableMethod(method) {
        var tulos = qsTr("source error");
        if (method === PositionSource.SatellitePositioningMethods) {
            tulos = qsTr("Satellite");
        } else if (method === PositionSource.NoPositioningMethods) {
            tulos = qsTr("Not available");
        } else if (method === PositionSource.NonSatellitePositioningMethods) {
            tulos = qsTr("Non-satellite");
        } else if (method === PositionSource.AllPositioningMethods) {
            tulos = qsTr("Multiple");
        }
        return tulos;
    }
    //*/
}
