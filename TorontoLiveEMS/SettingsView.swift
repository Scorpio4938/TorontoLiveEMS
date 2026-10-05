import SwiftUI
import TorontoLiveEMSKit

/// The app's preferences, and where each one is stored.
///
/// `@AppStorage` is the platform's own lightweight preference store, and
/// `DispatchTimeFormat` is `RawRepresentable` over `String`, which is what it wants.
/// There is no settings model and no synchronisation, because there is one preference.
enum SettingsKey {
    static let dispatchTimeFormat = "dispatchTimeFormat"
    static let presentation = "incidentPresentation"
    /// Which kind of map the map page draws. Read by `RootView`'s chrome as well as by the page,
    /// which is the point of it being a stored preference rather than state passed down.
    static let mapKind = "mapKind"
}

struct SettingsView: View {

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    @Environment(\.dismiss) private var dismiss

    /// The number the bundle carries, which is `MARKETING_VERSION` in the project.
    ///
    /// **Read, never written, and that is what the row is for.** A version typed into a screen is
    /// one that will one day disagree with the project it was built from — so that sentence lives
    /// here, with the decision, rather than in the footer, where a reader is looking for what their
    /// version *means* rather than for why this code is written the way it is.
    ///
    /// Whether a *tag* carries the same number is `scripts/version_check.py`'s business rather
    /// than this screen's — a screen cannot check a repository — and `docs/releasing.md` holds the
    /// scheme itself.
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
    /// same rule the layout names above follow. A version with no stage gets the first sentence
    /// alone, which is the honest answer for a number this cannot read.
    private static var versionNote: String {
        let whatTheNumbersAre =
            "The version is the checkpoint, and the number in brackets is the build."
        guard let stage = VersionStage.of(bundleVersion) else { return whatTheNumbersAre }
        return "\(whatTheNumbersAre) \(stage.note)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // The names come from the type rather than being written here, so
                    // the strings a test pins are the strings a reader sees.
                    Picker("Layout", selection: $presentation) {
                        ForEach(IncidentPresentation.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                } header: {
                    Text("Fire")
                } footer: {
                    Text("The table fits more incidents on a screen. Cards give each one a block of its own.")
                }

                Section {
                    Picker("Format", selection: $dispatchTimeFormat) {
                        Text("12-Hour").tag(DispatchTimeFormat.twelveHour)
                        Text("24-Hour").tag(DispatchTimeFormat.twentyFourHour)
                    }
                } header: {
                    Text("Dispatch Time")
                } footer: {
                    Text("How the time of day is shown.")
                }

                Section {
                    LinkedText(Attribution.attributed)
                } header: {
                    Text("About")
                }

                Section {
                    LabeledContent("Version", value: Self.version)
                } footer: {
                    Text(Self.versionNote)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
