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


    /// The live feed's URL.
    ///
    /// It serves an XML snapshot of currently active incidents, refreshed on a
    /// five-minute cycle. There is no history and no clear/close signal.
    public static let urlString = "https://www.toronto.ca/data/fire/livecad.xml"
}
