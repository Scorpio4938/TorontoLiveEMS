import Foundation
import TorontoLiveEMSKit

/// The compact table's columns, in the order they are shown.
///
/// This is the single source of truth for the column set — order, label, and the
/// value each column draws from an Incident. It is fixed at six: the table never
/// grows columns, so one layout serves every row on every device.
///
/// Incident Number and Area are deliberately absent. They are carried in the model
/// and shown in the detail view. See `docs/design-decisions.md`.
enum CompactColumn: CaseIterable {

    case primeStreet
    case crossStreet
    case dispatchTime
    case incidentType
    case alarmLevel
    case dispatchedUnits

    /// The City's own label for the field.
    var label: String {
        switch self {
        case .primeStreet:
            return "Prime Street"
        case .crossStreet:
            return "Cross Street"
        case .dispatchTime:
            return "Dispatch Time"
        case .incidentType:
            return "Incident Type"
        case .alarmLevel:
            return "Alarm Level"
        case .dispatchedUnits:
            return "Dispatched Units"
        }
    }

    /// What to show in this column for an incident.
    ///
    /// `nil` means there is nothing to show. It renders as an empty cell — no
    /// placeholder, no substitute.
    ///
    /// The feed's values are rendered for people here, not passed through: the
    /// timestamp is formatted, the Incident Type becomes a category, and the
    /// apparatus codes become the City's names. Anything we cannot interpret falls
    /// back to the published string.
    func text(for incident: Incident) -> String? {
        switch self {
        case .primeStreet:
            return incident.primeStreet
        case .crossStreet:
            return incident.crossStreets
        case .dispatchTime:
            return DispatchTimestamp.clockTime(incident.dispatchTime)
        case .incidentType:
            return IncidentCategory.from(incidentType: incident.incidentType)?.label
                ?? incident.incidentType
        case .alarmLevel:
            return incident.alarmLevel
        case .dispatchedUnits:
            let units = DispatchedUnit.roster(from: incident.dispatchedUnits)
            return units.isEmpty ? nil : units.map(\.display).joined(separator: ", ")
        }
    }
}
