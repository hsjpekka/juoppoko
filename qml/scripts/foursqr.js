.pragma library

//var apiUrl = "https://api.foursquare.com/v2/"
var apiProtocol = "https"
var apiServer = "api.foursquare.com"
//var appId = ""
//var appSecret = ""
//var fsqrVersion = ""
var lastLat = 61.61, lastLong = 22.58

//function auth(appId, appSecret, fsqrVersion) {
//    return "client_id=" + appId + "&client_secret=" + appSecret + "&v=" + fsqrVersion;
//}

function searchVenue(query, ll, radius, categories, limit, session) {
//function searchVenue(intent, valid, lat, long, radius, limit, category, query) {
    /* pilgrim API
    var endpoint = "venues/search?"
    var intTag = "&intent="
    var loc = "&ll="
    var radTag = "&radius=" // meters
    var limTag = "&limit=" // places
    var catTag = "&categoryId="
    var queTag = "&query="
    var fsqQuery = apiUrl + endpoint + auth()

    if (intent != "")
        fsqQuery += intTag + intent

    if (valid) {
        loc += lat + "," + long
    } else {
        loc += lastLat + "," + lastLong
    }
    fsqQuery += loc

    if (radius>1)
        fsqQuery += radTag + radius

    if (limit>1)
        fsqQuery += limTag + limit

    if (category != "")
        fsqQuery += catTag + category

    if (query != "")
        fsqQuery += queTag + query


    return encodeURI(fsqQuery)
    // */
    // places API
    var endpoint = "/v3/places/search";
    var parameters = "";
    parameters += "query=" + query;
    if (ll > "") {
        parameters += "&ll=" + ll;
    }
    if (radius > 0) {
        parameters += "&radius=" + radius;
    }
    if (categories > "") {
        parameters += "&categories=" + categories;
    }
    if (limit > 0) {
        parameters += "&limit=" + limit;
    }
    if (session > "") {
        parameters += "&session_token=" + session;
    }
    return [endpoint, parameters];
}
