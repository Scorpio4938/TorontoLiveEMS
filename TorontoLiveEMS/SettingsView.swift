import SwiftUI
import TorontoLiveEMSKit

/// The app's preferences, and where each one is stored.
///
/// `@AppStorage` is the platform's own lightweight preference store, and
/// `DispatchTimeFormat` is `RawRepresentable` over `String`, which is what it wants.
/// There is no settings model and no synchronisation, because there is one preference.
enum SettingsKey {
    static let dispatchTimeFormat = "dispatchTimeFormat"
}

struct SettingsView: View {

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Format", selection: $dispatchTimeFormat) {
                        Text("12-Hour").tag(DispatchTimeFormat.twelveHour)
                        Text("24-Hour").tag(DispatchTimeFormat.twentyFourHour)
                    }
                } header: {
                    Text("Dispatch Time")
                } footer: {
                    Text("How the time of day is shown in the table.")
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
