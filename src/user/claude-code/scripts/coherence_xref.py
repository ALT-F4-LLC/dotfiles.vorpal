#!/usr/bin/env python3
"""Mechanizes evolve-coherence's Phase 0 `xref-builder` step: build the PINNED
8-key cross-reference index (Data Models § of `.claude/skills/evolve-coherence/
SKILL.md`) over every agent + skill, emitting ONE fenced ```json block that the
four Phase 1 dimension reviewers consume as signals-to-verify.

Replaces the hand-executed grep/awk detection seeds the `xref-builder` sonnet
spawn ran by hand — hand-execution varied per run and dropped schema keys. This
script is byte-stable and deterministic across runs (fixed schema-order keys,
every array sorted on a stable key, repo-relative paths, no timestamps).

Two of the eight keys are the outputs of already-mechanized coherence legs; this
script CALLS those scripts rather than reimplementing their logic:
  - coupling_notes  (D3 #6): parsed from `coupling_check.py` stdout.
  - canonical_blocks (D4 #2): `family_hash`/parity from `doctrine_check.sh
    --emit-hashes` (its extract+strip+hash pipeline is the single source).

The other six keys are pure read-only grep/parse over the current file tree.

The XREF is signals, NOT judgment — every entry is a starting point a Phase 1
reviewer confirms against ground truth. Absent-but-computed dimensions emit `[]`;
dimensions not selected on the `--dimensions` subset path emit `null` (per the
schema's `[]`-vs-`null` contract).

Usage:
    coherence_xref.py [--dimensions d1,d3]
        No argument: compute all four dimensions (all 8 keys).
        Subset: keys for un-selected dimensions are emitted as `null`.

Exit codes: 0 = XREF emitted; 2 = a required input (a called leg script, the
manifest) was missing or a called leg errored unexpectedly.

Read-only. Never edits, never writes. Stdlib + the two sibling leg scripts.
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
COUPLING_CHECK = os.path.join(SCRIPT_DIR, "coupling_check.py")
DOCTRINE_CHECK = os.path.join(SCRIPT_DIR, "doctrine_check.sh")
MANIFEST = os.path.join(SCRIPT_DIR, "doctrine_check_manifest.tsv")

AGENTS_GLOB = "src/user/claude-code/agents/*.md"
SKILL_ROOTS = ["src/user/claude-code/skills", ".claude/skills"]
DEPLOYED_ROOT = "src/user/claude-code/skills"

# Keys grouped by the coherence dimension that owns them (schema § + rubric).
DIMENSION_KEYS = {
    "d1": ["registry", "skill_refs", "frontmatter_skills"],
    "d2": ["role_claims"],
    "d3": ["ladders", "coupling_notes"],
    "d4": ["canonical_blocks", "rule_presence"],
}
# Emission order is the PINNED schema order, NOT dimension order.
SCHEMA_KEY_ORDER = [
    "registry",
    "skill_refs",
    "frontmatter_skills",
    "role_claims",
    "ladders",
    "canonical_blocks",
    "coupling_notes",
    "rule_presence",
]


def repo_root():
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        print("coherence_xref.py: not inside a git repository", file=sys.stderr)
        sys.exit(2)
    return out.stdout.strip()


def read_text(path):
    with open(path, "r") as f:
        return f.read()


def skill_dirs():
    """Every skill directory under the two roots, as (dir_name, root, path)."""
    found = []
    for root in SKILL_ROOTS:
        for path in glob.glob(os.path.join(root, "*")):
            if os.path.isfile(os.path.join(path, "SKILL.md")):
                found.append((os.path.basename(path), root, path))
    return found


def skill_name(skill_path):
    """The `name:` frontmatter value of a skill's SKILL.md, or None."""
    for line in read_text(os.path.join(skill_path, "SKILL.md")).splitlines():
        m = re.match(r"name:\s*(\S+)", line)
        if m:
            return m.group(1)
    return None


def agent_files():
    return sorted(glob.glob(AGENTS_GLOB))


def agent_name(path):
    return os.path.basename(path)[:-3]  # strip ".md"


# --------------------------------------------------------------------------- D1

