# Toronto Police calls for service as the police incident source

Police incidents come from a **feature service** published by the Toronto Police Service on
ArcGIS Online:

```
https://services.arcgis.com/S9th0jAJ7bqgIRjw/arcgis/rest/services/C4S_Public_NoGO/FeatureServer
```

## It is an API, not a page

**The raw data is a JSON document at a URL, and the app reads it exactly the way it reads the
City's XML: one request, one response, one decoder. Nothing is scraped and no HTML is involved.**

The distinction matters because it is easy to mistake the two. The link a person finds is an
**item page** — `torontops.maps.arcgis.com/home/item.html?id=d6d48b3d9ccf42faa8e656b78f8289d3` —
which is a human interface. The item *declares* the machine endpoint above, and that endpoint is
part of the ArcGIS REST API, which Esri documents. A query looks like this:

```
<endpoint>/0/query?where=OCCURRENCE_TIME > TIMESTAMP '2026-10-05 15:00:00'&outFields=*&f=geojson
```

and answers with a GeoJSON `FeatureCollection` — or with Esri's own JSON when asked for `f=json`.
Both were fetched during this research, **anonymously**: no token, no API key, no account.

So the fetch is a data task and the parse is a decoder, which is what `LiveCADClient` and
`LiveCADParser` already do for the fire feed. The one difference in shape is that this endpoint is
asked a *question* — a `where` clause — rather than handed a fixed document.

**This is the opposite situation to ADR-0001.** The fire feed is an undocumented path found by
reading a page's inline JavaScript. This one is a published service, with a documented API, a
declared schema and written terms.

## What it carries

One point layer, nine fields, and **no geocoding**:

| field | meaning |
|---|---|
| `OBJECTID` | the row's identity |
| `OCCURRENCE_TIME` | when the call happened |
| `DIVISION` | the police division |
| `LATITUDE`, `LONGITUDE` | the point, in WGS84 |
| `CALL_TYPE_CODE`, `CALL_TYPE` | the call, as a code and as words |
| `CROSS_STREETS` | the nearest intersection |
| `OCCURRENCE_TIME_AGOL` | a second copy of the time, kept by the platform |

**The point is a published value, so the detail view shows it as numbers as well as a dot.** The
fire feed publishes a street and makes the app ask Apple where it is; this one publishes a latitude
and a longitude outright, and a published number is something a screen may state. The fire detail
view's map comes from a coordinate this app derived, which is why no coordinate appears there — a
number we worked out has no business being dressed as one the City sent.

**It is a four-hour rolling window.** The service held 80 records spanning 4.2 hours when it was
checked, oldest to newest, and the publisher's own description says a dot is visible for four
hours. So the whole of it arrives in one request and `maxRecordCount` of 2000 is never approached.
This is also the first source in this app that needs no geocoding at all: the Service publishes a
point, where the fire feed publishes a street and makes the app ask Apple where it is.

## Licence, and the restrictions that are design rules

**Open Government Licence – Ontario**, attributed to the Toronto Police Service. That is a third
licence — Toronto's for the fire feed, Canada's for the postal-area shapes, Ontario's here — so the
attribution screen carries all three. The clauses quoted below are read from the item's own
`licenseInfo` field rather than from memory: version 1.1, information provider "Her Majesty the
Queen in right of Ontario", and an exemptions clause granting no right to personal information at
all.

Two of the licence's restrictions are not footnotes, because they constrain what this app may be:

- **"Not to merge or link the information with any other databases for the purpose of attempting to
  identify an individual person, business, or organization."** Police calls are not correlated with
  the fire feed, or with anything else, to sharpen either. This is ADR-0004's rule, written by a
  licensor instead of by us.
- **"Not to present the information in such a manner that gives the appearance that you may have
  received … information held by the Toronto Police Service … about any identifiable individual
  person."** The police page presents calls *at places*, and nothing in it is person-shaped.

