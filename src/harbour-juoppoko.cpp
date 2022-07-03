/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QScopedPointer>
#include "juomari.h"
#include "untpd.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    juomari juoja, ennustaja;
    unTpd untpdkysely;
    view->engine()->rootContext()->setContextProperty("untpdKysely", &untpdkysely);
    view->engine()->rootContext()->setContextProperty("juoja", &juoja);
    view->engine()->rootContext()->setContextProperty("testaaja", &ennustaja);
    app->setApplicationVersion(JUOPPOKO_VERSIO);
    view->engine()->rootContext()->setContextProperty("unTappdId", UTPD_ID);
    view->engine()->rootContext()->setContextProperty("unTappdSe", UTPD_SECRET);
    view->engine()->rootContext()->setContextProperty("unTappdCb", CB_URL);
    view->engine()->rootContext()->setContextProperty("fsqId", FSQ_ID);
    view->engine()->rootContext()->setContextProperty("fsqSec", FSQ_SECRET);
    view->engine()->rootContext()->setContextProperty("fsqVer", FSQ_VERSIO);
    view->engine()->rootContext()->setContextProperty("ccKohde", CC_KOHDE);

    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();

    /*
    //char *strings[argc+8]; // + s1-s8
    //char *s1 = UTPD_ID;
    //char *s2 = UTPD_SECRET;
    //char *s3 = CB_URL;
    //char *s4 = FSQ_ID;
    //char *s5 = FSQ_SECRET;
    //char *s6 = FSQ_VERSIO;
    //char *s7 = JUOPPOKO_VERSIO;
    //char *s8 = CC_KOHDE;
    //int i;

    for (i=0; i<argc; i++){
        strings[i] = argv[i];
    }

    strings[argc] = s8; // onko käännös pc:lle (i486) vai puhelimeen (armv7hl)
    argc++;
    strings[argc] = s7; // ohjelman versio
    argc++;
    strings[argc] = s6; // 4square versio (version päivämäärä)
    argc++;
    strings[argc] = s5; // 4square salasana
    argc++;
    strings[argc] = s4; // 4square appId
    argc++;
    strings[argc] = s3; // redirect url
    argc++;
    strings[argc] = s2; // unTappd salasana
    argc++;
    strings[argc] = s1; // unTappd appId
    argc++;

    return SailfishApp::main(argc, strings);// */
}
