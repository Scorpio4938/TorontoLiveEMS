# Changelog

Every version this project has, newest first. A checkpoint and a release are the same kind of
entry here — the only question a reader has is what happened most recently.

**Each entry is a list of what changed, one thing per line** — a screen, a control, a rule, a property.
Prose is where a reason is needed; the list is where the fact is.

**Every version here was built, run, and had its tests run — unless its entry says otherwise.** That
silence is the convention, not an oversight: an entry only mentions building or testing when one of
them did not happen, which is why the one version that does not build says so in its own notes.

The exception is worth keeping because it was expensive. Seven consecutive commits once could not
build while Xcode kept running the last binary it had, and reports during that window described an
app that no longer existed. Believing a version was good when it was not is the mistake this file
exists to prevent.

**The commit is the one the tag points at** — `git rev-parse <tag>^{commit}` — not necessarily the
commit that bumped the number. Where those differ, the tag is what a version means.

## v0.0.19

`4980cf0`

- Settings grouped by what a setting affects: Display, Police, About
- About rebuilt for both sources: the version in a row, the two source pages, the repository, an App
  Licence placeholder
- Data Licences: an index, with a page each for Fire data, Postal areas and Police data
- Each licence page links its actual source and carries the publisher's full licence text
- A data screen's one-sentence notice opens that index
- The map's legend prose shortened, and it no longer counts the symbols
- Package tests pinning the three licence texts and the postal boundary file's source

## v0.0.18

`35921d2`

- Both pages list their own feed newest first
- The police refresh skips only on an unchanged as-of stamp — a write landing after a read is
  fetched rather than refused
- A duplicated apparatus token is shown once
- The police page's clock control removed; Settings is the only route to the window
- Map taps converted in the window, so the padded compass clearance no longer offsets them
- Known: the pin callout still flips above and below its pin — #34

## v0.0.17

`e00c1fe`

- The police page shows the last hour, folding the rest behind `Earlier calls · n`, strictly
- The map gets a window of its own — one hour or four — and always keeps criticals
- Settings sets the page's window

## v0.0.16

`4e6ccb1`

- The filter: All, Fire Only or Police Only, in the chrome, its glyph following the choice
- `map` in place of `map.fill`
- Three more police codes, a stabbing among them

## v0.0.15

`676b395`

- Pins legible after dark
- Twelve more police codes, a robbery and a knife among them
- The map's info button opens a legend of symbols and colours instead of the fire feed's data page

## v0.0.14

`3eb936f`

- Three tones — dark red, orange, and grey for the majority — over four severities
- Police severities inferred from its call codes, `unknown` for a call nobody named

## v0.0.13

`df4168a`

- Police calls on the map, grouped by point, each pin wearing its kind's symbol
- One shared mark vocabulary, produced by both feeds
- The map tab's refresh asks both feeds
- Not yet: a filter, so a busy window puts a hundred pins on one map

## v0.0.12

`f03a401`

- A static code list behind every code
- The reader's choice of the Service's words or its code in the table
- An information screen that is fields and licence

## v0.0.11

`294c44c`

- A second source and a second tab: police calls
- Over the same table and cards as the fire page, differing only in columns, detail screen and data

## v0.0.10

`1f4d003`

- Settings shows the version, the build and the stage
- The build number back where it was, with a sentence saying which number is which

## v0.0.9

`58668fe`

- One number for the version: `MARKETING_VERSION`, the tag, and what Settings shows
- A check that keeps them agreeing
- The first tag whose own tree carries its number

## v0.0.8-fire-page

`aa130e7`

- The incidents page renamed and retitled Fire
- A fire extinguisher on its tab

## v0.0.7-map-kinds

`d76a13d`

- Standard and Satellite, chosen from a control in the shared chrome

## v0.0.6-postal-areas

`f5c770d`

- A postal area drawn as the boundary Statistics Canada publishes, instead of a circle around a
  geocoder's guess

## v0.0.5-map-page

`f648162`

- The map page
- The chrome above both pages as one layer

## v0.0.4-two-tabs

`660f4a4`

- The bottom tab bar, with refresh as the prominent trailing tab

## v0.0.3-bar-and-cards

`3cb40f2`

- The bottom bar
- The switcher
- The cards arrangement
- The general map page

Kept on `archive/everything-since-v0.0.2` rather than on `master`.

## v0.0.2

`d1ea109`

- A version row
- `ToolbarSpacer` where a `Spacer` was

**It does not build.** `ToolbarSpacer` was put inside a `ToolbarItemGroup`, whose content is a
`ViewBuilder`, and `ToolbarSpacer` conforms to `ToolbarContent` rather than `View`. Every commit
through `065e326` inherits the fault; `1732bd5` fixes it.

## v0.0.1

`e98d13d`

- Builds, and is a working point

From before the design work, so rougher than `master`.
