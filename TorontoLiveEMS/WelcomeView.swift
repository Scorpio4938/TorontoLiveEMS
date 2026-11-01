import SwiftUI

/// The one greeting a fresh install gets.
///
/// **It is the acknowledgement.** Dismissing it — by Continue or by swiping the sheet away — writes
/// the version this device has seen, which is the same fact the launch rule reads. There is no
/// second first-launch flag and no second preference.
///
/// The name comes from `AppIdentity`, the reader About uses, so the two screens cannot spell the
/// app differently. The three points are the three live sections: Fire, Police and Map.
struct WelcomeView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppIdentity.name)
                            .font(.largeTitle.weight(.semibold))

                        Text("Live fire incidents and police calls in Toronto, as lists and on a map.")
                            .font(.title3)
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        WelcomePoint(
                            symbol: "fire.extinguisher",
                            title: "Fire",
                            detail: "Active incidents, newest first, as a table or as cards."
                        )
                        WelcomePoint(
                            symbol: "shield",
                            title: "Police",
                            detail: "Recent calls for service, newest first, with the window you choose."
                        )
                        WelcomePoint(
                            symbol: "map",
                            title: "Map",
                            detail: "Both feeds on one map. A symbol says what kind, a colour how much it matters."
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
            }

            Button("Continue") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        #if os(iOS)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        #endif
    }
}

/// One live section, said in a line.
private struct WelcomePoint: View {

    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(Color.primary)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    WelcomeView()
}
