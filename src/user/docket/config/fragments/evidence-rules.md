---
fragment: evidence-rules
version: 8
---
# Evidence rules

Every load-bearing factual claim cites what was actually read, run, or observed.
For source claims, cite the relevant `file:line` and inspected revision or
working state. For runs, give the command, working directory, relevant inputs
or configuration, exit status, and decisive output. Cite documentation for the
version in use. Distinguish observation, inference, and what remains UNVERIFIED.
Quote faithfully, mark redactions, and use confidence language the evidence
supports.

Apply the checks relevant to the claim. Reuse evidence while its inputs and
conditions remain applicable; repeat checks when a relevant change, failure, or
unresolved question warrants it.

## Establish scope and state

- **Read the actual target.** Inspect the relevant content and enough surrounding
  implementation, callers, or contracts to support the conclusion. Search hits
  locate evidence; they do not replace reading it. After an edit that could
  affect the claim or its location, re-read the affected region and resolve the
  citation again. Render the artifact when the claim concerns its rendered form.
- **Read engine records with jq or plain file reads, one read per call.** A
  `docket step context STEP-N --json` bundle carries the step's inputs at
  `.data.context.inputs[]`; project it with `jq`, or write it to a scratch file
  and read that. Never hand parsing code to an inline interpreter as an
  argument: the harness deny rule on interpreter code arguments refuses the
  call before it runs, nothing retries it, and a compound command that chains
  the read with such a call is refused as a whole, so the read never happens.
  A verdict cast after such a refusal rests on no evidence.
- **Absence needs a defined search space.** For a consequential search or count,
  establish the executable, pattern semantics, file coverage, exclusions, and
  exit status. Specify whether counting files, lines, or occurrences. Read the
  target region before trusting a custom probe's zero-hit result. A successful
  empty search supports only no matches within its verified scope; errored,
  unreadable, or materially truncated output leaves the affected claim UNVERIFIED.

## Interpret runs

- **A green result proves only what ran.** Match the evidence to the criterion:
  compilation, test execution, coverage, or runtime behavior. Before claiming
  tests passed, verify the relevant tests were discovered and executed, and
  account for skips and exclusions. Confirm that any required artifact belongs
  to the evaluated state; presence alone does not establish freshness or use.
- **Distinguish execution from cache reuse.** Identify cached results and verify
  they apply to the relevant inputs, configuration, and environment. When
  claiming fresh execution, or when cache provenance is uncertain, bypass result
  caching with the runner's supported option. Replayed logs do not prove a new
  run. Report an unavailable fresh run as unverified for that criterion.

## Validate probes and findings

- **Controls establish what a probe can detect.** Before inferring absence from
  a custom detector, run a representative known-positive control through the
  same pipeline and configuration, changing only the condition being isolated.
  Confirm the fixture reaches the check, using realistic values that satisfy its
  input requirements. A passing control supports only the behavior it exercises;
  it does not prove complete coverage.
- **Challenge positive results too.** Trace a suspected defect to the behavior,
  violated contract, and triggering conditions before reporting it. Check a
  plausible alternative explanation, especially when the result confirms your
  expectations. Use a known-negative control when a probe's specificity is in
  question. Neither a hit nor silence validates the probe by itself.
- **Compare effective coverage before assigning origin.** When a check inherits
  another tool's exclusions, establish the files each stage actually considers
  from active configuration, applicable documentation, and relevant source where
  needed. Text matches alone do not enumerate skip semantics. Compare baseline
  behavior, tool versions, and input corpora: pre-existing wording does not prove
  an exclusion was already effective. An inherited gap can still violate the
  required coverage.

## Anti-fabrication

Never invent content, commands, output, or citations from memory of similar work.
Keep evidence references and verification gaps with delegated findings and
compaction summaries, and retrieve the underlying evidence if those references
no longer suffice. Continue work that does not depend on the unknown.
