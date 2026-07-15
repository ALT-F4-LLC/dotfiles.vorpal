#!/usr/bin/env python3
"""Fixture-driven checks for evolve_signals.py — the de-dupe / determinism core.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_evolve_signals.py``.
Exit 0 = all asserts pass. Scoped entirely to fixtures/signals/ so it never
touches the peer symmetry fixtures. Drives the real CLI via subprocess.
"""
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "evolve_signals.py"
SIGNALS = HERE / "fixtures" / "signals"
ROOT = SIGNALS / "projects"
PITFALLS = SIGNALS / "pitfalls-root"
MIMIR = SIGNALS / "mimir.json"
TEAM_ROOT = HERE / "fixtures" / "signals-team" / "projects"
IDLE_ROOT = HERE / "fixtures" / "signals-idle" / "projects"
META_ROOT = HERE / "fixtures" / "signals-meta" / "projects"


def run(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args],
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def digest(*extra):
    code, out, err = run("--all", "--projects-root", str(ROOT),
                         "--pitfalls-root", str(PITFALLS), "--no-remote", *extra)
    assert code == 0, f"exit {code}: {err}"
    return json.loads(out)


def test_dedupe_core():
    d = digest()
    local = d["local"]
    # Replication cannot inflate: 8 files, 6 distinct sessionIds (2 resumed + 1 zero-byte).
    assert local["sessions_scanned"] == 8, local["sessions_scanned"]
    assert local["distinct_session_ids"] == 6, local["distinct_session_ids"]
    assert local["distinct_session_ids"] < local["sessions_scanned"]
    dist = local["distribution"]
    # opus-4-8 = replicated session (once, not twice) + malformed-line session = 2.
    assert dist == {"claude-opus-4-8": 2, "claude-sonnet-4-6": 1,
                    "claude-opus-4-7": 1, "claude-haiku-4-5": 1}, dist
    # The per-turn-repeated-model spawn contributes 1, not N.
    assert dist["claude-sonnet-4-6"] == 1


def test_distinct_names_share_session():
    # Two distinctly-named teammates spawned within one parent TEAM sessionId must
    # be counted separately (the ~7.8x undercount this fix closes), while
    # distinct_session_ids must still count the underlying sessionId once, not once
    # per teammate.
    code, out, err = run("--distribution", "--projects-root", str(TEAM_ROOT), "--no-remote")
    assert code == 0, f"exit {code}: {err}"
    local = json.loads(out)["local"]
    assert local["sessions_scanned"] == 2, local["sessions_scanned"]
    assert local["distinct_session_ids"] == 1, local["distinct_session_ids"]
    assert len(local["per_spawn"]) == 2, local["per_spawn"]
    roles = sorted(e["role"] for e in local["per_spawn"])
    assert roles == ["senior-engineer", "staff-engineer"], roles
    assert local["distribution"] == {"claude-opus-4-8": 1, "claude-sonnet-4-6": 1}, local["distribution"]


def test_synthetic_and_unparseable_filtered():
    d = digest()
    by_sid = {e["session_id"]: e for e in d["local"]["per_spawn"]}
    assert by_sid["sess-syn"]["resolved_model"] == "<synthetic>"
    assert "<synthetic>" not in d["local"]["distribution"]
    unparse = [e for e in d["local"]["per_spawn"] if e["resolved_model"] == "<unparseable>"]
    assert len(unparse) == 1 and unparse[0]["role"] == "sdet"
    assert "<unparseable>" not in d["local"]["distribution"]
    # Loop continued past the zero-byte AND the malformed-line files.
    assert by_sid["sess-mal"]["resolved_model"] == "claude-opus-4-8"


def test_meta_join():
    d = digest()
    by_sid = {e["session_id"]: e for e in d["local"]["per_spawn"]}
    assert by_sid["sess-pin"]["requested_model"] == "opus"       # pinned meta.model
    assert by_sid["sess-omit"]["requested_model"] is None        # meta.model absent
    assert d["local"]["errors"]["is_error"] == 1                 # tool_result is_error
    # sess-repeat's sidecar has agentType="impl-DKT-31" (spawn INSTANCE name) and
    # customAgentType="senior-engineer" (actual ROLE) — customAgentType must win.
    # Fails under the old agentType-first precedence (would read "impl-DKT-31").
    assert by_sid["sess-repeat"]["role"] == "senior-engineer", by_sid["sess-repeat"]["role"]


def test_sidecar_missing_vs_unreadable():
    # Missing sidecar (<omitted>) must read differently from a present-but-corrupt
    # one (<unparseable>); a valid sidecar still surfaces its real requested_model.
    code, out, err = run("--all", "--projects-root", str(META_ROOT), "--no-remote")
    assert code == 0, f"exit {code}: {err}"
    by_sid = {e["session_id"]: e for e in json.loads(out)["local"]["per_spawn"]}
    assert by_sid["sess-nosidecar"]["requested_model"] == "<omitted>", by_sid["sess-nosidecar"]
    assert by_sid["sess-badsidecar"]["requested_model"] == "<unparseable>", by_sid["sess-badsidecar"]
    assert by_sid["sess-oksidecar"]["requested_model"] == "opus", by_sid["sess-oksidecar"]


