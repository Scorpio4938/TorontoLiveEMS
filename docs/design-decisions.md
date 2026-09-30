# Design decisions

The smaller, largely reversible decisions behind TorontoLiveEMS. Decisions with
lasting architectural consequences live in `docs/adr/`. Vocabulary lives in
`CONTEXT.md`.

## Source and refresh

- **Refresh is manual.** No timers, no polling, no background refresh. The feed is
  an undocumented path on the City's server and its data cannot change more often
  than every five minutes, so repeated fetching buys nothing and pressures a
  service that never advertised this endpoint.
- **A refresh is skipped when the City cannot have republished.** The published tick
  lands on a five-minute boundary, so between two boundaries there is nothing new, and
  tapping Refresh in that window shows an alert rather than making a request whose answer
  we already know. The alert is the point: a silent skip is indistinguishable from a dead
  button, which is exactly the bug reported earlier. The gate **fails open** — no tick, or
  one of an unexpected shape, allows the fetch rather than blocking it.
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
- **The refresh control is the only way to refresh**, at the bottom right on iOS, within
  thumb reach. It is a plain toolbar item — no button style, background or padding of its
  own — so the platform draws it and it keeps the system's current button treatment.
  macOS keeps it in the top bar, where a bottom bar does not exist.
- **Pull-to-refresh is deliberately absent.** It called exactly the same function as the
  button, so the two were one action with two affordances; and because only the gesture
  showed a spinner, a working button looked like a broken one beside it.
- **A refresh in flight is announced in the status line**, not in the button, so the
  button's appearance is untouched. The feed only changes every five minutes, so a
  refresh returning exactly what we already had is the normal case — it has to be
  distinguishable from a tap that did nothing.
- **The title is the system's navigation title, pinned inline.** The large title was tried
  first and rejected on sight: it collapses as the list scrolls while the status line and
  column header below it stay pinned, so the chrome moves in two directions at once. It
  also reserves a band of empty space above the title that a table cannot afford. Inline
  puts the title on the same bar as the settings button rather than on a band above it.
- **Everything above the incidents is inside the list, as a section header** — the status
  line, and the column labels when there are columns. Nothing is drawn outside it, and
  there is no `Divider` between them. The status line used to be a hand-built band above
  the list with its own padding, which meant its 16pt inset lined up with neither the
  blocks below nor the rows within them; that misalignment was reported as the cards
  looking wrong. As a section header the platform insets it with everything else.
- **One consequence, deliberately taken.** The status line was always visible; as a section
  header in a grouped list it scrolls away with the content. It is context for what you are
  reading rather than a control, so scrolling is the right behaviour — but it is a change.
- **The states with no incidents are said by the views that replace the list.** A section
  header exists only when there is a section, so "Fetching…" and "Nothing fetched yet" — the
  two states that used to be written into the status line — are now the `ProgressView` and
  the `ContentUnavailableView` instead.
- **The feed's own timestamp is always shown**, in that header, labelled
  **"City data as of …"**. That value is `update_from_db_time` —
  the City's own refresh tick, which lands on a five-minute boundary — and not the moment
  we fetched it. "Last updated" left that open to the wrong reading, and was changed after
  it was mistaken for our own fetch time.

  There is no platform component for "the age of this data", and ADR-0005 calls for
  Apple's component *where one exists* — so a plain caption is the answer rather than an
  invention. Putting it at the bottom would detach it from the table it qualifies, and the
  bottom bar now holds the refresh button.

  It is also worth knowing that this timestamp is Toronto **local** wall-clock, not UTC:
  the City's `23:55` and a UTC machine's `03:56` are four hours apart in September. That is
  why `DispatchTimestamp` reads components out of the string rather than handing it to a
  date formatter, which would have shifted it.
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

- **Five fixed columns:** Prime Street, Dispatch Time, Incident Type, Alarm Level,
  Dispatched Units. The table never grows columns.
- **Cross Street is not a column.** It is blank on most incidents — every medical
  one — and it refines Prime Street rather than being a peer of it, so on a phone it
  spent width it rarely used. It lives in the detail view, with Incident Number and
  Area.
- **The City's column *proportions* are not mirrored.** They are desktop-tuned: at
  their widths every text column wraps on a phone. We mirror their *fields* and
  allocate widths ourselves.
- **Every column header takes two lines.** "Alarm Level" is a character shorter than the
  next shortest label, so it was the only one that fitted on a single line — which reads as
  a column of a different shape rather than as a shorter label. The break is forced, at no
  cost, where narrowing the column would move the widths and the alignment with them. That
  was tried and reverted.
