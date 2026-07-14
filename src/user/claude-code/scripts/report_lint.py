#!/usr/bin/env python3
"""Shared "Validation Before Emit" checker for the report-emission skills
(code-review-verdict, verify-ac, design-review, design-qa), previously
hand-maintained as per-skill prose checklists. Each skill's text-decidable
checks are transcribed check-for-check into the per-skill parameter tables
below; per-skill parameterization is preserved, never flattened. No check is
added, dropped, or widened; checks needing external state (a resolved diff's
file list, a Docket issue's AC list, semantic evidence quality, the
override-vs-diff arm) stay in the skill as prose and are NOT mechanized here.

Usage: report_lint.py --skill {code-review-verdict|verify-ac|design-review|design-qa|investigator}
                      [--mode full|round-n|light] <file>

  stdout: OK: <skill> report (<mode>)                exit 0
  stderr: validation failed: <check> — <detail>      exit 1  (one line per failure)
  stderr: usage / unknown skill / unreadable         exit 2

  --mode default: full. round-n is valid only with code-review-verdict.
  light is valid only with verify-ac and short-circuits to exit 0 by contract
  (verify-ac LIGHT mode is a single line — nothing to lint).

  The ``investigator`` profile is not a report-emission skill but the
  distinguished-engineer.md Mode 3 output contract for an investigator-class
  report. It checks exactly three text-decidable items and nothing else (no
  section-order/bucket machinery applies): a COVERAGE statement is present,
  the OBSERVED/REPRODUCED/INFERRED label vocabulary is used, and any expressed
  uncertainty is paired with a next-probe. No check is added, dropped, or
  widened beyond those three.

Stdlib-only (repo script convention). Fence-aware: the placeholder and
banned-phrase scans skip ``` fenced blocks.
"""
import argparse
import re
import sys

# The banned confidence phrases — identical across all four skills' current
# "Epistemic discipline scan" checklists (this is the check being centralized).
BANNED_PHRASES = ["clearly", "obviously", "should work", "definitely", "100%", "guaranteed"]
_ALPHA_BANNED = [p for p in BANNED_PHRASES if p.isalpha()]
_OTHER_BANNED = [p for p in BANNED_PHRASES if not p.isalpha()]
_BANNED_RE = re.compile(
    "|".join([r"\b" + re.escape(p) + r"\b" for p in _ALPHA_BANNED]
             + [re.escape(p) for p in _OTHER_BANNED]),
    re.IGNORECASE,
)

# code-review-verdict is one skill with two roles (general/security) and a
# compact Round-N template. Each concrete report resolves to exactly one
# variant, selected by its banner (full mode) or by --mode round-n.
CRV_GENERAL = {
    "banner_re": r"^## Review \(general — @staff-engineer\)\s*$",
    "sections": ["Summary", "Scope Reviewed", "Risk Assessment", "Findings",
                 "Hard Gates Triggered", "Dimension Checklist", "Recommendation", "Next Steps"],
    "buckets": ["Blockers", "Concerns", "Suggestions", "Questions", "Praise", "Overrides Recognized"],
    "allowlist": ["Approve", "Approve with follow-up", "Request changes", "Block", "Split required"],
    "hard_gate": True,
}
CRV_SECURITY = {
    "banner_re": r"^## Review \(security — @security-engineer\)\s*$",
    "sections": ["Summary", "Scope Reviewed", "Threat Model (assumed)", "Risk Assessment",
                 "Findings", "Required Mitigations", "Dimension Checklist", "Recommendation", "Next Steps"],
    "buckets": ["Critical", "High", "Medium", "Low", "Info"],
    "allowlist": ["Approve (security)", "Approve with follow-up", "Block (security)", "Split required"],
    "hard_gate": False,
}