def test_load_meta_with_status_direct():
    import importlib.util
    spec = importlib.util.spec_from_file_location("evolve_signals", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    missing = META_ROOT / "-Users-fixture-meta" / "metasess-0002" / "subagents" / "agent-anosidecar-1111111111111111.jsonl"
    bad = META_ROOT / "-Users-fixture-meta" / "metasess-0002" / "subagents" / "agent-abadsidecar-2222222222222222.jsonl"
    ok = META_ROOT / "-Users-fixture-meta" / "metasess-0002" / "subagents" / "agent-aoksidecar-3333333333333333.jsonl"
    assert mod.load_meta_with_status(missing) == ({}, None)
    assert mod.load_meta_with_status(bad) == ({}, False)
    assert mod.load_meta_with_status(ok) == ({"agentType": "senior-engineer", "name": "senior-engineer", "model": "opus"}, True)
    # load_meta() itself stays dict-only for callers that ignore readability.
    assert mod.load_meta(missing) == {} and mod.load_meta(bad) == {}


def test_role_of_precedence():
    import importlib.util
    spec = importlib.util.spec_from_file_location("evolve_signals", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    # customAgentType (the ROLE) wins over agentType (the spawn INSTANCE name).
    assert mod.role_of({"agentType": "impl-DKT-31", "customAgentType": "senior-engineer"}) == "senior-engineer"
    assert mod.role_of({"agentType": "impl-DKT-31"}) == "impl-DKT-31"  # no customAgentType: agentType fallback
    assert mod.role_of({"name": "reviewer"}) == "reviewer"            # last-resort fallback
    assert mod.role_of({}) == "<unknown>"


def test_sorted_arrays():
    d = digest()
    ps = d["local"]["per_spawn"]
    keys = [(e["session_id"] or "", e["role"] or "") for e in ps]
    assert keys == sorted(keys), keys
    rec = d["pitfalls"]["recurring"]
    rkeys = [(e["role"], e["symptom"]) for e in rec]
    assert rkeys == sorted(rkeys), rkeys
    assert d["pitfalls"]["manifest"] == sorted(d["pitfalls"]["manifest"])


def test_determinism_double_run():
    a = run("--all", "--projects-root", str(ROOT), "--pitfalls-root", str(PITFALLS), "--no-remote")
    b = run("--all", "--projects-root", str(ROOT), "--pitfalls-root", str(PITFALLS), "--no-remote")
    assert a[0] == 0 and b[0] == 0
    assert a[1] == b[1], "double-run stdout differs — not deterministic"
    # --distribution is the byte-stable consumer path.
    c = run("--distribution", "--projects-root", str(ROOT), "--no-remote")
    e = run("--distribution", "--projects-root", str(ROOT), "--no-remote")
    assert c[1] == e[1]
    assert "remote" not in json.loads(c[1]) and "pitfalls" not in json.loads(c[1])


def test_failure_modes_and_exit_codes():
    # Empty/absent subagents -> sessions_scanned 0, exit 0 (never non-zero for "no data").
    empty = ROOT.parent / "does-not-exist"
    code, out, _ = run("--all", "--projects-root", str(empty), "--no-remote")
    assert code == 0 and json.loads(out)["local"]["sessions_scanned"] == 0
    # Mimir mock success branch.
    code, out, _ = run("--all", "--projects-root", str(ROOT),
                       "--pitfalls-root", str(PITFALLS), "--mimir-base", str(MIMIR))
    assert code == 0 and json.loads(out)["remote"] == {"available": True, "reason": None, "series": 2}
    # Usage errors -> exit 2.
    assert run("--projects-root", str(ROOT), "--no-remote")[0] == 2            # no mode
    assert run("--all", "--since", "2026-01-01", "--days", "3", "--no-remote")[0] == 2  # both windows
    assert run("--all", "--no-remote", "--mimir-base", "x")[0] == 2            # both remote


def test_idle_regex_anchors_on_hook_event():
    # A transcript line where "TeammateIdle" appears only as a substring of
    # injected skill-description prose (no hookEvent JSON key) must NOT count as a
    # stall (the false-positive self-match this fix closes); a genuine
    # {"hookEvent": "TeammateIdle", ...} record must still count.
    code, out, err = run("--all", "--projects-root", str(IDLE_ROOT), "--no-remote")
    assert code == 0, f"exit {code}: {err}"
    idle = json.loads(out)["local"]["stalls"]["TeammateIdle"]
    assert "fp-role" not in idle, idle
    assert idle == {"tp-role": 1}, idle


def test_jdn_helpers():
    import importlib.util
    spec = importlib.util.spec_from_file_location("evolve_signals", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    assert mod._jdn(1970, 1, 1) == 2440588
    assert mod._from_jdn(mod._jdn(2026, 6, 30)) == (2026, 6, 30)
    assert mod._subtract_days_iso("2026-06-30", 7) == "2026-06-23T00:00:00Z"
    assert mod._subtract_days_iso("2026-03-01", 1) == "2026-02-28T00:00:00Z"  # non-leap boundary
    assert mod._date_to_epoch_ms("1970-01-02") == 86_400_000


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
