#!/bin/bash

# commit-guard (03 §5, TDD §4.5) — PreToolUse: Bash.
#
# Shim over `docket guard gate --step commit-gate`: `git commit/push/add` only
# behind an APPROVED human gate. The decision is the engine's; this hook holds
# no policy about which commits are acceptable.
#
# WHY THIS FILE IS NOT ONE LINE (deviation from AC-4.1's "one-line shim", argued
# rather than assumed). 03 §5 is explicit that this hook "replaces the 13KB awk-
# parser hook's job with an engine query" while "the awk hardening is RETAINED
# as the parser". Those are two statements about two different halves: the
# DECISION moves into the engine, the MATCHER stays. A literally-one-line
# `exec docket guard gate --step commit-gate` would deny every Bash call in the
# session, because the engine correctly denies when the gate is merely ABSENT
# ([OBSERVED] `no type="human" step named "commit-gate" in any active run`
# → exit 2). The matcher is what decides whether the engine is even the right
# question to ask. This file's behavior is pinned by
# tests/docket-commit-guard-hook.test.sh.
#
# THE DECISION, and how it differs from the old fleet's. The old hook resolves
# on permission_mode: interactive modes get an `ask`, non-interactive modes get
# a hard deny, because a human must confirm each git write and in `auto` no
# human is at the prompt. The graph fleet answers that same question from engine
# state instead: an approved `commit-gate` step IS the recorded human decision,
# so it authorizes the write in any permission mode. That is the whole point of
# re-keying to engine truth — the approval happened, durably, at gate-approval
# time rather than at prompt time.
#
# Exit 0 allow / exit 2 deny with reason on stderr, matching the old hook's
# choice of exit 2 over a permissionDecision envelope: exit 2 is a
# pre-permission hard stop whose interaction with bypassPermissions is defined,
# and the guard family's native contract is already exit 0/2 (engine-spec §2).
#
# Fail-OPEN on a missing `docket` binary, fail-CLOSED on everything the engine
# itself judges. A tooling gap must not brick every Bash call in the session;
# an unapproved or absent gate must.
#
# THE MATCHER — leaf enumeration, widening, and quote-group marking below —
# is shared with docket-trust-guard-hook.sh; see that file's header for the
# redesign rationale this replaces. Two parts differ: this file selects
# each leaf's code lines through docket-guard-leaf-lines.awk, where the
# trust-guard scans a leaf's first line (see the widening comment), and this
# file's MATCH step looks for `git commit`/`push`/`add`, with git's own
# `-C`/`-c`/`--git-dir` global-option skipping and its
# option-before-subcommand help exemption, where the trust-guard's looks
# for `docket trust add`/`rm`. This hook also
# carries no `agent_type` scoping — unlike the executor-only trust-guard, a
# git write needs an approved gate from ANY caller, main conversation
# included, matching the old fleet's own scope.

set -uo pipefail

allow_default() {
    exit 0
}

# Exit 2 is a pre-permission hard stop: it blocks the tool call before
# permission rules/mode are evaluated at all, unlike a JSON
# permissionDecision:"deny" whose interaction with bypassPermissions mode is
# undocumented. Used for every deny path below so the block holds regardless
# of permission mode.
deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

