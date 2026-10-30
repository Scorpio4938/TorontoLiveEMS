import SwiftUI
import TorontoLiveEMSKit

/// Everything the Service says about these calls, in one place.
///
/// The police counterpart of `AboutThisDataContent`, and reached the same way — the info button in
/// the chrome, on the tab it belongs to. It is a reference screen rather than a setting: which fields
/// the Service publishes, how long a call stays, and what the licence requires of an app that shows
/// them.
///
/// **What is here is what could be checked.** The Service's item and layer both leave `description`
/// empty, so `CallsForServiceFeed.sourceNote` is the whole of what it says about its own data in
/// machine-readable form, and the licence's own clauses — downloaded and read, not remembered — are
/// what the privacy section states. Two claims that appear in ADR-0006 could not be reproduced from
/// the published metadata, and this screen does not repeat them. See the note there.
struct PoliceCallsInformationContent: View {

    var body: some View {
        List {
            Section {
                Text(CallsForServiceFeed.sourceNote)
            } header: {
                Text("The Calls")
            } footer: {
                LinkedText(markdown: """
                    The Toronto Police Service's own summary of the dataset, quoted. It is read \
                    through the Service's [web app](\(CallsForServiceFeed.pageURLString)), which \
                    is the page a person can open.
                    """)
            }

            Section {
                // **Call Type and Code are one row here, because they are one fact.** The Service
                // publishes a code and the words for it together, on every call, and the list behind
                // this row is where the whole mapping lives. It is also the only row on this screen
                // that leads anywhere, so the two are the same row rather than neighbours.
                NavigationLink {
                    CallTypeCodeList()
                } label: {
                    Text("Call Type & Code")
                }

                Text("Division")
                Text("Intersection")

                // The same judgement as the row above: the Service publishes a point as two numbers,
                // and it is one place. Two rows would list a single published fact twice.
                Text("Latitude & Longitude")

                Text("Occurrence Time")
            } header: {
                Text("Fields")
            }

            Section {
                Text(CallsForServiceFeed.cadenceNote)
            } header: {
                Text("How Long a Call Is Here")
            }

            Section {
                Text("The licence below is written for anyone using this data, and two of its clauses say what this app may not be.")
                Text("It is not to merge or link this data with any other database in an attempt to identify a person. Nothing in this app is correlated with anything else — not the fire incidents, not the map — and no call is combined with anything to work out who it was about.")
                Text("It is not to present the data in a way that suggests access to information the Service holds about an identifiable person. A call here is shown as what happened at a place, and nothing on any screen is shaped like a person.")
                Text("The licence also grants no right to personal information at all, so what the Service withholds is not something this app could show even if it wanted to.")
            } header: {
                Text("Privacy")
            } footer: {
                Text("This app shows what the Service published. What it does not publish is not evidence that nothing happened.")
            }

            Section {
                LinkedText(Attribution.policeCalls)
            }

            SourcesSection()
        }
        .navigationTitle("About Police Calls")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The same screen, presented rather than pushed.
///
/// The pair exists for the reason the fire screen's pair does: a pushed screen takes its way out
/// from the navigation bar and a sheet needs a button of its own. Keeping that here rather than in
/// the content is what would let a second way in push the same list without nesting a second
/// `NavigationStack`.
struct PoliceCallsInformationView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PoliceCallsInformationContent()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// Every code the Service has been observed using, and what it means.
///
/// **The mapping, and nothing else.** A code and its words, one per line, with no explanation over the
/// top — the screen a reader reaches by tapping a code is there to answer one question.
///
/// Both rows are the Service's own, spelled as published, so a code found here matches the same code
/// on the call it came from. See `PoliceCallType.documented` for where the list came from.
struct CallTypeCodeList: View {

    var body: some View {
        List {
            ForEach(PoliceCallType.documented) { type in
                LabeledContent(type.code, value: type.name)
            }
        }
        .navigationTitle("Call Type Codes")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    PoliceCallsInformationView()
}
