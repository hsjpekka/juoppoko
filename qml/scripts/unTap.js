.pragma library

var callbackURL = "", newBadges, newBadgesSet = false, notificationsRespond // JSON-objekti
var oluetSuosionMukaan = true
var oluenEtiketti = "", oluenHappamuus = -1, oluenId = -1, oluenNimi = "", oluenPanimo = ""
var oluenTyyppi = "", oluenVahvuus = -1, saateSanat = ""
var postFoursquare = false, postFacebook = false, postTwitter = false
var programName = "", queryLimit = 25
var kayttaja = ""
var unTpdId = "" // ohjelman clientId
var unTpOsoite = "https://api.untappd.com/v4" // url
//var unTpdSecret = "" // ohjelman salasana
var unTpToken = "" // käyttäjän valtuutus
var yhteys = ""

function olutVaihtuu(beerId){
    if (beerId != oluenId) {
        oluenEtiketti = "";
        oluenHappamuus = -1;
        oluenId = beerId;
        oluenNimi = "";
        oluenPanimo = "";
        oluenTyyppi = "";
        oluenVahvuus = -1;
        saateSanat = "";
    }
    return;
}

//
// ======= UnTappd API ==========
//post-komennot: addComment, removeComment, checkIn, toast
//get-komennot: muut

function userAut() {
    // access_token=ACESSTOKENHERE
    return "access_token=" + unTpToken;
}

//function appAut() {
//    // client_id=CLIENTID&client_secret=CLIENTSECRET
//    return "client_id=" + unTpdId + "&client_secret=" + unTpdSecret
//}

function acceptFriend(targetId) {// (address1, auth, targetId) {
    // TARGET_ID (int, required) - The target user id that you wish to accept.//"32"
    var endpoint = "/v4/friend/accept/"+ targetId;
    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    //return encodeURI(query);
    return [endpoint, parameters];
}
/*
function addCommentAddress(checkinId) { //(address1, auth, targetId, comment)
    //post-string "&comment=" + comment
    // CHECKIN_ID (int, required) - The checkin id of the check-in you want to add the comment.//"32"
    //comment (string, required) - The text of the comment you want to add. Max of 140 characters.//"&comment=Tou!"
    var endpoint = "/v4/checkin/addcomment/"+ checkinId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
}

function addCommentString(comment){
    //post-string "&comment=" + comment
    //comment (string, required) - The text of the comment you want to add. Max of 140 characters.//"&comment=Tou!"
    var query = "&comment=" + comment

    return encodeURI(query);
} //*/

function addComment(checkinId, comment){
    //post-string "&comment=" + comment
    //CHECKIN_ID (int, required) - The checkin id of the check-in you want to add the comment.//"32"
    //comment (string, required) - The text of the comment you want to add. Max of 140 characters.//"&comment=Tou!"
    var endpoint = "/v4/checkin/addcomment/"+ checkinId;
    //var query = unTpOsoite + endpoint + "?" + userAut();
    //"&comment=" + comment;
    var parameters = "comment=" + comment;
    return [endpoint, encodeURI(parameters)];

}

