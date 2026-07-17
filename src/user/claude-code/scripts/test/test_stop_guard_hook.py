#!/usr/bin/env python3
"""Fixture-driven checks for stop-guard-hook.sh v2 (DKT-362) -- session
gate + teammate rate limiting.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_stop_guard_hook.py``.
Exit 0 = all asserts pass. Drives the real hook via subprocess with a
fixture-rooted HOME and a stub `docket` binary on PATH (mirrors
test_vote_delegate.py's stub-dir-on-PATH pattern); `docket plan --json`
canned responses are captured from REAL `docket init` + `docket issue
create`/`move`/`label add` runs (fixtures/stop_guard_hook/*.json), not
hand-authored, per DKT-362 acceptance-panel concern #7.

Known gap (DKT-362 advisor ruling, plan-mode review): the teammate
dimension's no-session_id branch (TEAMMATE_BLOCK=1 when TEAM_MEMBER_COUNT
> 0 but SESSION_ID_SAFE is empty) is deliberately untested here.
TEAM_MEMBER_COUNT can only be > 0 when SESSION_ID is non-empty --
member-count resolution is itself gated on session_id -- so this exact
combination is structurally unreachable via the hook's real stdin
interface in both v1 and v2. The branch exists as fail-toward-safety
against a future refactor that decouples member counting from
session_id; see the comment on that branch in stop-guard-hook.sh.
"""
import json
import os
import shutil
import stat
import subprocess
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
HOOK = HERE.parent.parent / "hooks" / "stop-guard-hook.sh"
FIXTURES = HERE / "fixtures" / "stop_guard_hook"


def _write_docket_stub(stub_dir, fixture_name=None, exit_code=0):
    stub = stub_dir / "docket"
    lines = ["#!/bin/bash", 'if [ "${1:-}" = "plan" ]; then']
    if exit_code:
        lines.append(f"    exit {exit_code}")
    else:
        if fixture_name:
            fixture_content = (FIXTURES / fixture_name).read_text().rstrip("\n")
            lines.append("    cat <<'JSONEOF'")
            lines.append(fixture_content)
            lines.append("JSONEOF")
        lines.append("    exit 0")
    lines.append("fi")
    lines.append("exit 0")
    stub.write_text("\n".join(lines) + "\n")
    stub.chmod(stub.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)


def _write_team_config(home, session_id, member_names, lead_name="team-lead"):
    prefix = session_id[:8]
    team_dir = home / ".claude" / "teams" / f"session-{prefix}"
    team_dir.mkdir(parents=True, exist_ok=True)
    members = [{"name": lead_name, "agentType": "team-lead"}]
    members += [{"name": n, "agentType": "generic"} for n in member_names]
    config = {
        "createdAt": "2026-07-16T00:00:00Z",
        "leadAgentId": "a-lead",
        "leadSessionId": session_id,
        "members": members,
        "name": "test-team",
    }
    config_path = team_dir / "config.json"
    config_path.write_text(json.dumps(config))
    return config_path


def _git_repo(path):
    path.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "init", "-q", str(path)], check=True, capture_output=True)
    return path


def _tmp_home():
    return Path(tempfile.mkdtemp(prefix="stop_guard_hook_test_"))


def run_hook(payload, home, cwd=None, docket_stub_dir=None, env_extra=None, no_stdin=False):
    env = dict(os.environ)
    env["HOME"] = str(home)
    if docket_stub_dir:
        env["PATH"] = f"{docket_stub_dir}:{env['PATH']}"
    if env_extra:
        env.update(env_extra)
    stdin_input = "" if no_stdin else json.dumps(payload)
    return subprocess.run(
        ["bash", str(HOOK)],
        input=stdin_input,
        capture_output=True,
        text=True,
        cwd=str(cwd or home),
        env=env,
    )


def _stdout_json(proc):
    assert proc.returncode == 0, f"exit {proc.returncode}: {proc.stderr}"
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        raise AssertionError(f"non-JSON stdout: {proc.stdout!r} stderr: {proc.stderr!r}")


