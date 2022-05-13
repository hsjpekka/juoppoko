#ifndef JUOMARI_H
#define JUOMARI_H

#include <QObject>
#include <QString>
#include <QDate>
#include <QVector>

class juomari : public QObject
{
    Q_OBJECT
public:
    explicit juomari(QObject *parent = nullptr);
    int asetaImeytymisaika(int minuuttia); // < 0, jos epäonnistuu
    int asetaKeho(int paino, double pros, double teho, QDate pvm = QDate::currentDate());
    int asetaKeho(int paino, double pros, double teho, qint64 ms1970);
    int asetaMaksa(double teho, QDate pvm = QDate::currentDate()); // < 0, jos epäonnistuu, normaali teho = 1
    int asetaMaksa(double teho, qint64 ms1970);
    int asetaPaino(double kg, QDate pvm = QDate::currentDate()); // < 0, jos epäonnistuu, muuten painohistorian pituus
    int asetaPaino(double kg, qint64 ms1970);
    int asetaPohjat(double po, QDateTime aika = QDateTime::currentDateTime()); // < 0, jos epäonnistuu
    int asetaPohjat(double po, qint64 ms1970);
    int asetaPromilleraja(double prom);
    int asetaVesimaara(int pros, QDate pvm = QDate::currentDate()); // < 0, jos epäonnistuu, pros = 0.65 naisilla, 0.75 miehillä
    int asetaVesimaara(int pros, qint64 ms1970); // < 0, jos epäonnistuu, pros = 0.65 naisilla, 0.75 miehillä
    int asetaVrkVaihdos(int minuutti);
    int juo(int id, int ml, double prosentteja, QDateTime aika = QDateTime::currentDateTime(), bool paivitaRajat = true); // prosentteja: 4.7% = 4.7, palauttaa < 0, jos epäonnistuu, muuten juotujen määrä
    int juo(int id, int ml, double prosentteja, qint64 ms1970, bool paivitaRajat = true); // prosentteja: 4.7% = 4.7, palauttaa < 0, jos epäonnistuu, muuten juotujen määrä
    double lueMaksa(QDate pvm = QDate::currentDate());
    double luePaino(QDate pvm = QDate::currentDate());
    double lueVesimaara(QDate pvm = QDate::currentDate());
    int muutaJuoma(int id, int ml, double prosentteja, QDateTime aika = QDateTime::currentDateTime(), bool paivitaRajat = true);
    double paljonkoAikana(QDate pvmAlku, QDate pvmLoppu); // ml aikavälillä
    int poistaJuoma(int id, bool tarkistaKaikki=false);
    double polttonopeus(double paino, double maksa = 1.0);
    double promilleja(QDateTime aika = QDateTime::currentDateTime());
    double promilleja(bool veresta, QDateTime aika = QDateTime::currentDateTime());
    QDateTime selvana();
    QDateTime rajalla(double prom);

signals:

private:
    // imeytymisaika - annoksen imeytymiseen kuluva aika [h]
    // raja1 - promilleraja
    double imeytymisaika, raja1;
    QDateTime milloinRajalla, milloinSelvana;
    bool tarkka; // otetaanko laskennassa huomioon painon muutokset ajan myötä
    QTime vrkVaihtuu;

    const int msTunti = 1000*60*60;
    // maksa - maksan tehokkuus - normaali 1.0, huono < 1
    // vesiPros - veden osuus kehon painosta - naisilla 0.65, miehillä 0.75
    // polttonopeusVakio - ml/kg/h -- 1 g/10 kg/h = 1.267 ml/10 kg/h
    // alkoholin tiheys, g/ml
    const double oletusMaksa = 1.0, oletusPaino = 77, oletusVesi = 0.7, polttonopeusVakio = 0.1267, tiheys = 0.7897;

    struct omaKeho { double paino; double maksa; double vesiPros; QDate aika; };
    QVector<omaKeho> keho; // keho[0], kun aika < keho[1].aika
    struct juotu { int id; int ml; double pros; double vatsassaEnnen; double veressaEnnen; QDateTime aika;}; // pros 4.7% = 0.047, vatsassa, veressa [ml]
    QVector<juotu> juodut; // juodut[0] = pohjat, juodut[0].aika = Date(0,0,0)

    int etsiJuomanJarjestys(QDateTime aika);
    int etsiKehonJarjestys(QDate aika);
    int jarjestaJuomat(int i = -1);
    omaKeho kehonOminaisuudet(int iKeho);
    int muutettavaJuoma(int id);
    QDateTime milloinPromilleja(double promilleja, QDateTime aika);
    void paljonkoPohjia(juotu &ryyppy, QDateTime aika, int i);
    double palonopeus(int i = -1);
    void laskeUudelleen(int i = 0); // laskee juodut-taulukon arvot vatsassa ja veressa uudelleen alkaen juomasta i

};

#endif // JUOMARI_H
