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

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Active Incidents")
        }
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot {
            VStack(spacing: 0) {
                header
                Divider()
                List(snapshot.incidents) { incident in
                    IncidentRow(incident: incident)
                }
                .listStyle(.plain)
            }
        } else if let failureMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .imageScale(.large)
                Text(failureMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        } else {
            ProgressView("Loading active incidents")
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

    private func load() async {
        do {
            snapshot = try await LiveCADClient().snapshot()
            failureMessage = nil
        } catch {
            failureMessage = "The live feed could not be loaded.\n\(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}
