#!/bin/bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="${SCRIPT_DIR}/../src/user/task-completed-hook.sh"

PASS=0
FAIL=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

run_hook() {
    printf '%s' "$1" | bash "$HOOK"
}

assert_exit_zero() {
    if [ "$1" -eq 0 ]; then
        pass "$2"
    else
        fail "$2 (exit=$1)"
    fi
}

assert_valid_json() {
    if printf '%s' "$1" | jq -e . >/dev/null 2>&1; then
        pass "$2"
    else
        fail "$2 (stdout was not valid JSON: $1)"
    fi
}

assert_empty_object() {
    local normalized
    normalized=$(printf '%s' "$1" | jq -c . 2>/dev/null)
    if [ "$normalized" = "{}" ]; then
        pass "$2"
    else
        fail "$2 (expected {}, got: $1)"
    fi
}

assert_decision_block() {
    local decision
    decision=$(printf '%s' "$1" | jq -r '.decision // empty' 2>/dev/null)
    if [ "$decision" = "block" ]; then
        pass "$2"
    else
        fail "$2 (expected decision=block, got: $1)"
    fi
}

assert_reason_contains() {
    local reason
    reason=$(printf '%s' "$1" | jq -r '.reason // empty' 2>/dev/null)
    case "$reason" in
        *"$2"*) pass "$3" ;;
        *) fail "$3 (reason did not contain '$2': $reason)" ;;
    esac
}

FIXTURE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/taskcompletedhook.XXXXXX") || {
    printf 'FATAL: could not create fixture dir\n' >&2
    exit 2
}
trap 'rm -rf "$FIXTURE_DIR"' EXIT

# Writes the PARENT session transcript at ${FIXTURE_DIR}/<session>.jsonl.
write_parent() {
    local session="$1"
    shift
    printf '%s\n' "$@" > "${FIXTURE_DIR}/${session}.jsonl"
}

# Writes a teammate's meta.json + jsonl sidecar pair at
# ${FIXTURE_DIR}/<session>/subagents/agent-a<suffix>.{meta.json,jsonl}.
write_teammate() {
    local session="$1" suffix="$2" tname="$3"
    shift 3
    mkdir -p "${FIXTURE_DIR}/${session}/subagents"
    jq -n --arg n "$tname" '{name: $n}' > "${FIXTURE_DIR}/${session}/subagents/agent-a${suffix}.meta.json"
    printf '%s\n' "$@" > "${FIXTURE_DIR}/${session}/subagents/agent-a${suffix}.jsonl"
}

session_path() {
    printf '%s' "${FIXTURE_DIR}/$1.jsonl"
}

teammate_path() {
    printf '%s' "${FIXTURE_DIR}/$1/subagents/agent-a$2.jsonl"
}

CLAIM_LINE='{"message":{"content":[{"type":"tool_use","name":"TaskUpdate","input":{"taskId":"7","status":"in_progress"}}]}}'
OTHER_LINE='{"message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
SEND_TEAMLEAD_LINE='{"message":{"content":[{"type":"tool_use","name":"SendMessage","input":{"to":"team-lead","message":"done"}}]}}'
SEND_PEER_LINE='{"message":{"content":[{"type":"tool_use","name":"SendMessage","input":{"to":"peer","message":"hi"}}]}}'

# Deterministic, exactly-16-character id generator for filename-key fixtures
# (avoids manual character counting on repeated-char literals).
ID16() {
    printf '%016d' "$1"
}

# Writes a teammate's jsonl at a filename-key-resolvable path:
# ${FIXTURE_DIR}/<session>/subagents/agent-a<tname>-<id16>.jsonl
# No meta.json sidecar (birth-lag realism) unless paired with a separate
# meta.json write.
write_teammate_fnkey() {
    local session="$1" tname="$2" id16="$3"
    shift 3
    mkdir -p "${FIXTURE_DIR}/${session}/subagents"
    printf '%s\n' "$@" > "${FIXTURE_DIR}/${session}/subagents/agent-a${tname}-${id16}.jsonl"
}

fnkey_path() {
    printf '%s' "${FIXTURE_DIR}/$1/subagents/agent-a$2-$3.jsonl"
}

# Debug-channel test isolation: a separate fixture HOME so the toggle/log
# never touch the real ${HOME}/.claude/task-completed-hook.{debug,log}.
DEBUG_HOME="${FIXTURE_DIR}/debughome"
mkdir -p "${DEBUG_HOME}/.claude"

run_hook_debug() {
    printf '%s' "$1" | HOME="$DEBUG_HOME" bash "$HOOK"
}

enable_debug_toggle() {
    : > "${DEBUG_HOME}/.claude/task-completed-hook.debug"
}

debug_log_path() {
    printf '%s' "${DEBUG_HOME}/.claude/task-completed-hook.log"
}

clear_debug_log() {
    rm -f "$(debug_log_path)"
}

payload() {
    local transcript="$1" teammate="${2-impl-X}" task_id="${3-7}"
    jq -n --arg t "$transcript" --arg n "$teammate" --arg id "$task_id" \
        '{task_id: $id, teammate_name: $n, transcript_path: $t}'
}

