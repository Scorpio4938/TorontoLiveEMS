/// The live active-incident feed published by Toronto Fire Services.
///
/// This endpoint is undocumented. It is not on the City's Open Data portal and
/// carries no licence notice on the page that hosts it; it was found by reading
/// the inline JavaScript of the City's "Toronto Fire Active Incidents" page.
/// See `docs/adr/0001-toronto-livecad-xml-as-live-source.md`.
public enum LiveCADFeed {

    /// Where the incidents come from, in the City's own words.
    ///
    /// The app has always known the five-minute cadence — the refresh button is gated on it —
    /// and never once said so on screen. This is the sentence that says it, from the page the
    /// feed belongs to.
    public static let sourceNote = """
        The following active incidents are dispatched from Toronto Fire Services Communication \
        Centre. The contents are updated at five minute intervals from the CAD (Computer Aided \
        Dispatch) system.
        """


    /// The City's own name for the page the feed belongs to.
    ///
    /// Kept here rather than typed into the screens that name it, because it appears in the
    /// documentation as well and a page renamed by the City should be renamed in one place.
    public static let pageName = "Toronto Fire Active Incidents"

    /// The City's page for these incidents.
    ///
    /// Not the same thing as `urlString`: that serves the XML the app reads, and this is the
    /// page a person can open. We link to the second and merely fetch the first — the feed is
    /// undocumented and was never offered for readers.
    public static let pageURLString =
        "https://www.toronto.ca/community-people/public-safety-alerts/alerts-notifications/toronto-fire-active-incidents/"

    /// The same page as a URL, for the places that need one.
    ///
    /// Optional because `URL(string:)` is, not because this one can fail — and the test asserts it
    /// parses, so a typo in the string above is caught where a typo belongs, rather than by a link
    /// that quietly does nothing when a reader taps it. That is the whole reason this exists rather
    /// than a `URL(string:)!` in a view: a force-unwrap in a screen is an assertion nobody tested.
    public static var pageURL: URL? {
        URL(string: pageURLString)
    }

    /// The live feed's URL.
    ///
    /// It serves an XML snapshot of currently active incidents, refreshed on a
    /// five-minute cycle. There is no history and no clear/close signal.
    public static let urlString = "https://www.toronto.ca/data/fire/livecad.xml"
}
