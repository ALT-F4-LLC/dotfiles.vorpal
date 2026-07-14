#!/bin/bash

set -uo pipefail

# Exit 2 is a pre-permission hard stop: it blocks the tool call before permission
# rules/mode are evaluated, unlike a JSON permissionDecision:"deny" whose interaction
# with bypassPermissions mode is undocumented. Deny is unconditional here (operator
# decision, DKT-282): an "ask" can't be answered in the non-interactive modes teammates
# run in, so there is no permission_mode case-split.
allow_default() {
    exit 0
}

deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

INPUT=$(cat 2>/dev/null) || allow_default

if ! command -v jq >/dev/null 2>&1; then
    allow_default
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default

# Fires ONLY on write-target forms whose target is a literal /tmp/ or /private/tmp/ path,
# allowlisting the harness scratchpad prefixes /tmp/claude* and /private/tmp/claude*.
# Write forms: output redirections (> >> 1> 2> &>), tee [-a], dd of=, and
# cp/mv (target = last arg before a shell separator) / touch / mkdir. Reads
# (cat /tmp/x, < /tmp/x, ls /tmp, grep, if=, echoed strings) never match. Bias narrow:
# a false-allow falls through to the existing sandbox denial (safe); a false-deny blocks
# legit work (bad). The sandbox remains the backstop.
MATCH=$(printf '%s' "$COMMAND" | awk '
function is_bad_tmp(p) {
    gsub(/^[\047\042]+|[\047\042]+$/, "", p)
    if (p ~ /^\/tmp\/claude/ || p ~ /^\/private\/tmp\/claude/) return 0
    if (p ~ /^\/tmp\// || p ~ /^\/private\/tmp\//) return 1
    return 0
}
function is_sep(t) { return (t == ";" || t == "&&" || t == "||" || t == "|" || t == "&") }
{
    n = split($0, w, /[ \t]+/)
    for (i = 1; i <= n; i++) {
        tok = w[i]
        if (tok ~ /^(1|2|&)?>>?/) {
            path = tok
            sub(/^(1|2|&)?>>?/, "", path)
            if (path != "") {
                if (is_bad_tmp(path)) { print "MATCH"; exit }
            } else if (i+1 <= n && is_bad_tmp(w[i+1])) { print "MATCH"; exit }
            continue
        }
        if (tok == "tee") {
            for (j = i+1; j <= n; j++) {
                a = w[j]
                if (is_sep(a)) break
                if (a ~ /^-/) continue
                if (is_bad_tmp(a)) { print "MATCH"; exit }
                break
            }
            continue
        }
        if (tok ~ /^of=/) {
            path = tok; sub(/^of=/, "", path)
            if (is_bad_tmp(path)) { print "MATCH"; exit }
            continue
        }
        if (tok == "cp" || tok == "mv") {
            lastarg = ""
            for (j = i+1; j <= n; j++) {
                a = w[j]
                if (is_sep(a)) break
                if (a ~ /^-/) continue
                lastarg = a
            }
            if (lastarg != "" && is_bad_tmp(lastarg)) { print "MATCH"; exit }
            continue
        }
        if (tok == "touch" || tok == "mkdir") {
            for (j = i+1; j <= n; j++) {
                a = w[j]
                if (is_sep(a)) break
                if (a ~ /^-/) continue
                if (is_bad_tmp(a)) { print "MATCH"; exit }
            }
            continue
        }
    }
}
' 2>/dev/null)

[ "$MATCH" = "MATCH" ] || allow_default

deny "Refusing a literal /tmp/ write target. The sandbox denies these; write scratch files under \$TMPDIR instead (e.g. \$TMPDIR/foo). The harness scratchpad prefixes /tmp/claude* and /private/tmp/claude* are exempt."
