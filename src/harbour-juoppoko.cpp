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

#ifndef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QScopedPointer>
#include "juomari.h"
#include "untpd.h"
#include "salaisuudet.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());
    juomari juoja, ennustaja;
    unTpd untpdkysely;

    app->setApplicationVersion(JUOPPOKO_VERSIO);

    untpdkysely.setOAuthId(UTPD_ID);
    untpdkysely.setOAuthSecret(UTPD_SECRET);
    untpdkysely.setOAuthRedirect(CB_URL);
    //untpdkysely.setServer("https","api.untappd.com");
    untpdkysely.setOAuthPath("https://untappd.com/oauth/authenticate/");
    untpdkysely.setOAuthTokenPath("https://untappd.com/oauth/authorize/");
    untpdkysely.setQueryParameter("fsqClientId", FSQ_ID, "client_id");
    untpdkysely.setQueryParameter("fsqClientSecret", FSQ_SECRET, "client_secret");
    untpdkysely.setQueryParameter("fsqVersion", FSQ_VERSIO, "v");
    untpdkysely.setQueryParameter("fsqAPIkey", FSQ_APIKEY, "Authorization");

    view->engine()->rootContext()->setContextProperty("unTappdId", UTPD_ID);
    view->engine()->rootContext()->setContextProperty("unTappdCb", CB_URL);
    //view->engine()->rootContext()->setContextProperty("fsqAPIkey", FSQ_APIKEY);
    view->engine()->rootContext()->setContextProperty("untpdKysely", &untpdkysely);
    view->engine()->rootContext()->setContextProperty("juoja", &juoja);
    view->engine()->rootContext()->setContextProperty("testaaja", &ennustaja);

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
