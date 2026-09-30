/// The live active-incident feed published by Toronto Fire Services.
///
/// This endpoint is undocumented. It is not on the City's Open Data portal and
/// carries no licence notice on the page that hosts it; it was found by reading
/// the inline JavaScript of the City's "Toronto Fire Active Incidents" page.
/// See `docs/adr/0001-toronto-livecad-xml-as-live-source.md`.
public enum LiveCADFeed {

    /// The live feed's URL.
    ///
    /// It serves an XML snapshot of currently active incidents, refreshed on a
    /// five-minute cycle. There is no history and no clear/close signal.
    public static let urlString = "https://www.toronto.ca/data/fire/livecad.xml"
}
