#!/bin/bash

# Behavior suite for the docket-plan binding and cost probe
# (skills/docket-plan/scripts/bind-probe.sh).
#
# WHY THIS EXISTS. docket-plan rebuilt the same workflow-binding probe and
# cost arithmetic by hand in every planning session, and the hand versions
# failed in recurring ways: a wrong JSON path read an empty workflow list as
# "nothing registered"; a deprecated or older version counted as a second
# match; a `when`-gated loop step was priced once per variant; and the loop
# step already inside the `workflow show` total was added again as rework
# headroom. Each of those reads as a plausible number, so the suite pins one
# fixture per failure.
#
# HOW. Feeds the probe a fixture registry (the shape of `docket workflow list
# --json=v2`) through --workflows and issue rows through stdin. Needs jq; no
# engine, no network.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROBE="${BIND_PROBE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-plan/scripts/bind-probe.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1"; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$PROBE" ] || fatal "bind-probe.sh not found at ${PROBE}"
[ -x "$PROBE" ] && pass "bind-probe.sh is executable" || fail "bind-probe.sh is not executable"

TMPD=$(mktemp -d "${TMPDIR:-/tmp}/bind-probe-test.XXXXXX")
trap 'rm -rf "$TMPD"' EXIT

# base: baseline, matches unless a variant label is present. fast: v1 retired,
# v2 live, binds `small`. ui: two `when`-gated revise variants of one loop.
cat > "$TMPD/wf.json" <<'JSON'
{"ok":true,"data":{"total":5,"truncated":false,"items":[
 {"name":"base","version":3,"definition":{"match":{"unless_labels":["small","ui","blocked"]},"steps":[
   {"name":"impl","expected_cost":1.0,"after":[]},
   {"name":"review","fanout":["a","b","c"],"expected_cost":0.5,"after":["impl"]},
   {"name":"gate","expected_cost":0,"max_fix_loops":2,"after":["review"]},
   {"name":"fix","loop":true,"after_loop":"review","expected_cost":1.0,"after":null}]}},
 {"name":"fast","version":1,"deprecated_at_ms":5,"definition":{"match":{"labels_any":["small"]},"steps":[{"name":"impl","expected_cost":9}]}},
 {"name":"fast","version":2,"definition":{"match":{"labels_any":["small"]},"steps":[{"name":"impl","expected_cost":1.0,"after":[]}]}},
 {"name":"ui","version":1,"definition":{"match":{"labels_any":["ui"],"labels_all":["route-run"]},"steps":[
   {"name":"impl","expected_cost":1.0,"after":[]},
   {"name":"judge","expected_cost":1.0,"max_fix_loops":2,"after":["impl"]},
   {"name":"revise-a","loop":true,"after_loop":"judge","expected_cost":1.5,"after":null},
   {"name":"revise-b","loop":true,"after_loop":"judge","expected_cost":1.5,"after":null}]}},
 {"name":"also-small","version":1,"definition":{"match":{"labels_any":["small"]},"steps":[{"name":"impl","expected_cost":1}]}}
]}}
JSON

row() { printf '%s' "$1" | "$PROBE" --workflows "$TMPD/wf.json" 2>&1; }
field() { printf '%s\n' "$1" | awk -F'\t' -v n="$2" 'NR==2 {print $n}'; }

out=$(row '[{"id":"A-1","labels":["route-run"]}]')
[ "$(field "$out" 2)" = 1 ] && [ "$(field "$out" 3)" = "base@3" ] \
  && pass "baseline binds on no variant label" || fail "baseline binding: $out"
# floor = 1.0 + 0.5*3 + 0 + 1.0 = 3.5; round = fix 1.0 + review 1.5 = 2.5 (gate 0);
# headroom = 2.5*2 - 1.0 already in the floor = 4.0
[ "$(field "$out" 4)" = 3.5 ] && [ "$(field "$out" 5)" = 2 ] && [ "$(field "$out" 6)" = 2.5 ] && [ "$(field "$out" 7)" = 4 ] && [ "$(field "$out" 8)" = 7.5 ] \
  && pass "floor expands fanout; headroom nets the loop step out of the floor" || fail "baseline costs: $out"

out=$(row '[{"id":"A-2","labels":["small"]}]')
[ "$(field "$out" 2)" = 2 ] && [ "$(field "$out" 3)" = "also-small@1,fast@2" ] \
  && pass "retired version is not a match; two live names count as two" || fail "small binding: $out"
[ "$(field "$out" 4)" = "-" ] \
  && pass "no cost is printed unless exactly one workflow binds" || fail "cost on ambiguous binding: $out"

out=$(row '[{"id":"A-3","labels":["ui"]}]')
[ "$(field "$out" 2)" = 0 ] \
  && pass "labels_all unmet binds nothing" || fail "labels_all: $out"

out=$(row '[{"id":"A-8","labels":["route-run","blocked"]}]')
[ "$(field "$out" 2)" = 0 ] \
  && pass "unless_labels wins: a blocked issue binds nothing" || fail "blocked binding: $out"

out=$(row '[{"id":"A-4","labels":["ui","route-run"]}]')
# floor = 1.0 + 1.0 + 1.5 + 1.5 = 5.0; round = max revise 1.5 + judge 1.0 = 2.5;
# headroom = 2.5*2 - 3.0 (both variants in the floor) = 2.0
[ "$(field "$out" 3)" = "ui@1" ] && [ "$(field "$out" 4)" = 5 ] && [ "$(field "$out" 6)" = 2.5 ] && [ "$(field "$out" 7)" = 2 ] && [ "$(field "$out" 8)" = 7 ] \
  && pass "when-gated loop variants are alternatives in one round" || fail "ui costs: $out"

out=$(printf '%s' '{"ok":true,"data":{"id":"A-5","labels":["route-run"]}}' | "$PROBE" --workflows "$TMPD/wf.json" 2>&1)
[ "$(field "$out" 1)" = "A-5" ] \
  && pass "reads an issue show envelope" || fail "show envelope: $out"

out=$(printf '%s' '{"ok":true,"data":{"items":[{"id":"A-6","labels":["route-run"]}],"total":1}}' | "$PROBE" --workflows "$TMPD/wf.json" 2>&1)
[ "$(field "$out" 1)" = "A-6" ] \
  && pass "reads an issue list envelope" || fail "list envelope: $out"

out=$(printf '%s' '[{"id":"A-7","labels":[]}]' | "$PROBE" --workflows "$TMPD/empty.json" 2>&1); rc=$?
[ "$rc" -ne 0 ] && pass "unreadable registry is a failure, not an empty table" || fail "missing registry exited 0: $out"

printf '%s' 'not json' | "$PROBE" --workflows "$TMPD/wf.json" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "non-JSON input exits 2" || fail "non-JSON input exited $rc"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
