#!/usr/bin/env python3
"""Auto-generates the initial Findings Ledger skeleton (CANONICAL:IMPACT-CLASS)
that evolve-skills/evolve-agents currently hand-author at Phase 0 completion.

Input contract (no prior consumer existed -- this is the reference definition,
mirroring how findings_ledger_check.py documents itself as the reference for
the ledger grammar): a directory containing the six Phase 0 auditor files at
`{scratchpad}/phase0/<auditor>.md`, each in the Output Format its spawn
template (evolve-phase0-templates.md) defines:
  - historical-auditor.md      -- per-skill `### Skill: <name>` blocks, one
                                   `- Suggested focus areas: <bullets>` line each.
  - bug-auditor.md              -- flat `FIX <n>: ...` / `PREVENT <n>: ...`
                                   findings (optionally with CLASS/SESSIONS/
                                   SUGGESTION fields, same or later lines).
  - repetition-auditor.md       -- flat `FIX <n>:` / `PREVENT <n>:` /
                                   `BENIGN-RACE <n>:` findings (BENIGN-RACE is
                                   correct-behavior noise, never a finding).
  - innovation-scanner.md       -- per-skill blocks with four fixed lenses:
                                   Rethink, Refactor & Automate, Retire,
                                   Cross-Skill Leverage (each `<bullet>, or "none"`).
  - model-routing-auditor.md    -- per-skill blocks, one
                                   `- Routing recommendations: <bullets>` line each.
  - docs-researcher-phase0.md   -- flat `- **<capability>**: <relevance>`
                                   bullets grouped under a `Recommendations`
                                   heading (the other three headings are
                                   informational, not actionable findings).
A file that is missing, empty, or whose entire content is a `SKIPPED:` /
`UNAVAILABLE:` sentinel (or the auditor's own no-findings literal, e.g.
"No bug findings.") contributes zero findings -- not an error.

Output: one `- <ID>: <summary>` bullet per actionable finding, ID = a
single uppercase auditor-tag letter (H=historical, B=bug, R=repetition,
I=innovation, M=model-routing, D=docs-research) + a 1-based sequence number
scoped to that letter, matching the CANONICAL:IMPACT-CLASS convention
("H1, B2, I3, ..."). No terminal disposition is written -- dispositions are
assigned during Phase 1 review, in place, on this same file. Running
findings_ledger_check.py against this skeleton is therefore expected to
report every entry OPEN (exit 1), which is the correct pre-Phase-1 state; a
non-parseable-entries failure (exit 2) is the only failure mode this script
guards against structurally (every emitted line matches the checker's
`^- [A-Z][0-9]+: ` entry-start grammar).

Exit codes: 0 = ledger written (including zero-finding runs); 2 = precondition
failure (bad argv count, missing phase0-dir, or zero of the six auditor files
found) -- matching findings_ledger_check.py's reservation of 2 for exactly
this class, distinct from that script's 1 (OPEN findings remain).

Usage: findings_ledger_init.py <phase0-dir> <output-ledger-path>
"""
import re
import sys
from pathlib import Path

AUDITOR_LETTERS = {
    "historical-auditor.md": "H",
    "bug-auditor.md": "B",
    "repetition-auditor.md": "R",
    "innovation-scanner.md": "I",
    "model-routing-auditor.md": "M",
    "docs-researcher-phase0.md": "D",
    "sdlc-role-researcher.md": "S",
}

SENTINEL_RE = re.compile(r"^(SKIPPED|UNAVAILABLE):", re.IGNORECASE)
NO_FINDINGS_LITERALS = {"no bug findings.", "no repetition findings."}
SKILL_BLOCK_RE = re.compile(r"^###\s+Skill:\s*(.+?)\s*$")
MARKER_RE = re.compile(r"^(FIX|PREVENT|BENIGN-RACE)\s+\d+:\s*(.*)$")
CLASS_RE = re.compile(r"CLASS:\s*([A-Z-]+)")
SUGGESTION_RE = re.compile(r"SUGGESTION:\s*(.+?)(?:\n|$)", re.DOTALL)
DOCS_BULLET_RE = re.compile(r"^-\s+\*\*(.+?)\*\*:\s*(.+?)\s*$")
INNOVATION_LENSES = ("Rethink", "Refactor & Automate", "Retire", "Cross-Skill Leverage")


def read_auditor_file(path):
    """Returns the file's text, or "" if missing/empty/a sentinel/no-findings literal."""
    if not path.exists():
        return ""
    text = path.read_text().strip()
    if not text or SENTINEL_RE.match(text) or text.lower() in NO_FINDINGS_LITERALS:
        return ""
    return text


def field_bullets_by_skill(text, field_label):
    """Extracts `- <field_label>: <value>` lines from `### Skill:` blocks.
    Returns [(skill_name, value), ...], skipping literal "none" values."""
    findings = []
    current_skill = None
    field_re = re.compile(rf"^-\s+{re.escape(field_label)}:\s*(.+?)\s*$")
    for line in text.splitlines():
        m = SKILL_BLOCK_RE.match(line)
        if m:
            current_skill = m.group(1)
            continue
        m = field_re.match(line)
        if m:
            value = m.group(1).strip()
            if value.lower().startswith("none"):
                continue
            findings.append((current_skill, value))
    return findings


