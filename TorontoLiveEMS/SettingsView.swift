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
    /// Read, never written: the project file is the source of the number and this only reports it.
    /// Whether a *tag* carries the same number is `scripts/version_check.py`'s business rather
    /// than this screen's — a screen cannot check a repository — and `docs/releasing.md` is where
    /// the scheme itself is written down.
    private static var bundleVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "unknown"
    }

    /// The version as a reader should see it: the number, and the stage the number reports.
    ///
    /// **The build number is deliberately not shown.** Nothing has been distributed, and
    /// `CURRENT_PROJECT_VERSION` is not maintained until there is something to distribute — the
    /// scheme puts it with the act of shipping. A row reading "0.0.9 (1)" claims a build one, which
    /// is neither true in any useful sense nor a number anyone chose. It comes back when it means
    /// something, and the first upload is when it means something.
    private static var version: String {
        guard let stage = VersionStage.of(bundleVersion) else { return bundleVersion }
        return "\(bundleVersion) · \(stage.label)"
    }

    /// What the version means, in the two sentences a reader has room for.
    ///
    /// The first is the reason this row exists at all. The second comes from the package, so the
    /// words a test pins are the words a reader sees — the same rule the layout names above follow.
    /// A version with no stage gets the first sentence alone, which is the honest answer for a
    /// number this cannot read.
    private static var versionNote: String {
        let provenance = """
            Read from the app rather than written into this screen: a version typed here is one \
            that will one day disagree with the project it was built from.
            """
        guard let stage = VersionStage.of(bundleVersion) else { return provenance }
        return "\(provenance) \(stage.note)"
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
