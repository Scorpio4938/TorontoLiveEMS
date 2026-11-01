# Changelog

Every version this project has, newest first. A checkpoint and a release are the same kind of
entry here — the only question a reader has is what happened most recently.

**Each entry is a list of what changed, one thing per line** — a screen, a control, a rule, a property —
and each line names the commit that finished it. Where a change spans several commits, the hash is
the last of them: the one that left the thing working.

**A line may also name the issue it came from**, where one existed. The two recent batches were
filed as issues before they were built — the five fixes in `v0.0.18` and the information pass in
`v0.0.19` — and three earlier campaigns had tickets too. Most lines have none, because for the
first dozen versions the work happened before there was a tracker to file it in, and inventing a
number afterwards would be worse than the gap.

**A line with no commit is not a change.** Three are states or gaps rather than work — that v0.0.1
builds, that v0.0.13 had no filter yet, and that v0.0.18's pin callout still flips — and a gap has
nothing to point at. They are kept because what a version was *missing* is part of what it was.

**Every version here was built, run, and had its tests run — unless its entry says otherwise.** That
silence is the convention, not an oversight: an entry only mentions building or testing when one of
them did not happen, which is why the one version that does not build says so in its own notes.

The exception is worth keeping because it was expensive. Seven consecutive commits once could not
build while Xcode kept running the last binary it had, and reports during that window described an
app that no longer existed. Believing a version was good when it was not is the mistake this file
exists to prevent.

**The commit is the one the tag points at** — `git rev-parse <tag>^{commit}` — not necessarily the
commit that bumped the number. Where those differ, the tag is what a version means.

## v0.0.20

`496e082`

