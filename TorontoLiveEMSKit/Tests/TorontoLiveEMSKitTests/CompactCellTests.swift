import Testing
import TorontoLiveEMSKit

/// The cell type itself: what a value is, and what a mark is allowed to sit on.
///
/// Separate from `CompactColumnTests`, which is about which field a column draws from. This
/// is about the shape of a cell once it has been built.
@Suite("Compact table cells")
struct CompactCellTests {

    @Test("a blank value is not a value")
    func blankBecomesNothing() {
        // The feed publishes a space for fields it will not fill in, and the parser turns
        // those into nil. This is the second line of defence rather than the first, and it is
        // here because the first one is in another module and a caller should not have to
        // know that an empty string and nil mean the same thing.
        #expect(CompactCell("").text == nil)
        #expect(CompactCell(" ").text == nil)
        #expect(CompactCell("\n").text == nil)
        #expect(CompactCell(nil).text == nil)
    }

    @Test("keeps a value that is merely surrounded by space")
    func keepsWhatWasPublished() {
        // Trimmed to decide whether there is anything there, never to change what there is.
        // The app shows what the City published.
        #expect(CompactCell(" M6K ").text == " M6K ")
    }

    @Test("cannot be a mark with nothing to mark")
    func aMarkAlwaysSitsOnAValue() {
        // The reported fault: the intersection mark drawn over an empty address, so the cell
        // showed the sign and the emptiness at once. That reads as an error rather than as
        // information, and the state is unconstructable now rather than merely avoided at the
        // one call site that could have asked for it.
        #expect(!CompactCell(nil, isFallback: true).isFallback)
        #expect(!CompactCell("", isFallback: true).isFallback)
        #expect(!CompactCell("   ", isFallback: true).isFallback)
    }

    @Test("carries a mark when there is something to mark")
    func aMarkSurvivesItsValue() {
        let cell = CompactCell("ARDAGH ST / JANE ST", isFallback: true)
        #expect(cell.text == "ARDAGH ST / JANE ST")
        #expect(cell.isFallback)
    }

    @Test("keeps attention and substitution independent")
    func theTwoFlagsAreIndependent() {
        let dangerous = CompactCell("Fire - Residential", warrantsAttention: true)
        #expect(dangerous.warrantsAttention)
        #expect(!dangerous.isFallback)

        let substituted = CompactCell("ARDAGH ST / JANE ST", isFallback: true)
        #expect(!substituted.warrantsAttention)
        #expect(substituted.isFallback)
    }
}