# Row 1 (AC-1): leaf session (no team config) + outstanding docket fixture
# => allow, regardless of repo-wide outstanding issues.
def test_leaf_session_allows_despite_outstanding_docket():
    home = _tmp_home()
    stub_dir = Path(tempfile.mkdtemp(prefix="docket_stub_"))
    try:
        _write_docket_stub(stub_dir, fixture_name="docket_plan_outstanding.json")
        repo = _git_repo(home / "repo")
        payload = {"session_id": "leafsession12345", "cwd": str(repo), "stop_hook_active": False}
        out = _stdout_json(run_hook(payload, home, cwd=repo, docket_stub_dir=stub_dir))
        assert out == {}, out
    finally:
        shutil.rmtree(home, ignore_errors=True)
        shutil.rmtree(stub_dir, ignore_errors=True)


# Row 2: team session, 1 live member, no prior state => block; reason
# contains the member name AND the verbatim reuse-wait guidance tail.
def test_team_session_one_member_no_prior_state_blocks_with_tail():
    home = _tmp_home()
    try:
        session_id = "teamsess1abcdef"
        _write_team_config(home, session_id, ["alice"])
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        out = _stdout_json(run_hook(payload, home))
        assert out.get("decision") == "block", out
        assert "alice" in out.get("reason", ""), out
        assert "reuse the existing armed wait (Monitor or singleton_wait.sh)" in out["reason"], out
        assert "do NOT spawn a new background wait for this nudge" in out["reason"], out
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 3 (AC-2): same roster, immediate second run => suppressed.
def test_team_session_same_roster_immediate_rerun_suppressed():
    home = _tmp_home()
    try:
        session_id = "teamsess2abcdef"
        _write_team_config(home, session_id, ["alice"])
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        first = _stdout_json(run_hook(payload, home))
        assert first.get("decision") == "block", first
        second = _stdout_json(run_hook(payload, home))
        assert second == {}, second
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 4: same roster, short reblock interval, sleep past it => nudge refires.
def test_team_session_interval_elapsed_reblocks():
    home = _tmp_home()
    try:
        session_id = "teamsess3abcdef"
        _write_team_config(home, session_id, ["alice"])
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        env_extra = {"STOP_GUARD_TEAMMATE_REBLOCK_SECONDS": "1"}
        first = _stdout_json(run_hook(payload, home, env_extra=env_extra))
        assert first.get("decision") == "block", first
        time.sleep(2)
        second = _stdout_json(run_hook(payload, home, env_extra=env_extra))
        assert second.get("decision") == "block", second
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 5: roster changed => immediate block despite a fresh epoch.
def test_team_session_roster_change_blocks_immediately():
    home = _tmp_home()
    try:
        session_id = "teamsess4abcdef"
        _write_team_config(home, session_id, ["alice"])
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        first = _stdout_json(run_hook(payload, home))
        assert first.get("decision") == "block", first
        _write_team_config(home, session_id, ["alice", "bob"])
        second = _stdout_json(run_hook(payload, home))
        assert second.get("decision") == "block", second
        assert "bob" in second.get("reason", ""), second
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 6: team session, 0 members, outstanding fixture, fresh signature =>
# block once then suppressed on an identical re-run (Docket rate limit
# still works behind the new session gate). THIS IS THE STUB-SHAPE
# POSITIVE CONTROL (DKT-362 panel concern #7): if
# fixtures/stop_guard_hook/docket_plan_outstanding.json's shape ever
# drifted from what real `docket plan --json` emits, this is the row that
# would fail loudly (DOCKET_OUTSTANDING_COUNT would silently read 0 via
# jq's `?` operators instead of raising) -- do NOT delete this row as
# "apparently redundant" with row 1; row 1 never lets the Docket
# dimension run at all (no team config), so it can't catch a stub-shape
# regression.
def test_team_session_zero_members_docket_blocks_once_then_suppressed():
    home = _tmp_home()
    stub_dir = Path(tempfile.mkdtemp(prefix="docket_stub_"))
    try:
        _write_docket_stub(stub_dir, fixture_name="docket_plan_outstanding.json")
        session_id = "teamsess5abcdef"
        _write_team_config(home, session_id, [])
        repo = _git_repo(home / "repo")
        payload = {"session_id": session_id, "cwd": str(repo), "stop_hook_active": False}
        first = _stdout_json(run_hook(payload, home, cwd=repo, docket_stub_dir=stub_dir))
        assert first.get("decision") == "block", first
        reason = first.get("reason", "")
        assert "DKT-1" in reason and "DKT-2" in reason, first
        assert "DKT-4" not in reason, first
        second = _stdout_json(run_hook(payload, home, cwd=repo, docket_stub_dir=stub_dir))
        assert second == {}, second
    finally:
        shutil.rmtree(home, ignore_errors=True)
        shutil.rmtree(stub_dir, ignore_errors=True)


