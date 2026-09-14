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
#              ever a scratch dir.
#   WORKTREE   `git worktree prune` always (it drops the bookkeeping of every
#              checkout momentarily absent, siblings still working included);
#              `git worktree remove`/`move` unless every path operand lies
#              inside the caller's own scratch dir (a throwaway probe checkout
#              the executor made itself); `git -c alias.<x>=...` (an alias
#              can spell any of these); and `rm`/`rmdir`/`mv` of a path under
#              `.claude/worktrees/` or `.git/worktrees/` that is not the
#              caller's own checkout, the checkout being its `cwd`. The
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
#              this very repository makes, and stays allowed.
#   ENGINE     `docket step reap` always, docket's own global flags skipped.
#              The verb is token-free by design (the relay that spawned a
#              holder is the seat that can observe it is dead) and clears
#              another holder's claim on that assertion; an executor cannot
#              observe a sibling at all, and a reap from one returns a live
#              step to the pool under a stranger. The token-bound verbs
#              (`record`, `fail`, `heartbeat`) reach only the caller's own
#              step and need no clause.
#
# THE SCOPE, mirroring docket-trust-guard-hook.sh and
# sandbox-bypass-guard-hook.sh: the three graph-fleet executor archetypes
# (agents/executor-{read,write,research}.md), identified by `agent_type`
# first. When `agent_type` is absent (the Workflow-spawned-seat shape the
# sandbox-bypass guard measured), the transcript's own opening is read for
# the wave executor brief marker above; nothing else puts a caller in scope.
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
#   unknown  no readable transcript: the SCRATCH, WORKTREE-path and BRANCH
#            clauses are skipped and the call is allowed, logged to
#            ~/.claude/friction so the shape gets confirmed, because denying
#            here would strand every bootstrap `rm -rf` of a real executor
#            behind a transcript-delivery gap — this hook family's direction
#            when the caller or target cannot be identified. `pkill`,
#            `killall`, `git worktree prune`, `kill <literal pid>` and `docket
#            step reap` need no own id and still deny.
#
# Exit 0 allow / exit 2 deny with reason on stderr, this hook family's
# contract: exit 2 is a pre-permission hard stop the classifier never sees,
# honored regardless of permission mode, and the reason reaches the executor
# so it reports the collision as a finding instead of retrying under another
# spelling.
#
# HOW THE COMMAND IS READ: the same two stages as docket-trust-guard-hook.sh
# and docket-commit-guard-hook.sh, whose headers carry the full reasoning.
# Stage one asks bash itself which simple commands it would dispatch (a DEBUG
# trap under `extdebug` and `set -T` that vetoes every leaf), so chains,
# subshells, substitutions, heredocs and comments are bash's parse and not a
# re-derivation of it; stage two is the shared quote-group pre-pass
# (docket-guard-prepass.awk) that tells a quoted prose span from
# separately-quoted words and unmarks an interpreter's code argument (`bash -c
# '...'`) so the words inside it are read as the invocation they are. A word
# inside a quoted group of two or more words is prose here; a lone quoted
# path (`rm -rf "<TMP>/STEP-7.d"`) is not; and when any leaf is headed by an
# interpreter, no quoted group is prose at all — `echo "rm -rf ..." | sh` and
# `sh <<< "rm -rf ..."` carry code in a string exactly as a heredoc does, and
# the pre-pass's heredoc rule is applied to strings for the same reason.
#
# THE PROBE HARDENING, measured on bash 3.2 and pinned in the suite, where
# this hook's probe departs from the copy the two sibling guards run:
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
#     distinct exit code, a compound redirect fails under the restriction
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
#     as prose — `eval` is on the interpreter list for the same reason.
#   - `break` and `continue` RUN, so loops end where the real command's
#     would; `exit` and `return` stay vetoed so the caller cannot choose the
#     probe's exit status. The cap EXITS the probe (nothing runs after it)
#     instead of disarming the trap, and is checked before the empty-walk
#     allow: `<2001 structural commands>; rm -rf <dir>` had capped with an
#     empty leaf list and fallen through to allow.
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
# the permission text clears it for every session), `fuser -k`, and a pid
# read from a file under another checkout. An unquoted-delimiter heredoc body
# or an unquoted argument that merely mentions a sibling's `STEP-M.d` in
# prose is a false DENY, and the deny reason names a quoted delimiter as the
# way to write such prose; a quoted-delimiter heredoc body is never read,
# whatever words it carries, because the interpreter test that widens a body
# into the scan reads leaf heads only — a findings artifact that mentions
# `node`, `sh` or `.env` in passing is the sanctioned record path for
# executor-read and executor-research, which have no Write tool.
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
        --argjson payload_keys "$keys" \
        '{at:$at, hook:"docket-sibling-guard", decision:$decision, clause:$clause, detected_via:$detected_via, agent_type:$agent_type, own_mode:$own_mode, own_step:$own_step, session:$session, payload_keys:$payload_keys}' \
        >>"$FRICTION_LOG" 2>/dev/null || true
}

