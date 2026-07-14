#!/usr/bin/env python3
"""Byte-symmetry linter for parity-locked CANONICAL blocks shared across the
evolve-agents / evolve-skills / evolve-config skill family.

Mechanizes evolve-agents/SKILL.md Phase 2 coherence check 5: each CANONICAL block that
must be byte-identical across its declared carrier files, modulo an established set of
agent<->skill noun substitutions where applicable. Each carrier's block is normalized
(default: identity) and diffed against a single reference carrier's block verbatim.

- ``impact-class``: CANONICAL:IMPACT-CLASS, carriers evolve-agents + evolve-skills,
  reference evolve-skills, evolve-agents normalized into skill vocabulary. The
  historical/repetition/bug/model-routing auditor templates, the Innovation Scan and
  Docs Research Phase-0 templates, and the HARVEST block are all single-homed in
  evolve-phase0-templates.md and so are symmetric by construction — no longer compared
  here.
- ``trial-protocol``: CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL, carriers evolve-agents +
  evolve-skills + evolve-config, reference evolve-agents, pure byte-identity (no
  vocabulary substitution — the block carries no agent/skill/config-specific vocab).
- ``disambiguation-charter``, ``phase3-boundary``, ``genetic-drift``,
  ``second-failure-recovery``, ``operator-prompts``: five more real-bug-risk spines
  (DKT-288) shared verbatim across evolve-agents + evolve-skills + evolve-config, all
  pure byte-identity (no agent/skill/config-specific vocab in any of the five blocks).
- ``mimir-note`` (mode ``presence``, DKT-287): mechanizes the Phase 2 coherence-reviewer's
  manual eyeball check that the historical-auditor Mimir note is present in each of the
  §3a/§3b/§3c historical-audit variants in evolve-phase0-templates.md. Unlike the
  byte-identity checks above, this only verifies pattern presence per section — the
  historical-auditor variants are intentionally structurally asymmetric.

The calibrated normalizer below is retained as the reference inventory of known
agent<->skill divergences (evolve-phase0-templates.md §1), though the sole remaining
CANONICAL:IMPACT-CLASS block carries no agent/skill vocabulary and so needs no substitution.

Read-only. Never edits, never commits. Stdlib only.
"""

import argparse
import difflib
import re
import sys
from pathlib import Path

FILES = {
    "agents": ".claude/skills/evolve-agents/SKILL.md",
    "skills": ".claude/skills/evolve-skills/SKILL.md",
    "config": ".claude/skills/evolve-config/SKILL.md",
    "phase0-templates": "src/user/claude-code/skills/team-doctrine/references/evolve-phase0-templates.md",
}

# Tokens that CONTAIN "agent"/"skill" but must never be rewritten by the generic
# word-level substitution below (identifiers, tool-call syntax, role names shared
# verbatim by both sides). Masked out before normalization, restored after.
PROTECTED_LITERALS = [
    "subagent_type",
    "Agent(",
    "innovation-scanner",
    "historical-auditor",
    "model-routing-auditor",
    "SendMessage",
    "sub-agents",
    "sub-agent",
    "agent-memory",
    "Agent memory",
]

# Bespoke structural asymmetries: not clean token swaps (different glob count, a verb
# change, an article change), so the whole clause is substituted verbatim. Applied
# before the generic word rule so the generic rule never sees these clauses.
STRUCTURAL_RULES = [
    (
        "count operator-typed `@<agent>` mentions in the window per target agent",
        "count operator-typed `/<skill>` invocations in the window per target skill",
    ),
    (
        "Read src/user/claude-code/agents/*.md and surface",
        "Read .claude/skills/*/SKILL.md and src/user/claude-code/skills/*/SKILL.md and surface",
    ),
    (
        "If a category is empty for an agent, write",
        "If a category is empty for a skill, write",
    ),
]

# Clean token substitutions that the generic word-boundary rule below cannot reach
# because the token is joined by "_" or "{}" (no regex word-boundary at the join).
TOKEN_RULES = [
    ("{target_agents}", "{target_skills}"),
    ("agent_name", "skill_name"),
]

# Generic clean substitution for the remaining bare "agent"/"agents" occurrences
# (Cross-Agent, target agent, agent role, agent definition, <agent-name>, etc.).
# Negative lookbehind keeps "sub-agent(s)" untouched even though PROTECTED_LITERALS
# already masks it (belt-and-suspenders: this regex must never re-corrupt it).
_WORD_MAP = {"Agents": "Skills", "agents": "skills", "Agent": "Skill", "agent": "skill"}
_WORD_RE = re.compile(r"(?<!sub-)(?<!Sub-)\b(Agents|agents|Agent|agent)\b")

