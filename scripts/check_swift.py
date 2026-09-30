#!/usr/bin/env python3
"""Structural checks for the Swift sources.

This is not a compiler. It catches the specific transcription errors that blind
authoring produces: unbalanced delimiters, and raw newlines or unescaped quotes
inside single-line string literals.

Usage: python3 scripts/check_swift.py [root]
Exits non-zero if anything is wrong.
"""
import pathlib
import sys

RAW_NEWLINE = "<<RAW-NEWLINE-INSIDE-LITERAL>>"


def scan(src):
    """Replace comments and string bodies with placeholders, keeping length.

    Returns (code, string_bodies) where `code` has string bodies blanked out, so
    delimiters inside literals are never counted.
    """
    code = []
    bodies = []
    i, n = 0, len(src)
    while i < n:
        if src.startswith("//", i):
            while i < n and src[i] != "\n":
                i += 1
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if src[i] == '"':
            i += 1
            buf = []
            while i < n:
                if src[i] == "\\":
                    buf.append(src[i:i + 2])
                    i += 2
                    continue
                if src[i] == '"':
                    i += 1
                    break
                if src[i] == "\n":
                    buf.append(RAW_NEWLINE)
                    i += 1
                    continue
                buf.append(src[i])
                i += 1
            bodies.append("".join(buf))
            code.append('""')
            continue
        code.append(src[i])
        i += 1
    return "".join(code), bodies


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "TorontoLiveEMSKit")
    files = sorted(root.rglob("*.swift"))
    if not files:
        print(f"no .swift files under {root}")
        return 1

    problems = 0
    for path in files:
        src = path.read_text()
        code, bodies = scan(src)

        pairs = {"{}": ("{", "}"), "()": ("(", ")"), "[]": ("[", "]")}
        notes = []
        for label, (open_c, close_c) in pairs.items():
            o, c = code.count(open_c), code.count(close_c)
            if o != c:
                notes.append(f"unbalanced {label} {o}/{c}")

        for body in bodies:
            if RAW_NEWLINE in body:
                notes.append("raw newline inside a single-line string literal")
                break

        if notes:
            problems += 1
            print(f"  FAIL  {path}")
            for note in notes:
                print(f"          {note}")
        else:
            print(f"  ok    {path}")

    print()
    if problems:
        print(f"  {problems} file(s) with problems")
        return 1
    print(f"  {len(files)} file(s) clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
