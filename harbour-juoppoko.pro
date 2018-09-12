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

CONFIG += sailfishapp

SOURCES += \
    src/harbour-juoppoko.cpp

OTHER_FILES += \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

DISTFILES += \
    qml/pages/asetukset.qml \
    qml/pages/juomanMuokkaus.qml \
    qml/pages/tietoja.qml \
    qml/pages/Paaikkuna.qml \
    qml/pages/Kansi.qml \
    harbour-juoppoko.desktop \
    rpm/harbour-juoppoko.yaml \
    rpm/harbour-juoppoko.changes.in \
    rpm/harbour-juoppoko.spec \
    qml/harbour-juoppoko.qml \
    qml/pages/tilastot.qml \
    qml/pages/demolaskuri.qml \
    qml/scripts/scripts.js \
    qml/pages/unTpBaarit.qml \
    qml/scripts/tietokanta.js

DEFINES += \
     "UTPD_ID=\"\\\"$${_CL_ID}\\\"\"" \
     "UTPD_SECRET=\"\\\"$${_CL_SECRET}\\\"\"" \
     "CB_URL=\"\\\"$${_CB_URL}\\\"\"" \
     "FSQ_ID=\"\\\"$${_FSQ_ID}\\\"\"" \
     "FSQ_SECRET=\"\\\"$${_FSQ_SECRET}\\\"\"" \
     "FSQ_VERSION=\"\\\"$${_FSQ_VERSION}\\\"\""

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