- **A field's label and its column header are separate things.** The header carries the
  forced break above; a field's label appears beside its value in the accessibility layout
  below, where the same break would be a stray blank line. `CompactColumn.label` is the
  City's field name, `headerLabel` is the header, and they differ only for Alarm Level.
- **Above the accessibility text sizes the grid becomes a stack.** Five columns cannot be
  made readable at those sizes — the text scales up roughly threefold, so a row needs
  something like 450pt of width to hold five usable columns and has about 340 — and because
  a cell wraps rather than truncates, running out of room does not clip the grid, it grows.
  One incident becomes a screenful with one word per line. Above that boundary an incident
  is one field per line, each labelled, and the column header stands down because the rows
  now carry their own labels. The boundary is the platform's and the layout is
  `LabeledContent`'s; only the naming of the boundary is ours, because the rows and the
  header have to agree on it. *Those two measurements are estimates, not readings.*
- **The table's measurements have one home.** The header and the rows are separate views
  that have to agree on type size, header weight and column spacing, and each used to state
  its own with nothing enforcing the match. They now read `CompactTable`. A header that
  disagrees with its rows is what broke the column alignment twice before.
- **The columns live in the package; the measurements do not.** `CompactColumn` maps an
  Incident to what a cell shows — content rather than layout, importing nothing from
  SwiftUI — so it sits in `TorontoLiveEMSKit`, where it can be tested. `CompactTable`
  holds SwiftUI values and stays in the app target.
- **Empty cells are left empty.** No `N/A`, no dash.
- **Alarm Level shows the bare ordinal**, always, including `0`. Note the cost: it
  is `0` on 99.76% of incidents, so the column is near-constant by design.
- **A value that does not fit wraps inside its own cell.** It is never truncated and
  is never moved out of its column, so a long apparatus roster makes its own column
  taller and leaves the other four alone. A nine-unit response therefore makes a tall,
  narrow cell rather than a wide one. This replaces an earlier full-width continuation
  line, which read as though the value belonged to whichever column it landed under.
- **Incident Number and Area are not columns.** They live in the model and in the
  detail view.

## The two arrangements

- **The reader picks between a table and cards, in Settings.** Table is the default: it
  fits the most incidents on a screen, which is what the product is for. Cards give each
  incident a block of its own. Same five fields, same words, same data in both — only the
  shape differs.
- **Cards are rows in the platform's own list**, and the platform draws everything: the
  container, the corner radius, and the hairlines between rows inset from the leading edge.
  The references are the Notes app and this app's own detail view, which both get this by
  using a `List` of `Section`s and setting no style of their own.
- **One `Section` for the list, not one per incident.** A `Section` groups *related rows
  into one block* — the detail view has three, and each holds several rows. Giving every
  incident its own section made a block holding a single row, which is not a group; it is a
  border, and a screen of them reads as a wall of boxes rather than as a list. Tried, looked
  at, corrected.
- **A hand-rolled card was built and rejected.** It drew `.regularMaterial` inside a
  `RoundedRectangle(cornerRadius: 10)` with padding picked by hand — rules 1 and 17 of
  `docs/design-grammar.md` both forbid it, and the version that ships is the one where the
  system draws everything. The rejected version is on `prototype/table-treatments`.
- **Two typographic variants were tried and dropped.** Heavier weights on the identity
  fields, and a monospaced *instrument* reading. Neither could be told apart from the
  table at a glance, which is an answer in itself: the table is not short of typographic
  options, it is short of a different shape.
- **Cards need no accessibility layout of their own.** Two stacked lines are already what
  the accessibility layout turns the table into, so at those sizes cards simply get
  bigger. The layout in #9 governs the table only.

## Values

- **Human-rendered, not raw pass-through.** The City's table cells apply zero
  transformation and put all readability in a footnote legend; we render values
  readably and carry the explanation inline.
- **Dispatch Time is formatted**, not the raw ISO string the City displays with
  its `T` intact. The reader chooses between the City's own 12-hour form and a 24-hour
  one in Settings; 12-hour is the default because it is what the City publishes.
- **There is one setting.** Settings is reached from a toolbar button shaped exactly like
  the refresh button, and holds a single choice. It is stored with `@AppStorage`, the
  platform's own preference store, behind a `RawRepresentable` enum — no settings model,
  no synchronisation, because there is nothing to synchronise.
