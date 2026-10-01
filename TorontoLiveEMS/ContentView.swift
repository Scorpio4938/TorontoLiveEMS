//
//  ContentView.swift
//  TorontoLiveEMS
//
//  Created by Scorpio493.8 on 2026-09-27.
//

import SwiftUI
import TorontoLiveEMSKit

struct ContentView: View {

    @State private var snapshot: LiveCADSnapshot?
    @State private var failureMessage: String?
    @State private var isShowingStaleResult = false
    @State private var isRefreshing = false
    @State private var isShowingSettings = false
    @State private var isShowingAboutData = false
    @State private var isShowingNothingToUpdate = false

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Active Incidents")
            #if os(iOS)
            // Inline rather than large. A large title collapses as the list scrolls while
            // the status line and column header below it stay pinned, so the chrome moves
            // in two directions at once. It also reserves a band of space above the title
            // that a table cannot afford. Inline sits on the same bar as the settings
            // button, rather than on a band above it, and does not move.
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                // One group, not several items sharing a placement. `ToolbarItemGroup` is the
                // API for more than one control in the same spot, and the order below is then
                // the order on screen — which is what keeps settings in the rightmost slot it
                // has always had. Two separate `ToolbarItem`s would also put them side by side,
                // but their left-to-right order would be something this code asserted rather
                // than something it decided, and nothing here can check which it is.
                ToolbarItemGroup(placement: .primaryAction) {
                    #if !os(iOS)
                    // On iOS this is in the bottom bar, where a thumb reaches it.
                    refreshButton
                    #endif
                    infoButton
                    settingsButton
                }

                #if os(iOS)
                // The same plain toolbar item, in the system's bottom bar rather than the top
                // one, and pushed to the trailing edge.
                //
                // `ToolbarSpacer` rather than a bare `Spacer()`. Both push the button over, but
                // the first is the API for it — `@available(iOS 26.0, macOS 26.0, *)`, checked
                // in the SDK's own interface, where a `Spacer` in a toolbar is a view that
                // happens to have that effect.
                //
                // **A sibling of the group, not a child of it.** `ToolbarSpacer` conforms to
                // `ToolbarContent` and not to `View`, and `ToolbarItemGroup`'s content is a
                // `ViewBuilder` — so `ToolbarSpacer()` inside the braces does not compile:
                // "generic struct 'ToolbarItemGroup' requires that 'ToolbarSpacer' conform to
                // 'View'". It is a toolbar item in its own right, which is what makes it the API
                // for this. The button needs a `ToolbarItem` of its own to go with it.
                ToolbarSpacer(placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    refreshButton
                }
                #endif
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingAboutData) {
                AboutThisDataView()
            }
            .alert("Up to Date", isPresented: $isShowingNothingToUpdate) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(nothingToUpdateMessage)
            }
        }
        // Runs when the view appears. It deliberately does not run again when the app
        // comes back from the background: the previous result is still in memory, and the
        // feed cannot have changed more than once in five minutes anyway. The feed is an
        // undocumented path on the City's server, so the app asks for it only when it has
        // nothing to show, or when someone taps refresh.
        .task {
            if snapshot == nil {
                await load()
            }
        }
    }

    /// Unchanged from the original: a plain labelled button inside a toolbar item, with
    /// no button style, background or padding of its own, so the platform draws it.
    private var refreshButton: some View {
        Button {
            Task { await refresh() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }

    /// The same shape as the refresh button, in the platform's standard spot for it.
    private var settingsButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }

    /// What the fields mean, and where the data comes from. Reference material, so it is a
    /// button of its own rather than a row in Settings — somebody wondering what an Alarm Level
    /// is should not have to guess that it is filed under preferences.
    private var infoButton: some View {
        Button {
            isShowingAboutData = true
        } label: {
            Label("About this Data", systemImage: "info.circle")
        }
    }

    /// Refreshes, unless the City provably has not republished since the tick we hold.
    ///
    /// The feed is a five-minute snapshot of a source that only changes every five
    /// minutes, so between two of its boundaries there is nothing to fetch. Asking anyway
    /// would be a request whose answer we already know, against a server that never
    /// offered the endpoint in the first place.
    ///
    /// The message is an alert rather than a change to the status line, because the whole
    /// reason this exists is that a tap has to be visibly acknowledged — a silent skip is
    /// indistinguishable from the dead button reported earlier.
    private func refresh() async {
        guard FeedRefresh.mayHaveRefreshed(since: snapshot?.updatedFromDatabaseAt) else {
            isShowingNothingToUpdate = true
            return
        }
        await load()
    }

    private var nothingToUpdateMessage: String {
        let updated = snapshot?.updatedFromDatabaseAt ?? "an unknown time"
        return "Nothing newer than \(updated)."
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot {
            switch presentation {
            case .compactTable:
                CompactTableList(
                    incidents: snapshot.incidents,
                    timeFormat: dispatchTimeFormat,
                    status: status(for: snapshot)
                )
            case .cards:
                CardsList(
                    incidents: snapshot.incidents,
                    timeFormat: dispatchTimeFormat,
                    status: status(for: snapshot)
                )
            }
        } else if let failureMessage {
            ContentUnavailableView(
                "Live feed unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(failureMessage)
            )
        } else {
            ProgressView("Loading active incidents")
        }
    }

    /// The feed's own timestamp, and whether what is on screen is the last good result.
    ///
    /// It is the age of the *data*, not of our request, which is what a reader needs in
    /// order to judge whether what they are looking at is current. The City shows the same
    /// value; we add the space after the colon that their page omits.
    ///
    /// A refresh in flight says so here rather than in the toolbar, so the button keeps its
    /// untouched appearance. The feed only changes every five minutes, so a refresh that
    /// returns exactly what we already had is the normal case and has to be
    /// distinguishable from a tap that did nothing.
    ///
    /// No case for having no snapshot. This used to be drawn outside the list, where it was
    /// visible while the first fetch was in flight and could say "Fetching…". A section
    /// header only exists when there is a section, and the list is only built from a
    /// snapshot — so those states are now said by the `ProgressView` and the
    /// `ContentUnavailableView` that stand in the list's place, which is where a reader
    /// looks for them anyway.
    private func status(for snapshot: LiveCADSnapshot) -> FeedStatus {
        // "City data as of", not "Last updated". The value is the City's own refresh tick
        // — update_from_db_time, which lands on a five-minute boundary — and not the moment
        // we fetched it. "Last updated" left that open to exactly the wrong reading.
        let updated = snapshot.updatedFromDatabaseAt ?? "unknown"
        let base = "City data as of \(updated)"

        if isShowingStaleResult {
            return FeedStatus(text: "\(base) · showing the last result", isStale: true)
        }
        if isRefreshing {
            return FeedStatus(text: "\(base) · checking…", isStale: false)
        }
        return FeedStatus(text: base, isStale: false)
    }

    private func load() async {
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

#Preview {
    ContentView()
}
