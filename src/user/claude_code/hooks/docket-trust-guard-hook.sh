#!/bin/bash

# trust-guard — PreToolUse: Bash.
#
# `docket trust add/rm` mutates the trust store that authorizes an executor's
# own completion gates (`~/.config/docket/trust.toml`, granted sandbox-write
# at SANDBOX_DOCKET_TRUST_PATH in claude_code.rs). Unlike every other write an
# executor makes, this one lands nowhere in the recorded diff a wave judge
# reads — trust.toml lives outside every checkout — so a self-repointed gate
# is invisible to the one review layer downstream of the executor itself. The
# `Bash(docket trust add/rm:*)` ask rule in claude_code.rs is not a
# structural stop for that case: an unattended executor has no human at a
# terminal to answer an ask, so under this fleet's `auto` permission default
# the decision falls to the same classifier already measured approving
# sandbox bypasses a brief forbade (a fleet review found this, see the removed
# sandbox-bypass-ask-hook.sh). This hook re-keys the decision away from that
# classifier for exactly the callers who must never win it.
#
# THE SCOPE, and why it is not a blanket deny. `docket trust add/rm` stays a
# permission ASK for the main conversation — the operator's own path, working
# as intended per the conduct contract's "Reserved to the operator" list
# (trust-store writes go through a direct question, every time). A deny here
# that ignored caller identity would block the operator's own ask-confirmed
# path too, which the issue's acceptance criteria explicitly forbids. The
# distinguishing field is `agent_type`, present in PreToolUse hook input only
# for a subagent's own tool calls (Claude Code hooks.md, "Subagent Fields")
# and absent for the main conversation's -- so EXECUTOR_ARCHETYPES below is
# the whole of this hook's policy, and it names only the three graph-fleet
# executor archetypes (agents/executor-{read,write,research}.md), not every
# subagent type: a groomer or planner seat was never in this hook's scope, and
# widening this list to "any agent_id present" would deny seats this issue
# never asked to touch, on no evidence any of them needs to.
#
# Exit 0 allow / exit 2 deny with reason on stderr, matching this hook
# family's established contract (docket-commit-guard-hook.sh): exit 2 is a
# pre-permission hard stop, honored "regardless of permission mode" — the
# same property that makes it survive an unsandboxed retry, unlike the ask
# rule and unlike a sandbox-only deny.
#
# This hook carries no engine query and no state, deliberately: unlike
# commit-gate, whether a trust-store write is in scope for a step does not
# depend on run content, only on who is asking. There is nothing here for the
# engine to have an opinion about.
#
# Fail-open on a missing `jq`: a tooling gap must not brick every Bash call in
# the session. There is no `docket`-binary fail-open branch here, unlike
# commit-guard — this hook never shells out to `docket` itself.

set -uo pipefail

allow_default() {
    exit 0
}

deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

# Only these three: the graph-fleet executor archetypes this issue names. Any
# other agent_type (or none, i.e. the main conversation) falls through to the
# existing ask rule.
is_executor_archetype() {
    case "$1" in
        executor-read | executor-write | executor-research) return 0 ;;
        *) return 1 ;;
    esac
}

INPUT=$(cat 2>/dev/null) || allow_default

if ! command -v jq >/dev/null 2>&1; then
    allow_default
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null) || allow_default
is_executor_archetype "$AGENT_TYPE" || allow_default

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default

