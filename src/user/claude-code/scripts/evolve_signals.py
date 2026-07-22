#!/usr/bin/env python3
"""Deterministic, stdlib-only fitness-signal miner for the evolve cycles.

Source of truth is the LOCAL transcript tree (``~/.claude/projects/**/subagents/
*.{jsonl,meta.json}``) plus ``~/.claude/history.jsonl`` and per-role
``.claude/agent-memory/*/pitfalls.md``. One unauthenticated Mimir GET supplements
the local arm and is always optional. Emits one JSON object to stdout with sorted
keys AND explicitly-sorted arrays; diagnostics go to stderr.

The de-dupe discipline is the reason this script exists: transcripts replicate
~10x across resumed/subagent files, and one parent TEAM ``sessionId`` is shared by
every distinctly-named teammate spawned within it, so every model/session count is
keyed on the DISTINCT ``(sessionId, spawn name)`` pair (sessionId parsed from each
record, spawn name from the sidecar meta's ``"name"``) — this closes both the
replication and the multi-teammate-per-session undercount. ``distinct_session_ids``
specifically still counts distinct ``sessionId`` VALUES alone, unaffected by the
spawn-name half of the key. A spawn's resolved ``"model"`` is read ONCE per spawn,
never once per turn. ``"<synthetic>"`` model turns are filtered from distribution
counts.

Determinism (identical input -> byte-identical stdout) is guaranteed for the LOCAL
arm under ``--no-remote``: file iteration is path-sorted (never mtime), no
wall-clock value appears in the payload, and windowing avoids ``datetime`` (which
is intentionally outside this script's stdlib allowlist). ``--days N`` is anchored
to the newest record in the data (data-relative, reproducible), not to now().

Follows the ``session_metrics.py`` split pattern (stdlib script emits JSON, agent
reasons over it) as precedent only; it shares no code and de-dupes by distinct
``(sessionId, spawn name)`` rather than ``message_id``.
"""

import argparse
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

SYNTHETIC = "<synthetic>"
UNPARSEABLE = "<unparseable>"
OMITTED = "<omitted>"
DEFAULT_MIMIR_BASE = "https://mimir.bulbasaur.altf4.domains"
# One PromQL vector query; the exact series are a labeled supplement, never
# determinism-bearing (the remote arm is omitted under --distribution / --no-remote).
MIMIR_QUERY = "count by (model) (claude_code_active_time_total)"

# Days since the Unix epoch for JDN 0's calendar; 1970-01-01 has JDN 2440588.
_JDN_UNIX_EPOCH = 2440588
_MS_PER_DAY = 86_400_000


def _jdn(year, month, day):
    """Julian Day Number for a proleptic-Gregorian date (integer-only)."""
    a = (14 - month) // 12
    y = year + 4800 - a
    m = month + 12 * a - 3
    return day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045