case_row10_block_no_report() {
    write_parent "sess01" "$OTHER_LINE"
    write_teammate "sess01" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess01)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row10 block/no-report: exit 0"
    assert_valid_json "$out" "row10 block/no-report: valid JSON"
    assert_decision_block "$out" "row10 block/no-report: decision=block"
    assert_reason_contains "$out" "PREMATURE-COMPLETION-BLOCKED" "row10 block/no-report: reason has marker"
}

case_row8_allow_report_to_lead() {
    write_parent "sess02" "$OTHER_LINE"
    write_teammate "sess02" "w1" "impl-X" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess02)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row8 allow/report-to-lead: exit 0"
    assert_empty_object "$out" "row8 allow/report-to-lead: {}"
}

case_row8_allow_report_to_peer() {
    write_parent "sess03" "$OTHER_LINE"
    write_teammate "sess03" "w1" "impl-X" "$CLAIM_LINE" "$SEND_PEER_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess03)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row8 allow/report-to-peer (recipient-agnostic): exit 0"
    assert_empty_object "$out" "row8 allow/report-to-peer (recipient-agnostic): {}"
}

case_row9_allow_fallback_no_claim() {
    write_parent "sess04" "$OTHER_LINE"
    write_teammate "sess04" "w1" "impl-X" "$OTHER_LINE" "$SEND_PEER_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess04)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row9 allow/fallback no-claim-record: exit 0"
    assert_empty_object "$out" "row9 allow/fallback no-claim-record: {}"
}

case_row2_allow_empty_teammate_name() {
    write_parent "sess05" "$OTHER_LINE"
    write_teammate "sess05" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess05)" "" "7")"); rc=$?
    assert_exit_zero "$rc" "row2 allow/empty teammate_name: exit 0"
    assert_empty_object "$out" "row2 allow/empty teammate_name: {}"
}

case_row3_allow_team_lead_teammate_name() {
    write_parent "sess06" "$OTHER_LINE"
    write_teammate "sess06" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess06)" "team-lead" "7")"); rc=$?
    assert_exit_zero "$rc" "row3 allow/team-lead teammate_name: exit 0"
    assert_empty_object "$out" "row3 allow/team-lead teammate_name: {}"
}

case_row1_allow_malformed_payload() {
    local out rc
    out=$(printf 'not json at all' | bash "$HOOK"); rc=$?
    assert_exit_zero "$rc" "row1 allow/malformed payload: exit 0"
    assert_empty_object "$out" "row1 allow/malformed payload: {}"
}

case_row4_allow_empty_transcript_path() {
    local out rc
    out=$(run_hook "$(payload "" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row4 allow/empty transcript_path: exit 0"
    assert_empty_object "$out" "row4 allow/empty transcript_path: {}"
}


# case_row7_allow_shape_drift_canary (Revision 2) is SUPERSEDED by
# case_case21_canary_refinement's (a)-(c) arms per DKT-227 Phase 1d Revision
# 3 -- its array-content-with-unrecognized-item-types fixture now falls
# through to a block (the quiet-transcript violation class), not an allow.

case_row10_block_send_before_claim() {
    write_parent "sess10" "$OTHER_LINE"
    write_teammate "sess10" "w1" "impl-X" "$SEND_TEAMLEAD_LINE" "$CLAIM_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess10)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row10 block/ordering (send before claim): exit 0"
    assert_decision_block "$out" "row10 block/ordering (send before claim): decision=block"
}

case_case11_block_parent_evidence_ignored() {
    # Parent transcript alone contains a claim + a post-claim send (would ALLOW
    # if read directly, i.e. Revision 1's defect). The resolved teammate
    # transcript has a claim but no send. Overall verdict must be BLOCK,
    # proving the parent's misleading evidence is never consulted.
    write_parent "sess11" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    write_teammate "sess11" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess11)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "case11 block/parent-has-evidence teammate-lacks-it: exit 0"
    assert_decision_block "$out" "case11 block/parent-has-evidence teammate-lacks-it: decision=block"
}

case_case12_allow_teammate_evidence_used() {
    # Parent transcript alone has neither a claim nor a send (would BLOCK if
    # read directly). The resolved teammate transcript has a send with no
    # local claim record (the real pre-claim-then-spawn shape). Overall
    # verdict must be ALLOW, proving the teammate's own evidence is used.
    write_parent "sess12" "$OTHER_LINE"
    write_teammate "sess12" "w1" "impl-X" "$SEND_TEAMLEAD_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess12)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "case12 allow/parent-lacks-evidence teammate-has-it: exit 0"
    assert_empty_object "$out" "case12 allow/parent-lacks-evidence teammate-has-it: {}"
}

case_resolution_passthrough_both_directions() {
    # transcript_path already shaped as */subagents/agent-*.jsonl -- no parent
    # session file is written at all, proving pass-through never derives or
    # reads a session directory. Both arms: allow-worthy resolved evidence and
    # block-worthy resolved evidence must each pass through untouched.
    write_teammate "sess13a" "w1" "impl-X" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    write_teammate "sess13b" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"

    local out_a rc_a out_b rc_b
    out_a=$(run_hook "$(payload "$(teammate_path sess13a w1)" "impl-X" "7")"); rc_a=$?
    out_b=$(run_hook "$(payload "$(teammate_path sess13b w1)" "impl-X" "7")"); rc_b=$?

    assert_exit_zero "$rc_a" "resolution pass-through allow arm: exit 0"
    assert_empty_object "$out_a" "resolution pass-through allow arm: {}"

    assert_exit_zero "$rc_b" "resolution pass-through block arm: exit 0"
    assert_decision_block "$out_b" "resolution pass-through block arm: decision=block"
}

