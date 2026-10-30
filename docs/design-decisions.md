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
- **The police feed skips only on an unchanged stamp, never on a pace.** The
  Service states when it last wrote to the layer. The app keeps the stamp the calls on
  screen were read under — the **as-of**, not the Service's latest stamp — and reads the
  Service's stamp on every refresh. If it is unchanged, the calls are already current and
  are not fetched. If it has moved, the write is fetched: a pace describes the publisher,
  not our copy, and our copy can be a write behind. After a fetch the calls are compared
  with the calls that were there, because a stamp can move while the calls do not. The
  status line and the "nothing newer" sentence quote the as-of, never the Service's newest
  write. Fire keeps its five-minute gate because the City's tick rides inside the document
  it already fetched.
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
- **The boundary under the bar is the soft scroll edge effect, everywhere.** Apple's styles
  are `hard` — a linear, nearly opaque boundary — `soft`, a subtle blur, and `automatic`,
  which lets the context decide. The current design uses soft, and asks for it rather than
  taking whatever a given context picks. It was on the detail view and nowhere else, so the
  same app behaved two ways: a hard bottom edge on the incident list and none on the detail
  view. That was an omission rather than a decision, and it is one modifier now, applied to
  every scroll view under a bar.
- **The states with no incidents are said by the views that replace the list.** A section
  header exists only when there is a section, so "Fetching…" and "Nothing fetched yet" — the
  two states that used to be written into the status line — are now the `ProgressView` and
  the `ContentUnavailableView` instead.
- **The feed's own timestamp is always shown**, in that header, labelled
  **"City fire data as of …"**. That value is `update_from_db_time` —
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
- **Each page lists its own feed newest first, by a rule the app applies.** The two
  sources order differently, and neither order is something the app controls: the City's
  document runs oldest first and the Service's response is only newest first because it was
  asked to be. So each feed sorts its own collection by the time its publisher states,
  descending, and the parsers keep reporting the publisher's order unchanged. Fire sorts the
  published timestamp string — zero-padded ISO-8601, so string order is time order and no
  timezone is chosen. Calls sort their instant. Neither is ever compared with the other,
  because the two pages never show them together. An incident with no Dispatch Time sorts
  last: the empty string compares below every digit, so it cannot claim to be the newest.

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
- **Except when the intersection is the only location there is.** The City publishes an
  intersection instead of an address for some incidents, and leaves Prime Street blank when
  it does. There is no address to refine, so that intersection stands in for the missing one
  rather than the cell being left empty — which hid a location the feed had supplied, on
  precisely the incidents whose location is hardest to infer.
- **A substituted address is marked, and the mark is deliberately tiny.** Two arrows
  pointing apart: the smallest thing that can carry the meaning, and one that needs no
  legend, because the value beside it is two street names joined by a slash where every other
  row holds one address. It keeps its own small type even on a card, where the address itself
  is a headline — a mark that scaled with the value would stop being a footnote. It is a mark
  rather than a word such as "at" because the column has no characters to spare, and because
  the app shows what the City published rather than a rendering of it. It carries an
  accessibility label, so the mark is not information only sighted readers get.
- **The mark goes after the value, not before it.** In front it pushed the address right, so
  that row's text began where no other row's did — against the column in the table, and
  against its own second line in a card. A marker that moves the thing it marks is worse than
  no marker: the value stops being in the column it belongs to. Trailing, the value keeps the
  leading edge and only its wrap shortens, on the rows that need it.
- **A mark can never sit on nothing.** With both streets absent — which happens, when the
  counter is the only place a location was published — the cell is empty and carries no
  mark. That is settled in `CompactCell`'s initialiser rather than at the call site, so a
  blank value and a mark are mutually exclusive by construction: an empty cell showing the
  intersection sign reads as a fault rather than as information, and no caller should have
  to remember not to ask for one.
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
- **Empty cells are left empty — except the one that starts the row.** No `N/A`, no dash,
  and no slash: a column of slashes is noise, and an absent apparatus roster costs the reader
  nothing. The address is the exception, because it begins the row in both compact
  arrangements, and a row that starts with nothing leaves the eye without anywhere to land.
  It shows the same `/` the detail view uses — one mark, one definition, both views.
- **The address has two ways of being absent, and they are different.** A blank Prime Street
  with an intersection published beside it shows that intersection, marked. Both blank shows
  the slash, unmarked. `⇄ /` would say that a location was found elsewhere and that the
  location is nothing.
- **The slash is a placeholder, and the parser drops placeholders.** They are not in
  contradiction: the parser removes punctuation the *feed* sent in place of a value, and the
  column adds punctuation *we* show in place of one. Nothing the City publishes in these
  fields is only punctuation, which is why the first rule is safe.
- **Alarm Level shows the bare ordinal**, always, including `0`. Note the cost: it
  is `0` on 99.76% of incidents, so the column is near-constant by design.
- **A value that does not fit wraps inside its own cell.** It is never truncated and
  is never moved out of its column, so a long apparatus roster makes its own column
  taller and leaves the other four alone. A nine-unit response therefore makes a tall,
  narrow cell rather than a wide one. This replaces an earlier full-width continuation
  line, which read as though the value belonged to whichever column it landed under.
