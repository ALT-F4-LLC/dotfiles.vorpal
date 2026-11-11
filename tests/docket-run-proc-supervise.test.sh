#!/bin/bash

# Suite for the docket-run skill's proc_supervise.sh: the process inventory,
# classification and kill gate the conductor uses on its own session's shells.
#
# Each audited intervention maps to cases below (locators in the docket-run
# reference proc-supervise.md, **Audited scenarios**). H is
# ~/.claude/history.jsonl; P is ~/.claude/projects/-Users-erikreinert-
# Development-repository-github-com-ALT-F4-LLC-.
#   S1  P dotfiles-vorpal-git-main/aab7ddfc-...jsonl:2000   subagent shells
#       overloading the machine, out of the conductor's TaskStop reach
#   S2  P docket-git-feature-engine-improvements/1b58c2fd-...jsonl:18014
#       stale `tail -f | grep -m1` followers
#   S3  same transcript, :23468-23705   a blanket stop killed nine live
#       executor shells taken for leftovers
#   S4  P docket-git-feature-docket-daemon/959a6484-...jsonl:869,964
#       a Bash call blocked on stdin (`python3 -`), auto-backgrounded, hung
#   S5  P docket-git-feature-docket-daemon/bd10139a-...jsonl:1137
#       "Why are there 14 shells running?": counts by owner
#   S6  H:6662-6664   a watcher loop that never fired
#   S7  P docket-git-feature-engine-improvements/b29ca600-...jsonl:724
#       a `nohup &` watcher outside task tracking
#   S8  H:1472 "There are 37 shells open right now."
#
# No fixture is a recording: `ps` is refused in the Bash sandbox, so no
# transcript holds a process table. Each fixture restates the scenario's
# processes as the table the live snapshot would give.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PS_SCRIPT="${PROC_SUPERVISE_SCRIPT:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/scripts/proc_supervise.sh}"

command -v jq >/dev/null 2>&1 || { echo "FATAL: jq is required" >&2; exit 2; }
[ -f "$PS_SCRIPT" ] || { echo "FATAL: no script at $PS_SCRIPT" >&2; exit 2; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/proc-supervise-test.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

CUR=11111111-1111-1111-1111-111111111111
SIB=22222222-2222-2222-2222-222222222222
DEAD=33333333-3333-3333-3333-333333333333
GONE=44444444-4444-4444-4444-444444444444
REUSE=55555555-5555-5555-5555-555555555555
P5=66666666-6666-6666-6666-666666666666
P6=77777777-7777-7777-7777-777777777777
P8=88888888-8888-8888-8888-888888888888
L0="Mon Nov  9 07:00:00 2026"
L0N="Mon Nov 9 07:00:00 2026"
L1="Tue Nov 10 08:00:00 2026"
L2="Tue Nov 10 09:00:00 2026"
L3="Tue Nov 10 10:00:00 2026"
SNAP='/bin/zsh -c source /Users/u/.claude/shell-snapshots/snapshot-zsh-1-a.sh && eval'

row() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }

# The base table: this session (pid 100) with its conductor and agent shells,
# a live sibling (pid 200), and synthetic orphans of dead sessions.
base_snapshot() {
    printf '#self\t151\n#source\tps\n'
    row 1 0 1 "$L0N" - - /sbin/launchd
    row 50 1 50 "$L0N" - - -zsh
    row 100 50 100 "$L1" - - 2.1.322
    row 150 100 150 "$L1" "$CUR" - "$SNAP 'bash proc_supervise.sh inventory'"
    row 151 150 150 "$L1" "$CUR" - "bash proc_supervise.sh inventory"
    row 152 151 150 "$L1" "$CUR" - "awk -F x"
    # S1: an Agent subagent's background suite loops.
    row 110 100 110 "$L1" "$CUR" - "$SNAP 'for m in m3386a m3386b; do bash /private/tmp/claude-501/sg-ac37/run.sh \$m; done'"
    row 111 110 110 "$L1" "$CUR" - "bash /private/tmp/claude-501/sg-ac37/run.sh m3386a"
    # S2: a follower of a finished test run.
    row 120 100 120 "$L1" "$CUR" - "$SNAP 'tail -n +1 -f /private/tmp/claude-501/p/s/tasks/bmw79qtsn.output | grep -m1 -E \"tests: ok\"'"
    row 121 120 120 "$L1" "$CUR" - "tail -n +1 -f /private/tmp/claude-501/p/s/tasks/bmw79qtsn.output"
    row 122 120 120 "$L1" "$CUR" - "grep -m1 -E tests: ok"
    # S3: a live lane executor's gate run.
    row 130 100 130 "$L1" "$CUR" - "$SNAP 'cd /private/tmp/claude-501/STEP-4521.d/wt && make qa-test'"
    row 131 130 130 "$L1" "$CUR" /private/tmp/claude-501/STEP-4521.d/wt "make qa-test"
    # S4: a call blocked on inherited stdin.
    row 140 100 140 "$L1" "$CUR" - "$SNAP 'python3 - 2>/dev/null || true'"
    row 141 140 140 "$L1" "$CUR" - "python3 -"
    # S6: a watcher loop that never fires.
    row 160 100 160 "$L1" "$CUR" - "$SNAP 'while :; do for DIR in \$DIRS; do ls \$DIR; done; sleep 60; done'"
    # S7: a nohup watcher; S5: an engine gate run detached from its executor.
    row 170 1 170 "$L1" "$CUR" - "bash /private/tmp/claude-501/watcher2.sh"
    row 180 1 180 "$L1" "$CUR" - "go1.26.9 test -timeout 60m ./..."
    # Services and hook runners of this session.
    row 190 100 190 "$L1" "$CUR" - "node /Users/u/mcp/server.js"
    row 195 100 195 "$L1" "$CUR" - "/bin/sh -c bash ~/.claude/hooks/docket-park-notice-hook.sh"
    row 196 100 196 "$L1" "$CUR" - "/bin/sh -c ~/.claude/statusline.sh"
    # A nested `claude -p` started from an own shell, and its own shell.
    row 600 100 600 "$L1" "$CUR" - "$SNAP 'claude -p summarize'"
    row 601 600 600 "$L1" "$CUR" - "claude -p summarize"
    row 602 601 602 "$L1" "$P6" - "$SNAP 'make'"
    row 603 601 603 "$L1" "$CUR" - "node /opt/lsp/server.js"
    row 604 601 604 "$L1" "$CUR" - "/bin/sh -c bash ~/.claude/hooks/x-hook.sh"
    # A detached `claude -p` and a child that inherited this session's id.
    row 800 1 800 "$L1" "$CUR" - "claude -p detached"
    row 801 800 801 "$L1" "$CUR" - "node /opt/lsp/server.js"
    # A live sibling session and its shells.
    row 200 1 200 "$L2" - - 2.1.322
    row 210 200 210 "$L2" "$SIB" - "$SNAP 'go test ./...'"
    row 211 210 210 "$L2" "$SIB" - "go test ./..."
    row 220 1 220 "$L2" "$SIB" - "bash sib-nohup.sh"
    # Synthetic orphans: no audited scenario has one (see the reference).
    row 310 1 310 "$L0N" "$DEAD" - "$SNAP 'vorpal build'"
    row 320 1 320 "$L0N" "$GONE" - "cargo build"
    # A live `claude` whose registry start time does not match, with an orphan.
    row 850 1 850 "$L2" - - 2.1.322
    row 851 1 851 "$L2" "$P8" - "bash nohup-job.sh"
    row 400 1 400 "$L3" - - /usr/libexec/somed
    row 410 1 410 "$L0N" "$REUSE" - "sleep 999"
    # An unregistered `claude -p` launched from a dead shell, and its shell.
    row 500 1 500 "$L0N" "$DEAD" - "2.1.322 -p summarize"
    row 501 500 501 "$L0N" "$P5" - "$SNAP 'ls'"
    row 700 1 700 "$L0N" - - /usr/bin/foreign
}
base_sessions() {
    printf '100\t%s\t%s\n' "$CUR" "$L1"
    printf '200\t%s\t%s\n' "$SIB" "$L2"
    printf '300\t%s\t%s\n' "$DEAD" "$L0"
    printf '400\t%s\t%s\n' "$REUSE" "$L0"
    printf '850\t%s\t%s\n' "$P8" "$L0"
    printf '852\t%s\t%s\n' "$P8" "$L0"
}
base_snapshot > "$WORK/snap"
base_sessions > "$WORK/sess"

run() { bash "$PS_SCRIPT" "$@" --snapshot "$WORK/snap" --sessions-tsv "$WORK/sess" --session "$CUR"; }
run inventory > "$WORK/inv" 2>"$WORK/inv.err"; rc=$?
class_of() { awk -F '\t' -v p="$1" '$3 == p && $1 != "summary" { print $1 "/" $2 }' "$WORK/inv"; }
expect_class() { # <pid> <class/action> <label>
    local got; got=$(class_of "$1")
    [ "$got" = "$2" ] && pass "$3: pid $1 is $2" || fail "$3: pid $1 expected $2, got '${got:-<absent>}'"
}
plan() { grep -E '^(refuse|dry-run|would-signal)' "$1" | tr '\n' ' '; }

