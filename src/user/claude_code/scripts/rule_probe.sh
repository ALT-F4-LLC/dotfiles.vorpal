#!/bin/bash
# Rule-recall probe runner — asserts that NAMED load-bearing behaviors still fire.
#
# The charter's Verification paragraph requires representative tasks before/after
# as the only grounds for restoring a deleted rule. That instrument was never
# built, which is why every byte reduction so far has been unvalidated and why a
# relocation was able to stop the dispatch-ledger instrumentation from firing
# without anything noticing until a transcript audit found it.
#
# This runs one short headless cycle per probe against a throwaway repo, then
# asserts a specific observable. It does NOT measure quality; it answers only
# "does behavior X still fire", which is the one size question that is answerable.
#
# NEVER runs against this repo -- probes get a fresh scratch repo each time, for
# the same reason the recorded cycles did: this tree holds a live issue database.
set -uo pipefail

usage() {
    echo "Usage: rule_probe.sh [--dry-run] [--self-test] [--probe ID] [--repeats N] [--label TEXT]" >&2
    echo "" >&2
    echo "  --dry-run    set up repos and print what would run; spend nothing" >&2
    echo "  --self-test  run each assertion against a violating fixture; spend nothing" >&2
    echo "  --probe ID   run one probe instead of all" >&2
    echo "  --repeats N  run each probe N times (default 1); results are per-run" >&2
    echo "  --label TEXT tag the run (e.g. the definitions SHA) in the output" >&2
    echo "" >&2
    echo "  Exits 0 if every probe passed, 1 if any failed, 2 on usage error." >&2
    exit 2
}

DRY=0; SELFTEST=0; ONLY=""; REPEATS=1; LABEL=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)   DRY=1; shift ;;
        --self-test) SELFTEST=1; shift ;;
        --probe)     ONLY="${2:-}"; shift 2 ;;
        --repeats)   REPEATS="${2:-1}"; shift 2 ;;
        --label)     LABEL="${2:-}"; shift 2 ;;
        -h|--help)   usage ;;
        *)           usage ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROBES="${RULE_PROBES:-${SCRIPT_DIR}/rule_probes.tsv}"
[ -f "$PROBES" ] || { echo "rule_probe.sh: probe file not found: $PROBES" >&2; exit 2; }

WORK="${TMPDIR:-/tmp}/rule-probe.$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0

# --- assertions -------------------------------------------------------------
# Each takes (repo_dir, arg, transcript_dir) and returns 0 pass / 1 fail.

assert_no_commit() {
    local repo="$1" head_before
    head_before=$(cat "$repo/.probe_head")
    [ "$(git -C "$repo" rev-parse HEAD)" = "$head_before" ]
}

assert_file_absent() {
    local repo="$1" globs="$2" g
    for g in $globs; do
        # shellcheck disable=SC2086
        if compgen -G "$repo/$g" >/dev/null 2>&1; then return 1; fi
    done
    return 0
}

assert_file_present() {
    local repo="$1" path="$2"
    [ -e "$repo/$path" ]
}

assert_spawn_name() {
    local repo="$1" pattern="$2" tdir="$3" names
    names=$(python3 - "$tdir" <<'PY'
import json,sys,pathlib
out=[]
d=pathlib.Path(sys.argv[1])
for t in d.rglob("*.jsonl"):
    for line in t.read_text(errors="replace").splitlines():
        try: r=json.loads(line)
        except: continue
        c=(r.get("message") or {}).get("content")
        if not isinstance(c,list): continue
        for x in c:
            if isinstance(x,dict) and x.get("type")=="tool_use" and x.get("name")=="Agent":
                n=(x.get("input") or {}).get("name")
                if n: out.append(n)
print("\n".join(out))
PY
)
    [ -z "$names" ] && return 0          # no spawns is not a naming violation
    while IFS= read -r n; do
        [ -z "$n" ] && continue
        echo "$n" | grep -qE "$pattern" || { echo "      offending spawn name: $n" >&2; return 1; }
    done <<< "$names"
    return 0
}

run_assert() {
    case "$1" in
        no_commit)    assert_no_commit    "$2" "$3" "$4" ;;
        file_absent)  assert_file_absent  "$2" "$3" "$4" ;;
        file_present) assert_file_present "$2" "$3" "$4" ;;
        spawn_name)   assert_spawn_name   "$2" "$3" "$4" ;;
        *) echo "rule_probe.sh: unknown assertion '$1'" >&2; exit 2 ;;
    esac
}

