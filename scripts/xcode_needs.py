#!/usr/bin/env python3
"""Says whether Xcode needs the project closed and reopened.

The app folder is a `PBXFileSystemSynchronizedRootGroup`: every `.swift` file under it joins
the target by being there, with no project-file edit. The cost is that **Xcode scans it when the
project opens**, so a file that arrives while the project is open is invisible — the build fails
with `cannot find type 'X' in scope`, naming the type rather than the reason.

That has caught this project three times. It is not diagnosable from the source, which is why it
is a command rather than a note in a README nobody rereads at the moment it matters.

Tags mark points that have been built, so the newest one is the right thing to compare against by
default.

Usage:
    python3 scripts/xcode_needs.py             # since the newest tag
    python3 scripts/xcode_needs.py v0.0.2      # since a particular one
    python3 scripts/xcode_needs.py HEAD~5
"""

import pathlib
import subprocess
import sys


def git(*args):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def newest_tag():
    tags = git("tag", "--sort=-creatordate")
    return tags.splitlines()[0] if tags else None


def main():
    if git("rev-parse", "--is-inside-work-tree") is None:
        print("not a git repository")
        return 1

    ref = sys.argv[1] if len(sys.argv) > 1 else newest_tag()
    if not ref:
        print("no tag to compare against; pass a commit")
        return 1

    if git("rev-parse", "--verify", ref) is None:
        print(f"no such ref: {ref}")
        return 1

    changes = git("diff", "--name-status", f"{ref}..HEAD")
    added, removed = [], []
    for line in (changes or "").splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        status, path = parts[0][0], parts[-1]
        if not path.endswith(".swift"):
            continue
        # Only the app folder is synchronized. The package's sources are a package target, and
        # its tests are a test target; both are found by path, not by a scan.
        if not path.startswith("TorontoLiveEMS/"):
            continue
        (added if status == "A" else removed if status == "D" else []).append(path)

    print(f"  comparing against {ref}")
    print()
    for path in added:
        print(f"  added    {path}")
    for path in removed:
        print(f"  removed  {path}")

    print()
    if added or removed:
        print(f"  {len(added)} added, {len(removed)} removed — XCODE MUST BE REOPENED")
        print("  Close the project and open it again. A clean build does not rescan the folder.")
        return 0

    print("  nothing added or removed — a rebuild is enough")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
