import SwiftUI

/// PROTOTYPE — throwaway. The floating control that switches treatments.
///
/// Pinned to the bottom of the screen so it never scrolls away: the whole point is
/// flipping between treatments while looking at the same incidents.
struct PrototypeSwitcher: View {

    @AppStorage(PrototypeDefaults.tableStyle)
    private var style: PrototypeTableStyle = .current

    var body: some View {
        VStack(spacing: 5) {
            Text("PROTOTYPE — no decision recorded yet")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.secondary)

            Picker("Treatment", selection: $style) {
                ForEach(PrototypeTableStyle.allCases) { candidate in
                    Text(candidate.title).tag(candidate)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}
