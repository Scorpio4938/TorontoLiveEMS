import SwiftUI

/// The row that carries a detail onto the app's own map.
///
/// The label names the page and nothing else, so it cannot be mistaken for the row that leaves the
/// app for Apple Maps.
struct ShowOnMapPageRow: View {

    let action: () -> Void

    var body: some View {
        LocationActionRow(title: "Show on the Map Page", action: action)
    }
}
