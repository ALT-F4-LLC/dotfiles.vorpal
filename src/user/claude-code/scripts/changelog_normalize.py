#!/usr/bin/env python3
"""Changelog Format "Normalization" step for evolve-agents/evolve-skills/evolve-config.

Mechanizes the per-cycle manual LLM edit pass (run ~8x per all-agents cycle,
once per agent's changelog entry) described in each skill's "## Changelog
Format" section: fix the H1 to the canonical `# Changelog: <artifact-name>`
form, strip any suffix on the H2 date heading beyond `YYYY-MM-DD`, rename
non-standard H3 headings to the canonical set (Summary / Changes / Dimensions
Evaluated / Rename), delete extra/unrecognized sections, and truncate the
entry to at most 20 lines. Operates ONLY on the topmost `## YYYY-MM-DD` entry
-- the one most recently prepended -- and never on any entry below it.

Truncation is structure-aware: it only ever removes lines from the `### Changes`
bullet list, never from `### Summary`, `### Dimensions Evaluated`, or
`### Rename`. If the entry can't be brought under the line limit without
cutting into those other sections, truncation is skipped entirely. Any cut
emits a visible warning on stderr naming what was dropped -- never silent.

Diff-guard (hard invariant): before writing, the freshly normalized text is
re-scanned with the same entry-boundary detector used to extract the topmost
entry, and the resulting "everything below the topmost entry" region is
diffed against the original. Any difference aborts with a nonzero exit and
the diff -- normalization must never touch a prior entry or a trailing
"## Compacted history" section, even as a side effect of a boundary-detection
bug on the newly rewritten entry.

Read-only unless writing is requested (default). --dry-run prints the
normalized text without writing. Stdlib only.
"""

import argparse
import difflib
import re
import sys
from pathlib import Path

MAX_ENTRY_LINES = 20

H1_RE = re.compile(r"^# .*$", re.MULTILINE)
H2_ANY_RE = re.compile(r"^## .*$", re.MULTILINE)
H3_RE = re.compile(r"^### (.*)$", re.MULTILINE)


class DiffGuardError(ValueError):
    """Raised when normalization would change content outside the topmost entry."""


def find_entry_boundaries(text: str) -> "tuple[int, int]":
    """Return (topmost_entry_start, prior_region_start) byte offsets into `text`.

    topmost_entry_start is the offset of the first '## ' heading (the topmost,
    most-recently-prepended entry). prior_region_start is the offset of the
    second '## ' heading (a prior dated entry, or '## Compacted history'), or
    len(text) if there is no prior region.
    """
    matches = list(H2_ANY_RE.finditer(text))
    if not matches:
        raise ValueError("no '## YYYY-MM-DD' entry heading found")
    topmost_start = matches[0].start()
    prior_start = matches[1].start() if len(matches) > 1 else len(text)
    return topmost_start, prior_start


def normalize_h1(preamble: str, artifact_name: str) -> str:
    """Replace the first '# ...' heading line in `preamble` with the canonical form."""
    new_preamble, count = H1_RE.subn(f"# Changelog: {artifact_name}", preamble, count=1)
    if count == 0:
        raise ValueError("no H1 heading ('# ...') found before the first entry")
    return new_preamble


def normalize_h2(entry_text: str) -> str:
    """Strip any suffix after the YYYY-MM-DD date on the entry's H2 heading line."""
    lines = entry_text.splitlines(keepends=True)
    m = re.match(r"^## (\d{4}-\d{2}-\d{2})\b", lines[0])
    if not m:
        raise ValueError(f"topmost entry heading is not '## YYYY-MM-DD': {lines[0]!r}")
    stripped = lines[0].rstrip("\r\n")
    line_ending = lines[0][len(stripped):]
    lines[0] = f"## {m.group(1)}{line_ending}"
    return "".join(lines)


def _h3_canonical_name(heading_text: str) -> "str | None":
    """Map a raw H3 heading to the canonical set, or None if unrecognized (delete)."""
    lowered = heading_text.strip().lower()
    if "summary" in lowered:
        return "Summary"
    if "change" in lowered:
        return "Changes"
    if "dimension" in lowered:
        return "Dimensions Evaluated"
    if "rename" in lowered:
        return "Rename"
    return None


def normalize_h3_sections(entry_text: str) -> str:
    """Rename non-standard H3 headings to the canonical set; drop unrecognized sections."""
    h3_matches = list(H3_RE.finditer(entry_text))
    if not h3_matches:
        return entry_text

    out = [entry_text[: h3_matches[0].start()]]
    for i, m in enumerate(h3_matches):
        section_end = h3_matches[i + 1].start() if i + 1 < len(h3_matches) else len(entry_text)
        section = entry_text[m.start():section_end]
        canonical = _h3_canonical_name(m.group(1))
        if canonical is None:
            continue
        heading_end = section.index("\n") + 1 if "\n" in section else len(section)
        out.append(f"### {canonical}\n" + section[heading_end:])
    return "".join(out)


