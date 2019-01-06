import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0
import QtPositioning 5.2
import "../scripts/unTap.js" as UnTpd
import "../scripts/foursqr.js" as FourSqr

Dialog {
    id: sivu
    anchors.leftMargin: Theme.paddingLarge
    anchors.rightMargin: Theme.paddingLarge

    property string baarinTunnus: ""
    property int valittuBaari: 0
    property int hakunro: 0
    property int hakusade: 50
    property string baari: ""
    property bool haettu: false
    property int ikoninKoko: 88 // 32, 44, 64 ja 88 saatavilla

    property bool naytaSijainti: true
    property alias ppiiri: pituuspiiri.text
    property alias lpiiri: leveyspiiri.text
    property bool sijaintiTuore: false
    property string aikaaSitten: ""

    property bool face: false
    property bool foursq: false
    property bool tweet: false

    property bool asetuksetNakyvat: false
    property bool julkaisutNakyvat: false

    function haeBaareja(haku) {
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

        luokat = "4d4b7105d754a06374d81259,4d4b7105d754a06376d81259"
        // 4d4b7105d754a06374d81259 - food
        // 4d4b7105d754a06376d81259 - nightlife spot

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

    function haunAloitus(hakuteksti) {
        tyhjennaLista()
        hakunro = 0
        haettu = true
        kuvaBaari.source = ""

        return haeBaareja(hakuteksti)
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

    function paivitaHaetut(vastaus) { // vastaus = JSON(fourSqr-vastaus)
        var haetut = vastaus.response.venues
        var i=0, n=haetut.length, j, m
        var tunnus, nimi, osoite, etaisyys, tyyppi, pitpii, levpii
        var kuvake = ""

        while (i<n) {
            tyyppi = ""
            if (onkoTietoa(haetut[i],"categories")) {
                var luokat = haetut[i].categories
                tyyppi = luokat[0].name
                if (onkoTietoa(luokat[0],"icon"))
                    if (onkoTietoa(luokat[0].icon,"prefix"))
                        kuvake = luokat[0].icon.prefix + ikoninKoko + luokat[0].icon.suffix
                j = 1
                m = luokat.length
                while (j<m) {
                    if (luokat[j].primary == true) {
                        tyyppi = luokat[j].name
                        j = m
                        if (onkoTietoa(luokat[i],"icon"))
                            if (onkoTietoa(luokat[i].icon,"prefix"))
                                kuvake = luokat[j].icon.prefix + ikoninKoko + luokat[j].icon.suffix
                    }
                    j++
                }
            }

            nimi = ""
            if (onkoTietoa(haetut[i],"name"))
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
        var i=0, n=loydetytBaarit.count//baariLista.count
        while (i<n) {
            loydetytBaarit.remove(0)
            i++
        }

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
                valittuBaari = baariLista.indexAt(mouseX,y+mouseY)
                kopioiBaari(valittuBaari)
            }

            Row {
                x: Theme.paddingLarge
                width: sivu.width - 2*x

                Rectangle {
                    height: baarinIkoni.height + 2*border.width
                    width: height
                    border.width: 1
                    radius: 5
                    color: "transparent"
                    border.color: (baarinId.text == baarinTunnus) ? Theme.highlightColor : "transparent"

                    Image {
                        id: baarinIkoni
                        source: kuvake

                        //height: Theme.fontSizeMedium*3.3
                        //width: height:
                    }

                }

                Label {
                    id: baarinId
                    text: baariId
                    visible: false
                }

                TextField {
                    id: baarinNimi
                    text: nimi
                    label: tyyppi
                    readOnly: true
                    width: sivu.width - baarinIkoni.width - 2*Theme.paddingLarge
                    //width: 0.5*sivu.width - x
                    //color: baarinTiedot.highlighted ? Theme.highlightColor : Theme.primaryColor
                    color: (baarinId.text == baarinTunnus) ? Theme.highlightColor : Theme.primaryColor
                    onClicked: {
                        valittuBaari = baariLista.indexAt(mouseX,baarinTiedot.y+0.5*height)
                        kopioiBaari(valittuBaari)
                    }
                    //z: -1
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

        Column {
            id: column
            width: sivu.width

            DialogHeader {
                title: qsTr("check-in details")
            }

            /*
            Item {
                id: julkaisujenPiilotusRivi
                x: Theme.paddingMedium
                width: sivu.width - 2*x
                height: (julkaisujenPiilotus.height > Theme.fontSizeMedium)? julkaisujenPiilotus.height : Theme.fontSizeMedium

                IconButton {
                    id: julkaisujenPiilotus
                    icon.source: julkaisutNakyvat? "image://theme/icon-m-down" : "image://theme/icon-m-right"
                    onClicked: {
                        julkaisutNakyvat = !julkaisutNakyvat
                    }
                }

                Label {
                    y: julkaisujenPiilotus.y + 0.5*(julkaisujenPiilotus.height - height)
                    x: julkaisujenPiilotus.x + julkaisujenPiilotus.width + Theme.paddingMedium
                    text: (facebook.checked || twitter.checked || foursquare.checked) ? qsTr("postings") : qsTr("no postings")
                }

                MouseArea {
                    anchors.fill: julkaisujenPiilotusRivi
                    onClicked: {
                        julkaisutNakyvat = !julkaisutNakyvat
                    }
                }

            } //

            Item {
                width: sivu.width
                height: facebook.height + twitter.height + foursquare.height
                visible: julkaisutNakyvat

                Rectangle {
                    x: Theme.paddingLarge
                    width: 1
                    height: facebook.height + twitter.height + foursquare.height
                    visible: julkaisutNakyvat
                }

                TextSwitch {
                    id: facebook
                    checked: false
                    text: checked ? qsTr("post to facebook") : qsTr("not to facebook")
                    visible: julkaisutNakyvat
                    x: Theme.paddingLarge
                }

                TextSwitch {
                    id: twitter
                    checked: false
                    text: checked ? qsTr("post to twitter") : qsTr("no tweeting")
                    visible: julkaisutNakyvat
                    x: Theme.paddingLarge
                    y: facebook.height
                }

                TextSwitch {
                    id: foursquare
                    checked: false
                    text: checked ? qsTr("post to foursquare") : qsTr("not to foursquare")
                    visible: julkaisutNakyvat
                    x: Theme.paddingLarge
                    y: twitter.y + twitter.height
                }

            }
            // */

            IconTextSwitch {
                id: asemanTalletus
                icon.source: "image://theme/icon-m-location"
                checked: true
                highlighted: !sijaintiTuore
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
                    color: asemanTalletus.checked ? Theme.highlightColor : Theme.highlightDimmerColor
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

                        TextField {
                            id: pituuspiiri
                            text: "???"
                            label: qsTr("lng")
                            //wrapMode: Text.WordWrap
                            readOnly: !asemanTalletus.checked
                            width: (sivu.width - 2*asetuksetRivi.x - asemaRivi.spacing)/2
                            //width: (sivu.width - asetuksetRivi.width - 2*asetuksetRivi.x - 2*asemaRivi.spacing - lueAsema.width)/2
                            color: asemanTalletus.checked ? Theme.primaryColor : Theme.highlightDimmerColor
                            //visible: asetuksetNakyvat
                            //x: Theme.paddingLarge
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator {bottom: -180.0; top: 180.0}
                            onTextChanged: {
                                sijainninTila.visible = false
                            }
                        }

                        TextField {
                            id: leveyspiiri
                            text: "???"
                            label: qsTr("lat")
                            //wrapMode: Text.WordWrap
                            color: asemanTalletus.checked ? Theme.primaryColor : Theme.highlightDimmerColor
                            //readOnly: !asemanTalletus.checked
                            width: pituuspiiri.width
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

            Row {
                id: valittuRivi
                x: Theme.paddingMedium

                Image {
                    id: kuvaBaari
                }

                TextField {
                    id: txtBaari
                    width: sivu.width - kuvaBaari.width - valittuRivi.x - valittuRivi.spacing
                    color: asemanTalletus.checked ? Theme.highlightColor : Theme.highlightDimmerColor
                    readOnly: true
                    //x: Theme.paddingLarge
                }
            }

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
                    placeholderText: qsTr("search text")
                    //label: qsTr("search text")
                    //text:
                    width: sivu.width - 2*hakurivi.x - tyhjennaHaku.width
                           - hae.width - 2*hakurivi.spacing
                }

                // /*
                IconButton {
                    id: hae
                    icon.source: "image://theme/icon-m-search"
                    width: Theme.fontSizeMedium*3
                    highlighted: asemanTalletus.checked
                    onClicked: {
                        haunAloitus(haettava.text)
                    }
                }// */
            } // hakurivi

            BusyIndicator {
                id: hetkinen
                size: BusyIndicatorSize.Medium
                x: 0.5*(sivu.width - width)
                running: false
                visible: running
            }

            Label {
                id: fourSqrViestit
                x: 0.5*(sivu.width - width)
                text: qsTr("starting search")
                color: Theme.secondaryHighlightColor
                visible: hetkinen.running
            }

            SilicaListView {
                id: baariLista
                height: sivu.height - piilotusRivi.y - piilotusRivi.height
                        - txtBaari.height - hakurivi.height - 3*column.spacing
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
                        haeBaareja(haettava.text)
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
    }

}
