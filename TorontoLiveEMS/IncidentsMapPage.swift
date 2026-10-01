import SwiftUI

/// The map of active incidents — **not built yet.**
///
/// This is a placeholder, and it is here on purpose. The tab bar is the thing that has failed
/// repeatedly, and a failure with one real screen and one sentence has exactly one cause. A
/// failure with two real screens has several, and the earlier attempts could never say which.
///
/// So the switcher is proven with this in the second tab, and then the map is built into a
/// container already known to work. What replaces this is specified in
/// `docs/design-decisions.md`, *The bar and the map page*.
///
/// `ContentUnavailableView` rather than a bare `Text`, because the switch between the two tabs
/// has to be unmistakable: if it is not obvious which tab you are looking at, "tapping a tab
/// switches" is not something that can be judged from looking at it.
struct IncidentsMapPage: View {

    var body: some View {
        ContentUnavailableView(
            "Map",
            systemImage: "map",
            description: Text("The map of active incidents is not built yet.")
        )
    }
}
