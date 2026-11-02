import Foundation
import TorontoLiveEMSKit

/// Which feed a presented map detail explains.
enum MapDetailSource: Hashable {
    case fire
    case police
}

/// One detail presented above the map.
///
/// **A value in a navigation path, not an appearance callback.** The map tab owns a
/// `NavigationStack(path:)`; pushing a detail appends its route immediately, and popping it removes
/// the route. The capsule can therefore read the path rather than waiting for a view to disappear,
/// which is what made the old stack expand half a second late.
enum MapRoute: Hashable {
    case fire(Incident)
    case police(PoliceCall)

    var source: MapDetailSource {
        switch self {
        case .fire: return .fire
        case .police: return .police
        }
    }
}

/// A request to show one record on the map page.
///
/// **The id is the point.** The same incident or call can be asked for twice, and a value that
/// compares equal to the last request would not change anything. A fresh id makes every tap a new
/// request while the map keeps the route it is showing.
struct MapFocusRequest: Equatable {
    let id: UUID
    let route: MapRoute

    /// The point the detail already resolved, when it has one.
    ///
    /// A fire incident's place is often a street the detail has just geocoded. Carrying that point
    /// lets the map draw and frame the target immediately instead of waiting for its own geocode.
    let resolvedPoint: Coordinate?

    init(route: MapRoute, resolvedPoint: Coordinate? = nil) {
        self.id = UUID()
        self.route = route
        self.resolvedPoint = resolvedPoint
    }
}