SKILLS = {
    "code-review-verdict": {
        "trailing": "Code review emitted",
        "placeholders": ["{file:line}", "{count}", "{scope}", "TBD", "TODO"],
        "banned_sections": ["Findings", "Recommendation"],
        "crv": True,
        # LGTM short-forms are legitimate trivial emissions with no structure to lint.
        "shortform_re": r"^LGTM\b",
        "round_n": {
            "banner_re": r"^## Re-Review Round-",
            "labels": ["Prior Findings Disposition", "New Findings", "Recommendation"],
            "allowlist": (CRV_GENERAL["allowlist"] + CRV_SECURITY["allowlist"]),
        },
    },
    "verify-ac": {
        "trailing": "Verification report emitted",
        "placeholders": ["{Issue ID}", "{count}", "{evidence}", "TBD", "TODO"],
        "banned_sections": ["Acceptance Criteria", "Additional Testing", "Issues Found", "Recommendation"],
        "banner_re": r"^## Verification: ",
        "sections": ["Acceptance Criteria", "Additional Testing", "Test Coverage",
                     "Issues Found", "Recommendation"],
        "buckets": ["Critical", "High", "Medium", "Low"],
        "buckets_section": "Issues Found",
        "allowlist": ["APPROVE", "ACCEPT WITH CAVEATS", "BLOCK"],
        "verdict_rule": "verify-ac",
    },
    "design-review": {
        "trailing": "Design review emitted",
        "placeholders": ["{Artifact Title}", "{dimension}", "{count}", "TBD", "TODO"],
        "banned_sections": ["What's Strong", "What Needs Work", "Open Questions", "Next Steps"],
        "banner_re": r"^## Design Review: ",
        "sections": ["Assessment", "Artifact", "What's Strong", "What Needs Work",
                     "Open Questions", "Dimension Checklist", "Recommendation", "Next Steps"],
        "buckets": ["Blockers", "Concerns", "Suggestions", "Questions"],
        "buckets_section": "What Needs Work",
        "allowlist": ["Approve", "Approve with follow-up", "Block", "Redesign", "Incremental Improvement"],
        "verdict_rule": "design-review",
        "dimensions": ["Usability", "Consistency", "Accessibility",
                       "Information Hierarchy", "Error Handling", "Performance Perception"],
        "blocker_dimension_tag": True,
    },
    "design-qa": {
        "trailing": "Design QA report emitted",
        "placeholders": ["{Spec Title}", "{spec heading}", "TBD", "TODO"],
        "banned_sections": ["Issues", "What's Implemented Well", "Acceptable Deviations", "Recommendation"],
        "banner_re": r"^## Design QA: ",
        "sections": ["Spec Reference", "Verdict", "Issues", "What's Implemented Well",
                     "Acceptable Deviations", "Recommendation"],
        "allowlist": ["Pass", "Pass with Issues", "Fail"],
        "verdict_rule": "design-qa",
        "issues_table": True,
    },
    "investigator": {
        # distinguished-engineer.md Mode 3 output contract — not a report skill.
        "investigator_profile": True,
    },
}

# Investigator-profile vocabularies (distinguished-engineer.md Mode 3).
_EVIDENCE_LABELS = ["OBSERVED", "REPRODUCED", "INFERRED"]
_UNCERTAINTY_CUES = re.compile(
    r"\b(inconclusive|low[- ]confidence|uncertain|unresolved|indeterminate|unclear|cannot determine)\b",
    re.IGNORECASE,
)
_NEXT_PROBE_CUE = re.compile(r"next[- ]probe|next probe", re.IGNORECASE)


def tokenize(text):
    """Yield records (idx, raw, in_fence) for each line. Fence delimiters are
    marked in_fence=True so they are never treated as content."""
    records = []
    in_fence = False
    for idx, raw in enumerate(text.split("\n")):
        if re.match(r"^\s*```", raw):
            records.append((idx, raw, True))
            in_fence = not in_fence
            continue
        records.append((idx, raw, in_fence))
    return records


def h3_titles(records):
    out = []
    for idx, raw, in_fence in records:
        if in_fence:
            continue
        m = re.match(r"^### (.+?)\s*$", raw)
        if m:
            out.append(m.group(1).strip())
    return out


