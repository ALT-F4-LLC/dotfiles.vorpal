#!/usr/bin/env bash
#
# gate_repro: STEP-N [--sha SHA] [--repo DIR] [--work DIR] [--token FILE]
#
# The reproduction the standing ruling "a completion-gate failure the machine
# caused" requires before a gate park is presented (SKILL.md). It reads the
# parked step's gate rows, checks the recorded sha out into a detached
# worktree, runs each failing row's own argv there, and prints a verdict:
#
#   VERDICT: override-pass            every failing gate passed on reproduction;
#                                     RESOLVE: is the exact resolve command
#                                     (with --token; without it a
#                                     RESOLVE_TEMPLATE: line names the
#                                     token path to fill in)
#   VERDICT: present advisor-first    anything else; REASON: says why
#
# It resolves nothing and files nothing: the conductor runs the RESOLVE: line,
# links the root-cause issue, and reports the auto-pass.
#
# Advisor-first, without running a thing, when a gate's newest row is not
# pass or fail (`unmatched` is a trust matter, `skipped` is the engine's own
# park, a timeout is neither), when a failing gate is a security gate, when
# no gate failed, or when the step has no recorded sha. Advisor-first after
# the run when any failing gate fails again on the same sha. A row is the
# newest ordinal of its gate, the one the saga acted on.
#
# The recorded sha is `head` in the payload of the step's newest issue.diff
# artifact that no later artifact supersedes; --sha overrides it. The run
# uses this process's environment as it stands, in the checkout --repo names
# (default: the cwd's git toplevel), under --work (default $TMPDIR), plus the
# engine's gate input contract: DOCKET_GATE, DOCKET_STEP and DOCKET_ISSUE are
# exported per run, CI is left alone, and DOCKET_GATE_BASE is unset. A gate that
# scans the committed range (.docket/bin/gate-range) fails closed with exit 2
# when DOCKET_GATE names it and no base is set, so it reads advisor-first
# here rather than passing over an empty tree. The worktree is removed on
# exit. Each argv runs as an argv, never through a shell, with no stdin, and
# no timeout: a hung gate hangs the caller.
#
# Exit 0 override-pass, 1 advisor-first, 2 usage error or missing tool.
set -u

SECURITY_GATES="secret-scan vuln-scan sdet-abuse qa-test"

usage() { echo "usage: gate_repro.sh STEP-N [--sha SHA] [--repo DIR] [--work DIR] [--token FILE]" >&2; exit 2; }
advisor() { printf 'VERDICT: present advisor-first\nREASON: %s\n' "$1"; exit 1; }

step=""; sha=""; repo=""; work="${TMPDIR:-/tmp}"; token=""
while [ $# -gt 0 ]; do
    case "$1" in
        --sha) [ $# -ge 2 ] || usage; sha=$2; shift 2 ;;
        --repo) [ $# -ge 2 ] || usage; repo=$2; shift 2 ;;
        --work) [ $# -ge 2 ] || usage; work=$2; shift 2 ;;
        --token) [ $# -ge 2 ] || usage; token=$2; shift 2 ;;
        -*) usage ;;
        *) [ -z "$step" ] || usage; step=$1; shift ;;
    esac
done
case "$step" in STEP-[0-9]*) ;; *) usage ;; esac
for tool in docket jq git; do
    command -v "$tool" >/dev/null 2>&1 || { echo "gate_repro: $tool is required" >&2; exit 2; }
done
[ -n "$repo" ] || repo=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "gate_repro: not in a git checkout; pass --repo" >&2; exit 2; }

gates=$(docket step gates "$step" --json 2>/dev/null) || advisor "docket step gates $step failed, so the gate rows cannot be read"
rows=$(printf '%s' "$gates" | jq -c '.data.gates | group_by(.gate) | map(max_by(.ordinal)) | .[]' 2>/dev/null) \
    || advisor "the gate rows of $step did not parse"
[ -n "$rows" ] || advisor "$step has no recorded gate rows"

# Nothing runs until every row is judged: a non-pass/fail row or a failing
# security gate settles the question without a reproduction.
failing=""
while IFS= read -r row; do
    gate=$(printf '%s' "$row" | jq -r '.gate')
    verdict=$(printf '%s' "$row" | jq -r '.verdict')
    case "$verdict" in
        pass) ;;
        fail)
            case " $SECURITY_GATES " in
                *" $gate "*) advisor "$gate is a security gate and its failure is never passed under the machine-caused ruling" ;;
            esac
            failing="$failing$row"$'\n'
            ;;
        *) advisor "gate $gate reads $verdict, not pass or fail (unmatched is a trust matter, skipped is the engine's own park)" ;;
    esac
