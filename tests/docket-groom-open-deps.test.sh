#!/bin/bash

# Behavior suite for the open-dependency gate helper
# (skills/docket-groom/scripts/open-deps.sh).
#
# WHY THIS EXISTS. A groom pass certified eight route-run issues as waiting
# on a named prerequisite, and every prerequisite carried route-direct. A
# run never does route-direct work, so docket-plan deferred all eight on
# every pass as "unavailable prerequisite" and nothing named the route that
# held them. The helper now prints each open target's route beside its
# status, so the gate can split "waiting on a run prerequisite" from
# "waiting on direct work" mechanically. Each rule has a failure that reads
# as success: a helper that prints status alone passes the cross-route edge
# unseen; one that reads the first label only misses route-direct behind a
# size label; one that exits 0 on a missing target lets the gate call the
# dependent run-ready.
#
# HOW. Puts a fake docket on PATH that answers `issue show` from fixture
# files, one per id. Needs bash and jq.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HELPER="${OPEN_DEPS:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-groom/scripts/open-deps.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1"; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$HELPER" ] || fatal "open-deps.sh not found at ${HELPER}"
command -v jq >/dev/null 2>&1 || fatal "jq is required"
[ -x "$HELPER" ] && pass "open-deps.sh is executable" || fail "open-deps.sh is not executable"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-groom-open-deps.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/store" "$WORK/checkout"

# Fake docket: `docket issue show <id> --json=v2` prints store/<id>.json or
# fails like the CLI does on an unknown id.
cat > "$WORK/bin/docket" <<'FAKE'
#!/bin/bash
[ "$1" = issue ] && [ "$2" = show ] || { echo '{"ok":false}' >&2; exit 2; }
f="$DOCKET_FAKE_STORE/$3.json"
[ -f "$f" ] || { echo '{"ok":false,"error":{"code":"NOT_FOUND"}}' >&2; exit 1; }
cat "$f"
FAKE
chmod +x "$WORK/bin/docket"
export DOCKET_FAKE_STORE="$WORK/store"
export PATH="$WORK/bin:$PATH"

# issue <id> <status> <kind> <labels-json> <depends-on-json>
issue() {
    jq -n --arg id "$1" --arg status "$2" --arg kind "$3" --argjson labels "$4" --argjson deps "$5" \
        '{ok:true,data:{id:$id,status:$status,kind:$kind,labels:$labels,
          relations:[$deps[] | {relation_type:"depends_on",source_issue_id:$id,target_issue_id:.}]}}' \
        > "$DOCKET_FAKE_STORE/$1.json"
}

issue T-1 backlog task '["route-run"]' '[]'
issue T-2 done task '["route-direct"]' '[]'
issue T-3 todo task '["small","route-direct"]' '[]'
issue T-4 backlog task '[]' '[]'
issue T-5 backlog epic '["blocked"]' '[]'
issue T-6 backlog task '["route-loop","blocked"]' '[]'
issue T-7 backlog task '["route-run","blocked"]' '[]'
issue T-10 backlog task '["route-direct"]' '[]'
issue T-11 backlog epic '["route-run"]' '[]'
issue D-run backlog task '["route-run"]' '["T-1"]'
issue D-done backlog task '["route-run"]' '["T-2"]'
issue D-direct backlog task '["route-run"]' '["T-3"]'
issue D-mixed backlog task '["route-run"]' '["T-1","T-3","T-2"]'
issue D-unrouted backlog task '["route-run"]' '["T-4"]'
issue D-epic backlog task '["route-run"]' '["T-5"]'
issue D-loop backlog task '["route-run"]' '["T-6"]'
issue D-missing backlog task '["route-run"]' '["T-9"]'
issue D-runblocked backlog task '["route-run"]' '["T-7"]'
issue D-prefix backlog task '["route-run"]' '["T-1","T-10"]'
issue D-staleepic backlog task '["route-run"]' '["T-11"]'

run() { # ids... -> sets OUT and RC
    OUT=$(printf '%s\n' "$@" | "$HELPER" --checkout "$WORK/checkout" 2>&1); RC=$?
}

run D-done
[ "$RC" -eq 0 ] && [ -z "$OUT" ] && pass "done target prints nothing" || fail "done target: rc=$RC out='$OUT'"

run D-run
[ "$RC" -eq 0 ] && [ "$OUT" = $'D-run\tT-1(backlog,route-run)' ] && pass "run target carries its route" || fail "run target: rc=$RC out='$OUT'"

run D-direct
[ "$RC" -eq 0 ] && [ "$OUT" = $'D-direct\tT-3(todo,route-direct)' ] && pass "route-direct behind a size label is named" || fail "direct target: rc=$RC out='$OUT'"

run D-mixed
[ "$RC" -eq 0 ] && [ "$OUT" = $'D-mixed\tT-1(backlog,route-run),T-3(todo,route-direct)' ] && pass "mixed targets list open ones in order, done one dropped" || fail "mixed: rc=$RC out='$OUT'"

run D-unrouted
[ "$OUT" = $'D-unrouted\tT-4(backlog,unrouted)' ] && pass "unlabelled target is unrouted" || fail "unrouted: out='$OUT'"

run D-epic
[ "$OUT" = $'D-epic\tT-5(backlog,epic+blocked)' ] && pass "epic target names epic and blocked" || fail "epic: out='$OUT'"

run D-loop
[ "$OUT" = $'D-loop\tT-6(backlog,route-loop+blocked)' ] && pass "route-loop target with blocked" || fail "loop: out='$OUT'"

run D-missing
[ "$RC" -eq 1 ] && [ "$OUT" = $'D-missing\tT-9(missing,missing)' ] && pass "missing target sets exit 1" || fail "missing target: rc=$RC out='$OUT'"

run X-0
[ "$RC" -eq 1 ] && [ "$OUT" = $'X-0\tunresolved' ] && pass "unresolved id sets exit 1" || fail "unresolved: rc=$RC out='$OUT'"

run D-runblocked
[ "$OUT" = $'D-runblocked\tT-7(backlog,route-run+blocked)' ] && pass "route-run target with blocked keeps the suffix" || fail "run+blocked: out='$OUT'"

run D-prefix
[ "$RC" -eq 0 ] && [ "$OUT" = $'D-prefix\tT-1(backlog,route-run),T-10(backlog,route-direct)' ] && pass "cache key does not collide on an id prefix" || fail "prefix: rc=$RC out='$OUT'"

run D-staleepic
[ "$OUT" = $'D-staleepic\tT-11(backlog,epic)' ] && pass "epic with a stale route-run label still prints epic" || fail "stale epic: out='$OUT'"

run D-direct D-run D-direct
want=$'D-direct\tT-3(todo,route-direct)\nD-run\tT-1(backlog,route-run)\nD-direct\tT-3(todo,route-direct)'
[ "$RC" -eq 0 ] && [ "$OUT" = "$want" ] && pass "cached target keeps its route on reuse" || fail "cache: rc=$RC out='$OUT'"

OUT=$("$HELPER" 2>&1 </dev/null); RC=$?
[ "$RC" -eq 2 ] && pass "no checkout is a usage error" || fail "usage: rc=$RC"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
