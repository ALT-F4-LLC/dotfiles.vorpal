#!/usr/bin/env python3
"""Shared "Validation Before Save" checker for the doc-authoring skills
(adr, prd, tdd, ux-spec), previously hand-maintained as per-skill prose
checklists. Each type's checklist is transcribed check-for-check into the
per-type rule table below; no check is added, dropped, or widened.

Usage: doc_validate.py --type {adr|prd|tdd|ux-spec} <file>

  stdout: OK: <file> (<type>)                        exit 0
  stderr: validation failed: <check> — <detail>      exit 1  (one line per failure)
  stderr: usage / unreadable file                    exit 2

Stdlib-only (repo script convention). Fence-aware: "## headings at column 0
outside code fences" and the placeholder scan both skip ``` fenced blocks.
"""
import argparse
import re
import sys

MATURITY_ALLOWED = ["proof-of-concept", "draft", "experimental", "stable"]
MERMAID_KEYWORDS = (
    "graph", "flowchart", "sequenceDiagram", "stateDiagram", "stateDiagram-v2",
    "erDiagram", "journey", "classDiagram", "gantt", "pie", "gitGraph",
    "mindmap", "timeline", "quadrantChart", "requirementDiagram", "C4Context",
)
COMMON_PLACEHOLDERS = ["{slug}", "{topic}", "{project_name}", "TBD", "TODO"]

# Per-type rule tables — a faithful transcription of each skill's current
# "Validation Before Save" checklist. Field meanings:
#   frontmatter: keys required present+non-empty (dependencies exempt from
#     the non-empty rule — may be the empty list []).
#   superseded_by_when: (field, value) — extra required key when field==value.
#   status_field / status_allowed: allow-list check on that field's value.
#   forbid_field: a frontmatter field whose presence is a defect.
#   sections: exact ordered list of ## headings the body must carry.
#   alternatives: ("nonempty", section) or ("subsections>=2", section).
#   mermaid: whether a ```mermaid block with a diagram-type keyword is required.
#   placeholders: banned tokens (body only, fence-exempt).
#   success_metrics: section whose list items each need a digit or comparator.
#   security_track: TDD-only conditional subsection checks keyed on updated_by.
RULES = {
    "adr": {
        "frontmatter": ["project", "last_updated", "updated_by", "status"],
        "superseded_by_when": ("status", "superseded"),
        "status_field": "status",
        "status_allowed": ["proposed", "accepted", "superseded"],
        "sections": ["Context", "Decision", "Consequences", "Alternatives Considered"],
        "alternatives": ("nonempty", "Alternatives Considered"),
        "mermaid": False,
        "placeholders": ["{slug}", "{topic}", "{project_name}", "{NNNN}", "TBD", "TODO"],
    },
    "prd": {
        "frontmatter": ["project", "maturity", "last_updated", "updated_by", "scope", "owner", "dependencies"],
        "forbid_field": "status",
        "maturity_allowed": MATURITY_ALLOWED,
        "sections": ["Problem Statement", "Goals", "Non-Goals", "User Stories / Use Cases",
                     "Requirements", "Success Metrics", "Risks & Open Questions"],
        "mermaid": True,
        "placeholders": COMMON_PLACEHOLDERS,
        "success_metrics": "Success Metrics",
    },
    "tdd": {
        "frontmatter": ["project", "maturity", "last_updated", "updated_by", "scope", "owner", "dependencies", "status"],
        "status_field": "status",
        "status_allowed": ["draft", "questions-resolved", "in-review", "accepted", "superseded"],
        "sections": ["Problem Statement", "Context & Prior Art", "Alternatives Considered",
                     "Architecture & System Design", "Data Models & Storage", "API Contracts",
                     "Migration & Rollout", "Risks & Open Questions", "Testing Strategy",
                     "Observability & Operational Readiness", "Implementation Phases"],
        "alternatives": ("subsections>=2", "Alternatives Considered"),
        "mermaid": True,
        "placeholders": COMMON_PLACEHOLDERS,
        "security_track": {
            "trigger_field": "updated_by",
            "trigger_value": "@security-engineer",
            # (check-name, required ### subsections) per host ## section — the
            # two TDD checks (§7 subsections, §8 abuse cases) stay distinct.
            "subsections": {
                "Architecture & System Design": ("security-subsections",
                                                 ["Threat Model", "Trust Boundaries", "Security Considerations"]),
                "Testing Strategy": ("security-abuse-cases", ["Abuse Cases"]),
            },
        },
    },
    "ux-spec": {
        "frontmatter": ["project", "maturity", "last_updated", "updated_by", "scope", "owner", "dependencies"],
        "forbid_field": "status",
        "maturity_allowed": MATURITY_ALLOWED,
        "sections": ["Overview", "Information Architecture", "Layout & Structure",
                     "Interaction Design", "Visual & Sensory Design", "Edge Cases & Error States",
                     "Accessibility", "Internationalization / Privacy / Measurement", "Handoff Notes"],
        "mermaid": True,
        "placeholders": COMMON_PLACEHOLDERS,
    },
}


