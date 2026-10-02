import SwiftUI

/// The two colours a mark can take, defined once.
///
/// **Red is the most urgent; orange is everything else.** A map has to give every shape and every
/// dot *some* colour, so unlike the table — which colours what is exceptional and leaves the rest
/// plain — "ordinary" needs a name of its own here.
///
/// **One definition, because this was spelled out in six places.** `Color.orange` appeared
/// wherever an incident warranted attention, which made the colour impossible to move and easy to
/// drift: the postal areas used it for their *shape* rather than for anything urgent, so a quiet
/// neighbourhood and a dangerous one looked identical, and red — the app's own accent — meant
/// "nothing to see" on a pin while orange meant "something to see" on the area behind it.
///
/// The accent is the red. It is the app's identity colour, already fire red, and having one red
/// rather than two is what makes "red means urgent" true everywhere at once.
enum MarkColour {

    /// The most urgent: a fire, hazmat, carbon monoxide or rescue, or ten or more vehicles.
    /// See `Incident.warrantsAttention`, which is the one home of that rule.
    static let urgent = Color.accentColor

    /// Everything else.
    static let ordinary = Color.orange

    /// Red for the urgent, orange for the rest.
    static func of(warrantsAttention: Bool) -> Color {
        warrantsAttention ? urgent : ordinary
    }
}