def truncate_entry(entry_text: str, max_lines: int) -> "tuple[str, str | None]":
    """Truncate `entry_text` to at most `max_lines` lines, cutting only within
    the '### Changes' bullet list. '### Summary', '### Dimensions Evaluated',
    and '### Rename' are never touched -- if the entry can't be brought under
    the limit without cutting into them, it is left un-truncated instead.

    Returns (new_text, warning): warning is None when no cut was made, else a
    message naming what was dropped (or why truncation was skipped).
    """
    lines = entry_text.splitlines(keepends=True)
    if len(lines) <= max_lines:
        return entry_text, None

    h3_matches = list(H3_RE.finditer(entry_text))
    changes_idx = next(
        (i for i, m in enumerate(h3_matches) if m.group(1).strip() == "Changes"), None
    )
    if changes_idx is None:
        return entry_text, (
            f"entry exceeds {max_lines} lines but has no '### Changes' section to safely "
            "truncate within -- left un-truncated to avoid dropping other sections"
        )

    changes_match = h3_matches[changes_idx]
    changes_end = (
        h3_matches[changes_idx + 1].start()
        if changes_idx + 1 < len(h3_matches)
        else len(entry_text)
    )
    changes_section = entry_text[changes_match.start():changes_end]
    heading_end = changes_section.index("\n") + 1
    body_lines = changes_section[heading_end:].splitlines(keepends=True)
    content_lines = [ln for ln in body_lines if ln.strip()]

    before = entry_text[:changes_match.start()]
    after = entry_text[changes_end:]
    # +1 for the '### Changes' heading, +1 for the blank separator line kept after it.
    fixed_lines = len(before.splitlines()) + 2 + len(after.splitlines())
    budget = max_lines - fixed_lines

    if budget < 1 or len(content_lines) <= budget:
        return entry_text, (
            f"entry exceeds {max_lines} lines even outside '### Changes' bullets -- left "
            "un-truncated to avoid dropping 'Dimensions Evaluated' or 'Rename'"
        )

    dropped = len(content_lines) - budget
    new_changes_section = "### Changes\n" + "".join(content_lines[:budget]) + "\n"
    new_text = before + new_changes_section + after
    warning = (
        f"truncated {dropped} line(s) from '### Changes' to fit the {max_lines}-line limit; "
        "'Dimensions Evaluated' and 'Rename' preserved"
    )
    return new_text, warning


def normalize_changelog(text: str, artifact_name: str) -> "tuple[str, list[str]]":
    """Normalize the topmost entry of `text`; raises DiffGuardError if a prior
    entry (or '## Compacted history') would be touched, ValueError on malformed
    input. Returns (new_text, warnings) -- warnings is non-empty when truncation
    had to cut (or skip cutting) content; see truncate_entry."""
    topmost_start, prior_start = find_entry_boundaries(text)
    preamble = text[:topmost_start]
    entry = text[topmost_start:prior_start]
    prior_region = text[prior_start:]

    new_preamble = normalize_h1(preamble, artifact_name)
    new_entry = normalize_h2(entry)
    new_entry = normalize_h3_sections(new_entry)
    new_entry, warning = truncate_entry(new_entry, MAX_ENTRY_LINES)
    warnings = [warning] if warning else []

    new_text = new_preamble + new_entry + prior_region

    _, new_prior_start = find_entry_boundaries(new_text)
    new_prior_region = new_text[new_prior_start:]
    if new_prior_region != prior_region:
        diff = "".join(
            difflib.unified_diff(
                prior_region.splitlines(keepends=True),
                new_prior_region.splitlines(keepends=True),
                fromfile="prior entries (before)",
                tofile="prior entries (after)",
            )
        )
        raise DiffGuardError(
            "normalization would modify content below the topmost entry:\n" + diff
        )

    return new_text, warnings


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("changelog_file", help="path to the changelog markdown file (topmost entry normalized in place)")
    parser.add_argument("--artifact-name", help="canonical artifact name for the H1 (default: file stem)")
    parser.add_argument("--dry-run", action="store_true", help="print the normalized file without writing")
    args = parser.parse_args(argv)

    path = Path(args.changelog_file)
    if not path.is_file():
        print(f"error: file not found: {path}", file=sys.stderr)
        return 2

    artifact_name = args.artifact_name or path.stem
    original_text = path.read_text()

    try:
        new_text, warnings = normalize_changelog(original_text, artifact_name)
    except DiffGuardError as exc:
        print(f"error: diff-guard tripped: {exc}", file=sys.stderr)
        return 3
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    for warning in warnings:
        print(f"warning: {warning}", file=sys.stderr)

    if new_text == original_text:
        print(f"{path}: already normalized (no changes)")
        return 0

    if args.dry_run:
        sys.stdout.write(new_text)
        return 0

    path.write_text(new_text)
    print(f"{path}: normalized topmost entry")
    return 0


if __name__ == "__main__":
    sys.exit(main())
