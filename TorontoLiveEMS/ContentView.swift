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
            List(snapshot.incidents) { incident in
                Text(incident.incidentType)
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
