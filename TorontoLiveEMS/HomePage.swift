import Foundation
import SwiftUI
import TorontoLiveEMSKit

/// The app's index.
///
/// **A list, because the platform's list is the right shape for an index.** Two sections grouped by
/// service, each row carrying the size of the catalogue behind it, then the sources the data comes
/// from, and at the bottom the two provenance lines the Fire and Police pages lead with. Nothing
/// here is live content of its own, which is why Home is the only page that can be opened before
/// either feed has answered.
///
/// **Home is the first-launch screen, not the launch screen.** A fresh install opens here because it
/// has no last page to restore; every launch after opens the last of Fire, Police or Map. The rule
/// lives in `LaunchBehaviour`, in the package, where it can be tested.
///
/// **The provenance lines are the same values the two tabs show, not a paraphrase.** They are
/// `FeedStatusLine` over the two feeds' own `status`, so a refresh on Home has something visible to
/// change and cannot say something different from the page it belongs to.
struct HomePage: View {

    let feed: IncidentFeed

    /// The police feed, read here for its provenance line and loaded when Home is opened.
    ///
    /// The police page and the map load it on arrival for the same reason: nothing else used to read
    /// these calls, so asking before somebody looked was a request made for nobody. Home now shows
    /// their as-of, so Home is a screen that reads them.
    let policeFeed: PoliceCallFeed

    private var stations: FireStations { FireStations.bundled }
    private var units: FireUnits { FireUnits.bundled }
    private var divisions: PoliceDivisions { PoliceDivisions.bundled }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    StationCatalogueView(feed: feed)
                } label: {
                    LabeledContent("Stations", value: "\(stations.count)")
                }

                NavigationLink {
                    UnitCatalogueView(feed: feed)
                } label: {
                    LabeledContent("Units", value: "\(units.count)")
                }
            } header: {
                Text("Fire")
            }

            Section {
                // The Divisions catalogue is #28. Until it exists the row carries the count the
                // index promises rather than pretending to lead somewhere it does not.
                LabeledContent("Divisions", value: "\(divisions.count)")
            } header: {
                Text("Police")
            }

            Section {
                sources
            } header: {
                Text("Sources")
            } footer: {
                Text("Station and division facts come from the City's open data; incidents and calls come from their publishers' own feeds.")
            }

            Section {
                FeedStatusLine(status: feed.status)
                FeedStatusLine(status: policeFeed.status)
            }
        }
        .navigationTitle("Home")
        .softScrollEdge()
        .task {
            // Only the police feed. RootView loads the fire feed at launch because the map needs it
            // either way; asking again here would be a second request for the same document.
            if policeFeed.calls == nil {
                await policeFeed.load()
            }
        }
    }

    /// The publishers' pages, and the open data the reference section is built from.
    ///
    /// **Links rather than a second information screen.** These are the same destinations the info
    /// button reaches through its sheets, with one tap instead of three. The open data links are the
    /// dataset pages rather than the CKAN resource URLs the generated files record: a reader wants
    /// the page that describes the data, not the download that happens to be behind it.
    @ViewBuilder
    private var sources: some View {
        if let url = LiveCADFeed.pageURL {
            Link(LiveCADFeed.pageName, destination: url)
                .tint(.blue)
        }
        if let url = CallsForServiceFeed.pageURL {
            Link(CallsForServiceFeed.pageName, destination: url)
                .tint(.blue)
        }
        if let url = OpenData.fireStations {
            Link("Fire Station Locations", destination: url)
                .tint(.blue)
        }
        if let url = OpenData.policeDivisions {
            Link("Police Boundaries", destination: url)
                .tint(.blue)
        }
    }
}

/// The City's open data pages, which are human pages rather than the resource downloads.
private enum OpenData {
    static let fireStations = URL(string: "https://open.toronto.ca/dataset/fire-station-locations/")
    static let policeDivisions = URL(string: "https://open.toronto.ca/dataset/police-boundaries/")
}

#Preview("Home") {
    NavigationStack {
        HomePage(
            feed: IncidentFeed(fetch: { PreviewIncidents.snapshot }),
            policeFeed: PreviewCalls.feed()
        )
    }
}
