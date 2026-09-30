/// What a field with nothing published behind it shows.
///
/// A slash, and the same slash in both views. A reader who learns the mark in the list should
/// not meet a second one in the detail view, and the app should not have two answers to
/// "what does an absent value look like".
///
/// It is not a substitute and never carries the substitution mark. `⇄ /` would be saying that
/// a location was found somewhere else and that the location is nothing, which is two
/// contradictory statements in one cell.
///
/// Where it is used differs by view, and that is deliberate. The detail view shows every
/// field, so every absent one gets the mark — an empty row there reads as a loading fault.
/// The compact arrangements leave most absent fields empty, because a column of slashes is
/// noise, and use the mark only where an empty *leading* cell would leave the eye without
/// anything to land on: the address, which starts the row.
public enum NotProvided {

    /// The mark itself.
    public static let mark = "/"
}