[ "$rc" -eq 0 ] && pass "inventory exits 0" || fail "inventory exited $rc: $(cat "$WORK/inv.err")"

# ---- audited scenarios -------------------------------------------------------
expect_class 110 own-shell/stop "S1 subagent shell"
expect_class 111 own-shell/stop "S1 subagent suite loop"
expect_class 121 own-shell/stop "S2 tail -f follower"
expect_class 122 own-shell/stop "S2 grep -m1 follower"
expect_class 131 own-shell/stop "S3 executor gate run"
grep -q $'^own-shell\tstop\t131\t.*step=STEP-4521\t/private/tmp/claude-501/STEP-4521.d/wt\t' "$WORK/inv" \
    && pass "S3 executor row shows its step and cwd" || fail "S3 executor row lacks step=STEP-4521 and its cwd"
expect_class 141 own-shell/stop "S4 stdin-blocked call"
expect_class 160 own-shell/stop "S6 watcher loop"
expect_class 170 own-detached/stop "S7 nohup watcher"
expect_class 180 own-detached/stop "S5 detached engine gate run"
grep -q $'^summary\tcount\town-shell\t10$' "$WORK/inv" && grep -q $'^summary\tcount\town-detached\t2$' "$WORK/inv" \
    && grep -q $'^summary\tcount\tsibling\t2$' "$WORK/inv" \
    && pass "S5 summary counts shells by owner" || fail "S5 summary counts wrong: $(grep count "$WORK/inv" | tr '\n' ' ')"

# S3: no blanket stop. kill without --pid is a usage error.
run kill --dry-run > "$WORK/dry0" 2>&1; rc=$?
[ "$rc" -eq 2 ] && grep -q 'there is no blanket stop' "$WORK/dry0" \
    && pass "S3 kill without --pid is refused (no blanket stop)" || fail "S3 blanket kill: rc=$rc"
# S1: naming the subagent's root shell stops the whole tree, parents first,
# so a loop shell cannot start its next iteration.
run kill --dry-run --pid 110 > "$WORK/dry1" 2>&1
[ "$(grep '^would-signal' "$WORK/dry1" | cut -f3 | tr '\n' ' ')" = "110 111 " ] \
    && pass "S1 a named root shell takes its tree, parents first" || fail "S1 tree plan: $(plan "$WORK/dry1")"
# S2/S4/S6/S7: named own pids are targets.
run kill --dry-run --pid 120 --pid 140 --pid 160 --pid 170 > "$WORK/dry2" 2>&1
[ "$(grep '^would-signal' "$WORK/dry2" | cut -f3 | tr '\n' ' ')" = "120 140 160 170 121 122 141 " ] \
    && pass "S2/S4/S6/S7 named followers, stdin-blocked call, watcher and nohup watcher are targets" \
    || fail "S2/S4/S6/S7 plan: $(plan "$WORK/dry2")"
# S5/S7 on the one real Darwin table: no session descendant showed its id in
# `ps -E`. A detached watcher without that id is not listed, is counted
# foreign, and a named kill refuses it as not-listed.
awk -F '\t' 'BEGIN { OFS = "\t" } $1 == 170 { $5 = "-" } { print }' "$WORK/snap" > "$WORK/snap-noenv"
bash "$PS_SCRIPT" inventory --snapshot "$WORK/snap-noenv" --sessions-tsv "$WORK/sess" --session "$CUR" > "$WORK/inv-noenv" 2>&1
bash "$PS_SCRIPT" kill --dry-run --pid 170 --snapshot "$WORK/snap-noenv" --sessions-tsv "$WORK/sess" --session "$CUR" > "$WORK/dry-noenv" 2>&1
! awk -F '\t' '$3 == 170 && $1 != "summary"' "$WORK/inv-noenv" | grep -q . \
    && grep -q $'^summary\tsource=ps\t.*\tforeign=4$' "$WORK/inv-noenv" \
    && grep -q $'^refuse\t170\t-\tnot-listed$' "$WORK/dry-noenv" \
    && ! grep -q '^would-signal' "$WORK/dry-noenv" \
    && pass "S5/S7 a detached watcher without its id in the environment is foreign and refused not-listed" \
    || fail "S5/S7 no-env watcher: $(grep summary "$WORK/inv-noenv" | head -1) | $(cat "$WORK/dry-noenv")"
