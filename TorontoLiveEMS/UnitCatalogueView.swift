import SwiftUI
import TorontoLiveEMSKit

/// Every unit code the catalogue knows, grouped by apparatus type.
///
/// **The group heading is the City's name for the code, not its first letter.** `C23` is a Chief
/// and `CMD10` a Command Vehicle, so they are separate sections; `R346` is Rescue, not R. The same
/// longest matching legend entry that names the row decides the group. A code the legend does not
/// name falls back to its first letter.
///
/// The catalogue is the roster, not a census of the fleet. A unit absent from the roster is absent,
/// and that absence is not a claim that it does not exist.
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
                            FireUnitRow(unit: unit)
                        }
                    }
                } header: {
                    Text(group.title)
                }
            }
        }
        .navigationTitle("Units")
        .softScrollEdge()
    }
}

#Preview {
    NavigationStack {
        UnitCatalogueView(feed: PreviewIncidents.feed())
    }
}
