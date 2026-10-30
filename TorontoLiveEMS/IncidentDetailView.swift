import SwiftUI
import TorontoLiveEMSKit

/// Everything the City publishes about one incident.
///
/// Laid out the way the platform lays out a details screen: `LabeledContent` for every
/// label-and-value pair, and explanations in section footers rather than stacked under
/// each value. See `docs/design-decisions.md` and
/// `docs/adr/0005-apple-components-first.md`.
///
/// The values here are the City's own, not our renderings of them. The table turns
/// Incident Type into a category and Dispatch Time into a clock time because width is
/// scarce there; on a screen with room, the published value is the honest one, and
/// showing both was clutter.
struct IncidentDetailView: View {

    let incident: Incident

    /// The map's geocoder, owned by this screen.
    ///
    /// **One per detail view rather than one shared.** This screen looks up exactly one location,
    /// so there is nothing to share and nothing to keep warm; the alternative is threading a
    /// geocoder through two list types and five call sites for no gain. `@State` and not
    /// `@Environment`: a missing environment value of our own type is a trap rather than a nil,
    /// which is a lesson already paid for.
    @State private var geocoder = IncidentGeocoder()

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
                LabeledContent("Incident Type", value: incident.incidentType)
                LabeledContent("Alarm Level", value: incident.alarmLevel)
                LabeledContent("Dispatch Time", value: incident.dispatchTime)
                LabeledContent("Area", value: incident.area)
            } header: {
                Text("Incident")
            } footer: {
                Text("Area is the fire station area the incident falls in. Alarm Level is Toronto Fire Services' response escalation, where 0 is an initial response.")
            }

            Section {
                LabeledContent(
                    "Prime Street",
                    value: incident.primeStreet ?? NotProvided.mark
                )
                LabeledContent(
                    "Cross Street",
                    value: incident.crossStreets ?? NotProvided.mark
                )

                // A row of its own rather than inside one of the two above, because it is drawn
                // from whichever of them the feed did publish — see `IncidentLocation`.
                IncidentLocationMap(incident: incident, geocoder: geocoder)
            } header: {
                Text("Location")
            } footer: {
                if incident.isLocationPostalArea {
                    Text("A medical incident's location is published as a postal area rather than an address, to preserve privacy. It is shown as an area, because that is what the City published — an address would be a guess.")
                } else if IncidentLocation.from(incident) != .unpublished {
                    Text("Placement is approximate. The City publishes a street or an intersection rather than a street number, so this is somewhere along it rather than a doorstep.")
                }
            }

            Section {
                if units.isEmpty {
                    LabeledContent("Dispatched Units", value: NotProvided.mark)
                } else {
                    // Each unit already carries its published code as the label, so the
                    // raw roster needs no section of its own.
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

            // The screen showing the City's data states who published it and that this app is not
            // the City. The terms themselves are one row away, on Data Licences.
            DataLicenceNotice(sentence: Attribution.fireNotice)
        }
        .navigationTitle(incident.incidentNumber)
        .softScrollEdge()
    }
}