# S5/S7 under the argv-marker launch convention. No row below carries an id in
# the environment column, as on Darwin for a sandboxed process; the wrappers
# carry `docket-session=<uuid>` as the final argument of `sh -c`.
{
    printf '#self\t151\n#source\tps\n'
    row 1 0 1 "$L0N" - - /sbin/launchd
    row 50 1 50 "$L0N" - - -zsh
    row 100 50 100 "$L1" - - 2.1.322
    row 150 100 150 "$L1" - - "$SNAP 'bash proc_supervise.sh inventory'"
    row 151 150 150 "$L1" - - "bash proc_supervise.sh inventory"
    row 200 1 200 "$L2" - - 2.1.322
    # This session's detached gate run: the wrapper and its child.
    row 910 1 910 "$L1" - - "sh -c go test ./...; exit \$? docket-session=$CUR"
    row 911 910 910 "$L1" - - "go1.26.9 test -timeout 60m ./..."
    # Another session's detached job, under its marker.
    row 920 1 920 "$L2" - - "sh -c sleep 600; exit \$? docket-session=$SIB"
    row 921 920 920 "$L2" - - "sleep 600"
    # A detached job with no attribution evidence.
    row 930 1 930 "$L1" - - "bash /private/tmp/claude-501/watcher2.sh"
    # This session's id in the command text, but not as the final argument.
    row 940 1 940 "$L1" - - "sh -c echo docket-session=$CUR; sleep 9"
    # Guards. A wrapper around a nested `claude -p`, and the nested child.
    row 950 1 950 "$L1" - - "sh -c claude -p x; exit \$? docket-session=$CUR"
    row 951 950 950 "$L1" - - "claude -p x"
    row 952 951 952 "$L1" - - "make"
    # Nested wrappers whose markers disagree.
    row 960 1 960 "$L1" - - "sh -c sh -c inner; exit \$? docket-session=$CUR"
    row 961 960 960 "$L1" - - "sh -c sleep 5; exit \$? docket-session=$SIB"
    row 962 961 960 "$L1" - - "sleep 5"
    row 963 1 963 "$L1" - - "sh -c sh -c inner; exit \$? docket-session=$SIB"
    row 964 963 963 "$L1" - - "sh -c sleep 5; exit \$? docket-session=$CUR"
    row 965 964 963 "$L1" - - "sleep 5"
    # A marker as the final argument of a non-shell process.
    row 945 1 945 "$L1" - - "python3 -c pass docket-session=$CUR"
    # The current id in the environment under another session's marker.
    row 970 1 970 "$L1" "$CUR" - "sh -c make; exit \$? docket-session=$SIB"
    row 971 970 970 "$L1" "$CUR" - "make"
    # A current-session marker under another session's environment id.
    row 980 1 980 "$L2" "$SIB" - "bash job.sh"
    row 981 980 980 "$L2" - - "sh -c y; exit \$? docket-session=$CUR"
    row 982 981 980 "$L2" - - "sleep 1"
} > "$WORK/snap-mark"
mrun() { bash "$PS_SCRIPT" "$@" --snapshot "$WORK/snap-mark" --sessions-tsv "$WORK/sess" --session "$CUR"; }
mrun inventory > "$WORK/inv-mark" 2>&1
mrun kill --dry-run --pid 910 > "$WORK/dry-mark-own" 2>&1
mrun kill --dry-run --pid 920 --pid 921 > "$WORK/dry-mark-sib" 2>&1
mrun kill --dry-run --pid 930 --pid 940 > "$WORK/dry-mark-none" 2>&1
grep -q $'^own-detached\tstop\t910\t1\t'"$CUR"$'\targv-marker,registry-live\t' "$WORK/inv-mark" \
    && grep -q $'^own-detached\tstop\t911\t910\t'"$CUR"$'\targv-marker,registry-live\t' "$WORK/inv-mark" \
    && [ "$(grep '^would-signal' "$WORK/dry-mark-own" | cut -f3 | tr '\n' ' ')" = "910 911 " ] \
    && pass "S5/S7 argv marker: this session's detached wrapper and child without an env id are own-detached/stop, wrapper first" \
    || fail "S5/S7 argv marker own: $(grep -E '^(own|summary\tsource)' "$WORK/inv-mark" | tr '\n' ' ') | $(plan "$WORK/dry-mark-own")"
! awk -F '\t' '($3 == 920 || $3 == 921) && $1 != "summary"' "$WORK/inv-mark" | grep -q . \
    && grep -q $'^summary\tsource=ps\t.*\tforeign=13$' "$WORK/inv-mark" \
    && grep -q $'^refuse\t920\t-\tnot-listed$' "$WORK/dry-mark-sib" && grep -q $'^refuse\t921\t-\tnot-listed$' "$WORK/dry-mark-sib" \
    && ! grep -q '^would-signal' "$WORK/dry-mark-sib" \
    && pass "S5/S7 argv marker: another session's marked job is foreign and refused not-listed" \
    || fail "S5/S7 argv marker another session: $(grep -E '^(sibling|own-detached|summary\tsource)' "$WORK/inv-mark" | tr '\n' ' ') | $(plan "$WORK/dry-mark-sib")"
