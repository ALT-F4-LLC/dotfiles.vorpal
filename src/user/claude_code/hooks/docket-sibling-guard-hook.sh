#!/bin/bash

# sibling-guard — PreToolUse: Bash.
#
# Every executor in a wave shares one scratch root, one repository object
# store, one process table and one operating-system user with every sibling
# executor running beside it. The sandbox confines none of that: a sibling's
# `<TMP>/STEP-N.d` is as writable as the caller's own, `git worktree remove`
# reaches any checkout, `pkill` reaches any process, `docket step reap` clears
# any claim. The permission layer clears these verbs outright for everyone —
# the auto-mode allow text names worktree verbs and scratch-root `rm -rf` as
# routine — so before this hook nothing keyed an executor's destructive verb
# to the step it holds. An executor never perceives its siblings (no Agent
# tool, no channel), so the motive is absent by design; this guard is ranked
# on blast radius, not on likelihood: one confused step id in an `rm -rf`, or
# one `pkill` aimed at a port a sibling's test server holds, takes a
# stranger's step down with no record of who did it.
#
# THE RULE, one sentence: a target belongs to the caller when it names the
# caller's own step, and nothing else is the caller's to destroy. The step id
# is the one fact the hook can establish — a wave executor's rendered brief is
# its transcript's first message and carries `docket step claim STEP-N --owner
# wave:STEP-N:...` — and it is what makes `<TMP>/STEP-N.d` that executor's
# own. From it, five clauses:
#
#   SCRATCH    any word naming another step's scratch directory, whatever the
#              verb: `STEP-M.d` with M not the caller's step; a glob, brace
#              or expansion (`STEP-*.d`, `STEP-{7,8}.d`, `STEP-$n.d`,
#              `STEP-$((6+1)).d`) where the id should be, since a literal own
#              id is never spelled that way; a glob standing for the `.d`
#              (`STEP-7.[d]`, `STEP-7*`); the caller's own dir followed by a
#              `..` component; and a `find` that negates the own name
#              (`! -name STEP-N.d`) to reach everything else. Not only `rm
#              -rf`: a redirect into a sibling's token file, `mv`, `find
#              -delete`, `chmod`, or a variable assignment that a later `rm
#              $d` in the same call consumes all name the dir, and an executor
#              has no reading business there either (a sibling's dir is mode
#              0700 and the brief says never to reach for it). A verb list
#              would have to be complete; the name is one token and is only
#              ever a scratch dir. One admission: a `docket` argument that is
#              a whole expansion-form step id (`STEP-$s`, `STEP-${s}`, no
#              `.d`, glob or `/` after it, not a redirect target, and in a
#              leaf carrying no `$( )`, backtick, `<( )` or `${ }`
#              substitution) names a step to the engine, not a directory, so
#              a read loop over sibling ids passes; every `.d` and path form
#              stays a token. A second admission: inside the caller's own
#              dir, a file named for the own id, a `-`, then plain text that
#              may carry `$name` or `${name}` (`<TMP>/STEP-N.d/STEP-N-$i.json`)
#              is the caller's own file; any other character right after the
#              own digits, a substitution, or the same name outside the own
#              dir stays a token.
#   WORKTREE   `git worktree prune` always (it drops the bookkeeping of every
#              checkout momentarily absent, siblings still working included);
#              `git worktree remove`/`move` unless every path operand lies
#              inside the caller's own scratch dir (a throwaway probe checkout
#              the executor made itself); `git -c alias.<x>=...` (an alias
#              can spell any of these); and `rm`/`rmdir`/`mv` of, or an
#              output redirection into, a path under `.claude/worktrees/` or
#              `.git/worktrees/` that is not the caller's own checkout, the
#              checkout being its `cwd` (`cat /dev/null > <sibling>/.git`
#              breaks that checkout as surely as removing it). The
#              harness creates a writer's worktree and the conductor sweeps
#              it after integration, so no other checkout is an executor's.
#              A judge READS a sibling writer's target checkout by design, so
#              the path rule binds destructive heads only.
#   BRANCH     `git branch -d/-D/--delete`, `git update-ref -d`, `git
#              symbolic-ref -d`, and `git push --delete` or `push <remote>
#              :<ref>` unless the ref name carries the caller's own step id.
#              A writer's hand-back is a commit sha on its own worktree
#              branch; no branch is an executor's to delete, and publishing
#              is the operator's alone.
#   PROCESS    `pkill`, `killall` and `killall5` always: they address
#              processes by name across the whole machine. `kill` with a
#              literal numeric pid (`1234`, `-1234`, `+1234` after a signal,
#              `0`, `$((...))`, `$(echo 1234)`): shell state does not survive
#              between an executor's Bash calls, so a literal pid can only
#              have been copied from a process listing, which is exactly the
#              shape of taking a sibling down. `kill` on a jobspec (`%1`) or
#              an expansion (`$!`, `$pid`, `$(cat own.pid)`) is the caller's
#              own call ending what it started, and stays allowed — unless
#              the same command also runs a process lookup (`ps`, `pgrep`,
#              `pidof`, `lsof`, `fuser`, `ss`, `netstat`, `top`), in which
#              case the expansion is that lookup's result and the kill is
#              denied. `kill -l` and signal 0 deliver nothing and are never
#              denied. The verb is read at the head of the leaf, after
#              `sudo`, `env`, `command`, `xargs`, `nohup`, `timeout` and the
#              like are stripped: `grep -rn pkill hooks/` is a read a judge of
#              this very repository makes, and stays allowed. After zsh
#              `repeat` every later word is read as a verb for the
#              name-addressed kills and ENGINE, since the pre-pass cannot
#              show where its count ends, so `repeat 3 echo pkill` denies.
#   ENGINE     `docket step reap` and `docket run conduct` always, docket's
#              own global flags skipped. A reap clears another holder's
#              claim on the assertion that the holder is dead, which only
#              the relay that spawned it can observe; an executor cannot
#              observe a sibling at all, and a reap from one returns a live
#              step to the pool under a stranger. The engine binds reap,
#              with approve, reject, resolve and run pause/resume/abandon,
#              to the run's conductor capability and refuses them itself;
#              `run conduct` is the deliberately token-free re-mint of that
#              capability (a run whose conductor died must stay
#              recoverable), so an executor running it would retire the
#              conductor's token and lock it out of its own rulings. The
#              lease-bound verbs (`record`, `fail`, `heartbeat`) reach only
#              the caller's own step and need no clause.
#
# THE SCOPE, mirroring docket-trust-guard-hook.sh and
# sandbox-bypass-guard-hook.sh: the three graph-fleet executor archetypes
# (agents/executor-{read,write,research}.md), identified by `agent_type`
# first. When `agent_type` is absent (the Workflow-spawned-seat shape the
# sandbox-bypass guard measured), the transcript's own opening is read for
# the wave executor brief marker above; nothing else puts a caller in scope.
#
# WHICH TRANSCRIPT. Inside a subagent the harness's `transcript_path` names
# the PARENT conversation's file, not the seat's own: measured 2026-09-15 on
# Claude Code 2.1.272, where 25 denials in one wave logged `own_mode: none`
# while every executor's own `agent-<id>.jsonl` carried the marker 1.3 KiB
# in, and this scan run by hand over those files found it. When the payload
# carries `agent_id`, the seat's own transcript is resolved from it
# (`<session dir>/subagents/agent-<id>.jsonl` for an Agent-tool seat,
# `<session dir>/subagents/workflows/*/agent-<id>.jsonl` for a Workflow
# seat; the session dir is `transcript_path` minus `.jsonl`, else
# `<dirname>/<session_id>`), and ONLY that file is read. A seat whose own
# transcript cannot be located, or is still empty because the harness writes
# it asynchronously, is `unknown`, never `none`: `none` is a verdict about
# the caller's own opening and says nothing about a stranger's file.
# An identified non-executor seat (a `docket-conductor-RUN-N` sweeping a dead
# executor's dir, a groomer, `general-purpose`) and the main conversation are
# out of scope, on purpose: the conductor's sweep and the operator's own
# terminal are the sanctioned paths to a stranger's scratch dir, and a deny
# here would block exactly them. The transcript marker is the full wave
# spelling — a literal step id, `--owner wave:`, and the same id after it —
# because a looser marker (`docket step claim`, `docket vote cast`) appears
# in skill text a session's first message can carry, and this hook denies
# ordinary `rm`, not a sandbox lift, so a false catch on the operator's own
# session is not a mild error.
#
# THREE OWN-STEP STATES, each pinned in tests/docket-sibling-guard-hook.test.sh:
#   known    the marker was found: `<TMP>/STEP-N.d` is the caller's.
#   none     the transcript was read and carries no marker: an executor
#            archetype that holds no step (a tribunal seat, a worker spawned
#            for an ordinary issue) has no scratch dir of its own, so every
#            `STEP-M.d`, worktree and branch is a stranger's.
#   unknown  no readable, non-empty own transcript (none named, unreadable,
#            still empty, or an `agent_id` whose file is not under the
#            session directory): the SCRATCH, WORKTREE-path and BRANCH
#            clauses are skipped and the call is allowed, logged to
#            ~/.claude/friction so the shape gets confirmed, because denying
#            here would strand every bootstrap `rm -rf` of a real executor
#            behind a transcript-delivery gap — this hook family's direction
#            when the caller or target cannot be identified. `pkill`,
#            `killall`, `git worktree prune`, `kill <literal pid>`, `docket
#            step reap` and `docket run conduct` need no own id and still
#            deny.
#
# Exit 0 allow / exit 2 deny with reason on stderr, this hook family's
# contract: exit 2 is a pre-permission hard stop the classifier never sees,
# honored regardless of permission mode, and the reason reaches the executor
# so it reports the collision as a finding instead of retrying under another
# spelling.
#
# HOW THE COMMAND IS READ: the same two stages as docket-trust-guard-hook.sh
# and docket-commit-guard-hook.sh, whose headers carry the full reasoning.
# Between them, line selection differs: those guards keep the first line of
# each leaf, while this one keeps every line except heredoc bodies (see
# LEAF_LINES_AWK), since a substitution body that spans lines reaches the
# probe only inside its outer leaf. Stage one asks bash itself which simple
# commands it would dispatch (a DEBUG trap under `extdebug` and `set -T`
# that vetoes every leaf), so chains, subshells, substitutions, heredocs
# and comments are bash's parse and not a re-derivation of it; stage two
# is the shared quote-group pre-pass (docket-guard-prepass.awk) that tells
# a quoted prose span from separately-quoted words and unmarks an
# interpreter's code argument (`bash -c '...'`) so the words inside it are
# read as the invocation they are. A word inside a quoted group of two or
# more words is prose here; a lone quoted path (`rm -rf "<TMP>/STEP-7.d"`)
# is not; and when any leaf is headed by an interpreter, no quoted group is
# prose at all — `echo "rm -rf ..." | sh` and `sh <<< "rm -rf ..."` carry
# code in a string exactly as a heredoc does, and the pre-pass's heredoc
# rule is applied to strings for the same reason.
#
# THE PROBE HARDENING, measured on bash 3.2 and pinned in the suite. This
# probe is shared with docket-trust-guard-hook.sh and
# docket-commit-guard-hook.sh, which originally ran an unhardened copy;
# the hardening this hook introduced is ported into both, except the `read`
# admission below, which only this hook carries:
#   - The probe shell is RESTRICTED (`set -r`) once the trap is armed, so no
#     redirection can open a file. A vetoed leaf never performs its
#     redirection anyway (verified: `rm x > marker` leaves the marker
#     intact and the leaf text, `> marker` included, reaches the matcher);
#     but a redirection on a STRUCTURAL builtin (`: > f`, `true > f`, `[ ]
#     > f`) or on a COMPOUND command (`{ ...; } > f`, `( ... ) > f`, a loop
#     or `if` with a trailing `> f`) was performed for real by the unhardened
#     probe, truncating the target before any verdict — and never reached
#     the matcher, since a compound redirect appears in no BASH_COMMAND.
#     Now a structural leaf carrying `<` or `>` ends the probe with a
#     refusal marker and a distinct exit code, a compound redirect fails under the restriction
#     and its error text is read back, and both DENY as uninspectable, with
#     a reason naming the plain-command spelling.
#   - `readonly -f` on the handler: a function definition is a compound
#     command the trap never sees, so `_guard_probe() { return 0; }; ...`
#     silently disarmed the walk and the rest of the command ran for real.
#     Redefinition now fails, and the attempt itself denies.
#   - Function-call leaves are RECORDED before the body is walked, so `rm()
#     { command rm "$@"; }; rm -rf <dir>` shows the call with its operands.
#   - `for`, `select`, `case` and `eval` headers are RECORDED as scan lines:
#     `for d in <TMP>/STEP-7.d; do rm -rf $d; done` names the dir only there,
#     and `eval "$(printf 'rm -rf ...')"` runs a string every other pass reads
#     as prose — `eval` is on the interpreter list for the same reason. A
#     `for` or `select` header that names a `_leaf_*` variable DENIES: it
#     would write the probe's own state, which no assignment leaf may.
#   - `break` and `continue` RUN, so loops end where the real command's
#     would (a `break` also sends every pending `read` site back for one
#     more walk, below); `exit` and `return` stay vetoed so the caller
#     cannot choose the probe's exit status. The cap EXITS the probe (nothing runs after it)
#     instead of disarming the trap, and is checked before the empty-walk
#     allow: `<2001 structural commands>; rm -rf <dir>` had capped with an
#     empty leaf list and fallen through to allow.
#   - A leaf that is ONLY assignments (`n=0`, `i=$((i+1))`) RUNS, so a
#     counter-bounded wait loop ends where the real command's would instead
#     of walking into the cap (a vetoed counter never advanced, and every
#     `until [ -s <packet> ] || [ $n -ge 180 ]` wait was refused as
#     oversized). The value shapes that run are bare words, `$name`,
#     `${name}` and `$(( ))` over names and operators: never a quote,
#     `$( )`, a backtick or a subscript, so nothing the assignment evaluates
#     can dispatch a command, and never a `_leaf_*` name, since the counter
#     shares the shell. A command word after the assignment (`n=1 rm -rf
#     <dir>`) is a command leaf as before.
#   - A `read` leaf RUNS on the second firing of its site, so `... | while
#     read d; do ...; done` ends instead of walking into the cap (a vetoed
#     read reported success forever). Every pipe producer is vetoed, so the
#     probe's read finds no input; a read that ran at once would end the
#     loop before its body was walked. The first firing of a site (its exact
#     text in one shell: `$BASH_SUBSHELL` tells a pipeline stage, a `( )`
#     or a function's pipeline from the shell around it) is therefore
#     vetoed, the body is walked once, and the next firing runs the read and
#     ends the loop. A `break` between the two marks the site for one more
#     vetoed firing, so a loop left by `break` cannot hand a later read of
#     the same text a run at once, while a loop whose body breaks out of an
#     inner loop on every pass still ends after its second walk. It runs
#     only on a pipe already at EOF: a here-string, a file or a device that
#     may never end keeps every later read vetoed, and the loop caps as
#     before. The shape is
#     `[IFS=<bare word>] read [-r] [name...]`: no other option, quote, `$`,
#     subscript or redirect, and never a `_leaf_*` name, since a read into
#     the counter would reset it on every pass. A vetoed read assigned
#     nothing real, so the walk after it cannot follow the loop's own
#     choices: while any read site is pending in the shell, a structural
#     leaf that expands a value (`[ -n "$d" ] || continue`, `case $d in`,
#     `while read d && [ -n "$d" ]`, `for f in $d`, `: ${d:?}`), an
#     arithmetic `[[` comparison over a bare name (`[[ n -ne 0 ]]`, any of
#     -eq -ne -lt -le -gt -ge, since `[[` reads a bare operand as a
#     variable), an arithmetic `for ((...))` head or `((...))` command, or
#     any `continue` DENIES as uninspectable, and the vetoed read gives each
#     name the value `x` so that a for-list over it has a pass to refuse. A
#     read loop that tests what it read is therefore refused, with a reason
#     that says so.
#   - The command reaches the probe on STDIN, not in the environment: a
#     command over the argument-size limit made `bash -c` fail with no leaf
#     and no syntax error, which allowed. Syntax is checked first with `bash
#     -n` over the same stdin, and a command over 256 KiB is refused outright
#     (the pre-pass is quadratic in a word's length).
#   - No temporary file. Leaves travel on stdout inside \035...\036 frames
#     and bash's own stderr is merged around them; the frame split recovers
#     both. The unhardened design's predictable `$TMPDIR/<hook>.<pid>` path
#     followed a planted symlink (overwriting its target with leaf text) and
#     blocked forever on a planted FIFO. A command carrying either framing
#     byte is refused.
#
# KNOWN RESIDUALS, each pinned ALLOW in the suite so a change of direction
# is a visible diff: a verb or a scratch-dir name split across quotes inside
# one word (`rm -rf STEP-"7".d`, `pk""ill`; a backslash split, `pk\ill`,
# is read through, since backslashes are dropped from every word), a glob
# outside the id (`S*-7.d`), a verb reached through a variable or `$(which
# ...)` (`k=pkill; $k node`), a command string carried in a variable (`x='rm
# -rf ...'; $x`), `xargs` fed from a pipe stage that never names the dir,
# `rm -rf <TMP>` or `<TMP>/*` against the whole scratch root (no step named;
# the permission text clears it for every session), `fuser -k`, a pid
# read from a file under another checkout, and a read loop that follows,
# in the same shell, a `read` with the same text that was vetoed and never
# fired again: a lone read (`ls | { read d; while read d; do rm ...; done;
# }`) or a loop left through a failing condition right after its read
# (`while read d && false; do :; done; while read d; do rm ...; done`),
# or two same-text loops in a row, each left by `break`. That site is
# still marked, so the later read runs at once and its body is not
# walked. A for-list over a read placeholder the command strips itself
# (`for f in ${d%x}`) is empty again, so its body never fires; and a
# vetoed condition reports status 0, so the else branch after it (`if
# test -z "$d"; then :; else rm ...; fi`) is never walked, in a read loop
# as at top level. An unquoted-delimiter heredoc body
# or an unquoted argument that merely mentions a sibling's `STEP-M.d` in
# prose is a false DENY, and the deny reason names the Write tool or a
# quoted delimiter as the way to write such prose. A quoted-delimiter
# heredoc body is not read, whatever words it carries, at top level or
# inside a substitution when the body and its terminator line hold no
# quote, backtick, backslash, `#` or `$` and their parens balance. Any other
# body inside a substitution is read, since bash 3.2 may end the
# substitution inside it (see LEAF_LINES_AWK), and a sibling named there is
# a false DENY. A skipped body stays unread because the interpreter test
# that widens a body into the scan reads the leaf's code lines only, never
# a heredoc body, and never counts a file extension as an interpreter (a
# target named `cases.sh` or `.env` does not widen; an earlier spelling
# matched the extension and scanned the body) — a findings artifact that
# mentions `node`, `sh` or `.env` in passing is the sanctioned record path
# for executor-read and executor-research, which have no Write tool. A
# search for the glob-form token itself (`grep -rn 'STEP-[0-9]*'` on the
# step's own dir) is a false DENY too; the deny reason offers `STEP.[0-9]+`
# instead, which is safe only as a regex operand (grep -E, rg): as a
# pathname glob it joins the glob-outside-the-id residual above.
#
# Fail-open on unparseable stdin and a missing `jq`, exactly as the sibling
# guards do and for the reason the trust guard's header measures (a hook's
# PATH and TMPDIR come from the operator's CLI environment, not from anything
# an executor's earlier Bash calls did). A missing pre-pass file fails
# CLOSED, as in both siblings: without the lexer there is no safe reading.
# The dependency set is bash/cat/jq/awk; the transcript is read with bash
# builtins alone so the suite can run this hook with PATH restricted to those
# four. Logging is best-effort and may use more.