_PLACEHOLDER = "\x00{}\x00"


def normalize(text: str) -> str:
    """Rewrite agent-flavored text into skill-flavored text (the calibrated normalizer)."""
    masked = text
    for i, literal in enumerate(PROTECTED_LITERALS):
        masked = masked.replace(literal, _PLACEHOLDER.format(i))
    for old, new in STRUCTURAL_RULES:
        masked = masked.replace(old, new)
    for old, new in TOKEN_RULES:
        masked = masked.replace(old, new)
    masked = _WORD_RE.sub(lambda m: _WORD_MAP[m.group(0)], masked)
    for i, literal in enumerate(PROTECTED_LITERALS):
        masked = masked.replace(_PLACEHOLDER.format(i), literal)
    return masked


def extract_block(text: str, start_pattern: str, end_pattern: str, include_end: bool = False) -> str:
    """Extract lines from the first line matching start_pattern up to end_pattern."""
    lines = text.splitlines()
    start_re = re.compile(start_pattern)
    end_re = re.compile(end_pattern)
    start_idx = None
    end_idx = len(lines)
    for i, line in enumerate(lines):
        if start_idx is None:
            if start_re.search(line):
                start_idx = i
            continue
        if end_re.search(line):
            end_idx = i + 1 if include_end else i
            break
    if start_idx is None:
        raise ValueError(f"block start pattern not found: {start_pattern!r}")
    return "\n".join(lines[start_idx:end_idx]).strip("\n")


CHECKS = {
    "impact-class": {
        "start": r"^<!-- CANONICAL:IMPACT-CLASS:BEGIN -->$",
        "end": r"^<!-- CANONICAL:IMPACT-CLASS:END -->$",
        "include_end": True,
        "files": ["agents", "skills"],
        "reference": "skills",
        "normalize": {"agents": normalize},
    },
    "trial-protocol": {
        "start": r"^<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:BEGIN -->$",
        "end": r"^<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:END -->$",
        "include_end": True,
        "files": ["agents", "skills", "config"],
        "reference": "agents",
        "normalize": {},
    },
    "disambiguation-charter": {
        "start": r"^<!-- CANONICAL:DISAMBIGUATION-CHARTER:BEGIN -->$",
        "end": r"^<!-- CANONICAL:DISAMBIGUATION-CHARTER:END -->$",
        "include_end": True,
        "files": ["agents", "skills", "config"],
        "reference": "agents",
        "normalize": {},
    },
    "phase3-boundary": {
        "start": r"^<!-- CANONICAL:PHASE3-DISAMBIGUATION-BOUNDARY:BEGIN -->$",
        "end": r"^<!-- CANONICAL:PHASE3-DISAMBIGUATION-BOUNDARY:END -->$",
        "include_end": True,
        "files": ["agents", "skills", "config"],
        "reference": "agents",
        "normalize": {},
    },
    "genetic-drift": {
        "start": r"^<!-- CANONICAL:GENETIC-DRIFT-OPERATOR:BEGIN -->$",
        "end": r"^<!-- CANONICAL:GENETIC-DRIFT-OPERATOR:END -->$",
        "include_end": True,
        "files": ["agents", "skills", "config"],
        "reference": "agents",
        "normalize": {},
    },
    "second-failure-recovery": {
        "start": r"^<!-- CANONICAL:SECOND-FAILURE-RECOVERY:BEGIN -->$",
        "end": r"^<!-- CANONICAL:SECOND-FAILURE-RECOVERY:END -->$",
        "include_end": True,
        "files": ["agents", "skills", "config"],
        "reference": "agents",
        "normalize": {},
    },
    "operator-prompts": {
        "start": r"^<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:BEGIN -->$",
        "end": r"^<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:END -->$",
        "include_end": True,
        "files": ["agents", "skills", "config"],
        "reference": "agents",
        "normalize": {},
    },
    "mimir-note": {
        "mode": "presence",
        "file": "phase0-templates",
        "sections": [
            ("3a", r"^### 3a\. Historical Audit", r"^### 3b\. Historical Audit"),
            ("3b", r"^### 3b\. Historical Audit", r"^### 3c\. Historical Audit"),
            ("3c", r"^### 3c\. Historical Audit", r"^## 4\. Repetition Audit"),
        ],
        "presence_pattern": r"Mimir metrics \(supplementary context",
    },
}

