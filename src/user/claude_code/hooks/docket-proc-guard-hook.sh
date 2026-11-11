#!/bin/bash

# proc-guard — PreToolUse: Bash. Runs the docket-run conductor's process
# inventory, dry run and kill outside the Bash sandbox, and refuses the kill
# to everyone else.
#
# WHY A HOOK. Inside the Bash sandbox `ps`, `pgrep` and every signal to a
# process outside the call are refused, even `kill -0` to this session's own
# background shell. So a conductor cannot stop an Agent subagent's runaway
# test loops. The operator once had to run `! pkill` by hand while fan noise
# and a load of 6.7 went on. A detached job (`nohup`, setsid) outside task
# tracking is attributed by its session id in the `ps -E` environment or,
# where the sandbox hides the environment (Darwin), by the `docket-session=`
# argv marker launch convention in
# skills/docket-run/references/proc-supervise.md. The marker is read only
# from this hook's `ps` table; a job with neither stays foreign and
# `kill --pid` refuses it. A hook runs outside the
# sandbox, so this hook is the one place where
# skills/docket-run/scripts/proc_supervise.sh reads the full `ps` table and
# can signal. The operator chose this event, matcher and action (PreToolUse,
# Bash, kill), limited it to docket conductors, and widened it to the
# conductor's inventory and dry run.
#
# THE TRIGGER, exact and nothing else. The whole command must be one simple
# call, one of
#     [bash ]<SCRIPT> inventory
#     [bash ]<SCRIPT> kill [--dry-run] (--pid N | --signal TERM|INT|HUP|KILL)...
# with at least one --pid for kill. <SCRIPT> is
# ~/.claude/skills/docket-run/scripts/proc_supervise.sh, spelled with `~`,
# `$HOME` or the literal home directory. The command may hold only letters,
# digits, spaces and `_ . / ~ $ -`. A chain, pipe, redirect, quote,
# substitution, newline, an extra flag, a copied script path, or a `grep` or
# `echo` that only names the script is not the trigger. This hook takes no
# action on any of them, and the call runs in the sandbox, where no signal
# escapes. This hook therefore leans toward no action, where the deny guards
# lean toward deny.
#
# BY CALLER:
#   subagent (payload carries agent_id)  a command that names the script with
#                                        `kill` and without `--dry-run` is
#                                        denied (exit 2): agents only
#                                        inventory. The match is textual; the
#                                        sandbox, which refuses every signal,
#                                        is the barrier for other spellings.
#                                        Anything else runs in the sandbox.
#   main conversation, not a conductor   an exact kill is denied (exit 2);
#                                        inventory and dry run run in the
#                                        sandbox.
#   docket conductor                     on an exact trigger the hook runs the
#                                        script itself, unsandboxed, with only
#                                        the parsed words: `inventory
#                                        --session <payload session_id>`,
#                                        `kill --dry-run --session <id>
#                                        <words>`, or `kill --payload <this
#                                        payload> <words>`. The sandboxed call
#                                        is then denied (exit 2) with the
#                                        script's output as the reason,
#                                        because it would only see less or
#                                        fail. The inventory and dry run
#                                        return the full table, sibling
#                                        sessions' argv included.
#
# A CONDUCTOR is a session whose scratchpad
# (/tmp/claude-<uid>/<project>/<session_id>/scratchpad) holds a non-empty
# conductor.d/RUN-<digits>.token, the file docket-run writes on activation
# and removes when the run ends. It is a filesystem test, not an engine
# check: a subagent shares the session's scratchpad and could write the file,
# and a crashed run can leave a token behind. What bounds it: the script's
# kill signals only this session's own shells, and a subagent's kill is
# denied above, so a session that passes can stop only shells it already
# owns. The glob covers /private/tmp and /tmp; a scratchpad under another base
# (CLAUDE_CODE_TMPDIR) is not found, and the check fails closed. The token must
# be owned by this user (`-O`), since /tmp/claude-* spans users.
#
# PreToolUse hooks run side by side and before the permission layer, so the
# script has run whatever another hook or the permission mode decides; they
# bind only the sandboxed call, which this hook denies.
# The deny text never begins "Permission", so docket-denied-reissue-guard does
# not read it as a permission denial.
#
# DOCKET_PROC_GUARD_SCRIPT overrides <SCRIPT> and DOCKET_PROC_GUARD_TOKEN_GLOB
# the token glob, for the suite. A hook's
# environment is the harness's, which no Bash call can set.
#
# Exit 0 allow; exit 2 deny, reason on stderr.

set -u

SCRIPT_PATH=${DOCKET_PROC_GUARD_SCRIPT:-$HOME/.claude/skills/docket-run/scripts/proc_supervise.sh}
REL=.claude/skills/docket-run/scripts/proc_supervise.sh

