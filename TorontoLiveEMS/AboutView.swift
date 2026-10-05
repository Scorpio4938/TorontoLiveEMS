import SwiftUI
import TorontoLiveEMSKit

/// What this app is, on the screen a reader looks at to ask that question.
///
/// **Not the same screen as *About this Data*.** That one is reference material for the feed: what
/// an Alarm Level means, what the unit codes are, which licence the postal-area shapes are under.
/// This one is about the app — what it is for, which version is in the reader's hand, and where the
/// data it shows comes from. The two were sections of one Settings screen until the sections
/// stopped being settings, and the split follows the question rather than the file.
///
/// **Everything here is read rather than typed.** The name comes from the bundle, the version from
/// the bundle, and the City's page from the package. A string typed into a screen is one that will
/// one day disagree with the thing it was copied from — which is the same reason the version is not
/// written here either.
struct AboutView: View {

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.name)
                        .font(.headline)
                    Text(Self.version)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 2)
            } footer: {
                Text(Self.versionNote)
            }

            Section {
                Text(
                    """
                    A reader for Toronto Fire Services' active incidents, as a list and as a map. \
                    The incidents are the City's own, published for anyone to read.
                    """
                )
            } header: {
                Text("What this is")
            } footer: {
                Text(
                    """
                    Not affiliated with the City of Toronto. Nothing is collected, and the only \
                    things this app asks the network for are the City's feed and — for a location \
                    with no published shape — Apple's geocoder.
                    """
                )
            }

            Section {
                // A `Link` rather than a button opening Safari, so the platform decides how to
                // open it and a long press gives the reader the menu they get anywhere else.
                //
                // No row for the source repository, and its absence is deliberate: the repository
                // is private, so the link would answer 404 to everyone who is not its owner, and a
                // link a reader cannot open is worse than no link. It belongs here the day it is
                // public.
                if let url = LiveCADFeed.pageURL {
                    Link(LiveCADFeed.pageName, destination: url)
                }
            } header: {
                Text("Links")
            }

            Section {
                NavigationLink {
                    AboutThisDataContent()
                } label: {
                    Text("About this Data")
                }
            } footer: {
                Text(
                    """
                    Every field explained, and the licences this app's data and its postal-area \
                    shapes are used under.
                    """
                )
            }
        }
        .navigationTitle("About")
    }

    /// The app's name, as the device shows it.
    ///
    /// Read rather than typed, so the row and the Home screen cannot disagree. The project sets no
    /// `CFBundleDisplayName`, so this is the target name — `TorontoLiveEMS`, without the spaces the
    /// app is called in prose. Setting `INFOPLIST_KEY_CFBundleDisplayName` to *Toronto Live EMS* is
    /// the whole of that change, and then both places say it without being told.
    private static var name: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "This app"
    }

    /// The number the bundle carries, which is `MARKETING_VERSION` in the project.
    ///
    /// **Read, never written, and that is what the row is for.** A version typed into a screen is
    /// one that will one day disagree with the project it was built from — so that sentence lives
    /// here, with the decision, rather than in front of a reader who is looking for what their
    /// version *means*.
    ///
    /// Whether a *tag* carries the same number is `scripts/version_check.py`'s business rather than
    /// this screen's — a screen cannot check a repository — and `docs/releasing.md` holds the scheme.
    private static var bundleVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "unknown"
    }

    /// The version as a reader should see it: the checkpoint, and the build.
    ///
    /// **The build is shown even though it stays at 1 until the app is distributed.** It is the one
    /// number that changes with every upload, so it is the number someone reporting a problem will
    /// be asked for — and a version row that conceals a number the app has is a row that leaves the
    /// reader wondering what else it is not saying.
    private static var version: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "unknown"
        return "\(bundleVersion) (\(build))"
    }

    /// What the two numbers are, and what the version says about the app.
    ///
    /// The first sentence is for a reader looking at two numbers and wondering which is which. The
    /// second comes from the package, so the words a test pins are the words a reader sees — the
    /// same rule the layout names follow in Settings. A version with no stage gets the first
    /// sentence alone, which is the honest answer for a number this cannot read.
    private static var versionNote: String {
        let whatTheNumbersAre =
            "The version is the checkpoint, and the number in brackets is the build."
        guard let stage = VersionStage.of(bundleVersion) else { return whatTheNumbersAre }
        return "\(whatTheNumbersAre) \(stage.note)"
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