- **Dispatched Units are decoded in the detail view, and left raw in the table.**
  Decoding uses the City's own legend — `P` Pumper, `R` Rescue, `A` Aerial, `T` Tower,
  `PL` Platform, `S` Squad, `HR` Highrise, `HZ` HazMat, `FB` Fireboat, `CMD` Command
  Vehicle, `C` Chief, `LA` Air Light, `TRS` Trench Rescue Support, `WT` Water Tanker,
  `HS` Haz Support, `Sup7` and `Box12` Canteen, `DE` Decon, `MP` Mini Pumper,
  `FI` Fire Investigator. That is the City's vocabulary, not ours. The table keeps the
  published tokens — `P231, P234` — because it has the least room and the detail view is
  one tap away.
- **Codes we cannot decode are shown raw.** The legend appears not to be
  exhaustive — `L325` was observed once and is undefined. An undecodable code
  falls back to its raw token rather than a guess.
- **Colour marks exceptions, not categories.** Incident Type is tinted only for Fire,
  Hazmat, Carbon Monoxide and Rescue; Alarm Level only when it is not `0`. Together
  those are about 9% of incidents. Colouring all thirteen categories equally would make
  the 64% of incidents that are medical as loud as the 5% that are fires, which is the
  opposite of what colour is for.
- **The tint is the text colour and nothing else** — no dot, no symbol, no badge. It
  costs no width and adds nothing to the layout, so the table stays a table.
- **The detail view does not tint.** Colour there would mark nothing: a single incident
  has nothing to stand out from.
- **The street suffix is kept verbatim.** Real-street values carry a two-letter
  municipality code, never present on FSAs, and it is displayed as published. Every
  observation so far matches the street's geography:

  | Code | Municipality |
  |---|---|
  | `TT` | Toronto (the pre-amalgamation city) |
  | `ET` | Etobicoke |
  | `NY` | North York |
  | `SC` | Scarborough |

  Toronto's other pre-1998 municipalities are York and East York, so `YK` and `EY`
  are expected to appear. Decoding to `LAWRENCE AVE · Scarborough` is now known to be
  possible and would be a one-line change; we keep the published form, because
  mirroring the City's own values is the standing preference.

## Detail

- **The detail view is the only place extra data appears.** Tapping an incident
  opens it; the compact table never gains columns.
- **It carries everything**: all eight published fields, the full Incident Type
  string, and the decoded unit list.
- **Laid out with `LabeledContent`**, the platform's own label-and-value row, with
  explanations in section footers rather than stacked under each value. That is the
  Settings and Contacts shape, and it arrives with Dynamic Type, VoiceOver labelling and
  alignment behaviour we would otherwise hand-roll.
- **The detail view shows the City's values, not our renderings of them.** Incident
  Type appears as `MEDICAL`, Dispatch Time as `2026-09-29T18:24:39`, Dispatched Units as
  `R346`. The rendering — the category label, the clock time — belongs to the table,
  where width is scarce enough to justify it and where a value has to be scannable at a
  glance. On a screen with room, the published value is the honest one. Showing both was
  duplication, and it has been removed.
- **It is where the legend lives.** Alarm Level meanings, unit-letter expansions and
  the rest of the City's explanatory text belong here, explaining *this* incident's
  values from the section footers rather than as footnotes under a table.
- **Unknown incident types and undecodable unit codes surface here** as raw
  strings, so nothing is silently relabelled.

## Attribution and data terms

- **The City is credited, non-affiliation is stated, and the licence is linked inline.**
  The detail view carries a single line: that the app is not affiliated with the City of
  Toronto, that the data is shown from the City's public Toronto Fire Active Incidents
  page, and that it contains information licensed under the Open Government Licence –
  Toronto. The licence name is an inline link inside that sentence — a separate row
  repeating "Open Government Licence – Toronto" said nothing the sentence had not.

  "Not affiliated" is stated rather than left to inference. The feed is the one the
  City's own page loads; it is not offered to anyone, we took it from there, and a line
  reading "Data provided by the City of Toronto" implied a relationship that does not
  exist.

- **It is unresolved whether the licence formally covers this feed.**
  `livecad.xml` is not on the City's Open Data portal — searching that portal for
  "livecad" and for "active incidents" both return nothing — and the page hosting
  the feed carries no licence notice of any kind. We use the City's statement
  regardless: it is the City's information, and the statement costs nothing.

- **Nothing may imply official status or City endorsement.** The licence grants no
  right to suggest the City endorses this app, and explicitly excludes the City's
  names, crests, logos and other official symbols. No City marks, no "official"
  framing.

- **The data is provided "as is", with no warranty**, so the app must not present it
  as authoritative. This is a second reason — alongside politeness toward an
  undocumented endpoint, and the feed's own five-minute cycle — for showing
  `update_from_db_time` at all times: the user needs to see how old the data is
  rather than trust it blindly.
