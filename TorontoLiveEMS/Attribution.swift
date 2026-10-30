import Foundation
import SwiftUI
import TorontoLiveEMSKit

/// The app's attribution and licence line.
///
/// In one place because several screens show it: the detail views, the information screens
/// and *Data Licences*. The licence name is an inline markdown link, so it reads as part of
/// the sentence rather than as a separate control beside it.
enum Attribution {

    /// The sentence, with both of its links written as markdown.
    ///
    /// Composed rather than written out, because the page's name and address are the feed's and
    /// live beside it. A page the City renames should be renamed in one place, and a link the
    /// app shows should be an address the app has actually checked.
    private static var source: String {
        """
        Not affiliated with the City of Toronto. Data shown from their public \
        [\(LiveCADFeed.pageName)](\(LiveCADFeed.pageURLString)) page. Contains information \
        licensed under the [Open Government Licence – Toronto](\(licenceURL)).
        """
    }

    /// The City's Open Data licence, which the feed's page links to.
    ///
    /// Here rather than in the package: nothing in the package is about licensing, and this
    /// sentence is the only thing that cites it.
    private static let licenceURL =
        "https://www.toronto.ca/city-government/data-research-maps/open-data/open-data-licence/"

    /// The shapes' licence, which is a different licence from the feed's and has to be shown too.
    ///
    /// **The sentence itself travels inside the data file.** That is the point of putting it
    /// there: the shapes and their attribution cannot be separated, so a missing attribution is
    /// not a possibility to remember. This shows that sentence and adds only the link a JSON file
    /// cannot carry.
    ///
    /// If the file failed to load there is nothing to attribute — and nothing drawn from it either
    /// — so the sentence would be the link alone, which is why the licence is named in the link's
    /// own text.
    static var postalAreas: AttributedString {
        .fromMarkdown(
            "\(PostalAreas.bundled.attribution) The licence: "
                + "[Open Government Licence – Canada](\(canadaLicenceURL))"
        )
    }

    /// The police calls' licence, which is a third one and has to be shown on the police screens.
    ///
    /// **Three licences, three providers.** The fire feed is the City of Toronto's, the postal-area
    /// shapes are Statistics Canada's under the Canadian licence, and the police calls are the
    /// Toronto Police Service's under Ontario's. Each is stated where its data is explained, and
    /// *Data Licences* gathers the three — none is stated generically, because a licence that names
    /// the wrong provider is worse than one that is missing: it reads as compliance.
    ///
    /// The attribution string is the provider's own: *Toronto Police Service*, which is what the
    /// item's `accessInformation` says.
    static var policeCalls: AttributedString {
        .fromMarkdown(
            "Calls for service: Toronto Police Service. Contains information licensed under the "
                + "[Open Government Licence – Ontario](\(ontarioLicenceURL))"
        )
    }

    /// The Government of Canada's open licence, which Statistics Canada's boundary file is under.
    /// Statistics Canada's own metadata names it in exactly these terms.
    private static let canadaLicenceURL =
        "https://open.canada.ca/en/open-government-licence-canada"

    /// The Government of Ontario's open licence, which the police calls are published under.
    /// Checked rather than assumed: it answers 200 to a plain request.
    private static let ontarioLicenceURL =
        "https://www.ontario.ca/page/open-government-licence-ontario"

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
