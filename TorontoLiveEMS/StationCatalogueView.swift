import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Every fire station the City publishes, as a list or as pins.
///
/// **The catalogue, not a search.** 84 rows is short enough to scan, and the station number is what a
/// reader arrives with — `Area 143` on an incident — so the list is in station-number order and each
/// row leads with that number. Address and municipality are the second line, context rather than the
/// key.
///
/// **The map is points, not coverage.** The reference file publishes a coordinate per station and
/// nothing about what ground a station covers, so the map answers *where is Station 143* and never
/// *what is its area*. The camera and the open card live in this view rather than in the map, so a
/// flip to the list and back returns to the same place.
struct StationCatalogueView: View {

    /// The shared fire feed, handed on to each station page so its unit rows can open unit pages.
    let feed: IncidentFeed

    private var stations: [FireStation] { FireStations.bundled.stations }

    @State private var mode: CatalogueMode = .list
    @State private var position: MapCameraPosition = .region(IncidentMapScale.city)
    @State private var selected: Int?

    /// One scroll target, set only when the map is left for the list and cleared once used.
    ///
    /// Keeping it separate from `selected` means returning from a detail page does not yank the
    /// list back to the pin the reader chose earlier; the pin stays selected for the map, while the
    /// list keeps the place the reader left it.
    @State private var scrollTarget: Int?

    var body: some View {
        Group {
            switch mode {
            case .list:
                list
            case .map:
                map
            }
        }
        .navigationTitle("Stations")
        .toolbar {
            ToolbarItem(placement: .principal) {
                CatalogueModeMenu(title: "Stations", mode: $mode)
            }
        }
        .onChange(of: mode) { _, newMode in
            if newMode == .list, let selected = selected {
                scrollTarget = selected
            }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(stations) { station in
                    NavigationLink {
                        StationPage(station: station, feed: feed)
                    } label: {
                        StationRow(station: station)
                    }
                    .id(station.number)
                }
            }
            .onAppear {
                // A pin chosen on the map is the reader's place; bring the list back to it once.
                if let scrollTarget = scrollTarget {
                    proxy.scrollTo(scrollTarget, anchor: .center)
                    self.scrollTarget = nil
                }
            }
            .onChange(of: scrollTarget) { _, target in
                // The mode change and the list's appearance can arrive in either order; whichever
                // is second performs the scroll, and the target is cleared so it happens once.
                guard let target else { return }
                proxy.scrollTo(target, anchor: .center)
                self.scrollTarget = nil
            }
            .softScrollEdge()
        }
    }

    private var map: some View {
        CatalogueMap(
            items: stations,
            title: { "Station \($0.number)" },
            subtitle: { $0.address },
            coordinate: { station in
                CLLocationCoordinate2D(
                    latitude: station.coordinate.latitude,
                    longitude: station.coordinate.longitude
                )
            },
            position: $position,
            selected: $selected
        ) { station in
            StationPage(station: station, feed: feed)
        }
    }
}

/// One station in the catalogue.
private struct StationRow: View {

    let station: FireStation

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Station \(station.number)")
            Text(station.address)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        StationCatalogueView(feed: PreviewIncidents.feed())
    }
}
