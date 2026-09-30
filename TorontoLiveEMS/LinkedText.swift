import SwiftUI

/// Text that may contain a link, drawn with its link in blue.
///
/// **Blue because red is the app's accent and links take the accent.** That is correct
/// behaviour — it is what an accent is for, and Apple Music does exactly the same with its red
/// one — but red also means error and destructive, so a licence notice or a reference to the
/// City's page drawn in it reads as a warning rather than as something to tap. Blue is what a
/// link looks like, and this is the one place the accent is overridden. The rest of the app
/// stays fire red.
///
/// One view rather than a modifier at each call site, because three screens now draw text with
/// a link in it and three screens should not be able to disagree about what colour it is.
///
/// `tint` rather than a `foregroundColor` on the parsed link run. Both are plausible; `tint` is
/// documented as *the* colour of a link, and the other depends on an explicit run attribute
/// winning against the tint, which nothing here can check.
struct LinkedText: View {

    let text: AttributedString

    /// Markdown from a string that is not a literal.
    ///
    /// `Text` parses markdown when it is handed a literal, and renders the syntax verbatim when
    /// it is handed a `String` variable — so `[name](url)` would appear as typed. Anything
    /// composed at runtime has to be parsed by hand first, which is what this does.
    init(markdown: String) {
        text = .fromMarkdown(markdown)
    }

    /// Already parsed, for text that was put together elsewhere.
    init(_ text: AttributedString) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .tint(.blue)
    }
}

extension AttributedString {

    /// Markdown parsed out of a string, falling back to the string itself.
    ///
    /// The fallback matters: an unbalanced bracket or a malformed link should show the sentence
    /// as typed rather than show nothing at all.
    static func fromMarkdown(_ source: String) -> AttributedString {
        (try? AttributedString(markdown: source)) ?? AttributedString(source)
    }
}
