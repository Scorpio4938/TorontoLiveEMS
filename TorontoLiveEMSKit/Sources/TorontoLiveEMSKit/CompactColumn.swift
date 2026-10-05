import Foundation

/// One cell of the compact table: what to show, and whether it should stand out.
///
/// Almost every cell is neutral. Colour marks state rather than taxonomy — a fire, a
/// hazmat call, an escalated alarm level — because colouring all thirteen categories
/// equally would make the sixty-four percent of incidents that are medical as loud as
/// the five percent that are fires. See `docs/design-decisions.md`.
public struct CompactCell: Equatable, Sendable {

    public let text: String?
    public let warrantsAttention: Bool

    /// Whether this value came from a field other than the one the column names.
    ///
    /// There is one case. The City publishes an intersection instead of an address for some
    /// incidents, and leaves Prime Street blank when it does — the intersection is not a
    /// refinement of a missing address there, it is the only location there is. So it stands
    /// in, and is marked, because a reader who sees two street names joined by a slash in a
    /// column that otherwise holds one address should be able to find out why.
    ///
    /// A flag rather than a mark baked into `text`, so the published value stays exactly as
    /// published and the view decides how to say the rest.
    public let isFallback: Bool

    /// A blank value is not a value, and a mark with nothing to mark is a contradiction.
    /// Both are settled here rather than at each call site, so the state cannot be built even
    /// by a caller that tries — a cell that showed the intersection mark over an empty
    /// address is exactly what this prevents, and it is not a thing any caller should have to
    /// remember not to do.
    ///
    /// The blank check mirrors the parser's, which already turns the feed's three
    /// "not published" shapes into `nil`. This is the second line of defence rather than the
    /// first, and it is here because the first one is in another module.
    public init(
        _ text: String?,
        warrantsAttention: Bool = false,
        isFallback: Bool = false
    ) {
        let isBlank = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.text = isBlank ? nil : text
        self.warrantsAttention = warrantsAttention
        self.isFallback = isFallback && !isBlank
    }
}

/// One column of the compact table: what it is called, and how it reads one row.
///
/// **Generic over the row, because there is more than one source.** A fire incident and a police
/// call are different things with different fields — which is why they get models of their own —
/// but the table is *one* table: the same grid, the same equal shares, the same header, the same
/// cell renderer, the same fallbacks at accessibility sizes. So a column is a value that knows how
/// to read one row, and each source declares its own set.
///
/// **The count is therefore a property of the set rather than a constant of the layout.** Fire
/// declares five and police declares four, and nothing in the table assumes either, because every
/// column takes an equal share of the width — four columns divide it by four.
///
/// This is what replaced a closed enum. The enum was the fire feed's five columns *and* the only
/// shape a column could have, so a second source had nowhere to put its own.
public struct CompactColumn<Row>: Sendable {

    /// The full name, for the card and for the labelled layout at accessibility text sizes.
    public let label: String

    /// The cramped name, for the header above the grid, where width is the scarcest thing there is.
    public let headerLabel: String

    /// The cell this column draws for one row.
    public let cell: @Sendable (Row, DispatchTimeFormat) -> CompactCell

    public init(
        label: String,
        headerLabel: String? = nil,
        cell: @escaping @Sendable (Row, DispatchTimeFormat) -> CompactCell
    ) {
        self.label = label
        self.headerLabel = headerLabel ?? label
        self.cell = cell
    }
}

extension CompactColumn: Identifiable {

    /// The label is the identity: no two columns in one set share one, and a column is the same
    /// column whatever it happens to read. Taken from the label rather than stored beside it, so
    /// the two cannot come to disagree — which is the failure the header alignment has already had
    /// twice, in a different place.
    public var id: String { label }
}

// MARK: - The fire feed's columns

extension CompactColumn where Row == Incident {

