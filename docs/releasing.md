# Versions

One number, and everything that mentions a version takes it from the same place: the project
file's `MARKETING_VERSION`, the git tag, and the version Settings shows a reader.

## The number

`major.minor.checkpoint` — three period-separated digits.

| | | |
|---|---|---|
| **major** | the era | the app as a released thing; changes when something fundamental does |
| **minor** | worth being aware of | a change of substance: a new screen, a new source of data |
| **checkpoint** | this one | incremented at every checkpoint — and it carries fixes too, so a fix between minor bumps is still visible in the version |

**A tag is the number and nothing else**: `v0.0.9`. What the effort *was* goes in the tag's
**message**, where it reads as a reference rather than forming part of the identity. That is what
makes "the tag and the project agree" a checkable fact instead of a habit.

**The project's `MARKETING_VERSION` is that same number.** `CFBundleShortVersionString` is
generated from it, so it is what Settings shows, and it is what matches the build in someone's
hand to a commit.

**A release is a decision, not a different kind of number.** After `v1.0.0`, checkpoints continue
`1.0.1`, `1.0.2`, … and shipping one means releasing exactly the number you are on: six checkpoints
later, `v1.0.6` is the release. Nothing is renamed, nothing is renumbered, and the checkpoint
history stays legible as the app's history.

## A checkpoint is a decision, not a merge hook

Not every merged branch becomes one. The version moves when the work is worth marking, and the
merge that introduced the *About* screen went in **without** moving it: the number stayed `0.0.10`,
no tag was made, and `0.0.11` is still free for the next checkpoint that deserves it. A branch may
carry a bump with it, so that the merge commit's tree already says its own number — or it may be
merged as it is, and the number waits. What it must never do is move by itself.

## At a checkpoint

1. Bump `MARKETING_VERSION` in `TorontoLiveEMS.xcodeproj/project.pbxproj` — **both build
   configurations** — to the new number.
2. Update the tag table in `README.md`, including whether this one has been built.
3. Run `python3 scripts/version_check.py`. It must pass.
4. Tag the commit: `git tag -a v0.0.9 -m "…"`, with the effort named in the message.

**The build number waits.** `CURRENT_PROJECT_VERSION` is not touched until there is something to
distribute. TestFlight and the App Store want a new build number for *every* upload, even at the
same marketing version, so it belongs to the act of shipping rather than to the checkpoint.

**Settings reports all of this**, and in the same terms: the row shows the version and the build —
`0.0.9 (1)` — read from the bundle rather than typed into the screen, and the sentence beneath it
says which number is which and what the stage means. The stage's words come from `VersionStage` in
the package, so the words a test pins are the words a reader sees.

## At a release

Everything above, then the build number, then an archive. Two rules that are easy to meet once and
hard to fix later:

- **`CURRENT_PROJECT_VERSION` must never repeat** for an upload. A build that was rejected or
  replaced cannot be uploaded again under the same number.
- **`CFBundleShortVersionString` must be period-separated integers.** This is why the version is
  `0.0.9` and not `0.0.9-alpha`: letters are refused, and finding that out costs an archive. Alpha
  is the leading `0`, which is what a leading `0` means.

## History, and why the rule starts where it does

Eight tags were made before this rule, and every one of their trees says `0.0.1a1` — set once at
`v0.0.1` and never moved. They are not wrong; they are older than the rule. Rewriting them would be
worse than leaving them, because a tag that changes meaning is the one thing tags exist to prevent.
So the check begins at **`v0.0.9`**, and this paragraph is the record of why the eight before it
are exempt.
