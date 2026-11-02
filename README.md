# TorontoLiveEMS

Live fire incidents and police calls in Toronto, as lists and on a map. The incidents are Toronto
Fire Services', republished by the City of Toronto every five minutes; the calls are the Toronto
Police Service's. This app reads what those publishers make public — it is not affiliated with
either, and it collects nothing about you.

## What it does

- **Fire** — active incidents, newest first, as a table or as cards. A detail screen carries the
  alarm level, the station area, the apparatus sent, and where it is.
- **Police** — recent calls for service, newest first, with a call's type as the Service's words or
  its code. How far back it looks is yours to set; older calls fold away rather than mixing in.
- **Map** — both feeds in one picture. A mark's symbol says what kind of incident it is, its colour
  says how much it matters, and either source can be filtered out.
- **Settings** — layout, time format, and how a police call's type is shown.

## The data

- **Fire incidents** — the City of Toronto's live feed,
  `https://www.toronto.ca/data/fire/livecad.xml`, refreshed every five minutes. Undocumented: not on
  the Open Data portal, found by reading that page's JavaScript. `docs/adr/0001`, `0002` and `0004`
  record why this source, why nothing is thrown away, and why a medical location is never narrowed.
- **Police calls** — the Toronto Police Service's calls-for-service dataset, queried for the last
  four hours. `docs/adr/0006` records the endpoint, the fields, and what could be measured.

Both are open government data under their publishers' licences. The terms, and what they require of
an app that shows the data, are in the app under **Settings → Data Licences**.

### Reference data

Fire stations, police divisions, police facilities, and the apparatus roster are bundled rather
than fetched. The live feed names a station by number and a police call names a division as `D14`;
neither feed says what either one is. `scripts/make_reference_data.py` reads the City's *Fire
Facility Locations*, *Police Boundaries* and *Police Facility Locations* open datasets, and the
community-maintained *Firefighting Wiki* apparatus roster, and writes the four JSON files under
`TorontoLiveEMSKit/Sources/TorontoLiveEMSKit/Resources/`. A fifth file, `TorontoWikipedia.json`,
is written by `scripts/make_wikipedia_data.py` and holds only the paraphrased station histories
and unit photographs that exist. Each file records its source URL, licence and retrieval date. The
divisions file uses the City's current 16-division datastore geometry, because a division is
ground rather than a point. The datastore already merges the former 54 area into 55 and the water
into 52; the older 19-feature download still carries `00` (water and island areas), `54` and `58`
(retired) separately, and filtering it left holes. The three City datasets are Open Government
Licence – Toronto; the apparatus roster is CC BY-SA 3.0; Wikipedia text is CC BY-SA 4.0, and each
Commons photograph keeps its own licence. Re-running the scripts is the only way those files
change. The app reads them from the bundle: the Stations, Units and Divisions catalogues are the
reference section, and a station, unit or division page is built from the file rather than from a
second copy of the facts.

## Requirements

iPhone, iOS 27 or later. Xcode 27 to build. No dependencies.

The target also declares iPad, Mac and visionOS; none of those has been designed for.

## Build and run

```bash
cd TorontoLiveEMSKit && swift test        # the tests
```

Then open `TorontoLiveEMS.xcodeproj` and press **⌘R**.

**The one gotcha.** The app folder is a synchronized group, scanned when the project opens — a file
added or removed by a `git pull` while it is open will not be seen, and the build fails naming a type
rather than the reason. `python3 scripts/xcode_needs.py` says whether a reopen is needed. A clean
build does not rescan; only reopening does.

## Layout

```
TorontoLiveEMS/       the app — views, and the table's measurements
TorontoLiveEMSKit/    the data logic, as a local package, and the tests
scripts/              the checks, the reference data, the postal shapes, the version rule
docs/                 the decisions
```

`Package.swift` says why the package sits beside the app folder rather than inside it.
`scripts/check_swift.py` stands in for a compiler on the machine this is partly written on; its
docstring says what it catches and why each check exists.

## Documentation

| | |
|---|---|
| `CONTEXT.md` | the vocabulary — Incident, Prime Street, Alarm Level, FSA, and the rest |
| `docs/adr/` | the decisions that are hard to reverse |
| `docs/design-decisions.md` | behaviour, layout, colour, and the smaller calls |
| `docs/design-grammar.md` | the Apple-design critique, and the rules adopted out of it |
| `docs/releasing.md` | the version scheme, and what a checkpoint involves |
| `docs/agents/` | where issues live, the triage labels, and how to read the above |

`docs/design-decisions.md` records several decisions that were *reversed* during design, with what
they replaced and why, so the reasoning survives rather than the outcome alone. Open work is tracked
as GitHub issues on `Scorpio4938/TorontoLiveEMS`.

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) — every version, newest first, with the commit and the issue behind
each line.
