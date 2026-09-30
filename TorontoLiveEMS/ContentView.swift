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
                ToolbarItem(placement: .primaryAction) { settingsButton }

                #if os(iOS)
                // The same plain toolbar item as the settings button, in the system's
                // bottom bar rather than the top one, and pushed to the trailing edge —
                // a lone bottom-bar item sits centred without the Spacer.
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    refreshButton
                }
                #else
                ToolbarItem(placement: .primaryAction) { refreshButton }
                #endif
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
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
