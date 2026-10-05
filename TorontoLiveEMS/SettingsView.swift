import SwiftUI
import TorontoLiveEMSKit

/// The app's preferences, and where each one is stored.
///
/// `@AppStorage` is the platform's own lightweight preference store, and
/// `DispatchTimeFormat` is `RawRepresentable` over `String`, which is what it wants.
/// There is no settings model and no synchronisation, because there are two preferences.
enum SettingsKey {
    static let dispatchTimeFormat = "dispatchTimeFormat"
    static let presentation = "incidentPresentation"
    /// Which kind of map the map page draws. Read by `RootView`'s chrome as well as by the page,
    /// which is the point of it being a stored preference rather than state passed down.
    static let mapKind = "mapKind"
}

/// The app's preferences, and one row to everything that is not one.
///
/// **Preferences inline; reference material behind a row.** A picker is a value being chosen, and it
/// belongs where it is chosen. A version number, a description of the app and a licence are things
/// to read, and they had collected into sections here — which is how a screen for choosing things
/// came to be a screen for reading them too. So this applies the judgement the project had already
/// made once for *About this Data*: reference material is a screen of its own behind a row, not a
/// section in Settings.
///
/// The version and the attribution moved to *About* rather than being copied into it, so each has
/// one home — and the licences keep theirs in *About this Data*, which *About* links to rather than
/// repeating.
struct SettingsView: View {

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    @Environment(\.dismiss) private var dismiss

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
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("About")
                    }
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