def build_registry():
    rows = []
    for dir_name, root, path in skill_dirs():
        rows.append({
            "dir": dir_name,
            "name": skill_name(path),
            "root": root,
            "deployed": root == DEPLOYED_ROOT,
        })
    rows.sort(key=lambda r: (r["dir"], r["root"]))
    return rows


SKILL_CALL_RE = re.compile(r"Skill\(([a-z][a-z-]*)")


def build_skill_refs():
    refs = []
    for path in agent_files():
        for i, line in enumerate(read_text(path).splitlines(), start=1):
            for token in SKILL_CALL_RE.findall(line):
                if token == "name":  # documented placeholder, not a real ref
                    continue
                refs.append({
                    "file": path,
                    "line": i,
                    "token": token,
                    "kind": "Skill-call",
                })
    refs.sort(key=lambda r: (r["file"], r["line"], r["token"]))
    return refs


def build_frontmatter_skills():
    entries = []
    for path in agent_files():
        agent = agent_name(path)
        lines = read_text(path).splitlines()
        in_fm = False
        in_skills = False
        for line in lines:
            if line.strip() == "---":
                # Toggle into, then out of, the leading frontmatter block.
                if not in_fm:
                    in_fm = True
                    continue
                break
            if not in_fm:
                continue
            if re.match(r"^skills:\s*$", line):
                in_skills = True
                continue
            if in_skills:
                m = re.match(r"\s*-\s*(\S+)", line)
                if m:
                    entries.append({"agent": agent, "skill": m.group(1)})
                    continue
                if re.match(r"^\S", line):  # next top-level key ends the list
                    in_skills = False
    entries.sort(key=lambda e: (e["agent"], e["skill"]))
    return entries


# --------------------------------------------------------------------------- D2

ROLE_CLAIM_RE = re.compile(
    r"driven by|format authority|callable ONLY by|restricted to|typically .@|Role Detection",
    re.IGNORECASE,
)
HARD_RE = re.compile(r"callable ONLY by|restricted to|Role Detection|ABORT", re.IGNORECASE)
AGENT_TOKEN_RE = re.compile(r"@([a-z][a-z-]+)")


def build_role_claims():
    claims = []
    for dir_name, _root, path in skill_dirs():
        skill_md = os.path.join(path, "SKILL.md")
        for i, line in enumerate(read_text(skill_md).splitlines(), start=1):
            if not ROLE_CLAIM_RE.search(line):
                continue
            agent_m = AGENT_TOKEN_RE.search(line)
            claims.append({
                "skill": dir_name,
                "file": skill_md,
                "line": i,
                "claimed_agent": agent_m.group(1) if agent_m else None,
                "restriction": "hard-abort" if HARD_RE.search(line) else "soft-typically",
            })
    claims.sort(key=lambda c: (c["file"], c["line"]))
    return claims


# --------------------------------------------------------------------------- D3

# The two severity ladders the D3 #4 seed pins, with their definition-site
# skills. def_site = first match in a definer skill; citations = agent matches.
# Spacing-tolerant: the definer skills write the ladder slash-tight
# ("Blocker/Concern") while agents cite it spaced ("Blocker / Concern").
LADDERS = [
    ("staff-severity", re.compile(r"Blocker\s*/\s*Concern"),
     ["code-review-verdict", "design-review"]),
    ("security-severity", re.compile(r"Critical\s*/\s*High"),
     ["code-review-verdict"]),
]


def _grep_first(path, pattern):
    for i, line in enumerate(read_text(path).splitlines(), start=1):
        if pattern.search(line):
            return "%s:%d" % (path, i)
    return None


def _grep_all(paths, pattern):
    hits = []
    for path in paths:
        for i, line in enumerate(read_text(path).splitlines(), start=1):
            if pattern.search(line):
                hits.append("%s:%d" % (path, i))
    return sorted(hits)


def build_ladders():
    agents = agent_files()
    skill_path = {d: p for d, _r, p in skill_dirs()}
    out = []
    for name, pattern, definer_dirs in LADDERS:
        def_site = None
        for dir_name in definer_dirs:
            path = skill_path.get(dir_name)
            if path:
                def_site = _grep_first(os.path.join(path, "SKILL.md"), pattern)
            if def_site:
                break
        out.append({
            "name": name,
            "def_site": def_site,
            "citations": _grep_all(agents, pattern),
        })
    return out