def section_bounds(records, title):
    """Record-index bounds (start, end) of the ### section with this title,
    ending at the next ###/## heading, or None if absent."""
    start = None
    for ri, (idx, raw, in_fence) in enumerate(records):
        if in_fence:
            continue
        m = re.match(r"^### (.+?)\s*$", raw)
        if m and m.group(1).strip() == title:
            start = ri
            break
    if start is None:
        return None
    end = len(records)
    for ri in range(start + 1, len(records)):
        idx, raw, in_fence = records[ri]
        if not in_fence and re.match(r"^#{2,3} (.+?)\s*$", raw):
            end = ri
            break
    return start, end


def section_text(records, title):
    b = section_bounds(records, title)
    if b is None:
        return None
    start, end = b
    return "\n".join(records[ri][1] for ri in range(start + 1, end))


def bucket_state(records, section_title, bucket, buckets):
    """Classify a **bucket** inside a ### section: 'missing' | 'empty' | 'ok'.
    'ok' = the bucket lists a content bullet or the literal None. The region is
    the bold label line up to the next bold bucket label / heading."""
    b = section_bounds(records, section_title)
    if b is None:
        return "missing"
    start, end = b
    label_ri = None
    for ri in range(start + 1, end):
        if records[ri][1].strip().startswith(f"**{bucket}**"):
            label_ri = ri
            break
    if label_ri is None:
        return "missing"
    region_end = end
    other = [x for x in buckets if x != bucket]
    for ri in range(label_ri + 1, end):
        stripped = records[ri][1].strip()
        if any(stripped.startswith(f"**{o}**") for o in other):
            region_end = ri
            break
    label_line = records[label_ri][1]
    if "None" in label_line:
        return "ok"
    for ri in range(label_ri + 1, region_end):
        raw = records[ri][1]
        if "None" in raw:
            return "ok"
        m = re.match(r"^\s*-\s+(\S.*)$", raw)
        if m and not m.group(1).lstrip().startswith("..."):
            return "ok"
    return "empty"


def parse_trailing(text, prefix):
    """Return the chosen verdict/recommendation from the trailing confirmation
    line `<prefix> (<value>).`, or None if absent."""
    m = re.search(r"^" + re.escape(prefix) + r" \((.+?)\)\.\s*$", text, re.M)
    return m.group(1).strip() if m else None


def scan_placeholders(records, tokens):
    hits = []
    for idx, raw, in_fence in records:
        if in_fence:
            continue
        for tok in tokens:
            if tok in raw:
                hits.append((idx + 1, tok))
    return hits


def scan_banned(records, sections):
    """Banned-phrase scan scoped to the named sections only (whole-body scanning
    would widen semantics — rejected by the design), fence-exempt."""
    hits = []
    for title in sections:
        b = section_bounds(records, title)
        if b is None:
            continue
        start, end = b
        for ri in range(start + 1, end):
            idx, raw, in_fence = records[ri]
            if in_fence:
                continue
            m = _BANNED_RE.search(raw)
            if m:
                hits.append((title, idx + 1, m.group(0)))
    return hits


def bucket_counts(records, section_title, buckets):
    """Count content bullets (non-None) per bucket in a Findings/Issues section."""
    counts = {}
    for bucket in buckets:
        b = section_bounds(records, section_title)
        counts[bucket] = 0
        if b is None:
            continue
        start, end = b
        label_ri = None
        for ri in range(start + 1, end):
            if records[ri][1].strip().startswith(f"**{bucket}**"):
                label_ri = ri
                break
        if label_ri is None:
            continue
        region_end = end
        other = [x for x in buckets if x != bucket]
        for ri in range(label_ri + 1, end):
            stripped = records[ri][1].strip()
            if any(stripped.startswith(f"**{o}**") for o in other):
                region_end = ri
                break
        n = 0
        for ri in range(label_ri + 1, region_end):
            m = re.match(r"^\s*-\s+(\S.*)$", records[ri][1])
            if m:
                content = m.group(1).strip()
                if content != "None" and not content.startswith("..."):
                    n += 1
        counts[bucket] = n
    return counts


