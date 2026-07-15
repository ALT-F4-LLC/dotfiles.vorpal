#!/usr/bin/env python3
"""Mechanizes evolve-coherence D3 check 6 (`<!-- COUPLING -->` family-
membership notes are self-consistent) -- the count/roster/reciprocity legs
(i) and (ii) of that check's invariant, per its own detection recipe:

    grep -rn '<!-- COUPLING' src/user/claude-code/skills/*/SKILL.md
        .claude/skills/*/SKILL.md
    -> parse each note's "all N" count + named siblings; build family
    rosters; flag any note whose count != roster size or whose named
    siblings don't reciprocate (excluding the whitelisted one-directional
    bridges simplify-scout, ux-spec).

Only genuine `<!-- COUPLING ... -->` HTML-comment lines are notes (matched
at column 0, modulo leading whitespace) -- this excludes prose that merely
*mentions* the string `<!-- COUPLING` inside backticks (e.g.
evolve-coherence/SKILL.md's own description of this check).

Only notes matching the literal family-membership grammar --
`update all N in lockstep` -- are family-membership notes; this excludes
the differently-worded scope-resolution and reserved-name COUPLING notes
(e.g. "Keep all four in sync", "Update init-specs and this file in
lockstep") by construction, without needing to enumerate them.

Two observed sibling-list forms:
  - Self-inclusive: `... the <family> family (A, B, C, D). ... update all N
    in lockstep ...` -- the parenthetical after "family" already includes
    the note's own skill.
  - Siblings-only: `... stay in sync with src/user/claude-code/skills/A, B,
    and C -- update all N in lockstep ...` -- the note's own skill is
    implied, not listed; add it to the roster.

leg (iii) ("When NOT to Use" delegation-list agreement) is NLP-judgment,
not text-decidable, and is explicitly out of scope for this script (left to
the coherence-reviewer agent).

Exit codes: 0 = every family-membership note's count matches its roster
size AND every named sibling reciprocates with a matching roster (modulo
the whitelisted one-directional bridges); 1 = at least one mismatch found;
2 = no family-membership notes found at all (precondition failure -- this
repo is known to carry >=2 such families).
"""
import argparse
import glob
import re
import sys

DEFAULT_GLOBS = [
    "src/user/claude-code/skills/*/SKILL.md",
    ".claude/skills/*/SKILL.md",
]

# Whitelisted one-directional bridges (evolve-coherence D3 check 6): these
# skills may be NAMED inside another family's note without reciprocating a
# matching note of their own -- not drift. `init-specs` is added here even
# though evolve-coherence/SKILL.md's explicit whitelist bullet only names
# simplify-scout and ux-spec: that same file's worked example for the
# doc-authoring family states "(init-specs's own note is the reserved-name
# one, not 'all 5')" as an expected, non-drift asymmetry -- the whitelist
# bullet is one entry short of its own worked example (a documentation gap
# worth fixing in a future evolve-coherence/evolve-skills cycle; flagged
# rather than silently worked around).
ONE_DIRECTIONAL_BRIDGES = {"simplify-scout", "ux-spec", "init-specs"}

COMMENT_START_RE = re.compile(r"^\s*<!-- COUPLING", re.MULTILINE)
COUNT_RE = re.compile(r"update all (\d+) in lockstep")
# Anchored on "is part of the <family> family (" specifically -- this is the
# self-inclusive roster for THIS note's count. A later, unrelated
# "bridges the <other family> (...)" clause (the ux-spec case) never matches
# "is part of the", so it is never mistaken for this note's own roster.
SELF_INCLUSIVE_RE = re.compile(r"is part of the [\w-]+ family\s*\(([^)]+)\)")
SIBLINGS_ONLY_RE = re.compile(
    r"sync with\s+(?:src/user/claude-code/skills/)?(.+?)\s*[-–—]+\s*update all"
)


def find_comment_spans(text):
    """Returns each `<!-- COUPLING ... -->` comment's full text, for lines
    that start (modulo leading whitespace) with the literal marker."""
    spans = []
    for m in COMMENT_START_RE.finditer(text):
        end = text.find("-->", m.start())
        if end == -1:
            continue
        spans.append(text[m.start(): end + 3])
    return spans


def clean_tokens(raw):
    """Splits a comma/"and"-joined sibling list into clean skill-name tokens."""
    raw = raw.replace(" and ", ", ")
    tokens = []
    for tok in raw.split(","):
        tok = tok.strip().strip(".")
        tok = tok.split("/")[-1]  # strip any residual "skills/" path prefix
        if tok:
            tokens.append(tok)
    return tokens


def parse_note(owner, comment_text):
    """Returns (count, roster_set) if this is a family-membership note,
    else None."""
    count_m = COUNT_RE.search(comment_text)
    if not count_m:
        return None
    count = int(count_m.group(1))

    incl_m = SELF_INCLUSIVE_RE.search(comment_text)
    if incl_m:
        roster = set(clean_tokens(incl_m.group(1)))
    else:
        sib_m = SIBLINGS_ONLY_RE.search(comment_text)
        if not sib_m:
            return None
        roster = set(clean_tokens(sib_m.group(1)))
        roster.add(owner)

    return count, roster


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--glob",
        action="append",
        default=None,
        help="glob for SKILL.md files to scan (repeatable; default: the two skill roots)",
    )
    args = parser.parse_args(argv)
    globs = args.glob or DEFAULT_GLOBS

    paths = sorted({p for g in globs for p in glob.glob(g)})
    if not paths:
        print(f"coupling_check.py: no files matched globs {globs}", file=sys.stderr)
        return 2

    notes = {}  # owner skill name -> list of (count, roster, source_path)
    for path in paths:
        owner = path.rstrip("/").split("/")[-2]
        with open(path, "r") as f:
            text = f.read()
        for span in find_comment_spans(text):
            parsed = parse_note(owner, span)
            if parsed is None:
                continue
            count, roster = parsed
            notes.setdefault(owner, []).append((count, roster, path))

    if not notes:
        print("coupling_check.py: no family-membership COUPLING notes found", file=sys.stderr)
        return 2

    failed = 0
    checked = 0

    for owner, entries in sorted(notes.items()):
        for count, roster, path in entries:
            checked += 1
            label = f"{owner} ({path})"
            if len(roster) != count:
                print(
                    f"[COUNT-MISMATCH] {label}: states \"all {count}\" but roster has "
                    f"{len(roster)} members: {sorted(roster)}"
                )
                failed += 1
                continue

            mismatches = []
            for sibling in sorted(roster - {owner}):
                if sibling in ONE_DIRECTIONAL_BRIDGES:
                    continue
                sibling_entries = notes.get(sibling)
                if not sibling_entries:
                    mismatches.append(f"{sibling} carries no reciprocal family note")
                    continue
                if not any(sib_roster == roster for _, sib_roster, _ in sibling_entries):
                    mismatches.append(
                        f"{sibling}'s roster does not match {owner}'s roster {sorted(roster)}"
                    )

            if mismatches:
                print(f"[RECIPROCITY-MISMATCH] {label}: " + "; ".join(mismatches))
                failed += 1
            else:
                print(f"[OK] {label}: family of {count} = {sorted(roster)}")

    print(f"{checked - failed}/{checked} family-membership notes consistent")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