COUPLING_LINE_RE = re.compile(
    r"^\[(OK|COUNT-MISMATCH|RECIPROCITY-MISMATCH)\]\s+\S+\s+\(([^)]+)\):"
)
COUPLING_ROSTER_RE = re.compile(r"'([^']+)'")
COUPLING_COUNT_RE = re.compile(r"family of (\d+)|all (\d+)")
NOTE_LINE_RE = re.compile(r"update all \d+ in lockstep")
NOTE_FAMILY_RE = re.compile(r"is part of the ([\w-]+) family")


def _note_line_and_family(note_path):
    line_no = None
    family = None
    for i, line in enumerate(read_text(note_path).splitlines(), start=1):
        if line_no is None and NOTE_LINE_RE.search(line):
            line_no = i
        if family is None:
            fm = NOTE_FAMILY_RE.search(line)
            if fm:
                family = fm.group(1)
    return line_no, family


def build_coupling_notes(root):
    result = subprocess.run(
        ["python3", COUPLING_CHECK],
        capture_output=True, text=True, cwd=root,
    )
    # coupling_check.py exits 0 (consistent) or 1 (mismatch); both emit the
    # per-note lines we parse. Exit 2 means no notes found — an empty signal.
    if result.returncode not in (0, 1, 2):
        print("coherence_xref.py: coupling_check.py errored:\n%s"
              % result.stderr, file=sys.stderr)
        sys.exit(2)
    notes = []
    for line in result.stdout.splitlines():
        m = COUPLING_LINE_RE.match(line)
        if not m:
            continue
        note_path = m.group(2)
        roster = sorted(COUPLING_ROSTER_RE.findall(line))
        count_m = COUPLING_COUNT_RE.search(line)
        stated_count = None
        if count_m:
            stated_count = int(count_m.group(1) or count_m.group(2))
        line_no, family = _note_line_and_family(note_path)
        notes.append({
            "file": note_path,
            "line": line_no,
            "family": family,
            "stated_count": stated_count,
            "named_siblings": roster,
        })
    notes.sort(key=lambda n: (n["file"], n["line"] if n["line"] is not None else 0))
    return notes


# --------------------------------------------------------------------------- D4

def _manifest_rows():
    rows = []
    for line in read_text(MANIFEST).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        cols = line.split("\t")
        tag = cols[0]
        carrier = cols[1] if len(cols) > 1 and cols[1] else None
        marker = cols[3] if len(cols) > 3 and cols[3] else tag
        rows.append((tag, carrier, marker))
    return rows


def _begin_line(carrier_path, marker, root):
    needle = "CANONICAL:%s:BEGIN" % marker
    full = os.path.join(root, carrier_path)
    try:
        for i, line in enumerate(read_text(full).splitlines(), start=1):
            if needle in line:
                return i
    except OSError:
        return None
    return None


BANNER_FAMILY = {"BANNER": "orchestrator", "BANNER-LEAF": "leaf"}


def build_canonical_blocks(root):
    if not os.path.isfile(MANIFEST):
        print("coherence_xref.py: manifest missing: %s" % MANIFEST, file=sys.stderr)
        sys.exit(2)
    result = subprocess.run(
        ["bash", DOCTRINE_CHECK, "--emit-hashes"],
        capture_output=True, text=True, cwd=root,
    )
    # emit mode exits 0 (all parity ok) or 1 (a tag diverged); both stream the
    # tag<TAB>hash<TAB>count<TAB>parity lines we consume.
    if result.returncode not in (0, 1):
        print("coherence_xref.py: doctrine_check.sh --emit-hashes errored:\n%s"
              % result.stderr, file=sys.stderr)
        sys.exit(2)
    hashes = {}
    for line in result.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) == 4:
            hashes[parts[0]] = parts[1]

    carriers_by_tag = {}
    marker_by_tag = {}
    for tag, carrier, marker in _manifest_rows():
        marker_by_tag[tag] = marker
        if carrier:
            carriers_by_tag.setdefault(tag, []).append(carrier)

    blocks = []
    for tag in sorted(carriers_by_tag):
        marker = marker_by_tag[tag]
        carriers = []
        for carrier in carriers_by_tag[tag]:
            ln = _begin_line(carrier, marker, root)
            carriers.append("%s:%d" % (carrier, ln) if ln else carrier)
        blocks.append({
            "tag": tag,
            "family": BANNER_FAMILY.get(tag, tag),
            "carriers": sorted(carriers),
            "family_hash": hashes.get(tag),
        })
    return blocks