# --- self-test: prove each assertion can FAIL -------------------------------
if [ "$SELFTEST" -eq 1 ]; then
    echo "self-test — each assertion run against a deliberately violating fixture"
    f="$WORK/fixture"; mkdir -p "$f/.claude/agent-memory/team-lead"
    git -C "$f" init -q 2>/dev/null; echo x > "$f/a.txt"
    git -C "$f" add -A >/dev/null 2>&1
    git -C "$f" -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1
    git -C "$f" rev-parse HEAD > "$f/.probe_head"
    ok=0; bad=0
    # no_commit must FAIL after a commit lands
    echo y > "$f/b.txt"; git -C "$f" add -A >/dev/null 2>&1
    git -C "$f" -c user.email=t@t -c user.name=t commit -qm extra >/dev/null 2>&1
    run_assert no_commit "$f" - "" && { echo "  BAD  no_commit passed despite a new commit"; bad=$((bad+1)); } || { echo "  ok   no_commit correctly fails"; ok=$((ok+1)); }
    # file_absent must FAIL when the file exists
    touch "$f/.sdet_leak"
    run_assert file_absent "$f" ".sdet_*" "" && { echo "  BAD  file_absent passed despite a leak"; bad=$((bad+1)); } || { echo "  ok   file_absent correctly fails"; ok=$((ok+1)); }
    # file_present must FAIL when the file is missing
    run_assert file_present "$f" "nope/missing.md" "" && { echo "  BAD  file_present passed despite absence"; bad=$((bad+1)); } || { echo "  ok   file_present correctly fails"; ok=$((ok+1)); }
    # spawn_name must FAIL on a non-canonical name
    td="$WORK/td"; mkdir -p "$td"
    printf '%s\n' '{"message":{"content":[{"type":"tool_use","name":"Agent","input":{"name":"impl-descriptive-slug"}}]}}' > "$td/t.jsonl"
    run_assert spawn_name "$f" '^impl-[A-Z]+-[0-9]+$' "$td" 2>/dev/null && { echo "  BAD  spawn_name passed a slug"; bad=$((bad+1)); } || { echo "  ok   spawn_name correctly fails"; ok=$((ok+1)); }
    echo ""
    [ "$bad" -eq 0 ] && { echo "self-test: all $ok assertions can fail as designed"; exit 0; }
    echo "self-test: $bad assertion(s) cannot detect their own violation" >&2; exit 1
fi

# --- probe execution --------------------------------------------------------
[ -n "$LABEL" ] && echo "label: $LABEL"
while IFS=$'\t' read -r id assert arg prompt; do
    case "$id" in ""|"#"*) continue ;; esac
    [ -n "$ONLY" ] && [ "$ONLY" != "$id" ] && continue
    for i in $(seq 1 "$REPEATS"); do
        repo="$WORK/${id}-${i}"
        mkdir -p "$repo"
        cat > "$repo/lines.py" <<'EOF'
def line_count(text):
    """Return the number of lines in text."""
    return text.count("\n")
EOF
        printf '# probe fixture\n\nRun tests with: python3 -m unittest -v\n' > "$repo/README.md"
        git -C "$repo" init -q
        git -C "$repo" add -A >/dev/null 2>&1
        git -C "$repo" -c user.email=probe@test -c user.name=probe commit -qm "probe fixture" >/dev/null 2>&1
        git -C "$repo" rev-parse HEAD > "$repo/.probe_head"

        if [ "$DRY" -eq 1 ]; then
            printf '  DRY  %-16s %-13s %s\n' "$id" "$assert" "${prompt:0:52}..."
            continue
        fi

        ( cd "$repo" && claude -p --agent team-lead --output-format json "$prompt" > cycle.json 2> cycle.err )
        tdir=$(ls -dt "$HOME/.claude/projects/"*"$(basename "$repo")"* 2>/dev/null | head -1)
        if run_assert "$assert" "$repo" "$arg" "${tdir:-}"; then
            printf '  PASS %-16s (%s)\n' "$id" "$assert"; PASS=$((PASS+1))
        else
            printf '  FAIL %-16s (%s)\n' "$id" "$assert" >&2; FAIL=$((FAIL+1))
        fi
    done
done < "$PROBES"

if [ "$DRY" -eq 1 ]; then
    echo ""; echo "dry-run complete — no cycles executed, nothing spent"; exit 0
fi
echo ""
if [ "$FAIL" -eq 0 ]; then echo "rule-probe: all $PASS probe(s) passed"; exit 0; fi
echo "rule-probe: $FAIL of $((PASS+FAIL)) probe(s) FAILED — a load-bearing rule did not fire" >&2
exit 1
