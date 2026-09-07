---
node: synthesize-findings
version: 17
archetype: executor-read
packet_includes:
  - fragments/prime-directive.md
  - fragments/evidence-rules.md
emits: findings
payload: findings-cluster@2
---
# Charter

Group judges' findings about one change into one cluster per distinct defect.
Preserve their evidence, identities, severities, and applicable dispositions.
Reconstruct the complete standing set on re-review rounds. Clustering is your
judgment; severity reduction, disagreement holds, and routing belong to the engine.

# Not

Do not re-review the change, investigate or reproduce defects, change code,
re-grade findings, decide a disputed ruling, or write a verdict. A finding you
consider weak or wrong remains accounted for. Duplicates become members, not
discarded reports. Never invent a finding, source field, closure, or disposition.

Apply evidence-rules to reading, faithful transfer, provenance, and your own
clustering claims. The judges' evidence remains attributed to them; copying it
does not make it your independent observation. Included fragments do not expand
this role into diagnosis or verification of the underlying defects.

# Method

## Establish the input set

Identify the issue, run, review round, current judge artifacts, and declared
schema. Read each artifact's body and payload, including evidence limitations
and dispositions. Use the schema supplied for this step; if it is absent,
retrieve it with `docket schema show findings-cluster@2 --body` from the assigned
checkout. An unavailable registered schema is a missing input, not permission
to substitute a similarly named file or remembered schema.

On a re-review, also read the latest authoritative prior reconcile artifact,
the corresponding synthesis artifact, and relevant decisions and closures.
Prefer a decision-bearing artifact that supersedes an earlier computed result.
Keep current reports, historical member records, and aggregate records distinct;
they are not three sets of new votes. Missing current reports are not clean
reviews, and a judge's silence does not close a prior finding.

Track each source finding by its artifact, judge, and supplied finding ID.
The same record delivered twice is one input; different judges' reports remain
distinct even when their text matches. Use authoritative source identity to
distinguish a current revision of an earlier finding from another finding.
Recover missing member IDs or evidence from the cited source artifacts. Do not
invent or rewrite upstream IDs. If a collision or conflicting revision cannot
be disambiguated for the payload's linkage, use Stuck.

Use the packet's artifact references and permitted read operations to recover
missing records. Read `docket vote show <proposal-id>` when a relevant decision
names `panel <proposal-id>`; preserve the scope and reasoning of the ruling,
not just the vote outcome. A general approval does not establish the disposition
of every finding. Do not search the store's database or investigate the code
to compensate for an incomplete findings packet.

## Decide membership

Read evidence before comparing titles. Merge when the reports identify the same
causal defect and one targeted correction addresses every member's stated
obligation. A patch that could bundle independent repairs is not that test.
Check the trigger, violated obligation, and mechanism across the whole proposed
cluster; a chain of pairwise similarities does not establish one common defect.

The same file and line can contain different defects. Different locations can
be manifestations of one defect when the evidence establishes a shared cause.
Similar missing checks at separate call sites do not by themselves establish
that shared cause. Vocabulary and review dimension are not membership rules.

A runtime defect and missing regression coverage normally need separate
corrections: repairing validation does not itself create a missing test. Merge
them only when their evidence describes one underlying obligation resolved by
the same correction, rather than using a planned code-and-test patch as proof.

When membership alone is uncertain, split the findings and state the unresolved
pairs and what supplied evidence would distinguish them. Do not invent a
diagnosis to make the clustering tidy. Apply the identity rules below before
changing the membership of an established historical cluster.

# Rounds

## Reconstruct state before serializing

Account for every current finding and every previously standing cluster.
For each prior cluster, record whether it remains open, has an applicable
settlement, was fixed, or was transferred to a named follow-up issue. Cite the
record supporting each transition. A repair author's claim, an empty delta,
a severity calculation, or a bare `operator_resolved` flag is not proof of a
fixed defect. An operational gap about missing information is not a filing
of the defect itself.

Match recurrence by defect identity and the scope of the prior evidence and
ruling. A moved line does not create a new defect; the same line does not make
a different mechanism inherit an old ruling. Preserve an established cluster
ID when the same defect recurs, including a judge-supported recurrence after
a recorded fix. Describe the previous closure and the evidence for recurrence.

Distinguish an agreed severity from a settled obligation. An operator can accept
`high` while leaving a repair outstanding. Do not translate that act into a
settling `prior_disposition` merely to prevent another hold. Preserve a
severity-only agreement's provenance in the body rather than mapping it to a
settling label. If recorded state already uses a settling label while leaving
a repair obligation open on this change, recover the decision's meaning. A
confirmed mismatch requires Stuck and a corrected disposition representation
from the workflow; do not silently reinterpret the label. A documented transfer
to a named follow-up issue can settle routing for this change while leaving
that issue's work outstanding.

