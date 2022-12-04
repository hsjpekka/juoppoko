.pragma library

var apiUrl = "https://api.foursquare.com/v2/"
//var appId = ""
//var appSecret = ""
//var fsqrVersion = ""
var lastLat = 61.61, lastLong = 22.58

function auth(appId, appSecret, fsqrVersion) {
    return "client_id=" + appId + "&client_secret=" + appSecret + "&v=" + fsqrVersion;
}

function searchVenue(intent, valid, lat, long, radius, limit, category, query) {
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
}
