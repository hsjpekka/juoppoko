.pragma library

var callbackURL = ""
var newBadges
var newBadgesSet = false
var notificationsRespond // JSON-objekti
var oluetSuosionMukaan = true
var oluenNimi = ""
var oluenEtiketti = ""
var oluenPanimo = ""
var oluenTyyppi = ""
var oluenVahvuus = 0.0
var oluenHappamuus = 0
var oluenId = 0
var postFoursquare = false
var postFacebook = false
var postTwitter = false
var programName = ""
var queryLimit = 25
var shout = ""
var unTpdId = "" // ohjelman clientId
var unTpOsoite = "https://api.untappd.com/v4" // url
var unTpdSecret = "" // ohjelman salasana
var unTpToken = "" // käyttäjän valtuutus

function setBeer(beerId){
    if (beerId != oluenId) {
        oluenId = beerId
        oluenNimi = ""
        oluenEtiketti = ""
        oluenPanimo = ""
        oluenTyyppi = ""
        oluenVahvuus = 0.0
        shout = ""
    }

    return
}

//
// ======= UnTappd API ==========
//post-komennot: addComment, removeComment, checkIn, toast
//get-komennot: muut

function userAut() {
    // access_token=ACESSTOKENHERE
    return "access_token=" + unTpToken
}

function appAut() {
    // client_id=CLIENTID&client_secret=CLIENTSECRET
    return "client_id=" + unTpdId + "&client_secret=" + unTpdSecret
}

function acceptFriend(targetId) {// (address1, auth, targetId) {
    // TARGET_ID (int, required) - The target user id that you wish to accept.//"32"
    var endpoint = "/friend/accept/"+ targetId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
}

function addCommentAddress(checkinId) { //(address1, auth, targetId, comment)
    //post-string "&comment=" + comment
    // CHECKIN_ID (int, required) - The checkin id of the check-in you want to add the comment.//"32"
    //comment (string, required) - The text of the comment you want to add. Max of 140 characters.//"&comment=Tou!"
    var endpoint = "/checkin/addcomment/"+ checkinId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
}

function addCommentString(comment){
    //post-string "&comment=" + comment
    //comment (string, required) - The text of the comment you want to add. Max of 140 characters.//"&comment=Tou!"
    var query = "&comment=" + comment

    return encodeURI(query);
}

function addToWishList(targetId) { //(address1, auth, targetId)
    //bid (int, required) - The numeric BID of the beer you want to add your list. //"&bid=32"
    var endPoint = "/user/wishlist/add";
    var wishBeer = "&bid=" + targetId;
    var query = unTpOsoite + endPoint + "?" + userAut() + wishBeer;

    return encodeURI(query);
}

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

    var endpoint = "/checkin/add";

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

    if (venueId != ""){
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

function getBadges(targetName, offset, limit) { //(address1, appReg, auth, targetName, offset, limit)
    //USERNAME (string, optional) - The username that you wish to call the request upon.
        //If you do not provide a username - the feed will return results from the authenticated user
        //(if the access_token is provided) //"hsjpekka"
    //offset (int, optional) - The numeric offset that you what results to start //"&offset=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    //authentication not required

    var endpoint = "/user/badges/" + targetName;
    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut();
    else
        query +=  userAut();

    if (offset > 0) {
        query += "&offset=" + offset
    };
    if (limit > 0) {
        query += "&limit=" + limit
    };

    return encodeURI(query);
}

function getBeerFeed(beerId, maxId, minId, limit) { //(address1, appReg, auth, beerId, maxId, minId, limit)
    var endpoint = "/beer/checkins/" + beerId; //BID (int, required) - The beer ID that you want to display checkins //"132"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var query = unTpOsoite + endpoint + "?"; // authentication not required

    if (unTpToken == "")
        query +=  appAut();
    else
        query +=  userAut();

    if (minId > 0) {
        query += "&min_id=" + minId

        if ((maxId > 0) && (maxId < minId)) maxId = minId
    };
    if (maxId > 0) {
        query += "&max_id=" + maxId
    };
    if (limit > 0) {
        query += "&limit=" + limit
    };

    return encodeURI(query);
}

function getBeerInfo(targetId, compact) { //(address1, appReg, auth, targetId, compact)
    //BID (int, required) - The Beer ID that you want to display checkins //"32"
    //compact (string, optional) - You can pass "true" here only show the Beer infomation, and remove the "checkins", "media", "variants", etc attributes
                            //"&compact=true"
    //authentication not required

    var endpoint = "/beer/info/" + targetId;

    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut();
    else
        query +=  userAut();

    if (compact != "") {
        query += "&compact=" + compact
    };

    return encodeURI(query);
}

function getBreweryFeed(breweryId, maxId, minId, limit) { // (address1, appReg, auth, breweryId, maxId, minId, limit)
    var endpoint = "/Brewery/checkins/" + breweryId; //BREWERY_ID (int, required) - The brewery ID that you want to display checkins //"132"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var query = unTpOsoite + endpoint + "?"; // authentication not required

    if (unTpToken == "")
        query +=  appAut();
    else
        query +=  userAut();

    if (minId > 0) {
        query += "&min_id=" + minId

        if ((maxId > 0) && (maxId < minId))
            maxId = minId
    };
    if (maxId > 0)
        query += "&max_id=" + maxId

    if (limit > 0)
        query += "&limit=" + limit

    return encodeURI(query);
}

function getBreweryInfo(targetId, compact) { //(address1, appReg, auth, targetId, compact)
    //BREWERY_ID (int, required) - The Brewery ID that you want to display checkins //"32"
    //compact (string, optional) - You can pass "true" here only show the brewery infomation, and remove the "checkins", "media", "beer_list", etc attributes
                                //"&compact=true"
    //authentication not required

    var endpoint = "/brewery/info/" + targetId;

    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut();
    else
        query +=  userAut();

    if (compact != "")
        query += "&compact=" + compact;

    return encodeURI(query);
}

function getFriendsActivityFeed(maxId, minId, limit) { //(address1, auth, maxId, minId, limit)
    var endpoint = "/checkin/recent";
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 // "&limit=34"

    var query = unTpOsoite + endpoint + "?" + userAut(); // authentication required

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId))
            maxId = minId
        query += "&min_id=" + minId
    };

    if (maxId > 0) {
        query += "&max_id=" + maxId
    };

    if (limit > 0) {
        query += "&limit=" + limit
    };

    return encodeURI(query);
}

