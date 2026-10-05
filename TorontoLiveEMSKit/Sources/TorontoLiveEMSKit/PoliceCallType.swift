import Foundation

/// One call type the Service has used, as the Service published it.
///
/// **Derived from the calls, because the Service publishes no legend.** Checked rather than assumed,
/// and checked everywhere a legend could have been: the item's `description` is empty, its
/// `licenseInfo` is the licence alone, no field on the layer carries a coded-value domain, and the
/// Service's own web application — all 144 KB of its configuration — contains no list of codes. What
/// the Service *does* publish is both halves of the mapping, on every call: a code, and the words it
/// stands for. So the app collects them, which is what this type is.
///
/// **A record rather than a vocabulary.** It holds the codes in the calls the app has read, which is
/// the Service's own four-hour window — so it is as complete as the last four hours were busy, and a
/// code that has not come up yet cannot be in it. That limit is the reason the screen showing it says
/// so in its own words, rather than presenting a list that looks complete because it has no gaps.
public struct PoliceCallType: Identifiable, Equatable, Sendable {

    /// The Service's own code, spelled exactly as published.
    public let code: String

    /// The words the Service sent beside that code.
    ///
    /// Almost always one. More than one means the Service has used different words for the same code
    /// while the app was watching, and that is shown rather than silently reconciled: picking one
    /// would be this app deciding which of the Service's names is right.
    public let names: [String]

    public var id: String {
        code
    }

    public init(code: String, names: [String]) {
        self.code = code
        self.names = names
    }

    /// Every code in these calls, with the Service's words beside it.
    ///
    /// Ordered by code, which is how the fire screen's own legend is ordered and how someone looking
    /// one up will look. Duplicates are not possible: a code appears once however many calls carried
    /// it, which is the whole point of collecting rather than listing.
    public static func published(in calls: [PoliceCall]) -> [PoliceCallType] {
        var names: [String: Set<String>] = [:]
        for call in calls {
            names[call.callTypeCode, default: []].insert(call.callType)
        }

        return names
            .map { PoliceCallType(code: $0.key, names: $0.value.sorted()) }
            .sorted { $0.code < $1.code }
    }
}
