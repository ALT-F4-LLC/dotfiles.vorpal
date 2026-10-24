#!/bin/bash

# Guard suite for the docket stage chain: `/docket-groom /docket-plan
# /docket-run`, alone or under `/loop`.
#
# Defect class: a stage receives the rest of the chain as its $ARGUMENTS, so
# a stage that does not split the tail off treats `/docket-plan` as an
# unknown filter word and asks an absent operator about it; a stage that
# ends its turn at its own report, or that asks a question while the chain
# holds, stops the chain. Nothing else pins the three halves of the
# contract (the split, the hands-off ruling, the hand-off), so an edit that
# drops one ships green.
#
# Prose is flattened to one line before matching, so rewrapping is not a
# failure. Each pin is anchored to the file that owns the rule.

set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
skills="$root/src/user/claude_code/skills"
chain="$skills/docket/references/chain.md"
groom="$skills/docket-groom/SKILL.md"
plan="$skills/docket-plan/SKILL.md"
run="$skills/docket-run/SKILL.md"

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

for f in "$chain" "$groom" "$plan" "$run"; do
  if [ ! -f "$f" ]; then
    echo "FAIL missing file ${f#"$root"/}"
    exit 1
  fi
done

# The shared contract names both scenarios and its three parts.
pin "$chain" '/docket-groom /docket-plan /docket-run' "chain: one-pass scenario named"
pin "$chain" '/loop /docket-groom /docket-plan /docket-run' "chain: loop scenario named"
pin "$chain" 'Split on them before any other parsing' "chain: tail split precedes parsing"
pin "$chain" 'No stage calls `AskUserQuestion` while the chain holds' "chain: no questions while hands-off"
pin "$chain" 'the main session invokes the first stage of the tail with the `Skill` tool' "chain: hand-off by Skill tool"
pin "$chain" 'Precedence is `progressed`, then `blocked`, then `idle`' "chain: outcome precedence"
pin "$chain" 'never above its 3600 second cap' "chain: loop delay within the wakeup cap"

# Every stage points at the contract and splits the tail.
for pair in "groom:$groom" "plan:$plan" "run:$run"; do
  name="${pair%%:*}"
  file="${pair#*:}"
  pin "$file" '../docket/references/chain.md' "$name: links the chain contract"
done
pin "$groom" 'First split off any chain tail' "groom: splits the tail first"
pin "$plan" '**Chain tail first.**' "plan: splits the tail first"
pin "$run" '**Under a chain.** Split any chain tail off `$ARGUMENTS` first' "run: splits the tail first"

# Hands-off rulings, per stage.
pin "$groom" '**Hands-off grooming.**' "groom: hands-off ruling present"
pin "$groom" '**§4b proposals are not asked and not applied.**' "groom: gated proposals stay pending"
pin "$groom" 'The one exception is the next stage of a chain the operator typed' "groom: hand-off exception to the never-invoke rule"
pin "$plan" 'names this skill beside another stage of the chain' "plan: ruling covers the one-pass chain"
pin "$plan" 'ends `blocked` without handing off' "plan: security answers block the chain"
pin "$run" '**A chain the operator typed starts the run unattended.**' "run: chain starts unattended mode"
pin "$run" 'the check reads the operator'"'"'s message' "run: the check reads the operator's message"
pin "$run" "switch-back question rounds are skipped" "run: no question rounds under a chain"

# Hand-off at each stage's end.
pin "$groom" 'invoke the first stage of the tail in the same turn' "groom: hands off after its report"
pin "$plan" 'invokes the first stage of the tail in the same turn' "plan: hands off after its closing statement"
pin "$run" 'close with the chain outcome line' "run: closes with the outcome line"

echo
echo "docket-chain-skill: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "docket-chain-skill: PASS"
[ "$fail" -eq 0 ]
