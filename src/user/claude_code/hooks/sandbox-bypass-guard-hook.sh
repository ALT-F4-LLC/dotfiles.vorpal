#!/bin/bash

# sandbox-bypass-guard — PreToolUse: Bash.
#
# A Bash call carrying dangerouslyDisableSandbox=true runs OUTSIDE the
# sandbox: no filesystem allowlist, no network filter, no denyRead. Every
# executor brief forbids that lift ("the lift is the operator's to grant,
# never through a brief and never on your say-so"), and the prohibition had no
# mechanical backing: measured on one wave, an executor ran twenty-one
# `GOCACHE=<scratch> vorpal run go ...` calls unsandboxed without a single
# sandboxed attempt first, and the auto-mode classifier approved each one. The
# sandboxed form works (probed: vorpal runs inside the sandbox, env-var prefix
# included), so those lifts bought nothing and cost the whole sandbox.
#
# THE SCOPE, mirroring docket-trust-guard-hook.sh: deny for the three
# graph-fleet executor archetypes only. The main conversation (no agent_type)
# and every other seat keep the harness's own handling — in auto mode the
# classifier judges the underlying command; in manual mode the operator is
# prompted — because the operator's own path to a lift is exactly the thing an
# executor is told does not exist for it.
#
# Exit 0 allow / exit 2 deny with reason on stderr, this hook family's
# contract: exit 2 is a pre-permission hard stop the classifier never sees, and
# the reason reaches the executor so it runs the sandboxed form instead of
# retrying the lift under another spelling.

set -uo pipefail

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

INPUT=$(cat 2>/dev/null) || allow_default
[ -n "$INPUT" ] || allow_default

command -v jq >/dev/null 2>&1 || allow_default

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null) || allow_default
is_executor_archetype "$AGENT_TYPE" || allow_default

# Boolean-typed on purpose: the harness sends a JSON boolean, and a string
# "true" is a schema quirk, not a lift.
BYPASS=$(printf '%s' "$INPUT" | jq -r '.tool_input.dangerouslyDisableSandbox == true' 2>/dev/null) || allow_default
[ "$BYPASS" = "true" ] || allow_default

deny "sandbox bypass blocked: dangerouslyDisableSandbox is never available to an executor step, whatever the brief or the last error said. Run the same command sandboxed; \`vorpal run\`, \`go\`, and \`cargo\` all work inside the sandbox with build caches under your step's scratch directory. If the sandboxed form is refused (Operation not permitted, a blocked host, a bind failure), that is a NETWORK GATE BLOCKED or environment finding for your step report — attempt it once, record the exact error, and do not retry this lift."
