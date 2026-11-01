import SwiftUI
import TorontoLiveEMSKit

/// Everything the Service says about these calls, in one place.
///
/// The police counterpart of `AboutThisDataContent`, and reached the same way — the info button in
/// the chrome, on the tab it belongs to. It is a reference screen rather than a setting: which fields
/// the Service publishes and how long a call stays.
///
/// **What is here is what could be checked.** The Service's item and layer both leave `description`
/// empty, so `CallsForServiceFeed.sourceNote` is the whole of what it says about its own data in
/// machine-readable form. Two claims that appear in ADR-0006 could not be reproduced from the
/// published metadata, and this screen does not repeat them. See the note there.
///
/// **The licences are not here.** They live behind *Data Licences*, which the notice at the bottom
/// opens; this screen is about the calls, not their terms.
struct PoliceCallsInformationContent: View {

    var body: some View {
        List {
            Section {
                Text(CallsForServiceFeed.sourceNote)
            } header: {
                Text("The Calls")
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

            DataLicenceNotice(sentence: Attribution.policeNotice)
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
/// **The mapping, and one sentence saying what it is.** A code and its words, one per line; the
/// screen a reader reaches by tapping a code is there to answer one question.
///
/// Both rows are the Service's own, spelled as published, so a code found here matches the same code
/// on the call it came from. See `PoliceCallType.documented` for where the list came from.
struct CallTypeCodeList: View {

    var body: some View {
        List {
            Section {
                Text("Every call-type code the Service has used on a call, in its own words.")
            }

            Section {
                ForEach(PoliceCallType.documented) { type in
                    LabeledContent(type.code, value: type.name)
                }
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