- **Incident Number and Area are not columns.** They live in the model and in the
  detail view.
- **The table and the cards are one implementation, and the column set is the parameter.** Two
  pages need them — Fire and Police — and the second must not fork the first. What differs between
  sources is *which* columns there are and how a row reads them; what does not differ is the grid,
  the header, the cell renderer, the card, the accessibility fallback, the status line and the
  arrangements picker. So a column becomes a value — a label, a cramped label, and how to read one
  row — and each source declares its own array. **The count is therefore a property of the array
  rather than a constant of the layout:** Fire declares five, Police declares four, and nothing in
  the table assumes either.
- **Equal shares are why that costs no measurements.** Every column takes
  `.frame(maxWidth: .infinity)` in one `HStack`, in the header and in every row, so four columns
  divide the width by four and five by five. Checked rather than assumed, because "four instead of
  five" sounds like a layout problem and is not one.
- **What stays per-source:** the columns each source declares, the detail view a row pushes, and
  the card's four slots — which are positions rather than names, so each source decides what its
  first line and its second line mean for its own data.

## The two arrangements

- **The reader picks between a table and cards, in Settings. Cards are the default.** They show
  fewer incidents at once than the table does, and that is the trade being made deliberately:
  one incident per block is what the app opens on, and the table remains for a reader who wants
  more on screen. Same five fields, same words, same data in both — only the shape differs.
- **The default only decides what an *unset* preference resolves to.** A reader who has chosen
  either arrangement keeps it, because the choice is written to their preferences and the
  default is never consulted again. So this changes what a new install opens on, not what
  anybody already using the app sees.
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

## The app icon

- **An emergency light bar, not a flame.** Two marks were tried and rejected first. A small
  table with one cell marked was the product and its colour rule, and it had too many parts. A
  flame said *fire*, and the app reports the *response* to a fire rather than fire itself. A
  light bar is the thing arriving, which is what the feed actually carries, and it is what a
  fire truck shows: red, white, red.
- **Nothing smaller than it looks.** At 29pt — Settings, Spotlight — the whole mark is twenty
  points tall. Three large lenses survive that; the beacon alternative's rays come out under a
  point thick and do not.
- **Each appearance gets a housing that reads against its own ground.** A dark bar on a dark
  ground measured 1.2:1 in the tinted appearance — present in the geometry, invisible in the
  picture. The tinted housing is *lighter* than its ground, the opposite of the other two,
  because in tinted the lenses are the brightest thing in the frame either way.
- **Red, because the app is about fire response.** The lens is a brighter red than the ground,
  because on a red icon a red light has to be the brighter red or it is not a light.
- **Generated, not drawn.** `scripts/make_app_icon.py` writes the three appearance files, and
  `--compare` writes every candidate. There is no image editor here, so the mark is a number
  rather than an export from a tool nobody else has.
- **Flat, opaque, square, and nothing else.** No transparency, no rounded corners, no shadow,
  no attempt at glass. The platform applies the mask, the shadow and the Liquid Glass
  treatment — rule 17 of `docs/design-grammar.md` applied to the icon.
- **Links are blue, wherever they appear.** Links take the accent, which is correct — it is what
  an accent is for, and Apple Music does exactly the same with its red one. But red also means
  error and destructive, so a licence notice or the City's page drawn in it reads as a warning
  rather than as something to tap. Blue is what a link looks like: `LinkedText` tints it, and so
  does the one external link on *About*. The controls stay fire red.
- **The accent is fire red too**, in light and dark variants. It was an empty stub before, so
  the app had no colour of its own. Worth knowing what follows: red is now the app's *most urgent*
  state and orange is the ordinary one, so those two have to stay tellable apart — and if they read
  as one warm blur, the **orange** moves rather than the accent, because the accent is the app's
  identity.
- **Red is the most urgent; orange is everything else, and the postal areas share the rule.** The
  areas used to be painted orange for being areas, which meant one colour said two things — "this
  is a postal area" and "this incident is dangerous" — and a quiet FSA looked like a burning one.
  Every mark now takes the colour of what is inside it, and the level threshold moved from
  "anything but 0" to the City's own line at 2, which its own meanings define as ten or more
  emergency vehicles. Both colours live in one place, `MarkColour`, because they had been written
  out in six and could therefore not be changed.
- **One consequence, decided rather than overlooked:** the table's marked cells are red now instead
  of orange. Orange means ordinary on a map, and the same orange meaning "urgent" on one screen
  and "ordinary" on another is the drift this whole change exists to end.
- **The installed icon is flat, and that is a limit of the format, not of the artwork.** A PNG
  is one layer, so there is nothing for a glass treatment to refract between. A glassy icon is
  not a PNG we can draw: it is an assembly, and Apple's tool for it is **Icon Composer**, which
  ships with Xcode, takes the artwork as *separate layers*, applies the glass, and generates the
  appearance variants from them.
