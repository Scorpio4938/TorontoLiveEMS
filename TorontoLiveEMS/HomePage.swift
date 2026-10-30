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
///
/// The design is recorded in `docs/design-decisions.md`, *The reference section*: a directory
/// rather than a dashboard, no masthead or mark, counts as trailing values, and Sources as a
/// section because it is a destination. Nothing here exists only to fill the screen.
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
                NavigationLink {
                    DivisionCatalogueView(policeFeed: policeFeed)
                } label: {
                    LabeledContent("Divisions", value: "\(divisions.count)")
                }
            } header: {
                Text("Police")
            }

            Section {
                sources
            } header: {
                Text("Sources")
            } footer: {
                Text("Each source is named with the licence it is published under where the data is explained.")
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
        ForEach(Attribution.sources) { source in
            Link(source.name, destination: source.url)
                .tint(.blue)
        }
    }
}

#Preview("Home") {
    NavigationStack {
        HomePage(
            feed: IncidentFeed(fetch: { PreviewIncidents.snapshot }),
            policeFeed: PreviewCalls.feed()
        )
    }
}
