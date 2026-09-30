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
TorontoLiveEMS/         the app — views, and nothing else
TorontoLiveEMSKit/      the data logic, as a local Swift package, and all 53 tests
scripts/check_swift.py  a structural check, see below
docs/                   the decisions
```

**Why the package is a sibling and not inside `TorontoLiveEMS/`.** That folder is a
`PBXFileSystemSynchronizedRootGroup`: every `.swift` file under it joins the app target
automatically, with no `pbxproj` edit. Nesting the package there would compile its sources
into the app target *and* into the module, which does not work. The package is linked into
the app target by a local package reference.

**`scripts/check_swift.py`** exists because this repo is partly developed on a machine with
no Swift toolchain — no `swift`, no `xcodebuild`, no container to borrow one. It checks
balanced delimiters and raw newlines inside single-line string literals, which are the
transcription errors that writing blind produces. It caught a real one: a generated test
fixture containing a literal newline in a string. Run it after any edit to Swift here:

```bash
python3 scripts/check_swift.py TorontoLiveEMSKit
python3 scripts/check_swift.py TorontoLiveEMS
```

## Building and testing

```bash
cd TorontoLiveEMSKit && swift test        # the 53 tests
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

**`b2c36c0` is the last commit that was built and run in the iOS Simulator, and the last at
which `swift test` passed.** Everything after it is unverified — none of it has been
compiled, and the test count has grown from 42 to 53 since. To see how much is outstanding:

```bash
git log --oneline b2c36c0..HEAD | wc -l
```

- Tag `v0.0.1` marks the last state that was built and behaved as expected. That is the
  fallback.

The pieces most likely to fail, because they are the newest APIs and were written without a
compiler: `LabeledContent` in the detail view, `@AppStorage` over a `RawRepresentable`
enum in Settings, `AttributedString(markdown:)` in the attribution, and
`scrollEdgeEffectStyle` in the detail view.

## Documentation

| | |
|---|---|
| `CONTEXT.md` | the vocabulary — Incident, Prime Street, Alarm Level, FSA, and the rest |
| `docs/adr/` | five decisions that are hard to reverse and would otherwise be re-litigated |
| `docs/design-decisions.md` | behaviour, layout, colour, and the smaller calls |
| `docs/agents/` | where issues live, the triage labels, and how to read the above |

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