- **The layers are in `design/icon-layers/`**, written by `scripts/make_app_icon.py --layers`
  as SVG, bottom to top: ground, housing, dome, rays. The dome and the rays are the ones to
  give a glass material. The ground and the housing stay flat, and the contrast between a flat
  ground and a raised light is the whole effect — which is what Apple's own icons do with a map
  and a pin. The dome is drawn translucent and pale for that reason: opaque red is paint, and
  paint gives a glass material nothing to do.
- **The flat PNGs stay in the asset catalogue regardless.** They are what the app ships with
  today, they get the platform's own treatment, and the app is never without an icon while the
  Icon Composer assembly is somebody's afternoon rather than a build step.

- **The shape is verified by measuring it.** Nothing in this repository can look at it, so the
  numbers are the check: partly-counted shapes, contrast between each part and the thing it
  sits on, and the size of every part at the sizes iOS draws. Two of the three revisions here
  came from a measurement rather than from a decision — the invisible housing, and the rays
  that would not survive 29pt.

## Where an incident is

- **Three things the feed publishes, and they are not interchangeable.** An *intersection* is
  two streets crossing, so it names a place. A *street* is a street — `LAWRENCE AVE, SC` has no
  number, so the most anyone can say is somewhere along it. A *postal area* is not a place at
  all; it is a neighbourhood, published in place of an address, and ADR-0004 forbids narrowing it.
- **The intersection wins when there is one**, even though the list shows Prime Street as the
  location. For reading, the street names the incident's place; for looking up, two crossing
  streets are strictly more precise than one street name.
- **A postal area is drawn as an area, never a pin.** A pin is a claim about a point and a
  postal area cannot support one. On the live capture, **9 of 15 incidents are postal areas** —
  so this is most of the map, not an edge case, and a pin-per-incident map would be wrong for
  the majority of what it showed.
- **Nothing published means nothing on the map.** Not a best guess and not a default centre.
- **The City's former-municipality suffix is dropped before looking anything up.** `SC` is
  Scarborough, part of Toronto since 1998, and no geocoder wants the 1998 answer. Matched by
  shape — two capital letters after a comma — because the four observed are TT, ET, NY and SC
  and a fifth would otherwise reach a geocoder as part of a street name.
- **Every lookup says Toronto.** The feed is Toronto-only, and a bare `QUEEN ST W` geocodes
  confidently to the wrong continent. A geocoder that answers wrongly is worse than one that
  does not answer.
- **`CLGeocoder` is deprecated at iOS 26** — Apple's note says "Use MapKit" — so the app uses
  `MKGeocodingRequest`, which is new at iOS 26 and returns `MKMapItem`s. Checked against Apple's
  own documentation rather than guessed.
- **The `.street` case does not occur in the current capture**, where every addressable incident
  publishes an intersection. Kept and tested because the feed changes without telling anyone.

## Naming: the publisher and the subject

**Name the publisher when talking about publication; name the service when talking about the
data.** "The City did not publish a location" is right, because it describes an act of publishing.
"City data as of" was wrong, because on the fire page it named a publisher and left the subject
unsaid, beside a police line that says "TPS data as of" and names both.

So the fire line reads **"City fire data as of …"**, and prose about the incidents says **Toronto
Fire Services** — the service whose incidents they are — naming the City where publishing is what
is being described. "Fire division" remains a phrase this project does not use.

## What the app explains

- **The City's own explanations are in the app, paraphrased**, and they live with the thing they
  describe: `LiveCADFeed.sourceNote` for where the incidents come from and how often,
  `AlarmLevel.escalationNote` for how a level is arrived at, `AlarmLevel.countingNote` for what
  its vehicle counts count. A wording change happens beside the field, not in a view.

  **Paraphrased, not quoted, and the app no longer says otherwise.** The City's escalation
  paragraph ran to a hundred words of dispatcher procedure to make a point that takes forty, on a
  screen a reader opens once. Where the exact wording carries the meaning — the vehicle counts —
  it is still quoted, and the screen does not present itself as a transcript.
- **A screen of its own, behind an info button beside Settings.** Reference material rather than
  a preference: somebody wondering what an Alarm Level is should not have to guess that it is
  filed under settings. Settings keeps the attribution; this screen carries the licence too,
  because a reference screen that explains the data should say who published it.
- **The levels and the apparatus legend are rendered from the same tables the app parses with.**
  `AlarmLevel.levels` and `DispatchedUnit.documentedApparatus` were added for it, and
  `AlarmLevel.meaning(for:)` now reads from the list rather than from a dictionary beside it —
  so the screen and the rest of the app cannot come to believe different things about what a
  `2` means.
- **The counting note is the one that earns its place.** A reader sees *Alarm Level 2 = 10–14
  emergency vehicles* beside a roster of five tokens and concludes the app has miscounted. The
  City's own footnote — that support vehicles are not in that count — is the answer, and until
  now nothing in the app said it.