done <<EOF
$rows
EOF
[ -n "$failing" ] || advisor "no gate of $step failed in its newest rows, so there is nothing to reproduce"

if [ -z "$sha" ]; then
    artifacts=$(docket step artifacts "$step" --json 2>/dev/null) || advisor "docket step artifacts $step failed, so the recorded sha cannot be read"
    diff_id=$(printf '%s' "$artifacts" | jq -r '
        .data.artifacts
        | (map(.supersedes) | map(select(. != null))) as $gone
        | map(select(.kind == "issue.diff" and ([.artifact] | inside($gone) | not)))
        | sort_by(.created_at_ms) | last | .artifact // empty' 2>/dev/null)
    [ -n "$diff_id" ] || advisor "$step has no issue.diff artifact, so it records no sha"
    sha=$(docket step artifact "$diff_id" --json 2>/dev/null | jq -r '.data.payload | fromjson | .head // empty' 2>/dev/null)
fi
printf '%s' "$sha" | grep -qE '^[0-9a-f]{40}$' || advisor "the recorded sha of $step is not a 40-hex commit id (got '${sha}')"
git -C "$repo" cat-file -e "${sha}^{commit}" 2>/dev/null || advisor "sha $sha is not a commit in $repo"

scratch=$(mktemp -d "${work%/}/gate-repro.XXXXXX") || { echo "gate_repro: cannot create a scratch directory under $work" >&2; exit 2; }
wt="$scratch/checkout"
cleanup() { git -C "$repo" worktree remove --force "$wt" >/dev/null 2>&1; chmod -R u+w "$scratch" 2>/dev/null; rm -rf "$scratch"; }
trap cleanup EXIT
added=$(git -C "$repo" worktree add --detach "$wt" "$sha" 2>&1) || advisor "cannot check out $sha into a detached worktree under $repo: $(printf "%s" "$added" | tail -n 1)"

show=$(docket step show "$step" --json 2>/dev/null)
run=$(printf '%s' "$show" | jq -r '.data.run // empty' 2>/dev/null)
issue=$(printf '%s' "$show" | jq -r '.data.issue // empty' 2>/dev/null)

printf 'SHA: %s\n' "$sha"
bad=""
expected=$(printf '%s' "$failing" | grep -c .)
ran=0
while IFS= read -r row; do
    [ -n "$row" ] || continue
    gate=$(printf '%s' "$row" | jq -r '.gate')
    argv=()
    while IFS= read -r -d '' arg; do argv+=("$arg"); done < <(printf '%s' "$row" | jq -j '.argv[] | (., "\u0000")')
    [ "${#argv[@]}" -gt 0 ] || advisor "gate $gate records no argv to reproduce"
    out="$scratch/$gate.out"
    ( cd "$wt" && env -u DOCKET_GATE_BASE DOCKET_GATE="$gate" DOCKET_STEP="$step" DOCKET_ISSUE="$issue" "${argv[@]}" ) </dev/null >"$out" 2>&1
    code=$?
    ran=$((ran + 1))
    printf 'ROW: gate=%s recorded_exit=%s recorded_fingerprint=%s repro_exit=%s argv=%s\n' \
        "$gate" "$(printf '%s' "$row" | jq -r '.exit')" "$(printf '%s' "$row" | jq -r '.fingerprint // ""')" \
        "$code" "$(printf '%s' "$row" | jq -c '.argv')"
    if [ "$code" -ne 0 ]; then
        bad="$bad $gate"
        printf 'OUTPUT_TAIL: gate=%s\n' "$gate"
        tail -n 20 "$out" | sed 's/^/  /'
    fi
done <<EOF
$failing
EOF
[ "$ran" -eq "$expected" ] || advisor "ran $ran of $expected failing gate(s); an unreproduced failure is never passed"
[ -z "$bad" ] || advisor "failed again on reproduction at $sha:$bad (a real failure, or an environment the machine-caused ruling does not cover)"

printf 'VERDICT: override-pass\n'
resolve="docket step resolve $step --as override-pass --authority standing-grant --authority-ref machine-caused-gate-failure"
if [ -n "$token" ]; then
    printf 'RESOLVE: %s < %q\n' "$resolve" "$token"
else
    printf 'RESOLVE_TEMPLATE: %s < <scratchpad>/conductor.d/%s.token\n' "$resolve" "${run:-RUN-N}"
    printf 'NOTE: no --token was given, so the line above is a template, not runnable shell; re-run with --token FILE for the RESOLVE: command.\n'
fi
printf 'NOTE: file or link the root-cause issue, cite the ruling and the ROW lines above in the note, and report this auto-pass.\n'
exit 0