set -uo pipefail

FRICTION_DIR="$HOME/.claude/friction"
FRICTION_LOG="$FRICTION_DIR/docket-sibling-guard.jsonl"

allow_default() {
    exit 0
}

deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

is_executor_archetype() {
    case "$1" in
        executor-read | executor-write | executor-research) return 0 ;;
        *) return 1 ;;
    esac
}

# Best-effort only: a logging failure must never change the decision, so
# every path through this stays `|| true` and unchecked. Logged: every deny,
# and every in-scope call decided with the own step UNKNOWN, since that is
# the degraded shape worth confirming. Routine in-scope allows are not
# logged — an executor makes hundreds of Bash calls and each would be a row.
log_decision() {  # <decision> <clause>
    mkdir -p "$FRICTION_DIR" 2>/dev/null || return 0
    local keys
    keys=$(printf '%s' "$INPUT" | jq -c 'keys' 2>/dev/null || echo '[]')
    jq -n -c \
        --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" \
        --arg decision "$1" \
        --arg clause "$2" \
        --arg detected_via "$DETECTED_VIA" \
        --arg agent_type "$AGENT_TYPE" \
        --arg own_mode "$OWN_MODE" \
        --arg own_step "$OWN_STEP" \
        --arg session "$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)" \
        --arg agent_id "${AGENT_ID:-}" \
        --arg own_transcript "${OWN_TRANSCRIPT:-}" \
        --argjson payload_keys "$keys" \
        '{at:$at, hook:"docket-sibling-guard", decision:$decision, clause:$clause, detected_via:$detected_via, agent_type:$agent_type, own_mode:$own_mode, own_step:$own_step, session:$session, agent_id:$agent_id, own_transcript:$own_transcript, payload_keys:$payload_keys}' \
        >>"$FRICTION_LOG" 2>/dev/null || true
}

