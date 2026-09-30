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
            // A refresh control at the bottom, within thumb reach on a phone. Applied as
            // a safe-area inset so it sits below the list rather than over the last row,
            // and so the list keeps its own scrolling without being clipped.
            .safeAreaInset(edge: .bottom) { refreshBar }
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

    private var refreshBar: some View {
        HStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
            Spacer()
            Button {
                Task { await load() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
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
