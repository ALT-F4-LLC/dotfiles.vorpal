#!/bin/bash

# wave-audit (03 §5, TDD §4.5) — PostToolUse: Workflow.
#
# One-line shim over `docket guard record`. Denies (exit 2) while an
# unreconciled dispatch or a discrepancy stands, naming which and how to
# resolve it. No policy, no branching on run content, no state (AC-4.1).
#
# 03 §5 calls this "a courtesy early warning": enforcement is engine-side either
# way -- `next` refuses while discrepancies stand and a TTL'd dispatch can
# always be abandoned (02 §5). The hook makes drift loud at the moment the wave
# returns instead of at the next scheduling call.
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

command -v docket >/dev/null 2>&1 || exit 0

# stdout dropped, stderr kept — see docket-spawn-guard-hook.sh for why: on exit 0
# the harness parses stdout as JSON, and `✔ allowed` is not JSON. The deny
# reason travels on stderr, which exit 2 surfaces.
exec docket guard record >/dev/null
