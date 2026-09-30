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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if snapshot != nil {
                    header
                }
                statusLine
                Divider()
                content
            }
            .navigationTitle("Active Incidents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await load() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
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
    private var header: some View {
        HStack(alignment: .top, spacing: IncidentRow.spacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                Text(column.label)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    /// The feed's own timestamp, on screen at all times — including before the first
    /// fetch has returned, when it says so rather than disappearing.
    ///
    /// It is the age of the *data*, not of our request, which is what a reader needs in
    /// order to judge whether what they are looking at is current. The City shows the
    /// same value; we add the space after the colon that their page omits.
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
        .padding(.bottom, 4)
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
        return base
    }

    private func load() async {
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
