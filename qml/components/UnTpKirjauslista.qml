import QtQuick 2.0

ListModel {
    function lisaa(kirjaus, bid, aika, kuva, kayttajatunnus, nimi, etiketti, olut,
                          panimo, baari, baariId, maljoja, kohotinko, huuto, juttuja, juttuLista,
                          jutellut){
        if (kuva === undefined)
            kuva = "";
        if (nimi === undefined)
            nimi = "";
        if (etiketti === undefined)
            etiketti = "";
        if (baari === undefined)
            baari = "";
        if (baariId === undefined)
            baariId = -1;
        if (huuto === undefined)
            huuto = ""
        if (jutellut === undefined)
            jutellut = false
        return append({"checkinId": kirjaus, "bid": bid, "section": aika,
                          "osoite": kuva, "kayttajatunnus": kayttajatunnus,
                          "tekija": nimi, "paikka": baari, "baariId": baariId,
                          "etiketti": etiketti, "olut": olut, "panimo": panimo,
                          "maljoja": maljoja, "kohotinko": kohotinko,
                          "lausahdus": huuto, "jutteluita": juttuja,
                          "jutut": juttuLista, "mukana": jutellut })
    }

}
