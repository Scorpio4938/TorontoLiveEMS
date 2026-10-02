# Medical incident locations are not narrowed

A Medical Incident's location is displayed exactly as the City publishes it — an
FSA — and the app does not attempt to sharpen it. We hold `Area` (the nearest fire
station) in the model, and the City publishes 84 fire-services run-area polygons,
so intersecting the two would yield a far finer location. We do not, and should
not.

The City aggregates medical locations deliberately, in its own words:

> As per MFIPPA section 31, 32 for the use and disclosure of personal information,
> to preserve privacy, the data has been aggregated to intersections and forward
> sortation areas (FSAs) for medical calls.

The Open Government Licence – Toronto then exempts from its grant both "Personal
Information" and "Information not accessible under the Ontario Municipal Freedom of
Information and Protection of Privacy Act". Narrowing a blurred location would not
merely exceed the licence — it would reconstruct the personal information the City
withheld.

Consequences we accept:

- **No re-identification by any route.** Not intersecting the FSA with a station or
  run area, not reverse-geocoding, not combining it with another dataset to sharpen
  it. The same applies to any source added later.
- **Medical incidents have no mappable point — only an area.** That is why the map
  draws one for them, and why no zoom will ever put a medical incident at a point.
- **This is a no, not an unbuilt yes.** The station code sits in the model and looks
  available; it is deliberately not used for this.

## The area is drawn as the area it is

An FSA is drawn as the boundary Statistics Canada publishes for it — the real shape,
clipped to Toronto and generated into the package by
`scripts/make_postal_areas.py` — and never as a mark at a point. That is not a
narrowing but its opposite: it shows the ground the City named, where a circle drawn
around a geocoder's answer could spill into a neighbouring FSA or out into the lake
and claim ground the City never named.

Three consequences, each easy to get wrong later:

- **A callout hangs from an area's northern edge, never its centre.** A card anchored
  at the centre would put the app's own pointer exactly where this ADR forbids one.
- **A postal area the boundary file does not know falls back to a circle**, never to
  a pin. The file is from the 2021 census, so an FSA created since then has no shape
  here; an approximation is still not a point.
- **A postal area no longer needs geocoding at all.** The boundary is in the bundle,
  so a postal incident costs no network — and with the lookup gone, so is the chance
  of Apple's answer and the drawn area disagreeing about where the incident is.

What this does not change is the rule itself: the location is shown exactly as
published. Before, that meant a circle around a point the City never published;
now it means the area it did.
