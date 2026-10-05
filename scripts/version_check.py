"""Check that the version in the project and the version in the tags agree.

The rule this enforces, in one sentence: **the project's `MARKETING_VERSION` is the number of a
tag, and every tag's own tree carries that number.** Nothing else in the repository holds a
version, so the app a reader is holding can be matched to a commit by reading its Settings screen.

What it checks
--------------
1. The two build configurations in the project file agree with each other.
2. The version is three period-separated numbers — `major.minor.checkpoint` — because the third
   one is the checkpoint counter and a two-part version would leave it ambiguous.
3. Every tag from `SCHEME_STARTED_AT` onwards carries, in the tree it points at, a version equal
   to its own number.
4. The current tree is not *older* than the newest tag.

Why it starts where it does
---------------------------
Eight tags were made before this rule existed, and every one of their trees says `0.0.1a1` — set
once at `v0.0.1` and never moved. Those tags are not wrong; they are older than the rule. Moving
them would be worse than leaving them, because a tag that changes meaning is the one thing tags
exist to prevent. So the check begins at `v0.0.9` and the history is recorded in
`docs/releasing.md` instead of being rewritten.

Also worth knowing, since it is the reason the letters had to go: `CFBundleShortVersionString`
must be period-separated integers — `0.0.1a1` would have been refused by the App Store, after the
work of archiving it.

Usage
-----
    python3 scripts/version_check.py

Exits non-zero if the version and the tags disagree.
"""

import pathlib
import re
import subprocess
import sys

SCHEME_STARTED_AT = "v0.0.9"
PBXPROJ = "TorontoLiveEMS.xcodeproj/project.pbxproj"
MARKETING = re.compile(r"MARKETING_VERSION = ([^;]+);")
TAG = re.compile(r"^v(\d+)\.(\d+)\.(\d+)")
NUMBER = re.compile(r"^\d+\.\d+\.\d+$")


def ordinal(version):
    """A version as numbers, so that 0.0.10 is newer than 0.0.9.

    The first version of this compared the tag *names* as strings, which made `"v0.0.10" >=
    "v0.0.9"` false — the tenth checkpoint sorted before the ninth, was filtered out, and a
    deliberately wrong tag was reported as agreeing. Nothing about that failure was subtle, and
    nothing found it except trying to make the check fail.
    """
    return tuple(int(part) for part in version.split("."))


def git(*arguments):
    """Run git, returning stdout, or None when it failed."""
    result = subprocess.run(
        ("git",) + arguments, capture_output=True, text=True, check=False
    )
    return result.stdout.strip() if result.returncode == 0 else None


def versions(in_text):
    """Every MARKETING_VERSION in a project file, as a sorted list of distinct values."""
    return sorted({found.strip() for found in MARKETING.findall(in_text)})


def tags():
    """Every version tag, oldest first, as (name, version, commit)."""
    listed = git("tag", "--list", "--sort=v:refname", "--format=%(refname:short)|%(objectname)")
    out = []
    for line in (listed or "").splitlines():
        name, _, commit = line.partition("|")
        found = TAG.match(name)
        if not found:
            continue
        out.append((name, ".".join(found.groups()), commit))
    return out


def main():
    problems = []

    tree_versions = versions(pathlib.Path(PBXPROJ).read_text())
    print(f"  the project says: {', '.join(tree_versions) or 'nothing'}")

    if len(tree_versions) != 1:
        problems.append(
            f"the project file names {len(tree_versions)} versions ({', '.join(tree_versions)}); "
            "every build configuration must name the same one"
        )
    current = tree_versions[-1] if len(tree_versions) == 1 else None
    if current and not NUMBER.match(current):
        problems.append(
            f"{current!r} is not three period-separated numbers; the scheme is "
            "major.minor.checkpoint, and a letter would be refused by the App Store"
        )

    checked = tags()
    since = [tag for tag in checked if ordinal(tag[1]) >= ordinal(SCHEME_STARTED_AT[1:])]
    since.sort(key=lambda tag: ordinal(tag[1]))
    print(
        f"  tags: {len(checked)} versioned, {len(since)} since {SCHEME_STARTED_AT}"
    )

    for name, number, commit in since:
        project = git("show", f"{commit}:{PBXPROJ}")
        found = versions(project) if project else []
        if found != [number]:
            problems.append(
                f"{name} names {', '.join(found) or 'no version'} in its own tree; "
                f"a tag must carry its own number ({number})"
            )

    if since and current:
        newest = since[-1][1]
        if current != newest:
            # Older is always wrong; newer means a checkpoint is being prepared, which the
            # new tag is about to make true — so it is reported, not failed.
            older = ordinal(current) < ordinal(newest)
            print(
                f"  note: the tree says {current}, "
                f"{'older' if older else 'newer'} than the newest tag {newest}"
            )
            if older:
                problems.append(
                    f"the tree says {current} and the newest tag is {newest}: a checkout would be "
                    "older than the tag it follows"
                )

    print()
    if problems:
        for problem in problems:
            print(f"  FAIL  {problem}")
        print(f"\n{len(problems)} problem(s).")
        return 1

    print(f"  ok    {current} agrees with every tag from {SCHEME_STARTED_AT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