case_row5_allow_missing_session_dir() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/does-not-exist-session.jsonl" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row5 allow/missing session dir: exit 0"
    assert_empty_object "$out" "row5 allow/missing session dir: {}"
}

case_case15_mtime_select_newest_wins_both_directions() {
    # Two candidates share the exact-match name "impl-dup" (respawn reuse).
    # Force DISTINCT mtimes via touch -t (never write-order timing, which is
    # flaky at 1s filesystem granularity).
    #
    # Direction 1: the newer candidate HAS evidence, the older LACKS it ->
    # allow (newer selected, not older).
    write_parent "sess15a" "$OTHER_LINE"
    write_teammate "sess15a" "old" "impl-dup" "$CLAIM_LINE" "$OTHER_LINE"
    write_teammate "sess15a" "new" "impl-dup" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    touch -t 202001010000 "$(teammate_path sess15a old)"
    touch -t 202001020000 "$(teammate_path sess15a new)"

    # Direction 2 (inverse): the newer candidate LACKS evidence, the older
    # HAS it -> block (newer is still selected, proving selection follows
    # mtime rather than "whichever candidate happens to carry allow-worthy
    # evidence").
    write_parent "sess15b" "$OTHER_LINE"
    write_teammate "sess15b" "old" "impl-dup" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    write_teammate "sess15b" "new" "impl-dup" "$CLAIM_LINE" "$OTHER_LINE"
    touch -t 202001010000 "$(teammate_path sess15b old)"
    touch -t 202001020000 "$(teammate_path sess15b new)"

    local out_a rc_a out_b rc_b
    out_a=$(run_hook "$(payload "$(session_path sess15a)" "impl-dup" "7")"); rc_a=$?
    out_b=$(run_hook "$(payload "$(session_path sess15b)" "impl-dup" "7")"); rc_b=$?

    assert_exit_zero "$rc_a" "case15 mtime-select (newer has evidence): exit 0"
    assert_empty_object "$out_a" "case15 mtime-select (newer has evidence): allow, newer selected"

    assert_exit_zero "$rc_b" "case15 mtime-select (newer lacks evidence, inverse): exit 0"
    assert_decision_block "$out_b" "case15 mtime-select (newer lacks evidence, inverse): block, newer selected despite older having evidence"
}

case_case16a_allow_missing_sibling_jsonl() {
    write_parent "sess16a" "$OTHER_LINE"
    mkdir -p "${FIXTURE_DIR}/sess16a/subagents"
    jq -n --arg n "impl-X" '{name: $n}' > "${FIXTURE_DIR}/sess16a/subagents/agent-aw1.meta.json"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess16a)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "case16a allow/missing sibling jsonl: exit 0"
    assert_empty_object "$out" "case16a allow/missing sibling jsonl: {}"
}

case_case16b_allow_malformed_meta_json() {
    write_parent "sess16b" "$OTHER_LINE"
    mkdir -p "${FIXTURE_DIR}/sess16b/subagents"
    printf 'not valid json {{{' > "${FIXTURE_DIR}/sess16b/subagents/agent-aw1.meta.json"
    printf '%s\n' "$CLAIM_LINE" > "${FIXTURE_DIR}/sess16b/subagents/agent-aw1.jsonl"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess16b)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "case16b allow/malformed meta.json: exit 0"
    assert_empty_object "$out" "case16b allow/malformed meta.json: {}"
}

case_case16c_allow_zero_byte_meta_json() {
    write_parent "sess16c" "$OTHER_LINE"
    mkdir -p "${FIXTURE_DIR}/sess16c/subagents"
    : > "${FIXTURE_DIR}/sess16c/subagents/agent-aw1.meta.json"
    printf '%s\n' "$CLAIM_LINE" > "${FIXTURE_DIR}/sess16c/subagents/agent-aw1.jsonl"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess16c)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "case16c allow/zero-byte meta.json: exit 0"
    assert_empty_object "$out" "case16c allow/zero-byte meta.json: {}"
}

case_case16d_allow_meta_json_is_directory() {
    write_parent "sess16d" "$OTHER_LINE"
    mkdir -p "${FIXTURE_DIR}/sess16d/subagents/agent-aw1.meta.json"
    printf '%s\n' "$CLAIM_LINE" > "${FIXTURE_DIR}/sess16d/subagents/agent-aw1.jsonl"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess16d)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "case16d allow/meta.json is a directory: exit 0"
    assert_empty_object "$out" "case16d allow/meta.json is a directory: {}"
}

case_case16e_allow_meta_json_is_dangling_symlink() {
    write_parent "sess16e" "$OTHER_LINE"
    mkdir -p "${FIXTURE_DIR}/sess16e/subagents"
    ln -s "${FIXTURE_DIR}/sess16e/subagents/does-not-exist-target.json" \
        "${FIXTURE_DIR}/sess16e/subagents/agent-aw1.meta.json"
    printf '%s\n' "$CLAIM_LINE" > "${FIXTURE_DIR}/sess16e/subagents/agent-aw1.jsonl"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess16e)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "case16e allow/meta.json is a dangling symlink: exit 0"
    assert_empty_object "$out" "case16e allow/meta.json is a dangling symlink: {}"
}