ALL_CHECKS = [
    "impact-class",
    "trial-protocol",
    "disambiguation-charter",
    "phase3-boundary",
    "genetic-drift",
    "second-failure-recovery",
    "operator-prompts",
    "mimir-note",
]


def _check_labels(spec: dict) -> "list[str]":
    """FILES labels a check's spec requires loaded, regardless of mode."""
    if spec.get("mode", "parity") == "presence":
        return [spec["file"]]
    return spec["files"]


def _run_parity_check(name: str, spec: dict, file_texts: "dict[str, str]") -> "tuple[bool, list[str]]":
    """Returns (symmetric, unified_diff_lines) for one parity-mode check.

    ``file_texts`` maps each file label declared in the check's ``files`` list to
    that file's full text. Every non-reference block is diffed against the
    reference block (each-vs-reference, not all-pairs) after applying that file's
    normalizer (default: identity)."""
    reference_label = spec["reference"]
    normalizers = spec["normalize"]
    blocks = {
        label: extract_block(file_texts[label], spec["start"], spec["end"], spec["include_end"])
        for label in spec["files"]
    }
    reference_block = blocks[reference_label]
    diff = []
    symmetric = True
    for label in spec["files"]:
        if label == reference_label:
            continue
        normalized = normalizers.get(label, lambda text: text)(blocks[label])
        if normalized == reference_block:
            continue
        symmetric = False
        diff.extend(
            difflib.unified_diff(
                normalized.splitlines(keepends=True),
                reference_block.splitlines(keepends=True),
                fromfile=f"{name} ({label}, normalized)",
                tofile=f"{name} ({reference_label})",
            )
        )
    return symmetric, diff


def _run_presence_check(spec: dict, file_texts: "dict[str, str]") -> "tuple[bool, list[str]]":
    """Returns (present, report_lines) for one presence-mode check.

    Each declared section is extracted (header to next header) and checked for a
    match against ``presence_pattern``. Structural differences between sections
    are never flagged — only absence of the pattern."""
    text = file_texts[spec["file"]]
    pattern = re.compile(spec["presence_pattern"])
    missing = [
        label
        for label, start, end in spec["sections"]
        if not pattern.search(extract_block(text, start, end, include_end=False))
    ]
    return not missing, [f"missing: {label}\n" for label in missing]


def run_check(name: str, file_texts: "dict[str, str]") -> "tuple[bool, list[str]]":
    """Returns (ok, report_lines) for one named check, dispatching on the check's
    ``mode`` (default: ``parity``, mechanized as unified-diff-vs-reference; the
    new ``presence`` mode verifies a pattern is present in each declared section)."""
    spec = CHECKS[name]
    if spec.get("mode", "parity") == "presence":
        return _run_presence_check(spec, file_texts)
    return _run_parity_check(name, spec, file_texts)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        choices=ALL_CHECKS + ["all"],
        default="all",
        help="which parity-locked block(s) to verify (default: all)",
    )
    parser.add_argument("--agents-file", default=FILES["agents"], help="path to evolve-agents/SKILL.md")
    parser.add_argument("--skills-file", default=FILES["skills"], help="path to evolve-skills/SKILL.md")
    parser.add_argument("--config-file", default=FILES["config"], help="path to evolve-config/SKILL.md")
    parser.add_argument(
        "--phase0-templates-file",
        default=FILES["phase0-templates"],
        help="path to evolve-phase0-templates.md",
    )
    args = parser.parse_args(argv)

    paths = {
        "agents": Path(args.agents_file),
        "skills": Path(args.skills_file),
        "config": Path(args.config_file),
        "phase0-templates": Path(args.phase0_templates_file),
    }

    checks = ALL_CHECKS if args.check == "all" else [args.check]
    needed_labels = sorted({label for name in checks for label in _check_labels(CHECKS[name])})

    for label in needed_labels:
        if not paths[label].is_file():
            print(f"error: file not found: {paths[label]}", file=sys.stderr)
            return 2

    file_texts = {label: paths[label].read_text() for label in needed_labels}

    any_drift = False
    for name in checks:
        try:
            ok, report = run_check(name, file_texts)
        except ValueError as exc:
            print(f"error: {name}: {exc}", file=sys.stderr)
            return 2
        presence_mode = CHECKS[name].get("mode", "parity") == "presence"
        if ok:
            print(f"{name}: OK ({'present' if presence_mode else 'symmetric'})")
        else:
            any_drift = True
            print(f"{name}: {'MISSING' if presence_mode else 'DRIFT'}")
            sys.stdout.writelines(report)

    return 1 if any_drift else 0


if __name__ == "__main__":
    sys.exit(main())
