import SwiftUI
import TorontoLiveEMSKit

/// PROTOTYPE — throwaway. All four treatments in the canvas at once.
///
/// Faster than building and flipping the switcher: open the canvas and the four sit side
/// by side over the same three incidents under the same conditions, which is what makes
/// comparing them honest. The switcher is still there for looking at them against the
/// live feed, which a preview cannot do.
///
/// These render the treatment rows directly rather than through `IncidentRow`, because
/// that dispatches on a stored preference and a preview cannot set one.
private struct PrototypeTreatmentPreview: View {

    let style: PrototypeTableStyle

    var body: some View {
        List {
            Section {
                ForEach(PreviewIncidents.all) { incident in
                    row(for: incident)
                }
            } header: {
                if style.showsColumnHeader {
                    CompactColumnHeader()
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func row(for incident: Incident) -> some View {
        switch style {
        case .current:
            PrototypeCurrentRow(incident: incident, timeFormat: .twelveHour)
        case .hierarchy:
            PrototypeHierarchyRow(incident: incident, timeFormat: .twelveHour)
        case .instrument:
            PrototypeInstrumentRow(incident: incident, timeFormat: .twelveHour)
        case .cards:
            PrototypeCardsRow(incident: incident, timeFormat: .twelveHour)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
        }
    }
}

#Preview("1 Current") {
    PrototypeTreatmentPreview(style: .current)
}

#Preview("2 Hierarchy") {
    PrototypeTreatmentPreview(style: .hierarchy)
}

#Preview("3 Instrument") {
    PrototypeTreatmentPreview(style: .instrument)
}

#Preview("4 Cards") {
    PrototypeTreatmentPreview(style: .cards)
}

/// The same four in dark, because a treatment that only works in one appearance is not
/// a treatment.
#Preview("Dark — Current") {
    PrototypeTreatmentPreview(style: .current).preferredColorScheme(.dark)
}

#Preview("Dark — Hierarchy") {
    PrototypeTreatmentPreview(style: .hierarchy).preferredColorScheme(.dark)
}

#Preview("Dark — Instrument") {
    PrototypeTreatmentPreview(style: .instrument).preferredColorScheme(.dark)
}

#Preview("Dark — Cards") {
    PrototypeTreatmentPreview(style: .cards).preferredColorScheme(.dark)
}
