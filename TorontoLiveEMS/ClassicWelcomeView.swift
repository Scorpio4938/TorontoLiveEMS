import SwiftUI

/// The earlier welcome design, kept as an Easter egg.
///
/// **Not the automatic first-launch greeting.** That is `WelcomeView`, the full-height page. This is
/// the medium, text-only sheet the app used before that design: the app name, one sentence, the
/// three points and Continue, with no mark and no opaque page background.
///
/// **Kept deliberately, not left behind.** Settings → About → *Classic Welcome* opens it, so it can
/// be compared with the current greeting, played with, and reused if the fuller page ever stops
/// being the right shape. It does not write the launch acknowledgement; opening a curiosity must
/// not make the automatic greeting disappear.
struct ClassicWelcomeView: View {

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
                        ClassicWelcomePoint(
                            symbol: "fire.extinguisher",
                            title: "Fire",
                            detail: "Active incidents, newest first, as a table or as cards."
                        )
                        ClassicWelcomePoint(
                            symbol: "shield",
                            title: "Police",
                            detail: "Recent calls for service, newest first, with the window you choose."
                        )
                        ClassicWelcomePoint(
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
private struct ClassicWelcomePoint: View {

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
    ClassicWelcomeView()
}
