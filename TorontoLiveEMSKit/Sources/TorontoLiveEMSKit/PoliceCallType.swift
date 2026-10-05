import Foundation

/// One call type, as the Service publishes it: a code, and the words that go with it.
public struct PoliceCallType: Identifiable, Equatable, Sendable {

    /// The Service's own code, spelled exactly as published.
    public let code: String

    /// The words the Service sends beside that code, exactly as published.
    ///
    /// Upper case, because that is what a reader sees on a call in the table and in the detail view,
    /// and the same string in both places is the point — a code looked up here has to match the call
    /// it came from.
    public let name: String

    public var id: String {
        code
    }

    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }

    /// The codes the Service has been observed using, and what each one means.
    ///
    /// **Gathered from the Service, not invented, and static.** Every call carries both halves of this
    /// mapping, so it was collected from the calls themselves — and the two numbers involved are worth
    /// keeping apart. On 2026-10-05 the Service held **ninety-six calls**, which are individual
    /// incidents; among them were **thirty distinct codes**, which are kinds of incident. One code
    /// appears on many calls: `DIS` alone was seventeen of the ninety-six. So this list is thirty
    /// entries because thirty kinds of thing happened in four hours, not because the Service has only
    /// thirty kinds of call — and it is a starting point rather than an inventory. Adopting a code the
    /// Service is not using, or guessing at one, would be this app inventing the Service's vocabulary;
    /// guessing is not even possible, since `INDEX` means *indecent exposure* while `EXPJU` means
    /// *indecent exposure just occurred*.
    ///
    /// **A reference rather than a lookup, which is what makes an incomplete list harmless.** No screen
    /// resolves a call's code through this: the table and the detail view show the words the Service
    /// sent with the call, so a code missing here is still shown correctly there. A missing row costs a
    /// reader one unanswered question; it cannot make the app wrong.
    ///
    /// Ordered by code, which is how somebody looking one up looks.
    public static let documented: [PoliceCallType] = [
        PoliceCallType(code: "ARR", name: "ARREST"),
        PoliceCallType(code: "ASS", name: "ASSAULT"),
        PoliceCallType(code: "ASSJU", name: "ASSAULT JUST OCCURRED"),
        PoliceCallType(code: "ASSPR", name: "ASSAULT IN PROGRESS"),
        PoliceCallType(code: "ATTBR", name: "ATTEMPT BREAK & ENTER"),
        PoliceCallType(code: "BREEN", name: "BREAK & ENTER"),
        PoliceCallType(code: "DAM", name: "DAMAGE"),
        PoliceCallType(code: "DEMO", name: "DEMONSTRATION"),
        PoliceCallType(code: "DIS", name: "DISORDERLIES"),
        PoliceCallType(code: "DISPU", name: "DISPUTE"),
        PoliceCallType(code: "EXPJU", name: "INDECENT EXPOSURE JUST OCCURRED"),
        PoliceCallType(code: "FIG", name: "FIGHT"),
        PoliceCallType(code: "FIR", name: "FIRE"),
        PoliceCallType(code: "FIRAL", name: "FIRE ALARM"),
        PoliceCallType(code: "FOUPR", name: "FOUND PROPERTY"),
        PoliceCallType(code: "FRA", name: "FRAUD"),
        PoliceCallType(code: "HAZ", name: "HAZARD"),
        PoliceCallType(code: "IMPDR", name: "IMPAIRED DRIVER"),
        PoliceCallType(code: "INDEX", name: "INDECENT EXPOSURE"),
        PoliceCallType(code: "MISVU", name: "MISSING VULNERABLE PERSON"),
        PoliceCallType(code: "PDACC", name: "PROPERTY DAMAGE COLLISION"),
        PoliceCallType(code: "PERGU", name: "PERSON WITH A GUN"),
        PoliceCallType(code: "PIACC", name: "PERSONAL INJURY COLLISION"),
        PoliceCallType(code: "SEEAM", name: "SEE AMBULANCE"),
        PoliceCallType(code: "THEAU", name: "THEFT FROM AUTO"),
        PoliceCallType(code: "THEJU", name: "THEFT JUST OCCURRED"),
        PoliceCallType(code: "THEPR", name: "THEFT IN PROGRESS"),
        PoliceCallType(code: "TRE", name: "TRESPASS"),
        PoliceCallType(code: "UNKTR", name: "UNKNOWN TROUBLE"),
        PoliceCallType(code: "WRWAY", name: "WRONG WAY VEHICLE"),
    ]
}