def innovation_findings(text):
    """Extracts the four fixed lenses per `### Skill:` block, skipping "none"."""
    findings = []
    current_skill = None
    lens_res = {lens: re.compile(rf"^-\s+{re.escape(lens)}:\s*(.+?)\s*$") for lens in INNOVATION_LENSES}
    for line in text.splitlines():
        m = SKILL_BLOCK_RE.match(line)
        if m:
            current_skill = m.group(1)
            continue
        for lens, lens_re in lens_res.items():
            m = lens_re.match(line)
            if m:
                value = m.group(1).strip()
                if value.lower().startswith("none"):
                    continue
                findings.append((current_skill, lens, value))
                break
    return findings


def marker_findings(text):
    """Splits flat FIX/PREVENT/BENIGN-RACE findings (bug-auditor, repetition-auditor).
    Returns [(tag, body_text), ...] excluding BENIGN-RACE (correct-behavior noise)."""
    lines = text.splitlines()
    starts = []
    for i, line in enumerate(lines):
        m = MARKER_RE.match(line.strip())
        if m:
            starts.append((i, m.group(1), m.group(2)))
    findings = []
    for idx, (line_no, tag, rest) in enumerate(starts):
        end = starts[idx + 1][0] if idx + 1 < len(starts) else len(lines)
        body = "\n".join([rest] + lines[line_no + 1:end]).strip()
        if tag == "BENIGN-RACE":
            continue
        findings.append((tag, body))
    return findings


def docs_research_findings(text):
    """Extracts `- **<capability>**: <relevance>` bullets under a Recommendations
    heading only (New Capabilities/Changed Features/Deprecated are informational)."""
    findings = []
    in_recommendations = False
    for line in text.splitlines():
        stripped = line.strip().strip("#").strip("*").strip(":").strip()
        if stripped.lower() == "recommendations":
            in_recommendations = True
            continue
        if not in_recommendations:
            continue
        m = DOCS_BULLET_RE.match(line.strip())
        if m:
            findings.append((m.group(1).strip(), m.group(2).strip()))
        elif line.strip() and not line.strip().startswith("-"):
            # a non-bullet, non-blank line ends the Recommendations section
            in_recommendations = False
    return findings


def build_entries(phase0_dir):
    """Returns [(id, summary_line), ...] across all six auditor files."""
    entries = []
    for filename, letter in AUDITOR_LETTERS.items():
        text = read_auditor_file(phase0_dir / filename)
        if not text:
            continue
        seq = 0
        if letter == "H":
            for skill, value in field_bullets_by_skill(text, "Suggested focus areas"):
                seq += 1
                skill_tag = f"[{skill}] " if skill else ""
                entries.append((f"H{seq}", f"{skill_tag}{value}"))
        elif letter == "M":
            for skill, value in field_bullets_by_skill(text, "Routing recommendations"):
                seq += 1
                skill_tag = f"[{skill}] " if skill else ""
                entries.append((f"M{seq}", f"{skill_tag}{value}"))
        elif letter == "I":
            for skill, lens, value in innovation_findings(text):
                seq += 1
                skill_tag = f"[{skill}/{lens}] " if skill else f"[{lens}] "
                entries.append((f"I{seq}", f"{skill_tag}{value}"))
        elif letter in ("B", "R"):
            for tag, body in marker_findings(text):
                if not body:
                    continue
                seq += 1
                class_m = CLASS_RE.search(body)
                sugg_m = SUGGESTION_RE.search(body)
                headline = body.splitlines()[0].strip()
                extra = []
                if class_m:
                    extra.append(f"CLASS={class_m.group(1)}")
                if sugg_m:
                    extra.append(f"SUGGESTION={sugg_m.group(1).strip()}")
                extra_tag = f" ({', '.join(extra)})" if extra else ""
                entries.append((f"{letter}{seq}", f"[{tag}] {headline}{extra_tag}"))
        elif letter == "D":
            for capability, relevance in docs_research_findings(text):
                seq += 1
                entries.append((f"D{seq}", f"{capability}: {relevance}"))
    return entries


def main(argv):
    if len(argv) != 3:
        print("Usage: findings_ledger_init.py <phase0-dir> <output-ledger-path>", file=sys.stderr)
        return 2

    phase0_dir = Path(argv[1])
    output_path = Path(argv[2])

    if not phase0_dir.is_dir():
        print(f"findings_ledger_init.py: phase0 directory does not exist: {phase0_dir}", file=sys.stderr)
        return 2

    found = sum(1 for filename in AUDITOR_LETTERS if (phase0_dir / filename).is_file())
    if found == 0:
        print(
            f"findings_ledger_init.py: no auditor files found under {phase0_dir} "
            f"(expected one of: {', '.join(AUDITOR_LETTERS)}); refusing to write a ledger "
            "-- check for a mistyped or unsubstituted phase0-dir argument",
            file=sys.stderr,
        )
        return 2

    entries = build_entries(phase0_dir)
    lines = [f"- {entry_id}: {summary}" for entry_id, summary in entries]
    output_path.write_text("\n".join(lines) + ("\n" if lines else ""))

    print(f"findings_ledger_init.py: wrote {len(entries)} finding(s) to {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