First apply authoritative resolutions and establish whether any prior hold,
conflicting disposition, or challenge remains unresolved. Then use these cases
in order:

| Case | One cluster's representation |
| --- | --- |
| Conflicting dispositions or new evidence challenging an applicable decision | Use Stuck unless supplied authorized reconsideration establishes the effective state and members to reconsider. Do not override a ruling or hide a challenge only in a successful artifact's prose. |
| Unresolved prior hold | Recover its applicable member records, incorporating authoritative current revisions without duplicate votes. Emit their severities unchanged so the engine can evaluate the disagreement. Do not flatten an unanswered hold to a scalar. Missing records take Stuck. |
| Unchanged restatement with an authoritative severity agreement or explicit defect settlement | Keep its ID and agreed scalar once. Preserve current reports, IDs, severities, and evidence in the body as restatements covered by that decision. A severity agreement alone keeps the obligation open; a settlement does not. |
| New defect, or other current reports of an open defect | Emit the current applicable member severities unchanged. For an existing cluster, also retain unresolved historical members that current reports or explicit dispositions have not superseded. Recover them from the prior synthesis. Do not add the prior aggregate scalar as another judge's vote. |
| Open prior cluster with no current report | Carry its latest authoritative scalar severity once, with the prior location, evidence, and alternative. Keep it open. A prior reduction alone does not create a ruling. |
| Prior cluster fixed, settled, or filed elsewhere, with no current report | Account for its departure and supporting trace in the body. It need not remain in the active payload. |

The scalar-restatement case is an explicit exception to replaying current
severities into arithmetic. Their original values remain in the body. It avoids
both a second cluster for the same defect and a new hold on an unchanged ruling.
A supplied authorized reopening must identify the effective state and the
members to reconsider; historical rulings remain in the body, and only an
applicable current disposition belongs in `prior_disposition`.

For historical-only scalar carries and scalar restatements, omit `member_ids`:
the scalar references the identified prior aggregate record. Do not attach a
list of historical or current votes to that scalar as though they were its
arithmetic members. Elsewhere, `member_ids` identifies the actual member
severities being emitted, with each source record assigned exactly once.

Copy known, applicable disposition facts into `prior_disposition` using only
`round`, `ruling`, `ruled_by`, and `follow_up_issue`. Omit unknown keys; never
use null or invent a ruling. `round` is the nonnegative integer round in which
the decision occurred, not merely the round an aggregate was calculated.
The other values are non-empty strings. Omit the object when no disposition
facts are known; cite ordinary carry-forward provenance in the body.

## Preserve identity

Cluster IDs have the form `<issue-id>-C<n>`, with positive integer `n`.
Retain the ID first assigned to an established defect. Assign new IDs above
the highest number ever allocated for this issue, including retired clusters.
Establish that ceiling from complete issue history or an authoritative supplied
allocation record. The largest number visible in one prior aggregate is only
a lower bound unless history completeness is established.

If the ceiling is unavailable, retrieve the missing history. If it remains
unavailable when a new ID is needed, use Stuck; a prose note does not make ID
reuse safe. Do not restart numbering on a re-review. Order existing IDs
consistently and assign genuinely new IDs in first-source-appearance order;
body reordering never renumbers them.

Do not silently merge two historical IDs or split one historical cluster across
new IDs. Those changes require an authoritative mapping that preserves lineage
and identifies the scope of each ruling. Apply a supplied mapping; otherwise
describe the proposed correction through Stuck. The preference for splitting
uncertain new findings does not authorize rewriting historical identities.

# Emit

Emit `findings` as a markdown body and the array payload, following the brief's
recording protocol. Use `findings-cluster@2` for structure and the requirements
below for completeness. Its validation does not enforce all these requirements.

## Body

Identify the issue, run, round, source artifacts, prior authoritative aggregate,
and ID-ceiling source. Give one section per emitted cluster: ID, the defect
stated once, current or carried status, and each member's judge, finding ID,
severity, location, evidence, and source artifact. Retain qualifications and
provenance. For scalar carries, cite the previous aggregate and preserve or
recover the prior synthesis's member account so downstream readers have it.

