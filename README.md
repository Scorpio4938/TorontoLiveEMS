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
TorontoLiveEMSKit/      the data logic, as a local Swift package, and all 181 tests
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
four things that blind authoring gets wrong: balanced delimiters, raw newlines inside
single-line string literals, references to a member that does not exist on one of our own
types, and files that name a package type without importing the package.

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
cd TorontoLiveEMSKit && swift test        # the 181 tests
```

Then open `TorontoLiveEMS.xcodeproj` and press **⌘R**.

### The one Xcode gotcha

The app folder is a synchronized group, and **Xcode scans it when the project opens**. A
file that a `git pull` adds or removes while the project is open will not be seen — the build
fails with `cannot find type 'X' in scope`, naming the type rather than the reason, and the
errors around it are usually cascades of the same missing file.

**Ask, rather than remembering:**

```bash
python3 scripts/xcode_needs.py          # since the newest tag
python3 scripts/xcode_needs.py v0.0.2   # since a particular one
```

It names the files and says whether a reopen is needed. Tags mark points that have been built,
so the newest one is the right thing to compare against.

Two things worth knowing about it. A **clean build does not rescan the folder** — only reopening
the project does, so ⇧⌘K will not save you. And it only looks at `TorontoLiveEMS/`: the package's
sources and tests are found by path, so adding files there needs nothing.

This has caught this project three times. The first two were noticed late enough to cost a build
each, which is why it is a command now and no longer a paragraph.

## Versions and tags

**A tag is a version.** The project's `MARKETING_VERSION`, the tag, and the version Settings shows
are one number — `major.minor.checkpoint` — and `python3 scripts/version_check.py` fails if they
disagree. `docs/releasing.md` has the scheme and the process.

The rule starts at `v0.0.9`. The eight tags before it all carry `0.0.1a1` in their trees, set once
at `v0.0.1` and never moved: they are older than the rule, not wrong, and they are left alone
because a tag that changes meaning is the one thing tags exist to prevent.

**Tags are checkpoints, not promises.** Some have never been built, so the list is worth reading
rather than trusting.

| | | |
|---|---|---|
| `v0.0.1` | `e98d13d` | Builds. From before the design work, so rougher than what is on `master` — but it is a working point. |
| `v0.0.2` | `d1ea109` | **Does not build.** `d1ea109` put `ToolbarSpacer()` inside a `ToolbarItemGroup`, whose content is a `ViewBuilder`; `ToolbarSpacer` conforms to `ToolbarContent` and not to `View`. Every commit through `065e326` inherits the fault; `1732bd5` fixes it. |
| `v0.0.3-bar-and-cards` | `3cb40f2` | Builds. The design work after `v0.0.2` — the bottom bar, the switcher, the cards arrangement, the general map page. Kept on `archive/everything-since-v0.0.2`, not on `master`. |
| `v0.0.4-two-tabs` | `660f4a4` | Builds, and ran on an iPhone: the bottom tab bar, with refresh as the prominent trailing tab. |
| `v0.0.5-map-page` | `f648162` | Builds. The map page, and the chrome above both pages as one layer. |
| `v0.0.6-postal-areas` | `f5c770d` | Builds. A postal area drawn as the boundary Statistics Canada publishes, instead of a circle around a geocoder's guess. |
| `v0.0.7-map-kinds` | `d76a13d` | Builds. Standard and Satellite, chosen from a control in the shared chrome. |
| `v0.0.8-fire-page` | `aa130e7` | **Not built.** The incidents page renamed and retitled Fire, and a fire extinguisher on its tab. |
| `v0.0.9` | `58668fe` | **Not built.** The version scheme itself, and the first tag whose own tree carries its number. |
| `v0.0.10` | `1f4d003` | **Not built.** Settings says the version, the build and the stage — the build number back where it was, and the sentence under it explaining which number is which. |
| `v0.0.11` | `f468581` | Builds, and ran: the police page. A second source and a second tab over the same table and cards as the fire page, so the two feeds share one presentation layer and differ only in their columns, their detail screen and their data. |
| `v0.0.12` | `2fa91a4` | **Not yet run as it stands.** The police page finished: a static code list behind every code, the reader's choice of words or code in the table, an information screen that is fields and licence without padding, and a refresh that answers from the clock it already holds rather than spending a network round trip to decide there is nothing to fetch. |
| `v0.0.13` | `8684d3e` | Builds and runs. Police calls on the map — grouped by point, each pin wearing its incident kind's symbol — over one shared mark vocabulary that both feeds produce, and a map tab whose refresh asks both. **The filter is not in yet**, and a busy window puts a hundred pins on one map without it. |
| `v0.0.14` | `2fff7f9` | **Not yet run as it stands.** The map stops shouting: three tones — dark red, orange, and grey for the majority — over four severities, the police's inferred from their call codes and `unknown` for a call nobody named. |
| `v0.0.15` | `8958fe4` | **Not yet run as it stands.** The pins are legible after dark, twelve more police codes are known — a robbery and a knife among them — and the map's info button opens a legend of its nine symbols and three colours instead of the fire feed's data page. |
| `v0.0.16` | `9d356ab` | **Not yet run as it stands.** The filter — All, Fire Only or Police Only — in the chrome, second from the leading end, its glyph following the choice; `map` in place of `map.fill`; and three more police codes, a stabbing among them. |
| `v0.0.17` | `406c4be` | **Not yet run as it stands.** Recent by default: the police page shows the last hour and folds the rest behind `Earlier calls · n`, strictly — a serious call outside the window folds with everything else. The map has a window of its own, one hour or four, and always keeps criticals. Settings can set the page's window, and a fourth choice of `Last 4 hours` is the whole of what the Service publishes. |

A row whose own commit writes this file cannot name that commit; `git rev-parse <tag>` answers
it. Every other row can be checked with `git show <hash> --stat`.

Why this is written down: for seven commits nothing could build, and Xcode kept running the last
binary it had. Reports made during that window described an app older than the code being changed,
and fixes were tested against it. Believing a tag was good when it was not is the specific mistake
this table exists to prevent — and the same mistake, in the other direction, is why each row says
whether it was ever *run* as well as whether it was ever *built*.

## Status

**The app builds and runs on an iPhone.** The map has been looked at on a device as far as the symbols
and the colours — which is where three separate reports of a question mark came from, each one a
police code the app had not met.

**Not yet run: the 19 commits since v0.0.16.** Recent by default. The police page folds everything
older than its window behind `Earlier calls · n` — strictly, so a serious call outside the window folds
with the rest — and the map takes a window of its own, one hour or four, always keeping criticals. The
filter's menu, the police page's clock, and the Settings rows are the parts worth looking at.

**`swift test` has still never been run.** There are **226 tests** across 23 files, with 625
expectations, and they are the only thing that can check the parsers, the query builders, the gates,
the projections, the two windows and their exemption, the legend and the sentences. Nothing in this
checkpoint has been through a compiler's tests — only through a build.

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
  `NavigationSplitView`, which `docs/adr/0005` anticipates but nothing implements. The target
  also declares visionOS, which has never been built — which matters, because the Liquid Glass
  APIs are `@available(visionOS, unavailable)`.
- **App icon and accent colour are in place** — a beacon, and fire red. This section listed
  them as gaps; the assets are in the catalogue.
- The compact table is hand-built, deliberately — Apple's `Table` collapses to one column
  on a phone. See `docs/adr/0005` before "fixing" it.
- **The map is the one thing kept from the work after `v0.0.2`.** It lives in the detail view's
  Location section, and needs `IncidentLocation` in the package plus `IncidentGeocoder` and
  `IncidentLocationMap` in the app. There is no map *page* — that went back with the rest.
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
