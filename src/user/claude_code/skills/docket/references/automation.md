# Automation first

The skills that improve Docket processes share one primary goal: every remedy,
proposal, and definition they produce runs without a human in the loop,
unless a human is vital to the outcome. This file is the single copy of that
rule. Consumers: shadow, docket-retro, docket-refit, docket-reconcile,
docket-groom, docket-cli-audit, corpus-check, and corpus-cut.

## What the rule covers

The rule governs what these skills produce: a remedy shadow files, a
proposal docket-retro makes, a workflow or contract docket-refit designs,
a registry plan docket-reconcile applies, the routing and acceptance
criteria docket-groom writes, and a fix docket-cli-audit or corpus-check
lands.

It does not remove the skills' own confirmation gates. A gate that
authorizes this skill's edit, filing, registration, or commit stays: the
working agreement's "permission to prepare an action does not authorize
executing it" governs those, and this rule never overrides it. Removing or
loosening one of those gates is a change to the skill itself, made through
its own review, never inferred from this file.

## When a human is vital

A human touch is vital only when at least one of these holds:

- **Execution trust.** Granting or widening what a gate or command may run
  (`docket trust add`, a trust row, a sandbox or permission allowance).
- **Security boundary.** The change touches authentication, authorization,
  secrets, cryptography, sandboxing or permissions, supply-chain trust, or
  untrusted input at a privilege boundary.
- **Irreversible or destructive action.** Deleting unrecoverable work,
  discarding un-integrated commits, force-pushing, or abandoning a run with
  live work.
- **Spending authority.** Raising a budget or cap beyond what the operator
  already authorized.
- **Operator-only information.** The decision needs a value, priority, or
  intent that no artifact, repository, store, or prior ruling records.

Everything else is automatable: a retry, a reconciliation, a re-seat, a
routine park, a mechanical fix, a verified merge, a recurring question with
a recorded precedent, or a check a script can run.

## The automation ladder

Pick the highest rung that can carry the remedy, and say why a higher one
cannot:

1. **Engine behavior**: the engine does it, or refuses the wrong thing, by
   itself. File it against the Docket codebase.
2. **Deterministic code**: a script, `just` gate, hook, or workflow-script
   function with a test that fails on the defect.
3. **Contract or configuration**: a corpus contract, policy row, or
   workflow step that makes the executing agent do it, with a gate that
   verifies it happened.
4. **Standing ruling**: a machine-applied ruling for a recurring decision,
   recorded where the conductor or wave applies it without asking.
5. **Human gate**: last, and only with a named vital condition from the
   list above.

A remedy that keeps or adds a human touch names its vital condition in one
line. A remedy that removes one names the automated replacement, the check
that proves it ran, and what happens when that check fails. A prose
instruction to an agent sits on rung 3 only when a gate verifies the
behavior; without one it is a reminder, and a reminder is not a remedy for
a recurring defect.

## Measuring it

Every operator touch in a run is evidence: an `AskUserQuestion`, an
escalation, a `waiting-human` park, a `run-paused` or `step-held` event, a
permission prompt, an acknowledgment flag, or an operator message that
corrected the conductor. Classify each touch as vital, with its condition,
or automatable, with the rung that would have removed it. An automatable
touch that recurs is a finding in its own right.
