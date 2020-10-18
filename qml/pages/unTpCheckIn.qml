import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../components"
import "../scripts/unTap.js" as UnTpd
import "../scripts/foursqr.js" as FourSqr

Dialog {
    id: sivu
    anchors.leftMargin: Theme.paddingLarge
    anchors.rightMargin: Theme.paddingLarge

    property string baari: ""
    property string baarinTunnus: ""
    property bool   haettu: false
    property int    hakunro: 0
    property int    hakusade: 500
    property int    ikoninKoko: 88 // 32, 44, 64 ja 88 saatavilla
    //property int    valittuBaariNr: 0

    property string aikaaSitten: ""
    property alias  lpiiri: leveyspiiri.text
    property bool   naytaSijainti: true
    property alias  ppiiri: pituuspiiri.text
    property bool   sijaintiTuore: false

    property bool   face: false
    property bool   foursq: false
    property bool   tweet: false

    property bool   asetuksetNakyvat: false
    property bool   julkaisutNakyvat: false

    /*
    function qqhaeBaareja(haku) {
        var xhttp = new XMLHttpRequest();
        var kysely = ""
        var pp, lp, maara=25, luokat = "", tark = ""
        // tark = checkin (oletus), global, browse, match

        if (paikkatieto.position.longitudeValid)
            pp = paikkatieto.position.coordinate.longitude
        else
            pp = FourSqr.lastLong

        if (paikkatieto.position.latitudeValid)
            lp = paikkatieto.position.coordinate.latitude
        else
            lp = FourSqr.lastLat

        // 4d4b7105d754a06374d81259 - food
        // 4d4b7105d754a06376d81259 - nightlife spot
        if (tyyppiRajaus.checked)
            luokat = "4d4b7105d754a06374d81259,4d4b7105d754a06376d81259"
        else
            luokat = ""

        hetkinen.running = true
        fourSqrViestit.text = qsTr("posting query")

        kysely = FourSqr.searchVenue(tark, true, lp, pp, hakusade, maara, luokat, haku)

        //console.log(kysely)

        xhttp.onreadystatechange = function () {
            //console.log("haeOluita - " + xhttp.readyState + " - " + xhttp.status + " , " + hakunro)
            if (xhttp.readyState == 0)
                fourSqrViestit.text = qsTr("request not initialized") + ", " + xhttp.statusText
            else if (xhttp.readyState == 1)
                fourSqrViestit.text = qsTr("server connection established") + ", " + xhttp.statusText
            else if (xhttp.readyState == 2)
                fourSqrViestit.text = qsTr("request received") + ", " + xhttp.statusText
            else if (xhttp.readyState == 3)
                fourSqrViestit.text = qsTr("processing request") + ", " + xhttp.statusText
            else { //if (xhttp.readyState == 4){
                //console.log(xhttp.responseText)
                var vastaus = JSON.parse(xhttp.responseText);

                fourSqrViestit.text = xhttp.statusText

                if (xhttp.status == 200) {
                    //console.log(xhttp.responseText)
                    paivitaHaetut(vastaus)
                } else {
                    console.log("search pub: " + xhttp.status + ", " + xhttp.statusText)
                }

                hetkinen.running = false
            }

        }

        xhttp.open("GET", kysely, true)
        xhttp.send();

        return
    }
    // */

    function haunAloitus(hakuteksti) {
        tyhjennaLista()
        hakunro = 0
        haettu = true
        kuvaBaari.source = ""

        return fsYhteys.haeBaareja(hakuteksti)
    }

    function kopioiBaari(nro) {
        //console.log(nro)
        baari = loydetytBaarit.get(nro).nimi
        txtBaari.text = baari
        txtBaari.label = (loydetytBaarit.get(nro).osoite == "") ? loydetytBaarit.get(nro).tyyppi : loydetytBaarit.get(nro).osoite
        kuvaBaari.source = loydetytBaarit.get(nro).kuvake
        baarinTunnus = loydetytBaarit.get(nro).baariId
        pituuspiiri.text = loydetytBaarit.get(nro).baarinPituusPiiri
        leveyspiiri.text = loydetytBaarit.get(nro).baarinLeveysPiiri

        return
    }

    // /*
    function koordinaatit() {
        var pvm = new Date(paikkatieto.position.timestamp)
        var aikaero = 1000*60*60*24*10, minEro = 10*60*1000

        if (!paikkatieto.position.longitudeValid || !paikkatieto.position.latitudeValid) {            
            //asema.text = qsTr("defaults to lat: %1, long: %2").arg(FourSqr.lastLat).arg(FourSqr.lastLong)
            //asema.label = qsTr("timestamp") + ": " + paikkatieto.position.timestamp
            pituuspiiri.text = FourSqr.lastLong
            leveyspiiri.text = FourSqr.lastLat            
        } else {
            //asema.text = qsTr("lat: %1, long: %2, alt: %3").arg(paikkatieto.position.coordinate.latitude).arg(paikkatieto.position.coordinate.longitude).arg(paikkatieto.position.coordinate.altitude)
            //asema.label = qsTr("timestamp") + " " + Qt.formatDateTime(paivays)
            pituuspiiri.text = paikkatieto.position.coordinate.longitude
            leveyspiiri.text = paikkatieto.position.coordinate.latitude
            aikaero = new Date().getTime() - pvm.getTime()
        }

        console.log(" pvm " + pvm + " - " + pvm.getTime() )

        //sijainninTila.text = new Date().getTime() + " " + paikkatieto.active + " - " + paikkatieto.valid + " - " + paikkatieto.position.timestamp + " - " + pvm.getTime()

        if (aikaero < minEro) {
            sijaintiTuore = true
        } else
            sijaintiTuore = false

        if (paikkatieto.position.latitudeValid){
            if (aikaero < 60*60*1000){
                aikaaSitten = "(" + qsTr("location determined %1 min ago").arg(Math.round(aikaero/(60*1000))) + ")"
            } else {
                aikaaSitten = "(" + qsTr("location determined %1 hours ago").arg(Math.round(aikaero/(60*60*1000))) + ")"
            }
        }

        return
    }
    // */

    function lisaaListaan(id, nimi, osoite, tyyppi, kuvake, levpii, pitpii) {
        return loydetytBaarit.append({"baariId": id, "nimi": nimi, "osoite": osoite,
                                         "tyyppi": tyyppi, "kuvake": kuvake,
                                         "baarinPituusPiiri": pitpii,
                                         "baarinLeveysPiiri": levpii
                                     });
    }

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

    function naytaKapakanTiedot(jsonVastaus) {
        var kapakkaId, mj="", i=0
        try {
            pubiId = jsonVastaus.response.venue.items[0].venue_id
            if (jsonVastaus.response.venue.count > 1) {
                while (i<jsonVastaus.response.venue.count) {
                    mj += jsonVastaus.response.venue.items[i].venue_name + ", "
                    i++
                }
                console.log("löydettyjä " + i + ": " + mj)
            }
            pageContainer.push(Qt.resolvedUrl("../pages/unTpTarjoaja.qml"),
                               {"tunniste": kapakkaId })
        } catch (err) {
            console.log("error: " + err)
        }

        return
    }

    function paivitaHaetut(vastaus) { // vastaus = JSON(fourSqr-vastaus)
        var haetut = vastaus.response.venues
        var i=0, n=haetut.length, j, m
        var tunnus, nimi, osoite, etaisyys, tyyppi, pitpii, levpii
        var kuvake = ""

        while (i<n) {
            tyyppi = ""
            if ("categories" in haetut[i]) {
                var luokat = haetut[i].categories
                tyyppi = luokat[0].name
                if ("icon" in luokat[0])
                    if ("prefix" in luokat[0].icon)
                        kuvake = luokat[0].icon.prefix + ikoninKoko + luokat[0].icon.suffix
                j = 1
                m = luokat.length
                while (j<m) {
                    if (luokat[j].primary == true) {
                        tyyppi = luokat[j].name
                        j = m
                        if ("icon" in luokat[i])
                            if ("prefix" in luokat[i].icon)
                                kuvake = luokat[j].icon.prefix + ikoninKoko + luokat[j].icon.suffix
                    }
                    j++
                }
            }

            nimi = ""
            if ("name" in haetut[i])
                nimi = haetut[i].name

            osoite = ""
            if (onkoTietoa(haetut[i].location,"address")){
                osoite = haetut[i].location.address
            }
            if (onkoTietoa(haetut[i].location,"distance")){
                if (osoite != "")
                    osoite += ", "
                osoite += haetut[i].location.distance + " m"
            }
            if (onkoTietoa(haetut[i].location,"lat")) {
                levpii = haetut[i].location.lat
            } else
                levpii = leveyspiiri.text
            if (onkoTietoa(haetut[i].location,"lng")) {
                pitpii = haetut[i].location.lng
            } else
                pitpii = pituuspiiri.text

            lisaaListaan(haetut[i].id, nimi, osoite, tyyppi, encodeURI(kuvake), levpii, pitpii)
            i++
        }

        if (n === 0) {
            txtBaari.text = qsTr("None found.")
            txtBaari.label = qsTr("Better luck next time.")
            asetuksetNakyvat = true
        }

        return
    }

    function printableMethod(method) {
        if (method === PositionSource.SatellitePositioningMethods)
            return qsTr("Satellite");
        else if (method === PositionSource.NoPositioningMethods)
            return qsTr("Not available")
        else if (method === PositionSource.NonSatellitePositioningMethods)
            return qsTr("Non-satellite")
        else if (method === PositionSource.AllPositioningMethods)
            return qsTr("Multiple")
        return qsTr("source error");
    }

    function tyhjennaLista() {
        //var i=0, n=loydetytBaarit.count//baariLista.count
        //while (i<n) {
        //    loydetytBaarit.remove(0)
        //    i++
        //}
        loydetytBaarit.clear();

        return
    }

    Timer {
        id: jokoHaetaan
        interval: 1*1000 // ms
        running: true
        repeat: true
        onTriggered: {
            if (paikkatieto.position.latitudeValid){
                koordinaatit()
                if (haettu || haettava.activeFocus)
                    repeat = false
                else
                    haunAloitus("")
            }
        }
    }

    PositionSource {
        id: paikkatieto
        active: true
        updateInterval: 5*60*1000 // 5 min
        onPositionChanged: {
            koordinaatit()
            console.log("paikkatieto vaihtui")
        }
    }

    Component {
        id: baarienTiedot
        ListItem {
            id: baarinTiedot
            //height: Theme.fontSizeMedium*3
            height: baarinNimi.height
            width: sivu.width
            //highlightedColor: Theme.highlightColor
            onClicked: {
                var kuppilaNr = baariLista.indexAt(mouseX,y+mouseY)
                //valittuBaariNr = baariLista.indexAt(mouseX,y+mouseY)
                kopioiBaari(kuppilaNr)
            }

            //property string baarinId: baariId
            //property string katuosoite: osoite
            //property string pipi: baarinPituusPiiri
            //property string lepi: baarinLeveysPiiri

            Row {
                x: Theme.paddingLarge
                width: sivu.width - 2*x

                Rectangle {
                    height: baarinIkoni.height + 2*border.width
                    width: height
                    border.width: 1
                    radius: 5
                    color: "transparent"
                    border.color: (baarinTiedot.baarinId == baarinTunnus) ? Theme.highlightColor :
                                                                            "transparent"
                    Image {
                        id: baarinIkoni
                        source: kuvake

                        //height: Theme.fontSizeMedium*3.3
                        //width: height:
                    }

                }

                TextField {
                    id: baarinNimi
                    text: nimi
                    label: tyyppi
                    readOnly: true
                    width: sivu.width - baarinIkoni.width - 2*Theme.paddingLarge
                    //width: 0.5*sivu.width - x
                    //color: baarinTiedot.highlighted ? Theme.highlightColor : Theme.primaryColor
                    color: (baarinTiedot.baarinId == baarinTunnus) ? Theme.highlightColor :
                                                                     Theme.primaryColor
                    onClicked: {
                        var kuppilaNr = baariLista.indexAt(mouseX,baarinTiedot.y+0.5*height)
                        //valittuBaariNr = baariLista.indexAt(mouseX,baarinTiedot.y+0.5*height)
                        kopioiBaari(kuppilaNr)
                    }
                    //z: -1
                }

                /*
                Label {
                    id: baarinId
                    text: baariId
                    visible: false
                }

                Text {
                    text: osoite
                    visible: false
                    //width: sivu.width - 0.5*x - Theme.paddingLarge
                }

                Text {
                    text: baarinPituusPiiri
                    visible: false
                }

                Text {
                    text: baarinLeveysPiiri
                    visible: false
                }
                // */

            } // row
        }

    } // oluidenTiedot

    SilicaFlickable {
        id: ruutu
        anchors.fill: sivu
        height: sivu.height
        contentHeight: column.height
        width: sivu.width

        VerticalScrollDecorator {}

        XhttpYhteys {
            id: fsYhteys
            anchors.top: parent.top
            z: 1
            onValmis: {
                var jsonVastaus
                try {
                    jsonVastaus = JSON.parse(httpVastaus)
                    if (toiminto === "baareja")
                        paivitaHaetut(jsonVastaus)
                    else if (toiminto === "untpdInfo")
                        naytaKapakanTiedot(jsonVastaus)
                } catch (err) {
                    console.log("error: " + err)
                }
            }

            property int hakuNro: 0

            function haeBaareja(haku) {
                var pp, lp, maara=25, luokat = "", tark = ""
                var kysely = ""

                if (paikkatieto.position.longitudeValid)
                    pp = paikkatieto.position.coordinate.longitude
                else
                    pp = FourSqr.lastLong;

                if (paikkatieto.position.latitudeValid)
                    lp = paikkatieto.position.coordinate.latitude
                else
                    lp = FourSqr.lastLat;

                // 4d4b7105d754a06374d81259 - food
                // 4d4b7105d754a06376d81259 - nightlife spot
                if (tyyppiRajaus.checked)
                    luokat = "4d4b7105d754a06374d81259,4d4b7105d754a06376d81259"
                else
                    luokat = "";

                kysely = FourSqr.searchVenue(tark, true, lp, pp, hakusade, maara,
                                                      luokat, haku);
                xHttpGet(kysely, "baareja");

                return
            }

            function haeUnTpdId(frSqrId) {
                var kysely = UnTpd.lookupFoursquare(frSqrId)
                xHttpGet(kysely, "untpdInfo")
                return
            }

        }

        Column {
            id: column
            width: sivu.width

            DialogHeader {
                title: qsTr("check-in details")
            }

            IconTextSwitch {
                id: asemanTalletus
                icon.source: "image://theme/icon-m-location"
                checked: true
                //highlighted: !sijaintiTuore
                text: checked ? qsTr("shows location") : qsTr("hides location")
                onCheckedChanged: {
                    if (checked == false) {
                        asetuksetNakyvat = false
                    }
                    naytaSijainti = checked
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
                        //x: Theme.paddingLarge

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
                            text: "???"
                            label: qsTr("lng")
                            //wrapMode: Text.WordWrap
                            color: readOnly ? Theme.highlightColor : Theme.primaryColor
                            readOnly: !syotaKoordinaatit.highlighted
                            width: (sivu.width - 2*asetuksetRivi.x - 2*asemaRivi.spacing - syotaKoordinaatit.width )/2
                            //x: Theme.paddingLarge
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator {bottom: -180.0; top: 180.0}
                        }

                        TextField {
                            id: leveyspiiri
                            text: "???"
                            label: qsTr("lat")
                            //wrapMode: Text.WordWrap
                            color: readOnly ? Theme.highlightColor : Theme.primaryColor
                            readOnly: !syotaKoordinaatit.highlighted
                            width: pituuspiiri.width
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator {bottom: -180.0; top: 180.0}
                            //visible: asetuksetNakyvat
                            //x: Theme.paddingLarge
                        }

                        //IconButton {
                            //id: lueAsema
                            //icon.source: "image://theme/icon-m-refresh"
                            //onClicked: koordinaatit()
                            //highlighted: asemanTalletus.checked
                        //}

                    }

                    ComboBox {
                        id: etaisyys
                        width: sivu.width - hakuasetukset.x
                        //visible: asetuksetNakyvat
                        label: qsTr("radius")

                        //width: Theme.fontSizeSmall*7// font.pixelSize*8

                        menu: ContextMenu {
                            //id: drinkMenu
                            MenuItem { text: "50 m" }
                            MenuItem { text: "500 m" }
                            MenuItem { text: "2 km" }
                            //MenuItem { text: qsTr("radius %1").arg("50 m") }
                            //MenuItem { text: qsTr("radius %1").arg("500 m") }
                            //MenuItem { text: qsTr("radius %1").arg("2 km") }
                            MenuItem { text: qsTr("not limited") }
                        }

                        currentIndex: 0

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
                        //visible: asetuksetNakyvat
                        checked: true
                        text: checked? qsTr("limits to Foursquare categories %1 and %2").arg("Food").arg("Nightlife Spot") :
                                       qsTr("searches in all categories")
                    } // */
                }
            }

            ListItem {
                id: valittuKuppila
                width: parent.width - x
                contentHeight: kuvaBaari.height > txtBaari.height ? kuvaBaari.height : txtBaari.height
                x: Theme.paddingMedium
                menu: ContextMenu {
                    visible: valittuKuppila.kuppilaId > 0
                    MenuItem {
                        text: qsTr("venue info")
                    }
                }

                property int kuppilaId: -1

                Image {
                    id: kuvaBaari
                }

                TextField {
                    id: txtBaari
                    width: parent.width - kuvaBaari.width
                    color: asemanTalletus.checked ? Theme.highlightColor : Theme.highlightDimmerColor
                    readOnly: true
                    label: qsTr("check-in location")
                    //x: Theme.paddingLarge
                }
            }

            /*
            Row {
                id: hakurivi
                spacing: Theme.paddingSmall
                x: Theme.paddingMedium

                IconButton {
                    id: tyhjennaHaku
                    icon.source: "image://theme/icon-m-clear"
                    //width: Theme.fontSizeMedium*3
                    onClicked: {
                        haettava.text = ""
                    }
                }

                TextField {
                    id: haettava
                    placeholderText: qsTr("place")
                    //label: qsTr("search text")
                    //text:
                    width: sivu.width - 2*hakurivi.x - tyhjennaHaku.width
                           - hae.width - 2*hakurivi.spacing
                }

                IconButton {
                    id: hae
                    icon.source: "image://theme/icon-m-search"
                    width: Theme.fontSizeMedium*3
                    highlighted: asemanTalletus.checked
                    onClicked: {
                        haunAloitus(haettava.text)
                    }
                }
            } // hakurivi */

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
                property int vapaana: sivu.height - piilotusRivi.y - piilotusRivi.height
                                      - txtBaari.height - haettava.height - 3*column.spacing
                height: vapaana > minKorkeus ? vapaana : minKorkeus
                width: sivu.width
                clip: true
                highlightFollowsCurrentItem: true

                model: ListModel {
                    id: loydetytBaarit
                }

                delegate: baarienTiedot

                VerticalScrollDecorator {}

                onMovementEnded: {
                    //console.log("siirtyminen loppui")
                    if (atYEnd) {
                        //console.log("siirtyminen loppui " + atYEnd)
                        hakunro = hakunro + 1
                        fsYhteys.haeBaareja(haettava.text)
                    }

                }
            }

        }

    }

    onAccepted: {
        UnTpd.postFacebook = face //facebook.checked
        UnTpd.postTwitter = tweet //twitter.checked
        UnTpd.postFoursquare = foursq //foursquare.checked
        console.log("valittu baari " + baarinTunnus + " , " + baari)
    }

    Component.onCompleted: {
        paikkatieto.start()
        koordinaatit()
        sijaintiTuore = false
    }

}
