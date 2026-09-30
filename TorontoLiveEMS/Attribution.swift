import Foundation
import SwiftUI

/// The app's attribution and licence line.
///
/// In one place because two screens show it: the detail view and Settings. The licence
/// name is an inline markdown link, so it reads as part of the sentence rather than as a
/// separate control beside it.
enum Attribution {

    private static let source = "Not affiliated with the City of Toronto. Data shown from their public Toronto Fire Active Incidents page. Contains information licensed under the [Open Government Licence – Toronto](https://www.toronto.ca/city-government/data-research-maps/open-data/open-data-licence/)."

    /// The sentence with its link parsed.
    ///
    /// `Text` parses markdown from a string literal, but renders the syntax verbatim when
    /// handed a `String` variable — so `[name](url)` would appear as typed. Parsing it
    /// here once is what lets the sentence live in a single place.
    static var attributed: AttributedString {
        if let parsed = try? AttributedString(markdown: source) {
            return parsed
        }
        return AttributedString(source)
    }
}

/// The sentence as it is drawn, with its link in blue.
///
/// A view rather than a bare `Text(Attribution.attributed)` in each place, because the link
/// needs a colour and two screens drawing the same sentence should not be able to disagree
/// about it.
///
/// **Blue because red is the app's accent and links take the accent.** That is correct
/// behaviour — it is what an accent is for, and Apple Music does exactly the same — but red
/// also means error and destructive, so a licence notice drawn in it reads as a warning
/// rather than as a reference. Blue is what a link looks like, and this is the one place the
/// accent is overridden. The rest of the app stays fire red.
///
/// `tint` rather than a `foregroundColor` on the parsed link run. Both are plausible; this
/// one is documented as *the* colour of a link, and the other depends on an explicit run
/// attribute winning against the tint, which nothing here can check.
struct AttributionText: View {

    var body: some View {
        Text(Attribution.attributed)
            .tint(.blue)
    }
}
