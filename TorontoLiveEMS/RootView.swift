import SwiftUI

/// **A diagnostic. Not a version of the app.**
///
/// The tab bar has never drawn on this machine. Five attempts have tried to explain that, and every
/// one of them changed the *content* of the tabs or the modifiers around them — a bottom bar, an
/// accessory, a minimising style, an alert, a safe-area inset — while the tabs themselves were
/// always the real screens, with a `NavigationStack` and a `List` and a `Map` inside.
///
/// That leaves one thing never tested: **whether a tab bar draws here at all.**
///
/// So this file is two `Text` views and nothing else. No model, no feed, no navigation, no toolbar,
/// no sheet, no modifiers on the tab view. If the bar draws now, the platform is fine and one of
/// those real screens is suppressing it — and the next step is to bisect between here and there.
/// If it still does not draw, nothing in the app is responsible and the answer is the toolchain,
/// the simulator, or the destination.
///
/// Either way it is one bit, and it is the bit everything else has been guessing without.
struct RootView: View {

    /// Kept so that `ContentView` and `AppToolbar` still compile against this. Nothing presents
    /// them in this build.
    enum Sheet: String, Identifiable {
        case settings
        case aboutData

        var id: String { rawValue }
    }

    var body: some View {
        TabView {
            Tab("One", systemImage: "1.circle") {
                Text("First tab")
            }

            Tab("Two", systemImage: "2.circle") {
                Text("Second tab")
            }
        }
    }
}

#Preview {
    RootView()
}
