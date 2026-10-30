import SwiftUI

/// The six sources and the licence each is under, as a list section.
///
/// **One view because both information screens show it.** The fire screen and the police screen
/// explain different data, but the credit is the same set of six sources, and two copies would be
/// two places to forget one. The two live feeds, the three City reference datasets and the
/// community apparatus roster are different publishers under three different licences; each row
/// names its own rather than repeating a single licence that would be wrong for several of them.
struct SourcesSection: View {

    var body: some View {
        Section {
            ForEach(Attribution.sources) { source in
                VStack(alignment: .leading, spacing: 2) {
                    Link(source.name, destination: source.url)
                        .tint(.blue)
                    Text(source.licence)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        } header: {
            Text("Sources")
        } footer: {
            Text("Not affiliated with the City of Toronto. Each source is named with the licence it is published under; the two live feeds, the three City reference datasets and the community apparatus roster are different publishers under three different licences.")
        }
    }
}
