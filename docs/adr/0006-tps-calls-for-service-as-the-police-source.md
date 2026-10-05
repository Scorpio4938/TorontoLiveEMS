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
  contradicts itself, and two samples 14 and 17½ minutes old cannot settle it. So the app **shows
  the data's age and promises no cadence** — the fire feed's discipline, where the feed's own
  timestamp is the only thing the status line reads.

  > **Neither number is reproducible on 2026-10-05 either.** The item metadata today carries a
  > one-line snippet about the dataset and no cadence at all. The contradiction was read from
  > rendered text in the Service's web application. What the app says is what can be measured: a
  > call stays four hours, the screen shows when the app last read, and no cadence is claimed.
- **The layer does publish a last-edit time, and an earlier reading of it was wrong.** An earlier
  version of this file's companion code said the layer "carries no time info at all". It does: the
  layer's `editingInfo.dataLastEditDate` moves with the data — measured 2026-10-05 at 17:31:16Z,
  fifteen minutes old while the newest call the layer held was thirty. Gating a refresh on it is
  therefore *possible*, but it costs a **second request** to decide whether to make the first: a
  `query` cannot be asked for it, because `advancedQueryCapabilities` offers no `returnEditMoment`.
  So the gate stays off — one request per explicit refresh — and the status line still reads the
  app's own clock rather than quoting a Service time nobody asked it for.
- **Traps the client has to handle.** A time filter needs a literal: `OCCURRENCE_TIME > TIMESTAMP
  '…'` works and a bare millisecond number answers 400 — and the literal is read as **UTC**, which
  was measured too. A value standing in for nothing is recognised by the fire feed's own rule, that
  no letter and no digit means no value; a *one-sided intersection*, `"BONIS AVE - "`, has letters
  in it and is therefore kept **as published** rather than tidied — the dangling separator is a
  display question, not a parsing one.
- **The app asks for `f=json`, not `f=geojson`.** Both are offered, and GeoJSON *stringifies every
  attribute* — `OCCURRENCE_TIME` arrives as `"1791219259000"` — while Esri's own format keeps numbers
  as numbers. Nothing needs the geometry, because the point is published as two attributes, so the
  typed response is less code rather than more.
- **`returnCountOnly` is not supported**, so counting means fetching. At eighty records that is not
  a hardship.
- **Politeness.** It is a public service on somebody else's infrastructure, read on the fire feed's
  terms: once at launch, once per explicit refresh, and never on a timer of its own.
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
  mean, and the Ontario licence, in `Attribution.policeCalls`. Three licences, three providers,
  each stated where its own data is explained.
