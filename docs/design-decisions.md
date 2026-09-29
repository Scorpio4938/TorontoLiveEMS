# Design decisions

The smaller, largely reversible decisions behind TorontoLiveEMS. Decisions with
lasting architectural consequences live in `docs/adr/`. Vocabulary lives in
`CONTEXT.md`.

## Source and refresh

- **Refresh is manual.** No timers, no polling, no background refresh. The feed is
  an undocumented path on the City's server and its data cannot change more often
  than every five minutes, so repeated fetching buys nothing and pressures a
  service that never advertised this endpoint.
- **One fetch when the app has no data to show** — a cold launch, so it is never
  empty on arrival. This matches the City's own page, whose AJAX call fires on
  `document.ready` and whose refresh button is `location.reload()`.
- **Returning from the background never fetches.** If the app is still alive in
  memory holding a previous result, reopening shows that result unchanged. The
  data is replaced only when the refresh button is tapped. One request per cold
  launch, one per tap — never on foreground, never on a timer.

  The consequence, accepted deliberately: background the app for three hours,
  reopen it, and you see three-hour-old incidents. That is what the always-visible
  `update_from_db_time` timestamp is for — staleness stays legible instead of
  hidden.
- **The feed's own timestamp is always shown.** `update_from_db_time` renders as
  the City's page renders it ("Last Updated"), except with the space after the
  colon they omit. Using the *source's* timestamp rather than our fetch time keeps
  the age honest even when our request succeeded against stale upstream data.
- **Offline or feed-down shows the last successful snapshot, clearly marked
  stale** — never a blank screen. Staleness is only ever within one session, since
  nothing persists.

## Platform scope

- **iPhone first.** Mac and iPad are deferred, not abandoned.
- **The project is a single multiplatform target** (`SUPPORTED_PLATFORMS =
  iphoneos iphonesimulator macosx xros xrsimulator`), so there is no separate Mac
  target to defer. Any per-platform column divergence is `horizontalSizeClass`
  conditional layout in the same code path.
- **No map in v1.** Medical incidents — the large majority — have no mappable
  point, only an FSA, so a map would mostly render areas rather than pins.

## The compact table

- **Six fixed columns:** Prime Street, Cross Street, Dispatch Time, Incident Type,
  Alarm Level, Dispatched Units. The table never grows columns.
- **The City's column *proportions* are not mirrored.** They are desktop-tuned: at
  their widths every text column wraps on a phone. We mirror their *fields* and
  allocate widths ourselves.
- **Empty cells are left empty.** Cross Street is blank for roughly two-thirds of
  incidents (all medical ones). No `N/A`, no dash.
- **Alarm Level shows the bare ordinal**, always, including `0`. Note the cost: it
  is `0` on 99.76% of incidents, so the column is near-constant by design.
- **Incident Number and Area are not columns.** They live in the model and in the
  detail view.
- **Long values get a full-width continuation line** beneath the six-field grid
  rather than wrapping inside a narrow column. Dispatched Units at the City's 16%
  width fits about ten characters per line; a nine-unit response decoded runs to
  about 104 characters, so in-column wrapping would mean a ~150pt-tall cell in a
  ~58pt-wide column. Spanning the full width renders the same content in two
  lines. The 67% of rows that are single-unit medical calls stay a clean one-line
  grid, and row height ends up proportional to response size.

## Values

- **Human-rendered, not raw pass-through.** The City's table cells apply zero
  transformation and put all readability in a footnote legend; we render values
  readably and carry the explanation inline.
- **Dispatch Time is formatted**, not the raw ISO string the City displays with
  its `T` intact.
- **Dispatched Units are decoded using the City's own legend** — `P` Pumper,
  `R` Rescue, `A` Aerial, `T` Tower, `PL` Platform, `S` Squad, `HR` Highrise,
  `HZ` HazMat, `FB` Fireboat, `CMD` Command Vehicle, `C` Chief, `LA` Air Light,
  `TRS` Trench Rescue Support, `WT` Water Tanker, `HS` Haz Support, `Sup7` and
  `Box12` Canteen, `DE` Decon, `MP` Mini Pumper, `FI` Fire Investigator. This is
  the City's vocabulary, not ours.
- **Codes we cannot decode are shown raw.** The legend appears not to be
  exhaustive — `L325` was observed once and is undefined. An undecodable code
  falls back to its raw token rather than a guess.
- **The street suffix is kept verbatim.** Real-street values carry a variable
  two-letter suffix — `SPADINA RD, TT`, `SILVER DART DR, ET` — never present on
  FSAs. It is displayed as published. **Its meaning is unknown**, so it cannot yet
  be explained in the app, which is a documentation debt this creates rather than
  closes.

## Detail

- **The detail view is the only place extra data appears.** Tapping an incident
  opens it; the compact table never gains columns.
- **It carries everything**: all eight published fields, the full Incident Type
  string, the decoded unit list, and the verbatim values alongside the formatted
  ones.
- **It is where the legend lives.** Alarm Level meanings, unit-letter expansions
  and the rest of the City's explanatory text belong here, explaining *this*
  incident's values, rather than as footnotes under a table.
- **Unknown incident types and undecodable unit codes surface here** as raw
  strings, so nothing is silently relabelled.
