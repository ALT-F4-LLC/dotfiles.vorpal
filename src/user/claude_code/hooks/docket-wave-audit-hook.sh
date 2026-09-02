#!/bin/bash

# wave-audit (03 §5, TDD §4.5) — PostToolUse: Workflow.
#
# Shim over `docket guard record`. ADVISORY: surfaces the guard's reason on
# stderr but always exits 0. It used to deny (exit 2), which was correct when
# Workflow returned at wave COMPLETION — but Workflow now returns at LAUNCH,
# so an open dispatch at this hook point is the normal mid-flight state and a
# blocking exit denied every legitimate wave (observed on an early run).
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
  # A wave launch now legitimately carries the fixed sentinel
  # `__USE_PINNED_POLICY__` instead of the file — docket-policy-guard-hook.sh
  # (PreToolUse) substitutes the canonical bytes via updatedInput before the
  # tool runs. If this PostToolUse hook ever sees the PRE-substitution args
  # (harness ordering quirk) the sentinel is 25 chars against a ~28k-char
  # file — exactly the alarm-fatigue false positive this hook's own history
  # warns against — so treat the sentinel, and only the sentinel, as clean
  # rather than condensed.
  IS_SENTINEL=$(printf '%s' "$HOOK_INPUT" | jq -r '
    .tool_input.args
    | if type == "string" then (try fromjson catch {}) else (. // {}) end
    | .policyText // "" | if . == "__USE_PINNED_POLICY__" then "yes" else "no" end' 2>/dev/null)
  if [ "$IS_SENTINEL" = "yes" ]; then
    GOT=""
  fi
  if [ -n "$GOT" ] && [ "$GOT" -gt 0 ] 2>/dev/null; then
    # Measure the file with jq too, so BOTH sides count Unicode codepoints:
    # `wc -m` counts bytes under a non-UTF-8 locale, and policy.toml carries
    # multi-byte chars (20932 bytes vs 20834 chars today), which would make
    # the loud message below fire on every clean launch in a C-locale hook
    # environment — recreating the exact alarm fatigue this block kills
    # (a locale-counting false alarm a prior security review had flagged).
    WANT=$(jq -Rs 'length' < "$HOME/.docket/config/policy.toml" 2>/dev/null)
    # $(cat file) strips the trailing newline, so a byte-for-byte launch
    # legitimately arrives one char short. Warning on that fired on every
    # CLEAN launch (19+ false positives across one fleet), and
    # the noise trained conductors to ignore the REAL condensation warnings
    # in the same pile (several real governance panels and waves in that same
    # fleet). Exact and exact-minus-one are silent; anything else
    # says so loudly, with numbers.
    if [ -n "$WANT" ] && [ "$GOT" -ne "$WANT" ] 2>/dev/null && [ "$GOT" -ne "$((WANT - 1))" ]; then
      DELTA=$((WANT - GOT)); [ "$DELTA" -lt 0 ] && DELTA=$((0 - DELTA))
      PCT=$((DELTA * 100 / WANT))
      echo "wave-audit: POLICY CONDENSED — this launch carried policyText of $GOT chars but ~/.docket/config/policy.toml is $WANT chars (off by $DELTA, ~$PCT%). The wave or panel just launched is routing/judging on an INCOMPLETE policy: TaskStop it, re-cat the file, and relaunch byte-for-byte. This defect class has previously reached live governance votes before being caught." >&2
    fi
  fi
fi

command -v docket >/dev/null 2>&1 || exit 0

# stdout dropped, stderr kept — see docket-spawn-guard-hook.sh for why: on exit 0
# the harness parses stdout as JSON, and `✔ allowed` is not JSON. The guard's
# reason travels on stderr either way. The no-database case stays silent: exit 2
# with "no docket database found" is the engine's NOT_FOUND riding the deny
# channel (measured directly), not a discrepancy — advisory noise about a
# repo that is not docket's business helps nobody.
#
# `guard record` denies on exactly TWO states, and this hook must not treat them
# alike (DOT-1072). The engine computes both in one function shared with `next`
# (internal/engine/dispatch.go refuseIfUnreconciledTx), so the reason text below
# is the engine's own words rather than a paraphrase this file could drift from:
#
#   open dispatch  -> "RUN-N has an open dispatch: DISPATCH-M expiring at ..."
#   discrepancy    -> "RUN-N has N unreconciled discrepancy(s) and will not be
#                      offered new work until they are resolved: ..."
ERR=$(docket guard record 2>&1 >/dev/null)
if [ "$?" -eq 2 ]; then
  case "$ERR" in
    *'no docket database found'*) : ;;
    # AN OPEN DISPATCH IS SILENT. Workflow returns at wave LAUNCH, and a wave is
    # launched against an open dispatch BY DEFINITION — so this branch fired on
    # every legitimate wave launch (three for three on one measured run) while
    # telling the conductor nothing it could act on. That is the same alarm
    # fatigue the policyText block above was rewritten to kill, and it made the
    # docket-run skill's "wave-audit stays silent on a clean launch" false.
    *'has an open dispatch:'*) : ;;
    # EVERYTHING ELSE IS SURFACED, WITH THE GUARD'S OWN REASON. A standing
    # discrepancy is a property of the RUN, not of the manifest: it survives the
    # dispatch close and `next` refuses while it stands. Anything unexpected
    # (a missing run, a failed read) lands here too, so the line quotes the
    # engine rather than asserting which of the two it is.
    *) echo "wave-audit (advisory): \`docket guard record\` denies, and NOT for the normal open-dispatch reason — read it: $ERR" >&2 ;;
  esac
fi
exit 0
