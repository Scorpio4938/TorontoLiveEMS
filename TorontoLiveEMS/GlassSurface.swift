import SwiftUI

extension View {

    /// The surface something floating over a map sits on — or sitting in a bar without the
    /// bar's own material behind it: a callout card, a notice, the two screen controls.
    ///
    /// **One mechanism, not two.** `.glassEffect` and `.buttonStyle(.glass)` render
    /// differently, and mixing them in one surface is what made an earlier bar look like two
    /// materials stuck together. This is the only one used — here as in the callouts.
    ///
    /// Guarded because `glassEffect` is `@available(visionOS, unavailable)` while the target
    /// declares visionOS, and because the screens that use it exist on every platform rather
    /// than being iOS-only.
    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat) -> some View {
        #if os(iOS)
        glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        #else
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        #endif
    }
}
