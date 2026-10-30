import SwiftUI

/// Every licence the app is obliged to show, with the provider whose data it covers.
///
/// Reference material rather than a preference, so it is a screen behind a row in Settings rather
/// than a section of it. One section per provider because the three are three different licences:
/// the fire feed is the City of Toronto's, the postal-area shapes are Statistics Canada's, and the
/// police calls are the Toronto Police Service's under Ontario's. A licence that named the wrong
/// provider would read as compliance while being false, which is why the sections are separate
/// rather than one list.
///
/// Each section states its attribution and then what that licence says. The data screens carry one
/// sentence and a row to this screen instead of repeating the terms.
struct DataLicencesView: View {

    var body: some View {
        List {
            Section {
                LinkedText(Attribution.fire)
            } header: {
                Text("Fire")
            }

            Section {
                LinkedText(Attribution.postalAreas)

                Text(Self.postalAreaExplanation)
            } header: {
                Text("Postal areas")
            }

            Section {
                LinkedText(Attribution.policeCalls)

                ForEach(Self.policeClauses, id: \.self) { clause in
                    Text(clause)
                }
            } header: {
                Text("Police")
            } footer: {
                Text("This app shows what the Service published. What it does not publish is not evidence that nothing happened.")
            }
        }
        .navigationTitle("Data Licences")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// Why a medical incident's location is an area, and what the shapes are.
    ///
    /// Moved here from *About this Data*, because it is the postal-area licence's explanation rather
    /// than a field's: the shapes are Statistics Canada's, and the reason they are shown as areas is
    /// the reason the licence requires.
    private static let postalAreaExplanation =
        "A medical incident's location is a postal area, not an address, to protect privacy. These are Statistics Canada's boundaries, so the map draws the area the City published — a circle where it knows no boundary, and never a point."

    /// The two clauses that constrain the app, and the grant that excludes personal information.
    ///
    /// Read from the licence's own text rather than remembered. The app's answer to each clause stays
    /// beside it, because a licence requirement a reader cannot see being met is just a paragraph.
    private static let policeClauses = [
        "The licence has two clauses that say what this app may not be.",
        "It is not to merge or link this data with any other database in an attempt to identify a person. Nothing in this app is correlated with anything else — not the fire incidents, not the map — and no call is combined with anything to work out who it was about.",
        "It is not to present the data in a way that suggests access to information the Service holds about an identifiable person. A call here is shown as what happened at a place, and nothing on any screen is shaped like a person.",
        "The licence also grants no right to personal information at all, so what the Service withholds is not something this app could show even if it wanted to.",
    ]
}

/// The one sentence and one button a data screen carries.
///
/// **A notice, not a licence section.** The screen showing somebody's data states who published it
/// and that this app is not them; the terms themselves live on *Data Licences*, which this row
/// opens. A licence paragraph repeated on four screens is four places to keep true.
struct DataLicenceNotice: View {

    let sentence: String

    var body: some View {
        Section {
            Text(sentence)

            NavigationLink {
                DataLicencesView()
            } label: {
                Text("Data Licences")
            }
        }
    }
}

#Preview {
    NavigationStack {
        DataLicencesView()
    }
}