function getFriendsInfo(targetName, offset, limit) { //(address1, appReg, auth, targetName, offset, limit)
    //USERNAME (string, optional) - The username that you wish to call the request upon.
                                    //If you do not provide a username - the feed will return results from the authenticated user
                                    //(if the access_token is provided) //"hsjpekka"
    //offset (int, optional) - The numeric offset that you what results to start//"&offset=132"
    //limit (int, optional) - The number of records that you will return (max 25, default 25) //"&limit=15"
    // authentication not required

    var endpoint = "/user/friends/" + targetName;
    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut();
    else
        query +=  userAut();

    if (offset > 0)
        query += "&offset=" + offset;

    if (limit > 0)
        query += "&limit=" + limit;

    return encodeURI(query);
}

function getNotifications(offset, limit) { //(address1, auth, offset, limit)
    var endpoint = "/notifications";
    //offset (int, optional) - The numeric offset that you what results to start
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    // authentication required

    var query = unTpOsoite + endpoint + "?" + userAut();

    if (offset > 0)
        query += "&offset=" + offset;

    if (limit > 0)
        query += "&limit=" + limit;

    return encodeURI(query);
}

function getPendingFriends(offset, limit) { //(address1, auth, offset, limit)
    // offset (int, optional) - The numeric offset that you what results to start //"&offset=32"
    // limit (int, optional) - The number of results to return. (default is all) //"&limit=32"
    //authentication required

    var endpoint = "/user/pending";
    var query = unTpOsoite + endpoint + "?" + userAut();

    if (offset > 0)
        query += "&offset=" + offset;
    if (limit > 0)
        query += "&limit=" + limit;

    return encodeURI(query);
}

function getPubFeed(lat, lng, radius, unit, maxId, minId, limit) { //(address1, appReg, auth, lat, lng, radius, unit, maxId, minId, limit)
    var endpoint = "/thepub/local";
    var query = unTpOsoite + endpoint + "?"; // authentication not required
    var latStr = "&lat=" + lat; //lat (float, required) - The latitude of the query //"&lat=68.124"
    var lngStr = "&lng=" + lng; //lng (float, required) - The longitude of the query //"&lng=62.124"
    //radius (int, optional) - The max radius you would like the check-ins to start within, max of 25, default is 25 //"&radius=68.124"
    //dist_pref (string, optional) - If you want the results returned in miles or km. Available options: "m", or "km". Default is "m" //"&dist_pref=km"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    query += latStr + lngStr;

    if (radius > 0)
        query += "&radius=" + radius;

    if (unit != "")
        query += "&dist_pref=" + unit;

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId))
            maxId = minId;
        query += "&min_id=" + minId
    };

    if (maxId > 0)
        query += "&max_id=" + maxId;

    if (limit > 0)
        query += "&limit=" + limit;

    return encodeURI(query);
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

    var endpoint = "/user/beers/" + targetName;

    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    if (offset > 0)
        query += "&offset=" + offset;

    if (limit > 0)
        query += "&limit=" + limit;

    if (sort != "")
        query += "&sort=" + sort;

    return encodeURI(query);
}

function getUserFeed(targetName, maxId, minId, limit) { //(address1, appReg, auth, targetName, maxId, minId, limit)
    var endpoint = "/user/checkins/" + targetName;
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var query = unTpOsoite + endpoint + "?";

    // authentication not required
    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    if (minId > 0) {
        if ((maxId > 0) && (maxId < minId))
            maxId = minId;
        query += "&min_id=" + minId
    };

    if (maxId > 0)
        query += "&max_id=" + maxId;

    if (limit > 0)
        query += "&limit=" + limit;

    return encodeURI(query);
}

