import SwiftUI
import TorontoLiveEMSKit

/// What this app is, on the screen a reader opens to ask that question.
///
/// **Not the same screen as *About this Data*.** That one is reference material for the feed — what
/// an Alarm Level means, what the unit codes are, and how the feed is published — and it is reached
/// from the info button beside Settings. This one is about the app: the icon, the name, which
/// version is in the reader's hand, where the data it shows is published, and what a reader may do
/// with its source. There is deliberately **no row to that other screen**: it is reached from the
/// info button beside Settings, and a second way in would be a second place to keep true.
///
/// **Every external link says whose it is.** An About screen is about *this* app, so a row that
/// opened somebody else's page without saying so would be a mistake the reader had no way to avoid.
/// The City's page and the Service's page sit under *Sources*, each row labelled with its publisher;
/// the repository row is labelled as this app's own source.
///
/// **Everything here is read rather than typed**: the name and version through `AppIdentity`, the
/// icon mark from the asset catalogue, both publishers' pages from the package. The repository
/// address and the icon's original artwork are constants because no publisher carries them.
struct AboutView: View {

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    // The app icon itself, from the one Icon Composer document the app ships.
                    // The same view is on the Welcome screen, so neither keeps a copy of the
                    // artwork and the two cannot drift from what the device is showing.
                    AppIconView(size: 88)

                    Text(AppIdentity.name)
                        .font(.title3.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)

                LabeledContent("Version", value: AppIdentity.version)
            } footer: {
                Text(Self.versionNote)
            }

            Section {
                Text("Live fire incidents and police calls in Toronto, as lists and on a map. The incidents are Toronto Fire Services', republished by the City every five minutes. The calls are the Toronto Police Service's, published as they are dispatched.")
            } header: {
                Text("What this is")
            } footer: {
                Text(
                    """
                    Nothing is collected. The app asks the City for its fire incidents, the Toronto \
                    Police Service for its recent calls, and — for a location with no published \
                    shape — Apple's geocoder.
                    """
                )
            }

            Section {
                // **Blue, like every other link in the app.** The accent is fire red, and a link
                // drawn in it reads as a warning rather than as something to tap — which is the
                // same judgement `LinkedText` already makes for the licence notices.
                if let url = LiveCADFeed.pageURL {
                    Link(destination: url) {
                        LabeledContent("City of Toronto", value: LiveCADFeed.pageName)
                    }
                    .tint(.blue)
                }

                if let url = CallsForServiceFeed.pageURL {
                    Link(destination: url) {
                        LabeledContent(CallsForServiceFeed.provider, value: CallsForServiceFeed.pageName)
                    }
                    .tint(.blue)
                }
            } header: {
                Text("Sources")
            } footer: {
                Text("The publishers' own pages for the incidents and calls in this app. This app reads what they publish and is not affiliated with either publisher.")
            }

            Section {
                if let url = Self.repositoryURL {
                    Link("Repository", destination: url)
                        .tint(.blue)
                }

                NavigationLink {
                    AppIconLicenceView()
                } label: {
                    LabeledContent(
                        "App Icon",
                        value: "\(Attribution.iconTitle) · \(Attribution.iconProvider)"
                    )
                }

                LabeledContent("App Licence", value: "All rights reserved")
            } header: {
                Text("This app")
            } footer: {
                Text("The source is public, but no licence has been added yet. That means all rights are reserved.")
            }
        }
        .navigationTitle("About")
    }

    /// The repository's public address.
    ///
    /// **Typed, because nothing publishes it.** Every other address on this screen comes from the
    /// package beside the data it addresses; the app's own source has no such owner. It is a
    /// constant rather than a string in the row so a move happens in one place.
    private static let repositoryURLString = "https://github.com/Scorpio4938/TorontoLiveEMS"

    private static var repositoryURL: URL? {
        URL(string: repositoryURLString)
    }

    /// What the two numbers are, and what the version says about the app.
    ///
    /// The first sentence is for a reader looking at two numbers and wondering which is which. The
    /// second comes from the package, so the words a test pins are the words a reader sees. A
    /// version with no stage gets the first sentence alone, which is the honest answer for a number
    /// this cannot read.
    private static var versionNote: String {
        let whatTheNumbersAre =
            "The version is the checkpoint, and the number in brackets is the build."
        guard let stage = VersionStage.of(AppIdentity.marketingVersion) else {
            return whatTheNumbersAre
        }
        return "\(whatTheNumbersAre) \(stage.note)"
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