def ac_marker_counts(records):
    """Count PASS/FAIL/OUT-OF-SCOPE criterion bullets in verify-ac's Acceptance
    Criteria section. A bullet with exactly one marker is classified by it. A
    bullet with two markers (prose mentioning a second marker word, e.g.
    "PASS — verified the FAIL path") is classified by whichever marker token
    appears first in the line. An unfilled scaffold carrying all three markers
    is still counted as none — the AC-coverage arm that catches unfilled
    scaffolds stays in the skill."""
    b = section_bounds(records, "Acceptance Criteria")
    counts = {"PASS": 0, "FAIL": 0, "OUT-OF-SCOPE": 0}
    if b is None:
        return counts
    start, end = b
    for ri in range(start + 1, end):
        idx, raw, in_fence = records[ri]
        if in_fence:
            continue
        if not re.match(r"^\s*-\s*\[", raw):
            continue
        present = [k for k in ("PASS", "FAIL", "OUT-OF-SCOPE") if k in raw]
        if len(present) == 1:
            counts[present[0]] += 1
        elif len(present) == 2:
            first = min(present, key=raw.index)
            counts[first] += 1
    return counts


def verdict_severity_failures(records, rule, verdict, cfg):
    """Per-skill verdict ↔ severity-count consistency."""
    f = []
    if rule == "verify-ac":
        counts = bucket_counts(records, "Issues Found", cfg["buckets"])
        crit, high = counts["Critical"], counts["High"]
        med, low = counts["Medium"], counts["Low"]
        ac = ac_marker_counts(records)
        if verdict == "APPROVE":
            if crit or high:
                f.append(("verdict-consistency", "APPROVE with a Critical/High issue"))
            if ac["FAIL"]:
                f.append(("verdict-consistency", "APPROVE with a FAIL criterion"))
            if ac["OUT-OF-SCOPE"]:
                f.append(("verdict-consistency", "APPROVE with an OUT-OF-SCOPE criterion"))
        elif verdict == "ACCEPT WITH CAVEATS":
            if not (med or low or ac["OUT-OF-SCOPE"]):
                f.append(("verdict-consistency",
                          "ACCEPT WITH CAVEATS requires a Medium/Low issue or an OUT-OF-SCOPE criterion"))
        elif verdict == "BLOCK":
            if crit + high + med + low == 0:
                f.append(("verdict-consistency",
                          "BLOCK requires at least one Issue Found across severities"))
            if not (crit or high or ac["FAIL"]):
                f.append(("verdict-consistency",
                          "BLOCK requires a Critical/High issue or a FAIL criterion"))
    elif rule == "design-review":
        counts = bucket_counts(records, "What Needs Work", cfg["buckets"])
        blockers, concerns = counts["Blockers"], counts["Concerns"]
        if blockers and verdict not in ("Block", "Redesign", "Incremental Improvement"):
            f.append(("verdict-consistency",
                      f"a Blocker requires Block/Redesign/Incremental Improvement, got '{verdict}'"))
        elif not blockers and concerns and verdict not in (
                "Approve with follow-up", "Redesign", "Incremental Improvement"):
            f.append(("verdict-consistency",
                      "a Concern (no Blocker) requires Approve with follow-up/Redesign/"
                      f"Incremental Improvement, got '{verdict}'"))
    elif rule == "design-qa":
        sev = design_qa_severities(records)
        blockers = sev.count("Blocker")
        concerns = sev.count("Concern")
        if blockers and verdict != "Fail":
            f.append(("verdict-consistency", f"a Blocker requires Fail, got '{verdict}'"))
        elif not blockers and concerns and verdict != "Pass with Issues":
            f.append(("verdict-consistency", f"a Concern (no Blocker) requires Pass with Issues, got '{verdict}'"))
        elif not blockers and not concerns and verdict != "Pass":
            f.append(("verdict-consistency", f"no Blocker/Concern requires Pass, got '{verdict}'"))
    return f


