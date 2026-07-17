#!/usr/bin/env python3
"""Regression tests for the comment-ID-set Monitor signature recipe
(monitor-orchestration.md sec:4.4) -- proves the signature is stable
across polls with no real content change and sensitive to a real new
comment, including a synthetic test proving the fix discriminates
against the original relative-timestamp-drift bug (2026-07-16 DKT-345
false-positive polling incident), not just a self-consistency check.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_monitor_signal.py``.
Exit 0 = all asserts pass. Runtime dominated by a mandatory >=61s sleep
in the real-db test (crosses a minute boundary, per TDD
stop-guard-hook-session-scoping-and-monitor.md sec:9.2/sec:11 Phase 5
-- do not shorten or remove).
"""
import hashlib
import shlex
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

# Recipe under test (verbatim, both the ID-signature and the
# new-comment-extraction pipeline including its trailing Discovered:
# filter): src/user/claude-code/skills/team-doctrine/references/monitor-orchestration.md sec:4.4
SIGNATURE_JQ = '[.data[].id] | sort | join(",")'


def run(cmd, cwd=None, input_str=None):
    proc = subprocess.run(cmd, cwd=cwd, input=input_str, capture_output=True, text=True,
                           shell=isinstance(cmd, str))
    if proc.returncode != 0:
        raise AssertionError(f"cmd failed ({proc.returncode}): {cmd}\nstdout={proc.stdout}\nstderr={proc.stderr}")
    return proc.stdout


def _extraction_suffix(prev_sig):
    # jq + awk + grep arms of the monitor-orchestration.md sec:4.4 recipe,
    # verbatim including the trailing Discovered: filter -- never test a
    # re-implementation that drops a stage, or doctrine/test drift goes
    # ungreppable.
    prev_arg = f"prev=,{prev_sig},"
    return (
        "jq -r '.data[] | \"\\(.id)\\t\\(.body)\"' "
        f"| awk -F'\\t' -v {shlex.quote(prev_arg)} 'index(prev, \",\" $1 \",\")==0 {{print $2}}' "
        '| grep --line-buffered "Discovered:" || true'
    )


def capture_signature(cwd, issue_id):
    return run(f"docket issue comment list {shlex.quote(issue_id)} --json | jq -r '{SIGNATURE_JQ}'", cwd=cwd).strip()


def signature_from_json(json_str):
    return run(["jq", "-r", SIGNATURE_JQ], input_str=json_str).strip()


def extract_new_comments_live(cwd, issue_id, prev_sig):
    cmd = f"docket issue comment list {shlex.quote(issue_id)} --json | " + _extraction_suffix(prev_sig)
    return run(cmd, cwd=cwd)


def extract_new_comments_from_json(json_str, prev_sig):
    return run(_extraction_suffix(prev_sig), input_str=json_str)


def docket_init(cwd):
    run(["docket", "init"], cwd=cwd)


def create_issue(cwd):
    import json
    out = run(["docket", "issue", "create", "-t", "probe issue", "-d", "probe", "-p", "low", "-T", "chore", "--json"], cwd=cwd)
    return json.loads(out)["data"]["id"]


def add_comment(cwd, issue_id, body):
    run(["docket", "issue", "comment", "add", issue_id, "-m", body, "--json"], cwd=cwd)


