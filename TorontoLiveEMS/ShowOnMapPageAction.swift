import SwiftUI

/// The app-wide action behind **Show on the Map Page**.
///
/// **An environment value with a default no-op**, rather than a type-keyed environment value
/// (`@Environment(SomeType.self)`) that traps when it is missing: a detail view opened in a
/// preview has no tab bar, and a missing action should do nothing rather than crash. The state the
/// action changes still lives at the root, where the tab selection and the map's request belong.
private struct ShowOnMapPageKey: EnvironmentKey {
    static let defaultValue: (MapFocusRequest) -> Void = { _ in }
}

extension EnvironmentValues {
    var showOnMapPage: (MapFocusRequest) -> Void {
        get { self[ShowOnMapPageKey.self] }
        set { self[ShowOnMapPageKey.self] = newValue }
    }
}
