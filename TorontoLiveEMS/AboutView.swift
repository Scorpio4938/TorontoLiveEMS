import SwiftUI
import TorontoLiveEMSKit

/// What this app is, on the screen a reader opens to ask that question.
///
/// **Not the same screen as *About this Data*.** That one is reference material for the feed — what
/// an Alarm Level means, what the unit codes are, which licences the shapes are under — and it is
/// reached from the info button beside Settings. This one is about the app: the icon, the name,
/// which version is in the reader's hand, and where the incidents it shows are published. There is
/// deliberately **no row to that other screen**: the licences have one home already, and a second
/// way in would be a second place to keep true.
///
/// **One external link, and it says whose it is.** An About screen is about *this* app, so a row
/// that opened somebody else's page without saying so would be a mistake the reader had no way to
/// avoid. The City's page sits under a header naming the City, with a footer that says the app only
/// reads what they publish and is not affiliated with them.
///
/// **Everything here is read rather than typed**: the name from the bundle, the version from the
/// bundle, the artwork from the asset catalogue, the City's page from the package. A string typed
/// into a screen is one that will one day disagree with the thing it was copied from.
struct AboutView: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    // The same artwork and the same corner as the Home screen, from the imagesets
                    // the icon previews already use: iOS rounds an icon on a continuous arc at about
                    // 22.4% of the edge, and a raw square beside the app's own name would not look
                    // like the icon at all.
                    //
                    // The dark variant in dark mode, because that is the one the Home screen is
                    // showing at the time.
                    Image(colorScheme == .dark ? "IconAppearanceDark" : "IconAppearanceLight")
                        .resizable()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 88 * 0.2237, style: .continuous))

                    Text(AppIdentity.name)
                        .font(.title3.weight(.semibold))

                    Text(AppIdentity.version)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            } footer: {
                Text(Self.versionNote)
            }

            Section {
                Text("A reader for Toronto Fire Services' active incidents and the Toronto Police Service's recent calls, as lists and as a map.")
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
                    Link(LiveCADFeed.pageName, destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("The City's page")
            } footer: {
                Text(
                    """
                    The incidents in this app are the City of Toronto's, published on their own \
                    page for anyone to read. This app reads them and is not affiliated with the \
                    City of Toronto.
                    """
                )
            }
        }
        .navigationTitle("About")
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