# Quote-aware pre-pass, lifted byte-identical from docket-commit-guard-hook.sh
# (see that file's header for the full rationale): marks every word that came
# from inside a quoted string with a sentinel plus a quote-GROUP id, so the
# matcher below can tell real prose (`-m "... docket trust add ..."`, one
# group) apart from a bash-unquoted invocation built from separately-quoted
# words (`"docket" "trust" "add"`, three groups). Double-quoted content that
# could still trigger command/parameter substitution ($(...), backticks,
# ${...}) is left unmarked so the matcher inspects it directly.
STRIPPED=$(printf '%s' "$COMMAND" | awk '
{
    buf = (NR == 1) ? $0 : buf "\n" $0
}
END {
    line = buf
    n = length(line)
    out = ""
    i = 1
    SQ = "\047"
    DQ = "\042"
    MARK = "\001"
    GROUP = 0
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == "\\" && i < n) {
            out = out c substr(line, i + 1, 1)
            i += 2
            continue
        }
        if (c == SQ) {
            j = i + 1
            content = ""
            while (j <= n && substr(line, j, 1) != SQ) {
                content = content substr(line, j, 1)
                j++
            }
            GROUP++
            m = split(content, qw, /[ \t\n]+/)
            for (k = 1; k <= m; k++) {
                if (qw[k] != "") out = out " " MARK GROUP ":" qw[k] MARK
            }
            out = out " "
            i = j + 1
            continue
        }
        if (c == DQ) {
            j = i + 1
            content = ""
            while (j <= n) {
                cc = substr(line, j, 1)
                if (cc == "\\" && j < n) {
                    content = content cc substr(line, j + 1, 1)
                    j += 2
                    continue
                }
                if (cc == DQ) break
                content = content cc
                j++
            }
            if (content ~ /\$\(|`|\$\{/) {
                out = out " " content " "
            } else {
                GROUP++
                m = split(content, qw, /[ \t\n]+/)
                for (k = 1; k <= m; k++) {
                    if (qw[k] != "") out = out " " MARK GROUP ":" qw[k] MARK
                }
                out = out " "
            }
            i = j + 1
            continue
        }
        out = out c
        i += 1
    }
    print out
}
' 2>/dev/null) || allow_default

# THE MATCH: three consecutive words `docket trust (add|rm)`, head-normalized
# on `docket` the same way commit-guard normalizes `git` (closes a delimiter
# or subshell glued directly onto the front with no whitespace), and
# quote-group-aware on all three words so real prose stays allowed while a
# trick built from separately-quoted tokens still denies.
#
# THE ONE EXEMPTION: `docket trust add --help` (or `-h`, or `rm`) opens
# nothing -- it is the read a judge seat needs to evaluate a trust entry's
# flags, and denying it as a write cost a tribunal the one lookup its verdict
# rested on. The exemption is deliberately the narrowest shape that is a help
# read by construction rather than by CLI courtesy: the flag must be the word
# IMMEDIATELY after the verb, unquoted, and exactly `-h` or `--help` with at
# most a shell operator glued onto its tail (`--help;`, `--help)`, `--help|`
# all end the segment right after the flag). Directly after the verb no
# earlier option can swallow the flag as its value and no `--` has been seen,
# so docket's parser sees the help flag before it validates a single argument
# -- whereas `docket trust add name -- --help` is a real write with `--help`
# as an argv element, and `docket trust add --timeout --help -- x` feeds the
# flag to --timeout, which is why a help flag in any later position stays
# denied. Exact spelling matters for the same reason: `--help=false` and
# `-h=false` are pflag's way of turning the flag OFF, so they must not be
# stripped down to a match. The verb and `trust` must be clean words (nothing
# glued) -- a glued operator there means the segment ended before the flag.
#
# An exempted occurrence `continue`s the scan rather than allowing outright:
# `docket trust add --help && docket trust add x -- y` still denies on its
# second occurrence, on this line or a later one.
MATCH=$(printf '%s' "$STRIPPED" | awk '
BEGIN { MARK = "\001" }
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
{
    n = split($0, words, /[ \t]+/)
    for (i = 1; i <= n; i++) {
        hquoted = decode(words[i])
        hgroup = D_GROUP
        w = D_WORD
        hw = w
        sub(/^.*(\$\(|\140|\(|;|\||&)/, "", hw)
        if (hw == "docket" || hw ~ /\/docket$/) {
            if (i + 2 > n) continue
            tquoted = decode(words[i + 1])
            tgroup = D_GROUP
            tw = D_WORD
            texact = tw
            sub(/[^A-Za-z0-9_-].*$/, "", tw)
            if (tw != "trust") continue
            vquoted = decode(words[i + 2])
            vgroup = D_GROUP
            vw = D_WORD
            vexact = vw
            sub(/[^A-Za-z0-9_-].*$/, "", vw)
            if (vw != "add" && vw != "rm") continue
            if (hquoted && tquoted && vquoted && hgroup == tgroup && tgroup == vgroup) continue
            # Help read: an unquoted, bare -h/--help directly after a clean
            # verb. Only a glued trailing shell operator is stripped from the
            # flag (it ends the segment); any other suffix is a different
            # argument and keeps the deny. See the comment above the block.
            if (texact == tw && vexact == vw && i + 3 <= n) {
                pquoted = decode(words[i + 3])
                pw = D_WORD
                sub(/[|&;()<>].*$/, "", pw)
                if (!pquoted && (pw == "-h" || pw == "--help")) continue
            }
            print "MATCH"
            exit
        }
    }
}
' 2>/dev/null)
[ "$MATCH" = "MATCH" ] || allow_default

deny "trust-store write blocked: \`docket trust add/rm\` is operator-reserved and never in scope for an executor step, whatever the brief says. If your step genuinely needs a trust entry changed, that is a routing defect: record the mismatch as your step's finding through the gap channel your brief names, and do not retry this call."
