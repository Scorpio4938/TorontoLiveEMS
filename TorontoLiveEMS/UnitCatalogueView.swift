import SwiftUI
import TorontoLiveEMSKit

/// Every unit code the catalogue knows, grouped by the leading letter of the code.
///
/// **The letter is a way to find a row, not a reading of the name.** A `C` section holds Chief cars
/// and Command Vehicles together, and each row still says which it is — the naming rule is the
/// longest matching legend entry, and `C23` and `CMD…` prove that a shared first letter decides
/// nothing about the word beside the code.
///
/// The catalogue is the captured list, not a census of the fleet. A unit that was not dispatched in
/// that capture is absent, and that absence is not a claim that it does not exist.
struct UnitCatalogueView: View {

    let feed: IncidentFeed

    private var groups: [FireUnitGroup] { FireUnits.bundled.groups }

    var body: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.units) { unit in
                        NavigationLink {
                            UnitPage(unit: unit, feed: feed)
                        } label: {
                            UnitRow(unit: unit)
                        }
                    }
                } header: {
                    Text(group.letter)
                }
            }
        }
        .navigationTitle("Units")
        .softScrollEdge()
    }
}

/// One unit in the catalogue: its code, and the apparatus the legend names when it names one.
private struct UnitRow: View {

    let unit: FireUnit

    var body: some View {
        HStack {
            Text(unit.code)
            Spacer()
            if let name = unit.name {
                Text(name)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UnitCatalogueView(feed: PreviewIncidents.feed())
    }
}