- A detail reached from the map shows Info + Settings; Info opens the incident's own information · `c4fd378` · [#47](https://github.com/Scorpio4938/TorontoLiveEMS/issues/47)
- The map tab's navigation path drives the capsule: it shrinks at push and expands at pop · `bc5d5fd` · [#47](https://github.com/Scorpio4938/TorontoLiveEMS/issues/47)
- The capsule expands and shrinks with a spring, scaling and sliding toward its trailing edge · `bc5d5fd` · [#47](https://github.com/Scorpio4938/TorontoLiveEMS/issues/47)
- Changelog entries name the commit that finished each change, and the issue where one exists · `ec88c27`
- Known: an interactive back-swipe expands the capsule when the pop completes — [#47](https://github.com/Scorpio4938/TorontoLiveEMS/issues/47)

## v0.0.19

`4980cf0`

- Settings grouped by what a setting affects: Display, Police, About · `b5b2f2a` · [#36](https://github.com/Scorpio4938/TorontoLiveEMS/issues/36)
- About rebuilt for both sources: the version in a row, the two source pages, the repository, an App
  Licence placeholder · `ce0519b` · [#38](https://github.com/Scorpio4938/TorontoLiveEMS/issues/38)
- Data Licences: an index, with a page each for Fire data, Postal areas and Police data · `dae620f` · [#39](https://github.com/Scorpio4938/TorontoLiveEMS/issues/39)
- Each licence page links its actual source and carries the publisher's full licence text · `c16aeac` · [#39](https://github.com/Scorpio4938/TorontoLiveEMS/issues/39)
- A data screen's one-sentence notice opens that index · `f6daf23` · [#39](https://github.com/Scorpio4938/TorontoLiveEMS/issues/39)
- The map's legend prose shortened, and it no longer counts the symbols · `871f5e0` · [#37](https://github.com/Scorpio4938/TorontoLiveEMS/issues/37)
- Package tests pinning the three licence texts and the postal boundary file's source · `c16aeac` · [#39](https://github.com/Scorpio4938/TorontoLiveEMS/issues/39)

## v0.0.18

`35921d2`

- Both pages list their own feed newest first · `141c305` · [#20](https://github.com/Scorpio4938/TorontoLiveEMS/issues/20)
- The police refresh skips only on an unchanged as-of stamp — a write landing after a read is
  fetched rather than refused · `f9d9766` · [#21](https://github.com/Scorpio4938/TorontoLiveEMS/issues/21)
- A duplicated apparatus token is shown once · `aeba124` · [#22](https://github.com/Scorpio4938/TorontoLiveEMS/issues/22)
- The police page's clock control removed; Settings is the only route to the window · `3075a76` · [#24](https://github.com/Scorpio4938/TorontoLiveEMS/issues/24)
- Map taps converted in the window, so the padded compass clearance no longer offsets them · `140fcbd` · [#23](https://github.com/Scorpio4938/TorontoLiveEMS/issues/23)
- Known: the pin callout still flips above and below its pin — [#34](https://github.com/Scorpio4938/TorontoLiveEMS/issues/34)

## v0.0.17

`e00c1fe`

- The police page shows the last hour, folding the rest behind `Earlier calls · n`, strictly · `34acfad`
- The map gets a window of its own — one hour or four — and always keeps criticals · `66bd50b`
- Settings sets the page's window · `2894a82`

## v0.0.16

`4e6ccb1`

- The filter: All, Fire Only or Police Only, in the chrome, its glyph following the choice · `4de11d8`
- `map` in place of `map.fill` · `71e24b5`
- Three more police codes, a stabbing among them · `2bbff33`

## v0.0.15

`676b395`

- Pins legible after dark · `e4e296e`
- Twelve more police codes, a robbery and a knife among them · `9fd546d`
- The map's info button opens a legend of symbols and colours instead of the fire feed's data page · `8958fe4`

## v0.0.14

`3eb936f`

- Three tones — dark red, orange, and grey for the majority — over four severities · `2fff7f9`
- Police severities inferred from its call codes, `unknown` for a call nobody named · `2fff7f9`

## v0.0.13

`df4168a`

- Police calls on the map, grouped by point, each pin wearing its kind's symbol · `d88e2c9`
- One shared mark vocabulary, produced by both feeds · `026d231`
- The map tab's refresh asks both feeds · `d88e2c9`
- Not yet: a filter, so a busy window puts a hundred pins on one map

## v0.0.12

`f03a401`

- A static code list behind every code · `352adb1`
- The reader's choice of the Service's words or its code in the table · `581e1cc`
- An information screen that is fields and licence · `b46f71c`

## v0.0.11

`294c44c`

- A second source and a second tab: police calls · `646a784`
- Over the same table and cards as the fire page, differing only in columns, detail screen and data · `b48b5f7`

## v0.0.10

`1f4d003`

- Settings shows the version, the build and the stage · `1f01710`
- The build number back where it was, with a sentence saying which number is which · `970c11d`

## v0.0.9

`58668fe`

- One number for the version: `MARKETING_VERSION`, the tag, and what Settings shows · `58668fe`
- A check that keeps them agreeing · `58668fe`
- The first tag whose own tree carries its number · `58668fe`

## v0.0.8-fire-page

`aa130e7`

- The incidents page renamed and retitled Fire · `54add82`
- A fire extinguisher on its tab · `9ac4afb`

## v0.0.7-map-kinds

`d76a13d`

- Standard and Satellite, chosen from a control in the shared chrome · `6859df1`

## v0.0.6-postal-areas

`f5c770d`

- A postal area drawn as the boundary Statistics Canada publishes, instead of a circle around a
  geocoder's guess · `c931aa4`

## v0.0.5-map-page

`f648162`

- The map page · `8e087d0` · [#19](https://github.com/Scorpio4938/TorontoLiveEMS/issues/19)
- The chrome above both pages as one layer · `77c2e24`

## v0.0.4-two-tabs

`660f4a4`

- The bottom tab bar, with refresh as the prominent trailing tab · `5d6f70a` · [#16](https://github.com/Scorpio4938/TorontoLiveEMS/issues/16), [#17](https://github.com/Scorpio4938/TorontoLiveEMS/issues/17)

## v0.0.3-bar-and-cards

`3cb40f2`

- The bottom bar · `e632002`
- The switcher · `0003773`
- The cards arrangement · `f5b37bf` · [#13](https://github.com/Scorpio4938/TorontoLiveEMS/issues/13)
- The general map page · `8e087d0` · [#19](https://github.com/Scorpio4938/TorontoLiveEMS/issues/19)

Kept on `archive/everything-since-v0.0.2` rather than on `master`.

## v0.0.2

`d1ea109`

- A version row · `d1ea109`
- `ToolbarSpacer` where a `Spacer` was · `d1ea109`

**It does not build.** `ToolbarSpacer` was put inside a `ToolbarItemGroup`, whose content is a
`ViewBuilder`, and `ToolbarSpacer` conforms to `ToolbarContent` rather than `View`. Every commit
through `065e326` inherits the fault; `1732bd5` fixes it.

## v0.0.1

`e98d13d`

- Builds, and is a working point

From before the design work, so rougher than `master`.