def _from_jdn(jdn):
    """Inverse of :func:`_jdn` -> (year, month, day)."""
    a = jdn + 32044
    b = (4 * a + 3) // 146097
    c = a - 146097 * b // 4
    d = (4 * c + 3) // 1461
    e = c - 1461 * d // 4
    m = (5 * e + 2) // 153
    day = e - (153 * m + 2) // 5 + 1
    month = m + 3 - 12 * (m // 10)
    year = 100 * b + d - 4800 + m // 10
    return year, month, day


def _date_to_epoch_ms(date_str):
    """'YYYY-MM-DD' -> epoch milliseconds at 00:00:00Z (integer-only, no datetime)."""
    y, m, d = int(date_str[0:4]), int(date_str[5:7]), int(date_str[8:10])
    return (_jdn(y, m, d) - _JDN_UNIX_EPOCH) * _MS_PER_DAY


def _subtract_days_iso(date_str, days):
    """'YYYY-MM-DD' minus N days -> 'YYYY-MM-DDT00:00:00Z' cutoff (integer-only)."""
    y, m, d = int(date_str[0:4]), int(date_str[5:7]), int(date_str[8:10])
    yy, mm, dd = _from_jdn(_jdn(y, m, d) - days)
    return f"{yy:04d}-{mm:02d}-{dd:02d}T00:00:00Z"


def load_jsonl(path):
    """Return (records, parse_errors). A zero-byte or all-broken file yields []."""
    records = []
    parse_errors = 0
    try:
        text = path.read_text()
    except OSError:
        return records, 1
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            parse_errors += 1
    return records, parse_errors


def load_meta_with_status(jsonl_path):
    """Read the ``.meta.json`` sidecar paired with a spawn transcript, plus
    ``sidecar_readable`` distinguishing "no sidecar file" (``None``) from
    "sidecar present but unreadable/unparseable" (``False``) from "sidecar
    present and parsed" (``True``)."""
    meta_path = jsonl_path.with_name(jsonl_path.stem + ".meta.json")
    if not meta_path.is_file():
        return {}, None
    try:
        return json.loads(meta_path.read_text()), True
    except (OSError, json.JSONDecodeError):
        return {}, False


def load_meta(jsonl_path):
    """Read the ``.meta.json`` sidecar paired with a spawn transcript."""
    meta, _ = load_meta_with_status(jsonl_path)
    return meta


def role_of(meta):
    """The spawn's role. On a real sidecar meta.json, ``agentType`` is the spawn
    INSTANCE name (e.g. "impl-DKT-31") while ``customAgentType`` holds the actual
    ROLE (e.g. "senior-engineer") — the miner is per-role, so customAgentType must
    win. ``agentType`` and ``name`` are fallbacks for sidecars that omit it."""
    for key in ("customAgentType", "agentType", "name"):
        val = meta.get(key)
        if val:
            return val
    return "<unknown>"


def assistant_models(records):
    """Resolved ``"model"`` ids across a spawn's assistant turns, in record order."""
    models = []
    for rec in records:
        if rec.get("type") == "assistant":
            model = (rec.get("message") or {}).get("model")
            if model:
                models.append(model)
    return models


def error_count(records):
    """Number of ``tool_result`` blocks flagged ``is_error`` in this transcript."""
    count = 0
    for rec in records:
        if rec.get("type") != "user":
            continue
        content = (rec.get("message") or {}).get("content")
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "tool_result" and block.get("is_error"):
                    count += 1
    return count


# Anchored on the JSON key-value shape (not a loose substring) so prose mentioning
# "TeammateIdle" (e.g. injected skill-description text) never self-matches a real
# hook event. Records are re-dumped via json.dumps() before matching, whose default
# separators put a space after ':' -- \s* also tolerates a raw, space-free line.
_IDLE_RE = re.compile(r'"hookEvent"\s*:\s*"TeammateIdle"')
_SHUTDOWN_REJECT_RE = re.compile(r"shutdown[_-]?reject", re.IGNORECASE)
_RESPAWN_RE = re.compile(r"-r([2-9]|\d{2,})$|-fix-\d+$")


def parse_spawns(projects_root, cutoff_iso):
    """Parse every ``subagents/*.jsonl`` under ``projects_root`` (path-sorted).

    Files whose newest timestamp precedes ``cutoff_iso`` are windowed out.
    Returns (spawns, sessions_scanned) where each spawn is a parsed file.
    """
    spawns = []
    sessions_scanned = 0
    # Path-sorted, NEVER mtime: reproducible iteration is the whole point (§4.6).
    for path in sorted(projects_root.rglob("subagents/*.jsonl"), key=str):
        records, parse_errors = load_jsonl(path)
        timestamps = [rec["timestamp"] for rec in records if rec.get("timestamp")]
        if cutoff_iso and timestamps and max(timestamps) < cutoff_iso:
            continue  # entire spawn is older than the window
        sessions_scanned += 1
        session_ids = [rec["sessionId"] for rec in records if rec.get("sessionId")]
        meta, sidecar_readable = load_meta_with_status(path)
        spawns.append({
            "path": path,
            "session_id": session_ids[0] if session_ids else None,
            "records": records,
            "parse_errors": parse_errors,
            "models": assistant_models(records),
            "meta": meta,
            "sidecar_readable": sidecar_readable,
            "unparseable": len(records) == 0,
        })
    return spawns, sessions_scanned


def resolve_model(models):
    """One resolved model per spawn: first non-synthetic seen; else <synthetic>;
    else <unparseable> (no assistant turn at all)."""
    for model in models:
        if model != SYNTHETIC:
            return model
    if models:
        return SYNTHETIC
    return UNPARSEABLE


def build_local(projects_root, cutoff_iso, distribution_only):
    """Aggregate the LOCAL arm with distinct-``(sessionId, spawn name)`` de-dupe."""
    spawns, sessions_scanned = parse_spawns(projects_root, cutoff_iso)

    # Group replicated/resumed files by (sessionId, spawn name): sessionId alone is
    # the PARENT TEAM session shared by every distinctly-named teammate spawned
    # within it, so the spawn name (meta "name", the Agent(name=...) instance) closes
    # the key. Unparseable files have no sessionId so each keys on its own path
    # (kept distinct, never merged).
    groups = {}
    for spawn in spawns:
        if spawn["session_id"]:
            key = (spawn["session_id"], spawn["meta"].get("name", ""))
        else:
            key = (UNPARSEABLE, spawn["path"].name)
        groups.setdefault(key, []).append(spawn)

    # Distinct underlying sessionId VALUES, not distinct groups: multiple groups can
    # now share one sessionId (one per distinctly-named teammate), so counting groups
    # would overcount sessions.
    distinct_session_ids = len({spawn["session_id"] for spawn in spawns if spawn["session_id"]})

    distribution = {}
    per_spawn = []
    errors = 0
    stalls = {"TeammateIdle": {}, "r2_respawns": {}, "shutdown_rejection": {}}
    # RESERVED: no reliable transcript marker for "operator corrected model X" exists
    # yet, so this stays an empty, sorted, model-keyed container (never populated by
    # a fragile heuristic) until a marker is defined — tracked as a follow-up.
    corrections = {}

    for key in sorted(groups):
        group = sorted(groups[key], key=lambda s: str(s["path"]))
        rep = group[0]  # path-first file represents the spawn (de-dupes replication)
        meta = rep["meta"]
        role = role_of(meta)
        all_models = [m for spawn in group for m in spawn["models"]]
        resolved = resolve_model(all_models)

        sidecar_readable = rep["sidecar_readable"]
        if sidecar_readable is None:
            requested_model = OMITTED  # no .meta.json sidecar at all
        elif sidecar_readable is False:
            requested_model = UNPARSEABLE  # sidecar present but unreadable/corrupt
        else:
            requested_model = meta.get("model")  # sidecar present and parsed

        per_spawn.append({
            "session_id": rep["session_id"],
            "role": role,
            "requested_model": requested_model,
            "resolved_model": resolved,
        })
        if resolved not in (SYNTHETIC, UNPARSEABLE):
            distribution[resolved] = distribution.get(resolved, 0) + 1

        if distribution_only:
            continue

        # Signal arms count from the representative file only, so ~10x replication
        # of one session cannot inflate them (same rationale as the distribution).
        errors += error_count(rep["records"])
        blob = "\n".join(json.dumps(rec) for rec in rep["records"])
        if _IDLE_RE.search(blob):
            stalls["TeammateIdle"][role] = stalls["TeammateIdle"].get(role, 0) + 1
        if _SHUTDOWN_REJECT_RE.search(blob):
            name = meta.get("name", role)
            stalls["shutdown_rejection"][name] = stalls["shutdown_rejection"].get(name, 0) + 1
        name = meta.get("name", "")
        if _RESPAWN_RE.search(name):
            stalls["r2_respawns"][name] = stalls["r2_respawns"].get(name, 0) + 1

    per_spawn.sort(key=lambda e: (e["session_id"] or "", e["role"] or ""))

    local = {
        "sessions_scanned": sessions_scanned,
        "distinct_session_ids": distinct_session_ids,
        "distribution": distribution,
        "per_spawn": per_spawn,
    }
    if not distribution_only:
        local["stalls"] = stalls
        local["errors"] = {"is_error": errors}
        local["operator_corrections"] = corrections
        local["history_invocations"] = mine_history(projects_root, cutoff_iso)
    return local


def mine_history(projects_root, cutoff_iso):
    """Count slash-command invocations from ``history.jsonl`` (sibling of the
    projects root), windowed by the epoch-ms ``timestamp``."""
    history_path = projects_root.parent / "history.jsonl"
    counts = {}
    if not history_path.is_file():
        return counts
    cutoff_ms = _date_to_epoch_ms(cutoff_iso[:10]) if cutoff_iso else None
    for line in history_path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        display = rec.get("display", "")
        if not isinstance(display, str) or not display.startswith("/"):
            continue
        if cutoff_ms is not None:
            ts = rec.get("timestamp")
            if ts is not None and str(ts).isdigit() and int(ts) < cutoff_ms:
                continue
        command = display.split()[0]
        counts[command] = counts.get(command, 0) + 1
    return counts


def mine_pitfalls(pitfalls_root):
    """Manifest of ``.claude/agent-memory/*/pitfalls.md`` under one root, plus a
    de-duped ``recurring`` roll-up keyed by (role, symptom)."""
    root = Path(pitfalls_root).expanduser()
    files = sorted(root.glob(".claude/agent-memory/*/pitfalls.md"), key=str)
    manifest = [str(path) for path in files]
    tally = {}
    for path in files:
        role = path.parent.name
        try:
            text = path.read_text()
        except OSError:
            continue
        for line in text.splitlines():
            match = re.split(r"\s*(?:->|→)\s*", line.strip(), maxsplit=1)
            if len(match) == 2 and match[0]:
                symptom = re.sub(r"^[-*\d.\s]+", "", match[0]).strip()
                if symptom:
                    tally[(role, symptom)] = tally.get((role, symptom), 0) + 1
    recurring = [
        {"role": role, "symptom": symptom, "count": count}
        for (role, symptom), count in tally.items()
    ]
    recurring.sort(key=lambda e: (e["role"], e["symptom"]))
    return {"manifest": manifest, "recurring": recurring}


def fetch_remote(mimir_base):
    """One unauthenticated Mimir GET (or a local mock file). Never determinism-
    bearing: any failure degrades to available=false with a reason."""
    if re.match(r"^https?://", mimir_base):
        # Spaces are the only reserved chars in the fixed PromQL; encode inline so
        # the allowlist stays at urllib.request (quote lives in urllib.parse).
        query = MIMIR_QUERY.replace(" ", "%20")
        url = f"{mimir_base}/prometheus/api/v1/query?query={query}"
        try:
            with urllib.request.urlopen(url, timeout=5) as resp:  # noqa: S310 (fixed https host)
                if resp.status != 200:
                    return {"available": False, "reason": f"Mimir HTTP {resp.status}"}
                payload = json.loads(resp.read().decode())
        except Exception as exc:  # boundary: any network/parse failure -> supplement absent
            return {"available": False, "reason": f"Mimir unreachable: {exc}"}
    else:
        # Local mock path (fixture / offline) — same parse contract as the live GET.
        try:
            payload = json.loads(Path(mimir_base).expanduser().read_text())
        except (OSError, json.JSONDecodeError) as exc:
            return {"available": False, "reason": f"Mimir mock unreadable: {exc}"}
    result = (payload.get("data") or {}).get("result")
    if not result:
        return {"available": False, "reason": "Mimir returned no series"}
    return {"available": True, "reason": None, "series": len(result)}


def newest_date(projects_root):
    """Most recent 'YYYY-MM-DD' among all transcript timestamps, or None."""
    latest = None
    for path in projects_root.rglob("subagents/*.jsonl"):
        records, _ = load_jsonl(path)
        for rec in records:
            ts = rec.get("timestamp")
            if isinstance(ts, str) and len(ts) >= 10:
                date = ts[:10]
                if latest is None or date > latest:
                    latest = date
    return latest


def resolve_window(args, projects_root):
    """Return (cutoff_iso, window_meta). Unbounded when no window flag is given."""
    if args.since:
        return args.since, {"since_iso": args.since, "days": None}
    if args.days is not None:
        anchor = newest_date(projects_root)
        if anchor is None:
            return None, {"since_iso": None, "days": args.days}
        cutoff = _subtract_days_iso(anchor, args.days)
        return cutoff, {"since_iso": cutoff, "days": args.days}
    return None, {"since_iso": None, "days": None}


def build_digest(args):
    projects_root = Path(args.projects_root).expanduser()
    cutoff_iso, window = resolve_window(args, projects_root)
    distribution_only = args.distribution

    digest = {"window": window, "local": build_local(projects_root, cutoff_iso, distribution_only)}

    if not distribution_only:
        digest["pitfalls"] = mine_pitfalls(args.pitfalls_root)
        if args.no_remote:
            digest["remote"] = {"available": False, "reason": "remote disabled (--no-remote)"}
        else:
            digest["remote"] = fetch_remote(args.mimir_base or DEFAULT_MIMIR_BASE)
    return digest


def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="evolve_signals.py",
        description="Deterministic fitness-signal miner for the evolve cycles.",
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--all", action="store_true", help="emit the full digest")
    mode.add_argument("--distribution", action="store_true",
                      help="emit only the LOCAL, byte-stable per-spawn distribution arm")

    window = parser.add_mutually_exclusive_group()
    window.add_argument("--since", metavar="ISO8601", help="include records at/after this UTC timestamp")
    window.add_argument("--days", type=int, metavar="N",
                        help="N days ending at the newest record (data-relative, deterministic)")

    parser.add_argument("--projects-root", default="~/.claude/projects",
                        help="root of the transcript tree (default ~/.claude/projects)")
    parser.add_argument("--pitfalls-root", default=".",
                        help="root holding .claude/agent-memory/*/pitfalls.md (default cwd)")

    remote = parser.add_mutually_exclusive_group()
    remote.add_argument("--mimir-base", help="Mimir base URL or a local mock JSON path")
    remote.add_argument("--no-remote", action="store_true", help="skip the Mimir supplement")

    parser.add_argument("--cache", action="store_true", help="also dump the digest to $TMPDIR")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    digest = build_digest(args)
    out = json.dumps(digest, sort_keys=True)
    print(out)

    if args.cache:
        tmpdir = os.environ.get("TMPDIR")
        if tmpdir:
            cache_path = Path(tmpdir) / "evolve_signals_cache.json"
            cache_path.write_text(out)
            print(f"cache written: {cache_path}", file=sys.stderr)
        else:
            print("cache skipped: TMPDIR unset (refusing to write outside $TMPDIR)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
