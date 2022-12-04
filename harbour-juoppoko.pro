# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-juoppoko

CONFIG += link_pkgconfig
CONFIG += sailfishapp

PKGCONFIG += amberwebauthorization

SOURCES += \
    src/harbour-juoppoko.cpp \
    src/juomari.cpp \
    src/untpd.cpp

OTHER_FILES += \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172 256x256

DISTFILES += \
    qml/components/BarChart.qml \
    qml/components/Juomari.qml \
    qml/components/KulutusKuvaajat.qml \
    qml/components/ModExpandingSection.qml \
    qml/components/XhttpYhteys.qml \
    qml/pages/asetukset.qml \
    qml/pages/demolaskuri.qml \
    qml/pages/eiVerkkoa.qml \
    qml/pages/juomanMuokkaus.qml \
    qml/pages/Kansi.qml \
    qml/pages/Paaikkuna.qml \
    qml/pages/tietoja.qml \
    qml/pages/tilastot.qml \
    qml/pages/unTpAnsiomerkit.qml \
    qml/pages/unTpCheckIn.qml \
    qml/pages/unTpJuomispuheet.qml \
    qml/pages/unTpKaverit.qml \
    qml/pages/unTpKayttaja.qml \
    qml/pages/UnTpKirjauksenKooste.qml \
    qml/pages/unTpKirjautuminen.qml \
    qml/pages/unTpOluet.qml \
    qml/pages/unTpPub.qml \
    qml/pages/unTpTarjoaja.qml \
    qml/pages/unTpTietojaOluesta.qml \
    qml/scripts/foursqr.js \
    qml/scripts/scripts.js \
    qml/scripts/tietokanta.js \
    qml/scripts/unTap.js \
    harbour-juoppoko.desktop \
    rpm/harbour-juoppoko.yaml \
    rpm/harbour-juoppoko.changes.in \
    rpm/harbour-juoppoko.spec \
    qml/harbour-juoppoko.qml

# defines windowsissa "UTPD_ID=\"\\\"$${_CL_ID}\\\"\"", linuxissa XXX
#DEFINES += \
#     "UTPD_ID=\"\\\"$${_CL_ID}\\\"\"" \
#     "UTPD_SECRET=\"\\\"$${_CL_SECRET}\\\"\"" \
#     "FSQ_ID=\"\\\"$${_FSQ_ID}\\\"\"" \
#     "FSQ_SECRET=\"\\\"$${_FSQ_SECRET}\\\"\"" \
#     "CC_KOHDE=\"\\\"$${_CC_KOHDE}\\\"\""\
#     "FSQ_VERSIO=\"\\\"20180712\\\"\"" \
#     "CB_URL=\"\\\"juoppoko.untpd.tunnistus\\\"\"" \
#     "JUOPPOKO_VERSIO=\"\\\"2.5.0\\\"\""

#DEFINES += \
#     UTPD_ID=\\\$${_CL_ID}\\\" \
#     UTPD_SECRET=\\\"$${_CL_SECRET}\\\" \
#     FSQ_ID=\\\"$${_FSQ_ID}\\\" \
#     FSQ_SECRET=\\\"$${_FSQ_SECRET}\\\" \
#     CC_KOHDE=\\\"$${_CC_KOHDE}\\\"\
#     FSQ_VERSIO=\\\"20180712\\\" \
#     CB_URL=\\\"juoppoko.untpd.tunnistus\\\" \
#     JUOPPOKO_VERSIO=\\\"2.5.0\\\"

QT += positioning

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.

TRANSLATIONS += translations/$${TARGET}-fi.ts \
    translations/$${TARGET}-C.ts

HEADERS += \
    src/juomari.h \
    src/salaisuudet.h \
    src/untpd.h
