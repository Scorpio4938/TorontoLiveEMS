import SwiftUI
import TorontoLiveEMSKit

/// Everything the City publishes about one incident.
///
/// Laid out the way the platform lays out a details screen: `LabeledContent` for every
/// label-and-value pair, explanations in section footers, and the verbatim published
/// values in a group of their own rather than tangled in with the readable ones. See
/// `docs/design-decisions.md` and `docs/adr/0005-apple-components-first.md`.
struct IncidentDetailView: View {

    let incident: Incident

    private static let notProvided = "/"

    private var category: IncidentCategory? {
        IncidentCategory.from(incidentType: incident.incidentType)
    }

    private var units: [DispatchedUnit] {
        DispatchedUnit.roster(from: incident.dispatchedUnits)
    }

    private var hasUndecodedUnit: Bool {
        units.contains { $0.apparatus == nil }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Incident Number", value: incident.incidentNumber)
                LabeledContent(
                    "Incident Type",
                    value: category?.label ?? incident.incidentType
                )
                LabeledContent("Alarm Level", value: incident.alarmLevel)
                LabeledContent(
                    "Dispatch Time",
                    value: DispatchTimestamp.dateAndTime(incident.dispatchTime)
                )
                LabeledContent("Area", value: incident.area)
            } header: {
                Text("Incident")
            } footer: {
                Text("Area is the nearest fire station. Alarm Level is the City's response escalation, where 0 is an initial response.")
            }

            Section {
                LabeledContent(
                    "Prime Street",
                    value: incident.primeStreet ?? Self.notProvided
                )
                LabeledContent(
                    "Cross Street",
                    value: incident.crossStreets ?? Self.notProvided
                )
            } header: {
                Text("Location")
            } footer: {
                if incident.isLocationPostalArea {
                    Text("A medical incident's location is published as a postal area rather than an address, to preserve privacy.")
                }
            }

            Section {
                if units.isEmpty {
                    LabeledContent("Dispatched Units", value: Self.notProvided)
                } else {
                    ForEach(units, id: \.code) { unit in
                        LabeledContent {
                            Text(unit.display)
                        } label: {
                            Text(unit.code)
                        }
                    }
                }
            } header: {
                Text("Dispatched Units")
            } footer: {
                if hasUndecodedUnit {
                    Text("A code not named here is not in the City's published legend.")
                }
            }

            Section {
                LabeledContent("Incident Type", value: incident.incidentType)
                LabeledContent("Dispatch Time", value: incident.dispatchTime)
                if let published = incident.dispatchedUnits {
                    LabeledContent("Dispatched Units", value: published)
                }
            } header: {
                Text("As published")
            } footer: {
                Text("The City's own values, before any of the above was rendered for reading.")
            }

            Section {
                Text("Data provided by the City of Toronto.")
                Text("Contains information licensed under the Open Government Licence – Toronto.")
                if let licenceURL {
                    Link("Open Government Licence – Toronto", destination: licenceURL)
                }
            }
        }
        .navigationTitle(incident.incidentNumber)
    }

    private var licenceURL: URL? {
        URL(string: "https://www.toronto.ca/city-government/data-research-maps/open-data/open-data-licence/")
    }
}