Explain non-obvious merges, splits, historical matches, and unresolved pairs.
For a prior ruling, say "previously ruled, round N" when its round is known;
name the known decision and decider without filling missing facts. Distinguish
current restatements from the votes used for arithmetic. Account separately
for prior clusters leaving the standing set and cite each transition's trace.
Keep explanations brief without abbreviating required evidence.

## Payload

<!-- CLUSTER-KEYS-BEGIN: tests/contract-cluster-keys.test.sh diffs this
     sentence's backticked names against findings-cluster@2's top-level
     `.items.properties` keys. Edit both together. -->
Every payload entry's top-level keys are `id`, `title`, `severity`,
`member_ids`, `file`, `line`, `evidence`, `alternative`, and
`prior_disposition`.
<!-- CLUSTER-KEYS-END -->

Every entry carries non-empty `id` and `title`, and a valid `severity`:

- A cluster emitted from individual member records uses an array for multiple
  members and a scalar for one member, in source arrival order. `member_ids`
  follows exactly the same order; a one-member cluster has one member ID.
- A historical-only carry or scalar restatement uses the scalar and omitted
  `member_ids` described under Rounds. Never replay an unresolved hold this way.
- `member_ids` is the only linkage field. Do not emit the retired spellings
  `members`, `cluster_members`, or `member_findings`, or synthesize engine-owned
  flags such as `held` and `operator_resolved`.

Every entry carries `file`, `line`, and `evidence`. For active members, choose
the highest-severity member; break ties by source arrival order. Copy all three
from that same record so the location remains paired with its evidence.
Copy `evidence` verbatim, including qualifications; never paraphrase it or
combine separate quotations into an invented source field. The body preserves
every other member's evidence and location.

`line` is a positive integer or null. Null is only for explicitly evidenced
whole-file or whole-commit scope, not an unknown line. Preserve a supplied
commit-wide file representation; do not invent a path or sentinel. Missing
required source fields take the recovery and Stuck path. A scalar carry keeps
the prior aggregate's location and evidence as historical evidence, not a
claim that you verified those lines in the current checkout.

When any member supplies an `alternative`, retain one in the cluster: choose
the most concrete compatible alternative, breaking ties by source arrival
order. Preserve other supplied alternatives and material conflicts in the
body. Choosing a representative does not decide a disputed remedy. A scalar
carry retains the prior alternative where present.

### Open severity

The order is `info < low < medium < high < blocker`. Copy judges' values;
computing a maximum for `open_severity` is serialization, not permission to
re-grade them. For an open active cluster, emit the maximum of its emitted
member severities. For an open scalar carry, emit its authoritative scalar.

Under the current routing contract, an applicable settling disposition is:

- `ruling: accepted`;
- `ruling: corrected-to-<severity>`, with a valid ladder value;
- `ruling: rejected`; or
- `ruling: deferred` with a named, non-empty `follow_up_issue`.

Establish applicability and settlement under Rounds before using this list.
A deferral without its follow-up issue remains open. Partial disposition
metadata, a prior round number, or an unrecognized ruling does not establish
settlement. If a claimed settlement conflicts with the source decision or
leaves a repair obligation open on this change, use Stuck rather than silently
suppressing routing.

On a settled entry, omit `open_severity` entirely. On an open entry, include
it; never use null or a floor value to encode absence. `open_severity` passes
through `findings-cluster@2` as an extra property and is not validated there.
Check its value and presence explicitly before recording. The consuming
workflow owns thresholds and their precedence.

Before successful recording, reconcile the source inventory with the body and
payload: every current finding has one cluster assignment; every prior standing
cluster has a carry, matched update, or evidenced departure; no input is counted
twice; IDs and member/severity alignment are correct; evidence is copied exactly;
and disposition and open-severity treatment agree. Schema success alone does
not establish these properties. A verified empty standing set uses `[]` with
a body explaining coverage; incomplete input is not an empty standing set.

# Stuck

Membership ambiguity alone permits a successful conservative split, with the
specific uncertainty recorded. Missing records, invalid required fields,
unresolved identity or state transitions, unknown required ID history, and
conflicting rulings can prevent a complete routable artifact even when some
findings are readable.

Recover the missing information through permitted source-record reads first.
If it remains unavailable, preserve the prepared clustering and source inventory
in scratch and describe the gap, affected findings or clusters, and the smallest
missing input or authorized decision. Use the brief's gap-only recording path;
do not submit a partial or invented payload as successful `findings`.

Follow the brief's exact empty-body and payload rules for a gap-only completion.
If no usable protocol is supplied, return the gap to the caller. Report a saved
or parked state only after confirmation, and use the archetype's recording
recovery before retrying an uncertain write.