case_row5_allow_subagents_dir_unreadable() {
    write_parent "sess17" "$OTHER_LINE"
    write_teammate "sess17" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"
    chmod 000 "${FIXTURE_DIR}/sess17/subagents"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess17)" "impl-X" "7")"); rc=$?
    chmod 755 "${FIXTURE_DIR}/sess17/subagents"

    assert_exit_zero "$rc" "row5 allow/subagents dir unreadable: exit 0"
    assert_empty_object "$out" "row5 allow/subagents dir unreadable: {}"
}

case_row5_allow_zero_exact_name_matches() {
    # Baseline: candidate exists but under a wholly different name.
    write_parent "sess18" "$OTHER_LINE"
    write_teammate "sess18" "w1" "other-teammate" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess18)" "impl-X" "7")"); rc=$?
    assert_exit_zero "$rc" "row5 allow/zero exact-name matches: exit 0"
    assert_empty_object "$out" "row5 allow/zero exact-name matches: {}"

    # Prefix-collision near-miss #1: payload teammate_name is a STRICT PREFIX
    # of the on-disk candidate's name (payload "impl-DKT-206-phase2" vs
    # on-disk "impl-DKT-206-phase2-fix-1" -- the real respawn-suffix-name
    # class DKT-222 was opened over). Must NOT match on prefix; exact
    # equality only.
    write_parent "sess18b" "$OTHER_LINE"
    write_teammate "sess18b" "w1" "impl-DKT-206-phase2-fix-1" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out_b rc_b
    out_b=$(run_hook "$(payload "$(session_path sess18b)" "impl-DKT-206-phase2" "7")"); rc_b=$?
    assert_exit_zero "$rc_b" "row5 allow/prefix-collision (payload is prefix of on-disk name): exit 0"
    assert_empty_object "$out_b" "row5 allow/prefix-collision (payload is prefix of on-disk name): {}"

    # Prefix-collision near-miss #2 (inverse): the on-disk candidate's name is
    # a STRICT PREFIX of the payload teammate_name.
    write_parent "sess18c" "$OTHER_LINE"
    write_teammate "sess18c" "w1" "impl-DKT-206-phase2" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out_c rc_c
    out_c=$(run_hook "$(payload "$(session_path sess18c)" "impl-DKT-206-phase2-fix-1" "7")"); rc_c=$?
    assert_exit_zero "$rc_c" "row5 allow/prefix-collision (on-disk name is prefix of payload): exit 0"
    assert_empty_object "$out_c" "row5 allow/prefix-collision (on-disk name is prefix of payload): {}"
}

case_row6_allow_resolved_transcript_unreadable() {
    write_parent "sess19" "$OTHER_LINE"
    write_teammate "sess19" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"
    chmod 000 "$(teammate_path sess19 w1)"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess19)" "impl-X" "7")"); rc=$?
    chmod 644 "$(teammate_path sess19 w1)"

    assert_exit_zero "$rc" "row6 allow/resolved transcript unreadable: exit 0"
    assert_empty_object "$out" "row6 allow/resolved transcript unreadable: {}"
}

case_row5_allow_no_strict_mtime_winner() {
    # Two exact-name candidates share an IDENTICAL forced mtime -- no strict
    # newest winner exists. Both carry block-worthy content (claim, no send)
    # so that an arbitrary (non-tie-aware) pick would still surface as a
    # false BLOCK, making this assertion falsify a broken tie-detector
    # regardless of directory-iteration order.
    write_parent "sess20" "$OTHER_LINE"
    write_teammate "sess20" "t1" "impl-dup2" "$CLAIM_LINE" "$OTHER_LINE"
    write_teammate "sess20" "t2" "impl-dup2" "$CLAIM_LINE" "$OTHER_LINE"
    touch -t 202001010000 "$(teammate_path sess20 t1)"
    touch -t 202001010000 "$(teammate_path sess20 t2)"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess20)" "impl-dup2" "7")"); rc=$?
    assert_exit_zero "$rc" "row5 allow/no strict mtime winner: exit 0"
    assert_empty_object "$out" "row5 allow/no strict mtime winner: {}"
}

case_cross_teammate_discrimination() {
    # Two DISTINCT-name candidate pairs coexist. The matching pair carries
    # block-worthy evidence; the non-matching pair carries the OPPOSITE
    # (allow-worthy) evidence. Assert the decision follows ONLY the exact
    # teammate_name match, in both directions, never the other candidate.
    write_parent "sess21" "$OTHER_LINE"
    write_teammate "sess21" "match" "impl-A" "$CLAIM_LINE" "$OTHER_LINE"
    write_teammate "sess21" "other" "impl-B" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out_a rc_a out_b rc_b
    out_a=$(run_hook "$(payload "$(session_path sess21)" "impl-A" "7")"); rc_a=$?
    out_b=$(run_hook "$(payload "$(session_path sess21)" "impl-B" "7")"); rc_b=$?

    assert_exit_zero "$rc_a" "cross-teammate discrimination (impl-A): exit 0"
    assert_decision_block "$out_a" "cross-teammate discrimination: impl-A resolves to its own (block-worthy) evidence, not impl-B's"

    assert_exit_zero "$rc_b" "cross-teammate discrimination (impl-B): exit 0"
    assert_empty_object "$out_b" "cross-teammate discrimination: impl-B resolves to its own (allow-worthy) evidence, not impl-A's"
}

