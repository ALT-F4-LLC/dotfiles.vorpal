#!/usr/bin/env python3
"""Completeness check for doctrine_check.sh's manifest.

Standalone (no pytest):
``python3 src/user/claude-code/scripts/test/test_doctrine_manifest_completeness.py``

The hole this closes: the manifest is a hand-maintained list, and
``doctrine_check.sh`` only ever checks what the manifest names. A CANONICAL tag
replicated across several carriers but absent from the manifest is never
byte-compared, and the run still reports "all arms PASS" -- a vacuous pass
indistinguishable from a real one. This is the same failure shape found in
drift_guard_check.py, where a relocated block in an unscanned doc passed
because an empty scan exits clean.

The fix is not "declare everything": several multi-carrier blocks are per-role
BY DESIGN (each carrier states the commands or paths that role actually uses),
and locking them to byte-parity would be wrong. The fix is that the difference
between DELIBERATE and FORGOTTEN must be written down. Deliberate omissions are
recorded as ``#EXCLUDE<TAB>TAG<TAB>reason`` lines in the manifest -- ordinary
comments to doctrine_check.sh, authoritative to this test.

So: every multi-carrier tag on disk must be either parity-locked or explicitly
excused, and a tag that is neither fails here.
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[4]
SRC = REPO_ROOT / "src/user/claude-code"
MANIFEST = SRC / "scripts/doctrine_check_manifest.tsv"

BEGIN_RE = re.compile(r'<!--\s*CANONICAL:([A-Z0-9_-]+):BEGIN')


def parse_manifest():
    """Return (declared_tags, excluded_tags_to_reason)."""
    declared, excluded = set(), {}
    for line in MANIFEST.read_text(encoding="utf-8").splitlines():
        if line.startswith("#EXCLUDE\t"):
            parts = line.split("\t")
            if len(parts) >= 3:
                excluded[parts[1].strip()] = parts[2].strip()
            continue
        if line.startswith("#") or not line.strip():
            continue
        declared.add(line.split("\t")[0].strip())
    return declared, excluded


def tags_on_disk():
    """tag -> list of carrier paths, from the live tree."""
    found = defaultdict(list)
    for path in sorted(SRC.rglob("*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for tag in set(BEGIN_RE.findall(text)):
            found[tag].append(path.relative_to(REPO_ROOT).as_posix())
    return found


def multi_carrier():
    """Only tags with >=2 carriers are comparable; a single carrier is a master."""
    return {t: c for t, c in tags_on_disk().items() if len(c) >= 2}


def test_every_multi_carrier_tag_is_locked_or_excused():
    declared, excluded = parse_manifest()
    unaccounted = {
        t: c for t, c in multi_carrier().items()
        if t not in declared and t not in excluded
    }
    assert not unaccounted, (
        "CANONICAL tags replicated across carriers but neither parity-locked nor "
        "excused -- doctrine_check.sh will silently never compare them:\n  "
        + "\n  ".join(f"{t} ({len(c)} carriers): {', '.join(c)}"
                      for t, c in sorted(unaccounted.items()))
        + "\n\nAdd manifest rows to lock it, or an #EXCLUDE line with a reason."
    )


def test_no_tag_is_both_locked_and_excused():
    declared, excluded = parse_manifest()
    both = declared & set(excluded)
    assert not both, f"tags both parity-locked and excused (contradiction): {sorted(both)}"


def test_no_stale_exclusions():
    """An excuse for a tag that no longer exists is rot -- it hides nothing and
    misleads the next reader about what the tree contains."""
    _, excluded = parse_manifest()
    on_disk = set(tags_on_disk())
    stale = sorted(set(excluded) - on_disk)
    assert not stale, f"#EXCLUDE entries for tags not present on disk: {stale}"


def test_exclusions_carry_a_reason():
    _, excluded = parse_manifest()
    empty = sorted(t for t, r in excluded.items() if len(r) < 15)
    assert not empty, f"#EXCLUDE entries with no substantive reason: {empty}"


def test_excluded_tags_are_genuinely_multi_carrier():
    """A single-carrier tag needs no excuse; excusing one signals a
    misunderstanding of what the manifest governs."""
    _, excluded = parse_manifest()
    multi = multi_carrier()
    needless = sorted(t for t in excluded if t not in multi)
    assert not needless, f"#EXCLUDE entries for tags that are not multi-carrier: {needless}"


def test_manifest_still_declares_the_locked_tags():
    """Guards against the reverse regression: an #EXCLUDE line quietly
    replacing real parity rows."""
    declared, _ = parse_manifest()
    assert len(declared) >= 12, f"manifest declares only {len(declared)} tags — rows may have been lost"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"ok  {t.__name__}")
        except AssertionError as e:
            failed += 1
            print(f"FAIL {t.__name__}: {e}")
    print(f"\n{len(tests) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
