import SwiftUI
import TorontoLiveEMSKit

/// Every fire station the City publishes, as a list.
///
/// **The catalogue, not a search.** 84 rows is short enough to scan, and the station number is what a
/// reader arrives with — `Area 143` on an incident — so the list is in station-number order and each
/// row leads with that number. Address and municipality are the second line, context rather than the
/// key.
///
/// The rows open `StationPage`; the facts there come from the generated reference file, not from
/// anything typed into this view.
struct StationCatalogueView: View {

    private var stations: [FireStation] { FireStations.bundled.stations }

    var body: some View {
        List {
            ForEach(stations) { station in
                NavigationLink {
                    StationPage(station: station)
                } label: {
                    StationRow(station: station)
                }
            }
        }
        .navigationTitle("Stations")
        .softScrollEdge()
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
        StationCatalogueView()
    }
}
