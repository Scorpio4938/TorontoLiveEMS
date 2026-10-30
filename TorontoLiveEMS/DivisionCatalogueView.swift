import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Every police division the City publishes, as a list or as pins.
///
/// **The number in the feed's spelling.** The City's boundary file stores `14`; the feed and this
/// screen write `D14`. Showing one form everywhere is the point, and the feed's is the one a reader
/// sees on a call.
///
/// The list's second line is the published facility address when there is one. Three divisions have
/// no facility row, so the map has 16 pins: it can answer where a division's building is, and it
/// cannot answer where a division without one is. No boundary is drawn, because the reference data
/// is points only.
struct DivisionCatalogueView: View {

    let policeFeed: PoliceCallFeed

    private var divisions: [PoliceDivision] { PoliceDivisions.bundled.divisions }

    @State private var mode: CatalogueMode = .list
    @State private var position: MapCameraPosition = .region(IncidentMapScale.city)
    @State private var selected: String?

    private var pins: [DivisionPin] {
        divisions.compactMap { division in
            guard
                let facility = PoliceFacilities.bundled.facility(forPublished: division.number)
            else {
                return nil
            }
            return DivisionPin(division: division, facility: facility)
        }
    }

    var body: some View {
        Group {
            switch mode {
            case .list:
                list
            case .map:
                map
            }
        }
        .navigationTitle("Divisions")
        .toolbar {
            ToolbarItem(placement: .principal) {
                CatalogueModeMenu(title: "Divisions", mode: $mode)
            }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(divisions) { division in
                    NavigationLink {
                        DivisionPage(division: division, policeFeed: policeFeed)
                    } label: {
                        DivisionRow(division: division)
                    }
                    .id(division.number)
                }
            }
            .onAppear {
                // A pin chosen on the map is the reader's place; bring the list back to it.
                if let selected = selected {
                    proxy.scrollTo(selected, anchor: .center)
                }
            }
            .softScrollEdge()
        }
    }

    private var map: some View {
        CatalogueMap(
            items: pins,
            title: { $0.division.feedCode },
            subtitle: { $0.facility.address },
            coordinate: { pin in
                CLLocationCoordinate2D(
                    latitude: pin.facility.coordinate.latitude,
                    longitude: pin.facility.coordinate.longitude
                )
            },
            position: $position,
            selected: $selected
        ) { pin in
            DivisionPage(division: pin.division, policeFeed: policeFeed)
        }
        .overlay(alignment: .bottomLeading) {
            // Three divisions have no published facility point. Saying so prevents the map from
            // being read as a complete list of the 19; the list remains the complete catalogue.
            Text("Pins are published facility locations. Divisions without one are in the list only.")
                .font(.caption2)
                .foregroundStyle(Color.secondary)
                .padding(.leading, 12)
                .padding(.bottom, 10)
        }
    }
}

/// A division and the facility point that can place it on the map.
///
/// The three divisions without a facility are in the list and not in this array; the map has no
/// coordinate to draw for them.
private struct DivisionPin: Identifiable {

    let division: PoliceDivision
    let facility: PoliceFacility

    var id: String { division.number }
}

/// One division in the catalogue.
private struct DivisionRow: View {

    let division: PoliceDivision

    private var facility: PoliceFacility? {
        PoliceFacilities.bundled.facility(forPublished: division.number)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(division.feedCode)
            if let facility = facility {
                Text(facility.address)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DivisionCatalogueView(policeFeed: PreviewCalls.feed())
    }
}
