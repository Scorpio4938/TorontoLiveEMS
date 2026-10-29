import SwiftUI
import TorontoLiveEMSKit

/// The three colours a mark can take, defined once.
///
/// **Dark red is the most serious, orange is the middle, grey is everything else** — and "everything
/// else" is most of what is on the map. That is the correction this went through. The second colour
/// used to be orange for *ordinary*, and with nine tenths of the City's incidents ordinary the map was
/// a wall of warning: a colour that marks exceptions has to leave the majority quiet, or it marks
/// nothing.
///
/// **Three tones, and no legend to learn.** Red reads as serious and grey recedes, which is the whole
/// of the rule. The *kind* of an incident is its symbol; the colour is only ever how much it matters.
///
/// The accent is the red. It is the app's identity colour, already fire red, and having one red rather
/// than two is what makes "red means urgent" true everywhere at once.
enum MarkColour {

    /// A fire, hazmat, carbon monoxide or rescue — or a police call where somebody may be in danger now.
    static let critical = Color.accentColor

    /// Serious but not immediate: a major response, an assault that has already happened, a hazard.
    static let elevated = Color.orange

    /// Everything else, which is most of the map.
    ///
    /// `unknown` shares this tone. The map's job is to say what is alarming, and "we do not know" is not
    /// alarming — the difference between an ordinary call and one the Service could not name is carried
    /// by the symbol, which is where a kind belongs.
    static let routine = Color.secondary

    /// The tone for the two-step question, for the callers that only have "does this warrant
    /// attention" — the small map in a fire incident's detail view, and the table's tint.
    ///
    /// It is the same rule with the middle step removed, and it exists so that the boolean the fire
    /// feed already computes does not have to be translated at every call site.
    static func of(warrantsAttention: Bool) -> Color {
        warrantsAttention ? critical : routine
    }

    /// The tone for a severity.
    static func of(_ urgency: IncidentMark.Urgency) -> Color {
        switch urgency {
        case .critical:
            return critical
        case .elevated:
            return elevated
        case .routine, .unknown:
            return routine
        }
    }
}