case_injection_safety() {
    write_parent "sess22" "$OTHER_LINE"
    write_teammate "sess22" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"

    local sentinel out rc
    sentinel="${FIXTURE_DIR}/pwned"
    out=$(jq -n --arg t "$(session_path sess22)" --arg n "impl-X" \
        --arg subj "\$(touch ${sentinel})" \
        '{task_id: "7", teammate_name: $n, transcript_path: $t, task_subject: $subj, task_description: $subj}' \
        | bash "$HOOK"); rc=$?
    assert_exit_zero "$rc" "injection: exit 0"
    assert_valid_json "$out" "injection: valid JSON"
    assert_decision_block "$out" "injection: correct decision (block, unaffected by payload content)"
    if [ -e "$sentinel" ]; then
        fail "injection: sentinel file was created (payload was executed)"
        rm -f "$sentinel"
    else
        pass "injection: no side effect (sentinel file not created)"
    fi
}

case_case18_filename_key_production_shape() {
    # Real DKT-227 production shape: a SIBLING teammate's fully-born
    # meta+jsonl pair is present under a DIFFERENT name (must not interfere);
    # the COMPLETING teammate has jsonl only (no sidecar -- the birth-lag
    # window), properly patterned, resolvable via the primary filename key.
    # Discriminates a buggy "zero meta FILES in dir" trigger from correct
    # per-candidate matching. Both verdict arms.
    write_teammate "sess18d" "sib" "sibling-teammate" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    write_teammate_fnkey "sess18d" "impl-X" "$(ID16 1)" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    enable_debug_toggle
    clear_debug_log
    local out_a rc_a
    out_a=$(run_hook_debug "$(payload "$(session_path sess18d)" "impl-X" "7")"); rc_a=$?
    assert_exit_zero "$rc_a" "case18 filename-key production shape (allow arm): exit 0"
    assert_empty_object "$out_a" "case18 filename-key production shape (allow arm): {}"
    if grep -q 'key=filename' "$(debug_log_path)" 2>/dev/null; then
        pass "case18 filename-key production shape (allow arm): debug key=filename"
    else
        fail "case18 filename-key production shape (allow arm): debug key=filename (log: $(cat "$(debug_log_path)" 2>/dev/null))"
    fi

    write_teammate "sess18e" "sib" "sibling-teammate" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    write_teammate_fnkey "sess18e" "impl-X" "$(ID16 2)" "$CLAIM_LINE" "$OTHER_LINE"

    clear_debug_log
    local out_b rc_b
    out_b=$(run_hook_debug "$(payload "$(session_path sess18e)" "impl-X" "7")"); rc_b=$?
    assert_exit_zero "$rc_b" "case18 filename-key production shape (block arm): exit 0"
    assert_decision_block "$out_b" "case18 filename-key production shape (block arm): decision=block"
    if grep -q 'key=filename' "$(debug_log_path)" 2>/dev/null; then
        pass "case18 filename-key production shape (block arm): debug key=filename"
    else
        fail "case18 filename-key production shape (block arm): debug key=filename (log: $(cat "$(debug_log_path)" 2>/dev/null))"
    fi
}

case_case19_filename_key_exactness() {
    # Prefix-collision direction 1: on-disk filename-key candidate's derived
    # name has an extra suffix beyond the payload teammate_name -- must NOT
    # match on prefix; exact equality only. No meta fallback present, so a
    # near-miss falls all the way through to row5 (zero candidates).
    write_teammate_fnkey "sess19a" "impl-DKT-206-phase2-fix-1" "$(ID16 3)" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out_a rc_a
    out_a=$(run_hook "$(payload "$(session_path sess19a)" "impl-DKT-206-phase2" "7")"); rc_a=$?
    assert_exit_zero "$rc_a" "case19 filename-key prefix-collision (payload is prefix): exit 0"
    assert_empty_object "$out_a" "case19 filename-key prefix-collision (payload is prefix): {} (row5 fail-open, zero fn candidates)"

    # Prefix-collision direction 2 (inverse): on-disk derived name is a
    # strict prefix of the payload teammate_name.
    write_teammate_fnkey "sess19b" "impl-DKT-206-phase2" "$(ID16 4)" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out_b rc_b
    out_b=$(run_hook "$(payload "$(session_path sess19b)" "impl-DKT-206-phase2-fix-1" "7")"); rc_b=$?
    assert_exit_zero "$rc_b" "case19 filename-key prefix-collision (on-disk is prefix): exit 0"
    assert_empty_object "$out_b" "case19 filename-key prefix-collision (on-disk is prefix): {} (row5 fail-open, zero fn candidates)"

    # Filename without a 16-char tail segment -> skipped as malformed layout.
    write_teammate_fnkey "sess19c" "impl-X" "short" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out_c rc_c
    out_c=$(run_hook "$(payload "$(session_path sess19c)" "impl-X" "7")"); rc_c=$?
    assert_exit_zero "$rc_c" "case19 malformed filename (no 16-char tail): exit 0"
    assert_empty_object "$out_c" "case19 malformed filename (no 16-char tail): {} (row5 fail-open, skipped as malformed)"
}

