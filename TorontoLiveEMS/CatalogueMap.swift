import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Which way a catalogue is shown.
enum CatalogueMode: String, CaseIterable, Identifiable {

    case list
    case map

    var id: String { rawValue }

    var label: String {
        switch self {
        case .list: return "List"
        case .map: return "Map"
        }
    }
}


/// The List/Map toggle a catalogue carries.
///
/// A segmented picker rather than a menu: there are exactly two ways to see the same rows, and the
/// choice is one a reader flips back and forth. The labels are words rather than glyphs because a
/// map glyph and a list glyph side by side are a puzzle; "List" and "Map" are not.
struct CatalogueModePicker: View {

    @Binding var mode: CatalogueMode

    var body: some View {
        Picker("View", selection: $mode) {
            ForEach(CatalogueMode.allCases) { option in
                Text(option.label).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}

/// A catalogue's points as pins, with the live map's tap rule and card surface.
///
/// **The same rule as the live map.** Nothing is tagged and the map's own selection is not used:
/// the live map found that a tag raced its own gesture, and that an overlay could not be selected
/// at all. So a tap is turned into a point, the nearest pin within the same 22 points wins, and a
/// tap that lands on nothing puts the card away. The card is drawn inside the map, so it pans and
/// zooms with the thing it belongs to, and it is a `NavigationLink` to the entity's page.
///
/// **Pins, not discs.** The live map draws a thirteen-point dot because a place there can hold
/// several incidents and the mark is about urgency. A catalogue's rows are places with names and
/// addresses, so this uses the platform's own marker — 84 of them should read as pins.
///
/// **No shape is drawn.** The catalogue knows points; it does not know what ground a station or a
/// division covers, and a boundary drawn from nothing would be an invention.
struct CatalogueMap<Item: Identifiable, Destination: View>: View {

    let items: [Item]
    let title: (Item) -> String
    let subtitle: (Item) -> String
    let coordinate: (Item) -> CLLocationCoordinate2D

    /// The camera and the card, held by the catalogue so flipping to the list and back does not
    /// throw away where the reader was looking.
    @Binding var position: MapCameraPosition
    @Binding var selected: Item.ID?

    private let destination: (Item) -> Destination

    @AppStorage(SettingsKey.mapKind) private var mapKind: MapKind = .standard

    init(
        items: [Item],
        title: @escaping (Item) -> String,
        subtitle: @escaping (Item) -> String,
        coordinate: @escaping (Item) -> CLLocationCoordinate2D,
        position: Binding<MapCameraPosition>,
        selected: Binding<Item.ID?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) {
        self.items = items
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        _position = position
        _selected = selected
        self.destination = destination
    }

    private var selectedItem: Item? {
        guard let selected else { return nil }
        return items.first { $0.id == selected }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                ForEach(items) { item in
                    // **An untagged annotation, not a `Marker`.** The live map's finding is that a
                    // selection-capable pin races its own tap gesture; nothing here is tagged, and
                    // the tap is decided by `item(at:in:)`. The glyph is a pin rather than the live
                    // map's dot, because a catalogue row is a place with a name, not an incident.
                    Annotation(title(item), coordinate: coordinate(item)) {
                        Image(systemName: "mappin")
                            .font(.title3)
                            .foregroundStyle(Color.primary)
                            .shadow(radius: 1)
                            .accessibilityLabel(title(item))
                    }
                    .annotationTitles(.hidden)
                }

                if let selectedItem = selectedItem {
                    Annotation("", coordinate: coordinate(selectedItem), anchor: .bottom) {
                        NavigationLink {
                            destination(selectedItem)
                        } label: {
                            ReferenceMapCard(
                                title: title(selectedItem),
                                subtitle: subtitle(selectedItem)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(mapKind.style)
            .onTapGesture(coordinateSpace: .global) { point in
                selected = item(at: point, in: proxy)?.id
            }
        }
    }

    /// The pin a tap landed on, by the same generously-sized hit area the live map uses.
    ///
    /// `.global` on both sides, for the reason the live map gives: the map's safe area can be
    /// padded so its local origin differs from the proxy's, and the window is the one space both
    /// agree on.
    private func item(at point: CGPoint, in proxy: MapProxy) -> Item? {
        for item in items {
            guard let centre = proxy.convert(coordinate(item), to: .global) else { continue }
            if hypot(centre.x - point.x, centre.y - point.y) <= 22 {
                return item
            }
        }
        return nil
    }
}

/// The card a catalogue pin opens.
///
/// The same glass surface and the same padding as a live-map card; what differs is that a
/// catalogue row is one entity rather than a group, so this is a title and one optional line and
/// nothing else.
struct ReferenceMapCard: View {

    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .padding(8)
        .frame(maxWidth: 240, alignment: .leading)
        .glassSurface(cornerRadius: 12)
    }
}
