#!/bin/bash

# Guard suite for the brief skill's ultracode contract.
#
# Defect class: the builder emits `ultracode: true` (src/user/claude_code.rs).
# A session with ultracode on runs a Workflow for every substantive task
# without being asked. A brief skill that ignores it
# lets a workflow start before confirmation, hands /goal a condition whose
# evaluator never sees workflow results, schedules a /loop whose per-pass
# cost the operator never confirmed, or lets a workflow's own verify stage
# stand in for the security review. Nothing else pins these clauses, so an
# edit that drops one ships green.
#
# Prose is flattened to one line before matching, so rewrapping is not a
# failure.

set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
brief="$root/src/user/claude_code/skills/brief/SKILL.md"

pass=0
fail=0

flat() { tr '\n' ' ' <"$1" | tr -s ' '; }

# pin FILE LITERAL DESCRIPTION: the flattened file contains LITERAL.
pin() {
  if flat "$1" | grep -qF -- "$2"; then
    pass=$((pass + 1))
    echo "ok   $3"
  else
    fail=$((fail + 1))
    echo "FAIL $3 (missing in ${1#"$root"/}: $2)"
  fi
}

if [ ! -f "$brief" ]; then
  echo "FAIL missing file ${brief#"$root"/}"
  exit 1
fi

# State detection.
pin "$brief" 'Ultracode is on when a message from the system in this session confirms it' "brief: state comes from a system message"
pin "$brief" 'The shipped settings default is not that evidence' "brief: settings default is not evidence"

# No workflow before the route starts the work.
pin "$brief" 'Ultracode (§3) does not widen it: no `Workflow` runs until the confirmed route starts the work' "brief: Boundaries hold under ultracode"
pin "$brief" 'a pending `/goal` line, and `Just give me the brief`' "brief: guard covers pending goal and brief-only"
pin "$brief" 'a `Workflow` run is how a route executes its work, never a route of its own' "brief: workflow is not a route"

# Per-route effects.
pin "$brief" "That changes how the executing routes run, not which one §3 selects" "brief: routing unchanged"
pin "$brief" 'work above `trivial` runs in this conversation as one workflow per phase' "brief: /goal runs workflows above trivial"
pin "$brief" 'State the brief'"'"'s Size hint, and state in a reply each workflow result that settles a criterion' "brief: /goal condition carries Size hint and workflow results"
pin "$brief" 'an `unknown` hint counts as above `trivial`, so it raises no question of its own' "brief: unknown Size hint resolves without a question"
pin "$brief" 'a `Workflow` run is not a team' "brief: workflow is not a team"
pin "$brief" 'on whatever rule or operator choice the route was confirmed' "brief: /loop note covers an operator-picked loop"
pin "$brief" "the evaluator cannot open a workflow's journal or agent transcripts" "brief: duty reason stated"
pin "$brief" '`each pass runs a workflow while ultracode is on`' "brief: /loop records the per-pass workflow"
pin "$brief" 'The peer session applies its own ultracode state when it reselects the route under these rules' "brief: /peer defers to the peer's state"
pin "$brief" "its one confirmation says so when that route's work runs through workflows" "brief: peer confirmation names the workflow cost"
pin "$brief" 'Planning is a conversation with the operator and records the run without executing it, so it stays solo' "brief: /docket-plan planning stays solo"
pin "$brief" 'an eligible `/goal` or `/loop` line whose work is not trivial says it runs through workflows' "brief: confirmation names the workflow cost"

# Authority and review stay put.
pin "$brief" 'it adds no authority. A Security-sensitive' "brief: no added authority"
pin "$brief" "review on \`/goal\` or \`/loop\` still goes through the advisor, launched from this session, or a peer; a workflow's own verify stage or agents do not replace it. A workflow" "brief: security review not replaced"
pin "$brief" 'routed here by the harness rule or by an operator override of rule 1' "brief: security duty covers harness briefs"
pin "$brief" "When ultracode is off, \`/goal\` and \`/loop\` work runs a workflow only when the operator's own words ask for one" "brief: off reverts to opt-in"

echo
echo "brief-skill: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "brief-skill: PASS"
[ "$fail" -eq 0 ]
