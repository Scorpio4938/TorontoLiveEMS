import SwiftUI
import TorontoLiveEMSKit

/// Everything the Service says about these calls, in one place.
///
/// The police counterpart of `AboutThisDataContent`, and reached the same way — the info button in
/// the chrome, on the tab it belongs to. It is a reference screen rather than a setting: what the
/// fields mean, how long a call stays, and what the licence requires of an app that shows them.
///
/// **What is here is what could be checked.** The Service's item and layer both leave `description`
/// empty, so `CallsForServiceFeed.sourceNote` is the whole of what it says about its own data in
/// machine-readable form, and the licence's own clauses — downloaded and read, not remembered — are
/// what the privacy section states. Two claims that appear in ADR-0006 could not be reproduced from
/// the published metadata, and this screen does not repeat them. See the note there.
struct PoliceCallsInformationContent: View {

    /// The codes the app has read, for the list the Fields section opens.
    ///
    /// Passed in rather than taken from a feed: this screen is a reference and knows nothing about
    /// fetching, which is what lets it be pushed from About as well as presented from the chrome.
    let callTypes: [PoliceCallType]

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
                LabeledContent("Call Type", value: "What the call was, in words")

                // The one row on this screen that leads somewhere. The codes themselves are a list
                // rather than a sentence, and a list belongs on its own screen — which is also where
                // the honest sentence about what the list can and cannot be fits.
                NavigationLink {
                    CallTypeCodeList(callTypes: callTypes)
                } label: {
                    LabeledContent("Code", value: "The Service's own code for it")
                }

                LabeledContent("Division", value: "The police division it belongs to")
                LabeledContent("Intersection", value: "The nearest intersection")
                LabeledContent("Latitude", value: "The point, as published")
                LabeledContent("Longitude", value: "The point, as published")
                LabeledContent("Occurrence Time", value: "When the call happened")
            } header: {
                Text("Fields")
            } footer: {
                Text("A code is shown as published. The Service publishes no legend for these codes and this app does not guess at one — what it can do is list the ones it has read, with the Service's own words beside each, which is what the Code row opens.")
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

    let callTypes: [PoliceCallType]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PoliceCallsInformationContent(callTypes: callTypes)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// Every code the Service has used in the calls this app has read, with its name.
///
/// **The screen the Code rows open**, from this reference screen and from a call's own detail view.
///
/// **A record, not a legend, and it says so.** The Service publishes no list to show; what it
/// publishes is a code and the words it stands for, on every call. So this is as complete as the
/// Service's four-hour window was busy. A short list with no explanation would read as the app
/// failing rather than the window's limit — and a long one would read as complete — so the limit is
/// stated above the list instead of being left to be inferred.
struct CallTypeCodeList: View {

    let callTypes: [PoliceCallType]

    var body: some View {
        List {
            Section {
                if callTypes.isEmpty {
                    Text("No calls have been read yet, so no codes have been seen.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(callTypes) { type in
                        LabeledContent(type.code, value: type.names.joined(separator: " · "))
                    }
                }
            } footer: {
                Text("The Service publishes no legend for these codes. These are the codes in the calls this app has read — the Service's last four hours — with its own words beside each, which is why a code that has not come up yet is not here and will be when it does.")
            }
        }
        .navigationTitle("Call Type Codes")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    PoliceCallsInformationView(callTypes: [])
}