# Reads the opening of the caller's transcript for the wave executor brief
# marker and sets OWN_STEP (the digits of STEP-N) and OWN_MODE
# (known|none|unknown). Bounded: at most 64 KiB, read with `read -n` so a
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
    [ -n "$t" ] && [ -r "$t" ] && [ -f "$t" ] || return 0
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

INPUT=$(cat 2>/dev/null) || allow_default
[ -n "$INPUT" ] || allow_default

command -v jq >/dev/null 2>&1 || allow_default

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null) || allow_default
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null) || TRANSCRIPT_PATH=""
CALLER_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null) || CALLER_CWD=""

OWN_STEP=""
OWN_MODE="unknown"
DETECTED_VIA=""
if is_executor_archetype "$AGENT_TYPE"; then
    DETECTED_VIA="agent_type"
    scan_transcript "$TRANSCRIPT_PATH"
elif [ -z "$AGENT_TYPE" ]; then
    # Unidentified caller: only a transcript that opens with a wave executor
    # brief puts it in scope. The main conversation, whose first message is
    # the operator's, never carries that exact spelling.
    scan_transcript "$TRANSCRIPT_PATH"
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
# printed as \035<text>\036 frames on stdout; bash's stderr is merged into
# the same capture and recovered from between the frames. Exit codes: 113
# the cap, 114 a redirection on a structural builtin. The caller cannot pick
# either: `exit` and `return` are vetoed, and a vetoed leaf reports success.
PROBE_RAW=$(printf '%s' "$COMMAND" | bash -c '
    shopt -s extdebug
    set -T
    COMMAND=$(cat)
    n=0
    _guard_probe() {
        n=$((n + 1))
        if [ "$n" -gt 2000 ]; then
            exit 113
        fi
        # The first firing is this probe own eval line, not a leaf of the
        # command; recording it would put an interpreter word in every walk.
        if [ "$n" -eq 1 ] && [ "$BASH_COMMAND" = "eval \"\$COMMAND\"" ]; then
            return 0
        fi
        local head="${BASH_COMMAND%%[ $'"'"'\t\n'"'"']*}"
        head="${head##*/}"
        case "$head" in
            for | select | case | eval)
                case "$BASH_COMMAND" in
                    *[\<\>]*) exit 114 ;;
                esac
                printf "\035%s\036" "$BASH_COMMAND"
                return 0 ;;
            while | until | if | elif | else | fi | then | do | done | \
            esac | function | time | "{" | "}" | "[" | "[[" | : | \
            true | false | break | continue)
                case "$BASH_COMMAND" in
                    *[\<\>]*) exit 114 ;;
                esac
                return 0 ;;
        esac
        printf "\035%s\036" "$BASH_COMMAND"
        if declare -F "$head" >&9 2>&9; then
            return 0
        fi
        return 1
    }
    readonly -f _guard_probe
    exec 9>/dev/null
    set -r
    trap _guard_probe DEBUG
    eval "$COMMAND"
' 2>&1)
PROBE_RC=$?

if [ "$PROBE_RC" -eq 113 ]; then
    log_decision "deny" "oversized"
    deny "$REASON_PREFIX this command has too many parts (over 2000) for the sibling-guard hook to finish checking it. Split it into smaller Bash calls; a single call this large is refused rather than passed through unchecked."
fi
if [ "$PROBE_RC" -eq 114 ]; then
    log_decision "deny" "structural-redirect"
    deny "$REASON_PREFIX a redirection on a shell builtin that carries no command (\`: > file\`, \`true > file\`, \`[ ... ] > file\`) cannot be checked for a sibling's path. Truncate or create a file with \`cat /dev/null > <path>\`, so the target is a visible operand."
fi

# Leaves are the framed segments; everything outside a frame is bash's own
# stderr during the walk.
PROBE_TEXT=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s\036", substr($0, i + 1) }')
PROBE_ERR=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s", substr($0, 1, i - 1); else printf "%s", $0 }')

case "$PROBE_ERR" in
    *"restricted: cannot redirect output"*)
        log_decision "deny" "compound-redirect"
        deny "$REASON_PREFIX a redirection on a compound command (\`{ ... } > file\`, \`( ... ) > file\`, a loop or \`if\` followed by \`> file\`, or a function call \`> file\`) hides its target from this check. Redirect each simple command's output on its own, e.g. \`cargo build > <TMP>/STEP-N.d/build.log 2>&1\`." ;;
    *"readonly function"*)
        log_decision "deny" "probe-tamper"
        deny "$REASON_PREFIX this command redefines the sibling-guard hook's own probe handler (\`_guard_probe\`). No executor command needs a function by that name; rename it." ;;
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

