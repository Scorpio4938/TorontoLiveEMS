# Incident Category is derived from the CAD code prefix

The compact view shows a coarse Incident Category (`Fire`, `Vehicle`, `Rescue`)
rather than the City's Incident Type string. The category is derived from the CAD
code prefix the City itself assigns, recovered from the Open Data portal's
`Initial_CAD_Event_Type` field: the live feed emits those values **with the prefix
stripped**, so `FIR - Fire - Residential` arrives as `Fire - Residential`, and
`FIR` tells us the category. This is reading the City's own scheme, not imposing a
new one.

The trigger was measurement. Across the 69 distinct incident types:

```
minimum 7 characters   median 22   p90 33   maximum 45
```

The worst is `Carbon Monoxide - Non Medical - Non Emergency` at 45 characters. The
City's table gives Incident Type 12% width — on an iPhone that is roughly 43pt, or
about seven characters per line, so this would wrap to six or seven lines. The
City's own page escapes this only because a desktop browser has room; copying the
wrapping onto a phone would preserve an accident of their layout rather than their
design.

Truncation is worse than useless here: `Vehicle Accident - Trapped - Highway`
truncates to `Vehicle Accident - Tr…`, losing exactly the word that distinguishes
it from `Vehicle - Personal Injury`.

Consequences we accept:

- **The category is ours; the type is the City's.** Toronto publishes no
  incident-type mapping — the footnote legend on their page covers Alarm Level,
  Area and Dispatched Units only. The full Incident Type string is always
  available in the detail view.
- **`Alarm` stays separate from `Fire`.** The City's codes separate `FA*` (fire
  alarm) from `FI*` (fire) deliberately. `Alarm` is 15.58% of all incidents and
  `Fire` only 4.92%; merging them would label one row in five `Fire` when the
  Open Data `Final_Incident_Type` shows these are overwhelmingly benign
  (`Alarm System Equipment - Accidental activation`, `Alarm Equipment -
  Malfunction`, `Other False Fire Call`). Collapsing them would be inventing a
  taxonomy rather than reading the City's.
- **Unmapped types fall back to the raw string**, never to a blank or a guess, so
  a type the City adds later is never silently mislabelled.