- **The City's page is linked wherever the attribution is, and the feed is not.** Put in the
  attribution sentence rather than added beside it on two screens: that sentence already named
  the page, and it already goes to Settings, the detail view and the About screen — so one
  change reaches all three, and they cannot come to disagree about the source of their own data.
  The page's name and address are interpolated from the package, so a page the City renames
  changes in one place. They are two different addresses for two
  different readers: `pageURLString` is a page a person can open, `urlString` is the XML the app
  reads. The feed is undocumented and was never offered to people, so linking to it would be
  inviting someone to read a document that was never meant for them — and would advertise an
  endpoint the app deliberately asks for as little as possible.
- **Links are blue, wherever a link appears.** Three screens now draw text containing one, so
  the colour lives in `LinkedText` rather than at each call site: three screens should not be
  able to disagree about what a link looks like. `AttributionText` became a thin wrapper around
  a wrapper and was removed rather than kept.

- **The City's `10-14` stays `10–14`.** Their list uses a hyphen and the app uses an en dash.
  Ours is typographically right and theirs is what they published; the difference is a
  deliberate one, not a transcription slip.
- **Settings holds preferences; everything else sits behind a row.** The version, the app's own
  description and the attribution had collected into sections of Settings, which is a screen for
  *choosing* things and had become a screen for reading them too. Settings keeps its two pickers and
  gains one row — *About* — with a chevron, and what a reader might want to read lives one push
  away. That is the judgement this project had already made once for *About this Data*, applied to
  the rest of what had gathered here.
- **Two About screens, because they answer different questions.** *About* is about the app: its
  icon, its name, which version is in the reader's hand, what it is for, and the City's page it
  reads. *About this Data* is about the feed: what each field means, and the licences the data and
  the postal-area shapes come under — and it is reached from the **info button** beside Settings
  rather than from *About*, which has no row to it. A second way in would be a second place to keep
  the same list true, and the licences have one home already.
- **The one external link on *About* says whose it is.** It sits under a header naming the City,
  with a footer saying that the app only reads what they publish and is not affiliated with them.
  An About screen is about *this* app, so a row that opened somebody else's page without saying so
  would be a mistake the reader has no way to avoid making.
- **The icon is the artwork the Home screen uses**, from the imagesets the icon previews already
  load, clipped on the same continuous corner the system uses — about 22.4% of the edge — and the
  dark variant in dark mode, because that is the one the Home screen is showing at the time. No
  `UIImage(named: "AppIcon")`, which is a trick the documentation does not promise.
- **The source repository is not linked, and that is a fact about the repository rather than a
  preference.** `github.com/Scorpio4938/TorontoLiveEMS` answers **404** to anyone not signed in as
  its owner — checked, with the account itself answering 200 to the same request — so a row
  pointing at it would be a link a reader cannot open. It belongs in *About* on the day the
  repository is public, which a release will make it.
- **Everything on *About* is read rather than typed**: the name from the bundle, the version from
  the bundle, the artwork from the asset catalogue, the City's page from the package. The app sets no `CFBundleDisplayName`, so its name
  there is the target's — `TorontoLiveEMS`, without the spaces it is called by in prose. Setting
  `INFOPLIST_KEY_CFBundleDisplayName` to *Toronto Live EMS* is the whole of that change, and then
  the row and the Home screen agree without either being told.

## The map

> **Superseded on 2026-10-01.** Everything below describes the design that was built and
> then abandoned before the reset: refresh in the top bar, the geocoder in `@Environment`,
> the feed and the geocoder both living at the root. See *The bar and the map page* at the
> end of this file for what replaced it. It is kept because the reasoning is still worth
> reading — and because one line of it, the environment, contradicted a rule this project
> already held: `@Environment(Type.self)` traps when the key is missing rather than
> degrading.
>
> One thing in it was never wrong: a map that fetched on its own could disagree with the
> list. That survives as the feed model living in one place.

- **Two screens, and a `TabView` between them.** Apple's `Tab` API, not a segmented picker: a
  segmented control filters content rather than navigating between places, and the tab bar is
  what a reader already knows. The app's root is the tab view; the feed and the geocoder live
  there rather than in either tab, because a map that fetched separately from the list could
  disagree with it about what is happening.
- **Refresh moved to the top bar, on every platform.** It was a bottom-bar item on iOS, chosen
  when a thumb reaching it was the argument. The bottom belongs to the tab bar now, and two
  things claiming it is what "shouldn't conflict with the refresh button" was about.
- **Pins fill in as they resolve, and the map says how many are left.** Apple's geocoder takes
  one address string against a service with undisclosed limits, so thirty-five incidents arrive
  over some seconds. A reader counting dots against the list would otherwise find a discrepancy
  and no explanation.
- **The geocoder is in the environment, not passed down.** Three views use it and they are four
  levels apart; threading it through the ones between would give four chances to forget.
- **Apple's geocoder, and the current one.** `CLGeocoder` is deprecated at iOS 26 with the note
  "Use MapKit"; `MKGeocodingRequest` is what the app uses. Every call in the map code was checked
  against Apple's documentation or the SDK interface rather than remembered — which is how
  `MapScaleView()` was caught: two initialisers, both fully defaulted, so the natural call is
  ambiguous.