RULE_TOKEN_RE = re.compile(r"\bR([1-7])\b")
TOP_RULE_RE = re.compile(r"^(\d+)\.")
COMM_HEADING_RE = re.compile(r"^#{1,4}\s+Communication Discipline", re.IGNORECASE)
RULES_HEADING_RE = re.compile(r"^#{1,4}\s+Rules\b", re.IGNORECASE)
ANY_HEADING_RE = re.compile(r"^#{1,4}\s")
UNNUMBERED_AGENTS = {"senior-engineer", "distinguished-engineer"}


def _longest_run_from_one(nums):
    """The largest N such that 1..N are all present — the length of the rules
    list, robust to a shorter numbered list sharing the same section."""
    present = set(nums)
    n = 0
    while (n + 1) in present:
        n += 1
    return n or None


def _rules_section(lines):
    """The lines of the numbered-rules section: the `## Communication
    Discipline` block (execution/doc/review agents) or `## Rules` (team-lead),
    bounded by the next heading. Scoping here excludes longer workflow lists
    elsewhere in the file that would otherwise inflate the count."""
    start = None
    for i, line in enumerate(lines):
        if COMM_HEADING_RE.match(line):
            start = i
            break
    if start is None:
        for i, line in enumerate(lines):
            if RULES_HEADING_RE.match(line):
                start = i
                break
    if start is None:
        return lines
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if ANY_HEADING_RE.match(lines[j]):
            end = j
            break
    return lines[start:end]


def build_rule_presence():
    out = []
    for path in agent_files():
        agent = agent_name(path)
        text = read_text(path)
        present = sorted({"R%s" % n for n in RULE_TOKEN_RE.findall(text)})
        unnumbered = agent in UNNUMBERED_AGENTS
        top = None
        if not unnumbered:
            section = _rules_section(text.splitlines())
            nums = [int(m.group(1)) for line in section
                    for m in [TOP_RULE_RE.match(line)] if m]
            top = _longest_run_from_one(nums)
        out.append({
            "agent": agent,
            "rules_present": present,
            "top_rule_count": top,
            "numbering_parse": "unnumbered-crosstag" if unnumbered else "numbered",
        })
    out.sort(key=lambda r: r["agent"])
    return out


# ---------------------------------------------------------------------------

def resolve_dimensions(arg):
    if not arg:
        return {"d1", "d2", "d3", "d4"}
    dims = set()
    for tok in arg.split(","):
        tok = tok.strip().lower()
        if tok not in DIMENSION_KEYS:
            print("coherence_xref.py: bad dimension %r (expected subset of d1..d4)"
                  % tok, file=sys.stderr)
            sys.exit(2)
        dims.add(tok)
    return dims


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dimensions",
        default=None,
        help="comma list subset of d1..d4; un-selected dimensions' keys emit null",
    )
    args = parser.parse_args(argv)
    dims = resolve_dimensions(args.dimensions)

    for required in (COUPLING_CHECK, DOCTRINE_CHECK):
        if not os.path.isfile(required):
            print("coherence_xref.py: required leg script missing: %s" % required,
                  file=sys.stderr)
            return 2

    root = repo_root()
    os.chdir(root)

    builders = {
        "registry": build_registry,
        "skill_refs": build_skill_refs,
        "frontmatter_skills": build_frontmatter_skills,
        "role_claims": build_role_claims,
        "ladders": build_ladders,
        "canonical_blocks": lambda: build_canonical_blocks(root),
        "coupling_notes": lambda: build_coupling_notes(root),
        "rule_presence": build_rule_presence,
    }
    selected_keys = set()
    for dim in dims:
        selected_keys.update(DIMENSION_KEYS[dim])

    xref = {}
    for key in SCHEMA_KEY_ORDER:
        xref[key] = builders[key]() if key in selected_keys else None

    print("```json")
    print(json.dumps(xref, indent=2, ensure_ascii=False))
    print("```")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
