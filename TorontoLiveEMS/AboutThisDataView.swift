import SwiftUI
import TorontoLiveEMSKit

/// Everything the City's own page explains, in one place.
///
/// Reference material rather than a setting: what the fields mean, how an Alarm Level is arrived
/// at, what its vehicle counts actually count, and where the data comes from. It is reached two
/// ways — the info button in the chrome presents it, and *About* pushes it — which is why the list
/// and the way of leaving it are two types rather than one.
///
/// The prose is the City's, quoted rather than paraphrased, and it lives with the thing it
/// describes in the package — `LiveCADFeed.sourceNote`, `AlarmLevel.escalationNote`,
/// `AlarmLevel.countingNote` — so a wording change happens beside the field, not in a view.
/// The levels and the apparatus legend are *rendered from* the same tables the app parses
/// with, so this screen cannot drift from what the rest of the app believes.
struct AboutThisDataContent: View {

    var body: some View {
        List {
            Section {
                Text(LiveCADFeed.sourceNote)
            } header: {
                Text("The Data")
            } footer: {
                LinkedText(markdown: """
                    Taken from the City of Toronto's own \
                    [\(LiveCADFeed.pageName)](\(LiveCADFeed.pageURLString)) page, which is \
                    the page this feed belongs to.
                    """)
            }

            Section {
                Text(AlarmLevel.escalationNote)

                ForEach(AlarmLevel.levels, id: \.published) { level in
                    LabeledContent("Level \(level.published)", value: level.meaning)
                }
            } header: {
                Text("Alarm Level")
            } footer: {
                Text(AlarmLevel.countingNote)
            }

            Section {
                LabeledContent("Area", value: "Nearest fire station")
                LabeledContent("Dispatched Units", value: "Fire trucks dispatched")
            } header: {
                Text("Fields")
            }

            Section {
                ForEach(DispatchedUnit.documentedApparatus, id: \.code) { entry in
                    LabeledContent(entry.code, value: entry.name)
                }
            } header: {
                Text("Dispatched Unit Codes")
            } footer: {
                Text("The City's own legend, in full. A code that is not here is one the City has not named, and it is shown as published rather than guessed at.")
            }

            Section {
                LinkedText(Attribution.attributed)
            }

            Section {
                LinkedText(Attribution.postalAreas)
            } header: {
                Text("Postal Areas")
            } footer: {
                Text("A medical incident's location is published as a postal area rather than an address, to preserve privacy. These are Statistics Canada's boundaries for those areas, so the map shows the area the City named — never a point inside it. A postal area the boundary file does not know is drawn as a circle, which is an approximation and still not a point.")
            }
        }
        .navigationTitle("About this Data")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The same screen, presented rather than pushed.
///
/// The only thing that differs between the two ways in is how a reader gets out: a sheet needs a
/// button of its own, and a pushed screen has the navigation bar's. Keeping that here — rather than
/// in the content — is what lets *About* push the same list without putting a second
/// `NavigationStack` inside the first.
struct AboutThisDataView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AboutThisDataContent()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    AboutThisDataView()
}
