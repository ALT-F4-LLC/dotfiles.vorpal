#!/bin/bash

# wave-audit (03 §5, TDD §4.5) — PostToolUse: Workflow.
#
# Shim over `docket guard record`. ADVISORY: surfaces the guard's reason on
# stderr but always exits 0. It used to deny (exit 2), which was correct when
# Workflow returned at wave COMPLETION — but Workflow now returns at LAUNCH,
# so an open dispatch at this hook point is the normal mid-flight state and a
# blocking exit denied every legitimate wave (observed on RUN-2, 2026-08-06).
# No policy, no branching on run content, no state (AC-4.1).
#
# 03 §5 calls this "a courtesy early warning": enforcement is engine-side either
# way -- `next` refuses while discrepancies stand and a TTL'd dispatch can
# always be abandoned (02 §5). Advisory is the honest strength for a check
# that can no longer distinguish mid-flight from drift.
#
# NO --run, DELIBERATELY, unlike the TDD §4.5 table's `--run $RUN`. The engine
# documents the no-flag form as answering "over every non-terminal run, denying
# if any is unreconciled -- so a hook wired once keeps working as runs come and
# go." That is strictly the better fit for a global hook AND it removes a
# `docket run status` subprocess from every Workflow return. Recorded as a
# deviation from the table's literal shim text; the role is unchanged.
#
# Fail-OPEN only on a missing binary (see spawn-guard's note). Engine-state
# uncertainty resolves to the engine's own exit 2.

set -uo pipefail

# The harness hands PostToolUse hooks the tool call as JSON on stdin. Drain it
# once up front — the policyText check below reads it, and it must be consumed
# before any subprocess could swallow it.
HOOK_INPUT=$(cat 2>/dev/null || true)

# --- policyText integrity (advisory) ---
# Conductors hand-carry policy.toml into Workflow launches as args.policyText,
# and models have repeatedly emitted a condensed rendering straight through an
# explicit byte-for-byte contract line — re-reading the file immediately
# before the launch did not stop it (measured on two consecutive runs). This
# hook is the one seat that sees both sides at launch time, so the comparison
# lives here as code. Advisory like everything else in this file: warn loudly,
# never block. Launches whose args carry no policyText (other workflows) skip.
if [ -n "$HOOK_INPUT" ] && [ -f "$HOME/.docket/config/policy.toml" ] \
   && command -v jq >/dev/null 2>&1; then
  GOT=$(printf '%s' "$HOOK_INPUT" | jq -r '
    .tool_input.args
    | if type == "string" then (try fromjson catch {}) else (. // {}) end
    | .policyText // "" | length' 2>/dev/null)
  if [ -n "$GOT" ] && [ "$GOT" -gt 0 ] 2>/dev/null; then
    WANT=$(wc -m < "$HOME/.docket/config/policy.toml" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$WANT" ] && [ "$GOT" -ne "$WANT" ]; then
      echo "wave-audit (advisory): this launch carried policyText of $GOT chars but ~/.docket/config/policy.toml is $WANT chars — the launch did NOT carry the file byte-for-byte. Re-cat the file and re-launch with the full output; a condensed policy is the RUN-4 defect." >&2
    fi
  fi
fi

command -v docket >/dev/null 2>&1 || exit 0

# stdout dropped, stderr kept — see docket-spawn-guard-hook.sh for why: on exit 0
# the harness parses stdout as JSON, and `✔ allowed` is not JSON. The guard's
# reason travels on stderr either way. The no-database case stays silent: exit 2
# with "no docket database found" is the engine's NOT_FOUND riding the deny
# channel ([MEASURED 2026-08-06]), not a discrepancy — advisory noise about a
# repo that is not docket's business helps nobody.
ERR=$(docket guard record 2>&1 >/dev/null)
if [ "$?" -eq 2 ]; then
  case "$ERR" in
    *'no docket database found'*) : ;;
    *) echo "wave-audit (advisory): dispatch open or discrepancy standing — normal mid-wave; the engine refuses 'next' if real drift persists" >&2 ;;
  esac
fi
exit 0
