import SwiftUI

/// Every licence the app is obliged to show, with the provider whose data it covers.
///
/// Reference material rather than a preference, so it is a screen behind a row in Settings rather
/// than a section of it. One section per provider because the three are three different licences:
/// the fire feed is the City of Toronto's, the postal-area shapes are Statistics Canada's, and the
/// police calls are the Government of Ontario's. A licence that named the wrong provider would read
/// as compliance while being false, which is why the sections are separate rather than one list.
///
/// The sentences themselves live in `Attribution`, so this screen cannot name a provider differently
/// from the screens that show that provider's data.
struct DataLicencesView: View {

    var body: some View {
        List {
            Section {
                LinkedText(Attribution.attributed)
            } header: {
                Text("Fire")
            }

            Section {
                LinkedText(Attribution.postalAreas)
            } header: {
                Text("Postal areas")
            }

            Section {
                LinkedText(Attribution.policeCalls)
            } header: {
                Text("Police")
            }
        }
        .navigationTitle("Data Licences")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        DataLicencesView()
    }
}
