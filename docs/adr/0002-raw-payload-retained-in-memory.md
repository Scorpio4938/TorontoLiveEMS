# The raw payload is retained whole, reduced only at render

The app parses every field the feed publishes, holds the values in memory
unreduced, and reduces them only when rendering. Nothing is normalised away at the
boundary, and no field is discarded because the current UI does not display it.

This is why `Incident Number` and `Area` remain in the model while being absent
from the compact table, and why the detail view can show the City's verbatim
strings (`2026-09-28T13:06:52`) alongside our formatted ones.

Modelling only the six displayed fields would be simpler. We rejected it because it
closes doors permanently:

- **`Incident Number` is the only stable identity in the data.** Without it an
  incident cannot be recognised across two polls, so *new* and *cleared* are
  undetectable and no history is possible. Its number rises with dispatch order,
  so it also orders incidents by recency.
- **`Area` (the nearest fire station) is the only link from a medical incident to
  anything geographic**, because medical locations are blurred to FSAs.

Consequences we accept:

- **Nothing persists.** The model lives in memory for the session only, so the app
  forgets everything on quit. This is deliberate — it keeps the app a mirror of a
  live feed rather than a dataset. Adding persistence later is a bolt-on, which is
  what makes the decision cheap to revisit.