def split_frontmatter(text):
    """Return (frontmatter_dict, body_text). Frontmatter is the block between
    the leading `---` and the next `---`. Only top-level scalar keys are
    captured (value = raw text after the colon, quotes stripped); a key with an
    empty value that is followed by `- ` list items is recorded as present with
    a sentinel non-empty marker so the presence check passes."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}, text
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        return {}, text
    fm = {}
    fm_lines = lines[1:end]
    for j, ln in enumerate(fm_lines):
        m = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):\s?(.*)$", ln)
        if not m:
            continue
        key, raw = m.group(1), m.group(2).strip()
        if raw == "":
            # A key with a following `- ` item is a non-empty list.
            if j + 1 < len(fm_lines) and re.match(r"^\s*-\s+\S", fm_lines[j + 1]):
                raw = "[list]"
        else:
            raw = raw.strip().strip('"').strip("'")
        fm[key] = raw
    body = "\n".join(lines[end + 1:])
    return fm, body


def tokenize(body):
    """Yield (idx, raw_line, in_fence, fence_info). in_fence is True for lines
    strictly inside a ``` fenced block (fence delimiters themselves are marked
    in_fence=True too so they are never treated as content). fence_info carries
    the info string on the opening delimiter (e.g. 'mermaid')."""
    records = []
    in_fence = False
    fence_info = ""
    for idx, raw in enumerate(body.split("\n")):
        m = re.match(r"^\s*```(.*)$", raw)
        if m:
            if not in_fence:
                in_fence = True
                fence_info = m.group(1).strip()
                records.append((idx, raw, True, fence_info))
            else:
                records.append((idx, raw, True, fence_info))
                in_fence = False
                fence_info = ""
            continue
        records.append((idx, raw, in_fence, fence_info))
    return records


def h2_titles(records):
    out = []
    for idx, raw, in_fence, _ in records:
        if in_fence:
            continue
        m = re.match(r"^## (.+?)\s*$", raw)
        if m:
            out.append((idx, m.group(1).strip()))
    return out


def section_bounds(records, title):
    """Return (start_idx, end_idx) record-list indices bounding the body of the
    ## section with the given title (exclusive of the next ## heading), or
    None if absent."""
    start_ri = None
    for ri, (idx, raw, in_fence, _) in enumerate(records):
        if in_fence:
            continue
        m = re.match(r"^## (.+?)\s*$", raw)
        if m and m.group(1).strip() == title:
            start_ri = ri
            break
    if start_ri is None:
        return None
    # next ## (outside fence) after start
    end_ri = len(records)
    for ri in range(start_ri + 1, len(records)):
        idx, raw, in_fence, _ = records[ri]
        if not in_fence and re.match(r"^## (.+?)\s*$", raw):
            end_ri = ri
            break
    return start_ri, end_ri


def h3_in_section(records, title):
    b = section_bounds(records, title)
    if b is None:
        return None
    start_ri, end_ri = b
    subs = []
    for ri in range(start_ri + 1, end_ri):
        idx, raw, in_fence, _ = records[ri]
        if in_fence:
            continue
        m = re.match(r"^### (.+?)\s*$", raw)
        if m:
            subs.append(m.group(1).strip())
    return subs


