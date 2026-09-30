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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusLine
                if snapshot != nil {
                    columnHeader
                }
                Divider()
                content
            }
            .navigationTitle("Active Incidents")
            #if os(iOS)
            // Without this the title is large and collapses as the list scrolls, while
            // the column header below it stays put — which reads as the header row
            // drifting away from the columns it belongs to.
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                // The same toolbar item as before, in the system's bottom bar rather
                // than the top one. Left as a plain toolbar item so it keeps the
                // platform's own styling.
                ToolbarItem(placement: .bottomBar) { refreshButton }
                #else
                ToolbarItem(placement: .primaryAction) { refreshButton }
                #endif
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

    @ViewBuilder
    private var content: some View {
        if let snapshot {
            List(snapshot.incidents) { incident in
                NavigationLink {
                    IncidentDetailView(incident: incident)
                } label: {
                    IncidentRow(incident: incident)
                }
            }
            .listStyle(.plain)
            .refreshable { await load() }
        } else if let failureMessage {
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .imageScale(.large)
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            }
        } else {
            VStack {
                Spacer()
                ProgressView("Loading active incidents")
                Spacer()
            }
        }
    }

    /// The column labels, held still above the list so a long list stays readable.
    private var columnHeader: some View {
        HStack(alignment: .top, spacing: IncidentRow.spacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                Text(column.label)
                    .font(.caption2.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
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
        let updated = snapshot.updatedFromDatabaseAt ?? "unknown"
        let base = "Last updated \(updated)"
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
