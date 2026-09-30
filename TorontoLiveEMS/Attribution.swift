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
    /// handed a `String` variable — so `[name](url)` would appear as typed. Parsing it here
    /// once is what lets the sentence live in a single place. Drawn through `LinkedText`, which
    /// has the other half of the problem: what colour the link comes out.
    static var attributed: AttributedString {
        .fromMarkdown(source)
    }
}
