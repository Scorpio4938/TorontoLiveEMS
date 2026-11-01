# Changelog

Every version this project has, newest first. A checkpoint and a release are the same kind of
entry here — the only question a reader has is what happened most recently.

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

The information work. Settings is grouped by what a setting affects: Display, Police and About.
About is rebuilt for both sources, with the version in a row, the two source pages, the repository
and an App Licence placeholder. Data Licences is an index with a page for Fire data, Postal areas
and Police data; each page links its actual source and carries the publisher's full licence text,
and the one-sentence notice on a data screen now opens that index itself. The map's legend prose is
shorter and no longer counts the symbols. Package tests now pin the three licence texts and the
postal boundary file's source.

## v0.0.18

`35921d2`

Both pages list their own feed newest first. The police page's refresh skips only on an unchanged
as-of stamp, so a write landing after a read is fetched instead of being refused. A duplicated
apparatus token is shown once. The police page's clock control is gone, with Settings the only route
to the window. Map taps are converted in the window, so the padded compass clearance no longer
offsets them. The pin callout still flips above and below its pin — #34.

## v0.0.17

`e00c1fe`

Recent by default. The police page shows the last hour and folds the rest behind `Earlier calls · n`,
strictly: a serious call outside the window folds with the rest. The map has a window of its own —
one hour or four — and always keeps criticals. Settings sets the page's window.

## v0.0.16

`4e6ccb1`

The filter: All, Fire Only or Police Only, in the chrome, its glyph following the choice. `map` in
place of `map.fill`, and three more police codes, a stabbing among them.

## v0.0.15

`676b395`

The pins are legible after dark. Twelve more police codes are known, a robbery and a knife among
them, and the map's info button opens a legend of its symbols and colours instead of the fire feed's
data page.

## v0.0.14

`3eb936f`

The map stops shouting: three tones — dark red, orange, and grey for the majority — over four
severities, the police's inferred from its call codes and `unknown` for a call nobody named.

## v0.0.13

`df4168a`

Police calls on the map, grouped by point, each pin wearing its incident kind's symbol, over one
shared mark vocabulary that both feeds produce. The map tab's refresh asks both. No filter yet, so a
busy window puts a hundred pins on one map.

## v0.0.12

`f03a401`

The police page finished: a static code list behind every code, the reader's choice of the Service's
words or its code in the table, and an information screen that is fields and licence without padding.

## v0.0.11

`294c44c`

The police page. A second source and a second tab over the same table and cards as the fire page, so
the two feeds share one presentation layer and differ only in their columns, their detail screen and
their data.

## v0.0.10

`1f4d003`

Settings says the version, the build and the stage: the build number back where it was, and the
sentence under it explaining which number is which.

## v0.0.9

`58668fe`

One number for the version — `MARKETING_VERSION`, the tag and what Settings shows — and a check that
keeps them agreeing. The first tag whose own tree carries its number.

## v0.0.8-fire-page

`aa130e7`

The incidents page renamed and retitled Fire, and a fire extinguisher on its tab.

## v0.0.7-map-kinds

`d76a13d`

Standard and Satellite, chosen from a control in the shared chrome.

## v0.0.6-postal-areas

`f5c770d`

A postal area drawn as the boundary Statistics Canada publishes, instead of a circle around a
geocoder's guess.

## v0.0.5-map-page

`f648162`

The map page, and the chrome above both pages as one layer.

## v0.0.4-two-tabs

`660f4a4`

The bottom tab bar, with refresh as the prominent trailing tab.

## v0.0.3-bar-and-cards

`3cb40f2`

The design work after `v0.0.2`: the bottom bar, the switcher, the cards arrangement, the general map
page. Kept on `archive/everything-since-v0.0.2` rather than on `master`.

## v0.0.2

`d1ea109`

A version row, and `ToolbarSpacer` where a `Spacer` was. **It does not build.** `ToolbarSpacer` was
put inside a `ToolbarItemGroup`, whose content is a `ViewBuilder`, and `ToolbarSpacer` conforms to
`ToolbarContent` rather than `View`. Every commit through `065e326` inherits the fault; `1732bd5`
fixes it.

## v0.0.1

`e98d13d`

Builds. From before the design work, so rougher than `master`, but it is a working point.
