import SwiftUI
import TorontoLiveEMSKit

/// The fire feed's active incidents, as a screen and nothing more.
///
/// **Named for whose data it is, not for what it shows.** The feed is Toronto Fire Services' — the
/// City's own page for it is *"Toronto Fire Active Incidents"* — and police data is coming, which
/// will want a screen of its own. So the screen and its tab are **Fire**, and the title says what
/// the screen holds: **Active Fire Incidents**. Two list screens cannot both be titled "Active
/// Incidents", and naming each by its source is what tells them apart.
///
/// **Why the title is not just "Fire".** It was, for a few minutes, to match the tab — and the tab
/// is the right place for the short name, because a tab is a label in a bar. The title is a
/// sentence above the table, where there is room to say whose incidents these are and that they are
/// active, which is what a reader arriving on this screen wants to know.
///
/// This used to be the whole app's body. The chrome that surrounded it — the title, the toolbar,
/// the sheets, the alert — is the *app's* rather than this screen's, and lives in `RootView` now.
/// What is left is the one question this screen answers: what a reader sees when the feed has
/// arrived, when it has failed, and when it is still coming.
///
/// **It reads the feed; it does not own it.** Two screens share one feed, and a second copy would
/// be a second answer to "how old is this data" — which is the question the status line exists to
/// answer honestly. When police data arrives it will be a second feed, not a second copy of this
/// one, and this sentence is what says so.
struct FirePage: View {

    let feed: IncidentFeed

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    var body: some View {
        content
    }

    /// Three states, in the order a reader meets them: nothing yet, something, or a failure
    /// with nothing to put in its place.
    @ViewBuilder
    private var content: some View {
        if let snapshot = feed.snapshot {
            switch presentation {
            case .compactTable:
                CompactTableList(
                    incidents: snapshot.incidents,
                    timeFormat: dispatchTimeFormat,
                    status: feed.status
                )
            case .cards:
                CardsList(
                    incidents: snapshot.incidents,
                    timeFormat: dispatchTimeFormat,
                    status: feed.status
                )
            }
        } else if let failureMessage = feed.failureMessage {
            ContentUnavailableView(
                "Live feed unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(failureMessage)
            )
        } else {
            ProgressView("Loading active incidents")
        }
    }
}
