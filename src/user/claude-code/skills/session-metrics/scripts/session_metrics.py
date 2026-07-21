#!/usr/bin/env python3
"""Aggregate current-session Claude Code metrics from the local transcript.

Stdlib only — no third-party deps. Source of truth is the session JSONL
transcript under ~/.claude/projects/<cwd-slug>/; aggregate metrics (e.g. OTEL)
are never consulted — they cannot attribute tokens/cost to THIS specific
session or reconstruct per-session tool/file/timeline detail. Emits a JSON
summary to stdout followed by the absolute path to a self-contained HTML
report.
"""

import datetime
import html
import json
import os
import re
import sys
import tempfile
from pathlib import Path

def load_price_table():
    """Load the per-model price table from model_prices.json (colocated with this
    script), resolving any time-boxed intro/standard pricing against today's date."""
    data = json.loads((Path(__file__).parent / "model_prices.json").read_text())
    today = datetime.datetime.now(datetime.timezone.utc).date()
    prices = {}
    for model, entry in data["prices"].items():
        if "intro" in entry:
            cutoff = datetime.date.fromisoformat(entry["intro_cutoff"])
            prices[model] = entry["intro"] if today <= cutoff else entry["standard"]
        else:
            prices[model] = entry
    return prices, {"updated": data["updated"], "source": data.get("source")}


PRICES, PRICE_TABLE_META = load_price_table()

COORDINATION_TOOLS = {"Agent", "SendMessage", "Task"}
FILE_TOOLS = {"Edit", "Write", "Read"}


def price_for(model_id):
    """Look up the price row for a model id, stripping date suffixes as a fallback."""
    if model_id in PRICES:
        return PRICES[model_id]
    stripped = re.sub(r"-\d{8}$", "", model_id)
    return PRICES.get(stripped)


def cwd_slug(cwd):
    """Mirror Claude Code's project-dir naming: '/' and '.' become '-'."""
    return cwd.replace("/", "-").replace(".", "-")