The publisher filters as well: calls are excluded for domestic violence, sexual assault and medical
distress, and for ongoing police operations. **A call that is not there is not evidence that
nothing happened** — so the police page has to read as a view of what was published, which is the
position ADR-0004 already takes for the fire feed.

> **The list itself could not be reproduced on 2026-10-05, and no screen repeats it.** It was read
> from the Service's public web application, whose text is rendered in the browser and cannot be
> fetched: the item and its layer both leave `description` empty, and the item's `licenseInfo` names
> no exclusion. What the app states is the **caution** above — that a call's absence is not evidence
> — and the police detail view says only that calls are published at an intersection. **Check the
> list in a browser before putting it on a screen again.**

## Consequences we accept

- **Twenty minutes, or five, or neither.** The item's summary says the data is updated every 20
  minutes; the application's own description says it is refreshed every five. The publisher
  contradicts itself, and two samples 14 and 17½ minutes old cannot settle it. The layer's own clock
  is the only measurable cadence (see the measurement below), and the app does not gate on it: a pace
  describes the publisher, and the calls on screen can be a write behind it. Twenty minutes survives
  as what the information screen states, not as a reason to skip a refresh.

  > **The item metadata carries no cadence on 2026-10-05, but the layer's own clock does.** The
  > contradiction above was read from rendered text in the Service's web application; the item and
  > its layer both leave `description` empty, and neither states a refresh interval. What *is*
  > measurable is the layer's edit time, and it moves with the data: sampled twice six minutes
  > apart, the stamp went from `17:31:16Z` to `17:50:47Z` — **19.5 minutes**, the first hard support
  > for the twenty-minute figure, and **one interval rather than a schedule.** Note the phase: the
  > stamp is not on a :00/:20/:40 grid, so the next change cannot be predicted to the minute, only
  > observed after the fact. That is why the app *asks* rather than counting down.
- **There is no published legend for the call type codes, so the app carries its own.** Checked
  everywhere one could have been: the item's `description` is empty, its `licenseInfo` is the licence
  alone, no field on the layer carries a coded-value domain, the service has no other layer or table,
  the Service's web application — **all 144 KB of its configuration** — contains no list of codes, and
  neither does any of **the 481 items in the Service's own ArcGIS organisation** or a portal search
  across the rest.

  What the Service does publish is both halves of the mapping, on every call. So the list was gathered
  from the calls themselves, once, and is **static**: `PoliceCallType.documented`, thirty codes from
  the ninety-six calls the Service held on 2026-10-05. Guessing is not even available as an option —
  `INDEX` means *indecent exposure* while `EXPJU` means *indecent exposure just occurred*, so the codes
  are not compositional.

  **A reference rather than a lookup, which is what makes an incomplete list harmless.** No screen
  resolves a call's code through it: the table and the detail view show the words the Service sent
  with the call, so a code missing from the list is still shown correctly on the call. A missing row
  costs a reader one unanswered question; it cannot make the app wrong. Both places that name a code
  lead to it — a call's detail view and the information screen — and the screen is the mapping and
  nothing else.
- **The status line is the fire line's shape, on the fire line's clock.** Fire quotes the City's own
  `2026-10-05 14:00:02` verbatim, which is Toronto wall-clock and unshifted by where the reader is.
  This Service publishes an *instant* and no string, so the app writes one:
  `2026-10-05 17:50:47`, rendered on **Toronto's** clock rather than the reader's, so that two lines a
  reader compares are in one shape and on one clock. The reader's 12- or 24-hour setting still governs
  the *calls*, where a table cell shows a time of day and a clock and a preference are what is wanted;
  this line states the age of the data, where a date is. Written by hand from calendar components
  rather than with a `DateFormatter`, for the reason this type gives throughout and one more: a
  formatter would put the calendar in a locale's hands, and a device set to a non-Gregorian calendar
  would render the Service's clock in a year the Service has never published.