def validate(doc_type, text):
    rule = RULES[doc_type]
    fm, body = split_frontmatter(text)
    records = tokenize(body)
    failures = []

    # Check: frontmatter fields present + non-empty (dependencies exempt from non-empty).
    for field in rule["frontmatter"]:
        if field not in fm:
            failures.append(("frontmatter", f"required field '{field}' missing"))
        elif field != "dependencies" and fm[field] == "":
            failures.append(("frontmatter", f"required field '{field}' is empty"))
    swhen = rule.get("superseded_by_when")
    if swhen:
        f, v = swhen
        if fm.get(f) == v and not fm.get("superseded_by"):
            failures.append(("frontmatter", "status is 'superseded' but 'superseded_by' missing or empty"))

    # Check: forbidden field (prd/ux-spec — no status).
    forbid = rule.get("forbid_field")
    if forbid and forbid in fm:
        failures.append(("no-status", f"'{forbid}' field is not permitted for {doc_type}"))

    # Check: status allow-list.
    if "status_field" in rule:
        val = fm.get(rule["status_field"], "")
        if val not in rule["status_allowed"]:
            failures.append(("status", f"'{val}' not in {rule['status_allowed']}"))

    # Check: maturity allow-list.
    if "maturity_allowed" in rule:
        val = fm.get("maturity", "")
        if val not in rule["maturity_allowed"]:
            failures.append(("maturity", f"'{val}' not in {rule['maturity_allowed']}"))

    # Check: section order (exact ordered match of ## headings outside fences).
    observed = [t for _, t in h2_titles(records)]
    if observed != rule["sections"]:
        failures.append(("section-order",
                         f"expected {rule['sections']} got {observed}"))

    # Check: alternatives.
    alt = rule.get("alternatives")
    if alt:
        mode, sect = alt
        if mode == "nonempty":
            b = section_bounds(records, sect)
            if b is None:
                failures.append(("alternatives", f"section '{sect}' absent"))
            else:
                start_ri, end_ri = b
                has_content = any(
                    records[ri][1].strip() and not records[ri][2]
                    and not re.match(r"^#{2,}\s", records[ri][1])
                    for ri in range(start_ri + 1, end_ri)
                )
                if not has_content:
                    failures.append(("alternatives", f"section '{sect}' names no alternative"))
        elif mode == "subsections>=2":
            subs = h3_in_section(records, sect)
            if subs is None:
                failures.append(("alternatives", f"section '{sect}' absent"))
            elif len(subs) < 2:
                failures.append(("alternatives", f"section '{sect}' has {len(subs)} ### subsections, need >=2"))

    # Check: mermaid presence + diagram-type keyword.
    if rule.get("mermaid"):
        if not has_valid_mermaid(records):
            failures.append(("mermaid", "no ```mermaid block with a diagram-type keyword on its first non-blank line"))

    # Check: placeholder scan (body only, fence-exempt).
    for idx, raw, in_fence, _ in records:
        if in_fence:
            continue
        for tok in rule["placeholders"]:
            if tok in raw:
                failures.append(("placeholder", f"line {idx + 1}: banned token '{tok}'"))

    # Check: Success Metrics concreteness (prd).
    sm = rule.get("success_metrics")
    if sm:
        b = section_bounds(records, sm)
        if b is None:
            failures.append(("success-metrics", f"section '{sm}' absent"))
        else:
            start_ri, end_ri = b
            for ri in range(start_ri + 1, end_ri):
                idx, raw, in_fence, _ = records[ri]
                if in_fence:
                    continue
                if re.match(r"^\s*([-*]|\d+\.)\s+\S", raw):
                    if not re.search(r"[0-9<>=≤≥]", raw):
                        failures.append(("success-metrics",
                                         f"line {idx + 1}: metric has no numeric target or comparator"))

    # Check: security-track subsections (tdd, conditional on updated_by).
    st = rule.get("security_track")
    if st and fm.get(st["trigger_field"]) == st["trigger_value"]:
        for sect, (check_name, needed) in st["subsections"].items():
            subs = h3_in_section(records, sect)
            present = set(subs or [])
            for name in needed:
                if name not in present:
                    failures.append((check_name,
                                     f"section '{sect}' missing required ### '{name}'"))

    return failures


def has_valid_mermaid(records):
    i = 0
    n = len(records)
    while i < n:
        idx, raw, in_fence, info = records[i]
        if in_fence and info == "mermaid" and re.match(r"^\s*```", raw):
            # collect until the closing fence
            j = i + 1
            first = None
            while j < n:
                _, r2, inf2, _ = records[j]
                if re.match(r"^\s*```", r2):
                    break
                if r2.strip():
                    first = r2.strip()
                    break
                j += 1
            if first and first.startswith(MERMAID_KEYWORDS):
                return True
        i += 1
    return False


def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--type", required=True, choices=sorted(RULES.keys()))
    parser.add_argument("file")
    try:
        args = parser.parse_args()
    except SystemExit:
        raise SystemExit(2)

    try:
        with open(args.file, "r", encoding="utf-8") as fh:
            text = fh.read()
    except OSError as exc:
        print(f"doc_validate.py: cannot read {args.file}: {exc}", file=sys.stderr)
        raise SystemExit(2)

    failures = validate(args.type, text)
    if failures:
        for check, detail in failures:
            print(f"validation failed: {check} — {detail}", file=sys.stderr)
        raise SystemExit(1)
    print(f"OK: {args.file} ({args.type})")
    raise SystemExit(0)


if __name__ == "__main__":
    main()
