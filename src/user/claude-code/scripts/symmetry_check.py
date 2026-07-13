#!/usr/bin/env python3
"""Byte-symmetry linter for the evolve-agents/evolve-skills parity-locked blocks.

Mechanizes evolve-agents/SKILL.md Phase 2 coherence check 5: the five blocks that
must be byte-identical between evolve-agents/SKILL.md and evolve-skills/SKILL.md modulo
an established set of agent<->skill noun substitutions. Normalizes the evolve-agents
block into skill vocabulary, then diffs it against the evolve-skills block verbatim.

Read-only. Never edits, never commits. Stdlib only.
"""

import argparse
import difflib
import re
import sys
from pathlib import Path

DEFAULT_AGENTS_FILE = ".claude/skills/evolve-agents/SKILL.md"
DEFAULT_SKILLS_FILE = ".claude/skills/evolve-skills/SKILL.md"

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


# NOTE: "mimir"'s range is fully contained within "model-routing-auditor"'s range,
# so a drift inside the Mimir lines is reported twice under `--check all` — intentional
# and harmless (mimir exists as a narrower, independently-runnable check).
CHECKS = {
    "pitfalls-harvest": {
        "start": r"^<!-- CANONICAL:HARVEST:BEGIN -->$",
        "end": r"^<!-- CANONICAL:HARVEST:END -->$",
        "include_end": True,
    },
    "innovation-scanner": {
        "start": r"^### Phase 0: Innovation Scan$",
        "end": r"^### Phase 0: Model Routing Audit$",
        "include_end": False,
    },
    "model-routing-auditor": {
        "start": r"^### Phase 0: Model Routing Audit$",
        "end": r"^### Phase",
        "include_end": False,
    },
    "mimir": {
        "start": r"^\d+\. \*\*Mimir metrics \(primary factual arm",
        "end": r"^## Improvement-Only Mandate$",
        "include_end": False,
    },
    "impact-class": {
        "start": r"^<!-- CANONICAL:IMPACT-CLASS:BEGIN -->$",
        "end": r"^<!-- CANONICAL:IMPACT-CLASS:END -->$",
        "include_end": True,
    },
}

ALL_CHECKS = ["pitfalls-harvest", "innovation-scanner", "model-routing-auditor", "mimir", "impact-class"]


def run_check(name: str, agents_text: str, skills_text: str) -> "tuple[bool, list[str]]":
    """Returns (symmetric, unified_diff_lines) for one named check."""
    spec = CHECKS[name]
    agents_block = extract_block(agents_text, spec["start"], spec["end"], spec["include_end"])
    skills_block = extract_block(skills_text, spec["start"], spec["end"], spec["include_end"])
    normalized_agents = normalize(agents_block)
    if normalized_agents == skills_block:
        return True, []
    diff = list(
        difflib.unified_diff(
            normalized_agents.splitlines(keepends=True),
            skills_block.splitlines(keepends=True),
            fromfile=f"{name} (evolve-agents, normalized)",
            tofile=f"{name} (evolve-skills)",
        )
    )
    return False, diff


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        choices=ALL_CHECKS + ["all"],
        default="all",
        help="which parity-locked block to verify (default: all)",
    )
    parser.add_argument("--agents-file", default=DEFAULT_AGENTS_FILE, help="path to evolve-agents/SKILL.md")
    parser.add_argument("--skills-file", default=DEFAULT_SKILLS_FILE, help="path to evolve-skills/SKILL.md")
    args = parser.parse_args(argv)

    agents_path = Path(args.agents_file)
    skills_path = Path(args.skills_file)
    for path in (agents_path, skills_path):
        if not path.is_file():
            print(f"error: file not found: {path}", file=sys.stderr)
            return 2

    agents_text = agents_path.read_text()
    skills_text = skills_path.read_text()

    checks = ALL_CHECKS if args.check == "all" else [args.check]

    any_drift = False
    for name in checks:
        try:
            symmetric, diff = run_check(name, agents_text, skills_text)
        except ValueError as exc:
            print(f"error: {name}: {exc}", file=sys.stderr)
            return 2
        if symmetric:
            print(f"{name}: OK (symmetric)")
        else:
            any_drift = True
            print(f"{name}: DRIFT")
            sys.stdout.writelines(diff)

    return 1 if any_drift else 0


if __name__ == "__main__":
    sys.exit(main())
