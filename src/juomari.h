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
    Q_INVOKABLE double alkoholia(QDateTime aika = QDateTime::currentDateTime(), bool veresta = false);// ml
    Q_INVOKABLE double alkoholia(qint64 aikaMs, bool veresta = false);
    Q_INVOKABLE int asetaImeytymisaika(int minuuttia); // minuuttia keskiyön jälkeen, < 0, jos epäonnistuu
    Q_INVOKABLE int asetaKeho(int paino, double pros, double teho=1.0, QDateTime pvm = QDateTime::currentDateTime());
    Q_INVOKABLE int asetaKeho(int paino, double pros, double teho, qint64 ms1970);
    Q_INVOKABLE int asetaMaksa(double teho, QDateTime pvm = QDateTime::currentDateTime()); // < 0, jos epäonnistuu, normaali teho = 1
    Q_INVOKABLE int asetaMaksa(double teho, qint64 ms1970);
    Q_INVOKABLE int asetaPaino(double kg, QDateTime pvm = QDateTime::currentDateTime()); // < 0, jos epäonnistuu, muuten painohistorian pituus
    Q_INVOKABLE int asetaPaino(double kg, qint64 ms1970);
    Q_INVOKABLE int asetaPohjat(double mlAlkoholia, QDateTime aika = QDateTime::currentDateTime()); // < 0, jos epäonnistuu
    Q_INVOKABLE int asetaPohjat(double mlAlkoholia, qint64 ms1970);
    Q_INVOKABLE int asetaPohjaPromillet(double prom, QDateTime aika = QDateTime::currentDateTime()); // < 0, jos epäonnistuu
    Q_INVOKABLE int asetaPohjaPromillet(double prom, qint64 ms1970);
    Q_INVOKABLE int asetaPromilleraja(double prom);
    Q_INVOKABLE int asetaVesimaara(int pros, QDateTime pvm = QDateTime::currentDateTime()); // < 0, jos epäonnistuu, pros = 0.65 naisilla, 0.75 miehillä
    Q_INVOKABLE int asetaVesimaara(int pros, qint64 ms1970); // < 0, jos epäonnistuu, pros = 0.65 naisilla, 0.75 miehillä
    Q_INVOKABLE int asetaVrkVaihdos(int minuutti);
    Q_INVOKABLE int juo(int id, int ml, double prosentteja, QDateTime aika = QDateTime::currentDateTime(), bool paivita = true); // prosentteja: 4.7% = 4.7, palauttaa < 0, jos epäonnistuu, muuten juotujen määrä
    Q_INVOKABLE int juo(int id, int ml, double prosentteja, qint64 ms1970, bool paivita = true); // prosentteja: 4.7% = 4.7, palauttaa < 0, jos epäonnistuu, muuten juotujen määrä
    Q_INVOKABLE qint64 juodunAika(int id = -1); // ms vuoden 1970 alusta
    Q_INVOKABLE qint64 juodunPaiva(int id = -1); // paivia vuoden 1970 alusta
    Q_INVOKABLE int juotuja();
    Q_INVOKABLE void laskeUudelleen(int i = 0); // laskee juodut-taulukon arvot vatsassa ja veressa uudelleen alkaen juomasta i
    Q_INVOKABLE double lueMaksa(QDateTime pvm = QDateTime::currentDateTime());
    Q_INVOKABLE double luePaino(QDateTime pvm = QDateTime::currentDateTime());
    Q_INVOKABLE double lueVesimaara(QDateTime pvm = QDateTime::currentDateTime());
    Q_INVOKABLE int muutaJuoma(int id, int ml, double prosentteja, QDateTime aika);
    Q_INVOKABLE bool onkoOletukset();
    Q_INVOKABLE void paivitaRajat();
    Q_INVOKABLE double paljonkoAikana(qint64 alku, qint64 loppu, bool paivittain = true); // ml aikavälillä
    Q_INVOKABLE double paljonkoAikana(QDateTime alku, QDateTime loppu, bool paivittain = true); // ml aikavälillä
    Q_INVOKABLE double paljonkoPaivassa(QDateTime loppu, int paivia = 1); // ml
    Q_INVOKABLE double paljonkoPaivassa(qint64 loppu, int paivia = 1); // ml
    Q_INVOKABLE int poistaJuoma(int id, bool tarkistaKaikki=false);
    Q_INVOKABLE double polttonopeus(double paino, double maksa = 1.0);
    Q_INVOKABLE double promilleja(QDateTime aika = QDateTime::currentDateTime(), bool veresta = false);
    Q_INVOKABLE double promilleja(qint64 ms1970, bool veresta = false);
    Q_INVOKABLE QDateTime selvana();
    Q_INVOKABLE QDateTime rajalla();

signals:

private:
    // imeytymisaika - annoksen imeytymiseen kuluva aika [h]
    // raja1 - promilleraja
    double imeytymisaika, raja1;
    QDateTime milloinRajalla, milloinSelvana;
    bool onkoOletusArvot, tarkka; // otetaanko laskennassa huomioon painon muutokset ajan myötä
    QTime vrkVaihtuu;

    const int msTunti = 60*60*1000;
    // maksa - maksan tehokkuus - normaali 1.0, huono < 1
    // vesiPros - veden osuus kehon painosta - naisilla 0.65, miehillä 0.75
    // polttonopeusVakio - ml/kg/h -- 1 g/10 kg/h = 1.267 ml/10 kg/h
    // alkoholin tiheys, g/ml
    const double oletusMaksa = 1.0, oletusPaino = 77, oletusVesi = 0.7, polttonopeusVakio = 0.1267, tiheys = 0.7897;

    struct omaKeho { double paino; double maksa; double vesiPros; QDate aika; };
    QVector<omaKeho> keho; // keho[0], kun aika < keho[1].aika
    struct juotu { int id; int ml; double pros; double vatsassaEnnen; double veressaEnnen; QDateTime aika;}; // pros 4.7% = 0.047, vatsassa, veressa [ml]
    QVector<juotu> juodut; // juodut[0] = pohjat, juodut[0].aika = Date(0,0,0)
    juotu pohjat;
    struct mlMaarat {double vatsassa; double veressa;};

    mlMaarat alkoholiaMl(QDateTime nyt, int iJuoma, int iKeho);
    int etsiJuomanJarjestys(QDateTime aika);
    int etsiKehonJarjestys(QDate aika);
    int jarjestaJuomat(int i = -1);
    omaKeho kehonOminaisuudet(int iKeho);
    int muutettavaJuoma(int id);
    QDateTime milloinPromilleja(double prom, QDateTime aika = QDateTime::currentDateTime());
    double mlPromilleiksi(double ml, QDateTime aika = QDateTime::currentDateTime());
    void paljonkoPohjia(juotu &ryyppy, QDateTime aika, int i);
    double palonopeus(int i = -1);
    double promilletMlitroiksi(double promillet, QDateTime aika = QDateTime::currentDateTime());

};

#endif // JUOMARI_H
