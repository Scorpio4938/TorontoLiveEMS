import SwiftUI

/// One plain, link-shaped row inside a detail's Location section.
///
/// **Blue, like every other link in the app.** Fire red is the accent, and a handoff drawn in it
/// reads as a warning rather than as something to tap.
struct LocationActionRow: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .tint(.blue)
    }
}