case_case20_precedence_fallback() {
    # Part A: completing teammate's jsonl deliberately OFF-pattern (filename
    # key yields zero candidates); a valid matching meta.json + sibling jsonl
    # exists -> resolution falls back to and is attributed to the meta key.
    write_teammate "sess20a" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"

    enable_debug_toggle
    clear_debug_log
    local out_a rc_a
    out_a=$(run_hook_debug "$(payload "$(session_path sess20a)" "impl-X" "7")"); rc_a=$?
    assert_exit_zero "$rc_a" "case20 meta-key fallback (off-pattern filename): exit 0"
    assert_decision_block "$out_a" "case20 meta-key fallback (off-pattern filename): decision=block"
    if grep -q 'key=meta' "$(debug_log_path)" 2>/dev/null; then
        pass "case20 meta-key fallback: debug key=meta"
    else
        fail "case20 meta-key fallback: debug key=meta (log: $(cat "$(debug_log_path)" 2>/dev/null))"
    fi

    # Part B: respawn-trap regression. TWO same-name instances, both
    # filename-key compliant (jsonl exists from spawn for every instance).
    # OLD instance also carries a surviving same-base meta.json sidecar
    # (stale evidence); NEW instance is jsonl-only (birth-lag, no meta yet)
    # and actively newer. The filename key must resolve the NEW instance via
    # the newest-mtime tiebreak -- a meta-first algorithm would instead see
    # only OLD's meta (NEW's meta not yet born), MATCH_COUNT=1, and wrongly
    # pick OLD's stale evidence.
    write_teammate_fnkey "sess20b" "impl-dup3" "$(ID16 5)" "$CLAIM_LINE" "$OTHER_LINE"
    jq -n --arg n "impl-dup3" '{name: $n}' \
        > "${FIXTURE_DIR}/sess20b/subagents/agent-aimpl-dup3-$(ID16 5).meta.json"
    write_teammate_fnkey "sess20b" "impl-dup3" "$(ID16 6)" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    touch -t 202001010000 "$(fnkey_path sess20b impl-dup3 "$(ID16 5)")"
    touch -t 202001020000 "$(fnkey_path sess20b impl-dup3 "$(ID16 6)")"

    clear_debug_log
    local out_b rc_b
    out_b=$(run_hook_debug "$(payload "$(session_path sess20b)" "impl-dup3" "7")"); rc_b=$?
    assert_exit_zero "$rc_b" "case20 respawn-trap regression: exit 0"
    assert_empty_object "$out_b" "case20 respawn-trap regression: {} (new instance's allow-worthy evidence governs)"
    if grep -q 'key=filename' "$(debug_log_path)" 2>/dev/null; then
        pass "case20 respawn-trap regression: debug key=filename"
    else
        fail "case20 respawn-trap regression: debug key=filename (log: $(cat "$(debug_log_path)" 2>/dev/null))"
    fi
}

case_case21_canary_refinement() {
    # (a) Only user/attachment-shaped lines -- no assistant-envelope records
    # at all (array .message.content nowhere in the transcript) -> allow
    # (row 7).
    write_teammate_fnkey "sess21a" "impl-X" "$(ID16 7)" \
        '{"message":{"role":"user","content":"hi"}}' \
        '{"type":"attachment","path":"/tmp/foo"}'

    local out_a rc_a
    out_a=$(run_hook "$(payload "$(session_path sess21a)" "impl-X" "7")"); rc_a=$?
    assert_exit_zero "$rc_a" "case21a canary: user/attachment-only transcript: exit 0"
    assert_empty_object "$out_a" "case21a canary: user/attachment-only transcript: {} (row7 allow)"

    # (b) An assistant text/thinking line (array content, zero tool_use) and
    # no sends -> the quiet-transcript violation class: block via
    # fall-through, NOT a row7 allow (the flipped Revision-2 drift fixture
    # shape).
    write_teammate_fnkey "sess21b" "impl-X" "$(ID16 8)" \
        '{"message":{"content":[{"type":"text","text":"hello"}]}}'

    local out_b rc_b
    out_b=$(run_hook "$(payload "$(session_path sess21b)" "impl-X" "7")"); rc_b=$?
    assert_exit_zero "$rc_b" "case21b canary: quiet assistant-envelope transcript: exit 0"
    assert_decision_block "$out_b" "case21b canary: quiet assistant-envelope transcript: decision=block (fall-through, not row7)"

    # (c) Whole-file unparseable garbage -> allow (row 7).
    write_teammate_fnkey "sess21c" "impl-X" "$(ID16 9)" \
        'not json at all' \
        'more garbage {{{'

    local out_c rc_c
    out_c=$(run_hook "$(payload "$(session_path sess21c)" "impl-X" "7")"); rc_c=$?
    assert_exit_zero "$rc_c" "case21c canary: unparseable-garbage transcript: exit 0"
    assert_empty_object "$out_c" "case21c canary: unparseable-garbage transcript: {} (row7 allow)"
}