def resolve_session_jsonl(project_dir):
    """Return (path, resolution_method) for the active session transcript."""
    session_id = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if session_id:
        candidate = project_dir / f"{session_id}.jsonl"
        if candidate.is_file():
            return candidate, "env:CLAUDE_CODE_SESSION_ID"
    candidates = sorted(project_dir.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not candidates:
        return None, None
    return candidates[0], "fallback:most-recently-modified"


def load_jsonl(path):
    records = []
    parse_errors = 0
    with path.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                parse_errors += 1
    return records, parse_errors


def new_usage_bucket():
    return {"input": 0, "output": 0, "cache_w5": 0, "cache_w1h": 0, "cache_r": 0}


def aggregate_transcript(records):
    """Walk one transcript's records, returning per-model usage and tool/file/thinking stats."""
    usage_by_model = {}
    tool_counts = {}
    tool_errors = {}
    tool_use_names = {}  # tool_use_id -> tool name, for matching tool_result errors
    files_touched = set()
    thinking_count = 0
    thinking_chars = 0
    turn_duration_ms_total = 0
    turn_duration_count = 0
    timestamps = []
    git_branch = None
    version = None
    seen_message_ids = set()  # one JSONL record per content block; usage repeats per block

    for rec in records:
        rtype = rec.get("type")
        if rec.get("gitBranch"):
            git_branch = rec["gitBranch"]
        if rec.get("version"):
            version = rec["version"]
        ts = rec.get("timestamp")
        if ts:
            timestamps.append(ts)

        if rtype == "system" and rec.get("subtype") == "turn_duration":
            turn_duration_ms_total += rec.get("durationMs", 0)
            turn_duration_count += 1
            continue

        if rtype == "assistant":
            message = rec.get("message", {})
            model = message.get("model", "unknown")

            # message.usage is stamped identically on every per-content-block record
            # of the same message; accumulate it once per message.id or it inflates
            # totals by however many blocks the message had.
            message_key = message.get("id") or rec.get("requestId") or rec.get("uuid")
            if message_key not in seen_message_ids:
                seen_message_ids.add(message_key)
                usage = message.get("usage", {})
                bucket = usage_by_model.setdefault(model, new_usage_bucket())
                bucket["input"] += usage.get("input_tokens", 0)
                bucket["output"] += usage.get("output_tokens", 0)
                cache_creation = usage.get("cache_creation") or {}
                if cache_creation:
                    bucket["cache_w5"] += cache_creation.get("ephemeral_5m_input_tokens", 0)
                    bucket["cache_w1h"] += cache_creation.get("ephemeral_1h_input_tokens", 0)
                else:
                    # Older records have no 5m/1h split; default-TTL writes are 5m.
                    bucket["cache_w5"] += usage.get("cache_creation_input_tokens", 0)
                bucket["cache_r"] += usage.get("cache_read_input_tokens", 0)

            for block in message.get("content", []) or []:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_use":
                    name = block.get("name", "unknown")
                    tool_counts[name] = tool_counts.get(name, 0) + 1
                    tool_use_names[block.get("id")] = name
                    if name in FILE_TOOLS:
                        fp = (block.get("input") or {}).get("file_path")
                        if fp:
                            files_touched.add(fp)
                elif block.get("type") == "thinking":
                    thinking_count += 1
                    thinking_chars += len(block.get("thinking", ""))
            continue

        if rtype == "user":
            message = rec.get("message", {})
            content = message.get("content")
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "tool_result":
                        if block.get("is_error"):
                            name = tool_use_names.get(block.get("tool_use_id"), "unknown")
                            tool_errors[name] = tool_errors.get(name, 0) + 1

    return {
        "usage_by_model": usage_by_model,
        "tool_counts": tool_counts,
        "tool_errors": tool_errors,
        "files_touched": files_touched,
        "thinking_count": thinking_count,
        "thinking_chars": thinking_chars,
        "turn_duration_ms_total": turn_duration_ms_total,
        "turn_duration_count": turn_duration_count,
        "timestamps": timestamps,
        "git_branch": git_branch,
        "version": version,
    }


def cost_for_usage(bucket, model):
    price = price_for(model)
    if not price:
        return None
    return (
        bucket["input"] * price["in"]
        + bucket["output"] * price["out"]
        + bucket["cache_w5"] * price["cache_w5"]
        + bucket["cache_w1h"] * price["cache_w1h"]
        + bucket["cache_r"] * price["cache_r"]
    ) / 1_000_000


def total_tokens(bucket):
    return sum(bucket.values())


def merge_usage(into, usage_by_model):
    for model, bucket in usage_by_model.items():
        dest = into.setdefault(model, new_usage_bucket())
        for k, v in bucket.items():
            dest[k] += v


def merge_counts(into, counts):
    for k, v in counts.items():
        into[k] = into.get(k, 0) + v


def sum_usage_across_models(usage_by_model):
    """Flatten a model -> bucket map into a single bucket (for one agent's totals)."""
    total = new_usage_bucket()
    for bucket in usage_by_model.values():
        for k, v in bucket.items():
            total[k] += v
    return total


def gather_subagents(subagents_dir):
    """Resolve each subagent transcript + its meta.json into a roster entry."""
    roster = []
    if not subagents_dir.is_dir():
        return roster
    for jsonl_path in sorted(subagents_dir.glob("*.jsonl")):
        records, _ = load_jsonl(jsonl_path)
        agg = aggregate_transcript(records)
        meta_path = jsonl_path.with_suffix("").with_suffix(".meta.json")
        meta = {}
        if meta_path.is_file():
            try:
                meta = json.loads(meta_path.read_text())
            except json.JSONDecodeError:
                meta = {}
        resolved_model = next(iter(agg["usage_by_model"]), None) or meta.get("model", "unknown")
        usage_total = sum_usage_across_models(agg["usage_by_model"])
        costs = [cost_for_usage(b, m) for m, b in agg["usage_by_model"].items()]
        # None if any model this subagent used is unpriced — an incomplete sum would
        # understate cost, not just omit it, so the total must be honestly unknown too.
        cost_total = None if any(c is None for c in costs) else sum(costs, 0.0)
        roster.append({
            "name": meta.get("name", jsonl_path.stem),
            "role": meta.get("customAgentType", "unknown"),
            "raw_model_alias": meta.get("model", "unknown"),
            "model": resolved_model,
            "effort": "unknown (not recorded in transcript)",
            "tokens": total_tokens(usage_total),
            "cost_est": round(cost_total, 4) if cost_total is not None else None,
            "tool_calls": sum(agg["tool_counts"].values()),
            "files_touched": len(agg["files_touched"]),
            "errors": sum(agg["tool_errors"].values()),
        })
    return roster


def build_summary(cwd, project_dir, session_path, resolution_method):
    main_records, main_parse_errors = load_jsonl(session_path)
    main_agg = aggregate_transcript(main_records)

    session_id = session_path.stem
    subagents_dir = project_dir / session_id / "subagents"
    roster = gather_subagents(subagents_dir)

    combined_usage = {}
    merge_usage(combined_usage, main_agg["usage_by_model"])
    combined_tool_counts = dict(main_agg["tool_counts"])
    combined_tool_errors = dict(main_agg["tool_errors"])
    combined_files = set(main_agg["files_touched"])

    for jsonl_path in sorted(subagents_dir.glob("*.jsonl")) if subagents_dir.is_dir() else []:
        records, _ = load_jsonl(jsonl_path)
        agg = aggregate_transcript(records)
        merge_usage(combined_usage, agg["usage_by_model"])
        merge_counts(combined_tool_counts, agg["tool_counts"])
        merge_counts(combined_tool_errors, agg["tool_errors"])
        combined_files |= agg["files_touched"]

    by_model = {}
    total_cost = 0.0
    total_tok = 0
    cache_read_sum = 0
    cache_base_sum = 0  # input + cache_read, the denominator for hit ratio
    for model, bucket in combined_usage.items():
        cost = cost_for_usage(bucket, model)
        by_model[model] = {
            "tokens": bucket,
            "total_tokens": total_tokens(bucket),
            "cost_est": round(cost, 4) if cost is not None else None,
        }
        total_tok += total_tokens(bucket)
        cache_read_sum += bucket["cache_r"]
        cache_base_sum += bucket["cache_r"] + bucket["input"]
        if cost is not None:
            total_cost += cost

    timestamps = sorted(main_agg["timestamps"])
    wall_start, wall_end, wall_seconds = None, None, None
    if timestamps:
        wall_start, wall_end = timestamps[0], timestamps[-1]
        try:
            t0 = datetime.datetime.fromisoformat(wall_start.replace("Z", "+00:00"))
            t1 = datetime.datetime.fromisoformat(wall_end.replace("Z", "+00:00"))
            wall_seconds = (t1 - t0).total_seconds()
        except ValueError:
            pass

    return {
        "note": (
            "Metrics are derived entirely from the local session transcript; "
            "aggregate metrics (e.g. OTEL) can't attribute to this specific session "
            "or reconstruct per-session detail, so they are not consulted."
        ),
        "price_table": PRICE_TABLE_META,
        "session": {
            "id": session_id,
            "cwd": cwd,
            "project_dir": str(project_dir),
            "jsonl_path": str(session_path),
            "resolution_method": resolution_method,
            "git_branch": main_agg["git_branch"],
            "claude_code_version": main_agg["version"],
            "parse_errors": main_parse_errors,
        },
        "session_effort": os.environ.get("CLAUDE_EFFORT", "unknown (CLAUDE_EFFORT not set)"),
        "totals": {
            "tokens": total_tok,
            "cost_est_usd": round(total_cost, 4),
            "cache_hit_ratio": round(cache_read_sum / cache_base_sum, 4) if cache_base_sum else None,
        },
        "by_model": by_model,
        "tool_usage": {
            name: {"count": count, "errors": combined_tool_errors.get(name, 0)}
            for name, count in sorted(combined_tool_counts.items(), key=lambda kv: -kv[1])
        },
        "coordination_tool_calls": {
            name: combined_tool_counts.get(name, 0) for name in COORDINATION_TOOLS if name in combined_tool_counts
        },
        "timeline": {
            "wall_clock_start": wall_start,
            "wall_clock_end": wall_end,
            "wall_clock_duration_seconds": wall_seconds,
            "turn_duration_ms_total": main_agg["turn_duration_ms_total"],
            "turn_count": main_agg["turn_duration_count"],
        },
        "files_touched": sorted(combined_files),
        "thinking": {
            "block_count": main_agg["thinking_count"],
            "char_count": main_agg["thinking_chars"],
        },
        "subagents": roster,
    }


def render_html(summary):
    """Build the self-contained HTML report. No CDN, no external assets."""
    s = summary

    def esc(v):
        return html.escape(str(v)) if v is not None else "—"

    model_rows = "".join(
        f"<tr><td>{esc(model)}</td><td>{data['total_tokens']:,}</td>"
        f"<td>{'$%.4f' % data['cost_est'] if data['cost_est'] is not None else 'n/a (unpriced model)'}</td></tr>"
        for model, data in sorted(s["by_model"].items(), key=lambda kv: -kv[1]["total_tokens"])
    )

    roster_rows = "".join(
        f"<tr><td>{esc(a['name'])}</td><td>{esc(a['role'])}</td><td>{esc(a['model'])}</td>"
        f"<td>{esc(a['effort'])}</td><td>{a['tokens']:,}</td>"
        f"<td>{'$%.4f' % a['cost_est'] if a['cost_est'] is not None else 'n/a (unpriced model)'}</td>"
        f"<td>{a['tool_calls']}</td><td>{a['errors']}</td><td>{a['files_touched']}</td></tr>"
        for a in s["subagents"]
    )

    tool_rows = "".join(
        f"<tr><td>{esc(name)}</td><td>{d['count']}</td><td>{d['errors']}</td></tr>"
        for name, d in s["tool_usage"].items()
    )

    files_items = "".join(f"<li>{esc(f)}</li>" for f in s["files_touched"])

    kpi = s["totals"]
    timeline = s["timeline"]

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Session Metrics — {esc(s['session']['id'])}</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 2rem; max-width: 1100px; }}
  h1, h2 {{ font-weight: 600; }}
  .note {{ color: #888; font-size: 0.9rem; margin-bottom: 1.5rem; }}
  .kpis {{ display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 2rem; }}
  .kpi {{ border: 1px solid #ccc; border-radius: 8px; padding: 1rem; min-width: 160px; }}
  .kpi .label {{ font-size: 0.8rem; color: #888; text-transform: uppercase; }}
  .kpi .value {{ font-size: 1.6rem; font-weight: 700; }}
  table {{ border-collapse: collapse; width: 100%; margin-bottom: 2rem; }}
  th, td {{ text-align: left; padding: 0.4rem 0.8rem; border-bottom: 1px solid #ddd; }}
  th {{ cursor: pointer; user-select: none; }}
  th.sorted-asc::after {{ content: " ▲"; }}
  th.sorted-desc::after {{ content: " ▼"; }}
  .marquee {{ border: 2px solid #5b8def; border-radius: 10px; padding: 1rem; background: rgba(91,141,239,0.06); }}
  details {{ margin-bottom: 2rem; }}
  pre {{ white-space: pre-wrap; background: #1111110d; padding: 1rem; border-radius: 8px; max-height: 500px; overflow: auto; }}
  section {{ margin-bottom: 2.5rem; }}
</style>
</head>
<body>
<h1>Session Metrics</h1>
<p class="note">{esc(s['note'])}<br>
Session: {esc(s['session']['id'])} · cwd: {esc(s['session']['cwd'])} · branch: {esc(s['session']['git_branch'])} ·
Claude Code {esc(s['session']['claude_code_version'])} · resolved via {esc(s['session']['resolution_method'])}<br>
Session-level effort ($CLAUDE_EFFORT): {esc(s['session_effort'])}<br>
Price table last updated: {esc(s['price_table']['updated'])}</p>

<section class="kpis">
  <div class="kpi"><div class="label">Total tokens</div><div class="value">{kpi['tokens']:,}</div></div>
  <div class="kpi"><div class="label">Est. cost (USD)</div><div class="value">${kpi['cost_est_usd']:.4f}</div></div>
  <div class="kpi"><div class="label">Cache hit ratio</div><div class="value">{'%.1f%%' % (kpi['cache_hit_ratio']*100) if kpi['cache_hit_ratio'] is not None else 'n/a'}</div></div>
  <div class="kpi"><div class="label">Wall clock</div><div class="value">{'%.0fs' % timeline['wall_clock_duration_seconds'] if timeline['wall_clock_duration_seconds'] is not None else 'n/a'}</div></div>
  <div class="kpi"><div class="label">Turn time</div><div class="value">{timeline['turn_duration_ms_total']/1000:.0f}s</div></div>
  <div class="kpi"><div class="label">Files touched</div><div class="value">{len(s['files_touched'])}</div></div>
</section>

<section>
<h2>Token &amp; Cost by Model (est.)</h2>
<table id="model-table">
<thead><tr><th>Model</th><th>Tokens</th><th>Est. cost</th></tr></thead>
<tbody>{model_rows}</tbody>
</table>
</section>

<section class="marquee">
<h2>Subagent Roster</h2>
<table id="roster-table">
<thead><tr><th>Name</th><th>Role</th><th>Model</th><th>Effort</th><th>Tokens</th><th>Est. cost</th><th>Tool calls</th><th>Errors</th><th>Files</th></tr></thead>
<tbody>{roster_rows or '<tr><td colspan="9">No subagents in this session.</td></tr>'}</tbody>
</table>
</section>

<section>
<h2>Tool Usage Breakdown</h2>
<table id="tool-table">
<thead><tr><th>Tool</th><th>Calls</th><th>Errors</th></tr></thead>
<tbody>{tool_rows}</tbody>
</table>
</section>

<section>
<h2>Timeline</h2>
<table id="timeline-table">
<tbody>
<tr><td>Wall-clock start</td><td>{esc(timeline['wall_clock_start'])}</td></tr>
<tr><td>Wall-clock end</td><td>{esc(timeline['wall_clock_end'])}</td></tr>
<tr><td>Wall-clock duration</td><td>{'%.0fs' % timeline['wall_clock_duration_seconds'] if timeline['wall_clock_duration_seconds'] is not None else 'n/a'}</td></tr>
<tr><td>Total turn duration (system turn_duration records)</td><td>{timeline['turn_duration_ms_total']/1000:.1f}s across {timeline['turn_count']} turns</td></tr>
</tbody>
</table>
</section>

<section>
<h2>Files Touched ({len(s['files_touched'])})</h2>
<ul>{files_items or '<li>None recorded.</li>'}</ul>
</section>

<section>
<details>
<summary>Raw JSON summary</summary>
<pre>{esc(json.dumps(s, indent=2, default=str))}</pre>
</details>
</section>

<script>
// Vanilla-JS sortable tables: click a header to sort its table by that column.
document.querySelectorAll("table").forEach(function (table) {{
  var headers = table.querySelectorAll("th");
  headers.forEach(function (th, colIndex) {{
    th.addEventListener("click", function () {{
      var tbody = table.querySelector("tbody");
      var rows = Array.prototype.slice.call(tbody.querySelectorAll("tr"));
      var asc = !th.classList.contains("sorted-asc");
      headers.forEach(function (h) {{ h.classList.remove("sorted-asc", "sorted-desc"); }});
      th.classList.add(asc ? "sorted-asc" : "sorted-desc");
      rows.sort(function (a, b) {{
        var av = a.children[colIndex].innerText.trim();
        var bv = b.children[colIndex].innerText.trim();
        var an = parseFloat(av.replace(/[^0-9.\\-]/g, ""));
        var bn = parseFloat(bv.replace(/[^0-9.\\-]/g, ""));
        var cmp = (!isNaN(an) && !isNaN(bn)) ? an - bn : av.localeCompare(bv);
        return asc ? cmp : -cmp;
      }});
      rows.forEach(function (r) {{ tbody.appendChild(r); }});
    }});
  }});
}});
</script>
</body>
</html>"""


def main():
    cwd = os.getcwd()
    project_dir = Path.home() / ".claude" / "projects" / cwd_slug(cwd)
    if not project_dir.is_dir():
        print(f"Error: no Claude Code project directory found at {project_dir}", file=sys.stderr)
        sys.exit(1)

    session_path, resolution_method = resolve_session_jsonl(project_dir)
    if session_path is None:
        print(f"Error: no session *.jsonl found under {project_dir}", file=sys.stderr)
        sys.exit(1)

    summary = build_summary(cwd, project_dir, session_path, resolution_method)

    html_content = render_html(summary)
    fd, html_path = tempfile.mkstemp(prefix=f"session-metrics-{summary['session']['id']}-", suffix=".html")
    with os.fdopen(fd, "w") as f:
        f.write(html_content)

    summary["html_report_path"] = html_path
    print(json.dumps(summary, indent=2, default=str))
    print(html_path)


if __name__ == "__main__":
    main()