- **A postal area is drawn as a circle, never a pin.** On the live capture that is 9 of 15
  incidents, so it is most of the map rather than a courtesy.
- **The detail map's frame becomes the location's own.** Zoomed in for a pin and backed off for
  an area, so a circle sits inside the frame instead of being cropped by the edges and reading
  as a pin that failed to load.

## Values

- **Human-rendered, not raw pass-through.** The City's table cells apply zero
  transformation and put all readability in a footnote legend; we render values
  readably and carry the explanation inline.
- **Dispatch Time is formatted**, not the raw ISO string the City displays with
  its `T` intact. The reader chooses between the City's own 12-hour form and a 24-hour
  one in Settings; 12-hour is the default because it is what the City publishes.
- **There are two settings** — how the incidents are arranged, and how the time of day is
  shown. Both are reached from a toolbar button shaped exactly like the refresh button, and
  both are stored with `@AppStorage`, the platform's own preference store, behind a
  `RawRepresentable` enum — no settings model, no synchronisation, because there is nothing
  to synchronise.
- **"Not published" has four shapes, and all four become nothing.** An empty element
  (`<cross_streets/>`); a missing element (`units_disp`, roughly one incident in five); the
  XML-escaped space the City sends for a Prime Street it will not publish
  (`<prime_street>&#x20;</prime_street>`); and a **punctuation placeholder** —
  `<cross_streets> / </cross_streets>`, a bare slash standing in for an intersection.
  The rule is *no letter and no digit means no value*, not a check for each shape, because
  the feed has produced four already and a fifth is a matter of when.
- **The fourth was found in a live capture on 2026-09-30, and it had gone unnoticed.** A slash
  survives a trim, so it read as a real intersection; the address fallback then offered a bare
  `/` as a location, with the mark for a substituted address sitting on top of it. The
  captured snapshot had the escaped space paired with a *real* intersection every time, so the
  one row where the fallback had nothing to fall back to was the one row missing from it.
- **Dispatched Units are decoded in the detail view, and left raw in the table.**
  Decoding uses the City's own legend — `P` Pumper, `R` Rescue, `A` Aerial, `T` Tower,
  `PL` Platform, `S` Squad, `HR` Highrise, `HZ` HazMat, `FB` Fireboat, `CMD` Command
  Vehicle, `C` Chief, `LA` Air Light, `TRS` Trench Rescue Support, `WT` Water Tanker,
  `HS` Haz Support, `Sup7` and `Box12` Canteen, `DE` Decon, `MP` Mini Pumper,
  `FI` Fire Investigator. That is the City's vocabulary, not ours. The table keeps the
  published tokens — `P231, P234` — because it has the least room and the detail view is
  one tap away.
- **A unit the feed publishes twice is shown once.** The roster is read through one rule in
  `DispatchedUnit`: identity is the trimmed token compared case-insensitively, the first
  occurrence keeps its place, and the published order survives. The correction is silent — a
  source glitch the reader can do nothing about is not worth a sentence — and it is applied
  where the roster is read, not to the payload. The stored `dispatchedUnits` string stays
  exactly as the City sent it.
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

## The reference section

**Recorded on `feat/home-screen` before the reference pages were finalised.** The
reference section answers *what is this number* — an Area, a station, a unit, a
division — and it is deliberately the quietest part of the app.

- **Home is a directory, not a dashboard.** Its job is to get a reader to a
  catalogue. It is a platform `List` with two service sections, a count trailing each
  row, a Sources section, and the same two provenance lines the Fire and Police tabs
  lead with, at the bottom. There is **no masthead and no mark**: About already carries
  the icon and the app's name, and a second identity block on a screen whose only job
  is navigation would be an element that exists to fill space. The navigation title is
  enough. The counts are trailing values, not badges or charts: they say how large a
  catalogue is, not how it is doing.
- **Sources are a section, not a footer.** They are destinations; a reader should be
  able to tap them. Provenance is the last section because it is context for the rows
  above, not a link. The five sources are named with their own licences — the City's
  fire data and its three reference datasets under Toronto's open licence, the
  Service's calls under Ontario's — rather than lumped under one licence that would be
  wrong for two of them. The ticket that asked for the credit parenthesised both live
  feeds as Ontario's; the fire feed is the City's, and the licence the app has stated
  since ADR-0001 is Toronto's.
- **Area is a run area, not a nearest station.** The City's run-area data has 84 areas
  numbered like the 84 stations, and the number does not claim which station responded;
  in our own capture it matched a dispatched unit about half the time. The interface
  says *the run area the City files the incident under, numbered as its station*, and
  the Area row opens that station's page. The glossary says the same.
- **A catalogue can be a list or points, never a coverage map.** The Stations and
  Divisions catalogues offer a List/Map toggle; the map draws one pin per published
  point and no boundary or polygon, because the reference data is points only. The
  camera and the open card survive the toggle, so a reader does not lose their place.
  The choice is a menu on the catalogue's own title, not a control in the shared trailing
  chrome: the Info/Settings capsule already occupies that corner on every page. Units have
  no map: a unit has no location of its own, and its station's coordinate is not the
  unit's.
