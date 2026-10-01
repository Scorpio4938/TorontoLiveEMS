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
//
// **The map is deliberately not in this list.** It asks for the effect to be hidden instead —
// `scrollEdgeEffectHidden(true, for: .top)` in `IncidentsMapPage` — because the effect blurs
// what is behind it, and behind a map that draws the map's own colours as a gradual band under
// the bar. Over a list it is invisible, because the rows underneath are neutral.
//
// The two mistakes this helper's history records are both about asking it to do something it
// cannot. aadb7c3 added it because only the detail view had asked and the incident list showed
// the platform's hard edge. Then the map was given it, on the assumption that any bar above any
// content wanted the soft style — and that is not what it is for: it chooses among styles, and
// there is no style meaning "none".
