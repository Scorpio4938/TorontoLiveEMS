import SwiftUI
import TorontoLiveEMSKit

/// Adds a page to the map's presented-detail stack while the page is on screen.
///
/// **Keyed by identity, not by a flag.** Pushing a child page makes the parent disappear; the parent
/// withdraws its own entry and the child has already added its own. The stack is therefore never
/// emptied by whichever page disappeared first, and the parent returns when its child pops.
///
/// The identity is the view's own `@State`, so a page that disappears and comes back — a pop, a tab
/// switch, the app returning — is the same entry rather than a new one. An interactive back-swipe
/// reports its disappearance when the pop completes, so the capsule can briefly still believe the
/// page is on top; that lag is accepted rather than giving the map tab's stack a navigation path.
private struct MapDetailPresentationModifier: ViewModifier {

    let stack: MapDetailStack?
    let source: MapDetailSource?

    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard let stack, let source else { return }
                stack.present(id: id, source: source)
            }
            .onDisappear {
                guard let stack else { return }
                stack.dismiss(id: id)
            }
    }
}

extension View {

    /// Publishes this page to the map's detail stack, when it has a stack and a source.
    ///
    /// Nil on both is the ordinary case for the same detail reached from the Fire or Police tab:
    /// there is no map capsule to change, and nothing to publish.
    func mapDetailPresentation(
        _ stack: MapDetailStack?,
        source: MapDetailSource?
    ) -> some View {
        modifier(MapDetailPresentationModifier(stack: stack, source: source))
    }
}