# --- Wall-clock bound. ----------------------------------------------------
#
# The harness cancels a hook that reaches its registered timeout (600 s) and
# then runs the Bash call unchecked, so a check that outlived the timeout
# would fail open. This hook therefore runs its whole check in a child copy
# of itself under a wall-clock bound of DOCKET_GUARD_BOUND_SECONDS seconds
# (default 60; a value other than a whole number from 1 to 300 reads as 60)
# and denies, naming the bound, when the bound fires. The bound covers the
# engine query too, so an engine call that hangs past it also denies.
# A CPU limit (`ulimit -t`) would not do: it is per process, and a probe walk
# that forks starts each subshell on a fresh budget. The bound uses bash
# builtins alone, since this hook's dependency set is bash/cat/jq/awk.
# `set -m` puts the pipeline below in a process group of its own, so the
# child and everything it starts (the probe, the awk passes, the engine
# query) share one group that this shell is outside of. The pipeline's last
# stage waits with `read -t` for the line carrying the child's exit status;
# when none arrives in time it reports the bound and kills the whole group,
# itself included, with `kill -KILL 0`. DOCKET_GUARD_BOUNDED marks the child,
# which runs the check below unchanged. docket-trust-guard-hook.sh and
# docket-sibling-guard-hook.sh carry the same bound.
if [ -z "${DOCKET_GUARD_BOUNDED:-}" ]; then
    GUARD_BOUND=${DOCKET_GUARD_BOUND_SECONDS:-60}
    case $GUARD_BOUND in
        [1-9] | [1-9][0-9] | [12][0-9][0-9] | 300) ;;
        *) GUARD_BOUND=60 ;;
    esac
    INPUT=$(cat 2>/dev/null) || allow_default
    exec 4>&1 5>&2
    GUARD_STATUS=$(
        set -m
        {
            printf '%s' "$INPUT" | DOCKET_GUARD_BOUNDED=1 "$BASH" "$0" >&4 2>&5 4>&- 5>&-
            printf '%s\n' "${PIPESTATUS[1]}"
        } | {
            if read -t "$GUARD_BOUND" -r guard_rc; then
                printf '%s' "$guard_rc"
                exit 0
            fi
            printf 'bound'
            kill -KILL 0
        }
    ) 2>/dev/null
    case $GUARD_STATUS in
        bound) deny "git write blocked: the commit-guard hook did not finish checking this command within its ${GUARD_BOUND} s wall-clock bound (DOCKET_GUARD_BOUND_SECONDS), so the command is refused rather than passed through unchecked. Split it into smaller Bash calls." ;;
        [0-9] | [0-9][0-9] | [0-9][0-9][0-9]) exit "$GUARD_STATUS" ;;
    esac
    exit 1
fi

INPUT=$(cat 2>/dev/null) || allow_default

if ! command -v jq >/dev/null 2>&1; then
    allow_default
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default
# Install integrity before anything else: a hook copy with no sibling lexer
# file cannot decide whether a git write is present and must fail CLOSED,
# whatever the engine would say.
HOOK_DIR="${0%/*}"
[ "$HOOK_DIR" = "$0" ] && HOOK_DIR="."   # bare-name invocation: no slash to strip
PREPASS_AWK="${HOOK_DIR}/docket-guard-prepass.awk"
[ -r "$PREPASS_AWK" ] || deny "git write blocked: the commit-guard hook's shared pre-pass file (docket-guard-prepass.awk) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."
LEAF_LINES_AWK="${HOOK_DIR}/docket-guard-leaf-lines.awk"
[ -r "$LEAF_LINES_AWK" ] || deny "git write blocked: the commit-guard hook's shared line-selection file (docket-guard-leaf-lines.awk) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."
PROBE_SH="${HOOK_DIR}/docket-guard-probe.sh"
[ -r "$PROBE_SH" ] && PROBE_PROGRAM=$(<"$PROBE_SH") && [ -n "$PROBE_PROGRAM" ] || deny "git write blocked: the commit-guard hook's shared probe file (docket-guard-probe.sh) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."

# ENGINE FIRST, PROBE ONLY WHEN A GATE STANDS. The gate query below is one
# cheap engine call; the DEBUG-trap probe further down is about a dozen
# processes per Bash call. No workflow in the shared corpus declares a
# `commit-gate` step today, so before this ordering every git write in
# every session paid the full probe and then allowed on the not-applicable
# arm. Now an absent or approved gate allows here, and the probe runs only
# to decide whether THIS command is a git write against a standing,
# unapproved gate.
# --- The decision: engine gate query, replacing the old hook's permission_mode
# --- case split. See this file's header for why an approved gate authorizes the
# --- write in any permission mode.
command -v docket >/dev/null 2>&1 || allow_default

if docket guard gate --step commit-gate >/dev/null 2>&1; then
    allow_default
fi

GATE_REASON=$(docket guard gate --step commit-gate 2>&1 >/dev/null) || true
[ -n "$GATE_REASON" ] || GATE_REASON="no approved commit-gate step in any active run"