def test_real_db_zero_notification_invariant_and_delta_detection():
    tmp = Path(tempfile.mkdtemp(prefix="monitor_signal_test_"))
    try:
        docket_init(tmp)
        issue_id = create_issue(tmp)
        add_comment(tmp, issue_id, "first comment")

        sig1 = capture_signature(tmp, issue_id)
        assert sig1, f"expected non-empty signature after first comment, got {sig1!r}"

        # Mandatory >=61s sleep -- crosses a minute boundary so any
        # relative-rendering drift in TEXT output would have occurred
        # (TDD stop-guard-hook-session-scoping-and-monitor.md sec:9.2/sec:11
        # Phase 5; recipe source: monitor-orchestration.md sec:4.4).
        # Do NOT shorten or remove.
        time.sleep(61)

        sig2 = capture_signature(tmp, issue_id)
        assert sig2 == sig1, f"zero-notification invariant violated: {sig1!r} != {sig2!r}"

        add_comment(tmp, issue_id, "Discovered: second comment")
        sig3 = capture_signature(tmp, issue_id)
        assert sig3 != sig2, f"signature did not change after new comment: {sig3!r}"

        extracted = extract_new_comments_live(tmp, issue_id, sig2).strip()
        assert extracted == "Discovered: second comment", f"expected exactly the new comment body, got {extracted!r}"

        # Suppression half: a new comment that does NOT start with
        # "Discovered:" must be extracted (id-wise) but filtered out by
        # the trailing grep, so the full recipe emits nothing for it.
        add_comment(tmp, issue_id, "just a note")
        sig4 = capture_signature(tmp, issue_id)
        assert sig4 != sig3, f"signature did not change after third comment: {sig4!r}"
        suppressed = extract_new_comments_live(tmp, issue_id, sig3).strip()
        assert suppressed == "", f"non-Discovered: comment must be suppressed by the filter, got {suppressed!r}"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def test_synthetic_old_text_hash_drifts_new_id_signature_invariant():
    """Panel concern #2 (DKT-V37): proves the fix discriminates against
    the ORIGINAL bug, not merely a self-consistency check.

    TEXT-hash half (positive control): two hand-constructed comment-list
    TEXT renderings differing ONLY in relative-timestamp text -- the
    exact mechanism of the 2026-07-16 DKT-345 false-positive polling
    incident -- must hash differently under the OLD (rendered-text-hash)
    approach.

    JSON-signature half: json_a and json_b represent the SAME comment
    set with signature-IRRELEVANT differences (shuffled array order,
    which exercises the recipe's own `sort`; and a differing body on one
    comment, documenting the accepted R-4 caveat that ID-based
    signatures miss body edits) -- their signatures must be EQUAL.
    json_c adds one new id -- its signature must DIFFER, and the full
    extraction recipe (monitor-orchestration.md sec:4.4, including the
    trailing Discovered: grep) run against json_c with prev=signature(json_a)
    must isolate exactly the one new Discovered: comment.
    """
    text_a = "Erik Reinert  6 hours ago\nfirst comment\n"
    text_b = "Erik Reinert  7 hours ago\nfirst comment\n"
    old_hash_a = hashlib.sha256(text_a.encode()).hexdigest()
    old_hash_b = hashlib.sha256(text_b.encode()).hexdigest()
    assert old_hash_a != old_hash_b, "synthetic renderings must differ only in relative-timestamp text (drift must be real)"

    json_a = ('{"data": [{"id": 1, "issue_id": "DKT-1", "body": "Discovered: first comment", '
              '"author": "Erik Reinert", "created_at": "2026-07-16T12:00:00Z"}, '
              '{"id": 2, "issue_id": "DKT-1", "body": "Discovered: second comment", '
              '"author": "Erik Reinert", "created_at": "2026-07-16T12:05:00Z"}]}')
    # Same two ids as json_a, shuffled array order + an edited body on id 1
    # -- both are signature-irrelevant under an ID-set signature.
    json_b = ('{"data": [{"id": 2, "issue_id": "DKT-1", "body": "Discovered: second comment", '
              '"author": "Erik Reinert", "created_at": "2026-07-16T12:05:00Z"}, '
              '{"id": 1, "issue_id": "DKT-1", "body": "Discovered: first comment EDITED", '
              '"author": "Erik Reinert", "created_at": "2026-07-16T12:00:00Z"}]}')
    # json_a plus one new comment -- a genuine id-set change.
    json_c = ('{"data": [{"id": 1, "issue_id": "DKT-1", "body": "Discovered: first comment", '
              '"author": "Erik Reinert", "created_at": "2026-07-16T12:00:00Z"}, '
              '{"id": 2, "issue_id": "DKT-1", "body": "Discovered: second comment", '
              '"author": "Erik Reinert", "created_at": "2026-07-16T12:05:00Z"}, '
              '{"id": 3, "issue_id": "DKT-1", "body": "Discovered: third comment", '
              '"author": "Erik Reinert", "created_at": "2026-07-16T12:10:00Z"}]}')

    sig_a = signature_from_json(json_a)
    sig_b = signature_from_json(json_b)
    sig_c = signature_from_json(json_c)
    assert sig_a == sig_b, f"ID-signature must be invariant to array order and body edits: {sig_a!r} != {sig_b!r}"
    assert sig_a != sig_c, f"ID-signature must change when the id set changes: {sig_a!r} == {sig_c!r}"

    extracted = extract_new_comments_from_json(json_c, sig_a).strip()
    assert extracted == "Discovered: third comment", f"expected exactly the new comment body, got {extracted!r}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