- **The layer does publish a last-edit time, and the app compares the stamp it holds.** An earlier
  version of the companion code said the layer "carries no time info at all". It does:
  `editingInfo.dataLastEditDate` moves with the data — measured 2026-10-05 at 17:31:16Z, fifteen
  minutes old while the newest call the layer held was thirty, and again at 17:50:47Z, nineteen and a
  half minutes later. A `query` cannot be asked for it, because `advancedQueryCapabilities` offers no
  `returnEditMoment`, so it costs a request of its own: **10.5 KB, against 22.7 KB for the calls.**
  That price is paid on every refresh, and it is what makes a skip honest. The feed keeps the stamp
  the calls on screen were read under — the **as-of** — and reads the Service's latest stamp first.
  It skips the calls only when the two are equal: an unchanged stamp proves the Service has not
  written since those calls were read. A stamp that has moved is a write the screen has not fetched,
  and it is fetched; so is a stamp that could not be read, because there is then no proof at all.
  After the fetch the calls are compared with the calls that were there, because a stamp can move
  while the calls do not. What the status line and the "nothing newer" sentence quote is the
  **as-of**, not the latest stamp: the two differ the moment a write lands between two reads.
- **Traps the client has to handle.** A time filter needs a literal: `OCCURRENCE_TIME > TIMESTAMP
  '…'` works and a bare millisecond number answers 400 — and the literal is read as **UTC**, which
  was measured too. A value standing in for nothing is recognised by the fire feed's own rule, that
  no letter and no digit means no value; a *one-sided intersection*, `"BONIS AVE - "`, has letters
  in it and is therefore kept **as published** rather than tidied — the dangling separator is a
  display question, not a parsing one. And **the same address with and without `f=json` is two
  different things**: the layer answers a 10.5 KB JSON document when asked and an 8.8 KB HTML page
  when not, which is how the app came to say "an unknown time" with nothing visibly wrong — the URL
  had been written without it, and the one test on that URL asserted its *shape* rather than what it
  asked for. The layer's `dateFieldsTimeReference` also reports `{"timeZone":"UTC"}`, corroborating
  the literal's zone from the service's own metadata rather than from a measurement.
- **The app asks for `f=json`, not `f=geojson`.** Both are offered, and GeoJSON *stringifies every
  attribute* — `OCCURRENCE_TIME` arrives as `"1791219259000"` — while Esri's own format keeps numbers
  as numbers. Nothing needs the geometry, because the point is published as two attributes, so the
  typed response is less code rather than more.
- **`returnCountOnly` is not supported**, so counting means fetching. At eighty records that is not
  a hardship.
- **Politeness.** It is a public service on somebody else's infrastructure, read on the fire feed's
  terms: once at launch, once per explicit refresh, and never on a timer of its own. A refresh always
  reads the stamp — one 10.5 KB request — and fetches the calls only when that stamp is not the one
  the calls on screen were read under. So the common tap costs the metadata request and no calls, and
  a write the screen has not fetched is never refused. The client also gives up on a request in
  **fifteen seconds rather than sixty** and ignores the cache: sixty is what made an unreachable
  service look like a dead app, and a cached metadata response would hide a write and leave the
  screen stale.
- **A second feed, not a second list.** The police page owns its own client, its own clock and its
  own age. See `docs/design-decisions.md` for why the fire feed is not copied.

## What this does not decide

- **The page's name is decided: *Recent*, not *Active*.** These calls are not active; they are
  recent, within a four-hour window, and the fire page's word cannot be borrowed for them.
- **Four columns, not five.** Fire's compact table is fixed at five because its data has five
  things worth a column; police has four — Time, Call Type, Division, Cross Streets. The fifth was
  never missing: it does not exist. So the table's column count is a property of the source's
  column set rather than a constant of the layout, which is a change to the shared table rather
  than a decision about police.
- **The police information screen, and where the licence goes.** The information button on the
  police tab leads to a police screen, not to the fire one: what a call, a call type and a division
  mean. The licence is not there: each provider has a licence page behind *Data Licences*, reached
  from Settings and from the single-sentence notice each data screen carries. Three licences, three
  providers, one index.
