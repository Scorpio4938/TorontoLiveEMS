import SwiftUI

extension View {

    /// The surface something floating over a map sits on: a callout card, a notice, a header
    /// control.
    ///
    /// **One mechanism, not two.** `.glassEffect` and `.buttonStyle(.glass)` render
    /// differently, and mixing them in one surface is what made an earlier bar look like two
    /// materials stuck together. This is the only one used — here as in the callouts.
    ///
    /// Guarded because `glassEffect` is `@available(visionOS, unavailable)` while the target
    /// declares visionOS, and because the map tab exists on every platform rather than being
    /// iOS-only.
    @ViewBuilder
    func mapSurface(cornerRadius: CGFloat) -> some View {
        #if os(iOS)
        glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        #else
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        #endif
    }
}
