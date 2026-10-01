import SwiftUI
import TorontoLiveEMSKit

/// The active incidents, as a screen and nothing more.
///
/// This used to be the whole app's body. The chrome that surrounded it — the title, the
/// toolbar, the sheets, the alert — is the *app's* rather than this screen's, and lives in
/// `RootView` now. What is left is the one question this screen answers: what a reader sees
/// when the feed has arrived, when it has failed, and when it is still coming.
///
/// **It reads the feed; it does not own it.** Two screens share one feed, and a second copy
/// would be a second answer to "how old is this data" — which is the question the status line
/// exists to answer honestly.
struct IncidentsPage: View {

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
