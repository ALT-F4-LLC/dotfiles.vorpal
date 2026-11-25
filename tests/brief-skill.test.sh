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
pin "$brief" "review on \`/goal\` or \`/loop\` still goes through an advisor consult from this session, or a peer; a workflow's own verify stage or agents do not replace it. A workflow" "brief: security review not replaced"
pin "$brief" "route the change's review through the advisor or a peer, and show the peer's output or the advisor's advice, summarized." "brief: security duty shows the peer's output or the advisor's advice"
pin "$brief" 'routed here by the harness rule or by an operator override of rule 1' "brief: security duty covers harness briefs"
pin "$brief" "When ultracode is off, \`/goal\` and \`/loop\` work runs a workflow only when the operator's own words ask for one" "brief: off reverts to opt-in"

# The advisor is a consult, not a launch. It sees the conversation and no file,
# so the caller reads passages in first and the draft reaches it through a
# tool call.
pin "$brief" 'When the session has the advisor tool, each round starts with one consult.' "brief: each round starts with one consult"
pin "$brief" 'before consulting, the caller reads each passage that bounded read-only inspection needs into the conversation' "brief: caller reads passages before consulting"
pin "$brief" 'the draft reaches the advisor only through a tool call that carries it, such as writing it to a scratch file with the Write tool, never through reply text the operator reads' "brief: draft reaches the advisor through a tool call"
pin "$brief" 'the draft brief, which lists its open questions and reaches the advisor only through a tool call that carries it;' "brief: consult carries the draft through a tool call"
pin "$brief" 'states the following in the conversation, except the draft brief, which goes in a scratch file written with the Write tool:' "brief: only the draft goes in the Write-tool scratch file"
pin "$brief" "is closed, not asked, and disclosed as advisor-settled, but only when the advisor's reply itself names exactly one offered option for it and affirms that it is an evidence question, not a preference, and outside the reserved classes; any other reply leaves it open." "brief: a question closes only on an explicit pick"
pin "$brief" "clause, which acts only on an advisor reply that names exactly one offered option for it and affirms that it is an evidence question, not a preference, and outside the reserved classes." "brief: Delegated acts only on an explicit pick"
pin "$brief" 'each question classified as evidence or preference, with the reserved classes named.' "brief: drafted set classifies each question"
pin "$brief" 'an answer to each question that the passages read decide;' "brief: consult answers rest on passages read"
pin "$brief" 'Reopen a settled question, or raise a dropped one again, only on new evidence.' "brief: settled questions reopen on new evidence only"
pin "$brief" 'A session with no advisor, because the tool is missing or returns an error, interrogates the operator alone.' "brief: no advisor means operator alone"
pin "$brief" 'it never skips the consult that confirms nothing is open' "brief: a clear request still gets the confirming consult"
pin "$brief" 'Make that consult §4'"'"'s: the text before it carries the draft brief, the route, and the confirmation question, so a clear request costs one consult.' "brief: the §4 consult ends the loop"
pin "$brief" 'write the draft brief, the route, and the drafted confirmation question to a scratch file with the Write tool, so the advisor sees them and the operator is shown nothing unconfirmed.' "brief: §4 draft reaches the advisor through the Write tool"

# A passage the caller read backs an answer; the advisor's say-so does not.
pin "$brief" "Fold an answer into the brief as source-backed only when it rests on a passage the caller read; the label belongs to that passage, not to the advisor's say-so." "brief: source-backed rests on a passage the caller read"

# Protective direction: inspection and the Recommended pick both lean to the
# value that grants nothing.
pin "$brief" 'A Security-sensitive question closes by inspection only toward the more protective value.' "brief: Security-sensitive inspection closes only toward the protective value"
pin "$brief" 'on a Reserved or security-override question, the protective option takes it: the one that grants nothing and leaves the gate failed.' "brief: Reserved and security-override questions recommend the protective option"
pin "$brief" "The advisor's pick takes \`(Recommended)\`;" "brief: the advisor's pick takes Recommended"
pin "$brief" "its pick is the recommended route below, and a differing §3 route is shown beside it as dissent. On a Reserved or security-override question the protective option takes \`(Recommended)\` instead, and the advisor's pick, if different, is shown in its description." "brief: the confirmation's Reserved question recommends the protective option and shows the advisor's pick"

# Before confirmation tools stay read-only; the one exception is the draft's
# scratch file, which lies outside the repository.
pin "$brief" 'read-only checks needed to describe or route the request. The one exception is the Write of the draft to a scratch file outside the repository.' "brief: the one pre-confirmation write is the draft's scratch file outside the repository"

# absent FILE LITERAL DESCRIPTION: the flattened file does not contain LITERAL.
absent() {
  if flat "$1" | grep -qF -- "$2"; then
    fail=$((fail + 1))
    echo "FAIL $3 (still in ${1#"$root"/}: $2)"
  else
    pass=$((pass + 1))
    echo "ok   $3"
  fi
}

absent "$brief" 'launch' "brief: no advisor launch wording"
absent "$brief" 'in the conversation or in a scratch file' "brief: the draft has no conversation route"
absent "$brief" 'scratch file in the repository' "brief: the scratch file is never inside the repository"
absent "$brief" 'The one exception is the Write of the draft to a scratch file inside' "brief: the exception names no inside-the-repository file"
absent "$brief" 'travels only inside' "brief: no launch-only draft route"
absent "$brief" 'an answer, with its locator, to each question' "brief: no locator-quoted answer"
absent "$brief" 'Read the located passage' "brief: no read-the-located-passage step"
absent "$brief" 'A session that cannot launch' "brief: no cannot-launch fallback"

echo
echo "brief-skill: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "brief-skill: PASS"
[ "$fail" -eq 0 ]
