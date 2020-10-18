import QtQuick 2.0

ListModel {
    function lisaaListaan(kirjaus, bid, aika, kuva, kayttajatunnus, nimi, etiketti, olut,
                          panimo, baari, baariId, maljoja, kohotinko, huuto, juttuja, juttuLista,
                          jutellut){

        return append({"checkinId": kirjaus, "bid": bid, "section": aika,
                          "osoite": kuva, "kayttajatunnus": kayttajatunnus,
                          "tekija": nimi, "paikka": baari, "baariId": baariId,
                          "etiketti": etiketti, "olut": olut, "panimo": panimo,
                          "maljoja": maljoja, "kohotinko": kohotinko,
                          "lausahdus": huuto, "jutteluita": juttuja,
                          "jutut": juttuLista, "mukana": jutellut })
    }

}
