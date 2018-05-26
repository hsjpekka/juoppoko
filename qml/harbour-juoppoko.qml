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
import "pages"
import "scripts/unTap.js" as UnTpd

ApplicationWindow
{
    id: app

    Paaikkuna {
        id: paaikkuna
    }

    Kansi {
        id: kansi
    }

    initialPage: paaikkuna
    cover: kansi

    property int args: Qt.application.arguments.length

    Component.onCompleted: { //paaikkuna ja kansi luodaan ennen tätä vaihetta
        UnTpd.unTpOsoite = "https://api.untappd.com/v4"
        UnTpd.unTpdId = Qt.application.arguments[args-6]
        UnTpd.unTpdSecret = Qt.application.arguments[args-5]
        UnTpd.callbackURL = Qt.application.arguments[args-4]
        UnTpd.fSqId = Qt.application.arguments[args-3]
        UnTpd.fSqSecret = Qt.application.arguments[args-2]
        UnTpd.fSqVersion = Qt.application.arguments[args-1]

        /*
        var viesti = "ep " + UnTpd.unTpOsoite + " utpId " + UnTpd.unTpdId + " utpSecret " + UnTpd.unTpdSecret
                + " cbUrl " + UnTpd.callbackURL + " 4Id " + UnTpd.fSqId + " 4Secret " + UnTpd.fSqSecret
                + " 4v " + UnTpd.fSqVersion
        //console.log(viesti)
        // */

    }
}
