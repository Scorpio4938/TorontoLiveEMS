import SwiftUI

/// What the feed's status line says, and whether it is warning.
///
/// Two values that always travel together, which is why they are one type rather than two
/// parameters on every list arrangement.
///
/// It is no longer optional. The line used to be drawn outside the list, above a hairline,
/// where it was visible even with nothing on screen — and where its 16pt inset lined up
/// with neither the list's blocks nor the rows inside them. It is a section header now, so
/// the platform insets it with everything else, and a section header is only drawn when
/// there is a section. Which means there is always a snapshot behind it, and the states
/// that had no snapshot — fetching, and nothing fetched — are said by the views that
/// replace the list instead.
struct FeedStatus: Equatable {

    let text: String
    let isStale: Bool
}

/// One line above the incidents saying how old the data is.
///
/// Deliberately without padding of its own. It is a section header, so the platform insets
/// it exactly as it insets the block below and the rows within it — which is the whole
/// point of moving it in here. It carried its own insets for as long as it lived outside
/// the list, and that is what stopped it aligning with anything.
///
/// The value is the City's own refresh tick, `update_from_db_time`, not the moment we
/// fetched it. "City data as of" says so; "Last updated" left that open to the wrong
/// reading and was changed after it was mistaken for our own fetch time.
struct FeedStatusLine: View {

    let status: FeedStatus

    var body: some View {
        HStack(spacing: 4) {
            if status.isStale {
                Image(systemName: "exclamationmark.triangle")
            }
            Text(status.text)
            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(status.isStale ? Color.orange : Color.secondary)
    }
}
