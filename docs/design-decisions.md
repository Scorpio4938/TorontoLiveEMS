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
- **The column header is a pinned section header** and the status line sits above the list.
- **The feed's own timestamp is always shown**, as a hand-built caption line above the
  column header. There is no platform component for "the age of this data", and
  ADR-0005 calls for Apple's component *where one exists* — so a plain caption is the
  answer rather than an invention. Putting it at the bottom would detach it from the
  table it qualifies, and the bottom bar now holds the refresh button. It renders as the
  City's page renders it ("Last Updated"), except with the space after the colon they
  omit. Using the *source's* timestamp rather than our fetch time keeps the age honest
  even when our request succeeded against stale upstream data.
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

- **The City of Toronto is credited in the app**, using the City's own attribution
  statement:

  > Contains information licensed under the Open Government Licence – Toronto.

  This is the statement the Open Government Licence – Toronto specifies as the
  default where the Information Provider gives no specific one. Link to the
  licence wherever the platform allows.

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
