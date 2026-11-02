import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Every police division the City publishes, as a list or as areas.
///
/// **The number in the feed's spelling.** The City's boundary file stores `14`; the feed and this
/// screen write `D14`. Showing one form everywhere is the point, and the feed's is the one a reader
/// sees on a call.
///
/// The list's second line is the published facility address when there is one. Every current
/// division has a published area, so the map draws the City's boundaries rather than a pin per
/// building.
///
/// **The last shape is remembered.** The List/Map choice is a stored preference, separate from
/// the Stations catalogue's, so each returns to the shape it was left in.
struct DivisionCatalogueView: View {

    private static let title = "Divisions"

    let policeFeed: PoliceCallFeed

    private var divisions: [PoliceDivision] { PoliceDivisions.bundled.divisions }

    /// The way back while the map wears no bar. The swipe may work as well; this is the guarantee.
    @Environment(\.dismiss) private var dismiss

    /// The last shape this catalogue was left in, from Settings' own store.
    @AppStorage(SettingsKey.divisionsCatalogueMode) private var mode: CatalogueMode = .list
    @State private var position: MapCameraPosition = .region(IncidentMapScale.city)
    @State private var selected: String?

    /// One scroll target, set only when the map is left for the list and cleared once used.
    ///
    /// Keeping it separate from `selected` means returning from a detail page does not yank the
    /// list back to the area the reader chose earlier; the area stays selected for the map, while
    /// the list keeps the place the reader left it.
    @State private var scrollTarget: String?

    var body: some View {
        Group {
            switch mode {
            case .list:
                list
            case .map:
                map
            }
        }
        .catalogueChrome(title: Self.title, mode: $mode, onBack: { dismiss() })
        .onChange(of: mode) { _, newMode in
            if newMode == .list, let selected = selected {
                scrollTarget = selected
            }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(divisions) { division in
                    NavigationLink {
                        DivisionPage(division: division, policeFeed: policeFeed)
                    } label: {
                        DivisionRow(division: division)
                    }
                    .id(division.number)
                }
            }
            .onAppear {
                // An area chosen on the map is the reader's place; bring the list back to it once.
                if let scrollTarget = scrollTarget {
                    proxy.scrollTo(scrollTarget, anchor: .center)
                    self.scrollTarget = nil
                }
            }
            .onChange(of: scrollTarget) { _, target in
                // The mode change and the list's appearance can arrive in either order; whichever
                // is second performs the scroll, and the target is cleared so it happens once.
                guard let target else { return }
                proxy.scrollTo(target, anchor: .center)
                self.scrollTarget = nil
            }
            .softScrollEdge()
        }
    }

    private var map: some View {
        DivisionCatalogueMap(
            divisions: divisions,
            policeFeed: policeFeed,
            position: $position,
            selected: $selected
        )
    }
}

/// One division in the catalogue.
private struct DivisionRow: View {

    let division: PoliceDivision

    private var facility: PoliceFacility? {
        PoliceFacilities.bundled.facility(forPublished: division.number)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(division.feedCode)
            if let facility = facility {
                Text(facility.address)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DivisionCatalogueView(policeFeed: PreviewCalls.feed())
    }
}