# NOT-APPLICABLE IS NOT A DENIAL. [OBSERVED] internal/engine/guard.go:138-147 —
# the engine returns exactly three verdicts, and only ONE of them is this
# guard's business:
#
#   approved -> allow                                            (handled above)
#   found    -> `gate "commit-gate" in <RUN> is <state>, not approved`  (DENY: the case
#               this guard exists for — a run whose pipeline HAS a commit-gate
#               step that the operator has not yet approved)
#   default  -> `no type="human" step named "commit-gate" in any active run`
#               (ALLOW: the gate is ABSENT, not unapproved)
#
# The `default` arm is reached by a single query (`:101-108`) that joins steps
# to runs WHERE the run is active AND the step name matches AND kind=human. So
# ONE reason string covers two situations that are both "this guard has no
# opinion": no active run at all, and an active run whose pipeline simply has
# no commit-gate step (a retro or investigation pipeline, say). Denying either
# would brick every git write in a session that is not conducting a
# commit-bearing pipeline — which is exactly what the operator's no-run check
# found.
#
# Allowing here adds no guard where the engine declined to give one: under this
# repo's auto-mode allow rules (src/user/claude_code.rs, AUTO_MODE_ALLOW_RULES)
# `git add` and `git commit` are auto-allowed, so an absent gate means a commit
# no hook checks, by design, not a permission ask.
# "no docket database found" joins the not-applicable set for the same reason
# as the absent-gate arm: no DB means no run means this guard has no opinion.
# The engine fix has landed: every guard verb now ALLOWS with no store (exit 0,
# "no docket database at ...; nothing here to allow or deny" on stderr), so
# this arm is reached only by an older binary that still denied with exit 2.
# It stays as the mitigation for that binary.
case $GATE_REASON in
    *'in any active run'*) allow_default ;;
    *'no docket database found'*) allow_default ;;
esac


# --- Leaf enumeration: ask bash, don't re-derive it. ---------------------
#
# PROBE_TEXT holds every simple command bash's own grammar would dispatch,
# `\036`-framed, each possibly itself multi-line when it embeds a heredoc
# (the heredoc's body arrives as part of that ONE leaf's text, exactly as
# bash reconstructs $BASH_COMMAND). The 2000-command ceiling below (exit
# 113) is a circuit breaker against a crafted or pathological input driving
# this into a long-running loop, not a bound expected to matter for an
# ordinary call (empirically, hundreds of simple commands enumerate in
# well under a second).
#
REASON_PREFIX="git write blocked:"

if [ "${#COMMAND}" -gt 262144 ]; then
    deny "$REASON_PREFIX this command is over 256 KiB, more than the commit-guard hook will check in one call. Split it into smaller Bash calls, or write a large body with the Write tool where you have it; a single call this large is refused rather than passed through unchecked."
fi
case "$COMMAND" in
    *$'\035'* | *$'\036'*)
        deny "$REASON_PREFIX this command carries a control byte (0x1d or 0x1e) the commit-guard hook uses to frame its own analysis, so it cannot be checked. Remove the byte; no shell command needs it." ;;
esac

# --- Syntax first, on the same bytes the probe will walk. ------------------
if ! printf '%s' "$COMMAND" | bash -n >/dev/null 2>&1; then
    deny "$REASON_PREFIX the commit-guard hook could not parse this command to check it (bash reported a syntax error while analyzing it) and refuses rather than guessing. Fix the command's syntax; if it is not actually invalid, that is a hook defect to report separately."
fi

# The probe is the shared file docket-guard-probe.sh (PROBE_SH, resolved and
# checked at the top of this file), the same code docket-sibling-guard-hook.sh
# and docket-trust-guard-hook.sh run; its header states the contract and
# docket-sibling-guard-hook.sh's header (THE PROBE HARDENING) the design.
# `eval -- "$COMMAND"` inside it is how the untrusted text reaches bash as
# SOURCE rather than as a re-quoted argument: COMMAND travels on stdin, never
# through string interpolation into this script's own source, so it is parsed
# exactly once, by bash, exactly as the real Bash tool would. Leaves come back
# as \035<text>\036 frames with bash's own stderr merged around them. The
# probe refuses through a marker between the frames: 113 the cap, 114 a
# redirection on a structural builtin, 115 a branch on a value a `read` never
# read, 116 probe state in a structural leaf. An exit inside a pipeline stage
# ends only that stage, so the marker, not the exit status, is what reaches
# this hook; 113 and 114 are also read from the status as a fallback.
#
# A `read` fed by a pipe at EOF runs on its site's second firing, so a
# pipe-fed read loop ends after one walk of its body instead of walking into
# the cap. A read that has not run leaves its value unknown: the probe
# refuses a structural leaf that branches on a value (115), and this hook
# refuses a walked leaf whose command word expands a value (`$x`, a backtick)
# after a read frame, since that leaf runs whatever the input names.
PROBE_RAW=$(printf '%s' "$COMMAND" | bash -c "$PROBE_PROGRAM" 2>&1)
PROBE_RC=$?