command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat)
[ "$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)" = Bash ] || exit 0
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
case "$CMD" in *proc_supervise.sh*) ;; *) exit 0 ;; esac
AGENT=$(printf '%s' "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null)

deny() { printf 'docket-proc-guard: %s\n' "$1" >&2; exit 2; }

# A subagent: a real kill in any spelling the match sees is denied.
if [ -n "$AGENT" ]; then
    if printf '%s' "$CMD" | grep -qE 'proc_supervise\.sh.*[^A-Za-z-]kill([^A-Za-z-]|$)' \
        && ! printf '%s' "$CMD" | grep -q -- '--dry-run'; then
        deny "refused: subagent $AGENT may only inventory (proc_supervise.sh inventory, or kill --dry-run). Report the pids to the conductor, which stops them."
    fi
    exit 0
fi

# The exact grammar.
LC_ALL=C
case "$CMD" in *[!A-Za-z0-9_./~\$\ -]*) exit 0 ;; esac
set -f
# shellcheck disable=SC2206
WORDS=($CMD)
set +f
i=0
[ "${WORDS[0]:-}" = bash ] && i=1
case "${WORDS[$i]:-}" in
    "~/$REL" | "\$HOME/$REL" | "$HOME/$REL") ;;
    *) exit 0 ;;
esac
i=$((i + 1))
OP=${WORDS[$i]:-}
i=$((i + 1))
ARGS=()
NPID=0
DRY=0
case "$OP" in
    inventory) [ "$i" -eq "${#WORDS[@]}" ] || exit 0 ;;
    kill)
        while [ "$i" -lt "${#WORDS[@]}" ]; do
            flag=${WORDS[$i]}
            if [ "$flag" = --dry-run ]; then
                [ "$DRY" -eq 0 ] || exit 0
                DRY=1; i=$((i + 1)); continue
            fi
            val=${WORDS[$((i + 1))]:-}
            case "$flag" in
                --pid) case "$val" in ''|*[!0-9]*) exit 0 ;; esac; NPID=$((NPID + 1)) ;;
                --signal) case "$val" in TERM|INT|HUP|KILL) ;; *) exit 0 ;; esac ;;
                *) exit 0 ;;
            esac
            ARGS+=("$flag" "$val")
            i=$((i + 2))
        done
        [ "$NPID" -gt 0 ] || exit 0
        [ "$DRY" -eq 1 ] && OP=dry-run
        ;;
    *) exit 0 ;;
esac

# A docket conductor: the session's scratchpad holds a run's conductor token,
# a non-empty regular file conductor.d/RUN-<digits>.token. The glob is
# unquoted on purpose; DOCKET_PROC_GUARD_TOKEN_GLOB (with @SESSION@) points it
# at a fixture for the suite.
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
conductor=0
case "$SID" in
    '' | *[!A-Za-z0-9-]*) ;;
    *)
        TOKEN_GLOB=${DOCKET_PROC_GUARD_TOKEN_GLOB:-/private/tmp/claude-*/*/@SESSION@/scratchpad/conductor.d/RUN-*.token /tmp/claude-*/*/@SESSION@/scratchpad/conductor.d/RUN-*.token}
        TOKEN_GLOB=${TOKEN_GLOB//@SESSION@/$SID}
        # shellcheck disable=SC2086
        for t in $TOKEN_GLOB; do
            n=${t##*/RUN-}; n=${n%.token}
            case "$n" in '' | *[!0-9]*) continue ;; esac
            [ -f "$t" ] && [ ! -L "$t" ] && [ -s "$t" ] && [ -O "$t" ] && { conductor=1; break; }
        done
        ;;
esac
if [ "$conductor" -ne 1 ]; then
    [ "$OP" = kill ] || exit 0
    deny "refused: proc_supervise.sh kill runs only from a docket conductor's main conversation (a session whose scratchpad holds a run's conductor.d token). Inventory and kill --dry-run stay open in the sandbox; stop your own shells with TaskStop."
fi

[ -r "$SCRIPT_PATH" ] || deny "the $OP was not run: $SCRIPT_PATH is missing."
WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-proc-guard.XXXXXX") || deny "the $OP was not run: mktemp failed."
trap 'rm -rf "$WORK"' EXIT
SESS=()
[ -n "$SID" ] && SESS=(--session "$SID")
rc=0
case "$OP" in
    inventory) bash "$SCRIPT_PATH" inventory ${SESS[@]+"${SESS[@]}"} > "$WORK/out" 2> "$WORK/err" || rc=$? ;;
    dry-run) bash "$SCRIPT_PATH" kill --dry-run ${SESS[@]+"${SESS[@]}"} "${ARGS[@]}" > "$WORK/out" 2> "$WORK/err" || rc=$? ;;
    kill)
        printf '%s' "$INPUT" > "$WORK/payload.json"
        bash "$SCRIPT_PATH" kill --payload "$WORK/payload.json" "${ARGS[@]}" > "$WORK/out" 2> "$WORK/err" || rc=$?
        ;;
esac
{
    printf 'docket-proc-guard ran this %s outside the Bash sandbox (the operator-approved hook action), so the sandboxed call is not run. Script exit %s.\n' "$OP" "$rc"
    if [ "$OP" = kill ]; then grep -E '^(refuse|signal|skip)	' "$WORK/out"; else cat "$WORK/out"; fi
    cat "$WORK/err"
} >&2
exit 2