case_case22_debug_channel() {
    # Toggle present -> exactly one attributed debug line per invocation,
    # with correct row=/key=/decision= fields. One invocation each for
    # key=filename/row=8, key=meta/row=10, and row=5.
    enable_debug_toggle

    write_teammate_fnkey "sess22fn" "impl-X" "$(ID16 10)" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    clear_debug_log
    run_hook_debug "$(payload "$(session_path sess22fn)" "impl-X" "7")" >/dev/null
    local log_fn
    log_fn=$(cat "$(debug_log_path)" 2>/dev/null)
    if [ "$(printf '%s\n' "$log_fn" | grep -c .)" -eq 1 ] && \
       printf '%s' "$log_fn" | grep -q 'row=8' && \
       printf '%s' "$log_fn" | grep -q 'key=filename' && \
       printf '%s' "$log_fn" | grep -q 'decision=allow'; then
        pass "case22 debug: key=filename row=8 decision=allow, exactly one line"
    else
        fail "case22 debug: key=filename row=8 decision=allow, exactly one line (log: $log_fn)"
    fi

    write_teammate "sess22meta" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"
    clear_debug_log
    run_hook_debug "$(payload "$(session_path sess22meta)" "impl-X" "7")" >/dev/null
    local log_meta
    log_meta=$(cat "$(debug_log_path)" 2>/dev/null)
    if [ "$(printf '%s\n' "$log_meta" | grep -c .)" -eq 1 ] && \
       printf '%s' "$log_meta" | grep -q 'row=10' && \
       printf '%s' "$log_meta" | grep -q 'key=meta' && \
       printf '%s' "$log_meta" | grep -q 'decision=block'; then
        pass "case22 debug: key=meta row=10 decision=block, exactly one line"
    else
        fail "case22 debug: key=meta row=10 decision=block, exactly one line (log: $log_meta)"
    fi

    clear_debug_log
    run_hook_debug "$(payload "${FIXTURE_DIR}/does-not-exist-session-debug.jsonl" "impl-X" "7")" >/dev/null
    local log_r5
    log_r5=$(cat "$(debug_log_path)" 2>/dev/null)
    if [ "$(printf '%s\n' "$log_r5" | grep -c .)" -eq 1 ] && \
       printf '%s' "$log_r5" | grep -q 'row=5' && \
       printf '%s' "$log_r5" | grep -q 'decision=allow'; then
        pass "case22 debug: row=5 decision=allow, exactly one line"
    else
        fail "case22 debug: row=5 decision=allow, exactly one line (log: $log_r5)"
    fi

    # Toggle absent -> log file NOT created (zero writes).
    local nolog_home="${FIXTURE_DIR}/nologhome"
    mkdir -p "${nolog_home}/.claude"
    write_teammate "sess22nolog" "w1" "impl-X" "$CLAIM_LINE" "$OTHER_LINE"
    printf '%s' "$(payload "$(session_path sess22nolog)" "impl-X" "7")" \
        | HOME="$nolog_home" bash "$HOOK" >/dev/null
    if [ ! -e "${nolog_home}/.claude/task-completed-hook.log" ]; then
        pass "case22 debug: toggle absent, log file not created"
    else
        fail "case22 debug: toggle absent, log file not created (found: ${nolog_home}/.claude/task-completed-hook.log)"
    fi

    # Log path unwritable with toggle present -> decision unaffected, exit 0.
    local unwritable_home="${FIXTURE_DIR}/unwritablehome"
    mkdir -p "${unwritable_home}/.claude"
    : > "${unwritable_home}/.claude/task-completed-hook.debug"
    : > "${unwritable_home}/.claude/task-completed-hook.log"
    chmod 000 "${unwritable_home}/.claude/task-completed-hook.log"
    write_teammate "sess22unwritable" "w1" "impl-X" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    local out_uw rc_uw
    out_uw=$(printf '%s' "$(payload "$(session_path sess22unwritable)" "impl-X" "7")" \
        | HOME="$unwritable_home" bash "$HOOK"); rc_uw=$?
    chmod 644 "${unwritable_home}/.claude/task-completed-hook.log"
    assert_exit_zero "$rc_uw" "case22 debug: unwritable log path, exit 0"
    assert_empty_object "$out_uw" "case22 debug: unwritable log path, decision unaffected ({})"
}