# Reads the opening of the caller's OWN transcript (own_transcript_path
# below) for the wave executor brief marker and sets OWN_STEP (the digits of
# STEP-N) and OWN_MODE (known|none|unknown). An empty file is `unknown`: the
# harness writes transcripts asynchronously, and an opening not yet flushed
# is not an opening without the marker. Bounded: at most 64 KiB, read with `read -n` so a
# pathological first line cannot be slurped whole (bash 3.2 has no `read
# -N`), and line by line so a transcript whose first record is not the brief
# still finds it within the bound. Measured on real executor transcripts the
# brief is line 1 (about 19 KiB) and the marker sits about 1.3 KiB in. The
# marker must name the same step twice (`claim STEP-N --owner wave:STEP-N:`),
# which is what wave.js renders and what no skill text carries.
scan_transcript() {  # <transcript-path>
    local t="$1" chunk="" rest="" total=0 budget=65536
    local re='docket step claim STEP-([0-9]+) --owner wave:STEP-([0-9]+):'
    OWN_STEP=""
    OWN_MODE="unknown"
    [ -n "$t" ] && [ -r "$t" ] && [ -f "$t" ] && [ -s "$t" ] || return 0
    OWN_MODE="none"
    while [ "$total" -lt "$budget" ]; do
        chunk=""
        IFS= read -r -n $((budget - total)) chunk || [ -n "$chunk" ] || break
        rest="$chunk"
        while [[ $rest =~ $re ]]; do
            if [ "${BASH_REMATCH[1]}" = "${BASH_REMATCH[2]}" ]; then
                OWN_STEP="${BASH_REMATCH[1]}"
                OWN_MODE="known"
                return 0
            fi
            rest="${rest#*"${BASH_REMATCH[0]}"}"
        done
        total=$((total + ${#chunk} + 1))
    done < "$t"
    return 0
}

# Resolves the caller's OWN transcript (WHICH TRANSCRIPT above). Prints the
# payload's transcript_path unchanged when no agent_id is present or when
# that path already names the seat's own file; with an agent_id, prints the
# first readable `agent-<id>.jsonl` under the session directory (Agent-tool
# shape first, then any Workflow run's directory), or nothing when none is
# found, which scan_transcript reads as `unknown`. Builtins only.
own_transcript_path() {  # <transcript_path> <agent_id> <session_id>
    local t="$1" agent="$2" session="$3" base dir candidate
    local dirs=()
    if [ -z "$agent" ]; then
        printf '%s' "$t"
        return 0
    fi
    [ -n "$t" ] || return 0
    case "${t##*/}" in
        "agent-${agent}.jsonl")
            printf '%s' "$t"
            return 0
            ;;
    esac
    case "$t" in
        *.jsonl) dirs+=("${t%.jsonl}") ;;
    esac
    if [ -n "$session" ]; then
        base="${t%/*}"
        [ "$base" = "$t" ] && base="."
        dirs+=("${base}/${session}")
    fi
    # ${dirs[@]+...}: bash 3.2 under `set -u` treats an empty array as unbound.
    for dir in ${dirs[@]+"${dirs[@]}"}; do
        [ -d "$dir" ] || continue
        candidate="${dir}/subagents/agent-${agent}.jsonl"
        if [ -f "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
        for candidate in "${dir}"/subagents/workflows/*/"agent-${agent}.jsonl"; do
            if [ -f "$candidate" ]; then
                printf '%s' "$candidate"
                return 0
            fi
        done
    done
    return 0
}

INPUT=$(cat 2>/dev/null) || allow_default
[ -n "$INPUT" ] || allow_default

command -v jq >/dev/null 2>&1 || allow_default

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null) || allow_default
AGENT_ID=$(printf '%s' "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null) || AGENT_ID=""
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null) || SESSION_ID=""
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null) || TRANSCRIPT_PATH=""
CALLER_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null) || CALLER_CWD=""
OWN_TRANSCRIPT=$(own_transcript_path "$TRANSCRIPT_PATH" "$AGENT_ID" "$SESSION_ID")

OWN_STEP=""
OWN_MODE="unknown"
DETECTED_VIA=""
if is_executor_archetype "$AGENT_TYPE"; then
    DETECTED_VIA="agent_type"
    scan_transcript "$OWN_TRANSCRIPT"
elif [ -z "$AGENT_TYPE" ]; then
    # Unidentified caller: only a transcript that opens with a wave executor
    # brief puts it in scope. The main conversation, whose first message is
    # the operator's, never carries that exact spelling.
    scan_transcript "$OWN_TRANSCRIPT"
    [ "$OWN_MODE" = "known" ] || allow_default
    DETECTED_VIA="transcript-brief"
else
    allow_default
fi

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default

REASON_PREFIX="sibling-destructive verb blocked:"

if [ "${#COMMAND}" -gt 262144 ]; then
    log_decision "deny" "oversized"
    deny "$REASON_PREFIX this command is over 256 KiB, more than the sibling-guard hook will check in one call. Split it into smaller Bash calls, or write a large body with the Write tool where you have it; a single call this large is refused rather than passed through unchecked."
fi
case "$COMMAND" in
    *$'\035'* | *$'\036'*)
        log_decision "deny" "framing-bytes"
        deny "$REASON_PREFIX this command carries a control byte (0x1d or 0x1e) the sibling-guard hook uses to frame its own analysis, so it cannot be checked. Remove the byte; no shell command needs it." ;;
esac

# --- Syntax first, on the same bytes the probe will walk. ------------------
if ! printf '%s' "$COMMAND" | bash -n >/dev/null 2>&1; then
    log_decision "deny" "unparseable"
    deny "$REASON_PREFIX the sibling-guard hook could not parse this command to check it (bash reported a syntax error while analyzing it) and refuses rather than guessing. Fix the command's syntax; if it is not actually invalid, that is a hook defect to report separately."
fi

# --- Leaf enumeration: ask bash, don't re-derive it. ---------------------
#
# The trust guard's probe with the hardening the header lists. Leaves are
# printed as \035<text>\036 frames on the probe's stdout, saved as fd 8
# before the walk: bash 5 runs a coproc's leaves in a child whose stdout is
# the coproc pipe, and they would be lost there. bash's stderr is merged into
# the same capture and recovered from between the frames. The probe refuses
# with four exit codes: 113 the cap, 114 a redirection on a structural
# builtin, 115 a branch on an unread value, 116 probe state in a loop
# header. Each reaches the hook through the stderr marker printed before
# the exit, since an exit inside a pipeline stage (`ls | { ...; }; echo
# done`) ends only that stage and never reaches the probe exit status. The
# marker is written on fd 7, a copy of the probe's stdout opened before
# `set -r`, not on fd 2: a loop that closes stderr (`done 2>&-`) would
# swallow it there, and restricted mode lets a close through since it opens
# no file. The hook reads it back with bash's own stderr, from between the
# frames. 113 and 114 are also read from the exit status, as a fallback for
# a top-level refusal whose marker was lost. The caller cannot pick any of
# them: `exit` and `return` are vetoed, and a vetoed leaf reports success.
PROBE_RAW=$(printf '%s' "$COMMAND" | bash -c '
    shopt -s extdebug
    set -T
    COMMAND=$(cat)
    _leaf_n=0   # not `n`: the analyzed command shares this shell, and `for n in …` collided with the counter
    # A leaf that is only variable assignments RUNS (see the header), but
    # only in these value shapes: bare words, $name, ${name}, and $(( ))
    # over names and operators. No quotes, no $( ), no backticks, no
    # subscripts, so nothing an assignment can evaluate runs a command.
    readonly _leaf_name="[A-Za-z_][A-Za-z0-9_]*"
    readonly _leaf_word="[A-Za-z0-9_./:@%+,-]|\\\$${_leaf_name}|\\\$\\{${_leaf_name}\\}|\\\$\\(\\(([^][()\$\`]|\\\$${_leaf_name})*\\)\\)"
    readonly _leaf_assign_re="^${_leaf_name}\\+?=(${_leaf_word})*([[:space:]]+${_leaf_name}\\+?=(${_leaf_word})*)*\$"
    # A read leaf RUNS (see the header) only in this shape: an optional
    # IFS= of bare characters, -r, and plain names. A site is the subshell
    # level and the leaf text. _leaf_reads holds |-separated sites, each
    # after a state letter: P vetoed once, B vetoed once and then a break
    # ran, Q vetoed again after that break. A P or Q site runs on its next
    # firing; a B site is vetoed once more. _leaf_read_ok drops to 0 for
    # good once a read meets input other than a pipe at EOF.
    readonly _leaf_read_re="^(IFS=[A-Za-z0-9_./:@%+,-]*[[:space:]]+)?read([[:space:]]+-r)?([[:space:]]+${_leaf_name})*\$"
    _leaf_reads="|"
    _leaf_read_ok=1
    _guard_probe() {
        _leaf_n=$((_leaf_n + 1))
        if [ "$_leaf_n" -gt 2000 ]; then
            printf "%s\n" "_guard_probe: leaf cap" >&7
            exit 113
        fi
        # The first firing is this probe own eval line, not a leaf of the
        # command; recording it would put an interpreter word in every walk.
        if [ "$_leaf_n" -eq 1 ] && [ "$BASH_COMMAND" = "eval -- \"\$COMMAND\"" ]; then
            return 0
        fi
        local _leaf_head="${BASH_COMMAND%%[ $'"'"'\t\n'"'"']*}"
        _leaf_head="${_leaf_head##*/}"
        # Structural leaves run for real. While a vetoed read stands in for
        # input it never read (_leaf_reads holds a site), one that expands a
        # value, or a continue, could steer the loop past the body it never
        # walked, so the walk is refused. Every refusal is a marker on
        # fd 7: an exit inside a pipeline stage never reaches the probe
        # exit status. An arithmetic `for ((...))` head or `((...))` command
        # reads bare names as variables, so it is refused the same way.
        if [ "$_leaf_reads" != "|" ]; then
            case "$BASH_COMMAND" in
                "(("*)
                    printf "%s\n" "_guard_probe: branch on an unread value" >&7
                    exit 115 ;;
            esac
        fi
        case "$_leaf_head" in
            for | select | case | eval)
                case "$BASH_COMMAND" in
                    *[\<\>]*)
                        printf "%s\n" "_guard_probe: structural redirect" >&7
                        exit 114 ;;
                esac
                case "$_leaf_head:$BASH_COMMAND" in
                    for:*_leaf_* | select:*_leaf_*)
                        printf "%s\n" "_guard_probe: probe state in a loop header" >&7
                        exit 116 ;;
                esac
                if [ "$_leaf_reads" != "|" ]; then
                    case "$BASH_COMMAND" in
                        *[\$\`]*)
                            printf "%s\n" "_guard_probe: branch on an unread value" >&7
                            exit 115 ;;
                    esac
                fi
                printf "\035%s\036" "$BASH_COMMAND" >&8
                return 0 ;;
            while | until | if | elif | else | fi | then | do | done | \
            esac | function | time | "{" | "}" | "[" | "[[" | : | \
            true | false | break | continue)
                case "$BASH_COMMAND" in
                    *[\<\>]*)
                        printf "%s\n" "_guard_probe: structural redirect" >&7
                        exit 114 ;;
                esac
                # An arithmetic `[[` comparison reads a bare name as a
                # variable (`[[ n -ne 0 ]]`), so it expands a value with no $.
                if [ "$_leaf_reads" != "|" ]; then
                    case "$_leaf_head:$BASH_COMMAND" in
                        continue:* | *[\$\`]* | \
                        "[[:"*" -eq "* | "[[:"*" -ne "* | "[[:"*" -lt "* | \
                        "[[:"*" -le "* | "[[:"*" -gt "* | "[[:"*" -ge "*)
                            printf "%s\n" "_guard_probe: branch on an unread value" >&7
                            exit 115 ;;
                    esac
                fi
                # A break may leave a read loop whose site never runs, so a
                # later read with the same text would run at once: every P
                # site becomes B and walks its body once more. A break in an
                # inner loop does the same to the read loop around it, whose
                # Q site then ends it on the next firing.
                [ "$_leaf_head" = break ] && _leaf_reads="${_leaf_reads//|P/|B}"
                return 0 ;;
        esac
        if [[ "$BASH_COMMAND" =~ $_leaf_read_re ]] && [[ "$BASH_COMMAND" != *_leaf_* ]]; then
            printf "\035%s\036" "$BASH_COMMAND" >&8
            local _leaf_site="${BASH_SUBSHELL}:${BASH_COMMAND}"
            # A vetoed read gives each name the value x, so a for-list over
            # it has a pass that reaches the guard above instead of none. A
            # read that runs assigns its own values over these. BASH* names
            # are left alone: BASH_SUBSHELL is part of the site key. Every
            # local here is a _leaf_* name, which no admitted read names, so
            # each assignment reaches the command variable.
            local _leaf_rest="${BASH_COMMAND#IFS=*[[:space:]]}" _leaf_named=0
            _leaf_rest="${_leaf_rest#read}"
            while [[ "$_leaf_rest" =~ ^[[:space:]]+([-A-Za-z0-9_]+)(.*)$ ]]; do
                _leaf_rest="${BASH_REMATCH[2]}"
                case "${BASH_REMATCH[1]}" in
                    -r) ;;
                    BASH*) _leaf_named=1 ;;
                    *) printf -v "${BASH_REMATCH[1]}" %s x 2>&9
                       _leaf_named=1 ;;
                esac
            done
            [ "$_leaf_named" -eq 1 ] || REPLY=x
            case "$_leaf_reads" in
                *"|B$_leaf_site|"*)
                    _leaf_reads="${_leaf_reads/"|B$_leaf_site|"/|Q$_leaf_site|}"
                    return 1 ;;
                *"|P$_leaf_site|"* | *"|Q$_leaf_site|"*)
                    _leaf_reads="${_leaf_reads/"|P$_leaf_site|"/|}"
                    _leaf_reads="${_leaf_reads/"|Q$_leaf_site|"/|}"
                    local _leaf_byte
                    if [ "$_leaf_read_ok" -eq 1 ] && [ -p /dev/stdin ]; then
                        IFS= read -r -t 1 -n 1 _leaf_byte
                        [ "$?" -eq 1 ] && return 0
                    fi
                    _leaf_read_ok=0
                    return 1 ;;
            esac
            _leaf_reads="${_leaf_reads}P${_leaf_site}|"
            return 1
        fi
        if [[ "$BASH_COMMAND" =~ $_leaf_assign_re ]]; then
            case "$BASH_COMMAND" in
                *_leaf_*) ;;   # the counter and these patterns: never the command'"'"'s to set
                *)
                    printf "\035%s\036" "$BASH_COMMAND" >&8
                    return 0 ;;
            esac
        fi
        printf "\035%s\036" "$BASH_COMMAND" >&8
        if declare -F "$_leaf_head" >&9 2>&9; then
            return 0
        fi
        return 1
    }
    readonly -f _guard_probe
    exec 7>&1 8>&1 9>/dev/null
    set -r
    trap _guard_probe DEBUG
    eval -- "$COMMAND"
' 2>&1)
PROBE_RC=$?

# Leaves are the framed segments; everything outside a frame is bash's own
# stderr during the walk, the probe's refusal markers included.
PROBE_TEXT=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s\036", substr($0, i + 1) }')
PROBE_ERR=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s", substr($0, 1, i - 1); else printf "%s", $0 }')

# One dispatch for every probe refusal: the marker, or for 113 and 114 the
# exit status as a fallback (see the comment above PROBE_RAW).
case "$PROBE_RC:$PROBE_ERR" in
    113:* | *"_guard_probe: leaf cap"*)
        log_decision "deny" "oversized"
        deny "$REASON_PREFIX this command has too many parts (over 2000) for the sibling-guard hook to finish checking it. A wait loop ends in the check when it counts its own passes, \`n=0; until [ -s f ] || [ \$n -ge N ]; do sleep S; n=\$((n+1)); done\`, and so does a read loop fed by a pipe whose read takes no option but -r, \`cmd | while IFS= read -r x; do ...; done\` (a file, here-string or process-substitution input, or another read option, keeps it from ending); an uncounted wait never does. Otherwise split it into smaller Bash calls; a single call this large is refused rather than passed through unchecked." ;;
    114:* | *"_guard_probe: structural redirect"*)
        log_decision "deny" "structural-redirect"
        deny "$REASON_PREFIX a redirection on a shell builtin that carries no command (\`: > file\`, \`true > file\`, \`[ ... ] > file\`) cannot be checked for a sibling's path. Truncate or create a file with \`cat /dev/null > <path>\`, so the target is a visible operand." ;;
    *"restricted: cannot redirect output"*)
        log_decision "deny" "compound-redirect"
        deny "$REASON_PREFIX a redirection on a compound command (\`{ ... } > file\`, \`( ... ) > file\`, a loop or \`if\` followed by \`> file\`, or a function call \`> file\`) hides its target from this check. Redirect each simple command's output on its own, e.g. \`cargo build > <TMP>/STEP-N.d/build.log 2>&1\`." ;;
    *"readonly function"*)
        log_decision "deny" "probe-tamper"
        deny "$REASON_PREFIX this command redefines the sibling-guard hook's own probe handler (\`_guard_probe\`). No executor command needs a function by that name; rename it." ;;
    *"_guard_probe: probe state in a loop header"*)
        log_decision "deny" "probe-tamper"
        deny "$REASON_PREFIX this command names a \`_leaf_*\` variable in a \`for\` or \`select\` header. The sibling-guard hook keeps its own analysis state under that prefix, so it cannot check the command; rename the variable." ;;
    *"_guard_probe: branch on an unread value"*)
        log_decision "deny" "read-value-branch"
        deny "$REASON_PREFIX this command branches on a variable after a \`read\` in it (a \`[ ... ]\`, \`[[ ... ]]\`, \`case\`, \`for ... in\`, \`for ((...))\`, \`:\` or \`eval\` that expands a value, or a \`continue\`). The sibling-guard hook feeds a read no input, so it cannot tell which commands the loop would run. Filter the input before the loop instead (\`cmd | grep -v '^\$' | while IFS= read -r x; do ...; done\`), or split it into smaller Bash calls." ;;
esac

if [ -z "$PROBE_TEXT" ]; then
    # No leaf dispatched: the command is inert (all comment, all whitespace,
    # or only structural builtins), unless bash reported something while
    # walking it, in which case the walk is "could not analyze" and refuses.
    if [ -n "$PROBE_ERR" ]; then
        log_decision "deny" "unanalyzable"
        deny "$REASON_PREFIX the sibling-guard hook could not analyze this command (bash reported: ${PROBE_ERR%%$'\n'*}) and refuses rather than guessing. Simplify the command; if it is valid, that is a hook defect to report separately."
    fi
    allow_default
fi

# --- Line selection: which lines of a leaf are code. ---------------------
#
# A leaf spans lines when it carries a heredoc, a multi-line quoted word, or
# a substitution whose body spans lines. The probe vetoes such a leaf before
# its substitutions run, so their inner commands never reach the probe as
# leaves of their own; every line of the leaf is therefore matched as a leaf,
# except the body of a heredoc (its terminator line included). LEAF_LINES_AWK
# classifies the lines. It finds heredoc operators with a quote-aware lexer,
# so a `<<'EOF'` inside quotes or a comment opens no body, and it stops
# skipping anything, keeping every remaining line, wherever its reading could
# disagree with bash's: a backtick, a comment, `$[`, a quote or backslash
# inside arithmetic, a single quote inside `${ }` within double quotes, an
# expansion or a newline in a delimiter, and a heredoc with no terminator
# line. Lines before that point keep their classification.
#
# A heredoc body starts after the first newline at the nesting level of its
# operator. A newline inside a substitution opened after the operator, or
# after the substitution around the operator has closed, stops skipping too.
# Inside a substitution, bash 3.2 finds the closing `)` by a paren and quote
# scan that ignores heredocs, so a body there is skipped only when that scan
# reads it and its terminator line as plain balanced text (body_inert).
#
# In "code" mode it prints the code lines of every leaf. In "scan" mode it
# prints the code lines, or the whole leaf when `widen` is set or the leaf
# carries an unquoted-delimiter heredoc (whose body bash expands before any
# consumer sees it). A delimiter it cannot read ends classification like the
# cases above: every remaining line is kept.
LEAF_LINES_AWK='
function count_nl(s,   t) {
    t = s
    return gsub(/\n/, "", t)
}
# Index just past the balanced arithmetic span opened at i ($(( or ((), or
# 0 when it is unbalanced or holds a quote, backtick or backslash.
function skip_arith(s, i, n,   j, depth, c) {
    j = i + (substr(s, i, 1) == "$" ? 3 : 2)
    depth = 2
    while (j <= n && depth > 0) {
        c = substr(s, j, 1)
        if (c == "(") depth++
        else if (c == ")") depth--
        else if (c == SQ || c == DQ || c == BQ || c == "\\") return 0
        j++
    }
    return depth > 0 ? 0 : j
}
# Index just past the single-quoted span opened at i, or 0 when unclosed.
function skip_single(s, i, n,   j) {
    j = i + 1
    while (j <= n && substr(s, j, 1) != SQ) j++
    return j > n ? 0 : j + 1
}
# Parses the heredoc operator at i into HD_DASH, HD_QUOTED and HD_DELIM (the
# delimiter after quote removal) and returns the index past its word.
# HD_BAIL is set when the delimiter value is uncertain.
function parse_heredoc(s, i, n,   j, c, k, part) {
    HD_DASH = 0
    HD_QUOTED = 0
    HD_DELIM = ""
    HD_BAIL = 0
    j = i + 2
    if (substr(s, j, 1) == "-") { HD_DASH = 1; j++ }
    while (j <= n && (substr(s, j, 1) == " " || substr(s, j, 1) == "\t")) j++
    while (j <= n) {
        c = substr(s, j, 1)
        if (index(" \t\n;&|()<>", c)) break
        if (c == SQ || c == DQ) {
            k = j + 1
            while (k <= n && substr(s, k, 1) != c) k++
            part = substr(s, j + 1, k - j - 1)
            if (k > n || part ~ /[\n\\$\140]/) { HD_BAIL = 1; return j }
            HD_DELIM = HD_DELIM part
            HD_QUOTED = 1
            j = k + 1
            continue
        }
        if (c == "\\") {
            if (j == n || substr(s, j + 1, 1) == "\n") { HD_BAIL = 1; return j }
            HD_DELIM = HD_DELIM substr(s, j + 1, 1)
            HD_QUOTED = 1
            j += 2
            continue
        }
        if (c == "$" || c == BQ) { HD_BAIL = 1; return j }
        HD_DELIM = HD_DELIM c
        j++
    }
    return j
}
function d_below(sp,   k) {
    for (k = 1; k < sp; k++) if (FT[k] == "D") return 1
    return 0
}
# 1 when lines a..b, a heredoc body and its terminator line, read the same to
# the paren and quote scan bash 3.2 uses to find the end of an enclosing
# substitution, which ignores heredocs: no quote, backtick, backslash, `#` or
# `$`, and parens that balance without closing below the level they start
# at. A `)` that closes there ends the substitution inside what would
# otherwise be body text; the terminator line is outside every quote for
# that scan even when the delimiter on the operator line was quoted.
function body_inert(a, b,   s, k, d, c) {
    d = 0
    for (s = a; s <= b; s++) {
        if (L[s] ~ /[\\#$\047\042\140]/) return 0
        for (k = 1; k <= length(L[s]); k++) {
            c = substr(L[s], k, 1)
            if (c == "(") d++
            else if (c == ")" && --d < 0) return 0
        }
    }
    return d == 0
}
# Nesting level of the lexer state in classify: every open frame above the
# first, plus the parens or braces each frame holds open (FD, 0 on D frames).
function level(sp,   k, v) {
    v = sp - 1
    for (k = 1; k <= sp; k++) v += FD[k]
    return v
}
# Fills NL, L[1..NL] and CLS[1..NL] ("c" code, "b" heredoc body or
# terminator) and sets UNQ when an operator has an unquoted or empty
# delimiter. Frames: N (command text, FD counts open parens), D (inside
# double quotes), B (inside ${ }, FD counts open braces). A body is taken
# only at a newline at the level its operator was queued at, with no close
# below that level since (pmin).
function classify(leaf,   n, i, c, c2, j, k, t, s, sp, np, ln, found, x, lv, pmin) {
    NL = split(leaf, L, "\n")
    START[1] = 1
    for (k = 1; k <= NL; k++) {
        CLS[k] = "c"
        START[k + 1] = START[k] + length(L[k]) + 1
    }
    UNQ = 0
    n = length(leaf)
    i = 1
    ln = 1
    sp = 1
    FT[1] = "N"
    FD[1] = 0
    np = 0
    while (i <= n) {
        c = substr(leaf, i, 1)
        c2 = substr(leaf, i, 2)
        if (c == "\\") {
            if (substr(leaf, i + 1, 1) == "\n") ln++
            i += 2
            continue
        }
        if (c == "\n") {
            ln++
            i++
            if (FT[sp] != "N" || np == 0) continue
            lv = level(sp)
            if (pmin < lv) return
            for (k = 1; k <= np; k++) {
                if (PLVL[k] != lv) return
                found = 0
                for (t = ln; t <= NL; t++) {
                    x = L[t]
                    if (PDASH[k]) sub(/^\t+/, "", x)
                    if (x == PDELIM[k]) { found = 1; break }
                }
                if (!found) return
                if (lv > 0 && !body_inert(ln, t)) return
                for (s = ln; s <= t; s++) CLS[s] = "b"
                ln = t + 1
            }
            np = 0
            i = START[ln]
            continue
        }
        if (c == BQ || c2 == "$[") return
        if (c2 == "$(" && substr(leaf, i, 3) == "$((" || FT[sp] == "N" && c2 == "((") {
            j = skip_arith(leaf, i, n)
            if (!j) return
            ln += count_nl(substr(leaf, i, j - i))
            i = j
            continue
        }
        if (FT[sp] == "D") {
            if (c == DQ) { sp--; if ((lv = level(sp)) < pmin) pmin = lv }
            else if (c2 == "$(") { FT[++sp] = "N"; FD[sp] = 0; i++ }
            else if (c2 == "${") { FT[++sp] = "B"; FD[sp] = 0; i++ }
            i++
            continue
        }
        if (c == SQ || c2 == "$" SQ) {
            if (FT[sp] == "B" && (c2 == "$" SQ || d_below(sp))) return
            if (c2 == "$" SQ) {
                j = i + 2
                while (j <= n && substr(leaf, j, 1) != SQ) j += (substr(leaf, j, 1) == "\\") ? 2 : 1
                j = (j > n) ? 0 : j + 1
            } else {
                j = skip_single(leaf, i, n)
            }
            if (!j) return
            ln += count_nl(substr(leaf, i, j - i))
            i = j
            continue
        }
        if (c == DQ) { FT[++sp] = "D"; FD[sp] = 0; i++; continue }
        if (c2 == "${") { FT[++sp] = "B"; FD[sp] = 0; i += 2; continue }
        if (FT[sp] == "B") {
            if (c2 == "$(") { FT[++sp] = "N"; FD[sp] = 0; i++ }
            else if (c == "{") FD[sp]++
            else if (c == "}") {
                if (FD[sp] > 0) FD[sp]--; else sp--
                if ((lv = level(sp)) < pmin) pmin = lv
            }
            i++
            continue
        }
        if (c == "#" && (i == 1 || index(" \t\n;&|()<>", substr(leaf, i - 1, 1)))) return
        if (c == "(" || c2 == "$(") {
            FD[sp]++
            i += (c == "(") ? 1 : 2
            continue
        }
        if (c == ")") {
            if (FD[sp] > 0) FD[sp]--
            else if (sp > 1) sp--
            else if (np) return
            else { i++; continue }
            if ((lv = level(sp)) < pmin) pmin = lv
            i++
            continue
        }
        if (substr(leaf, i, 3) == "<<<") { i += 3; continue }
        if (c2 == "<<") {
            j = parse_heredoc(leaf, i, n)
            if (HD_BAIL) return
            if (HD_DELIM == "" || !HD_QUOTED) UNQ = 1
            if (HD_DELIM != "") {
                lv = level(sp)
                if (++np == 1) pmin = lv
                PDELIM[np] = HD_DELIM
                PDASH[np] = HD_DASH
                PLVL[np] = lv
            }
            i = j
            continue
        }
        i++
    }
}
BEGIN {
    RS = "\036"
    SQ = "\047"
    DQ = "\042"
    BQ = "\140"
}
{
    leaf = $0
    if (leaf == "") next
    classify(leaf)
    if (mode == "scan" && (widen == "1" || UNQ)) {
        printf "%s\n", leaf
        next
    }
    for (k = 1; k <= NL; k++) if (CLS[k] == "c") printf "%s\n", L[k]
}
'

# --- Widening: where a heredoc's body stops being inert data. ------------
#
# The trust guard's two triggers, applied to this guard's line selection
# rather than its first lines, with one correction: the interpreter test
# reads each leaf's code lines only, never a heredoc body. An interpreter that
# consumes a heredoc is always a command word, never body text; reading bodies
# too made an artifact that mentioned `node` or `.env` widen itself, and its
# prose was then matched — the sanctioned record path for the two archetypes
# with no Write tool. An unquoted heredoc delimiter still widens its own leaf,
# since that body is expanded before its consumer ever sees it.
#
# The boundary on either side of an interpreter name is any byte that is not
# a word character and not a dot. An earlier spelling took any non-word byte,
# so `cat > tests/cases.sh <<'EOF'` widened on the `.sh` of its own target
# file and the quoted body was scanned; a whitespace-only boundary fixed that
# but missed `x=$(sh <<'EOF'`, whose body then ran unread. The dot alone
# separates a name from its extension, so `cases.sh` and `.env` do not widen
# while `sh`, `/bin/sh`, `"sh"`, `$(sh`, a backtick and `;sh` all do; the
# shapes are pinned in tests/docket-sibling-guard-hook.test.sh.
INTERPRETER_RE='(^|[^A-Za-z0-9_.])(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|tclsh|expect|osascript|env|eval)([^A-Za-z0-9_.]|$)'
CODE_LINES=$(printf '%s' "$PROBE_TEXT" | awk -v mode=code "$LEAF_LINES_AWK")
WIDEN=0
if [[ "$CODE_LINES" =~ $INTERPRETER_RE ]]; then
    WIDEN=1
fi

SCAN_TEXT=$(printf '%s' "$PROBE_TEXT" | awk -v mode=scan -v widen="$WIDEN" "$LEAF_LINES_AWK")

# --- Quote-group marking, the shared pre-pass. ---------------------------
HOOK_DIR="${0%/*}"
[ "$HOOK_DIR" = "$0" ] && HOOK_DIR="."
PREPASS_AWK="${HOOK_DIR}/docket-guard-prepass.awk"
[ -r "$PREPASS_AWK" ] || { log_decision "deny" "no-prepass"; deny "$REASON_PREFIX the sibling-guard hook's shared pre-pass file (docket-guard-prepass.awk) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."; }
STRIPPED=$(printf '%s' "$SCAN_TEXT" | awk -f "$PREPASS_AWK" 2>/dev/null) || allow_default

# --- THE MATCH. -----------------------------------------------------------
#
# Every line is one simple command bash would dispatch (or a widened leaf, or
# a loop header). A first pass over the whole command sets the process-lookup
# flag, since a `kill $pid` may precede or follow the `pgrep` that fed it;
# the second pass applies the five clauses in the header, first match wins.
# Output is `CLAUSE<TAB>DETAIL`, or nothing.
#
# Words are compared in the form bash builds them as far as this pass can
# see: quotes and backslashes are dropped from each word (`STEP-7\.d`,
# `."."`, `1\234`), and command names are lowercased (the scratch root and
# the checkout sit on a case-insensitive filesystem, where `PKILL` runs
# pkill). The verb of a leaf is its head after wrapper prefixes are skipped.
#
# A scratch token is `STEP-` (any case) followed by an id run — the word up
# to the next `/`. Digits then `.d` (or a glob standing for the `d`, or a
# bare `*`) name a step; a run carrying `$`, a backtick or `(` is an
# expansion, and a run carrying `* ? [ {` is a glob or brace, both foreign
# by construction since a literal own id is never spelled that way, except
# that a word that is exactly `STEP-$name` or `STEP-${name}` is admitted
# when it is an argument of a `docket` leaf with no substitution in it and
# does not follow a redirect operator, and that a run of the own digits, a
# `-`, then plain characters, `$name` or `${name}` is an own file when an own
# `.d` token precedes it in the same word.
# The id is compared whole: `STEP-93` and `STEP-9393` are different steps.
MATCH=$(printf '%s' "$STRIPPED" | awk -v own="$OWN_STEP" -v own_mode="$OWN_MODE" -v interp="$WIDEN" -v cwd="$CALLER_CWD" '
BEGIN {
    MARK = "\001"
    DOTDOT_RE = "(^|/)\\.\\.(/|$)"
    discovery = 0
    # Mandatory positional operands a wrapper takes before its command, by
    # count: verb_index skips them by position, whatever their shape, after
    # the wrapper options (`timeout 1.5 cmd`, `timeout $t cmd`).
    WRAPPER_OPERANDS["timeout"] = 1
}
function decode(raw,    inner, cpos) {
    if (length(raw) >= 2 && substr(raw, 1, 1) == MARK && substr(raw, length(raw), 1) == MARK) {
        inner = substr(raw, 2, length(raw) - 2)
        cpos = index(inner, ":")
        D_GROUP = substr(inner, 1, cpos - 1)
        D_WORD = substr(inner, cpos + 1)
        gsub(/[\047\042\\]/, "", D_WORD)
        return 1
    }
    D_GROUP = ""
    D_WORD = raw
    gsub(/[\047\042\\]/, "", D_WORD)
    return 0
}
# The command name a word would resolve to: a delimiter or subshell glued
# onto its front is stripped (`;rm`, `(rm`, `$(rm`), then a leading `=`
# (zsh expands `=rm` to the path of rm), then the directory, then case.
function head_of(w,   h) {
    h = w
    sub(/^.*(\$\(|\140|\(|;|\||&)/, "", h)
    sub(/^=+/, "", h)
    sub(/^.*\//, "", h)
    return tolower(h)
}
# `coproc` is here because bash 3.2 has no coproc keyword and reports it as
# the command name, while zsh runs the words after it as a coprocess.
# `noglob`, `nocorrect`, `-` and `repeat` are zsh precommand modifiers or
# reserved words that bash likewise reports as the command name.
function is_wrapper(h) {
    return (h == "coproc" || h == "noglob" || h == "nocorrect" || h == "-" || h == "repeat" || h == "sudo" || h == "doas" || h == "command" || h == "builtin" || h == "exec" || h == "xargs" || h == "nohup" || h == "nice" || h == "ionice" || h == "timeout" || h == "env" || h == "time" || h == "setsid" || h == "stdbuf" || h == "caffeinate" || h == "chronic" || h == "unbuffer")
}
# The verb position of a leaf: the first word (or word `start`), then past
# any wrapper and the wrapper own options, values (`-n 5`, `5s`, `FOO=1`) and
# flags. A wrapper in WRAPPER_OPERANDS has its mandatory operands skipped by
# position after its options, whatever their shape. zsh evaluates the `repeat` count arithmetically, so the word after
# `repeat` is the count whatever its shape (a quoted count spans its whole
# group), and each lone `{` after it opens a body.
# The pre-pass splits a count word built from glued quoted parts or a quoted
# expansion into several tokens, and a quoted blank in it leaves none, so
# where the count ends is a best guess. REPEAT_FROM is the first word after
# the first `repeat` passed (0 when none), for repeat_scan.
function verb_index(n, start,   i, h, quoted, g, k) {
    REPEAT_FROM = 0
    i = start ? start : 1
    while (i <= n && words[i] == "") i++
    if (i > n) return 0
    decode(words[i])
    h = head_of(D_WORD)
    while (is_wrapper(h)) {
        i++
        if (h == "repeat") {
            while (i <= n && words[i] == "") i++
            if (!REPEAT_FROM) REPEAT_FROM = i
            quoted = decode(words[i])
            g = D_GROUP
            i++
            if (quoted) while (i <= n && decode(words[i]) && D_GROUP == g) i++
            while (i <= n) {
                if (words[i] != "") { decode(words[i]); if (D_WORD != "{") break }
                i++
            }
        }
        if (h in WRAPPER_OPERANDS) {
            while (i <= n) {
                if (words[i] != "") { decode(words[i]); if (D_WORD !~ /^-/) break }
                i++
            }
            for (k = 0; i <= n && k < WRAPPER_OPERANDS[h]; i++) if (words[i] != "") k++
        }
        while (i <= n) {
            if (words[i] == "") { i++; continue }
            decode(words[i])
            if (D_WORD ~ /^-/ || D_WORD ~ /^[0-9]+[smhd]?$/ || D_WORD ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
            break
        }
        if (i > n) return 0
        decode(words[i])
        h = head_of(D_WORD)
    }
    return i
}
# First scratch token in w, into T_TOKEN (its text) and T_NUM (its digits,
# or "" when an expansion, glob or brace stands where the id should be).
# T_END is the position just past the token, for scanning the rest of the
# word. T_LEAF is 1 for an expansion token shaped as an own-file name: the
# own digits, a `-`, then plain characters and `$name` or `${name}` up to the
# next `/`. Only foreign_scratch honours it, and only after the own `.d`.
# docket_arg is true only for a word the engine reads as a step id (see THE
# MATCH); callers that pass nothing get 0.
function scratch_token(w, docket_arg,   pos, rest, run, id, suffix, dot, sub_ok) {
    T_END = 0
    T_LEAF = 0
    if (!match(w, /[Ss][Tt][Ee][Pp]-/)) return 0
    pos = RSTART + RLENGTH
    rest = substr(w, pos)
    run = rest
    sub(/\/.*$/, "", run)
    if (run ~ /[$`(]/) {
        if (docket_arg && w ~ /^[Ss][Tt][Ee][Pp]-\$(\{[A-Za-z_][A-Za-z0-9_]*\}|[A-Za-z_][A-Za-z0-9_]*)$/) return 0
        T_TOKEN = "STEP-" run
        T_NUM = ""
        T_END = pos + length(run)
        T_LEAF = (own_mode == "known" && run ~ ("^" own "-([A-Za-z0-9_.,@%+:-]|[$][A-Za-z_][A-Za-z0-9_]*|[$][{][A-Za-z_][A-Za-z0-9_]*[}])*$"))
        return 1
    }
    id = run
    suffix = ""
    dot = index(run, ".")
    if (dot > 0) {
        id = substr(run, 1, dot - 1)
        suffix = substr(run, dot + 1)
    }
    if (id != "" && (id ~ /^[0-9]+$/ || id ~ /[*?[{}]/)) {
        if (suffix ~ /^([Dd]|\[[^]]*\]|\?|\*)([^A-Za-z0-9_.]|$)/ || (suffix == "" && id ~ /\*$/)) {
            sub(/[^A-Za-z0-9_.\[\]?*].*$/, "", suffix)
            T_TOKEN = "STEP-" id (suffix == "" ? "" : "." suffix)
            T_NUM = (id ~ /^[0-9]+$/) ? id : ""
            T_END = pos + length(run)
            return 1
        }
    }
    # Not a token here; look further along the word.
    sub_ok = scratch_token(rest)
    if (sub_ok) { T_END = T_END + pos - 1; return 1 }
    return 0
}
# Does w name a scratch dir that is not the callers own? With own_mode
# "none" every token is foreign; with "known", a token whose id differs, an
# expansion, glob or brace id, and the own dir followed by a `..` component
# all are. An own-file leaf (T_LEAF) after the own dir is not.
function foreign_scratch(w, docket_arg,   rest, any_own) {
    rest = w
    any_own = 0
    while (scratch_token(rest, docket_arg)) {
        if (any_own && T_LEAF) { rest = substr(rest, T_END); continue }
        if (own_mode == "none" || T_NUM == "" || T_NUM != own) return 1
        any_own = 1
        rest = substr(rest, T_END)
    }
    if (any_own && match(w, DOTDOT_RE)) return 1
    return 0
}
# A worktree operand the caller may remove or move: inside its own scratch
# dir, naming no other step, with no `..` component.
function own_path(w,   rest, n) {
    if (own_mode != "known") return 0
    if (match(w, DOTDOT_RE)) return 0
    n = 0
    rest = w
    while (scratch_token(rest)) {
        if (T_NUM == "" || T_NUM != own) return 0
        n++
        rest = substr(rest, T_END)
    }
    return n > 0
}
function own_ref(w,   lw) {
    if (own_mode != "known") return 0
    lw = tolower(w)
    return match(lw, "(^|[^0-9a-z])step-" own "([^0-9]|$)") > 0
}
# A path into a harness checkout (`.claude/worktrees/<name>` or
# `.git/worktrees/<name>`) that is not the callers own cwd.
function foreign_checkout(w,   p, c) {
    if (!match(w, /(^|\/)\.(claude|git)\/worktrees\/[^\/]+/)) return 0
    p = substr(w, RSTART, RLENGTH)
    sub(/^\//, "", p)
    if (cwd == "") return 1
    c = cwd
    if (!match(c, /(^|\/)\.(claude|git)\/worktrees\/[^\/]+/)) return 1
    c = substr(c, RSTART, RLENGTH)
    sub(/^\//, "", c)
    return p != c
}
function report(clause, detail) {
    printf "%s\t%s\n", clause, detail
    exit
}
# ENGINE: `docket step reap` and `docket run conduct`, past docket own global
# flags, for the docket word at vi.
function engine_check(vi, n,   j, k, dq, dg, sq, sg, sw, vq, vg, vw) {
    j = vi + 1
    while (j <= n) {
        if (words[j] == "") { j++; continue }
        decode(words[j])
        if (D_WORD !~ /^-/) break
        if (D_WORD == "--format" || D_WORD == "--interval") { j += 2 } else { j++ }
    }
    k = j + 1
    while (k <= n && words[k] == "") k++
    if (j > n || k > n) return
    dq = decode(words[vi]); dg = D_GROUP
    sq = decode(words[j]); sg = D_GROUP; sw = tolower(D_WORD)
    sub(/[^a-z0-9_-].*$/, "", sw)
    vq = decode(words[k]); vg = D_GROUP; vw = tolower(D_WORD)
    sub(/[^a-z0-9_-].*$/, "", vw)
    if (sw == "step" && vw == "reap" && !(dq && sq && vq && dg == sg && sg == vg && !interp)) report("ENGINE", "docket step reap")
    if (sw == "run" && vw == "conduct" && !(dq && sq && vq && dg == sg && sg == vg && !interp)) report("ENGINE", "docket run conduct")
}
# PROCESS and ENGINE for the word at vi read as a verb: a name-addressed kill,
# or docket with an engine verb.
function protected_at(vi, n,   v) {
    decode(words[vi])
    v = head_of(D_WORD)
    if (v == "pkill" || v == "killall" || v == "killall5") report("PROCESS", v)
    if (v == "docket") engine_check(vi, n)
}
# After `repeat` the verb may be any later word (see verb_index), so each
# word from the count on that is not prose is read as a verb by protected_at.
function repeat_scan(from, n,   j) {
    for (j = from; j <= n; j++) {
        if (words[j] == "") continue
        if (decode(words[j]) && gsize[D_GROUP] >= 2 && !interp) continue
        protected_at(j, n)
    }
}
# The commands inside a substitution on this line. bash 5.2 reprints a `$( )`
# body onto its opener line (`echo $(\npkill node\n)` reaches the probe as
# `echo $(pkill node)`), and a body written on one line never reached the
# matcher as a leaf of its own on any bash. So the head of an unquoted word
# that opens a substitution, or that follows a separator once one is open, is
# a verb too, for the name-addressed kills and the engine verbs. A quoted
# word stays data: the pre-pass leaves a `$( )` inside double quotes
# unmarked, since bash runs it, and marks one inside single quotes.
function nested_verbs(n,   i, w, opened, after_sep, vi) {
    opened = 0
    after_sep = 0
    for (i = 1; i <= n; i++) {
        if (words[i] == "") continue
        if (decode(words[i])) { after_sep = 0; continue }
        w = D_WORD
        if (w ~ /\$\(|\140|[<>]\(/) opened = 1
        if (opened && (after_sep || w ~ /\$\(|\140|[<>]\(|[;|&]/)) {
            vi = verb_index(n, i)
            if (REPEAT_FROM) repeat_scan(REPEAT_FROM, n)
            if (vi > 0) protected_at(vi, n)
        }
        after_sep = (opened && w ~ /[;|&(]$/)
    }
}
{
    lines[NR] = $0
    n = split($0, words, /[ \t]+/)
    for (i = 1; i <= n; i++) {
        if (words[i] == "") continue
        decode(words[i])
        h = head_of(D_WORD)
        if (h == "ps" || h == "pgrep" || h == "pidof" || h == "lsof" || h == "fuser" || h == "ss" || h == "netstat" || h == "top" || h == "htop" || h == "procs") discovery = 1
    }
}
END {
    for (ln = 1; ln <= NR; ln++) {
        n = split(lines[ln], words, /[ \t]+/)
        # Group sizes: a quoted span of two or more words is prose, unless an
        # interpreter heads a leaf somewhere in this command.
        delete gsize
        for (i = 1; i <= n; i++) {
            if (words[i] == "") continue
            if (decode(words[i])) gsize[D_GROUP]++
        }
        vi = verb_index(n)
        repeat_from = REPEAT_FROM
        verb = ""
        if (vi > 0) { decode(words[vi]); verb = head_of(D_WORD) }
        # A substitution in the leaf is a command the probe vetoed along
        # with the leaf, so its words never reach the matcher as their own
        # leaf: no word of such a leaf is a docket argument.
        docket_leaf = (verb == "docket" && lines[ln] !~ /\$\(|\140|[<>]\(|\$\{[ \t|]/)
        negated = 0
        prev_redirect = 0
        prev_redirect_op = 0
        for (i = 1; i <= n; i++) {
            if (words[i] == "") continue
            quoted = decode(words[i])
            w = D_WORD
            prose = (quoted && gsize[D_GROUP] >= 2 && !interp)
            if (prose) continue
            # SCRATCH: any word naming a strangers scratch dir; a `find`
            # negating the own name reaches every stranger at once.
            if (own_mode != "unknown") {
                if (foreign_scratch(w, docket_leaf && !prev_redirect_op)) report("SCRATCH", T_TOKEN)
                if (verb == "find" && (w == "!" || w == "-not")) negated = 1
                if (verb == "find" && negated && own_mode == "known" && scratch_token(w) && T_NUM == own) report("SCRATCH", "everything but " T_TOKEN)
            }
            # WORKTREE by path: a destructive head, or an output or read-write
            # (`<>`) redirection, aimed at another checkout.
            if ((verb == "rm" || verb == "rmdir" || verb == "mv") && foreign_checkout(w)) report("WORKTREE", verb " " w)
            if (foreign_checkout(w) && (w ~ /^[0-9]*<?>/ || w ~ /^&>/ || prev_redirect)) report("WORKTREE", "write into " w)
            prev_redirect = (w ~ /^[0-9]*(>{1,2}\|?|<>)$/ || w ~ /^&>>?$/)
            # Any standalone redirect operator (`<`, `<>`, `>&`, `3<>`,
            # `{fd}>`): the word after it is a file the shell opens, not a
            # docket argument.
            prev_redirect_op = (w ~ /^([0-9]*|\{[A-Za-z_][A-Za-z0-9_]*\})[<>&|]*[<>][<>&|-]*$/)
        }
        nested_verbs(n)
        if (repeat_from) repeat_scan(repeat_from, n)
        if (vi == 0) continue
        protected_at(vi, n)
        # PROCESS: kill by literal pid.
        if (verb == "kill") {
            listing = 0; probe_only = 0; dashdash = 0; signalled = 0; nops = 0
            for (j = vi + 1; j <= n; j++) {
                if (words[j] == "") continue
                decode(words[j])
                x = D_WORD
                if (!dashdash && x == "--") { dashdash = 1; continue }
                if (!dashdash && x ~ /^-/) {
                    if (x ~ /^[-+][0-9]+$/ && signalled) { ops[++nops] = x; continue }
                    if (x == "-l" || x == "-L") listing = 1
                    if (x == "-0") probe_only = 1
                    if (x == "-s" || x == "-n") {
                        j++
                        while (j <= n && words[j] == "") j++
                        if (j <= n) { decode(words[j]); if (D_WORD == "0") probe_only = 1 }
                    }
                    signalled = 1
                    continue
                }
                ops[++nops] = x
            }
            if (!listing && !probe_only) {
                for (k = 1; k <= nops; k++) {
                    x = ops[k]
                    if (x ~ /^%/) continue
                    if (x ~ /^[-+]?[0-9]+$/) report("PROCESS", "kill " x)
                    if (x ~ /^\$\(\(/) report("PROCESS", "kill " x)
                    if (x ~ /^\$\((echo|printf)$/) report("PROCESS", "kill on an echoed literal")
                    if (x ~ /^\$/ && discovery) report("PROCESS", "kill on the result of a process lookup")
                }
            }
            delete ops
        }
        # WORKTREE and BRANCH: git, past its global options.
        if (verb == "git") {
            j = vi + 1
            while (j <= n) {
                if (words[j] == "") { j++; continue }
                decode(words[j])
                opt = D_WORD
                if (opt !~ /^-/) break
                if (opt == "-c" || opt == "-C" || opt == "--git-dir" || opt == "--work-tree" || opt == "--exec-path" || opt == "--namespace" || opt == "--super-prefix" || opt == "--config-env" || opt == "--attr-source") {
                    if (opt == "-c") {
                        k = j + 1
                        while (k <= n && words[k] == "") k++
                        if (k <= n) { decode(words[k]); if (tolower(D_WORD) ~ /^alias\./) report("WORKTREE", "git -c " D_WORD) }
                    }
                    j += 2
                } else {
                    if (tolower(opt) ~ /^-c=?alias\./ || tolower(opt) ~ /^--config=alias\./) report("WORKTREE", "git " opt)
                    j += 1
                }
            }
            if (j > n) continue
            decode(words[j])
            sw = tolower(D_WORD)
            sub(/[^a-z0-9_-].*$/, "", sw)
            if (sw == "worktree") {
                wverb = ""
                for (k = j + 1; k <= n; k++) {
                    if (words[k] == "") continue
                    decode(words[k])
                    if (D_WORD ~ /^-/) continue
                    wverb = tolower(D_WORD)
                    sub(/[^a-z0-9_-].*$/, "", wverb)
                    break
                }
                if (wverb == "prune") report("WORKTREE", "prune")
                if (wverb == "remove" || wverb == "move") {
                    for (m = k + 1; m <= n; m++) {
                        if (words[m] == "") continue
                        decode(words[m])
                        if (D_WORD ~ /^-/) continue
                        if (own_mode != "unknown" && !own_path(D_WORD)) report("WORKTREE", wverb " " D_WORD)
                    }
                }
            } else if (sw == "branch" || sw == "update-ref" || sw == "symbolic-ref" || sw == "push") {
                deleting = 0
                nops = 0
                for (k = j + 1; k <= n; k++) {
                    if (words[k] == "") continue
                    decode(words[k])
                    x = D_WORD
                    if (x == "--delete" || (sw != "push" && x ~ /^-[A-Za-z]*[dD][A-Za-z]*$/) || (sw == "push" && x == "-d")) { deleting = 1; continue }
                    if (x ~ /^-/) continue
                    # `push <remote> :<ref>` deletes <ref> with no flag at all.
                    if (sw == "push" && x ~ /^:./) { deleting = 1; sub(/^:/, "", x); ops[++nops] = x; continue }
                    if (sw == "push" && nops == 0 && x !~ /:/) { nops++; ops[nops] = ""; continue }
                    ops[++nops] = x
                }
                if (sw == "push") { for (k = 1; k <= nops; k++) if (ops[k] == "") { for (m = k; m < nops; m++) ops[m] = ops[m + 1]; nops--; k-- } }
                if (deleting && own_mode != "unknown") {
                    for (k = 1; k <= nops; k++) {
                        if (!own_ref(ops[k])) report("BRANCH", ops[k])
                    }
                }
                delete ops
            }
        }
    }
}
' 2>/dev/null)
[ -n "$MATCH" ] || {
    [ "$OWN_MODE" = "unknown" ] && log_decision "allow" "own-unknown"
    allow_default
}

CLAUSE="${MATCH%%$'\t'*}"
DETAIL="${MATCH#*$'\t'}"

if [ "$OWN_MODE" = "known" ]; then
    OWN_TEXT="your own scratch dir is <TMP>/STEP-${OWN_STEP}.d and nothing else under the scratch root is yours to read, write, or remove"
else
    OWN_TEXT="this seat holds no step claim, so no STEP-N.d directory, worktree or branch is yours"
fi

log_decision "deny" "$CLAUSE"
case "$CLAUSE" in
    SCRATCH)
        deny "$REASON_PREFIX this command names another step's scratch directory (${DETAIL}); ${OWN_TEXT}. A sibling's leftover dir is the conductor's to sweep at reap, never an executor's. If it blocks your step, record that as a finding in your step report and do not retry. If this command performs no operation on that directory and only mentions it in prose, write the prose with the Write tool where you have it, or through a heredoc with a quoted delimiter (<<'EOF'), which this guard does not read at top level; inside a substitution it skips that body only when the body holds no quote, backtick, backslash, # or \$ and its parens balance. If a search pattern must match a step id and the command operates on no sibling directory, spell the pattern \`STEP.[0-9]+\` (with grep -E or rg), which this guard does not read as a scratch directory. If the command only hands sibling step ids to a docket read verb and touches no directory, spell each id literally (for example \`docket step artifacts STEP-7; docket step artifacts STEP-8\`). Otherwise, rewording a command that operates on another step's directory is not authorized." ;;
    WORKTREE)
        case "$DETAIL" in
            prune) deny "$REASON_PREFIX \`git worktree prune\` deletes the bookkeeping of every checkout that is momentarily absent, siblings still working included, and is never an executor's to run. Leave the worktree list as it is; the conductor sweeps checkouts after integration." ;;
            "git -c "* | "git -c="* | "git --config="*) deny "$REASON_PREFIX \`${DETAIL}\` defines a git alias for this one call; an alias can spell any worktree or branch verb, so the guard cannot read what it runs. Spell the git subcommand out." ;;
            rm\ * | rmdir\ * | mv\ * | write\ into\ *) deny "$REASON_PREFIX \`${DETAIL}\` names another checkout under .claude/worktrees or .git/worktrees; your own checkout is your working directory and nothing else there is yours to remove, move or write into. The conductor sweeps checkouts after integration; if one blocks your step, report that as a finding." ;;
            *) deny "$REASON_PREFIX \`git worktree ${DETAIL}\` names a checkout you did not create; ${OWN_TEXT}. The harness created your worktree and the conductor sweeps it after integration; a checkout outside your own <TMP>/STEP-N.d is a sibling's or the shared tree. Leave it and, if it blocks your step, report that as a finding." ;;
        esac ;;
    BRANCH)
        deny "$REASON_PREFIX deletion of the ref \`${DETAIL}\`: no branch is an executor's to delete. Your hand-back is the commit sha on your own worktree branch, and every other branch belongs to a sibling or the shared tree. Leave it and report the conflict as a finding." ;;
    ENGINE)
        case "$DETAIL" in
            "docket run conduct") deny "$REASON_PREFIX \`docket run conduct\` re-mints the run's conductor capability and retires the token the conductor driving this run holds, locking it out of its own rulings until it re-conducts. The seat is the conductor's, taken from the main conversation that drives the run; an executor is never handed the capability and has no ruling to make. If a ruling on your step looks stuck, record that as a finding in your step report." ;;
            *) deny "$REASON_PREFIX \`docket step reap\` clears another holder's claim on the assertion that the holder is dead, which only the relay that spawned it can observe; an executor reaping a sibling returns a live step to the pool under a stranger. If a sibling's claim looks stuck, record that as a finding in your step report and leave the reap to the conductor." ;;
        esac ;;
    PROCESS)
        case "$DETAIL" in
            pkill | killall | killall5) deny "$REASON_PREFIX \`${DETAIL}\` addresses processes by name across the whole machine, including sibling executors' test servers and builds. Stop only what your own call started, by jobspec (\`kill %1\`) or \`kill \$!\`, and report a port or process conflict as a finding in your step report." ;;
            *) deny "$REASON_PREFIX \`${DETAIL}\`: a pid copied from a process listing may be a sibling's process, or a whole process group. Signal only a process your own call started, by jobspec (\`kill %1\`) or \`kill \$!\`; a port or process conflict is a finding for your step report, not a target." ;;
        esac ;;
esac
deny "$REASON_PREFIX ${CLAUSE} ${DETAIL}"
