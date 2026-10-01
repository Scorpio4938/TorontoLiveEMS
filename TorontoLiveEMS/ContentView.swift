//
//  ContentView.swift
//  TorontoLiveEMS
//
//  Created by Scorpio493.8 on 2026-09-27.
//

import SwiftUI
import TorontoLiveEMSKit

/// The active incidents as a list. One of the app's two screens.
///
/// It used to hold the feed as well, when it was the only screen. The state moved to
/// `IncidentFeedModel` and the controls to `AppToolbar`, because there are two screens now and
/// both need the same incidents and the same buttons.
struct ContentView: View {

    let model: IncidentFeedModel

    /// Passed, not read from the environment. An `@Environment(Type.self)` with no value in
    /// scope is a trap rather than a nil, and the detail view behind a list row was reading one
    /// that was not there. Four initialisers is a small price for a crash that cannot happen.
    let geocoder: IncidentGeocoder

    /// The root's, not a second flag. See `RootView.Sheet`.
    @Binding var sheet: RootView.Sheet?

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Active Incidents")
            #if os(iOS)
            // Inline rather than large. A large title collapses as the list scrolls while the
            // status line and column header below it stay pinned, so the chrome moves in two
            // directions at once. It also reserves a band of space above the title that a table
            // cannot afford. Inline sits on the same bar as the buttons, rather than on a band
            // above it, and does not move.
            .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    AppToolbar(model: model, sheet: $sheet)
                }
        }
        // The load, on the view that appears. See `IncidentsScreen` for why it is not on the
        // tab view.
        .task {
            await model.loadIfEmpty()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let status = model.status() {
            switch presentation {
            case .compactTable:
                CompactTableList(
                    incidents: model.incidents,
                    timeFormat: dispatchTimeFormat,
                    status: status,
                    geocoder: geocoder
                )
            case .cards:
                CardsList(
                    incidents: model.incidents,
                    timeFormat: dispatchTimeFormat,
                    status: status,
                    geocoder: geocoder
                )
            }
        } else if let failureMessage = model.failureMessage {
            ContentUnavailableView(
                "Live feed unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(failureMessage)
            )
        } else {
            ProgressView("Loading active incidents")
        }
    }
}

#Preview {
    ContentView(
        model: IncidentFeedModel(),
        geocoder: IncidentGeocoder(),
        sheet: .constant(nil)
    )
}
