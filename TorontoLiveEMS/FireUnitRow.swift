import SwiftUI
import TorontoLiveEMSKit

/// The two facts a unit row shows: its code, and the apparatus the legend names when it names one.
///
/// **One view because two screens list units.** The catalogue and a station's Units section ask the
/// same question of the same type, and a row that read one way in one place and another in the other
/// would be two answers to that question. The code leads because it is what the catalogue is keyed
/// by; the name is secondary because it is the City's reading of that code.
struct FireUnitRow: View {

    let unit: FireUnit

    var body: some View {
        HStack {
            Text(unit.code)
            Spacer()
            if let name = unit.name {
                Text(name)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}