! awk -F '\t' '($3 == 930 || $3 == 940) && $1 != "summary"' "$WORK/inv-mark" | grep -q . \
    && grep -q $'^summary\tsource=ps\t.*\tforeign=13$' "$WORK/inv-mark" \
    && grep -q $'^refuse\t930\t-\tnot-listed$' "$WORK/dry-mark-none" && grep -q $'^refuse\t940\t-\tnot-listed$' "$WORK/dry-mark-none" \
    && ! grep -q '^would-signal' "$WORK/dry-mark-none" \
    && pass "S5/S7 argv marker: a detached job with no marker (or one not in final position) is foreign and refused not-listed" \
    || fail "S5/S7 argv marker none: $(grep -E '^(own-detached|summary\tsource)' "$WORK/inv-mark" | tr '\n' ' ') | $(plan "$WORK/dry-mark-none")"
mclass() { awk -F '\t' -v p="$1" '$3 == p && $1 != "summary" { print $1 "/" $2 }' "$WORK/inv-mark"; }
g=""
for e in 950:unknown/report 951:unknown/report 952: 960:own-detached/stop 961: 962: 963: 964: 965: 945: \
         970:unknown/report 971:unknown/report 980:sibling-detached/report 981: 982:; do
    [ "$(mclass "${e%%:*}")" = "${e#*:}" ] || g="$g ${e%%:*}=$(mclass "${e%%:*}")"
done
[ -z "$g" ] && pass "S5/S7 argv marker guards: a nested session, a marker disagreeing with one nearer the root or with an env id, and a non-shell marker never stop" \
    || fail "S5/S7 argv marker guards:$g"
printf '200\t%s\t%s\n' "$SIB" "$L2" > "$WORK/sess-mark-nocur"
bash "$PS_SCRIPT" inventory --snapshot "$WORK/snap-mark" --sessions-tsv "$WORK/sess-mark-nocur" --session "$CUR" > "$WORK/inv-mark-nocur" 2>&1
grep -q $'^unknown\treport\t910\t.*\targv-marker,registry-unusable\t' "$WORK/inv-mark-nocur" \
    && ! grep -q '^own-detached' "$WORK/inv-mark-nocur" \
    && pass "S5/S7 argv marker with an unusable registry is unknown, never a stop" \
    || fail "S5/S7 argv marker unusable registry: $(grep -E '^(own-detached|unknown)' "$WORK/inv-mark-nocur" | tr '\n' ' ')"
# The live Darwin reader: `ps -E` shows the wrapper's argv and no environment,
# and an unsandboxed process's environment. Only the latter fills the
# environment column; the marker stays argv.
mkdir -p "$WORK/mbin"
cat > "$WORK/mbin/ps" <<STUB
#!/bin/bash
case "\$*" in
    *-E*) printf '%s\n' "910 sh -c go test ./...; exit \\\$? docket-session=$CUR" "911 go test ./..." "990 bash job.sh CLAUDE_CODE_SESSION_ID=$SIB" ;;
    *) printf '%s\n' "    1     0     1 $L0N /sbin/launchd" "  100     1   100 $L1 2.1.322" \
           "  910     1   910 $L1 sh -c go test ./...; exit \\\$? docket-session=$CUR" "  911   910   910 $L1 go test ./..." "  990     1   990 $L2 bash job.sh" ;;
esac
STUB
printf '#!/bin/sh\nexit 0\n' > "$WORK/mbin/lsof"
printf '#!/bin/sh\necho Darwin\n' > "$WORK/mbin/uname"
chmod +x "$WORK/mbin/ps" "$WORK/mbin/lsof" "$WORK/mbin/uname"
PATH="$WORK/mbin:$PATH" bash "$PS_SCRIPT" snapshot > "$WORK/snap-mlive" 2>&1
bash "$PS_SCRIPT" inventory --snapshot "$WORK/snap-mlive" --sessions-tsv "$WORK/sess" --session "$CUR" > "$WORK/inv-mlive" 2>&1
awk -F "\t" -v s="$SIB" '$1 == 910 && $5 == "-" { a = 1 } $1 == 990 && $5 == s { b = 1 } END { exit !(a && b) }' "$WORK/snap-mlive" \
    && grep -q $'^own-detached\tstop\t910\t.*\targv-marker,registry-live\t' "$WORK/inv-mlive" \
    && grep -q $'^own-detached\tstop\t911\t.*\targv-marker,registry-live\t' "$WORK/inv-mlive" \
    && pass "S5/S7 live Darwin reader fills the environment column from env ids only, never from the argv marker" \
    || fail "S5/S7 live reader: $(tr '\n' ' ' < "$WORK/snap-mlive") | $(grep -v '^summary' "$WORK/inv-mlive" | tr '\n' ' ')"
