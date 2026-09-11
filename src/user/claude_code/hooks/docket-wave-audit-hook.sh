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

# Drain the harness's JSON on stdin so `guard record` below cannot inherit it.
cat >/dev/null 2>&1 || true

command -v docket >/dev/null 2>&1 || exit 0

# stdout dropped, stderr kept — see docket-spawn-guard-hook.sh for why: on exit 0
# the harness parses stdout as JSON, and `✔ allowed` is not JSON. The guard's
# reason travels on stderr either way. The no-database case stays silent: exit 2
# with "no docket database found" is the engine's NOT_FOUND riding the deny
# channel (measured directly), not a discrepancy — advisory noise about a
# repo that is not docket's business helps nobody.
#
# `guard record` denies on exactly TWO states, and this hook must not treat them
# alike. The engine computes both in one function shared with `next`
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
    # telling the conductor nothing it could act on. That alarm fatigue trains
    # conductors to ignore the real warnings in the same pile, and it made the
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