# Row 7: stop_hook_active short-circuits to allow unconditionally.
def test_stop_hook_active_always_allows():
    home = _tmp_home()
    try:
        session_id = "teamsess6abcdef"
        _write_team_config(home, session_id, ["alice"])
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": True}
        out = _stdout_json(run_hook(payload, home))
        assert out == {}, out
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 8: invalid env value falls back to the 600s default (suppressed on
# an immediate re-run, same as no override).
def test_invalid_reblock_env_falls_back_to_default():
    home = _tmp_home()
    try:
        session_id = "teamsess7abcdef"
        _write_team_config(home, session_id, ["alice"])
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        env_extra = {"STOP_GUARD_TEAMMATE_REBLOCK_SECONDS": "banana"}
        first = _stdout_json(run_hook(payload, home, env_extra=env_extra))
        assert first.get("decision") == "block", first
        second = _stdout_json(run_hook(payload, home, env_extra=env_extra))
        assert second == {}, second
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 9a (fail-open spot check): no stdin => allow.
def test_fail_open_no_stdin():
    home = _tmp_home()
    try:
        out = _stdout_json(run_hook({}, home, no_stdin=True))
        assert out == {}, out
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 9b (fail-open spot check): unreadable team config => never block.
def test_fail_open_unreadable_team_config():
    home = _tmp_home()
    try:
        session_id = "teamsess8abcdef"
        config_path = _write_team_config(home, session_id, ["alice"])
        os.chmod(config_path, 0)
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        out = _stdout_json(run_hook(payload, home))
        assert out == {}, out
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 9c (fail-open spot check): stub docket exits non-zero => never
# block on the broken dimension.
def test_fail_open_docket_nonzero_exit():
    home = _tmp_home()
    stub_dir = Path(tempfile.mkdtemp(prefix="docket_stub_"))
    try:
        _write_docket_stub(stub_dir, exit_code=1)
        session_id = "teamsess9abcdef"
        _write_team_config(home, session_id, [])
        repo = _git_repo(home / "repo")
        payload = {"session_id": session_id, "cwd": str(repo), "stop_hook_active": False}
        out = _stdout_json(run_hook(payload, home, cwd=repo, docket_stub_dir=stub_dir))
        assert out == {}, out
    finally:
        shutil.rmtree(home, ignore_errors=True)
        shutil.rmtree(stub_dir, ignore_errors=True)


# Row 10 [panel concern #5]: empty session_id => TEAM_CONFIG="" => Docket
# dimension skipped entirely, distinct from row 1 (which has a real
# session_id but no matching team-config file). Uses the outstanding
# fixture (real outstanding issues) with the debug toggle armed so the
# debug log's docket= field discriminates "skipped" (docket=0 despite
# real outstanding issues in the fixture) from "ran and found none".
def test_empty_session_id_skips_docket_dimension():
    home = _tmp_home()
    stub_dir = Path(tempfile.mkdtemp(prefix="docket_stub_"))
    try:
        _write_docket_stub(stub_dir, fixture_name="docket_plan_outstanding.json")
        (home / ".claude").mkdir(parents=True, exist_ok=True)
        (home / ".claude" / "stop-guard-hook.debug").write_text("")
        repo = _git_repo(home / "repo")
        payload = {"session_id": "", "cwd": str(repo), "stop_hook_active": False}
        out = _stdout_json(run_hook(payload, home, cwd=repo, docket_stub_dir=stub_dir))
        assert out == {}, out
        log_path = home / ".claude" / "stop-guard-hook.log"
        assert log_path.exists(), "expected debug log to be written"
        log_text = log_path.read_text()
        assert "docket=0" in log_text, log_text
    finally:
        shutil.rmtree(home, ignore_errors=True)
        shutil.rmtree(stub_dir, ignore_errors=True)


# Row 11 [panel concern #3]: a .teammate-sig with a valid roster-signature
# line but a corrupt/non-numeric epoch line must be treated as changed
# (block, rewrite) and never fed into arithmetic -- a bad `[ -ge ]` on a
# non-numeric operand would abort the script, which the exit-code
# assertion inside _stdout_json would also catch.
def test_teammate_state_corrupt_epoch_treated_as_changed():
    home = _tmp_home()
    try:
        session_id = "teamsessAabcdef"
        _write_team_config(home, session_id, ["alice"])
        state_dir = home / ".claude" / "stop-guard-hook-state"
        state_dir.mkdir(parents=True, exist_ok=True)
        (state_dir / f"{session_id}.teammate-sig").write_text("alice\nnot-a-number\n")
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        out = _stdout_json(run_hook(payload, home))
        assert out.get("decision") == "block", out
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Row 12 [panel concern #4]: team-session gate outcome is logged
# unconditionally (without arming ~/.claude/stop-guard-hook.debug), scoped
# to sessions that actually have a team config.
def test_team_session_gate_logged_unconditionally_without_debug_toggle():
    home = _tmp_home()
    try:
        session_id = "teamsessBabcdef"
        _write_team_config(home, session_id, ["alice"])
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        run_hook(payload, home)
        gate_log = home / ".claude" / "stop-guard-hook-state" / f"{session_id}.gate-log"
        assert gate_log.exists(), "expected unconditional gate log without debug toggle"
        assert "team_session=1" in gate_log.read_text()
        debug_log = home / ".claude" / "stop-guard-hook.log"
        assert not debug_log.exists(), "debug-gated log must not fire without the toggle"
    finally:
        shutil.rmtree(home, ignore_errors=True)


# Panel concern #4, scope check: a leaf session (no team config) produces
# no unconditional gate-log artifact -- the carve-out is scoped to actual
# team sessions, not blanket-unconditional.
def test_leaf_session_no_gate_log():
    home = _tmp_home()
    stub_dir = Path(tempfile.mkdtemp(prefix="docket_stub_"))
    try:
        _write_docket_stub(stub_dir, fixture_name="docket_plan_outstanding.json")
        repo = _git_repo(home / "repo")
        payload = {"session_id": "leafsessB2345678", "cwd": str(repo), "stop_hook_active": False}
        run_hook(payload, home, cwd=repo, docket_stub_dir=stub_dir)
        state_dir = home / ".claude" / "stop-guard-hook-state"
        gate_logs = list(state_dir.glob("*.gate-log")) if state_dir.exists() else []
        assert gate_logs == [], gate_logs
    finally:
        shutil.rmtree(home, ignore_errors=True)
        shutil.rmtree(stub_dir, ignore_errors=True)


# State-dir hygiene: files older than 7 days are pruned on write.
def test_stale_state_files_pruned_on_write():
    home = _tmp_home()
    try:
        session_id = "teamsessCabcdef"
        _write_team_config(home, session_id, ["alice"])
        state_dir = home / ".claude" / "stop-guard-hook-state"
        state_dir.mkdir(parents=True, exist_ok=True)
        stale = state_dir / "stale-leftover.docket-sig"
        stale.write_text("DKT-999")
        old_time = time.time() - (8 * 86400)
        os.utime(stale, (old_time, old_time))
        payload = {"session_id": session_id, "cwd": str(home), "stop_hook_active": False}
        out = _stdout_json(run_hook(payload, home))
        assert out.get("decision") == "block", out
        assert not stale.exists(), "expected >7-day-old state file to be pruned on write"
    finally:
        shutil.rmtree(home, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
