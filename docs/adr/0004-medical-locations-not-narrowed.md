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
- **Medical incidents have no mappable point.** This, not a layout preference, is
  the real reason the app has no map.
- **This is a no, not an unbuilt yes.** The station code sits in the model and looks
  available; it is deliberately not used for this.
