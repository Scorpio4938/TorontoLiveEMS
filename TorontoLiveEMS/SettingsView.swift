import SwiftUI
import TorontoLiveEMSKit

/// The app's preferences, and where each one is stored.
///
/// `@AppStorage` is the platform's own lightweight preference store, and
/// `DispatchTimeFormat` is `RawRepresentable` over `String`, which is what it wants.
/// There is no settings model and no synchronisation: a preference is a key and a default.
enum SettingsKey {
    static let dispatchTimeFormat = "dispatchTimeFormat"
    static let presentation = "incidentPresentation"
    /// Which half of a police call's type the table and the card show.
    static let policeCallTypeStyle = "policeCallTypeStyle"
    /// How far back the police screens look by default.
    static let policeCallWindow = "policeCallWindow"
    /// Whether a critical police call is shown even when it falls outside that window.
    static let policeCallKeepsCritical = "policeCallKeepsCritical"
    /// Whether the map's police marks come from the whole four hours rather than the window.
    static let mapShowsAllPoliceHours = "mapShowsAllPoliceHours"
    /// Which kind of map the map page draws. Read by `RootView`'s chrome as well as by the page,
    /// which is the point of it being a stored preference rather than state passed down.
    static let mapKind = "mapKind"
    /// Which feeds the map draws, on the same terms: written by the chrome, read by the page.
    static let mapFilter = "mapFilter"
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

    @AppStorage(SettingsKey.policeCallTypeStyle)
    private var policeCallTypeStyle: PoliceCallTypeStyle = .words

    // The defaults here must be the defaults the police page and the map read, or Settings would
    // display a value the other screens are not using — the store is empty until something writes it.
    @AppStorage(SettingsKey.policeCallWindow)
    private var policeCallWindow: PoliceCallWindow = .oneHour

    @AppStorage(SettingsKey.policeCallKeepsCritical)
    private var policeCallKeepsCritical = true

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
                    Text("Incidents")
                } footer: {
                    Text("The table fits more incidents on a screen. Cards give each one a block of its own. This applies to the fire and police pages alike.")
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
                    Picker("Call Type", selection: $policeCallTypeStyle) {
                        ForEach(PoliceCallTypeStyle.allCases, id: \.self) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    Picker("Recent Calls", selection: $policeCallWindow) {
                        ForEach(PoliceCallWindow.allCases, id: \.self) { window in
                            Text(window.label).tag(window)
                        }
                    }

                    Toggle("Keep Critical Calls", isOn: $policeCallKeepsCritical)
                } header: {
                    Text("Police")
                } footer: {
                    Text("Whether a call's type is shown as the words the Service sends or as the Service's own code. A call's detail view shows both.")

                    Text("Recent Calls is how far back the police page and the map look. A call the app marks as critical is kept even when it falls outside that window. The map can show all four hours from its filter, or by choosing Last 4 hours here.")
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
