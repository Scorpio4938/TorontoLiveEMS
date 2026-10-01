#!/usr/bin/env python3
"""Structural checks for the Swift sources.

This is not a compiler. It catches the specific errors that blind authoring
produces and that nothing else here can:

  1. unbalanced delimiters;
  2. a raw newline inside a single-line string literal;
  3. a reference to a member that does not exist on one of our own types;
  4. a file that names a public package type without importing the package.

The fourth is here because it caught nothing when it mattered. `IncidentFeed` is declared
`public final class`, and the pattern that collects package types allowed `public class` but
not the `final` between them — so the type was never collected, and the import check could
not fire on a file that used it. It went to a build as "cannot find 'IncidentFeed' in scope".
A check that cannot fail is worse than no check, because it looks like one; this file already
said that, two checks further down.

Multi-line literals are exempt from (2), because a newline in one is the point.

The third is here because of a real one. Renaming `CompactTable.outgrowsTheGrid`
to `needsLabelledRows` updated every reference but one, and the miss reached a
build. Grepping for the old name would have found it; remembering to grep for
every name I had touched did not. So the check is mechanical now.

Declarations are pooled across all roots given, so the app target referring to a
package type resolves. Pass both roots or the cross-target check is weaker.

Usage: python3 scripts/check_swift.py TorontoLiveEMS TorontoLiveEMSKit
Exits non-zero if anything is wrong.
"""
import pathlib
import re
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
        # A multi-line literal, before the single-line branch below can misread its opening
        # quotes. None existed in this repo until the City's own paragraphs were quoted
        # verbatim, so the checker had never had to know about them — it read `"""` as an
        # empty string and then treated the paragraph as code, complete with real newlines.
        if src.startswith('"""', i):
            close = src.find('"""', i + 3)
            end = n if close < 0 else close
            bodies.append(src[i + 3:end])
            code.append('""')
            i = n if close < 0 else close + 3
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


# Members our own types get from a protocol, not from a declaration we can see.
SYNTHESIZED = {
    "allCases",        # CaseIterable
    "rawValue",        # RawRepresentable
    "hashValue",       # Hashable
    "description",     # CustomStringConvertible
    "debugDescription",
    "self",
    "init",
}


def body_of(code, brace_at):
    """Index just past the `}` matching the `{` at `brace_at`."""
    depth = 0
    for i in range(brace_at, len(code)):
        if code[i] == "{":
            depth += 1
        elif code[i] == "}":
            depth -= 1
            if depth == 0:
                return i + 1
    return len(code)


def declarations(code):
    """Map each type we declare to the members declared inside it.

    Deliberately loose. It collects any `func`, `var`, `let` or enum `case` inside
    the type's braces, including ones nested in a function body. A false negative
    costs a missed check; a false positive would make the check untrustworthy, so
    it errs towards believing a name exists.
    """
    found = {}
    pattern = re.compile(
        r"\b(?:struct|enum|class|actor|protocol)\s+(\w+)|\bextension\s+([\w.]+)"
    )
    member = re.compile(
        r"\bfunc\s+(\w+)"
        r"|^\s*(?:(?:public|private|internal|fileprivate|static|final|override"
        r"|nonisolated|mutating|class|lazy|weak|unowned)\s+)*(?:var|let)\s+(\w+)"
        r"|^\s*case\s+(\w+)\s*$"
        r"|^\s*case\s+(\w+)\(",
        re.M,
    )
    for match in pattern.finditer(code):
        name = match.group(1) or match.group(2).split(".")[-1]
        brace = code.find("{", match.end())
        if brace < 0:
            continue
        inner = code[brace:body_of(code, brace)]
        members = found.setdefault(name, set())
        for m in member.finditer(inner):
            members.add(next(g for g in m.groups() if g))
    return found


def unresolved(code, declared):
    """References to `OurType.member` where member is not declared on OurType."""
    out = []
    for m in re.finditer(r"\b([A-Z]\w+)\.([a-z_]\w*)", code):
        type_name, member = m.group(1), m.group(2)
        if type_name not in declared:
            continue
        if member in declared[type_name] or member in SYNTHESIZED:
            continue
        out.append((code[:m.start()].count("\n") + 1, f"{type_name}.{member}"))
    return out


def main():
    roots = sys.argv[1:] or ["TorontoLiveEMSKit"]
    files = sorted({f for root in roots for f in pathlib.Path(root).rglob("*.swift")})
    if not files:
        print(f"no .swift files under {', '.join(roots)}")
        return 1

    scanned = [(path, *scan(path.read_text())) for path in files]

    declared = {}
    for _, code, _ in scanned:
        for name, members in declarations(code).items():
            declared.setdefault(name, set()).update(members)

    # A file outside the package that names one of its public types has to import it. Swift
    # does not infer that, and the error it gives — "cannot find type 'Incident' in scope" —
    # names the type rather than the missing import, which reads like a typo.
    #
    # Comments and strings are already blanked out of `code`, which matters: a doc comment
    # mentioning a type by name is prose, and this is the third check here whose first draft
    # would have flagged one.
    package_types = set()
    for path, code, _ in scanned:
        if "/Sources/" in path.as_posix():
            package_types |= set(re.findall(
                r"^public (?:final )?(?:enum|struct|class|actor|protocol)\s+(\w+)", code, re.M))

    problems = 0
    for path, code, bodies in scanned:
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

        # Its own pass, after `code` is settled. The first version of this smuggled the finding
        # into `bodies` above the re-scan a few lines up, which silently overwrote it — so the
        # check ran, found the file, and reported nothing. A check that cannot fail is worse than
        # no check, because it looks like one.
        if "/Sources/" not in path.as_posix() and "import TorontoLiveEMSKit" not in code:
            used = sorted(t for t in package_types if re.search(rf"\b{t}\b", code))
            if used:
                notes.append(f"names {', '.join(used)} without importing TorontoLiveEMSKit")

        for line, name in unresolved(code, declared):
            notes.append(f"line {line}: {name} is not declared on that type")

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
    print(f"  {len(declared)} type(s) cross-referenced")
    print(f"  {len(package_types)} package type(s) checked for imports")
    return 0


if __name__ == "__main__":
    sys.exit(main())
