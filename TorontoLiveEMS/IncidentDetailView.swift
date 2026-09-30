import SwiftUI
import TorontoLiveEMSKit

/// Everything the City publishes about one incident.
///
/// The compact table shows six fields; this shows all eight, the raw published value
/// behind anything we formatted, and the City's own explanations for the codes it uses.
/// Nothing is reduced away — see `docs/adr/0002-raw-payload-retained-in-memory.md`.
struct IncidentDetailView: View {

    let incident: Incident

    private static let notPublished = "Not published"

    private var units: [DispatchedUnit] {
        DispatchedUnit.roster(from: incident.dispatchedUnits)
    }

    var body: some View {
        List {
            Section("Incident") {
                FieldRow(label: "Incident Number", value: incident.incidentNumber)
                FieldRow(
                    label: "Incident Type",
                    value: incident.incidentType,
                    detail: categoryDetail
                )
                FieldRow(
                    label: "Alarm Level",
                    value: incident.alarmLevel,
                    detail: AlarmLevel.meaning(for: incident.alarmLevel)
                )
                FieldRow(
                    label: "Dispatch Time",
                    value: DispatchTimestamp.dateAndTime(incident.dispatchTime),
                    detail: "Published as \(incident.dispatchTime)"
                )
                FieldRow(
                    label: "Area",
                    value: incident.area,
                    detail: "Nearest fire station"
                )
            }

            Section("Location") {
                FieldRow(
                    label: "Prime Street",
                    value: incident.primeStreet ?? Self.notPublished
                )
                FieldRow(
                    label: "Cross Street",
                    value: incident.crossStreets ?? Self.notPublished
                )
                if incident.isLocationPostalArea {
                    Text("A medical incident's location is published as a postal area rather than an address, to preserve privacy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Dispatched Units") {
                if units.isEmpty {
                    FieldRow(
                        label: "Dispatched Units",
                        value: Self.notPublished
                    )
                } else {
                    ForEach(units, id: \.code) { unit in
                        FieldRow(
                            label: unit.code,
                            value: unit.display,
                            detail: undecodedNote(for: unit)
                        )
                    }
                }
            }

            Section {
                Text("Contains information licensed under the Open Government Licence – Toronto.")
                    .font(.footnote)
                if let licenceURL {
                    Link("Open Government Licence – Toronto", destination: licenceURL)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle(incident.incidentNumber)
    }

    private var categoryDetail: String? {
        guard let category = IncidentCategory.from(incidentType: incident.incidentType) else {
            return "Not a type the City has published before"
        }
        return "Category: \(category.label)"
    }

    private func undecodedNote(for unit: DispatchedUnit) -> String? {
        if unit.apparatus == nil {
            return "Not in the City's legend"
        }
        return nil
    }

    private var licenceURL: URL? {
        URL(string: "https://www.toronto.ca/city-government/data-research-maps/open-data/open-data-licence/")
    }
}

/// One published field: the City's label, the value we show for it, and an optional
/// line explaining or sourcing that value.
private struct FieldRow: View {

    let label: String
    let value: String
    let detail: String?

    init(label: String, value: String, detail: String? = nil) {
        self.label = label
        self.value = value
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