# Leaves are the framed segments; everything outside a frame is bash's own
# stderr during the walk, the probe's refusal markers included.
PROBE_TEXT=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s\036", substr($0, i + 1) }')
PROBE_ERR=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s", substr($0, 1, i - 1); else printf "%s", $0 }')

READ_BRANCH_REASON="$REASON_PREFIX this command branches on a variable after a \`read\` in it (a \`[ ... ]\`, \`[[ ... ]]\`, \`case\`, \`for ... in\`, \`for ((...))\`, \`:\` or \`eval\` that expands a value, or a \`continue\`), or runs a command whose name expands a value (\`\$x\`) after one. The commit-guard hook feeds a read no input, so it cannot tell which commands the loop would run. An earlier lone \`read\` anywhere in the same Bash call counts too, and refuses every later test on a variable, the counted wait loop \`until [ -s f ] || [ \$n -ge N ]\` included: run that read in its own Bash call. Otherwise filter the input before the loop instead (\`cmd | grep -v '^\$' | while IFS= read -r x; do ...; done\`), or split it into smaller Bash calls."

case "$PROBE_RC:$PROBE_ERR" in
    113:* | *"_guard_probe: leaf cap"*)
        deny "$REASON_PREFIX this command has too many parts (over 2000) for the commit-guard hook to finish checking it. A wait loop ends in the check when it counts its own passes, \`n=0; until [ -s f ] || [ \$n -ge N ]; do sleep S; n=\$((n+1)); done\`, and so does a read loop fed by a pipe whose read takes no option but -r, \`cmd | while IFS= read -r x; do ...; done\` (a file, here-string or process-substitution input, or another read option, keeps it from ending); an uncounted wait never does. Otherwise split it into smaller Bash calls; a single call this large is refused rather than passed through unchecked." ;;
    114:* | *"_guard_probe: structural redirect"*)
        deny "$REASON_PREFIX a redirection on a shell builtin that carries no command (\`: > file\`, \`true > file\`, \`[ ... ] > file\`) cannot be checked for a git write. Truncate or create a file with \`cat /dev/null > <path>\`, so the target is a visible operand." ;;
    *"restricted: cannot redirect output"*)
        deny "$REASON_PREFIX a redirection on a compound command (\`{ ... } > file\`, \`( ... ) > file\`, a loop or \`if\` followed by \`> file\`, or a function call \`> file\`) hides its target from this check. Redirect each simple command's output on its own." ;;
    *"readonly function"*)
        deny "$REASON_PREFIX this command redefines the commit-guard hook's own probe handler (\`_guard_probe\`). No command needs a function by that name; rename it." ;;
    *"_guard_probe: probe state in a structural leaf"*)
        deny "$REASON_PREFIX this command names a \`_leaf_*\` variable in a command the hook runs while checking it (a \`:\`, \`true\`, \`[\` or \`[[\` command, or a \`for\`, \`select\`, \`case\` or \`eval\` header). The commit-guard hook keeps its own analysis state under that prefix, so it cannot check the command; rename the variable." ;;
    *"_guard_probe: branch on an unread value"*)
        deny "$READ_BRANCH_REASON" ;;
esac

