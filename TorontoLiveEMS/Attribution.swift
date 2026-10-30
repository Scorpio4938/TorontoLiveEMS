import Foundation
import SwiftUI
import TorontoLiveEMSKit

/// The app's attribution and licence sentences.
///
/// **One place now.** The licence pages behind *Data Licences* state each provider's attribution and
/// link its licence; a data screen carries one sentence naming the publisher and the licence, and a
/// row to those pages. Three licences, three providers, and no screen has to spell a provider
/// differently from another.
enum Attribution {

    /// The fire feed's attribution, for *Fire Data Licence*.
    ///
    /// The City publishes the incidents and licenses them under Toronto's open licence. The sentence
    /// names both and links the licence text, so a reader who wants the terms is one tap away.
    static var fire: AttributedString {
        .fromMarkdown(
            "Fire incidents: City of Toronto. Contains information licensed under the "
                + "[\(torontoLicenceName)](\(torontoLicenceURL))."
        )
    }

    /// The one sentence a fire data screen carries.
    ///
    /// **Non-affiliation is not a licence clause, and stays in the sentence deliberately.** The
    /// screen showing somebody's data is where a reader may think the app is official, so that is
    /// where the disclaimer belongs.
    static let fireNotice =
        "Not affiliated with the City of Toronto. Fire data licensed under the \(torontoLicenceName)."

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
                + "[\(canadaLicenceName)](\(canadaLicenceURL))"
        )
    }

    /// The police calls' attribution, for *Police Data Licence*.
    ///
    /// The attribution names the Service whose calls these are, and the licence is Ontario's rather
    /// than Toronto's or Canada's. Both names come from the feed, so a renamed provider or licence
    /// changes here and on the screen that shows the calls.
    static var policeCalls: AttributedString {
        .fromMarkdown(
            "Calls for service: \(CallsForServiceFeed.provider). Contains information licensed under "
                + "the Government of Ontario's [\(CallsForServiceFeed.licenceName)](\(ontarioLicenceURL))"
        )
    }

    /// The one sentence a police data screen carries.
    ///
    /// The same judgement as `fireNotice`: non-affiliation is stated where a reader might mistake
    /// the app for the publisher.
    static let policeNotice =
        "Not affiliated with the \(CallsForServiceFeed.provider). Police data licensed under the \(CallsForServiceFeed.licenceName)."

    /// The City's licence, which the fire feed's page links to.
    private static let torontoLicenceName = "Open Government Licence – Toronto"

    /// The City's Open Data licence address.
    private static let torontoLicenceURL =
        "https://www.toronto.ca/city-government/data-research-maps/open-data/open-data-licence/"

    /// The Government of Canada's open licence, which Statistics Canada's boundary file is under.
    /// Statistics Canada's own metadata names it in exactly these terms.
    private static let canadaLicenceName = "Open Government Licence – Canada"

    private static let canadaLicenceURL =
        "https://open.canada.ca/en/open-government-licence-canada"

    /// The Government of Ontario's open licence, which the police calls are published under.
    /// Checked rather than assumed: it answers 200 to a plain request.
    private static let ontarioLicenceURL =
        "https://www.ontario.ca/page/open-government-licence-ontario"
}