# S8: a cleanup across sessions moves only this session's named shells.
run kill --dry-run --pid 111 --pid 211 --pid 220 > "$WORK/dry8" 2>&1
grep -q $'^would-signal\tTERM\t111\t' "$WORK/dry8" && ! grep -q $'^would-signal\tTERM\t2[12]' "$WORK/dry8" \
    && pass "S8 cleanup signals only this session's named shells" || fail "S8 cleanup plan: $(plan "$WORK/dry8")"

# ---- criterion 5: live sibling and unknown owner are reported, never signalled
expect_class 211 sibling/report "live sibling shell"
expect_class 220 sibling-detached/report "live sibling's detached process"
grep -q $'^refuse\t211\tsibling\tnot-a-target$' "$WORK/dry8" && grep -q $'^refuse\t220\tsibling-detached\tnot-a-target$' "$WORK/dry8" \
    && pass "named sibling pids are refused, visibly" || fail "sibling pids not refused: $(plan "$WORK/dry8")"
expect_class 500 unknown/report "unregistered claude -p carrying a dead id"
expect_class 501 unregistered/report "shell of an unregistered live session"
expect_class 602 unregistered/report "a nested claude -p's shell under an own shell is never own-shell"
expect_class 601 unknown/report "a nested claude -p session process"
expect_class 600 unknown/report "the own shell that launched a nested session"
expect_class 603 unknown/report "a nested session's child carrying the inherited id"
expect_class 604 unknown/report "a nested session's hook runner carrying the inherited id"
expect_class 801 unknown/report "a detached claude -p's child carrying the inherited id"
run kill --dry-run --pid 600 --pid 602 --pid 603 --pid 604 --pid 801 > "$WORK/nest" 2>&1
grep -q $'^dry-run\t0 target(s)' "$WORK/nest" && pass "naming a nested session's tree signals nothing" || fail "nested plan: $(plan "$WORK/nest")"
expect_class 196 own-service/report "a status-line sh -c without the shell-snapshot marker"
printf '200\t%s\t%s\n' "$SIB" "$L2" > "$WORK/sess-nocur"
bash "$PS_SCRIPT" kill --dry-run --snapshot "$WORK/snap" --sessions-tsv "$WORK/sess-nocur" --session "$CUR" --pid 170 --pid 320 > "$WORK/unk" 2>&1
grep -q $'^summary\tsource=ps\tsession=.*\tregistry=unusable' "$WORK/unk" \
    && [ "$(grep -c $'^unknown\treport\t' "$WORK/unk")" -ge 10 ] \
    && grep -q $'^refuse\t170\tunknown\tnot-a-target$' "$WORK/unk" && grep -q $'^dry-run\t0 target(s)' "$WORK/unk" \
    && pass "unusable registry: every owner is unknown, a named one is refused" || fail "unknown-owner fixture: $(plan "$WORK/unk")"
listed=""
for p in 1 50 100 150 151 152 200 400 700; do [ -z "$(class_of $p)" ] || listed="$listed $p"; done
[ -z "$listed" ] && pass "init, live session processes, the caller's chain and foreign processes are never listed" \
    || fail "listed:$listed"

# ---- unaudited capability: dead-owner is reported, never signalled -------------
expect_class 310 dead-owner/report "stale registry entry, orphaned"
expect_class 320 unknown/report "absent from registry, orphaned: death unproven"
expect_class 851 unknown/report "orphan of a live claude with a mismatched registry entry"
expect_class 410 dead-owner/report "registry pid reused by another process"
run kill --dry-run --pid 310 --pid 320 > "$WORK/dead" 2>&1
grep -q $'^refuse\t310\tdead-owner\tnot-a-target$' "$WORK/dead" && grep -q $'^dry-run\t0 target(s)' "$WORK/dead" \
    && pass "a dead-owner pid is refused" || fail "dead-owner plan: $(plan "$WORK/dead")"

# ---- criterion 3: determinism --------------------------------------------------
run inventory > "$WORK/inv2" 2>&1
run kill --dry-run --pid 110 > "$WORK/k1" 2>&1
run kill --dry-run --pid 110 > "$WORK/k2" 2>&1
cmp -s "$WORK/inv" "$WORK/inv2" && cmp -s "$WORK/k1" "$WORK/k2" \
    && pass "same table and sessions give byte-identical output" || fail "output differs between runs"
{ sed -n '1,2p' "$WORK/snap"; sed '1,2d' "$WORK/snap" | sort -r; } > "$WORK/snap-shuf"
bash "$PS_SCRIPT" inventory --snapshot "$WORK/snap-shuf" --sessions-tsv "$WORK/sess" --session "$CUR" > "$WORK/inv3" 2>&1
cmp -s "$WORK/inv" "$WORK/inv3" && pass "input row order does not change the output" || fail "output depends on input row order"

