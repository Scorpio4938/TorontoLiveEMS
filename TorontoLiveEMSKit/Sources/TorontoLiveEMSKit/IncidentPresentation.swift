/// How the list of active incidents is arranged.
///
/// Two whole-list layouts rather than a column toggle. They show the same five fields and
/// differ only in shape, so this is a choice about how much a reader has to scan at once
/// rather than about what they are told.
///
/// **Cards are the default.** They show fewer incidents at once than the table does, and that
/// trade is deliberate rather than an oversight: one incident per block is the arrangement the
/// app opens on, and the table is still there for a reader who wants more on screen at a time.
///
/// This lives here rather than in the app target for the same reason `CompactColumn` does —
/// it is a display decision with no SwiftUI in it, so it can be tested, and it is the same
/// shape as the clock preference beside it in Settings.
public enum IncidentPresentation: String, CaseIterable, Sendable {

    /// Five fields on one grid row. Every incident is the same height, and a screen holds
    /// as many as will fit.
    case compactTable

    /// One block per incident, two lines each, the block formed by the platform's own
    /// grouped list.
    case cards

    /// What a reader gets before they have chosen anything.
    ///
    /// Cards, and chosen rather than derived — they show fewer incidents at once than the table
    /// does, which is the trade being made on purpose. Defined here rather than in each view so
    /// that changing it is a decision with a test on it, instead of a slip in one of two default
    /// values.
    ///
    /// It only decides what an *unset* preference resolves to. A reader who has chosen either
    /// arrangement keeps it, because `@AppStorage` writes their choice and this value is never
    /// consulted again.
    public static let standard: IncidentPresentation = .cards

    /// The reader-facing name, for the setting that picks between them.
    public var label: String {
        switch self {
        case .compactTable:
            return "Table"
        case .cards:
            return "Cards"
        }
    }
}
