import SwiftUI
import TorontoLiveEMSKit

/// The police calls, arranged the way the reader chose.
///
/// **The same two arrangements as the fire page, over a different model.** One table, one card, one
/// column header, one status line, one accessibility fallback — the code is shared, and what differs
/// is four columns instead of five and a detail screen of its own. That is the whole point of the
/// presentation layer being generic: two feeds cannot come to look like two apps.
///
/// **It reads the feed; it does not own it.** The feed lives at the root with the fire one, because
/// the reader should not be able to see two different answers to "how current is this".
///
/// **It loads when the reader arrives, not at launch.** The fire feed is read at launch because the
/// map tab needs it either way; nothing else reads the police calls, so asking for them before
/// anybody looks would be a request made for nobody. See ADR-0006 on politeness.
///
/// **It refreshes from the shared control, not by pulling.** The chrome's refresh control acts on the
/// tab the reader is on, so it serves this page the way it serves the fire one. Pulling was
/// deliberately left off both pages: the control is the app's one way to ask, and a second way to do
/// one thing is a second thing to keep working and a second thing to explain.
struct PolicePage: View {

    let feed: PoliceCallFeed

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    @AppStorage(SettingsKey.policeCallTypeStyle)
    private var policeCallTypeStyle: PoliceCallTypeStyle = .words

    /// How far back this page looks, and whether a critical call outside that window is kept.
    ///
    /// Read here rather than at the root, on the same terms as the three above: the preference is
    /// stored, so the screen that applies it is the screen that reads it.
    @AppStorage(SettingsKey.policeCallWindow)
    private var callWindow: PoliceCallWindow = .oneHour



    var body: some View {
        content
            .task {
                // Nothing to show and nothing to say about why: the reader has just opened this for
                // the first time.
                if feed.calls == nil {
                    await feed.load()
                }
            }
    }

    /// Three states, in the order a reader meets them: nothing yet, something, or a failure with
    /// nothing to put in its place. The fire page's shape, over this feed's vocabulary.
    @ViewBuilder
    private var content: some View {
        if let calls = feed.calls {
            switch presentation {
            case .compactTable:
                CompactTableList(
                    rows: calls,
                    columns: CompactColumn<PoliceCall>.police(style: policeCallTypeStyle),
                    timeFormat: dispatchTimeFormat,
                    status: feed.status
                ) { call in
                    PoliceCallDetailView(call: call)
                }
            case .cards:
                // **Four hours of calls is more than a reader can use**, so the recent ones get the page
                // and the rest wait behind one row. A call that has already happened is a log entry
                // rather than a live incident, which is what makes folding it away honest.
                //
                // **Strictly the window, with no exemption.** A critical call outside it is folded
                // with the rest: this page answers "what has been called in lately", and a page that
                // quietly widened its own range to keep a serious call would be answering a question
                // the reader did not ask, and would make the window a suggestion. The map is where
                // severity outranks age, and it says so.
                let split = callWindow.split(calls, keepingCritical: false, now: Date())
                CardsList(
                    rows: split.shown,
                    columns: CompactColumn<PoliceCall>.policeCard(style: policeCallTypeStyle),
                    timeFormat: dispatchTimeFormat,
                    status: feed.status,
                    folded: split.folded.isEmpty
                        ? nil
                        : FoldedCards(
                            // "Earlier", not "the other three hours": the window is a setting, and a
                            // label naming a fixed span would be wrong the moment it changed.
                            label: "Earlier calls · \(split.folded.count)",
                            rows: split.folded
                        )
                ) { call in
                    PoliceCallDetailView(call: call)
                }
            }
        } else if let failureMessage = feed.failureMessage {
            ContentUnavailableView(
                "Police calls unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(failureMessage)
            )
        } else {
            ProgressView("Loading police calls")
        }
    }
}

#Preview {
    NavigationStack {
        PolicePage(feed: PreviewCalls.feed())
    }
}
