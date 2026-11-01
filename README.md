# TorontoLiveEMS

Live fire incidents and police calls in Toronto, as lists and on a map. The incidents are Toronto
Fire Services', republished by the City of Toronto every five minutes; the calls are the Toronto
Police Service's, published as they are dispatched. This app reads what those two publishers make
public — it is not affiliated with either of them, and it collects nothing about you.

## What it does

- **Fire** — every active incident the City publishes, newest first, as a compact table or as cards.
  A detail screen carries the alarm level, the station area, the apparatus sent, and where the
  incident is.
- **Police** — recent calls for service, newest first, with a call's type shown as the Service's own
  words or as its code. How far back it looks is yours to set, and older calls fold away behind a
  single row rather than being mixed in.
- **Map** — both feeds in one picture. A mark's symbol says what kind of incident it is; its colour
  says how much it matters, and never what kind. Either source can be filtered out.
- **Settings** — layout, time format, and how a police call's type is shown.

## Where the data comes from

**Fire incidents** — the City of Toronto's live feed,
`https://www.toronto.ca/data/fire/livecad.xml`, refreshed every five minutes. It is not a published
API: it is not on the City's Open Data portal, its page carries no licence notice, and it was found
by reading that page's inline JavaScript. The app keeps all eight of its fields unreduced, showing
some and carrying the rest to the detail screen. `docs/adr/0001` records why this source, `0002` why
nothing is thrown away, and `0004` why a medical incident's location is never narrowed.

**Police calls** — the Toronto Police Service's calls-for-service dataset, queried for the last four
hours. `docs/adr/0006` records the endpoint, the nine fields, and what could be measured rather than
assumed.

Both are open government data under their publishers' licences. The terms, and what they require of
an app that shows the data, are in the app under **Settings → Data Licences**.

## Requirements

iPhone, iOS 27 or later. Xcode 27 to build. No dependencies.

The target also declares iPad, Mac and visionOS; none of those has been designed for.

## Layout

```
TorontoLiveEMS/         the app — the views, and the table's measurements
TorontoLiveEMSKit/      the data logic, as a local Swift package, and the tests
scripts/                the checks, the icon, the postal shapes, the version rule
docs/                   the decisions
```

**Why the package is a sibling and not inside `TorontoLiveEMS/`.** That folder is a
`PBXFileSystemSynchronizedRootGroup`: every `.swift` file under it joins the app target
automatically, with no `pbxproj` edit. Nesting the package there would compile its sources into the
app target *and* into the module, which does not work. The package is linked into the app target by
a local package reference.

**`scripts/check_swift.py`** exists because this repo is partly developed on a machine with no Swift
toolchain — no `swift`, no `xcodebuild`, no container to borrow one. It checks the four things that
blind authoring gets wrong: balanced delimiters, raw newlines inside single-line string literals,
references to a member that does not exist on one of our own types, and files that name a package
type without importing the package.

The third was added after a real one. Renaming `CompactTable.outgrowsTheGrid` to
`needsLabelledRows` updated every reference but one, in a file my own hand-written check had not
covered, and the miss reached a build. Grepping for the old name would have found it; remembering to
grep for every name I had touched did not. So the check is mechanical now, and reports the file and
the line:

```bash
python3 scripts/check_swift.py TorontoLiveEMS TorontoLiveEMSKit
```

**Give it both roots.** Declarations are pooled across them, so a member the app target uses from the
package resolves. One root at a time still checks delimiters and literals, but the cross-reference
check only sees types declared in the roots it was given.

## Building and running

```bash
cd TorontoLiveEMSKit && swift test        # the tests
```

Then open `TorontoLiveEMS.xcodeproj` and press **⌘R**.

### The one Xcode gotcha

The app folder is a synchronized group, and **Xcode scans it when the project opens**. A file that a
`git pull` adds or removes while the project is open will not be seen — the build fails with `cannot
find type 'X' in scope`, naming the type rather than the reason, and the errors around it are usually
cascades of the same missing file.

**Ask, rather than remembering:**

```bash
python3 scripts/xcode_needs.py          # since the newest tag
python3 scripts/xcode_needs.py v0.0.2   # since a particular one
```

It names the files and says whether a reopen is needed. Tags mark points that have been built, so
the newest one is the right thing to compare against.

Two things worth knowing about it. A **clean build does not rescan the folder** — only reopening the
project does, so ⇧⌘K will not save you. And it only looks at `TorontoLiveEMS/`: the package's sources
and tests are found by path, so adding files there needs nothing.

This has caught this project three times. The first two were noticed late enough to cost a build
each, which is why it is a command now and no longer a paragraph.

## Documentation

| | |
|---|---|
| `CONTEXT.md` | the vocabulary — Incident, Prime Street, Alarm Level, FSA, and the rest |
| `docs/adr/` | the decisions that are hard to reverse and would otherwise be re-litigated |
| `docs/design-decisions.md` | behaviour, layout, colour, and the smaller calls |
| `docs/design-grammar.md` | the Apple-design critique, and the rules adopted out of it |
| `docs/releasing.md` | the version scheme, and what a checkpoint involves |
| `docs/agents/` | where issues live, the triage labels, and how to read the above |

Open work is tracked as GitHub issues on `Scorpio4938/TorontoLiveEMS`. `docs/agents/issue-tracker.md`
says how they are written and read.

Written to be read before changing anything. `docs/design-decisions.md` in particular records several
decisions that were *reversed* during design, with what they replaced and why, so the reasoning
survives rather than the outcome alone.

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) — every version, newest first, with what it changed and whether it was
ever built, run, or tested.
