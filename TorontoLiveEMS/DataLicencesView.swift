import SwiftUI
import TorontoLiveEMSKit

/// The index of the app's data licences.
///
/// Reference material rather than a preference, so it is a screen behind a row in Settings rather
/// than a section of it. Each kind of data has a page of its own behind this one: the fire feed is
/// the City of Toronto's, the postal-area shapes are Statistics Canada's, and the police calls are
/// the Toronto Police Service's under Ontario's. The reference datasets, the community apparatus
/// roster and the Wikipedia/Commons material have their own pages for the same reason — each is a
/// different source with a different licence. Keeping them apart is deliberate: a licence that
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

                NavigationLink {
                    ReferenceDataLicenceView()
                } label: {
                    LabeledContent("Reference data", value: "City of Toronto")
                }

                NavigationLink {
                    ApparatusRosterLicenceView()
                } label: {
                    LabeledContent("Apparatus roster", value: "Firefighting Wiki")
                }

                NavigationLink {
                    WikipediaLicenceView()
                } label: {
                    LabeledContent("Wikipedia and Commons", value: "CC BY-SA / per file")
                }
            } footer: {
                Text("Each page names the source, links it and states the attribution; the open-government pages also include a copy of the licence.")
            }

            Section {
                NavigationLink {
                    AppIconLicenceView()
                } label: {
                    LabeledContent("App icon", value: Attribution.iconProvider)
                }
            } header: {
                Text("Artwork")
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

/// The City of Toronto's licence for the three reference datasets.
///
/// The fire station, police division and police facility files share the City's open licence. The
/// page states the attribution once and links each dataset, rather than making three pages that
/// would repeat the same terms.
struct ReferenceDataLicenceView: View {

    private let licence = DataLicence.toronto

    var body: some View {
        List {
            LicenceMetadataSection(licence: licence)

            Section {
                Text("Fire station locations, police divisions and police facility locations are published by the City of Toronto and ship as the app's reference data.")
                Text("Required attribution: \(licence.attributionStatement)")

                if let url = URL(string: "https://open.toronto.ca/dataset/fire-station-locations/") {
                    Link("Fire Station Locations", destination: url)
                        .tint(.blue)
                }
                if let url = URL(string: "https://open.toronto.ca/dataset/police-boundaries/") {
                    Link("Police Boundaries", destination: url)
                        .tint(.blue)
                }
                if let url = URL(string: "https://open.toronto.ca/dataset/police-facility-locations/") {
                    Link("Police Facility Locations", destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("The data")
            }

            LicenceFullTextSection(licence: licence)
        }
        .navigationTitle("Reference Data Licence")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The Firefighting Wiki roster's CC BY-SA 3.0 terms.
struct ApparatusRosterLicenceView: View {

    var body: some View {
        List {
            Section {
                LabeledContent("Licence", value: "CC BY-SA 3.0")
                LabeledContent("Source", value: "Firefighting Wiki (Fandom)")
                LabeledContent("Retrieved", value: FireUnits.bundled.retrieved)
            } header: {
                Text("The licence")
            }

            Section {
                Text("The apparatus codes, names and station assignments come from the community-maintained \(FireUnits.bundled.source) page.")
                Text("Attribution: Firefighting Wiki (Fandom), “Toronto Fire Services”, retrieved \(FireUnits.bundled.retrieved).")

                if let url = URL(string: FireUnits.bundled.source) {
                    Link("Toronto Fire Services on the Firefighting Wiki", destination: url)
                        .tint(.blue)
                }
                if let url = URL(string: "https://creativecommons.org/licenses/by-sa/3.0/") {
                    Link("CC BY-SA 3.0", destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("The data")
            }
        }
        .navigationTitle("Apparatus Roster Licence")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// Wikipedia and Wikimedia Commons, whose text and images have separate terms.
struct WikipediaLicenceView: View {

    var body: some View {
        List {
            Section {
                LabeledContent("Text licence", value: "CC BY-SA 4.0")
                LabeledContent("Images", value: "Each file's own licence")
                LabeledContent("Retrieved", value: WikipediaReference.bundled.retrieved)
            } header: {
                Text("The licences")
            }

            Section {
                Text("Station histories are short paraphrases of Wikipedia's List of historic Toronto fire stations. Unit photographs come from Wikimedia Commons, and each one names its author and licence on the unit page.")
                Text("Every entry used by the app links to its source, and the station entries record the Wikipedia revision they were drawn from.")

                if let url = URL(string: WikipediaReference.bundled.source) {
                    Link("List of historic Toronto fire stations", destination: url)
                        .tint(.blue)
                }
                if let url = URL(string: "https://commons.wikimedia.org/") {
                    Link("Wikimedia Commons", destination: url)
                        .tint(.blue)
                }
                if let url = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/") {
                    Link("CC BY-SA 4.0", destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("The data")
            }
        }
        .navigationTitle("Wikipedia Licence")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The artwork the app's icon is composed from.
///
/// The icon is not data, but it is a third party's work and belongs where every other credit is
/// kept. SVG Repo's default licence does not require attribution; the app gives it anyway, and names
/// the collection as well as the file so a reader can find the source.
struct AppIconLicenceView: View {

    private static let licenceURLString = "https://www.svgrepo.com/page/licensing/"

    var body: some View {
        List {
            Section {
                LabeledContent("Icon", value: Attribution.iconTitle)
                LabeledContent("Collection", value: Attribution.iconCollection)
                LabeledContent("Source", value: Attribution.iconProvider)
                LabeledContent("Licence", value: Attribution.iconLicence)
            } header: {
                Text("The artwork")
            } footer: {
                Text("The app icon is composed from this icon in Icon Composer: recoloured, given its background and appearances, and built by Xcode as the app icon.")
            }

            Section {
                Text("The icon comes from the Dazzle Line Icons collection on SVG Repo. SVG Repo's default licence permits use and adaptation without attribution; the app credits the source anyway.")

                if let url = Attribution.iconSourceURL {
                    Link("Light Emergency on SVG Repo", destination: url)
                        .tint(.blue)
                }
                if let url = URL(string: Self.licenceURLString) {
                    Link("SVG Repo licensing", destination: url)
                        .tint(.blue)
                }
            } header: {
                Text("Source")
            }
        }
        .navigationTitle("App Icon Licence")
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

/// The one sentence a data screen carries, and the way to the licence pages.
///
/// **One block, not a sentence beside a separate link.** The screen showing somebody's data states
/// who published it and that this app is not them; the whole sentence is the row that opens
/// *Data Licences*. A licence paragraph repeated on four screens is four places to keep true, and a
/// second row repeating the destination made this notice heavier than it needed to be.
struct DataLicenceNotice: View {

    let sentence: String

    var body: some View {
        Section {
            NavigationLink {
                DataLicencesView()
            } label: {
                Text(sentence)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityHint("Opens Data Licences")
        }
    }
}

#Preview {
    NavigationStack {
        DataLicencesView()
    }
}