def design_qa_rows(records):
    """Return the Issues table's data rows as lists of cell strings."""
    b = section_bounds(records, "Issues")
    if b is None:
        return []
    start, end = b
    rows = []
    for ri in range(start + 1, end):
        idx, raw, in_fence = records[ri]
        if in_fence:
            continue
        line = raw.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if not cells:
            continue
        joined = "".join(cells).replace("-", "").replace(":", "").strip()
        if joined == "":  # separator row
            continue
        if cells[0] == "#":  # header row
            continue
        rows.append(cells)
    return rows


def design_qa_severities(records):
    out = []
    for cells in design_qa_rows(records):
        if len(cells) >= 2:
            out.append(cells[1])
    return out


def validate_full(skill, cfg, records, text):
    failures = []

    # Resolve crv role variant from the banner.
    variant = None
    if cfg.get("crv"):
        heading = next((r for _, r, inf in records if not inf and r.startswith("## ")), "")
        if re.match(CRV_GENERAL["banner_re"], heading):
            variant = CRV_GENERAL
        elif re.match(CRV_SECURITY["banner_re"], heading):
            variant = CRV_SECURITY
        else:
            failures.append(("heading", "no recognized review banner "
                             "(## Review (general — @staff-engineer) / (security — @security-engineer))"))
            return failures
        sections = variant["sections"]
        buckets = variant["buckets"]
        allowlist = variant["allowlist"]
        buckets_section = "Findings"
    else:
        m = re.search(cfg["banner_re"], text, re.M)
        if not m:
            failures.append(("heading", f"missing report heading matching {cfg['banner_re']!r}"))
        sections = cfg["sections"]
        buckets = cfg.get("buckets", [])
        allowlist = cfg["allowlist"]
        buckets_section = cfg.get("buckets_section")

    # Required sections present, in order.
    observed = h3_titles(records)
    if observed != sections:
        failures.append(("section-order", f"expected {sections} got {observed}"))

    # Empty severity buckets explicit.
    for bucket in buckets:
        state = bucket_state(records, buckets_section, bucket, buckets)
        if state == "missing":
            failures.append(("empty-bucket", f"severity bucket '{bucket}' missing"))
        elif state == "empty":
            failures.append(("empty-bucket", f"severity bucket '{bucket}' is neither None nor lists items"))

    # Recommendation/verdict on allow-list + trailing confirmation line present.
    verdict = parse_trailing(text, cfg["trailing"])
    if verdict is None:
        failures.append(("trailing-confirmation",
                         f"missing trailing line `{cfg['trailing']} (<value>).`"))
    elif verdict not in allowlist:
        failures.append(("recommendation", f"'{verdict}' not on allow-list {allowlist}"))

    # Placeholder scan (fence-exempt).
    for line_no, tok in scan_placeholders(records, cfg["placeholders"]):
        failures.append(("placeholder", f"line {line_no}: banned token '{tok}'"))

    # Banned-confidence-phrase scan (scoped to named sections).
    for title, line_no, phrase in scan_banned(records, cfg["banned_sections"]):
        failures.append(("banned-phrase", f"{title} line {line_no}: '{phrase}'"))

    # Verdict ↔ severity-count consistency (verify-ac / design-review / design-qa).
    if cfg.get("verdict_rule") and verdict is not None:
        failures.extend(verdict_severity_failures(records, cfg["verdict_rule"], verdict, cfg))

    # Hard-gate ↔ Blocker cross-listing (crv general only; report-internal arm).
    if variant is not None and variant.get("hard_gate"):
        failures.extend(hard_gate_failures(records))

    # design-review Blocker structure + Dimension Checklist completeness.
    if skill == "design-review":
        failures.extend(design_review_structure(records, cfg))

    # design-qa Issues-table Spec-Section / evidence columns non-empty.
    if cfg.get("issues_table"):
        failures.extend(design_qa_table_failures(records))

    return failures


