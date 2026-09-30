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

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusLine
                Divider()
                content
            }
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
            Task { await load() }
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

    @ViewBuilder
    private var content: some View {
        if let snapshot {
            // The column header is a section header rather than a view sitting outside
            // the List. Outside, its insets were my own guess and the rows' were the
            // system's, so the two never quite lined up. In here the system insets both
            // identically, and a plain list keeps the header pinned while its rows scroll.
            List {
                Section {
                    ForEach(snapshot.incidents) { incident in
                        NavigationLink {
                            IncidentDetailView(incident: incident)
                        } label: {
                            IncidentRow(incident: incident, timeFormat: dispatchTimeFormat)
                        }
                    }
                } header: {
                    columnHeader
                }
            }
            .listStyle(.plain)
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

    /// The column labels, held still above the rows they label.
    ///
    /// No horizontal padding of its own: the List supplies it, which is the point.
    private var columnHeader: some View {
        HStack(alignment: .top, spacing: IncidentRow.spacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                Text(column.label)
                    .font(.caption2.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Every row is a NavigationLink, and its disclosure chevron takes a slice of
            // the row's trailing edge — so the rows lay their five columns out in less
            // width than the header would otherwise claim. Reserving the same slice keeps
            // the labels above the values instead of a little to the right of them.
            // Left at the default font so its width matches the system's chevron.
            Image(systemName: "chevron.right")
                .opacity(0)
        }
    }

    /// The feed's own timestamp, on screen at all times — including before the first
    /// fetch has returned, when it says so rather than disappearing.
    ///
    /// It is the age of the *data*, not of our request, which is what a reader needs in
    /// order to judge whether what they are looking at is current. The City shows the
    /// same value; we add the space after the colon that their page omits.
    ///
    /// A refresh in flight says so here rather than in the toolbar, so the button keeps
    /// its untouched appearance. The feed only changes every five minutes, so a refresh
    /// that returns exactly what we already had is the normal case and needs to be
    /// distinguishable from a tap that did nothing.
    private var statusLine: some View {
        HStack(spacing: 4) {
            if isShowingStaleResult {
                Image(systemName: "exclamationmark.triangle")
            }
            Text(statusText)
            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(isShowingStaleResult ? Color.orange : Color.secondary)
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private var statusText: String {
        guard let snapshot else {
            return failureMessage == nil ? "Fetching…" : "Nothing fetched yet"
        }
        // "City data as of", not "Last updated". The value is the City's own refresh tick
        // — update_from_db_time, which lands on a five-minute boundary — and not the
        // moment we fetched it. "Last updated" left that open to exactly the wrong
        // reading.
        let updated = snapshot.updatedFromDatabaseAt ?? "unknown"
        let base = "City data as of \(updated)"
        if isShowingStaleResult {
            return "\(base) · showing the last result"
        }
        if isRefreshing {
            return "\(base) · checking…"
        }
        return base
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
