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

    /// `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`, as the bundle carries them.
    ///
    /// Read, never written. The project in Xcode is the source of the number and this only
    /// reports it, which is also why nothing here tries to keep a tag and a version in step:
    /// that is one field in Xcode, and the project file is Xcode's to own.
    private static var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(short ?? "unknown") (\(build ?? "unknown"))"
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
                    Text("Active Incidents")
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
                    Text("The app's own version, read from the app rather than written down here — a version typed into a screen is one that will one day disagree with the project it was built from.")
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
