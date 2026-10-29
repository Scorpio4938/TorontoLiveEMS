import Foundation

/// How far back a police screen looks by default, and what it does with the rest.
///
/// **A police call is a log entry; a fire incident is a state.** That is the whole reason this type
/// exists for one feed and not the other. The Service holds four hours of calls — about a hundred on a
/// busy afternoon — and a call from three hours ago is *over*, so showing it beside a call from ten
/// minutes ago buries the one a reader can still do something about. The City's fire feed is different
/// in kind: an incident from three hours ago is still on it because it is still happening, so age there
/// is evidence of an emergency rather than of staleness, and no window applies.
///
/// **`RawRepresentable` over `String`, like `DispatchTimeFormat`**, which is what `@AppStorage` wants.
public enum PoliceCallWindow: String, CaseIterable, Sendable {

    case thirtyMinutes
    case oneHour
    case twoHours
    /// **Everything the Service holds.** The feed is a rolling four-hour window, so this is not a
    /// choice about taste — it is the whole of the data, and every call on it is inside the window.
    case fourHours

    /// The name a reader sees in Settings.
    public var label: String {
        switch self {
        case .thirtyMinutes: return "Last 30 minutes"
        case .oneHour: return "Last hour"
        case .twoHours: return "Last 2 hours"
        case .fourHours: return "Last 4 hours"
        }
    }

    /// How long the window is.
    public var duration: TimeInterval {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .fourHours: return 4 * 60 * 60
        }
    }

    /// The calls a screen shows, and the calls it folds away.
    ///
    /// **One filter and its complement**, rather than two passes over the list: a call is shown if it is
    /// inside the window, or if it is critical and the reader has asked for critical calls to be kept.
    /// The feed hands this list over newest first and neither half is re-sorted, so a call keeps the
    /// place the feed's rule gave it.
    ///
    /// **The exemption is about severity, not about kind.** A shooting three hours ago is worth a
    /// reader's attention now; a theft three hours ago is not. `Urgency` is where that lives, so this
    /// does not need to know what any particular call type is — and a call whose kind the app has not
    /// met is `.unknown`, which is not `.critical`, so it folds rather than shouting.
    public func split(
        _ calls: [PoliceCall],
        keepingCritical: Bool,
        now: Date
    ) -> (shown: [PoliceCall], folded: [PoliceCall]) {
        let cutoff = now.addingTimeInterval(-duration)
        var shown: [PoliceCall] = []
        var folded: [PoliceCall] = []

        for call in calls {
            let isRecent = call.occurrenceTime >= cutoff
            let isKept = keepingCritical
                && IncidentMark.Urgency(callTypeCode: call.callTypeCode) == .critical
            if isRecent || isKept {
                shown.append(call)
            } else {
                folded.append(call)
            }
        }
        return (shown, folded)
    }
}