function addToWishList(targetId) { //(address1, auth, targetId)
    //bid (int, required) - The numeric BID of the beer you want to add your list. //"&bid=32"
    var endPoint = "/v4/user/wishlist/add";
    //var wishBeer = "&bid=" + targetId;
    //var query = unTpOsoite + endPoint + "?" + userAut() + wishBeer;
    var parameters = "bid=" + targetId;

    //return encodeURI(query);
    return [endpoint, parameters];
}
/*
function checkInAddress() {
    //post
    //bid (int, required) - The numeric beer ID you want to check into. //"&bid=32"

    //gmt_offset (string, required) - The numeric value of hours the user is away from the GMT (Greenwich Mean Time), such as -5.//"&gmt_offset=1.5"
    //timezone (string, required) - The timezone of the user, such as EST or PST //"&timezone=EEST"

    //foursquare_id (string, optional) - The MD5 hash ID of the Venue you want to attach the beer checkin. This HAS TO BE the MD5 non-numeric hash from the foursquare v2.
    //geolat (int, optional) - The numeric Latitude of the user. This is required if you add a location.//"&geolat=32"
    //geolng (int, optional) - The numeric Longitude of the user. This is required if you add a location. //"&geolng=32"
    //shout (string, optional) - The text you would like to include as a comment of the checkin. Max of 140 characters. //"&shout=Good beer"
    //rating (int, optional) - The rating score you would like to add for the beer. This can only be 1 to 5 (half ratings are included). You can't rate a beer a 0. //"&rating=3.5"
    //facebook (string, optional) - If you want to push this check-in to the users' Facebook account, pass this value as "on", default is "off" //"&facebook=off"
    //twitter (string, optional) - If you want to push this check-in to the users' Twitter account, pass this value as "on", default is "off" //"&twitter=off"
    //foursquare (string, optional) - If you want to push this check-in to the users' Foursquare account, pass this value as "on", default is "off". You must include a location for this to enabled. //"&foursquare=off"

    //authentication required

    var endpoint = "/v4/checkin/add";

    var address = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(address);
}

function checkInData(beerId, tzone, venueId, position, lat, lng, shout, rating, fbook, twitter, fsquare) { //(address1, auth, beerId, venueId, lat, lng, shout, rating, fbook, twitter, fsquare)
    //post
    //bid (int, required) - The numeric beer ID you want to check into. //"&bid=32"

    //gmt_offset (string, required) - The numeric value of hours the user is away from the GMT (Greenwich Mean Time), such as -5.//"&gmt_offset=1.5"
    //timezone (string, required) - The timezone of the user, such as EST or PST //"&timezone=EEST"

    //foursquare_id (string, optional) - The MD5 hash ID of the Venue you want to attach the beer checkin. This HAS TO BE the MD5 non-numeric hash from the foursquare v2.
    //geolat (int, optional) - The numeric Latitude of the user. This is required if you add a location.//"&geolat=32"
    //geolng (int, optional) - The numeric Longitude of the user. This is required if you add a location. //"&geolng=32"
    //shout (string, optional) - The text you would like to include as a comment of the checkin. Max of 140 characters. //"&shout=Good beer"
    //rating (int, optional) - The rating score you would like to add for the beer. This can only be 1 to 5 (half ratings are included). You can't rate a beer a 0. //"&rating=3.5"
    //facebook (string, optional) - If you want to push this check-in to the users' Facebook account, pass this value as "on", default is "off" //"&facebook=off"
    //twitter (string, optional) - If you want to push this check-in to the users' Twitter account, pass this value as "on", default is "off" //"&twitter=off"
    //foursquare (string, optional) - If you want to push this check-in to the users' Foursquare account, pass this value as "on", default is "off". You must include a location for this to enabled. //"&foursquare=off"

    //authentication required

    var pvm = new Date();
    var gmtOffset = "&gmt_offset=" + (-pvm.getTimezoneOffset()/60).toFixed(1);
    var timezone = "&timezone=" + tzone;
    var query = ""

    query += "bid=" + beerId + gmtOffset + timezone;

    if (venueId != undefined && venueId != ""){
        query += "&geolat=" + lat;
        query += "&geolng=" + lng;
        query += "&foursquare_id=" + venueId;
    } else if (position) {
        query += "&geolat=" + lat;
        query += "&geolng=" + lng;
    }
    if (shout != "")
        query += "&shout=" + shout;
    if (rating > 0)
        query += "&rating=" + rating;
    if (fbook != "")
        query += "&facebook=" + fbook;
    if (twitter != "")
        query += "&twitter=" + twitter;
    if (fsquare != "")
        query += "&foursquare=" + fsquare;

    return encodeURI(query);
}
//*/
function checkIn(beerId, tzone, venueId, position, lat, lng, shout, rating, fbook, twitter, fsquare) {
    //(address1, auth, beerId, venueId, lat, lng, shout, rating, fbook, twitter, fsquare)
    //post
    //bid (int, required) - The numeric beer ID you want to check into. //"&bid=32"

    //gmt_offset (string, required) - The numeric value of hours the user is away from the GMT (Greenwich Mean Time), such as -5.//"&gmt_offset=1.5"
    //timezone (string, required) - The timezone of the user, such as EST or PST //"&timezone=EEST"

    //foursquare_id (string, optional) - The MD5 hash ID of the Venue you want to attach the beer checkin. This HAS TO BE the MD5 non-numeric hash from the foursquare v2.
    //geolat (int, optional) - The numeric Latitude of the user. This is required if you add a location.//"&geolat=32"
    //geolng (int, optional) - The numeric Longitude of the user. This is required if you add a location. //"&geolng=32"
    //shout (string, optional) - The text you would like to include as a comment of the checkin. Max of 140 characters. //"&shout=Good beer"
    //rating (int, optional) - The rating score you would like to add for the beer. This can only be 1 to 5 (half ratings are included). You can't rate a beer a 0. //"&rating=3.5"
    //facebook (string, optional) - If you want to push this check-in to the users' Facebook account, pass this value as "on", default is "off" //"&facebook=off"
    //twitter (string, optional) - If you want to push this check-in to the users' Twitter account, pass this value as "on", default is "off" //"&twitter=off"
    //foursquare (string, optional) - If you want to push this check-in to the users' Foursquare account, pass this value as "on", default is "off". You must include a location for this to enabled. //"&foursquare=off"

    //authentication required
    var endpoint = "/v4/checkin/add";

    var pvm = new Date();
    var gmtOffset = "&gmt_offset=" + (-pvm.getTimezoneOffset()/60).toFixed(1);
    var timezone = "&timezone=" + tzone;
    var parameters = ""

    parameters += "bid=" + beerId + gmtOffset + timezone;

    if (venueId != undefined && venueId != ""){
        parameters += "&geolat=" + lat;
        parameters += "&geolng=" + lng;
        parameters += "&foursquare_id=" + venueId;
    } else if (position) {
        parameters += "&geolat=" + lat;
        parameters += "&geolng=" + lng;
    }
    if (shout != "")
        parameters += "&shout=" + shout;
    if (rating > 0)
        parameters += "&rating=" + rating;
    if (fbook != "")
        parameters += "&facebook=" + fbook;
    if (twitter != "")
        parameters += "&twitter=" + twitter;
    if (fsquare != "")
        parameters += "&foursquare=" + fsquare;

    return [endpoint, encodeURI(parameters)];
}

