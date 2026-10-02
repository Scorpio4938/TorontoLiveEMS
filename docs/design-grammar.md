# The design grammar we were handed, and what we did with it

## Provenance — read this first

This document records an assessment of a description of an **"Apple visual grammar"**
that was supplied in conversation. That description was **AI-generated**. It is not
Apple's design guidance, and it should never be cited as such.

It presents itself as documentation — numbered items, bracketed references, phrases like
"Apple explicitly warns against…" and "Apple's current guidance also specifically
notes…" — and **not one of those attributions can be checked from this repository.** The
citations point at real Apple URLs, but they were retrieved by a language model and the
quoted claims are unsourced paraphrases at best. Treat every "Apple says" in the original
as the author's assertion.

None of that makes it worthless. Most of it is *directionally* consistent with Apple's
long-standing guidance, and it reached the right conclusion for this project — the app
targets a Liquid Glass-era SDK, which it correctly identified as the current direction.
It is simply not evidence, and the difference matters the moment somebody wants to settle
an argument by reference to it.

## What it is: a rubric, not a specification

Every item is a standard you can **judge** against, and almost none is an instruction you
can **build** from. "Extremely calm", "quiet, spacious, precise, confident",
"mathematically coherent", "a quiet piece of iOS itself" — these describe a feeling.
There is no diff for "calm".

So it has one real use: **a checklist to audit against.** Used that way it found
something, which is more than nothing. Used as a brief it would have produced nothing.

## Where it disagrees with itself, and with us

### 1. It contradicts itself on typography, exactly where it matters most to us

It asks for all of these at once:

- "strong contrast between primary and secondary information"
- "Secondary information — slightly smaller / less prominent"
- **"Avoid: tiny gray text everywhere"**
- **"never make the user struggle to read secondary information"**

The compact table is 11pt throughout. Applied literally, that advice produces a secondary
tier at 11pt — which is precisely the tiny grey text it forbids. Secondary label grey on
white at 11pt lands around 3.5:1, under the 4.5:1 that small text needs.

*That ratio is an estimate. Nothing in this repository can measure a colour, and it is the
shape of the argument that matters rather than the decimal: a second tier at this size has
less contrast than the first, not more.*

**At this size there is no room for a second tier.** Hierarchy in the table therefore has
to be built at a single size, through **weight** — or the table has to get larger, which
five columns on a phone cannot afford. This is recorded because the obvious reading of
the source ("make the table more hierarchical") is the one that breaks the table.

### 2. It is written against density, and our product is a dense board

- "Don't try to maximize the amount of information visible."
- "Use negative space."
- Avoid "densely packed".

The five-column table exists *to* maximise the information visible at once. That is the
product, not a failure of restraint. The document has no concept of a deliberately dense
artifact being the right answer, and it cannot arbitrate the density question it raises.
That is #12's decision to make.

### 3. It is silent on the actual problem

The table is **flat**: every cell is the same size, the same weight, and the same colour.
The source says "let typography establish hierarchy" as a principle and then never
touches a table's structure — which fields lead, how a pinned header relates to its rows,
what five columns do on a phone. It can judge a fix. It cannot propose one.

**Followed faithfully, it would leave the app looking exactly as it does now.**

## The audit

Seventeen rules, against this app, at the time of writing.

