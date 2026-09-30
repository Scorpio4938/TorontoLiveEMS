import Foundation
import TorontoLiveEMSKit

/// One cell of the compact table: what to show, and whether it should stand out.
///
/// Almost every cell is neutral. Colour marks state rather than taxonomy — a fire, a
/// hazmat call, an escalated alarm level — because colouring all thirteen categories
/// equally would make the sixty-four percent of incidents that are medical as loud as
/// the five percent that are fires. See `docs/design-decisions.md`.
struct CompactCell: Equatable {
    let text: String?
    let warrantsAttention: Bool

    init(_ text: String?, warrantsAttention: Bool = false) {
        self.text = text
        self.warrantsAttention = warrantsAttention
    }
}

/// The compact table's columns, in the order they are shown.
///
/// This is the single source of truth for the column set — order, label, and the value
/// each column draws from an Incident. It is fixed at five: the table never grows
/// columns, so one layout serves every row on every device.
///
/// Cross Street is deliberately absent. It is blank on most incidents — every medical
/// one — and it is a refinement of Prime Street rather than a peer of it, so on a phone
/// it spent width it rarely used. It lives in the detail view. Incident Number and Area
/// are there too. See `docs/design-decisions.md`.
enum CompactColumn: CaseIterable {

    case primeStreet
    case dispatchTime
    case incidentType
    case alarmLevel
    case dispatchedUnits

    /// The City's own label for the field.
    var label: String {
        switch self {
        case .primeStreet:
            return "Prime Street"
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

    /// What to show in this column for an incident, and whether it should stand out.
    ///
    /// `nil` text means there is nothing to show. It renders as an empty cell — no
    /// placeholder, no substitute.
    ///
    /// Anything we cannot interpret falls back to the published string.
    func cell(for incident: Incident) -> CompactCell {
        switch self {
        case .primeStreet:
            return CompactCell(incident.primeStreet)

        case .dispatchTime:
            return CompactCell(DispatchTimestamp.clockTime(incident.dispatchTime))

        case .incidentType:
            let category = IncidentCategory.from(incidentType: incident.incidentType)
            return CompactCell(
                category?.label ?? incident.incidentType,
                warrantsAttention: category?.warrantsAttention ?? false
            )

        case .alarmLevel:
            return CompactCell(
                incident.alarmLevel,
                warrantsAttention: AlarmLevel.isEscalated(incident.alarmLevel)
            )

        case .dispatchedUnits:
            // Left exactly as published. Decoding `P231` to `Pumper 231` is worth the
            // characters in the detail view and not here, where width is the scarcest
            // thing we have.
            return CompactCell(incident.dispatchedUnits)
        }
    }
}
