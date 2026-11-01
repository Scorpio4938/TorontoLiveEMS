import Foundation
import Observation

/// Which feed a detail pushed from the map belongs to.
public enum MapDetailSource: Hashable, Sendable {
    case fire
    case police
}

/// One page presented above the map, and the feed it explains.
public struct MapDetailPresentation: Identifiable, Equatable, Sendable {

    public let id: UUID
    public let source: MapDetailSource

    public init(id: UUID, source: MapDetailSource) {
        self.id = id
        self.source = source
    }
}

/// The pages currently presented above the map, newest last.
///
/// **A stack, not a flag.** A detail can push another page — the licences screen, for one — and the
/// parent disappears while the child is on screen. A boolean would be cleared by whichever page
/// disappeared first while its parent was still in the stack. Each page instead adds itself under
/// its own identity on appear and removes that identity on disappear; the top is what the capsule
/// and the Info button read.
@Observable
public final class MapDetailStack {

    public private(set) var presentations: [MapDetailPresentation] = []

    public init() {}

    /// What the reader is looking at, or nil when the map itself is on top.
    public var top: MapDetailSource? {
        presentations.last?.source
    }

    public var isEmpty: Bool {
        presentations.isEmpty
    }

    /// Adds a page, or moves an existing identity back to the top.
    public func present(id: UUID, source: MapDetailSource) {
        presentations.removeAll { $0.id == id }
        presentations.append(MapDetailPresentation(id: id, source: source))
    }

    /// Removes exactly the page that disappeared, leaving its parent alone.
    public func dismiss(id: UUID) {
        presentations.removeAll { $0.id == id }
    }
}
