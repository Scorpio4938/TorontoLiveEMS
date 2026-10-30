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
//   HomePage.swift             the index
//   StationCatalogueView.swift the station list
//   StationPage.swift          a station's facts and units
//   UnitCatalogueView.swift    the units list
//   UnitPage.swift             a unit's facts and live section
//   DivisionCatalogueView.swift the divisions list
//   DivisionPage.swift          a division's facts and live calls
//
// **The map page is deliberately not in this list.** It carries no edge treatment at all: its
// tab has no navigation bar, so there is no boundary to treat and no scroll view to treat it.
// That was not obvious — the page once ran its map under the bar and tried every setting of the
// effect against the band that appeared, which was four attempts at an API that configures
// scroll views on a page that had none.