# ---- criterion 4: the kill gate --------------------------------------------------
jq -n --arg s "$CUR" '{session_id: $s, hook_event_name: "PreToolUse"}' > "$WORK/main.json"
jq -n --arg s "$CUR" '{session_id: $s, agent_id: "a123", agent_type: "executor-write"}' > "$WORK/agent.json"
bash "$PS_SCRIPT" kill --pid 111 > "$WORK/r0" 2>&1; rc=$?
[ "$rc" -eq 3 ] && grep -q 'refused: kill signals only from the docket-proc-guard hook' "$WORK/r0" \
    && pass "kill without a hook payload is refused (exit 3)" || fail "kill without payload: rc=$rc"
bash "$PS_SCRIPT" kill --pid 111 --payload "$WORK/agent.json" > "$WORK/r1" 2>&1; rc=$?
[ "$rc" -eq 3 ] && grep -q 'refused: caller is subagent a123; agents only inventory' "$WORK/r1" \
    && pass "a subagent (non-conductor) caller is refused (exit 3)" || fail "subagent kill: rc=$rc $(cat "$WORK/r1")"
run kill --pid 111 --payload "$WORK/main.json" > "$WORK/r2" 2>&1; rc=$?
[ "$rc" -eq 3 ] && grep -q 'refused: --snapshot --sessions-tsv --session: a real kill reads only the live table' "$WORK/r2" \
    && pass "a real kill refuses a caller-chosen table, registry or session (exit 3)" || fail "override kill: rc=$rc $(cat "$WORK/r2")"
run inventory --payload "$WORK/agent.json" > /dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "a subagent may inventory" || fail "subagent inventory: rc=$rc"

# ---- the live signal path ------------------------------------------------------
# A real kill reads `ps`, `lsof`, `uname` and ~/.claude/sessions; the stubs
# below are those, on PATH and HOME, describing a table whose own-shell tree
# holds a real `sleep` this suite started. The signal itself is real.
CUR_ENV=$CUR sleep 30 &
child=$!
disown "$child" 2>/dev/null
trap 'kill -9 "$child" 2>/dev/null; rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/home/.claude/sessions"
jq -n --arg s "$CUR" --arg l "$L1" '{pid: 100, sessionId: $s, procStart: $l}' > "$WORK/home/.claude/sessions/100.json"
jq -n --arg s "$SIB" --arg l "$L2" '{pid: 200, sessionId: $s, procStart: $l}' > "$WORK/home/.claude/sessions/200.json"
cat > "$WORK/bin/ps" <<STUB
#!/bin/bash
# Like ps, lstart is local time unless TZ=UTC; the registry records UTC.
if [ "\${TZ:-}" = UTC ]; then T1="$L1"; else T1="Tue Nov 10 00:00:00 2026"; fi
case "\$*" in
    *-E*) printf '%s\n' "120 /bin/zsh -c x CLAUDE_CODE_SESSION_ID=$CUR" "$child sleep 30 CLAUDE_CODE_SESSION_ID=$CUR" "211 go test CLAUDE_CODE_SESSION_ID=$SIB" ;;
    *"-p $child") echo " \$T1" ;;
    *"-p 121") echo " $L3" ;;
    *"-p "*) ;;
    *) printf '%s\n' "    1     0     1 $L0N /sbin/launchd" "  100     1   100 \$T1 2.1.322" \
           "  120   100   120 \$T1 /bin/zsh -c source /u/.claude/shell-snapshots/s.sh && eval 'sleep 30 | tail -f x'" \
           "  121   120   120 \$T1 tail -f x" "$child   120   120 \$T1 sleep 30" \
           "  200     1   200 $L2 2.1.322" "  211   200   211 $L2 /bin/zsh -c go test" ;;
esac
STUB
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/lsof"
printf '#!/bin/sh\necho Darwin\n' > "$WORK/bin/uname"
chmod +x "$WORK/bin/ps" "$WORK/bin/lsof" "$WORK/bin/uname"
HOME="$WORK/home" PATH="$WORK/bin:$PATH" bash "$PS_SCRIPT" kill --payload "$WORK/main.json" --pid 120 --pid 211 > "$WORK/live" 2>&1; rc=$?
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do kill -0 "$child" 2>/dev/null || break; sleep 0.1; done
if kill -0 "$child" 2>/dev/null; then alive=1; else alive=0; fi
[ "$rc" -eq 0 ] && grep -q $'^signal\tTERM\t'"$child"$'\town-shell$' "$WORK/live" && [ "$alive" -eq 0 ] \
    && pass "the conductor's payload signals the named shell's tree (child gone; ps read in UTC like the registry)" \
    || fail "live signal: rc=$rc alive=$alive $(grep -E '^(signal|skip|refuse)' "$WORK/live" | tr '\n' ' ')"