# --- Widening: where a heredoc's body stops being inert data. ------------
#
# The trust guard's two triggers, with one correction: the interpreter test
# reads each leaf's FIRST LINE only. An interpreter that consumes a heredoc is
# always a command word, never body text; reading bodies too made an artifact
# that mentioned `node` or `.env` widen itself, and its prose was then
# matched — the sanctioned record path for the two archetypes with no Write
# tool. An unquoted heredoc delimiter still widens its own leaf, since that
# body is expanded before its consumer ever sees it.
INTERPRETER_RE='(^|[^A-Za-z0-9_])(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|tclsh|expect|osascript|env|eval)([^A-Za-z0-9_]|$)'
FIRST_LINES=$(printf '%s' "$PROBE_TEXT" | awk 'BEGIN { RS = "\036"; ORS = "" } { eol = index($0, "\n"); printf "%s\n", (eol == 0 ? $0 : substr($0, 1, eol - 1)) }')
WIDEN=0
if [[ "$FIRST_LINES" =~ $INTERPRETER_RE ]]; then
    WIDEN=1
fi

SCAN_TEXT=$(printf '%s' "$PROBE_TEXT" | awk -v RS='\036' -v widen="$WIDEN" '
    BEGIN { out = "" }
    {
        leaf = $0
        if (leaf == "") next
        eol = index(leaf, "\n")
        line1 = (eol == 0 ? leaf : substr(leaf, 1, eol - 1))
        leaf_widen = (widen == "1")
        if (!leaf_widen && line1 ~ /<</ && line1 !~ /<<-?[ \t]*[\x27\x22\\]/) {
            leaf_widen = 1
        }
        if (leaf_widen) {
            out = out leaf "\n"
        } else {
            out = out line1 "\n"
        }
    }
    END { printf "%s", out }
')

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
# by construction since a literal own id is never spelled that way. The id
# is compared whole: `STEP-93` and `STEP-9393` are different steps.
MATCH=$(printf '%s' "$STRIPPED" | awk -v own="$OWN_STEP" -v own_mode="$OWN_MODE" -v interp="$WIDEN" -v cwd="$CALLER_CWD" '
BEGIN {
    MARK = "\001"
    DOTDOT_RE = "(^|/)\\.\\.(/|$)"
    discovery = 0
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
# onto its front is stripped (`;rm`, `(rm`, `$(rm`), then the directory,
# then case.
function head_of(w,   h) {
    h = w
    sub(/^.*(\$\(|\140|\(|;|\||&)/, "", h)
    sub(/^.*\//, "", h)
    return tolower(h)
}
function is_wrapper(h) {
    return (h == "sudo" || h == "doas" || h == "command" || h == "builtin" || h == "exec" || h == "xargs" || h == "nohup" || h == "nice" || h == "ionice" || h == "timeout" || h == "env" || h == "time" || h == "setsid" || h == "stdbuf" || h == "caffeinate" || h == "chronic" || h == "unbuffer")
}
# The verb position of a leaf: the first word, then past any wrapper and the
# wrapper own options, values (`-n 5`, `5s`, `FOO=1`) and flags.
function verb_index(n,   i, h) {
    i = 1
    while (i <= n && words[i] == "") i++
    if (i > n) return 0
    decode(words[i])
    h = head_of(D_WORD)
    while (is_wrapper(h)) {
        i++
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
# word.
function scratch_token(w,   pos, rest, run, id, suffix, dot, sub_ok) {
    T_END = 0
    if (!match(w, /[Ss][Tt][Ee][Pp]-/)) return 0
    pos = RSTART + RLENGTH
    rest = substr(w, pos)
    run = rest
    sub(/\/.*$/, "", run)
    if (run ~ /[$`(]/) {
        T_TOKEN = "STEP-" run
        T_NUM = ""
        T_END = pos + length(run)
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
# all are.
function foreign_scratch(w,   rest, any_own) {
    rest = w
    any_own = 0
    while (scratch_token(rest)) {
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
        verb = ""
        if (vi > 0) { decode(words[vi]); verb = head_of(D_WORD) }
        negated = 0
        for (i = 1; i <= n; i++) {
            if (words[i] == "") continue
            quoted = decode(words[i])
            w = D_WORD
            prose = (quoted && gsize[D_GROUP] >= 2 && !interp)
            if (prose) continue
            # SCRATCH: any word naming a strangers scratch dir; a `find`
            # negating the own name reaches every stranger at once.
            if (own_mode != "unknown") {
                if (foreign_scratch(w)) report("SCRATCH", T_TOKEN)
                if (verb == "find" && (w == "!" || w == "-not")) negated = 1
                if (verb == "find" && negated && own_mode == "known" && scratch_token(w) && T_NUM == own) report("SCRATCH", "everything but " T_TOKEN)
            }
            # WORKTREE by path: a destructive head aimed at another checkout.
            if ((verb == "rm" || verb == "rmdir" || verb == "mv") && foreign_checkout(w)) report("WORKTREE", verb " " w)
        }
        if (vi == 0) continue
        # ENGINE: `docket step reap`, past docket own global flags.
        if (verb == "docket") {
            j = vi + 1
            while (j <= n) {
                if (words[j] == "") { j++; continue }
                decode(words[j])
                if (D_WORD !~ /^-/) break
                if (D_WORD == "--format" || D_WORD == "--project") { j += 2 } else { j++ }
            }
            k = j + 1
            while (k <= n && words[k] == "") k++
            if (j <= n && k <= n) {
                dq = decode(words[vi]); dg = D_GROUP
                sq = decode(words[j]); sg = D_GROUP; sw = tolower(D_WORD)
                sub(/[^a-z0-9_-].*$/, "", sw)
                vq = decode(words[k]); vg = D_GROUP; vw = tolower(D_WORD)
                sub(/[^a-z0-9_-].*$/, "", vw)
                if (sw == "step" && vw == "reap" && !(dq && sq && vq && dg == sg && sg == vg && !interp)) report("ENGINE", "docket step reap")
            }
        }
        # PROCESS: name-addressed kills, and kill by literal pid.
        if (verb == "pkill" || verb == "killall" || verb == "killall5") report("PROCESS", verb)
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
        deny "$REASON_PREFIX this command names another step's scratch directory (${DETAIL}); ${OWN_TEXT}. A sibling's leftover dir is the conductor's to sweep at reap, never an executor's. If it blocks your step, record that as a finding in your step report and do not retry. If this command performs no operation on that directory and only mentions it in prose, write the prose through a heredoc with a quoted delimiter (<<'EOF'), which this guard does not read, or with the Write tool where you have it." ;;
    WORKTREE)
        case "$DETAIL" in
            prune) deny "$REASON_PREFIX \`git worktree prune\` deletes the bookkeeping of every checkout that is momentarily absent, siblings still working included, and is never an executor's to run. Leave the worktree list as it is; the conductor sweeps checkouts after integration." ;;
            "git -c "* | "git -c="* | "git --config="*) deny "$REASON_PREFIX \`${DETAIL}\` defines a git alias for this one call; an alias can spell any worktree or branch verb, so the guard cannot read what it runs. Spell the git subcommand out." ;;
            rm\ * | rmdir\ * | mv\ *) deny "$REASON_PREFIX \`${DETAIL}\` names another checkout under .claude/worktrees or .git/worktrees; your own checkout is your working directory and nothing else there is yours to remove or move. The conductor sweeps checkouts after integration; if one blocks your step, report that as a finding." ;;
            *) deny "$REASON_PREFIX \`git worktree ${DETAIL}\` names a checkout you did not create; ${OWN_TEXT}. The harness created your worktree and the conductor sweeps it after integration; a checkout outside your own <TMP>/STEP-N.d is a sibling's or the shared tree. Leave it and, if it blocks your step, report that as a finding." ;;
        esac ;;
    BRANCH)
        deny "$REASON_PREFIX deletion of the ref \`${DETAIL}\`: no branch is an executor's to delete. Your hand-back is the commit sha on your own worktree branch, and every other branch belongs to a sibling or the shared tree. Leave it and report the conflict as a finding." ;;
    ENGINE)
        deny "$REASON_PREFIX \`docket step reap\` clears another holder's claim on the assertion that the holder is dead, which only the relay that spawned it can observe; an executor reaping a sibling returns a live step to the pool under a stranger. If a sibling's claim looks stuck, record that as a finding in your step report and leave the reap to the conductor." ;;
    PROCESS)
        case "$DETAIL" in
            pkill | killall | killall5) deny "$REASON_PREFIX \`${DETAIL}\` addresses processes by name across the whole machine, including sibling executors' test servers and builds. Stop only what your own call started, by jobspec (\`kill %1\`) or \`kill \$!\`, and report a port or process conflict as a finding in your step report." ;;
            *) deny "$REASON_PREFIX \`${DETAIL}\`: a pid copied from a process listing may be a sibling's process, or a whole process group. Signal only a process your own call started, by jobspec (\`kill %1\`) or \`kill \$!\`; a port or process conflict is a finding for your step report, not a target." ;;
        esac ;;
esac
deny "$REASON_PREFIX ${CLAUSE} ${DETAIL}"