- **Pins behave like the live map's, not like a second map.** Nothing is tagged and the
  map's own selection is not used. A tap becomes a point, the nearest pin within the
  same 22-point radius wins, the card is drawn inside the map on the same glass
  surface, and a tap on nothing dismisses it. The card opens the entity's page.
- **A station page carries no roster and no photographs.** The City's station file
  publishes the number, address, municipality, year built, ward, offices and a point;
  it publishes nothing about what apparatus is parked there and no imagery. A roster
  would be an inference from dispatch history or a guess, and a photograph would be an
  external asset with rights of its own. The page shows the published facts, a
  one-pin locator, and the catalogue's cross-reference of unit codes whose station is
  this one — which is not a roster of what is parked there. That distinction is the
  directory's whole premise: it says what it knows and nothing else.

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

## The bar and the map page

**Decided on 2026-10-01, on `feature/tab-bar-and-map`. Not built yet.** Written down before
the code, because the last attempt at the bar changed several things at once and could not
say which of them mattered.

- **iPhone is the only target for this work, and that is the diagnosis rather than a
  preference.** `sidebarAdaptable`'s own documentation: *"iPadOS displays a top tab bar that
  can adapt into a sidebar. iOS displays a bottom tab bar. macOS and tvOS always show a
  sidebar."* The last record of where Xcode was pointed names an **iPad simulator and a Mac**.
  There was never a bottom bar to find, in any of the six attempts.
- **The switcher is a `TabView` with two `Tab`s** — Incidents and Map. Not a segmented
  picker: a segmented control filters content, it does not navigate between places.
- **Refresh sits in the tab bar's trailing slot, as a `prominent` tab.** The request was for the
  shape Apple draws in Music and Books — the pages across the bar, one control set apart at its
  trailing end. That is `TabRole`, and it has **exactly two properties**: `prominent` (iOS 27)
  and `search` (iOS 18).

  **`search` was tried first and renders as an ordinary third item**, which is not the look: its
  documentation only promises that a `.search` tab *"may receive the prominent visual treatment
  by default."* `prominent` is the explicit request for that treatment, and using it is why
  `IPHONEOS_DEPLOYMENT_TARGET` moved to **27.0** — a `role:` argument cannot sit behind
  `if #available`, and the app is unreleased, so the cost is a number in the project file.
  Apple's words for the slot: *"a tab bar can include a dedicated search **tab** at the trailing
  end."* What *"in supported tab bars"* means is not yet known; the treatment may not apply to
  every tab bar style.

  **It is a tab, which means it selects, and that is a cost rather than a detail.** No API puts a
  non-navigating control in that bar. So the tab sets the selection, `RootView` puts it straight
  back, and the refresh happens in between: the bar's selection is seen to move on every tap,
  and VoiceOver is told it is a tab. Kept because the alternative looked worse — a `.bottomBar`
  toolbar item **does not merge** with the tab bar and draws as a second bar, of its own height,
  above it. That was tried on an iPhone and looked at, which is the only reason it can be stated.

- **The accessory is not used, and is the documented alternative.** Apple: the accessory can be
  *"moved inline with the tab bar"* when the bar is minimized on scroll — the Music MiniPlayer —
  and that remains the documented way to put a control in the same bar as the tabs. It was tried
  first, holding one button on a full-width strip, and read as a stray control on a blank band.
  If it is revisited it should carry the status line too, so that it has something to say.
- **The alert stays.** Kept deliberately, against the recommendation to remove it: it makes
  the window inert, and the code's own comment already calls that *"indistinguishable from
  the dead button reported earlier"*. Kept so that the first test of the bar changes one
  fewer thing. The consequence is recorded rather than hidden — if the window goes dead,
  there are two candidates and not one.
- **The first build is the bar alone** — the incidents tab real, the map tab a placeholder.
  Two real pages at once is how the earlier attempts became undiagnosable.
- **Info and Settings sit on both tabs**, declared once and applied by each. They are about
  the app and the data, not about the list, and a button that exists on one tab and vanishes
  on the other reads as a bug.
- **The feed state moves into the package** as an `@Observable` type, passed explicitly and
  never through `@Environment`. In the package because `swift test` cannot reach the app
  target, and the refresh flow is logic that deserves tests. `IncidentGeocoder` is the
  pattern already used here.
- **The root is `RootView`; `ContentView` becomes the incidents page.** The tab view, the
  accessory, the toolbar, the sheets and the alert are the app, not the content.
- **Every incident with a location is drawn** — a pin for a precise one, and the area the City
  published for a postal area.
- **The postal area is the real one, not a circle around a guess.** An FSA is drawn as Statistics
  Canada's boundary for it, generated into the package by `scripts/make_postal_areas.py`
  (Open Government Licence – Canada, and the attribution is shown in *About this Data* because it
  is required). The 1,200 m circle was an approximation drawn around wherever a geocoder landed,
  and it could spill into a neighbouring FSA or out into the lake — claiming ground the City never
  named. A postal area also needs **no geocoding at all** now, which removes a network round trip
  per postal incident: nine of the fifteen incidents in the live capture were postal areas.
