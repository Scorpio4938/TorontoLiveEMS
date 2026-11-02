import SwiftUI
import TorontoLiveEMSKit

/// The app's preferences, and where each one is stored.
///
/// `@AppStorage` is the platform's own lightweight preference store, and
/// `DispatchTimeFormat` is `RawRepresentable` over `String`, which is what it wants.
/// There is no settings model and no synchronisation: a preference is a key and a default.
enum SettingsKey {
    /// The version this device last acknowledged.
    ///
    /// **A version string, not a boolean.** Empty means this app has never been launched, and that
    /// is the one fact both the launch rule and the welcome greeting read (#33); the greeting writes
    /// the current version when it is dismissed. Anything else is a version this device has seen,
    /// which a later "what's new" notice can compare against without a migration.
    static let acknowledgedVersion = "acknowledgedVersion"

    /// The last section the reader used, including Home.
    ///
    /// **A launch restores this value.** It is written on every tab change, and seeded with the
    /// section a launch opened on, so the first launch also leaves Home behind as the fact to
    /// restore. It does not answer whether the app has launched before; `acknowledgedVersion` does.
    static let lastSection = "lastSection"

    static let dispatchTimeFormat = "dispatchTimeFormat"
    static let presentation = "incidentPresentation"
    /// Whether the app is light, dark, or whatever the device is set to.
    ///
    /// Read by `RootView`, which applies it once above every tab and sheet, and written here, where
    /// the three choices are offered. System is the default, so an install that never opens Settings
    /// looks exactly as it did before this key existed.
    static let appearance = "appearance"
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

    /// Whether the Stations catalogue was last left as a list or a map.
    ///
    /// The two catalogues keep their own choice: changing Stations to a map must not change
    /// Divisions, which has a different list and a different map.
    static let stationsCatalogueMode = "stationsCatalogueMode"

    /// Whether the Divisions catalogue was last left as a list or a map.
    static let divisionsCatalogueMode = "divisionsCatalogueMode"

    /// Whether Home appears as a tab on iPhone and iPad.
    ///
    /// Hiding it leaves the tab bar's width to Fire, Police and Map. The leading house control
    /// is the way back while the tab is hidden; `showsHomeButton` decides whether that control
    /// is drawn as well.
    static let showsHomeTab = "showsHomeTab"

    /// Whether the leading house control is drawn while the Home tab is hidden.
    ///
    /// It has no effect while Home is a tab, because the tab is the way there and the leading
    /// control is not drawn. With both this and `showsHomeTab` off, Home has no control in the
    /// app; that is a deliberate choice the reader can make.
    static let showsHomeButton = "showsHomeButton"
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
/// **Grouped by what a setting affects, not by which feed its name mentions.** Layout, the time
/// format and appearance apply to every page, so they sit together under *Display*; the two police
/// preferences sit under *Police*; and what a reader opens rather than chooses sits under *About*.
/// The old grouping put Layout under *Incidents* and gave the time format a section of its own, so
/// three of four sections named a source and the one cross-cutting setting that was misfiled needed
/// a footer to say it applied to fire and police alike. The header says it now, once.
struct SettingsView: View {

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @AppStorage(SettingsKey.presentation)
    private var presentation: IncidentPresentation = .standard

    @AppStorage(SettingsKey.appearance)
    private var appearance: Appearance = .standard

    @AppStorage(SettingsKey.policeCallTypeStyle)
    private var policeCallTypeStyle: PoliceCallTypeStyle = .words

    // Settings is the only writer now, and the page reads the same
    // `PoliceCallWindow.policePageDefault`, so an empty store shows the value the page uses.
    @AppStorage(SettingsKey.policeCallWindow)
    private var policeCallWindow: PoliceCallWindow = PoliceCallWindow.policePageDefault

    #if os(iOS)
    @AppStorage(SettingsKey.showsHomeTab)
    private var showsHomeTab = true

    @AppStorage(SettingsKey.showsHomeButton)
    private var showsHomeButton = true
    #endif

    @Environment(\.dismiss) private var dismiss

    /// Ask RootView to show the welcome greeting after Settings closes.
    ///
    /// Nil in a preview. The real Settings sheet is always given this closure, so the row is a
    /// manual way to see the same greeting without a second copy of its content.
    var onShowWelcome: (() -> Void)? = nil

    /// Ask RootView to show the Easter Egg: the earlier, medium text-only greeting.
    ///
    /// That design is kept rather than replaced: it can be compared with the current welcome,
    /// played with, and reused later. It does not write the launch fact.
    var onShowEasterEgg: (() -> Void)? = nil

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
                    // The names come from the type, like Layout's, so the words a test pins are the
                    // words a reader sees. System is a value rather than the absence of a choice:
                    // that is what lets a reader return to following the device after choosing.
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
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

                #if os(iOS)
                Section {
                    Toggle("Show Home Tab", isOn: $showsHomeTab)

                    if !showsHomeTab {
                        Toggle("Show Home Button", isOn: $showsHomeButton)
                    }
                } header: {
                    Text("Home")
                } footer: {
                    Text("Home is the directory of stations, units and divisions. Turning its tab off gives Fire, Police and Map more room.")

                    if !showsHomeTab {
                        Text("The house control at the top opens Home while its tab is hidden. Turn it off too if you want no Home control at all.")
                    }
                }
                #endif

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

                    Button {
                        onShowWelcome?()
                        dismiss()
                    } label: {
                        Label("Show Welcome", systemImage: "hand.wave")
                    }

                    Button {
                        onShowEasterEgg?()
                        dismiss()
                    } label: {
                        Label("Easter Egg", systemImage: "sparkles")
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