def hard_gate_failures(records):
    f = []
    gates_triggered = {}
    b = section_bounds(records, "Hard Gates Triggered")
    if b is not None:
        start, end = b
        for ri in range(start + 1, end):
            raw = records[ri][1]
            m = re.match(r"^\s*-\s*\*\*G([1-5])", raw)
            if m:
                gates_triggered[m.group(1)] = "None" not in raw
        for g in ("1", "2", "3", "4", "5"):
            if g not in gates_triggered:
                f.append(("hard-gate-enumeration",
                          f"Hard Gates Triggered is missing G{g} (must list every gate, even if None)"))
    fb = section_bounds(records, "Findings")
    cited = set()
    if fb is not None:
        start, end = fb
        in_blockers = False
        for ri in range(start + 1, end):
            stripped = records[ri][1].strip()
            if stripped.startswith("**Blockers**"):
                in_blockers = True
                continue
            if stripped.startswith("**") and not stripped.startswith("**Blockers**"):
                in_blockers = False
            if in_blockers:
                for g in re.findall(r"\bG([1-5])\b", records[ri][1]):
                    cited.add(g)
    for g in sorted(cited):
        if not gates_triggered.get(g, False):
            f.append(("hard-gate-consistency",
                      f"Blocker cites G{g} but Hard Gates Triggered marks G{g} None/absent"))
    return f


def design_review_structure(records, cfg):
    f = []
    dims = cfg["dimensions"]
    # Blocker bullets: dimension tag + alternative/fix fragment.
    b = section_bounds(records, "What Needs Work")
    if b is not None:
        start, end = b
        for label, checks in (("Blockers", ("tag", "fix")), ("Concerns", ("tag",))):
            label_ri = None
            for ri in range(start + 1, end):
                if records[ri][1].strip().startswith(f"**{label}**"):
                    label_ri = ri
                    break
            if label_ri is None:
                continue
            region_end = end
            for ri in range(label_ri + 1, end):
                s = records[ri][1].strip()
                if s.startswith("**") and not s.startswith(f"**{label}**"):
                    region_end = ri
                    break
            for ri in range(label_ri + 1, region_end):
                m = re.match(r"^\s*-\s+(\S.*)$", records[ri][1])
                if not m:
                    continue
                body = m.group(1).strip()
                if body == "None" or body.startswith("..."):
                    continue
                tagm = re.match(r"^\[([^\]]+)\]\s*(\S.*)$", body)
                if "tag" in checks:
                    if not tagm or tagm.group(1).strip() not in dims:
                        f.append(("blocker-dimension-tag",
                                  f"{label} bullet lacks a valid [dimension] tag: {body[:50]!r}"))
                        continue
                if "fix" in checks and "—" not in body:
                    f.append(("blocker-fix-fragment",
                              f"Blocker bullet lacks a '—' alternative/fix fragment: {body[:50]!r}"))
    # Dimension Checklist covers all six dimensions with a status.
    ct = section_text(records, "Dimension Checklist") or ""
    allowed_status = {"pass", "concern", "fail", "N/A"}
    for dim in dims:
        row = re.search(r"^\|\s*" + re.escape(dim) + r"\s*\|\s*(\S[^|]*?)\s*\|", ct, re.M)
        if not row:
            f.append(("dimension-checklist", f"dimension '{dim}' missing or has no status"))
        elif row.group(1).strip() not in allowed_status:
            f.append(("dimension-checklist",
                      f"dimension '{dim}' status '{row.group(1).strip()}' not in pass/concern/fail/N/A"))
    return f


def design_qa_table_failures(records):
    f = []
    for cells in design_qa_rows(records):
        if len(cells) < 4:
            continue
        severity = cells[1]
        if severity in ("Blocker", "Concern"):
            if cells[2] == "":
                f.append(("spec-section", f"{severity} row has empty Spec Section"))
            if cells[3] == "":
                f.append(("evidence", f"{severity} row has empty Description/evidence"))
    return f