function getBadges(targetName, offset, limit) { //(address1, appReg, auth, targetName, offset, limit)
    //USERNAME (string, optional) - The username that you wish to call the request upon.
    //    If you do not provide a username - the feed will return results from the authenticated user
    //    (if the access_token is provided) //"hsjpekka"
    //offset (int, optional) - The numeric offset that you want the results to start //"&offset=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    //authentication not required

    var endpoint = "/v4/user/badges/" + targetName;
    var parameters = "";

    //if (unTpToken == "")
    //    parameters +=  appAut();
    //else
    //    parameters +=  userAut();

    if (offset > 0)
        parameters += "&offset=" + offset;

    if (limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getBeerFeed(beerId, maxId, minId, limit) { //(address1, appReg, auth, beerId, maxId, minId, limit)
    var endpoint = "/v4/beer/checkins/" + beerId; //BID (int, required) - The beer ID that you want to display checkins //"132"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var parameters = "";// unTpOsoite + endpoint + "?"; // authentication not required

    //if (unTpToken == "")
    //    parameters +=  appAut();
    //else
    //    parameters +=  userAut();

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId)){
            var tmp = maxId;
            maxId = minId;
            minId = tmp;
        }
        parameters += "&min_id=" + minId;
    }
    if (maxId > 0) {
        parameters += "&max_id=" + maxId
    }
    if (limit > 0) {
        parameters += "&limit=" + limit
    }

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getBeerInfo(targetId, compact) { //(address1, appReg, auth, targetId, compact)
    //BID (int, required) - The Beer ID that you want to display checkins //"32"
    //compact (string, optional) - You can pass "true" here only show the Beer infomation, and remove the "checkins", "media", "variants", etc attributes
                            //"&compact=true"
    //authentication not required

    var endpoint = "/v4/beer/info/" + targetId;

    var parameters = ""; //unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut();
    //else
    //    query +=  userAut();

    if (compact != "") {
        parameters += "compact=" + compact
    };

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getBreweryFeed(breweryId, maxId, minId, limit) { // (address1, appReg, auth, breweryId, maxId, minId, limit)
    var endpoint = "/v4/brewery/checkins/" + breweryId; //BREWERY_ID (int, required) - The brewery ID that you want to display checkins //"132"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var parameters = "";//"unTpOsoite + endpoint + "?"; // authentication not required

    //if (unTpToken == "")
    //    query +=  appAut();
    //else
    //    query +=  userAut();

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId)){
            var tmp = maxId;
            maxId = minId;
            minId = tmp;
        }
        parameters += "&min_id=" + minId;
    }
    if (maxId > 0)
        parameters += "&max_id=" + maxId;

    if (limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getBreweryInfo(targetId, compact) { //(address1, appReg, auth, targetId, compact)
    //BREWERY_ID (int, required) - The Brewery ID that you want to display checkins //"32"
    //compact (string, optional) - You can pass "true" here only show the brewery infomation, and remove the "checkins", "media", "beer_list", etc attributes
                                //"&compact=true"
    //authentication not required

    var endpoint = "/v4/brewery/info/" + targetId;

    var parameters = "";//unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut();
    //else
    //    query +=  userAut();

    if (compact != "")
        parameters = "compact=" + compact;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getFriendsActivityFeed(maxId, minId, limit) { //(address1, auth, maxId, minId, limit)
    var endpoint = "/v4/checkin/recent";
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 // "&limit=34"

    var parameters = "";//unTpOsoite + endpoint + "?" + userAut(); // authentication required

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId)){
            var tmp = maxId;
            maxId = minId;
            minId = tmp;
        }
        parameters += "&min_id=" + minId;
    }

    if (maxId > 0) {
        parameters += "&max_id=" + maxId;
    }

    if (limit > 0) {
        parameters += "&limit=" + limit;
    }

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getFriendsInfo(targetName, offset, limit) { //(address1, appReg, auth, targetName, offset, limit)
    //USERNAME (string, optional) - The username that you wish to call the request upon.
                                    //If you do not provide a username - the feed will return results from the authenticated user
                                    //(if the access_token is provided) //"hsjpekka"
    //offset (int, optional) - The numeric offset that you what results to start//"&offset=132"
    //limit (int, optional) - The number of records that you will return (max 25, default 25) //"&limit=15"
    // authentication not required

    var endpoint = "/v4/user/friends/" + targetName;
    var parameters = "";//unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut();
    //else
    //    query +=  userAut();

    if (offset > 0)
        parameters += "&offset=" + offset;

    if (limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getNotifications(offset, limit) { //(address1, auth, offset, limit)
    var endpoint = "/v4/notifications";
    //offset (int, optional) - The numeric offset that you what results to start
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    // authentication required

    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    if (offset !== undefined && offset > 0)
        parameters += "&offset=" + offset;

    if (limit !== undefined && limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getPendingFriends(offset, limit) { //(address1, auth, offset, limit)
    // offset (int, optional) - The numeric offset that you what results to start //"&offset=32"
    // limit (int, optional) - The number of results to return. (default is all) //"&limit=32"
    //authentication required

    var endpoint = "/v4/user/pending";
    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    if (offset > 0)
        parameters += "&offset=" + offset;
    if (limit > 0)
        parameters += "&limit=" + limit;

    return [endpoint, parameters];
    //return encodeURI(query);
}

function getPubFeed(lat, lng, radius, unit, maxId, minId, limit) { //(address1, appReg, auth, lat, lng, radius, unit, maxId, minId, limit)
    var endpoint = "/v4/thepub/local";
    var parameters = "";//unTpOsoite + endpoint + "?"; // authentication not required
    var latStr = "lat=" + lat; //lat (float, required) - The latitude of the query //"&lat=68.124"
    var lngStr = "&lng=" + lng; //lng (float, required) - The longitude of the query //"&lng=62.124"
    //radius (int, optional) - The max radius you would like the check-ins to start within, max of 25, default is 25 //"&radius=68.124"
    //dist_pref (string, optional) - If you want the results returned in miles or km. Available options: "m", or "km". Default is "m" //"&dist_pref=km"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    parameters += latStr + lngStr;

    if (radius > 0)
        parameters += "&radius=" + radius;

    if (unit != "")
        parameters += "&dist_pref=" + unit;

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId)){
            var tmp = maxId;
            maxId = minId;
            minId = tmp;
        }
        parameters += "&min_id=" + minId;
    }

    if (maxId > 0)
        parameters += "&max_id=" + maxId;

    if (limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getUserBeers(targetName, offset, limit, sort) { //(address1, appReg, auth, targetName, offset, limit, sort)
    //USERNAME (string, optional) - The username that you wish to call the request upon.
        //If you do not provide a username - the feed will return results from the authenticated user
        //(if the access_token is provided) //"hsjpekka"
    //offset (int, optional) - The numeric offset that you what results to start //"&offset=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    //sort (string, optional) - You can sort the results using these values:
        //date - sorts by date (default),
        //checkin - sorted by highest checkin,
        //highest_rated - sorts by global rating descending order,
        //lowest_rated - sorts by global rating ascending order,
        //highest_rated_you - the user's highest rated beer,
        //lowest_rated_you - the user's lowest rated beer //"&sort=highest_rated"
    //authentication not required

    var endpoint = "/v4/user/beers/" + targetName;

    var parameters = "";//unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    if (offset > 0)
        parameters += "&offset=" + offset;

    if (limit > 0)
        parameters += "&limit=" + limit;

    if (sort != "")
        parameters += "&sort=" + sort;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getUserFeed(targetName, maxId, minId, limit) { //(address1, appReg, auth, targetName, maxId, minId, limit)
    var endpoint = "/v4/user/checkins/" + targetName;
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var parameters = "";//unTpOsoite + endpoint + "?";

    // authentication not required
    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId)) {
            var tmp = maxId;
            maxId = minId;
            minId = tmp;
        }
        parameters += "&min_id=" + minId;
    }

    if (maxId > 0)
        parameters += "&max_id=" + maxId;

    if (limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getUserInfo(targetName, compact) { //(address1, appReg, auth, targetName, compact)
    var endpoint = "/v4/user/info/" + targetName; //USERNAME (string, optional) - The username that you wish to call the request upon.
                            //If you do not provide a username - the feed will return results from the authenticated user
                            //(if the access_token is provided) //"hsjpekka"
    //compact (string, optional) - You can pass "true" here only show the user infomation, and remove the "checkins", "media", "recent_brews", etc attributes //"&compact=true"
    // authentication not required

    var parameters = "";//unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    if (compact != "")
        parameters = "compact=" + compact;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getVenueFeed(venueId, maxId, minId, limit) { //(address1, appReg, auth, venueId, maxId, minId, limit)
    var endpoint = "/v4/venue/checkins/" + venueId; //VENUE_ID (int, required) - The Venue ID that you want to display checkins //"132"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var parameters = "";//unTpOsoite + endpoint + "?"; // authentication not required

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId)){
            var tmp = maxId;
            maxId = minId;
            minId = tmp;
        }
        parameters += "&min_id=" + minId;
    }

    if (maxId > 0)
        parameters += "&max_id=" + maxId;

    if (limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function getVenueInfo(targetId, compact) { //(address1, appReg, auth, targetId, compact)
    //VENUE_ID (int, required) - The Venue ID that you want to display s
    //compact (string, optional) - You can pass "true" here only show the venue infomation, and remove the "checkins", "media", "top_beers", etc attributes
                            //"&compact=true"
    //authentication not required
    var endpoint = "/v4/venue/info/" + targetId;

    var parameters = "";//unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    if (compact != "")
        parameters += "compact=" + compact;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function lookupFoursquare(targetId) { //(address1, appReg, auth, targetId)
    //VENUE_ID (string, required) - The foursquare venue v2 ID that you wish to translate into a Untappd venue ID.
    var endpoint = "/v4/venue/foursquare_lookup/" + targetId;

    var parameters = "";//unTpOsoite + endPoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    //return encodeURI(query);
    return [endpoint, parameters];
}

function rejectFriend(targetId) { //(address1, auth, targetId)
    // TARGET_ID (int, required) - The target user id that you wish to reject.//"32"
    var endpoint = "/v4/friend/reject/"+ targetId;
    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    //return encodeURI(query);
    return [endpoint, parameters];
}

function removeComment(commentId) { //(address1, auth, targetId)
    //post-string not used
    // COMMENT_ID (int, required) - The checkin id of the check-in you want to add the comment.//"32"
    var endpoint = "/v4/checkin/deletecomment/"+ commentId;
    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    //return encodeURI(query);
    return [endpoint, parameters];
}

function removeFriend(targetId) { //(address1, auth, targetId)
    // TARGET_ID (int, required) - The target user id that you wish to remove.//"32"
    var endpoint = "/v4/friend/remove/"+ targetId;
    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    //return encodeURI(query);
    return [endpoint, parameters];
}

function removeFromWishList(beerId) { //(address1, auth, targetId)
    //bid (int, required) - The numeric BID of the beer you want to remove from your list. //"&bid=32"
    var endpoint = "/v4/user/wishlist/delete";
    var parameters = "bid=" + beerId;
    //var query = unTpOsoite + endpoint + "?" + userAut() + wishRemoveBeer;

    //return encodeURI(query);
    return [endpoint, parameters];
}

function requestFriend(targetId) { //(address1, auth, targetId)
    // TARGET_ID (int, required) - The target user id that you wish to be your friend.//"32"

    var endpoint = "/v4/friend/request/" + targetId;
    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    //return encodeURI(query);
    return [endpoint, parameters];
}

function searchBeer(qString, offset, limit, sort) { //(address1, appReg, auth, qString, offset, limit, sort)
    //q (string, required) - The search term that you want to search. //"&q=Karhu"
    //offset (int, optional) - The numeric offset that you what results to start //"&offset=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    //sort (string, optional) - You can sort the results using these values:
                            //checkin - sorts by checkin count (default),
                            //name - sorted by alphabetic beer name
                            //"&sort=name"
    //authentication not required

    var endpoint = "/v4/search/beer";

    var parameters = "";//unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    parameters += "q=" + qString;

    if (offset > 0)
        parameters += "&offset=" + offset;
    if (limit > 0)
        parameters += "&limit=" + limit;
    if (sort != "")
        parameters += "&sort=" + sort;

    //return encodeURI(query);
    return [endpoint, encodeURI(parameters)];
}

function searchBrewery(qString, offset, limit) { //(address1, appReg, auth, qString, offset, limit)
    //q (string, required) - The search term that you want to search. //"&q=Olvi"
    //offset (int, optional) - The numeric offset that you what results to start //"&offset=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    //authentication not required

    var endpoint = "/v4/search/brewery";

    var parameters = "";//unTpOsoite + endpoint + "?";

    //if (unTpToken == "")
    //    query +=  appAut()
    //else
    //    query +=  userAut();

    parameters += "q=" + qString;

    if (offset > 0)
        parameters += "&offset=" + offset;
    if (limit > 0)
        parameters += "&limit=" + limit;

    //return encodeURI(query);
    return [endpoint, encodeURI(parameters)];
}

function toast(checkInId) { //(address1, auth, targetId)
    //post-string not used
    //CHECKIN_ID (int, required) - The checkin ID of checkin you want to toast //"32"
    //authentication required

    var endpoint = "/v4/checkin/toast/" + checkInId;
    var parameters = "";//unTpOsoite + endpoint + "?" + userAut();

    //return encodeURI(query);
    return [endpoint, parameters];
}