| # | Rule | Status |
|---|---|---|
| 1 | Content comes first; don't decorate the container | **Already** — an undecorated `List`, edge to edge, no card |
| 2 | Controls occupy a separate functional layer | **Already** — system toolbar and bottom bar |
| 3 | Use Liquid Glass selectively, never whole-app | **Already** — no custom glass anywhere |
| 4 | Prefer system materials over custom backgrounds | **Already** — no custom backgrounds |
| 5 | Use generous negative space | **Tension** — dense by design; see below |
| 6 | Use soft, coherent curvature | **Moot** — we draw no rounded containers |
| 7 | Keep borders extremely restrained | **Already** — plain-list hairlines only |
| 8 | Typography carries hierarchy, not boxes or colour | **Partly** — the cards arrangement does it with type size; the table is deliberately flat, and see the contradiction above |
| 9 | Keep colour primarily semantic | **Already** — orange means escalated, and nothing else |
| 10 | Light and dark are the same environment | **Unverified** — never run in dark mode |
| 11 | Make interactions fluid and continuous | **Already** — `NavigationLink` pushes are the system's |
| 12 | Animate changes, not decoration | **Open** — the table swaps its contents abruptly |
| 13 | Minimal visuals, comfortable interaction areas | **Already** — system toolbar, full-width rows |
| 14 | Let content reach toward the edges | **Already** |
| 15 | Relationships rather than hard-coded dimensions | **Partly** — now mostly `CompactTable`; see below |
| 16 | Accessibility is part of the visual system | **Partly** — the accessibility layout landed in #9; the appearance settings are still unverified in #11 |
| 17 | Don't hand-roll what the system provides | **Already** — and adopted as policy below |

**Ten already. One moot. Three partly. Three open or unverified.**

That is the honest result: the document validates far more than it instructs, and the
single actionable thing it surfaced was an accessibility defect.

### Rule 15, in full

Dimensions used to be stated twice — the column header and the row cells each named
`.caption2` and neither enforced the other. That is the shape of bug that broke the
column alignment twice. They now resolve to `CompactTable`, and the columns themselves
moved into the package, where `CompactColumnTests` pins them.

What remains deliberately hard-coded: the forced line break in the Alarm Level header.
See `CompactColumn.headerLabel`.

### Rule 5, unresolved

The table is as dense as it is on purpose, and the source's advice to the contrary cannot
be followed without discarding the product. Recorded as an open question rather than an
action, and settled by #12.

## The rules we adopt as policy

Two, both already satisfied. They are recorded because each is something we could
plausibly get wrong later, and citing them should end the argument sooner than relitigating
it.

### Colour means state, not taxonomy

Colour marks an exception, and there are two colours. Fire, Hazmat, Carbon Monoxide, Rescue,
and an Alarm Level of **2 or above** are **red** — the City's own line, where a response reaches
ten or more vehicles rather than one more crew. Everything else is **orange** where a colour is
needed, and uncoloured where it is not: a table cell stays plain, a mark on a map cannot.

**Why orange for the ordinary case**, when this section used to say that nothing else is coloured
ever: a map has to draw every shape and every dot in *some* colour, so unlike a table it cannot
leave the ordinary case alone. Orange is that colour. What the rule still forbids is the thing
that was actually wrong before — an area painted orange because it is an *area*, so that a quiet
neighbourhood and a burning one looked identical, and red meant "nothing to see" on a pin while
orange meant "look here" on the postal area behind it.

**It forbids:** colouring the thirteen incident categories, colouring by area or station,
a colour theme, or anything else that would make the 64% of incidents that are medical as
loud as the 5% that are fires. It forbids adding a decorative surface tint.

### Do not hand-roll what the system provides

If SwiftUI or UIKit already does it, call that.

**It forbids:** custom glass, custom shadows, custom button chrome, custom disclosure
indicators, and any bespoke "Apple-looking" effect. It also forbids reimplementing a
threshold the platform already draws — which is why the accessibility layout in #9 uses
`DynamicTypeSize.isAccessibilitySize` and `LabeledContent` rather than a size constant of
our own.

See `docs/adr/0005-apple-components-first.md`, whose one deliberate exception is the
compact table.

## The verification list

The source's rule 16 is the only one that produced work, because the app has never been
run under settings that change how it renders. The list:

- **Dynamic Type, accessibility sizes** — #9
- **Dark mode** — #11
- **Reduce Transparency** — #11
- **Increase Contrast** — #11
- **Reduce Motion** — #11

None of these can be checked from the repository. They need the app run, which is what
#11 is for.

## What this document is not

Not Apple's guidance. Not a specification. Not authority for a visual change.

It is a record of one critique, its result, and the two rules worth keeping — so that the
next person to arrive with a design manifesto has somewhere to start, and knows what
happened to the last one.
