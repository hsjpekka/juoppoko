/*
  Published under New BSD license
  Copyright (C) 2017 Pekka Marjamäki <pekka.marjamaki@iki.fi>

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may
     be used to endorse or promote products derived from this software without specific
     prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "pages"
import "scripts/tietokanta.js" as Tkanta
import "scripts/unTap.js" as UnTpd
import "scripts/foursqr.js" as FourSqr
import QtPositioning 5.2

ApplicationWindow{
    id: juoppoko

    initialPage: paaikkuna
    cover: kansi

    Component.onCompleted: {
        avaaTk();
        asetukset();
        lueJuomari();
        lueJuodut(true);
        if (juoja.onkoOletukset()) {
            kysyAsetukset();
        }
        tiedotLuettu();
    }

    property var tk: null

    signal tiedotLuettu()

    Paaikkuna {
        id: paaikkuna
        onKysyAsetukset: {
            juoppoko.kysyAsetukset()
        }
    }

    Kansi {
        id: kansi
    }

    function asetukset() {
        UnTpd.programName = Qt.application.arguments[0]
        UnTpd.unTpdId = unTappdId
        UnTpd.callbackURL = unTappdCb
        UnTpd.unTpToken = Tkanta.arvoUnTpToken;
        untpdKysely.setOAuthToken(Tkanta.arvoUnTpToken);
        juoja.asetaVrkVaihdos(Tkanta.vrkVaihtuu);
        juoja.asetaPromilleraja(Tkanta.promilleRaja1);
        return;
    }

    function avaaTk() {
        if(tk == null) {
            try {
                tk = LocalStorage.openDatabaseSync("juoppoko", "0.1", "juodun alkoholin paivyri", 10000);
            } catch (err) {
                console.log("Error in opening the database: " + err);
                Tkanta.virheet.push("Error in opening the database: " + err);
            };
        }

        Tkanta.tkanta = tk;
        Tkanta.luoTaulukot();
        Tkanta.lueTkAsetukset();
        return;
    }

    function kysyAsetukset() {
        var dialog = pageStack.push(Qt.resolvedUrl("pages/asetukset.qml"), {
                                        "massa0": juoja.luePaino(), "vetta0": juoja.lueVesimaara(),
                                        "kunto0": juoja.lueMaksa(),
                                        "prom10": Tkanta.promilleRaja1, "prom20": Tkanta.promilleRaja2,
                                        "paiva10": Tkanta.vrkRaja1, "paiva20": Tkanta.vrkRaja2,
                                        "viikko10": Tkanta.vkoRaja1, "viikko20": Tkanta.vkoRaja2,
                                        "vuosi10": Tkanta.vsRaja1, "vuosi20": Tkanta.vsRaja2,
                                        "palonopeus": juoja.polttonopeus(1.0,1.0)//juomari.polttonopeusVakio
                                    });
        dialog.accepted.connect(function() {
            var tulos = 0;
            var pvm = new Date();
            if (juoja.luePaino() != dialog.massa || juoja.lueVesimaara() != dialog.vetta ||
                    juoja.lueMaksa() != dialog.kunto ){
                tulos = juoja.asetaKeho(dialog.massa, dialog.vetta, dialog.kunto, pvm.getTime());
                Tkanta.uusiJuomari(dialog.massa, dialog.vetta, dialog.kunto, pvm.getTime());
            } else {
                console.log("ei muutoksia kehoon");
            }

            Tkanta.promilleRaja1 = dialog.prom1;
            Tkanta.paivitaAsetus(Tkanta.tunnusProm1, Tkanta.promilleRaja1);
            Tkanta.promilleRaja2 = dialog.prom2;
            Tkanta.paivitaAsetus(Tkanta.tunnusProm2, Tkanta.promilleRaja2);
            Tkanta.vrkRaja1 = dialog.paiva1;
            Tkanta.paivitaAsetus(Tkanta.tunnusVrkRaja1, Tkanta.vrkRaja1);
            Tkanta.vrkRaja2 = dialog.paiva2;
            Tkanta.paivitaAsetus(Tkanta.tunnusVrkRaja2, Tkanta.vrkRaja2);
            Tkanta.vkoRaja1 = dialog.viikko1;
            Tkanta.paivitaAsetus(Tkanta.tunnusVkoRaja1, Tkanta.vkoRaja1);
            Tkanta.vkoRaja2 = dialog.viikko2;
            Tkanta.paivitaAsetus(Tkanta.tunnusVkoRaja2, Tkanta.vkoRaja2);
            Tkanta.vsRaja1 = dialog.vuosi1;
            Tkanta.paivitaAsetus(Tkanta.tunnusVsRaja1, Tkanta.vsRaja1);
            Tkanta.vsRaja2 = dialog.vuosi2;
            Tkanta.paivitaAsetus(Tkanta.tunnusVsRaja2, Tkanta.vsRaja2);

            juoja.asetaPromilleraja(dialog.prom1);

        });

        return;
    }

    function lueJuodut(kaikki, alkuAika, loppuAika) { //jos kaikki=true, alku- ja loppuajalla ei merkitystä
        var taulukko;
        var i = 0;

        taulukko = Tkanta.lueTkJuodut(kaikki, alkuAika, loppuAika).rows;
        if (taulukko.length > 0) {
            console.log(qsTr("%1 drinks, latest %2").arg(taulukko.length).arg(taulukko[taulukko.length-1].juoma))
        } else {
            console.log(qsTr("%1 drinks").arg(taulukko.length))
        }

        while (i < taulukko.length) {
            paaikkuna.juomari.juo(taulukko[i].id, taulukko[i].aika,
                      taulukko[i].tilavuus, taulukko[i].prosenttia,
                      taulukko[i].juoma, taulukko[i].kuvaus, taulukko[i].oluenId);
            juoja.juo(taulukko[i].id, taulukko[i].tilavuus,
                        taulukko[i].prosenttia, taulukko[i].aika, false);
            i++;
        }

        return;
    }

    function lueJuomari() {
        var keho, kunto, paino, vetta, i;

        keho = Tkanta.lueTkJuomari();
        if (keho.length > 0){
            i = 0;
            console.log(qsTr("read %1 body records").arg(keho.length));
        } else {
            i = -1;
            console.log(qsTr("no body records"))
        }

        while (i >= 0 && i < keho.length) {
            paino = keho[i].paino;
            vetta = keho[i].neste;
            kunto = keho[i].maksa;
            if (paino < 1 || paino > 400) {
                console.log(qsTr("Weight nr. %1 < 1 kg or > 400 kg, changed to 75 kg.").arg(i+1));
                paino = 75;
            }
            if (vetta < 0.01 || vetta > 1) {
                console.log(qsTr("body water content nr. %1 < 1 % or > 100 %, changed to 70 %.").arg(i+1));
                vetta = 0.7;
            }
            if (kunto < 0.01 || kunto > 3) {
                console.log(qsTr("lever condition nr. %1 < 1 % or > 300 %, changed to 100 %.").arg(i+1));
                kunto = 1.0;
            }
            juoja.asetaKeho(paino, vetta, kunto, keho[i].aika);
            i++;
        }

        return keho.length;
    }

}