- **One mark per place, not per incident.** The live capture holds fifteen incidents in
  thirteen places, with two postal areas holding two each. A mark per incident would stack two
  identical shapes and leave one incident unreachable from the map.
- **The map-kind switch lives in the shared chrome, and only while the map is showing.** Decided
  by a test build rather than in the abstract: the top-right capsule gains a third control behind
  `screen == .map`, placed at its **leading** end so that Info and Settings do not move when it
  appears — the capsule is trailing-aligned, so it grows leftward, and appending the control at the
  end would have shifted both by its width. The choice is a stored preference, which is what makes
  the arrangement cheap: the chrome writes it and the page reads it, and neither knows the other
  exists. What it costs is recorded too — one capsule now means two things, facts about the app and
  a setting about a map.
- **Two map modes.** Satellite is MapKit's *hybrid*: plain imagery has no labels at all, so a map
  with no street names was built, looked at, and rejected — the satellite view is the one with
  labels drawn over the imagery.
- **A third mode was built and removed.** Transit was the standard map with its points of interest
  limited to public transport — `PointOfInterestCategories.including([.publicTransport])`, a real
  API, checked before it was used — and on screen it made no difference worth having. It is
  recorded because the reasoning that produced it is still true and would produce it again:
  **MapKit has no transit lines.** `MKMapView` has `showsTraffic` and no `showsTransit`, Apple's own
  transit rendering is app-internal rather than an API, and filtering points of interest turned out
  not to be a transit view.
- **A menu, not Apple's bottom sheet.** Apple's chooser is that large because it carries *previews* —
  a thumbnail of each style, so you choose by looking rather than by reading. There are no thumbnails
  to show here: rendering one per option means snapshotting the map in each style, which is a network
  fetch per presentation to show a picture of the map the reader is already looking at. The sheet
  would be a large container holding three words, covering the thing it exists to change. The button
  wears the glyph of the kind in force, which is Apple's own behaviour and the reason the menu can be
  small.
- **The card is a callout anchored above the pin, and above an area's northern edge** — never at
  an area's centre, which is the claim ADR-0004 exists to refuse. For a published area that is the
  top of its own box, above the box's middle. Liquid Glass through `.glassEffect(_:in:)` alone;
  mixing it with `.buttonStyle(.glass)` produces two materials, which is what made the last bar
  look wrong.
- **The card carries no heading and no close button.** It had "2 incidents" and an `xmark`, which
  cost a whole row of height to say what the rows below already said and to offer a way out that
  tapping the map already is. Reported from a phone as too tall for what it held.
- **A tap decides everything, and only one thing decides it.** The map's own selection cannot
  select an overlay — a polygon tap produced a Metal drawable failure and no card — and where it
  can select, on an annotation, it raced this page's own gesture and produced a card that flashed
  and vanished. So nothing on the map is tagged, and every tap is turned into a coordinate and
  tested against the published shapes and then the pins. A tap that hits nothing clears the card,
  which is the dismissal: there is no control to reach for, because the tap already is one.
- **A postal area the boundary file does not know falls back to the circle, never to a pin.** The
  file is from the 2021 census, so an FSA created since then has no shape here. An approximation
  is still not a point, and a worse answer beats no answer.
- **Holes are kept, and travel with their ring.** Exactly one Toronto FSA (M6P) has one; the
  package keeps it rather than filling it, and the app draws it through `MKPolygon`'s interior
  polygons because `MapPolygon`'s coordinate initialiser takes a single ring.
- **Nothing published means nothing drawn, and no notice about it.** "Finding N more…"
  stays, because that is a loading indicator rather than a completeness notice.
- **The map tab shows the data's age.** Decided twice; the second time after reading the
  licence reason above, which is about the app rather than about the table.
- **Each screen owns its own geocoder** — the detail view and the map page resolve different
  sets, and nothing is threaded through the list types to reach a `NavigationLink`.
- **The map tab has no navigation bar; its title and controls float.** The band under the map
  page's header was the bar's own glass. An earlier fix made the map stop below the bar, and
  the report came back that nothing visible had changed. The build that then hid the bar
  entirely settled it: no bar, no band — and `toolbarBackgroundVisibility(.hidden)` does not
  remove that glass on this OS. The scroll-edge settings were no-ops for a plainer reason:
  those APIs configure scroll views, and the map page has none. The tab now takes Apple Maps'
  shape rather than Find My's: no bar over the map; the two controls float in a glass capsule,
  in label colour and centred in a bar's height so they sit where bar items sit —
  `.glassEffect` alone, per the callout decision above — and the page's name sits centred
  above the map as plain text, where the bar's inline title used to. Its first floating
  version was a capsule too, and that read as a button: the title is a name, not a control.