def validate_round_n(cfg, records, text):
    failures = []
    rn = cfg["round_n"]
    heading = next((r for _, r, inf in records if not inf and r.startswith("## ")), "")
    if not re.match(rn["banner_re"], heading):
        failures.append(("heading", "missing `## Re-Review Round-{N} ({role})` heading"))
    body = text
    for label in rn["labels"]:
        if not re.search(r"\*\*" + re.escape(label), body) and not re.search(
                r"^###\s+" + re.escape(label), body, re.M):
            failures.append(("section", f"Round-N section '{label}' missing"))
    verdict = parse_trailing(text, cfg["trailing"])
    if verdict is None:
        failures.append(("trailing-confirmation",
                         f"missing trailing line `{cfg['trailing']} (<value>).`"))
    elif verdict not in rn["allowlist"]:
        failures.append(("recommendation", f"'{verdict}' not on allow-list {rn['allowlist']}"))
    for line_no, tok in scan_placeholders(records, cfg["placeholders"]):
        failures.append(("placeholder", f"line {line_no}: banned token '{tok}'"))
    # Round-N banned-phrase scan over the whole compact body (its sections are
    # bold-labelled, not ### — scanning the body is the faithful analogue).
    for idx, raw, in_fence in records:
        if in_fence:
            continue
        m = _BANNED_RE.search(raw)
        if m:
            failures.append(("banned-phrase", f"line {idx + 1}: '{m.group(0)}'"))
    return failures


def validate_investigator(records, text):
    """distinguished-engineer.md Mode 3 output contract — three text-decidable
    checks, fence-aware, nothing else:
      1. a COVERAGE statement is present;
      2. the OBSERVED/REPRODUCED/INFERRED label vocabulary is used;
      3. any expressed uncertainty is paired with a next-probe."""
    failures = []
    content = "\n".join(raw for _, raw, in_fence in records if not in_fence)

    if not re.search(r"\bcoverage\b", content, re.IGNORECASE):
        failures.append(("coverage-statement",
                         "no COVERAGE statement (what case-space was examined vs not)"))

    if not any(re.search(r"\b" + lbl + r"\b", content) for lbl in _EVIDENCE_LABELS):
        failures.append(("evidence-labels",
                         "none of OBSERVED/REPRODUCED/INFERRED present — findings must be labeled"))

    if _UNCERTAINTY_CUES.search(content) and not _NEXT_PROBE_CUE.search(content):
        failures.append(("next-probe",
                         "report expresses uncertainty but names no next-probe to resolve it"))

    return failures


def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--skill", required=True, choices=sorted(SKILLS.keys()))
    parser.add_argument("--mode", default="full", choices=["full", "round-n", "light"])
    parser.add_argument("file")
    try:
        args = parser.parse_args()
    except SystemExit:
        raise SystemExit(2)

    cfg = SKILLS[args.skill]

    # Mode gating.
    if args.mode == "round-n" and args.skill != "code-review-verdict":
        print(f"report_lint.py: --mode round-n is valid only with code-review-verdict",
              file=sys.stderr)
        raise SystemExit(2)
    if args.mode == "light" and args.skill != "verify-ac":
        print(f"report_lint.py: --mode light is valid only with verify-ac", file=sys.stderr)
        raise SystemExit(2)
    if args.mode == "light":
        # verify-ac LIGHT is a single line — nothing to lint (short-circuit by contract).
        print(f"OK: {args.skill} report (light)")
        raise SystemExit(0)

    try:
        with open(args.file, "r", encoding="utf-8") as fh:
            text = fh.read()
    except OSError as exc:
        print(f"report_lint.py: cannot read {args.file}: {exc}", file=sys.stderr)
        raise SystemExit(2)

    records = tokenize(text)

    # crv LGTM short-form is a legitimate trivial emission (no structure to lint).
    if cfg.get("shortform_re") and re.match(cfg["shortform_re"], text.strip()):
        print(f"OK: {args.skill} report ({args.mode})")
        raise SystemExit(0)

    if cfg.get("investigator_profile"):
        failures = validate_investigator(records, text)
    elif args.mode == "round-n":
        failures = validate_round_n(cfg, records, text)
    else:
        failures = validate_full(args.skill, cfg, records, text)

    if failures:
        for check, detail in failures:
            print(f"validation failed: {check} — {detail}", file=sys.stderr)
        raise SystemExit(1)
    print(f"OK: {args.skill} report ({args.mode})")
    raise SystemExit(0)


if __name__ == "__main__":
    main()
