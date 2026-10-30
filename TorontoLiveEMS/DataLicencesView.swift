import SwiftUI
import TorontoLiveEMSKit

/// The index of the app's data licences.
///
/// Reference material rather than a preference, so it is a screen behind a row in Settings rather
/// than a section of it. Each kind of data has a page of its own behind this one: the fire feed is
/// the City of Toronto's, the postal-area shapes are Statistics Canada's, and the police calls are
/// the Toronto Police Service's under Ontario's. Keeping them apart is deliberate — a licence that
/// named the wrong provider would read as compliance while being false.
///
/// A data screen carries one sentence and a row to this index. The provider, the data source, the
/// attribution and the licence text are on the page for that data.
struct DataLicencesView: View {

    var body: some View {
        List {
            Section {
                NavigationLink {
                    FireDataLicenceView()
                } label: {
                    LabeledContent("Fire data", value: "City of Toronto")
                }

                NavigationLink {
                    PostalAreaLicenceView()
                } label: {
                    LabeledContent("Postal areas", value: "Statistics Canada")
                }

                NavigationLink {
                    PoliceDataLicenceView()
                } label: {
                    LabeledContent("Police data", value: CallsForServiceFeed.provider)
                }
            } footer: {
                Text("Each page names the publisher, links the data source, states the attribution and includes a copy of the licence.")
            }
        }
        .navigationTitle("Data Licences")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The City of Toronto's licence for the fire feed.
///
/// **More than a link, and more than one line.** The City's page carries no separate licence
/// notice, so this page says what the app treats as the licence, reproduces the attribution the
/// licence asks for, and offers the full text without leaving the app.
struct FireDataLicenceView: View {

    private let licence = DataLicence.toronto

    var body: some View {
        List {
            LicenceMetadataSection(licence: licence)

            Section {
                Text(Self.coverage)
                Text("Required attribution: \(licence.attributionStatement)")

                if let url = LiveCADFeed.pageURL {
                    Link(LiveCADFeed.pageName, destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("The data")
            }

            LicenceFullTextSection(licence: licence)
        }
        .navigationTitle("Fire Data Licence")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// What the fire feed is, and how the app treats its licence.
    ///
    /// **The City has not said the open licence covers this feed.** `livecad.xml` is not on the
    /// Open Data portal and its page carries no licence notice. The app credits the City and uses
    /// the City's Open Government Licence – Toronto as the licence for the information; the
    /// sentence says that rather than claiming a formal grant the City never published.
    private static let coverage =
        "The incidents in this app are Toronto Fire Services', published by the City of Toronto on its \(LiveCADFeed.pageName) page. That page carries no separate licence notice, and the City has not said that its open licence covers this feed. This app credits the City and uses the City's Open Government Licence – Toronto as the licence for the information."
}

/// Statistics Canada's licence for the postal-area shapes.
struct PostalAreaLicenceView: View {

    private let licence = DataLicence.canada

    var body: some View {
        List {
            LicenceMetadataSection(licence: licence)

            Section {
                LinkedText(Attribution.postalAreas)

                Text(Self.postalAreaExplanation)

                if let url = PostalAreas.sourceURL {
                    Link(PostalAreas.sourceName, destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("The data")
            }

            LicenceFullTextSection(licence: licence)
        }
        .navigationTitle("Postal Areas Licence")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// Why a medical incident's location is an area, and what the shapes are.
    ///
    /// The shapes are Statistics Canada's, and the reason they are shown as areas is the reason the
    /// licence requires.
    private static let postalAreaExplanation =
        "A medical incident's location is a postal area, not an address, to protect privacy. These are Statistics Canada's boundaries, so the map draws the area the City published — a circle where it knows no boundary, and never a point."
}

/// The Toronto Police Service's calls, under the Government of Ontario's licence.
///
/// **Short on purpose.** The previous page carried four long paragraphs explaining the two clauses
/// and the app's answer to each. The licence itself is the authority, so this page states the
/// attribution, links the data and puts the full text one row below.
struct PoliceDataLicenceView: View {

    private let licence = DataLicence.ontario

    var body: some View {
        List {
            LicenceMetadataSection(licence: licence)

            Section {
                LinkedText(Attribution.policeCalls)

                if let url = CallsForServiceFeed.pageURL {
                    Link(CallsForServiceFeed.pageName, destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("The data")
            }

            Section {
                Text("This app shows what the Service published. What it does not publish is not evidence that nothing happened.")
            }

            LicenceFullTextSection(licence: licence)
        }
        .navigationTitle("Police Data Licence")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// A licence's title, version, provider and last-updated date.
private struct LicenceMetadataSection: View {

    let licence: DataLicence

    var body: some View {
        Section {
            LabeledContent("Licence", value: licence.title)
            LabeledContent("Version", value: licence.version)
            LabeledContent("Licence provider", value: licence.provider)
            LabeledContent("Updated", value: licence.updated)
        } header: {
            Text("The licence")
        }
    }
}

/// The row to the complete reproduced text, and the publisher's authoritative copy.
private struct LicenceFullTextSection: View {

    let licence: DataLicence

    var body: some View {
        Section {
            NavigationLink {
                LicenceTextView(licence: licence)
            } label: {
                Text("The licence in full")
            }
        } footer: {
            LinkedText(markdown: "Reproduced from the publisher's [official licence page](\(licence.urlString)). That page is the authoritative copy.")
        }
    }
}

/// The complete licence text, as the publisher presents it: one text block, not a set of sections.
private struct LicenceTextView: View {

    let licence: DataLicence

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(licence.fullText)
                    .textSelection(.enabled)

                LinkedText(markdown: "Reproduced from the [official licence page](\(licence.urlString)). That page is the authoritative copy.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(licence.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The one sentence and one button a data screen carries.
///
/// **A notice, not a licence section.** The screen showing somebody's data states who published it
/// and that this app is not them; the terms themselves live behind *Data Licences*, which this row
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
