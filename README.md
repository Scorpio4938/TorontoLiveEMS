# TorontoLiveEMS

A native SwiftUI app showing Toronto Fire Services' **currently active incidents** — the
same information as the City's own [Toronto Fire Active
Incidents](https://www.toronto.ca/community-people/public-safety-alerts/alerts-notifications/toronto-fire-active-incidents/)
page, with the City's own live feed behind it.

Built for iPhone first. iPad, Mac and visionOS are in the target's supported platforms but
have never been designed for or built.

## The data

`https://www.toronto.ca/data/fire/livecad.xml`

An XML snapshot of active incidents, refreshed **every five minutes**. It is *not* a
published API: it is not on the City's Open Data portal, its page carries no licence
notice, and it was found by reading that page's inline JavaScript. It publishes eight
fields and the app keeps all eight unreduced, showing some and carrying the rest to the
detail view.

`docs/adr/0001` records why this source and nothing else, and `docs/adr/0002` why nothing
is thrown away. The City aggregates medical incident locations to postal areas under
MFIPPA — `docs/adr/0004` records that the app must never try to narrow them.

## Layout

```
TorontoLiveEMS/         the app — the views, and the table's measurements
TorontoLiveEMSKit/      the data logic, as a local Swift package, and all 68 tests
scripts/check_swift.py  a structural check, see below
docs/                   the decisions
```

**Why the package is a sibling and not inside `TorontoLiveEMS/`.** That folder is a
`PBXFileSystemSynchronizedRootGroup`: every `.swift` file under it joins the app target
automatically, with no `pbxproj` edit. Nesting the package there would compile its sources
into the app target *and* into the module, which does not work. The package is linked into
the app target by a local package reference.

**`scripts/check_swift.py`** exists because this repo is partly developed on a machine with
no Swift toolchain — no `swift`, no `xcodebuild`, no container to borrow one. It checks the
three things that blind authoring gets wrong: balanced delimiters, raw newlines inside
single-line string literals, and references to a member that does not exist on one of our
own types.

The third was added after a real one. Renaming `CompactTable.outgrowsTheGrid` to
`needsLabelledRows` updated every reference but one, in a file my own hand-written check had
not covered, and the miss reached a build. Grepping for the old name would have found it;
remembering to grep for every name I had touched did not. So the check is mechanical now,
and reports the file and the line:

```bash
python3 scripts/check_swift.py TorontoLiveEMS TorontoLiveEMSKit
```

**Give it both roots.** Declarations are pooled across them, so a member the app target uses
from the package resolves. One root at a time still checks delimiters and literals, but the
cross-reference check only sees types declared in the roots it was given.

## Building and testing

```bash
cd TorontoLiveEMSKit && swift test        # the 68 tests
```

Then open `TorontoLiveEMS.xcodeproj` and press **⌘R**.

### The one Xcode gotcha

The app folder is a synchronized group, and **Xcode scans it when the project opens**. A
file that a `git pull` adds or removes while the project is open will not be seen —
`import` will fail with *cannot find in scope* even though the file is on disk. Close and
reopen the project. To find out whether a pull needs it:

```bash
git diff --name-status ORIG_HEAD HEAD | grep -E '^[AD]'
```

Any `A` or `D` means reopen. Nothing printed means you are fine, and a rebuild is enough.

## Status

**The app builds and runs in the iOS Simulator, and `swift test` passes in the package.**
The four APIs that were the main compile risk — `LabeledContent` in the detail view,
`@AppStorage` over a `RawRepresentable` in Settings, `AttributedString(markdown:)` in the
attribution, and `scrollEdgeEffectStyle` — are therefore known to build.

"It builds" is not the same as "it has been looked at under every setting", and the
difference is tracked rather than assumed. The system's appearance and accessibility
settings — dark mode, Reduce Transparency, Increase Contrast, Reduce Motion — have not been
exercised; that is #11 in the tracker.

Tag `v0.0.1` marks an earlier, rougher checkpoint from before the design work. It is a
fallback, not a good state.

## Documentation

| | |
|---|---|
| `CONTEXT.md` | the vocabulary — Incident, Prime Street, Alarm Level, FSA, and the rest |
| `docs/adr/` | five decisions that are hard to reverse and would otherwise be re-litigated |
| `docs/design-decisions.md` | behaviour, layout, colour, and the smaller calls |
| `docs/design-grammar.md` | the Apple-design critique, and the two rules adopted out of it |
| `docs/agents/` | where issues live, the triage labels, and how to read the above |

Open work is tracked as GitHub issues on `Scorpio4938/TorontoLiveEMS`. `docs/agents/issue-tracker.md`
says how they are written and read.

Written to be read before changing anything. `docs/design-decisions.md` in particular
records several decisions that were *reversed* during design, with what they replaced and
why, so the reasoning survives rather than the outcome alone.

## Known gaps

- **iPad and Mac** have no design. Apple's own answer is a `Table` at regular width and a
  `NavigationSplitView`, which `docs/adr/0005` anticipates but nothing implements.
- **No app icon and no accent colour.** The asset catalogue is empty and the app is system
  blue.
- The compact table is hand-built, deliberately — Apple's `Table` collapses to one column
  on a phone. See `docs/adr/0005` before "fixing" it.
- **A per-column width breaks the header alignment**, for reasons not established. It was
  tried and reverted (`fb43ac1`). The helper sized the header and the rows through the same
  call with the same bounds, so it should not have been able to misalign them; the suspicion
  is the invisible `chevron.right` placeholder in the header, whose mismatch with the
  system's disclosure chevron was previously spread across five flexible columns and would
  have landed on four. Whoever next wants unequal columns should start there — and note that
  `Alarm Level` looking wide is not evidence of a wide column. It is one character shorter
  than the next shortest header, so it was the only one that fitted on one line.
- **`DispatchTimestamp.dateAndTime` is unused by the app** but still tested. Kept in case a
  wider table wants the date; it and its tests can go if not.
