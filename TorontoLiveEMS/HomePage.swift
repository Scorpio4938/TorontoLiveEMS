import SwiftUI
import TorontoLiveEMSKit

/// The app's index.
///
/// **A list, because the platform's list is the right shape for an index.** Two sections grouped by
/// service, each row carrying the size of the catalogue behind it, then the sources the data comes
/// from. Nothing here is live content of its own, which is why Home is the only page that can be
/// opened before either feed has answered.
///
/// **Home is the first-launch screen, and restorable like any other.** A fresh install opens here
/// because it has no last page to restore; every launch after opens the last of Home, Fire, Police
/// or Map. The rule lives in `LaunchBehaviour`, in the package, where it can be tested.
///
/// **The feeds' as-of lines are not here.** They are the Fire and Police pages' status, and a
/// refresh on those pages changes them. On the index they would sit beside reference data of a
/// different age and read as if they described the directory; Home has no live status of its own.
///
/// The design is recorded in `docs/design-decisions.md`, *The reference section*: a directory
/// rather than a dashboard, no masthead or mark, counts as trailing values, and Sources as a
/// section because it is a destination. Nothing here exists only to fill the screen.
struct HomePage: View {

    let feed: IncidentFeed

    /// The police feed, handed on to the Division catalogue and its live sections.
    ///
    /// Home loads it once when the index is opened so a division page does not have to wait for a
    /// second request; it no longer puts the feed's as-of line on Home.
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
        }
        .navigationTitle("Home")
        .softScrollEdge()
        .task {
            // Only the police feed. RootView loads the fire feed at launch because the map needs it
            // either way; asking again here would be a second request for the same document. The
            // division pages read these calls; loading them here means their live sections have a
            // snapshot without a second request, and none of it is drawn as a status line on Home.
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
