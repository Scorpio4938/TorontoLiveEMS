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
    public static let licenceName = "Open Government Licence – Ontario"

    /// The Service's web app, which is the page a person can open.
    public static let pageURLString =
        "https://experience.arcgis.com/experience/a22f5295933e48a5b0a4c90cd3c4cae1"

    /// The same page as a URL, for the screens that link to it.
    public static var pageURL: URL? {
        URL(string: pageURLString)
    }

    /// How far back a read reaches.
    ///
    /// **Four hours, which is what the service holds.** Checked rather than assumed: the layer held
    /// eighty records spanning 4.2 hours, oldest to newest, and the Service's own description says a
    /// dot is visible for four hours. Asking for more would return the same records; asking for less
    /// would hide calls that are still there.
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