# A walked leaf whose command word expands a value, after a read frame: the
# read stood in for input it never read, so the leaf's command is unknown.
# Leading assignment words are skipped to reach the command word. This is
# this hook's own rule; a computed command with no read before it stays the
# accepted residual pinned in the suite.
READ_COMPUTED=$(printf '%s' "$PROBE_TEXT" | awk '
BEGIN { RS = "\036"; name = "[A-Za-z_][A-Za-z0-9_]*" }
{
    leaf = $0
    if (seen_read) {
        while (match(leaf, "^" name "\\+?=[^ \t\n]*[ \t]+")) leaf = substr(leaf, RLENGTH + 1)
        if (leaf !~ "^" name "\\+?=") {
            word = leaf
            sub(/[ \t\n].*$/, "", word)
            if (word ~ /[$`]/) { print "READ_COMPUTED"; exit }
        }
    }
    if ($0 ~ "^(IFS=[A-Za-z0-9_./:@%+,-]*[ \t]+)?read([ \t]+-r)?([ \t]+" name ")*$") seen_read = 1
}
' 2>/dev/null)
[ "$READ_COMPUTED" = "READ_COMPUTED" ] && deny "$READ_BRANCH_REASON"

if [ -z "$PROBE_TEXT" ]; then
    # No leaf dispatched: the command is inert (all comment, all whitespace,
    # or only structural builtins), unless bash reported something while
    # walking it, in which case the walk is "could not analyze" and refuses
    # -- this hook's own direction on an unresolvable case is a false DENY
    # over a missed invocation.
    if [ -n "$PROBE_ERR" ]; then
        deny "$REASON_PREFIX the commit-guard hook could not analyze this command (bash reported: ${PROBE_ERR%%$'\n'*}) and refuses rather than guessing. Simplify the command; if it is valid, that is a hook defect to report separately."
    fi
    allow_default
fi

# --- Widening: where a heredoc's body stops being inert data. ------------
#
# Two independent triggers, either one widening a leaf's scan from its
# first physical line to its whole text (heredoc body included) rather
# than exempted as prose:
#
#   1. INTERPRETER (CL9's fix, whole-command scope). If ANY leaf names a
#      program that reads arbitrary input as code, no heredoc body
#      anywhere in the WHOLE command is treated as inert data — this does
#      not try to prove which specific pipe or substitution carries the
#      bytes to that interpreter (CL9 is exactly the finding that a
#      one-hop version of that proof is unsound), it widens instead.
#   2. UNQUOTED DELIMITER (per leaf). A heredoc with an unquoted (or
#      backslash-quoted-per-character, which is the same case) delimiter
#      undergoes parameter/command/arithmetic expansion on its body BEFORE
#      it ever reaches its consumer — `cat > f <<EOF` with a body
#      containing `$(git commit -m …)` runs that substitution as bash
#      prepares the heredoc, independent of what cat does with the result.
#      A quoted delimiter (`<<'EOF'`, `<<"EOF"`, `<<\EOF`) suppresses all of
#      that, which is the ONLY case this hook exempts as prose.
#
# With neither trigger, each leaf's code lines are scanned: every line
# except a quoted-delimiter heredoc body and its terminator line. A leaf
# spans lines when it carries a heredoc, a multi-line quoted word, or a
# substitution whose body spans lines. The probe vetoes such a leaf before
# its substitutions run, so a git write inside `$( )`, backticks or `<( )`
# on a later line never reaches the probe as a leaf of its own; scanning
# only the first line dropped it. The shared file docket-guard-leaf-lines.awk
# beside this hook (LEAF_LINES_AWK, resolved at the top of this file) makes
# that selection; docket-sibling-guard-hook.sh's "Line selection" comment
# describes its rules. It ends each leaf with the \036 byte, so the pre-pass
# drops its quote and group state at the leaf boundary rather than carrying
# it into the next leaf.
#
# The boundary on either side of an interpreter name is any byte that is not
# a word character and not a dot. The dot is what separates a file name from
# its extension, so a target named `cases.sh`, `x.env` or `run.node` is not
# an interpreter and does not widen; every spelling that can run
# one still does (`sh`, `/bin/sh`, `"sh"`, `$(sh`, a backtick, `;sh`).
INTERPRETER_RE='(^|[^A-Za-z0-9_.])(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|tclsh|expect|osascript|env|eval)([^A-Za-z0-9_.]|$)'
WIDEN=0
if [[ "$PROBE_TEXT" =~ $INTERPRETER_RE ]]; then
    WIDEN=1
fi

SCAN_TEXT=$(printf '%s' "$PROBE_TEXT" | awk -v mode=scan -v widen="$WIDEN" -f "$LEAF_LINES_AWK")

# --- Quote-group marking. ------------------------------------------------
#
# Marks every word that came from inside a single- or double-quoted string
# with a sentinel plus a quote-GROUP id, so the MATCH step below can tell
# real prose (`-m "... git commit ..."`, one group) apart from a
# bash-unquoted invocation built from separately-quoted words (`"git"
# "commit"`, two groups). A quoted group that is an interpreter's code
# argument (`bash -c "git commit -m x"`) is emitted unmarked instead: that is
# the one position where a quoted string is executed verbatim, so it was a
# bypass of this guard rather than prose, and it is no longer an accepted
# residual in either hook. Double-quoted content that could still trigger
# command/parameter substitution ($(...), backticks, ${...}) is left
# unmarked so the matcher inspects it directly. SCAN_TEXT above holds the
# lines this hook feeds per leaf: the code lines of each leaf, or the whole
# leaf when it is widened. The shared pre-pass (docket-guard-prepass.awk)
# applies a comment rule to every line it reads: a `#` where bash starts a
# word opens a comment to end of line, and a quote inside that comment opens
# no group. It also tracks arithmetic groups ((( )) and $(( ))), where no
# comment starts. A misread costs either way: a missed or an invented comment
# shifts quote parity in either direction, so the rule tracks bash's rather
# than erring toward either side. docket-guard-prepass.awk states the full
# rule and its known residuals.
#
# The awk PROGRAM itself lives in docket-guard-prepass.awk, shared
# byte-for-byte with docket-trust-guard-hook.sh: both hooks
# install as siblings under ~/.claude/hooks (src/user/claude_code.rs ships
# the whole hooks/ directory as one artifact), so resolving it beside this
# script's own path reaches the installed copy the same way in production
# and in the test suite's scratch-copy override. A missing file fails
# CLOSED (deny, not allow_default): this hook's whole job is deciding
# whether a git write is present in the command, and with no pre-pass
# program there is no way to make that call safely -- allowing would be
# worse than the tooling-gap fail-open above, which applies only when
# `docket` itself is missing, not when the lexer is missing. The directory
# is a bash parameter expansion on `$0` rather than a call to the external
# `dirname`: this hook's dependency set is fixed at bash/cat/jq/awk, and the
# test suite runs it with PATH restricted to exactly those.
# HOOK_DIR and PREPASS_AWK are resolved at the top of this file, in the
# install-integrity check that runs before the engine query.
# A pre-pass that fails (a program awk cannot parse) leaves the match stage
# no command to read, so the hook refuses rather than allowing.
STRIPPED=$(printf '%s' "$SCAN_TEXT" | awk -f "$PREPASS_AWK" 2>/dev/null) || \
    deny "$REASON_PREFIX the commit-guard hook's pre-pass program failed (docket-guard-prepass.awk), so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."

# THE MATCH: `git (commit|push|add)`, head-normalized on `git` and skipping
# git's own global options (`-C`, `-c`, `--git-dir`, …) that may precede the
# subcommand, quote-group-aware on the head and subcommand so real prose
# stays allowed while a trick built from separately-quoted tokens still
# denies. Unchanged from the pre-redesign hook — this step was never
# implicated in CL9/CL16/CL17, which were all about recognizing where a
# simple command begins and what is data versus code BEFORE this step
# ever runs.
#
# THE ONE EXEMPTION: `git --help commit` (option BEFORE the subcommand)
# opens nothing. `git commit --help` (subcommand before the flag) stays
# denied — an accepted false positive, since git's own option parsing
# would need modeling to tell that case apart from `git commit
# --help-me-a-message-file`-shaped real writes reliably.
#
# BRACE EXPANSION: bash's own $BASH_COMMAND reconstruction keeps
# a leaf's SOURCE spelling, unexpanded -- `git commi{t,} -m x` reaches this
# scan as the literal text `commi{t,}`, not as the two words bash actually
# dispatches (`commit`, empty) after expansion. The truncation below (stop
# at the first non-word character) then reads that as the word `commi`,
# which fails the commit/push/add test and ALLOWs a write bash really ran
# as `commit`. Rather than re-implementing brace expansion here -- exactly
# the kind of re-derivation of what bash already knows that produced CL16
# -- an unresolved `{` in the subcommand word (checked on the UNTRUNCATED
# word, before the truncation below runs) is read as the same residual
# class as a `$`-expansion look-behind: this pass cannot evaluate it, so it
# deviates from that pattern's usual ALLOW and stays on the DENY side,
# because every real use of `git commit/push/add` needs no brace at all.
# The brace test runs BEFORE the quote-group test, so prose can reach it.
# Two shapes bash never expands skip the DENY and fall through to the
# ordinary word tests: a brace word in the same quote group as `git`,
# since bash expands no quoted text, and a brace with no `,` or `..`
# anywhere after it, which is literal text to bash (`stub git {"ok":false}`
# in a findings note). "After it" runs to the end of the scanned text, not
# the end of the line: the pre-pass emits a double-quoted string holding
# `$(` raw, newline included, so the `,` can land on a later line, and a
# quoted newline inside the brace word puts it on the leaf's next code line.
# A `${...}` parameter expansion is stripped before this test, not treated
# as a brace: `git ${V}` is the SAME accepted residual as `git $V` (a
# computed-subcommand shape this pass already declines to resolve), and
# `${` is never brace ALTERNATION syntax, so it carries none of the risk
# this check exists for.
# The same DENY covers a brace word in command position, at a leaf's head or
# behind a prefix word, a wrapper (env, command, nohup, timeout) or a zsh
# precommand modifier (noglob, nocorrect, -, repeat N), which zsh still
# brace-expands: `env {git,commit} -m x` can expand into the whole write. It
# denies when the brace may expand and the letters of git and a write
# subcommand follow it in order. A brace word in argument position
# (`echo {git,commit}`, `cp f{,.bak}`) stays allowed.
MATCH=$(printf '%s' "$STRIPPED" | awk '
BEGIN { MARK = "\001" }
function has_brace(word,   stripped) {
    stripped = word
    gsub(/\$\{/, "", stripped)
    return index(stripped, "{") > 0
}
# Bash brace-expands only with a "," or ".." inside the braces. The pre-pass
# splits a source word at its embedded quotes, so {"commit",} reaches here as
# several words; the test reads from the brace word to the end of the text.
# The later lines are read once, in END: sep_after[r] holds whether any line
# after line r carries a separator, so a call scans only the words of its own
# line and the pass stays linear in the text.
function may_brace_expand(from,   k) {
    for (k = from; k <= n; k++) {
        if (index(words[k], ",") > 0 || index(words[k], "..") > 0) return 1
    }
    return sep_after[r]
}
# Every word bash builds from a brace is a subsequence of the source text from
# the brace onward, so a brace can produce git and a write subcommand only
# when these letters appear in order there.
function may_spell_git_write(from,   k, rest) {
    rest = ""
    for (k = from; k <= n; k++) rest = rest words[k]
    return rest ~ /g.*i.*t.*(c.*o.*m.*m.*i.*t|p.*u.*s.*h|a.*d.*d)/
}
# A word bash reads in command position without making it the command name:
# an assignment or a reserved word. A lone { is the reserved word unless a
# quoted fragment follows it, since the pre-pass splits {"a",b} at the quote.
function is_command_prefix(word, next_word) {
    if (word ~ /^[A-Za-z_][A-Za-z0-9_]*=/) return 1
    if (word ~ /^(if|then|else|elif|do|while|until|time|coproc|!)$/) return 1
    return word == "{" && substr(next_word, 1, 1) != MARK
}
# A wrapper or zsh precommand modifier runs the command named after its own
# options, so that word is in command position too.
function is_wrapper(word) {
    return word ~ /^(env|command|nohup|timeout|noglob|nocorrect|-|repeat)$/
}
function decode(raw,    inner, cpos) {
    if (length(raw) >= 2 && substr(raw, 1, 1) == MARK && substr(raw, length(raw), 1) == MARK) {
        inner = substr(raw, 2, length(raw) - 2)
        cpos = index(inner, ":")
        D_GROUP = substr(inner, 1, cpos - 1)
        D_WORD = substr(inner, cpos + 1)
        gsub(/^[\047\042]+|[\047\042]+$/, "", D_WORD)
        return 1
    }
    D_GROUP = ""
    D_WORD = raw
    gsub(/^[\047\042]+|[\047\042]+$/, "", D_WORD)
    return 0
}
{ lines[NR] = $0 }
END {
    sep_after[NR] = 0
    for (r = NR - 1; r >= 1; r--) {
        sep_after[r] = sep_after[r + 1] || index(lines[r + 1], ",") > 0 || index(lines[r + 1], "..") > 0
    }
    for (r = 1; r <= NR; r++) {
        n = split(lines[r], words, /[ \t]+/)
        cmdpos = 1
        wrapper = ""
        wrapper_arg = 0
        after_repeat = 0
        for (i = 1; i <= n; i++) {
            hquoted = decode(words[i])
            hgroup = D_GROUP
            w = D_WORD
            hw = w
            sub(/^.*(\$\(|\140|\(|;|\||&)/, "", hw)
            # Command position: line start, after a prefix word, after a
            # wrapper and its own options, or behind an operator. A quoted
            # fragment leaves it unchanged: the pre-pass splits one source
            # word at its quotes. After `repeat` every later word of the
            # command counts, since the pre-pass may split its count.
            if (!hquoted) {
                at_command = cmdpos
                if (hw != w || hw == "") {
                    at_command = 1
                    wrapper = ""
                    wrapper_arg = 0
                    after_repeat = 0
                }
                if (wrapper != "" && hw != "") {
                    if (wrapper_arg) {
                        wrapper_arg = 0
                    } else if (hw ~ /^-/) {
                        if (wrapper == "env" && hw ~ /^-[uCS]$/) wrapper_arg = 1
                        if (wrapper == "timeout" && hw ~ /^-[sk]$/) wrapper_arg = 1
                    } else if (wrapper == "env" && hw ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
                    } else if (wrapper == "timeout" && hw ~ /^[0-9.]+[smhd]?$/) {
                        wrapper = "timeout-duration-read"
                    } else {
                        wrapper = ""
                    }
                }
                if (wrapper != "" || hw == "") {
                    cmdpos = 1
                } else if (at_command && is_command_prefix(hw, words[i + 1])) {
                    cmdpos = 1
                } else if (at_command && is_wrapper(hw)) {
                    cmdpos = 1
                    if (hw == "repeat") after_repeat = 1
                    else if (hw == "env" || hw == "command" || hw == "timeout") wrapper = hw
                } else {
                    if ((at_command || after_repeat) && has_brace(hw) && may_brace_expand(i) && may_spell_git_write(i)) { print "MATCH"; exit }
                    cmdpos = 0
                }
            }
            if (hw == "git" || hw ~ /\/git$/) {
                j = i + 1
                helped = 0
                while (j <= n) {
                    decode(words[j])
                    opt = D_WORD
                    if (opt !~ /^-/) break
                    if (opt == "--help" || opt == "-h") helped = 1
                    if (opt == "-C" || opt == "-c" || opt == "--git-dir" || opt == "--work-tree" || opt == "--exec-path" || opt == "--namespace" || opt == "--super-prefix" || opt == "--config-env" || opt == "--attr-source") {
                        j += 2
                    } else {
                        j += 1
                    }
                    # The pre-pass splits a quoted option or value at its
                    # blanks and newlines, so `-c "a<newline>b"` reaches here
                    # as several words of one quote group. The rest of that
                    # group is the same argument, not the subcommand.
                    if (decode(words[j - 1])) {
                        vgroup = D_GROUP
                        while (j <= n && decode(words[j]) && D_GROUP == vgroup) j++
                    }
                }
                if (j <= n && !helped) {
                    squoted = decode(words[j])
                    sgroup = D_GROUP
                    s = D_WORD
                    sw = s
                    if (has_brace(sw) && !(hquoted && squoted && hgroup == sgroup) && may_brace_expand(j)) { print "MATCH"; exit }
                    sub(/[^A-Za-z0-9_-].*$/, "", sw)
                    if (sw == "commit" || sw == "push" || sw == "add") {
                        if (hquoted && squoted && hgroup == sgroup) continue
                        print "MATCH"
                        exit
                    }
                }
            }
        }
    }
}
' 2>/dev/null)
MATCH_RC=$?
# An awk that exits non-zero with no match printed did not finish the match
# (a program that fails to parse prints nothing), so its empty output is not
# "no git write": refuse, as for a missing pre-pass file. A printed match
# still decides below, since the program exits early on it and the pipeline
# can then end on SIGPIPE.
if [ "$MATCH_RC" -ne 0 ] && [ -z "$MATCH" ]; then
    deny "git write blocked: the commit-guard hook's match program failed (awk exit ${MATCH_RC}), so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."
fi
[ "$MATCH" = "MATCH" ] || allow_default


deny "git write blocked: ${GATE_REASON}. A git write needs an APPROVED commit-gate step on an active run — report COMMIT BLOCKED with this reason and do not retry: approval is the conductor's decision through the run's gate, never this caller's verb. If this command performs no git write, the retained text matcher has false-positived on git-write wording inside it (known limitation): to read a file's content, use the Read or Grep tool instead (bypasses this matcher entirely); only if the command must pass literal content through as an argument, write that content to a file and pass the path instead."
