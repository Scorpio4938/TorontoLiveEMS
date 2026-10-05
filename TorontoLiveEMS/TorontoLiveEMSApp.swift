//
//  TorontoLiveEMSApp.swift
//  TorontoLiveEMS
//
//  Created by Scorpio493.8 on 2026-09-27.
//

import SwiftUI
import TorontoLiveEMSKit

@main
struct TorontoLiveEMSApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(feed: IncidentFeed(), policeFeed: PoliceCallFeed())
        }
    }
}