    /// The address, or the area the City published in its place.
    public static let primeStreet = CompactColumn<Incident>(label: "Prime Street") { incident, _ in
        // Normally the address, or the postal area the City publishes in its place for a
        // medical incident. Both are `primeStreet`, and both are shown as published.
        if let street = incident.primeStreet {
            return CompactCell(street)
        }

        // Prime Street is blank here, which means the City published an intersection and
        // nothing else. Leaving the cell empty would hide a location the feed supplies,
        // for the incidents whose location is hardest to guess — so the intersection
        // stands in, marked as the fallback it is.
        //
        // Cross Street stays out of the table otherwise: it is a refinement of Prime
        // Street rather than a peer of it, and it is blank on most incidents. See
        // `docs/design-decisions.md`.
        //
        // Neither street, which happens. The address starts the row in both compact
        // arrangements, so an empty cell there leaves the eye without anything to land
        // on — the one place in the list where nothing at all looks like a fault rather
        // than like restraint. It shows the same mark the detail view uses.
        //
        // No substitution mark on it. `⇄ /` would say that a location was found
        // elsewhere and that the location is nothing.
        //
        // This is the only column that does this. The rest stay empty when the feed
        // published nothing, because a column of slashes is noise and their absence costs
        // the reader nothing.
        guard let intersection = incident.crossStreets,
              !intersection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return CompactCell(NotProvided.mark)
        }
        return CompactCell(intersection, isFallback: true)
    }

    /// When the City was called.
    public static let dispatchTime = CompactColumn<Incident>(label: "Dispatch Time") { incident, timeFormat in
        CompactCell(DispatchTimestamp.clockTime(incident.dispatchTime, format: timeFormat))
    }

    /// The City's own words for the call, as a category.
    public static let incidentType = CompactColumn<Incident>(label: "Incident Type") { incident, _ in
        let category = IncidentCategory.from(incidentType: incident.incidentType)
        return CompactCell(
            category?.label ?? incident.incidentType,
            warrantsAttention: category?.warrantsAttention ?? false
        )
    }

    /// How far the City escalated its response.
    public static let alarmLevel = CompactColumn<Incident>(
        label: "Alarm Level",
        headerLabel: "Alarm\nLevel"
    ) { incident, _ in
        CompactCell(
            incident.alarmLevel,
            warrantsAttention: AlarmLevel.isMajorResponse(incident.alarmLevel)
        )
    }

    /// The apparatus the City sent, exactly as published.
    public static let dispatchedUnits = CompactColumn<Incident>(label: "Dispatched Units") { incident, _ in
        // Left exactly as published. Decoding `P231` to `Pumper 231` is worth the
        // characters in the detail view and not here, where width is the scarcest
        // thing we have.
        CompactCell(incident.dispatchedUnits)
    }

    /// The fire feed's columns, in the order the table shows them.
    ///
    /// The single source of truth for this source's column set — order, labels, and the value each
    /// draws from an incident. **Five is this source's count, not the table's**: it is however many
    /// fields the fire feed publishes that are worth a column.
    ///
    /// Cross Street is deliberately absent. It is blank on most incidents — every medical one —
    /// and it is a refinement of Prime Street rather than a peer of it, so on a phone it spent
    /// width it rarely used. It lives in the detail view, as Incident Number and Area do.
    public static let fire: [CompactColumn<Incident>] = [
        primeStreet,
        dispatchTime,
        incidentType,
        alarmLevel,
        dispatchedUnits,
    ]

    /// The same five in the order the *card* reads them: what and where, then when and how much.
    ///
    /// Not the table's order, and deliberately. A card has two lines rather than five columns, and
    /// it puts the address beside the type because those are what the row is *about*; the clock,
    /// the level and the crews follow underneath. The order is a property of the card, so a source
    /// decides it for its own data — the shape is the same for both, which is the point.
    public static let fireCard: [CompactColumn<Incident>] = [
        primeStreet,
        incidentType,
        dispatchTime,
        alarmLevel,
        dispatchedUnits,
    ]
}
