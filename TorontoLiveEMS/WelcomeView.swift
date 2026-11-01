import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The one greeting a fresh install gets.
///
/// **A full-height page, not a small card.** It uses the sheet's large detent and an opaque page
/// background, so it reads like the welcome screens Apple ships: a mark, a title, a short list of
/// what the app does, and one Continue button at the bottom.
///
/// **It is the acknowledgement.** Dismissing it — by Continue or by swiping the sheet away — writes
/// the version this device has seen, which is the same fact the launch rule reads. There is no
/// second first-launch flag and no second preference.
///
/// The name comes from `AppIdentity`, the reader About uses, so the two screens cannot spell the
/// app differently. The three points are the three live sections: Fire, Police and Map.
struct WelcomeView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(colorScheme == .dark ? "IconAppearanceDark" : "IconAppearanceLight")
                            .resizable()
                            .frame(width: 96, height: 96)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 96 * 0.2237,
                                    style: .continuous
                                )
                            )
                            .accessibilityHidden(true)

                        Text("Welcome to \(AppIdentity.name)")
                            .font(.largeTitle.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("Live fire incidents and police calls in Toronto, as lists and on a map.")
                            .font(.title3)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 24) {
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
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.top, 56)
                .padding(.bottom, 28)
            }

            Button("Continue") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(pageBackground)
        #if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(pageBackground)
        #endif
    }

    private var pageBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.black
        #endif
    }
}

/// One live section, said in a line.
private struct WelcomePoint: View {

    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(Color.primary)

            VStack(alignment: .leading, spacing: 4) {
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