- **The top-right controls are one layer above both pages, like the tab bar.** Not a toolbar item
  on each page — one overlay on the tab view, `screenControlsLayer`, declared once and drawn
  above whichever page is showing. The tab bar is the model and the argument: it is not part of
  either page, the container draws it, and that is why it cannot differ between them. Apple
  provides no top-side equivalent — `tabViewBottomAccessory` is the only accessory API and it is
  the bottom — so an overlay on the container is how that arrangement is reached.
- **The police page's window has no control of its own.** The capsule carried a clock menu for it,
  which covered the page's header; the window is settable in Settings, so that second route was
  removed and Settings is now the only writer. The old rationale — that two routes to one preference
  cannot disagree — went with the control: one route cannot disagree with itself, and the default is
  stated once in `PoliceCallWindow.policePageDefault`, read by Settings and the page alike. What the
  page shows of the window now is the fold row counting the calls held back, which is accepted: the
  reader chose the window, and the fold already says older calls exist.
- **The platform's compass is kept clear by padding the map's safe area — to be checked on a device.**
  Rotated away from north, `MapCompass` appears in the map's top-trailing corner, under the app's
  capsule. There is no placement API for it — one initialiser, no alignment, and `mapControls` shows
  or hides every control at once. The first attempt reserved a transparent strip with
  `safeAreaInset`; the strip sat between the `MapReader` and its tap gesture, and tapping incidents
  became unreliable at the same time, so it was withdrawn. The second attempt adds the capsule's
  band to the map's safe area with `safeAreaPadding` instead, which keeps the map's frame — but the
  padded origin meant a tap's local point and the proxy's local conversion no longer agreed, so taps
  landed above their target. The tap and both proxy conversions now use `.global`, which the padded
  map and the reader share. **Whether the platform reflows the compass below the capsule has not
  been seen on a device.** If it does not, delete the compass and record the cost to north-reset
  beside the remaining controls. A hand-rolled compass is not the platform's control, and a rotation
  gesture is a poor north-reset.
- **That is the end of a long road, and it is worth recording** because each step was a real
  hypothesis and most were wrong. Two toolbar items were tuned to match by numbers. The bar's
  items were then assumed to be the reference and the capsule was shrunk to them. Then the capsule
  was made the reference and the bar's items were given its metrics. Then the whole capsule was
  hosted *in* the bar, with `sharedBackgroundVisibility(.hidden)` — a real API that really does
  suppress the platform's glass — which made the pages *less* alike, because the platform pads a
  custom item and a wide item pushes a centred inline title. Then the shared controls were made
  sizeless, which restored the title. Every one of those tried to reconcile two renderers, and two
  renderers cannot be reconciled. One layer cannot disagree with itself.
- **What the bars keep.** The incidents page keeps its navigation bar and its centred title; the
  map page keeps its hidden bar and its floating name. On iOS the bars simply no longer hold these
  two controls, and a detail view pushed from either page gets them from the same layer rather
  than from its own bar. On the platforms whose window toolbar is the right place for them,
  nothing changed — the bar behaviour this avoids is an iOS bar's.
- **A toolbar item's content must not size itself.** The title came to sit to the left because
  the shared controls carried a `.frame(width: 34, height: 34)` and a `.font(.title3)`: a content
  view larger than the platform's own makes the platform's toolbar item larger too, and a wide
  trailing item pushes a centred inline title off centre. The same measurements had been copied
  into the bar from the floating capsule, which is the mistake in miniature — the capsule's size
  is the capsule's, and it is made by its padding, not by the icons. The controls now carry no
  size at all: the bar sizes them, and the map's capsule is as chunky as its padding says.
  What that
  costs is written here too: floating controls are not toolbar items, so they are declared in
  `RootView` beside the sheets they open, and a detail view pushed from a callout carries its
  own bar — which is also what carries that view's back button.

- **The list page is named for whose data it is.** It was "Incidents", which was true while there
  was one feed and stopped being true the moment a second was planned. The screen and its tab are
  **Fire** now, and its title is **Active Fire Incidents** — because the feed is Toronto Fire
  Services', whose own page for it is *"Toronto Fire Active Incidents"*, and because a police feed
  is coming which will want a screen of its own. Two list screens cannot both be titled "Active
  Incidents", and naming each by its source is what tells them apart.
- **The tab is short and the title is not, on purpose.** The tab is a label in a busy bar, so it is
  one word; the title is a sentence above the table, where there is room to say whose incidents
  these are and that they are active. A title of just "Fire" says less than the screen knows.
  **The map keeps its generic name**, and for the same reason: it is not a feed's screen, and when
  the police feed arrives it will show both.

**Unverifiable on this machine, to be checked on the Mac:** MapKit. There is no MapKit
`.swiftinterface` here, so `Map`, `MapCircle`, `Annotation`, `.annotationTitles`,
`.safeAreaPadding` on the map and `MapCompass` are evidenced only by code that has already
compiled in this project. For the same reason selection is done with `.onTapGesture` on the
annotation content — plain SwiftUI — rather than `MapSelection`. What has to be looked at on a
device is both whether the compass is reflowed below the capsule and whether map taps still land.