case_case23_filename_key_tiebreaks() {
    # Direction 1: newer filename-key candidate HAS evidence, older LACKS it.
    write_teammate_fnkey "sess23a" "impl-dupfn" "$(ID16 11)" "$CLAIM_LINE" "$OTHER_LINE"
    write_teammate_fnkey "sess23a" "impl-dupfn" "$(ID16 12)" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    touch -t 202001010000 "$(fnkey_path sess23a impl-dupfn "$(ID16 11)")"
    touch -t 202001020000 "$(fnkey_path sess23a impl-dupfn "$(ID16 12)")"

    local out_a rc_a
    out_a=$(run_hook "$(payload "$(session_path sess23a)" "impl-dupfn" "7")"); rc_a=$?
    assert_exit_zero "$rc_a" "case23 filename-key tiebreak (newer has evidence): exit 0"
    assert_empty_object "$out_a" "case23 filename-key tiebreak (newer has evidence): allow, newer selected"

    # Direction 2 (inverse): newer LACKS evidence, older HAS it -> newer
    # still selected (block).
    write_teammate_fnkey "sess23b" "impl-dupfn" "$(ID16 13)" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
    write_teammate_fnkey "sess23b" "impl-dupfn" "$(ID16 14)" "$CLAIM_LINE" "$OTHER_LINE"
    touch -t 202001010000 "$(fnkey_path sess23b impl-dupfn "$(ID16 13)")"
    touch -t 202001020000 "$(fnkey_path sess23b impl-dupfn "$(ID16 14)")"

    local out_b rc_b
    out_b=$(run_hook "$(payload "$(session_path sess23b)" "impl-dupfn" "7")"); rc_b=$?
    assert_exit_zero "$rc_b" "case23 filename-key tiebreak (newer lacks evidence, inverse): exit 0"
    assert_decision_block "$out_b" "case23 filename-key tiebreak (newer lacks evidence, inverse): block, newer selected despite older having evidence"

    # Identical mtimes -> no strict newest winner -> allow (row 5).
    write_teammate_fnkey "sess23c" "impl-dupfn2" "$(ID16 15)" "$CLAIM_LINE" "$OTHER_LINE"
    write_teammate_fnkey "sess23c" "impl-dupfn2" "$(ID16 16)" "$CLAIM_LINE" "$OTHER_LINE"
    touch -t 202001010000 "$(fnkey_path sess23c impl-dupfn2 "$(ID16 15)")"
    touch -t 202001010000 "$(fnkey_path sess23c impl-dupfn2 "$(ID16 16)")"

    local out_c rc_c
    out_c=$(run_hook "$(payload "$(session_path sess23c)" "impl-dupfn2" "7")"); rc_c=$?
    assert_exit_zero "$rc_c" "case23 filename-key tiebreak (identical mtimes): exit 0"
    assert_empty_object "$out_c" "case23 filename-key tiebreak (identical mtimes): allow, row5 no strict winner"
}

case_case24_suffix_strip_exactness() {
    # A teammate name itself ENDING in "-" + 16 characters -> only the FINAL
    # (real id) segment strips; the derived name retains the name's own
    # 16-char tail and matches exactly.
    local id_tail id_real tname
    id_tail=$(ID16 19)
    id_real=$(ID16 20)
    tname="impl-X-${id_tail}"

    write_teammate_fnkey "sess24" "$tname" "$id_real" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"

    local out rc
    out=$(run_hook "$(payload "$(session_path sess24)" "$tname" "7")"); rc=$?
    assert_exit_zero "$rc" "case24 suffix-strip exactness: exit 0"
    assert_empty_object "$out" "case24 suffix-strip exactness: {} (derived name matches exactly, only trailing id stripped)"
}

case_strip_pattern_mechanical_length() {
    # AC-mandated mechanical check (not eyeballed): the filename key's
    # trailing-id strip pattern's wildcard run must be EXACTLY 16 '?'
    # characters -- a 17+ run would still contain "sixteen question marks"
    # as a substring and pass a plain grep -c check while being wrong.
    local match qrun qlen
    match=$(grep -o -- '%-[?]\+}' "$HOOK" | head -n1)
    qrun=$(printf '%s' "$match" | tr -dc '?')
    qlen=${#qrun}
    if [ -n "$match" ] && [ "$qlen" -eq 16 ]; then
        pass "strip-pattern mechanical length: wildcard run is exactly 16 '?' characters"
    else
        fail "strip-pattern mechanical length: expected 16 '?' characters, got $qlen (match: $match)"
    fi
}

if [ ! -f "$HOOK" ]; then
    printf 'FATAL: hook not found at %s\n' "$HOOK" >&2
    exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'FATAL: jq is required to run this test\n' >&2
    exit 2
fi

case_row10_block_no_report
case_row8_allow_report_to_lead
case_row8_allow_report_to_peer
case_row9_allow_fallback_no_claim
case_row2_allow_empty_teammate_name
case_row3_allow_team_lead_teammate_name
case_row1_allow_malformed_payload
case_row4_allow_empty_transcript_path
case_row10_block_send_before_claim
case_case11_block_parent_evidence_ignored
case_case12_allow_teammate_evidence_used
case_resolution_passthrough_both_directions
case_row5_allow_missing_session_dir
case_case15_mtime_select_newest_wins_both_directions
case_case16a_allow_missing_sibling_jsonl
case_case16b_allow_malformed_meta_json
case_case16c_allow_zero_byte_meta_json
case_case16d_allow_meta_json_is_directory
case_case16e_allow_meta_json_is_dangling_symlink
case_row5_allow_subagents_dir_unreadable
case_row5_allow_zero_exact_name_matches
case_row6_allow_resolved_transcript_unreadable
case_row5_allow_no_strict_mtime_winner
case_cross_teammate_discrimination
case_injection_safety
case_case18_filename_key_production_shape
case_case19_filename_key_exactness
case_case20_precedence_fallback
case_case21_canary_refinement
case_case22_debug_channel
case_case23_filename_key_tiebreaks
case_case24_suffix_strip_exactness
case_strip_pattern_mechanical_length

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
