import SwiftUI

extension View {

    /// The boundary between the bar and the content sliding under it.
    ///
    /// Apple's styles are `hard` — "a linear, nearly opaque boundary" — `soft`, a subtle
    /// blur, and `automatic`, which lets the context decide. The current design uses the
    /// soft one, so ask for it rather than taking whatever a given context happens to pick.
    ///
    /// **One definition, applied wherever there is a scroll view under a bar.** It was on the
    /// detail view and nowhere else, which is why the incident list showed a hard bottom
    /// edge under its header while the detail view had none — the same app behaving two
    /// ways, from an omission rather than a decision.
    ///
    /// It goes on the scroll view itself. On a container above one it may or may not reach
    /// the scroll view inside, and "may" is not worth a build cycle.
    ///
    /// Guarded because the API is iOS-only, and this target also builds for macOS.
    @ViewBuilder
    func softScrollEdge() -> some View {
        #if os(iOS)
        scrollEdgeEffectStyle(.soft, for: .top)
        #else
        self
        #endif
    }
}

// Where it is applied, written down because the list is the point of the helper:
//
//   IncidentLists.swift        both arrangements
//   IncidentDetailView.swift   the detail view
//   IncidentsMapPage.swift     the map
//
// **The map was the omission, and it was the same omission twice.** aadb7c3 fixed this defect
// when only the detail view had it and the incident list showed a hard edge under its bar. The
// map then arrived without it and showed the same hard edge, because a map is not a scroll view
// and it does not occur to anyone to apply a *scroll edge* modifier to one. The rule the helper
// states — everywhere there is a bar above content — is the rule that was being applied by hand,
// one screen at a time, which is why it was missed.
