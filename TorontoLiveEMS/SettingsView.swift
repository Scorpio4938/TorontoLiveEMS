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
    /// How far back the police page looks. Read there and written in Settings.
    static let policeCallWindow = "policeCallWindow"
    /// How far back the map draws police calls — the map's own, deliberately unrelated to the row above.
    static let mapPoliceWindow = "mapPoliceWindow"
    /// Which kind of map the map page draws. Read by `RootView`'s chrome as well as by the page,
    /// which is the point of it being a stored preference rather than state passed down.
    static let mapKind = "mapKind"
    /// Which feeds the map draws, on the same terms: written by the chrome, read by the page.
    static let mapFilter = "mapFilter"
}

/// The app's preferences, and the rows to everything that is not one.
///
/// **Preferences inline; reference material behind a row.** A picker is a value being chosen, and it
/// belongs where it is chosen. A version number, a description of the app and a licence are things
/// to read, and they had collected into sections here — which is how a screen for choosing things
/// came to be a screen for reading them too. So this applies the judgement the project had already
/// made once for *About this Data*: reference material is a screen of its own behind a row, not a
/// section in Settings.
///
/// **Grouped by what a setting affects, not by which feed its name mentions.** Layout and the time
/// format apply to every page, so they sit together under *Display*; the two police preferences sit
/// under *Police*; and what a reader opens rather than chooses sits under *About*. The old grouping
/// put Layout under *Incidents* and gave the time format a section of its own, so three of four
/// sections named a source and the one cross-cutting setting that was misfiled needed a footer to
/// say it applied to fire and police alike. The header says it now, once.
struct SettingsView: View {

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    @AppStorage(SettingsKey.policeCallTypeStyle)
    private var policeCallTypeStyle: PoliceCallTypeStyle = .words

    // Settings is the only writer now, and the page reads the same
    // `PoliceCallWindow.policePageDefault`, so an empty store shows the value the page uses.
    @AppStorage(SettingsKey.policeCallWindow)
    private var policeCallWindow: PoliceCallWindow = PoliceCallWindow.policePageDefault

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
                    Picker("Time Format", selection: $dispatchTimeFormat) {
                        Text("12-Hour").tag(DispatchTimeFormat.twelveHour)
                        Text("24-Hour").tag(DispatchTimeFormat.twentyFourHour)
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text("The table fits more incidents on a screen; cards give each one a block of its own.")
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

                } header: {
                    Text("Police")
                } footer: {
                    Text("A call's detail view shows both.")

                    Text("The map's window is its own, in the map's filter.")
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("About")
                    }

                    NavigationLink {
                        DataLicencesView()
                    } label: {
                        Text("Data Licences")
                    }
                } header: {
                    Text("About")
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