grep -q $'^skip\t121\town-shell\tstart-time-changed$' "$WORK/live" \
    && pass "a pid whose start time changed is skipped" || fail "reused pid not skipped: $(grep -E '^(signal|skip)' "$WORK/live" | tr '\n' ' ')"
grep -q $'^skip\t120\town-shell\tgone$' "$WORK/live" \
    && pass "a pid gone before its signal is skipped" || fail "gone pid not skipped"
grep -q $'^refuse\t211\tsibling\tnot-a-target$' "$WORK/live" && ! grep -q $'^signal\t.*\t211\t' "$WORK/live" \
    && pass "a live sibling's pid is never signalled" || fail "sibling pid in live kill"

# ---- criterion 6: Linux and the lsof fallback ------------------------------------
# procps prints lstart in the same five-word form. An orphan under a
# subreaper (systemd --user) rather than pid 1 is never dead-owner.
{
    printf '#self\t951\n#source\tps\n'
    row 1 0 1 "$L0N" - / /sbin/init
    row 900 1 900 "$L0N" - / "/usr/lib/systemd/systemd --user"
    row 100 900 100 "$L1" - /home/u 2.1.322
    row 950 100 950 "$L1" "$CUR" /home/u "/bin/bash -c source /home/u/.claude/shell-snapshots/snapshot-bash-1-a.sh && eval 'x'"
    row 951 950 950 "$L1" "$CUR" /home/u "bash proc_supervise.sh inventory"
    row 960 100 960 "$L1" "$CUR" /home/u "/bin/bash -c source /home/u/.claude/shell-snapshots/snapshot-bash-1-b.sh && eval 'go test ./...'"
    row 970 900 970 "$L0N" "$DEAD" /home/u "go test ./..."
    row 980 1 980 "$L0N" "$GONE" /home/u "cargo build"
} > "$WORK/snap-linux"
{ printf '100\t%s\t%s\n' "$CUR" "$L1"; printf '301\t%s\t%s\n' "$GONE" "$L0"; } > "$WORK/sess-linux"
bash "$PS_SCRIPT" inventory --snapshot "$WORK/snap-linux" --sessions-tsv "$WORK/sess-linux" --session "$CUR" > "$WORK/lin" 2>&1
grep -q $'^own-shell\tstop\t960\t' "$WORK/lin" && grep -q $'^unregistered\treport\t970\t' "$WORK/lin" \
    && grep -q $'^dead-owner\treport\t980\t' "$WORK/lin" \
    && pass "Linux table: bash shells own, subreaper orphan never dead-owner, init orphan reported" || fail "Linux fixture: $(tr '\n' ' ' < "$WORK/lin")"
{
    printf '#self\t151\n#source\tlsof\n'
    row 1 0 1 - - / launchd
    row 100 1 100 - - /w 2.1.322
    row 150 100 150 - - /w zsh
    row 151 150 150 - - /w bash
    row 120 100 120 - - /private/tmp/claude-501/STEP-77.d/wt zsh
    row 121 120 120 - - /private/tmp/claude-501/STEP-77.d/wt tail
    row 320 1 320 - - /w cargo
} > "$WORK/snap-lsof"
bash "$PS_SCRIPT" inventory --snapshot "$WORK/snap-lsof" --sessions-tsv "$WORK/sess" --session "$CUR" > "$WORK/lsof" 2>&1
grep -q $'^own-shell\tstop\t121\t.*step=STEP-77\t' "$WORK/lsof" && ! grep -q '^dead-owner' "$WORK/lsof" \
    && pass "lsof table: ancestry finds own shells, cwd names the step, nothing is dead-owner" || fail "lsof fixture: $(tr '\n' ' ' < "$WORK/lsof")"

# ---- the skill wiring -------------------------------------------------------------
SKILL_DIR="${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run"
grep -q 'references/proc-supervise.md' "$SKILL_DIR/SKILL.md" \
    && pass "SKILL.md points at the proc-supervise reference" || fail "SKILL.md lacks the proc-supervise pointer"
missing=""
for s in S1 S2 S3 S4 S5 S6 S7 S8; do grep -q "^| $s " "$SKILL_DIR/references/proc-supervise.md" 2>/dev/null || missing="$missing $s"; done
[ -z "$missing" ] && pass "the reference lists every audited scenario" || fail "reference lacks:$missing"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
