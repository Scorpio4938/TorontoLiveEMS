import Observation
import SwiftUI
import TorontoLiveEMSKit

/// The feed, and everything either screen needs to know about it.
///
/// One model for both tabs rather than one each, because they show the same feed: a map that
/// fetched separately from the list would be able to disagree with it about what is happening.
///
/// The state lived in `ContentView` until there were two screens to share it. It moved here
/// rather than into a tab, because a `@State` in one tab is invisible to the other.
@MainActor
@Observable
final class IncidentFeedModel {

    private(set) var snapshot: LiveCADSnapshot?

    /// Starts with a snapshot already, for previews.
    ///
    /// The feed itself arrives from the network and cannot arrive in a canvas, so a map preview
    /// with no seam to put incidents through would be a preview of an empty map — which is the
    /// one thing it cannot show.
    init(snapshot: LiveCADSnapshot? = nil) {
        self.snapshot = snapshot
    }
    private(set) var failureMessage: String?

    /// Whether what is on screen is the last good result rather than the newest.
    private(set) var isShowingStaleResult = false

    /// Whether a fetch is in flight.
    private(set) var isRefreshing = false

    /// The incidents, or nothing before the first fetch has returned.
    var incidents: [Incident] { snapshot?.incidents ?? [] }

    /// What the read is in flight doing, and whether it is the normal case.
    ///
    /// A refresh returning exactly what we already have is the common outcome, because the feed
    /// only changes every five minutes — so it has to be tellable apart from a tap that did
    /// nothing at all.
    /// Set when a refresh was skipped because the City cannot have republished.
    ///
    /// Not bound to anything any more — the alert it drove made the whole window inert, and it is
    /// shown in the status line instead. Which means it has to take itself back: the next thing to
    /// clear it might be five minutes away, and "already up to date" left standing for five
    /// minutes becomes a claim about a feed that has since moved on.
    var isUpToDate = false

    /// The status line's text and whether it is warning.
    ///
    /// No case for having no snapshot. The line is a section header now, and a section header
    /// only exists when there is a section — the states with nothing on screen are said by the
    /// views that stand in the list's place instead.
    func status() -> FeedStatus? {
        guard let snapshot else {
            return nil
        }
        // "City data as of", not "Last updated". The value is the City's own refresh tick —
        // `update_from_db_time`, which lands on a five-minute boundary — and not the moment we
        // fetched it. "Last updated" left that open to exactly the wrong reading.
        let updated = snapshot.updatedFromDatabaseAt ?? "unknown"
        let base = "City data as of \(updated)"

        // A refresh the City provably cannot have changed is said here rather than skipped in
        // silence. A silent skip is indistinguishable from a dead button, which is the fault this
        // exists to answer.
        if isUpToDate {
            return FeedStatus(text: "\(base) · already up to date", isStale: false)
        }
        if isShowingStaleResult {
            return FeedStatus(text: "\(base) · showing the last result", isStale: true)
        }
        if isRefreshing {
            return FeedStatus(text: "\(base) · checking…", isStale: false)
        }
        return FeedStatus(text: base, isStale: false)
    }

    /// Fetches, unless the City provably has not republished since the tick we hold.
    ///
    /// The feed is a five-minute snapshot of a source that only changes every five minutes, so
    /// between two of its boundaries there is nothing to fetch. Asking anyway would be a request
    /// whose answer we already know, against a server that never offered the endpoint in the
    /// first place. The gate fails open: anything it cannot tell, it lets through.
    func refresh() async {
        guard FeedRefresh.mayHaveRefreshed(since: snapshot?.updatedFromDatabaseAt) else {
            isUpToDate = true
            // Said, then taken back. Four seconds is long enough to be read by someone who just
            // tapped the button and short enough that it is gone before it can be mistaken for the
            // normal state of things. `Task {}` inside a `@MainActor` method inherits the actor,
            // so this writes on the main actor without saying so.
            Task {
                try? await Task.sleep(for: .seconds(4))
                isUpToDate = false
            }
            return
        }
        await load()
    }

    /// Fetches once, when a screen first appears with nothing to show.
    func loadIfEmpty() async {
        guard snapshot == nil else {
            return
        }
        await load()
    }

    private func load() async {
        isUpToDate = false
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            snapshot = try await LiveCADClient().snapshot()
            failureMessage = nil
            isShowingStaleResult = false
        } catch {
            guard snapshot == nil else {
                // Keep what we have and say so, rather than emptying the screen.
                isShowingStaleResult = true
                return
            }
            failureMessage = "The live feed could not be loaded.\n\(error.localizedDescription)"
        }
    }
}
