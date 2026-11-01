import Foundation

/// The live calls-for-service service published by the Toronto Police Service.
///
/// **A documented API this time, not a path found in a page.** The fire feed is an undocumented XML
/// document somebody found by reading JavaScript; this is a feature service on ArcGIS Online, with
/// a published schema, a written licence and an API that Esri documents. A person reaches it through
/// the Service's own web app, which is `pageURLString`; the app reads the query endpoint.
///
/// See `docs/adr/0006-tps-calls-for-service-as-the-police-source.md`.
public enum CallsForServiceFeed {

    /// The query endpoint, without its parameters.
    ///
    /// The layer is `0` and the service has only that one. `f=json` rather than `f=geojson` is
    /// deliberate: Esri's GeoJSON **stringifies every attribute**, so `OCCURRENCE_TIME` arrives as
    /// `"1791219259000"`, while its own JSON keeps numbers as numbers. Nothing needs the geometry,
    /// because the point is published as two attributes — so the typed response is less code, not
    /// more.
    public static let endpointURLString =
        "https://services.arcgis.com/S9th0jAJ7bqgIRjw/arcgis/rest/services/C4S_Public_NoGO/FeatureServer/0/query"

    /// The Service's own names for the thing and for itself.
    public static let pageName = "TPS Calls for Service"
    public static let provider = "Toronto Police Service"

    /// The licence the calls are published under, which is neither Toronto's nor Canada's.
    public static let licenceName = DataLicence.ontario.title

    /// The Service's web app, which is the page a person can open.
    ///
    /// Linked from *About*'s Sources row rather than from the police information screen, which is
    /// where a reader looks for provenance rather than for a field's explanation.
    public static let pageURLString =
        "https://experience.arcgis.com/experience/a22f5295933e48a5b0a4c90cd3c4cae1"

    /// The same page as a URL, for the screens that link to it.
    public static var pageURL: URL? {
        URL(string: pageURLString)
    }

    /// Where the layer describes itself, which is where its own clock is.
    ///
    /// **Not the query endpoint, and it must ask for JSON.** A `query` cannot be asked for the layer's
    /// edit time — this service's `advancedQueryCapabilities` offers no `returnEditMoment`, checked —
    /// so the app asks the layer what it is and reads `editingInfo.dataLastEditDate` out of the answer.
    /// That response is 10.5 KB against 22.7 KB for the calls themselves, and it is what the police
    /// feed compares on every refresh — see `PoliceCallFeed`.
    ///
    /// **`?f=json` is not decoration.** Without it this same address answers an 8.8 KB *HTML page* —
    /// ArcGIS's human-readable layer directory, `Layer: C4S_Public_NoGO (ID:0)` — which decodes to
    /// nothing, so the app had no clock to quote and said "an unknown time" while looking perfectly
    /// healthy. Every measurement that found this time used `?f=json`; the URL did not.
    public static let layerURLString =
        "https://services.arcgis.com/S9th0jAJ7bqgIRjw/arcgis/rest/services/C4S_Public_NoGO/FeatureServer/0?f=json"

    /// The same layer as a URL, for the client.
    public static var layerURL: URL? {
        URL(string: layerURLString)
    }

    /// What the dataset is, in the Service's own words.
    ///
    /// Quoted verbatim from the item that publishes it, which is the whole of what the Service says
    /// about its own data in machine-readable form: the item and its layer both leave `description`
    /// empty. There is no cadence statement anywhere in either — see `cadenceNote`.
    public static let sourceNote = """
        Calls for Service dataset prepared for public use.
        """

    /// How long a call stays, in this app's words.
    ///
    /// **The window, and one clause about asking rather than assuming a pace.** Nothing in the layer's
    /// metadata states an interval, and the two figures the publisher has contradicted itself over are
    /// not a schedule. The app asks the Service when it last wrote; what a reader needs from this note
    /// is how long a call they see will remain.
    public static let cadenceNote = """
        A call stays here for four hours and then goes. The app asks the Service when it last \
        wrote rather than assuming a pace.
        """

    /// How far back a read reaches.
    ///
    /// **Four hours, which is what the service holds.** Checked rather than assumed: the layer held
    /// eighty records spanning 4.2 hours, oldest to newest, on 2026-10-05. Asking for more would
    /// return the same records; asking for less would hide calls that are still there.
    public static let window: TimeInterval = 4 * 60 * 60

    /// The fields to read, named rather than asked for wholesale.
    ///
    /// `OCCURRENCE_TIME_AGOL` is left out: it is the same instant as `OCCURRENCE_TIME`, kept by the
    /// platform, and two copies of one value in one struct is a way for them to disagree.
    public static let outFields = [
        "OBJECTID",
        "OCCURRENCE_TIME",
        "DIVISION",
        "LATITUDE",
        "LONGITUDE",
        "CALL_TYPE_CODE",
        "CALL_TYPE",
        "CROSS_STREETS",
    ].joined(separator: ",")

    /// The query for the calls in the window ending at `now`.
    ///
    /// **A time filter needs a literal, and a bare number answers 400.** That was measured, not
    /// guessed: `OCCURRENCE_TIME > 1791219259000` returns *"Invalid query parameters"*, and
    /// `OCCURRENCE_TIME > TIMESTAMP '2026-10-05 15:12:00'` works. The literal is in **UTC**, which
    /// was also measured — a literal set to the current UTC instant returns nothing, where a
    /// literal read as local time four hours behind would have returned records.
    ///
    /// `returnGeometry=false` because the point is in the attributes, so nothing is fetched twice.
    ///
    /// **`orderByFields` is a convenience, not the app's ordering.** It asks for newest first, and the
    /// Service currently answers that way — but a response's order is the Service's to change, so
    /// `PoliceCallFeed` sorts the calls it receives by their instants and never relies on this.
    public static func queryURL(now: Date) -> URL? {
        let since = now.addingTimeInterval(-window)
        let stamp = utcStamp(since)

        var components = URLComponents(string: endpointURLString)
        components?.queryItems = [
            .init(name: "where", value: "OCCURRENCE_TIME > TIMESTAMP '\(stamp)'"),
            .init(name: "outFields", value: outFields),
            .init(name: "returnGeometry", value: "false"),
            .init(name: "orderByFields", value: "OCCURRENCE_TIME DESC"),
            .init(name: "f", value: "json"),
        ]
        return components?.url
    }

    /// `2026-10-05 15:12:00`, in UTC.
    private static func utcStamp(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return String(
            format: "%04d-%02d-%02d %02d:%02d:%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0,
            parts.hour ?? 0,
            parts.minute ?? 0,
            parts.second ?? 0
        )
    }
}
