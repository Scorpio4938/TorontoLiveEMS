import SwiftUI
import TorontoLiveEMSKit

/// The fire feed's active incidents, as a screen and nothing more.
///
/// **Named for whose data it is, not for what it shows.** The feed is Toronto Fire Services' — the
/// City's own page for it is *"Toronto Fire Active Incidents"* — and police data is coming, which
/// will want a screen of its own. So the screen, its tab and its title are all **Fire**, and the
/// descriptive phrase lives in *About this Data*, where the City's words belong anyway. Two list
/// screens cannot both be titled "Active Incidents".
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
