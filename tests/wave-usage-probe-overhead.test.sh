#!/bin/bash

# Behavior suite for wave-usage's three-way split of a wave's agents —
# judge, claimant, overhead — and specifically for the ordering of the two
# questions it asks a bootstrap brief.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `python3` — no engine, no
# database, no network, and it never runs a wave.
#
# WHY THIS EXISTS. wave.js spawns read-only probes (`docket step show STEP-N
# --json`) beside its executors, and the usage join once keyed on the first
# STEP-N in a brief, so each probe back-filled its tokens onto the step it had
# merely READ — RUN-66 wave 2 put whole ledger rows on STEP-3146 (pending,
# never claimed) and STEP-3158 (superseded). The join now reads the `docket
# step claim/record STEP-N` obligation instead, and the read test now runs
# BEFORE that join: a brief that hands its agent one read command is overhead
# however much record-shaped text its prose quotes. The fixtures below are the
# shapes that ordering exists for.
#
# WHAT THIS SUITE CANNOT SEE: it exercises classification, not measurement.
# The by-message-id dedup (last write wins) and the arithmetic over the four
# typed units are asserted only far enough to prove a claimant's row carries
# its own agent's spend and nobody else's.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
USAGE="${WAVE_USAGE:-${SCRIPT_DIR}/../src/user/claude_code/scripts/wave-usage}"
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$USAGE" ] || fatal "wave-usage not found at ${USAGE}"
[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v python3 >/dev/null 2>&1 || fatal "python3 is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-usage-probe.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

# ---- The briefs this script keys on must still be the briefs wave.js writes.
# Every constant below is duplicated prose; if wave.js drops one, the join
# silently reclassifies a whole wave, so check the two directions that matter.
grep -qF 'WAVE PROBE: not a step execution' "$WAVE"; ok $? \
    'wave.js still declares its probe briefs with the marker wave-usage reads'
grep -qF 'Run exactly this one command:' "$WAVE"; ok $? \
    'wave.js still opens a probe brief with the fixed one-command line'
grep -qF 'You are executing one step of a Docket run' "$WAVE"; ok $? \
    'wave.js still opens an executor brief with the line the drift guard reads'

# ---- Fixtures ---------------------------------------------------------------
# One synthetic wave directory. Each agent is a bootstrap user message plus two
# assistant messages carrying usage, so every agent has spend to misplace.
python3 - "$WORK/wave" <<'PY' || fatal "fixture build failed"
import json, os, sys

d = sys.argv[1]
os.makedirs(d, exist_ok=True)

PROBE_MARKER = "WAVE PROBE: not a step execution"

# wave.js probeBrief(), verbatim in shape, serving the step it READS.
probe = f"""Run exactly this one command:

  docket step show STEP-3146 --json

Return its output VERBATIM as your entire final reply — every line, unedited.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the record currently says.

{PROBE_MARKER}. Your usage is wave overhead. This
read serves STEP-3146, which is the step it READS, not a step you run — the
usage join must not attribute your tokens to it."""

# THE REGRESSION FIXTURE: the same probe, whose prose also QUOTES the
# obligation it is reading about. Record-shaped text in a read-only brief is
# exactly what the old ordering (join first, label second) could not survive.
quoting_probe = probe.replace(
    "read serves STEP-3146",
    "read serves STEP-3146 (whose executor will run `docket step record "
    "STEP-3146` once it claims)")

# A probe from before the marker existed: no declaration at all, just the one
# read command. "Only tells an agent to read/show a step" is the whole shape.
legacy_probe = """Run exactly this one command:

  docket step show STEP-3158 --json

Return its output verbatim as your entire final reply."""

# A real claimant. The join reads the obligation, never the prose around it.
executor = """You are executing one step of a Docket run (dispatch DISPATCH-9).

Obligations:
1. Claim it: `docket step claim STEP-3156 --owner wave:STEP-3156 --render --json`
3. Record it yourself with `docket step record STEP-3156 --artifact-file ...`

Context: your work follows STEP-3146 and must not touch STEP-3158."""

# A judge. Plain mode leaves it to --seats; --seats keys it by (proposal, seat).
judge = """You are seated on a Docket gate panel.

Cast with: docket vote cast PROP-77 --voter reviewer --decision approve"""

# An executor brief whose obligation was reworded out from under the join. It
# also carries a read command, to prove the probe test cannot swallow a
# claimant: this must still be a hard error, never overhead.
drifted = """You are executing one step of a Docket run (dispatch DISPATCH-9).

First read the row: `docket step show STEP-3160 --json`, then do the work and
mark it finished when you are done."""

# A wave agent whose bootstrap arrives list-shaped, so the brief's newlines are
# JSON-encoded as literal backslash-n. Classification must survive the encoding.
LIST_SHAPED = {"agent-alist.jsonl": legacy_probe.replace("STEP-3158", "STEP-3166")}

AGENTS = {
    "agent-aprobe.jsonl": probe,
    "agent-aquoting.jsonl": quoting_probe,
    "agent-alegacy.jsonl": legacy_probe,
    "agent-aexec.jsonl": executor,
    "agent-ajudge.jsonl": judge,
}
AGENTS.update(LIST_SHAPED)

def write(name, bootstrap, out_dir=d, listed=False):
    content = ([{"type": "text", "text": bootstrap}] if listed else bootstrap)
    lines = [{"type": "user", "message": {"content": content}}]
    for i, (out, mid) in enumerate(((100, "msg-a"), (250, "msg-b"))):
        # msg-a is written twice with a GROWING output count: the dedup keeps
        # the last, so this agent's output total is 100 + 250, not 40 + 250.
        if mid == "msg-a":
            lines.append({"type": "assistant", "message": {"id": mid, "usage": {
                "input_tokens": 5, "output_tokens": 40,
                "cache_creation_input_tokens": 1000, "cache_read_input_tokens": 2000}}})
        lines.append({"type": "assistant", "message": {"id": mid, "usage": {
            "input_tokens": 5, "output_tokens": out,
            "cache_creation_input_tokens": 1000, "cache_read_input_tokens": 2000}}})
    with open(os.path.join(out_dir, name), "w", encoding="utf-8") as f:
        for o in lines:
            f.write(json.dumps(o) + "\n")

for name, brief in AGENTS.items():
    write(name, brief, listed=name in LIST_SHAPED)

# The drift fixture lives in its own directory: it is a whole-run failure, and
# one exit code cannot say two things at once.
drift_dir = os.path.join(os.path.dirname(d), "drift")
os.makedirs(drift_dir, exist_ok=True)
write("agent-adrift.jsonl", drifted, out_dir=drift_dir)
PY

# ---- Plain mode: only the claimant reaches the ledger ------------------------
python3 "$USAGE" "$WORK/wave" > "$WORK/rows.json" 2> "$WORK/rows.err"
ok $? 'plain mode exits 0 on a wave of one executor, three probes and a judge'

steps=$(python3 -c '
import json, sys
print(",".join(sorted({r["step"] for r in json.load(open(sys.argv[1]))})))' "$WORK/rows.json")
[ "$steps" = "STEP-3156" ]; ok $? \
    "the only step keyed is the one an agent was obliged to record (got: ${steps:-none})"

for probed in STEP-3146 STEP-3158 STEP-3166; do
    ! grep -q "\"$probed\"" "$WORK/rows.json"; ok $? \
        "no ledger row is emitted for ${probed}, which was only READ"
done

# The regression itself: a read-only brief that quotes a record obligation.
grep -q 'agent-aquoting.jsonl: read-only probe' "$WORK/rows.err"; ok $? \
    'a probe brief QUOTING `docket step record STEP-N` is still overhead, not a claimant'

grep -q 'agent-alegacy.jsonl: read-only probe' "$WORK/rows.err"; ok $? \
    'a marker-less brief whose whole job is one read command is named a probe'
grep -q 'agent-alist.jsonl: read-only probe' "$WORK/rows.err"; ok $? \
    'and so is one whose bootstrap arrived JSON-encoded (list-shaped content)'
! grep -q 'not a wave agent' "$WORK/rows.err"; ok $? \
    'no wave probe is left in the unrecognized bucket'

grep -q 'agent-ajudge.jsonl (PROP-77/reviewer): cast a ballot' "$WORK/rows.err"; ok $? \
    'the judge is skipped here and named for --seats, never keyed to a step'

grep -q 'WAVE OVERHEAD: 4 agent(s)' "$WORK/rows.err"; ok $? \
    'all four probes are counted into one reported overhead total'

# The claimant's row carries its own agent's spend only — 2 messages after the
# dedup, output 100+250, cache_read 2000+2000 — with no probe folded in.
python3 - "$WORK/rows.json" <<'PY'
import json, sys
rows = {r["unit"]: r["quantity"] for r in json.load(open(sys.argv[1]))}
want = {"input_tokens": 10, "output_tokens": 350,
        "cache_creation_tokens": 2000, "cache_read_tokens": 4000}
sys.exit(0 if rows == want else 1)
PY
ok $? "the claimant's four units are its own agent's, deduped by message id"

# ---- --seats mode: the mirror image ----------------------------------------
python3 "$USAGE" --seats "$WORK/wave" > "$WORK/seats.json" 2> "$WORK/seats.err"
ok $? '--seats exits 0 over the same directory'
python3 - "$WORK/seats.json" <<'PY'
import json, sys
rows = json.load(open(sys.argv[1]))
keys = {(r["proposal"], r["voter"]) for r in rows}
sys.exit(0 if keys == {("PROP-77", "reviewer")} else 1)
PY
ok $? '--seats emits exactly the judge, keyed by (proposal, seat)'
grep -q 'agent-aexec.jsonl: no seat (never cast)' "$WORK/seats.err"; ok $? \
    'and drops the claimant with a named reason, so the modes partition the wave'

# ---- The drift guard survives the new ordering ------------------------------
python3 "$USAGE" "$WORK/drift" > "$WORK/drift.json" 2> "$WORK/drift.err"
[ $? -eq 1 ]; ok $? \
    'an executor brief with no claim/record obligation is a hard exit 1, not overhead'
grep -q 'RECORD_RE have drifted' "$WORK/drift.err"; ok $? \
    'and the failure names the drift rather than emptying the ledger silently'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