function getUserInfo(targetName, compact) { //(address1, appReg, auth, targetName, compact)
    var endpoint = "/user/info/" + targetName; //USERNAME (string, optional) - The username that you wish to call the request upon.
                            //If you do not provide a username - the feed will return results from the authenticated user
                            //(if the access_token is provided) //"hsjpekka"
    //compact (string, optional) - You can pass "true" here only show the user infomation, and remove the "checkins", "media", "recent_brews", etc attributes //"&compact=true"
    // authentication not required

    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    if (compact != "")
        query += "&compact=" + compact;

    return encodeURI(query);
}

function getVenueFeed(venueId, maxId, minId, limit) { //(address1, appReg, auth, venueId, maxId, minId, limit)
    var endpoint = "/venue/checkins/" + venueId; //VENUE_ID (int, required) - The Venue ID that you want to display checkins //"132"
    //max_id (int, optional) - The checkin ID that you want the results to start with //"&max_id=132"
    //min_id (int, optional) - Returns only checkins that are newer than this value //"&min_id=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"

    var query = unTpOsoite + endpoint + "?"; // authentication not required

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    if (minId > 0) {
        query += "&min_id=" + minId;

        if ((maxId > 0) && (maxId < minId))
            maxId = minId
    };

    if (maxId > 0)
        query += "&max_id=" + maxId;

    if (limit > 0)
        query += "&limit=" + limit;

    return encodeURI(query);
}

function getVenueInfo(targetId, compact) { //(address1, appReg, auth, targetId, compact)
    //VENUE_ID (int, required) - The Venue ID that you want to display s
    //compact (string, optional) - You can pass "true" here only show the venue infomation, and remove the "checkins", "media", "top_beers", etc attributes
                            //"&compact=true"
    //authentication not required
    var endpoint = "/venue/info/" + targetId;

    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    if (compact != "")
        query += "&compact=" + compact;

    return encodeURI(query);
}

function lookupFoursquare(targetId) { //(address1, appReg, auth, targetId)
    //VENUE_ID (string, required) - The foursquare venue v2 ID that you wish to translate into a Untappd venue ID.
    var endPoint = "/venue/foursquare_lookup/" + targetId;

    var query = unTpOsoite + endPoint + "?";

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    return encodeURI(query);
}

function rejectFriend(targetId) { //(address1, auth, targetId)
    // TARGET_ID (int, required) - The target user id that you wish to reject.//"32"
    var endpoint = "/friend/reject/"+ targetId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
}

function removeComment(commentId) { //(address1, auth, targetId)
    //post-string not used
    // COMMENT_ID (int, required) - The checkin id of the check-in you want to add the comment.//"32"
    var endpoint = "/checkin/deletecomment/"+ commentId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
}

function removeFriend(targetId) { //(address1, auth, targetId)
    // TARGET_ID (int, required) - The target user id that you wish to remove.//"32"
    var endpoint = "/friend/remove/"+ targetId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
}

function removeFromWishList(beerId) { //(address1, auth, targetId)
    //bid (int, required) - The numeric BID of the beer you want to remove from your list. //"&bid=32"
    var endPoint = "/user/wishlist/delete";
    var wishRemoveBeer = "&bid=" + beerId;
    var query = unTpOsoite + endPoint + "?" + userAut() + wishRemoveBeer;

    return encodeURI(query);
}

function requestFriend(targetId) { //(address1, auth, targetId)
    // TARGET_ID (int, required) - The target user id that you wish to be your friend.//"32"

    var endpoint = "/friend/request/" + targetId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
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

    var endpoint = "/search/beer";

    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    query += "&q=" + qString;

    if (offset > 0)
        query += "&offset=" + offset;
    if (limit > 0)
        query += "&limit=" + limit;
    if (sort != "")
        query += "&sort=" + sort;

    return encodeURI(query);
}

function searchBrewery(qString, offset, limit) { //(address1, appReg, auth, qString, offset, limit)
    //q (string, required) - The search term that you want to search. //"&q=Olvi"
    //offset (int, optional) - The numeric offset that you what results to start //"&offset=132"
    //limit (int, optional) - The number of results to return, max of 50, default is 25 //"&limit=32"
    //authentication not required

    var endpoint = "/search/brewery";

    var query = unTpOsoite + endpoint + "?";

    if (unTpToken == "")
        query +=  appAut()
    else
        query +=  userAut();

    query += "&q=" + qString;

    if (offset > 0)
        query += "&offset=" + offset;
    if (limit > 0)
        query += "&limit=" + limit;

    return encodeURI(query);
}

function toast(checkInId) { //(address1, auth, targetId)
    //post-string not used
    //CHECKIN_ID (int, required) - The checkin ID of checkin you want to toast //"32"
    //authentication required

    var endpoint = "/checkin/toast/" + checkInId;
    var query = unTpOsoite + endpoint + "?" + userAut();

    return encodeURI(query);
}
