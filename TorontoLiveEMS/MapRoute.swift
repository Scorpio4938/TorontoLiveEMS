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
