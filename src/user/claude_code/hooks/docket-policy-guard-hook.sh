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
# Second check (operator-approved 2026-08-20, DOT-298): the run pinned
# policy.toml at activation, and a mid-run `just activate` can drift disk away
# from that pin. The length check ties the launch to DISK; nothing tied disk
# to the PIN — a 33-agent wave once routed on a policy its run never pinned,
# found only by hand a day later. So before trusting disk, resolve the
# launching cwd's ACTIVE runs and ask the engine's own pin comparator
# (`docket run verify-pins`) whether policy.toml still matches. This runs
# FIRST: under drift, a conductor correctly relaunching the PINNED bytes would
# fail the disk-length check, and the drift is the message worth seeing.
# Only the policy.toml pin is enforced here — other drifted refs already make
# every engine verb that reads them refuse; policy.toml is the one artifact
# that reaches a wave without passing through an engine verb.
#
# Fail-OPEN everywhere except a REAL mismatch: no jq, no policy file, a
# launch carrying no policyText (other workflows), no docket binary, no
# active run, a run with no policy.toml pin, and malformed engine output all
# allow. Both sides of the length check are measured in Unicode codepoints
# via jq — never wc -m, which counts bytes under a non-UTF-8 locale
# (policy.toml holds multi-byte chars) and would deny every clean launch, the
# exact false-alarm defect wave-audit just shed.
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

# ---- Pin backstop (DOT-298) ----
if command -v docket >/dev/null 2>&1; then
  HOOK_CWD=$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
  if [ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ]; then
    cd "$HOOK_CWD" 2>/dev/null || true
  fi
  ACTIVE=$(docket run status --active --json 2>/dev/null \
    | jq -r '.data.runs // [] | .[].run // empty' 2>/dev/null)
  for RUN in $ACTIVE; do
    VERDICT=$(docket run verify-pins "$RUN" --json 2>&1)
    DRIFT=$(printf '%s' "$VERDICT" \
      | jq -r 'select(.ok == false) | .error // empty' 2>/dev/null \
      | tr ';' '\n' | grep -F 'policy.toml changed:' | head -1)
    if [ -n "$DRIFT" ]; then
      echo "policy-guard: LAUNCH DENIED — $RUN pinned policy.toml at activation and disk no longer matches it (${DRIFT# }). A mid-run \`just activate\` is the usual cause. Launching now would route and judge on a policy the run never pinned. Stop this dispatch and surface the drift to the operator (\`docket run verify-pins $RUN\` lists every drifted pin); do not relaunch on the disk policy." >&2
      exit 2
    fi
  done
fi

WANT=$(jq -Rs 'length' < "$POLICY" 2>/dev/null)
{ [ -n "$WANT" ] && [ "$WANT" -gt 0 ]; } 2>/dev/null || exit 0

if [ "$GOT" -ne "$WANT" ] && [ "$GOT" -ne "$((WANT - 1))" ]; then
  DELTA=$((WANT - GOT)); [ "$DELTA" -lt 0 ] && DELTA=$((0 - DELTA))
  PCT=$((DELTA * 100 / WANT))
  echo "policy-guard: LAUNCH DENIED — args.policyText is $GOT chars but $POLICY is $WANT chars (off by $DELTA, ~$PCT%). A wave or panel launched on a condensed policy routes and judges on incomplete tables. Re-run \`cat ~/.docket/config/policy.toml\` and relaunch with that output byte-for-byte (the trailing newline may drop; nothing else may)." >&2
  exit 2
fi
exit 0
