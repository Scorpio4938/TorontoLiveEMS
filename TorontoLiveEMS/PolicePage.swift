import SwiftUI
import TorontoLiveEMSKit

/// The police incidents, when there are any.
///
/// **A placeholder, and an empty one on purpose.** The City does not publish police incidents the
/// way it publishes fire ones — that is the first thing to establish, and until it is settled a
/// table here would be a table of invented columns. So the screen says the one true thing: there is
/// no source yet, and nothing is being guessed at in the meantime.
///
/// **The table and the cards are not built here.** They are the fire page's, and they are going to
/// be moved somewhere both pages call rather than copied into a second set — which is the work that
/// comes before anything on this screen, because two copies of a five-column grid are two things to
/// keep aligned, and the header alignment was already broken twice by one of them.
///
/// It is a `ContentUnavailableView` rather than a hand-drawn empty state: the platform has a shape
/// for "there is nothing to show", and it already knows how to lay it out.
struct PolicePage: View {

    var body: some View {
        ContentUnavailableView(
            "No Police Incidents Yet",
            image: "shield",
            description: Text(
                "The City does not publish police incidents the way it publishes fire ones. This screen is waiting for a source."
            )
        )
    }
}

#Preview {
    NavigationStack {
        PolicePage()
    }
}
