import Foundation

/// One call for service, as published by the Toronto Police Service.
///
/// **A model of its own, and not an `Incident`.** The fire feed's incidents and these calls are
/// different things: an incident has an alarm level, a fire station area and a roster of
/// apparatus, and a call has a division, a call type and an intersection. Forcing one into the
/// other would mean fields that are always empty and names that lie about what they hold, and the
/// point of the two models is that each says what its own publisher says.
///
/// **The publisher gives a point**, so nothing here is geocoded: `latitude` and `longitude` are
/// published outright, where the fire feed publishes a street and makes the app ask Apple where it
/// is. That is one fewer network call per row and one fewer thing to disagree about.
///
/// See `docs/adr/0006-tps-calls-for-service-as-the-police-source.md` for the source, its licence,
/// and the two restrictions that shape what may be done with it.
public struct PoliceCall: Identifiable, Equatable, Sendable {

    /// The row's identity in the service, and the only thing stable across two reads.
    public var id: Int { objectID }

    /// The service's own row number.
    public let objectID: Int

    /// When the call happened, as an instant.
    ///
    /// Published as milliseconds since 1970 and kept as a `Date` here, unlike the fire feed's
    /// timestamp, which is a wall-clock string in Toronto's time and is shown as published. An
    /// instant has no clock until a zone is chosen, and the reader's own is the honest choice.
    public let occurrenceTime: Date

    /// The division that responded, e.g. `D14`.
    public let division: String

    /// The published point.
    public let latitude: Double
    public let longitude: Double

    /// The call as a code, e.g. `PERGU`.
    ///
    /// Kept beside the readable form because it is what the Service publishes and the app does not
    /// decode it: the Service publishes no legend, and inventing one would be inventing the Service's
    /// vocabulary. What the app has instead is the list it gathered from the calls themselves, which
    /// is `PoliceCallType.documented`.
    public let callTypeCode: String

    /// The call in words, e.g. `PERSON WITH A GUN`, exactly as published.
    public let callType: String

    /// The nearest intersection, or `nil` when the service published nothing there.
    ///
    /// **A one-sided intersection arrives as `"BONIS AVE - "`** — the separator with nothing after
    /// it. That is not blank, so it is shown as published rather than normalised away; what to do
    /// with a dangling separator is a display decision, and this model does not make display
    /// decisions.
    public let crossStreets: String?

    public init(
        objectID: Int,
        occurrenceTime: Date,
        division: String,
        latitude: Double,
        longitude: Double,
        callTypeCode: String,
        callType: String,
        crossStreets: String?
    ) {
        self.objectID = objectID
        self.occurrenceTime = occurrenceTime
        self.division = division
        self.latitude = latitude
        self.longitude = longitude
        self.callTypeCode = callTypeCode
        self.callType = callType
        self.crossStreets = crossStreets
    }
}

// MARK: - The police calls' columns

extension CompactColumn where Row == PoliceCall {

    /// Where the call was, as the Service published it.
    public static let crossStreets = CompactColumn<PoliceCall>(label: "Cross Streets") { call, _ in
        // The mark when there is nothing, for the reason the fire table gives: this column starts
        // the row, and an empty cell there leaves the eye without anything to land on — the one
        // place in a list where nothing at all reads as a fault rather than as restraint.
        CompactCell(call.crossStreets ?? NotProvided.mark)
    }

    /// When the call happened.
    public static let occurrenceTime = CompactColumn<PoliceCall>(
        label: "Occurrence Time",
        headerLabel: "Time"
    ) { call, timeFormat in
        CompactCell(DispatchTimestamp.clockTime(call.occurrenceTime, format: timeFormat))
    }

    /// What the call was: the Service's words for it, or the Service's code.
    ///
    /// **A function rather than a value, because the reader chooses which of the two.** The column is
    /// the only place the choice shows — a call's detail view has room for both and shows both, and a
    /// column has room for one. The cell closure captures the choice, so `CompactColumn`'s signature is
    /// untouched and the shared table learns nothing about police preferences.
    public static func callType(style: PoliceCallTypeStyle) -> CompactColumn<PoliceCall> {
        CompactColumn<PoliceCall>(label: "Call Type") { call, _ in
            switch style {
            case .words:
                return CompactCell(call.callType)
            case .code:
                return CompactCell(call.callTypeCode)
            }
        }
    }

    /// Which division responded.
    public static let division = CompactColumn<PoliceCall>(label: "Division") { call, _ in
        CompactCell(call.division)
    }

    /// The police calls' columns, in the order the table shows them.
    ///
    /// **Four, where fire has five**, and that is this source's count rather than the table's: these
    /// are the fields the Service publishes that are worth a column. Latitude and longitude are not
    /// among them — they mean nothing to a reader, and the detail view states them as numbers for
    /// anyone who wants them.
    ///
    /// The order follows fire's rhythm so the two tables read alike: where, then when, then what,
    /// then who responded.
    public static func police(style: PoliceCallTypeStyle) -> [CompactColumn<PoliceCall>] {
        [crossStreets, occurrenceTime, callType(style: style), division]
    }

    /// The same four in the order the card reads them: where and what, then when and who.
    public static func policeCard(style: PoliceCallTypeStyle) -> [CompactColumn<PoliceCall>] {
        [crossStreets, callType(style: style), occurrenceTime, division]
    }
}
