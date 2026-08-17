#!/bin/bash

# policy-guard (operator-approved 2026-08-17, DKT-V31 follow-up) — PreToolUse:
# Workflow. DENIES a Workflow launch whose args.policyText does not carry
# ~/.docket/config/policy.toml byte-for-byte (modulo the trailing newline that
# $(cat …) strips). The PostToolUse wave-audit advisory proved insufficient
# alone: on 2026-08-17 three governance panels and two waves ran on a
# ~76%-condensed policy while the advisory scrolled past unread. This is the
# containment half — it refuses BEFORE any seat or executor spawns; the
# wave-audit advisory remains the after-the-fact narrator.
#
# Fail-OPEN everywhere except a REAL mismatch: no jq, no policy file, and a
# launch carrying no policyText (other workflows) all allow. Both sides are
# measured in Unicode codepoints via jq — never wc -m, which counts bytes
# under a non-UTF-8 locale (policy.toml holds multi-byte chars) and would
# deny every clean launch, the exact false-alarm defect wave-audit just shed.
# KNOWN LIMIT, accepted: a same-length substitution passes — the length check
# catches the observed condensation class, not forgery.

set -uo pipefail

HOOK_INPUT=$(cat 2>/dev/null || true)
[ -n "$HOOK_INPUT" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
POLICY="$HOME/.docket/config/policy.toml"
[ -f "$POLICY" ] || exit 0

GOT=$(printf '%s' "$HOOK_INPUT" | jq -r '
  .tool_input.args
  | if type == "string" then (try fromjson catch {}) else (. // {}) end
  | .policyText // "" | length' 2>/dev/null)
{ [ -n "$GOT" ] && [ "$GOT" -gt 0 ]; } 2>/dev/null || exit 0

WANT=$(jq -Rs 'length' < "$POLICY" 2>/dev/null)
{ [ -n "$WANT" ] && [ "$WANT" -gt 0 ]; } 2>/dev/null || exit 0

if [ "$GOT" -ne "$WANT" ] && [ "$GOT" -ne "$((WANT - 1))" ]; then
  DELTA=$((WANT - GOT)); [ "$DELTA" -lt 0 ] && DELTA=$((0 - DELTA))
  PCT=$((DELTA * 100 / WANT))
  echo "policy-guard: LAUNCH DENIED — args.policyText is $GOT chars but $POLICY is $WANT chars (off by $DELTA, ~$PCT%). A wave or panel launched on a condensed policy routes and judges on incomplete tables. Re-run \`cat ~/.docket/config/policy.toml\` and relaunch with that output byte-for-byte (the trailing newline may drop; nothing else may)." >&2
  exit 2
fi
exit 0
