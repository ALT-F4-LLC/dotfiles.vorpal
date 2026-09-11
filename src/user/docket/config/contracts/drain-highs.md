---
node: drain-highs
version: 10
archetype: executor-read
packet_includes:
  - fragments/prime-directive.md
  - fragments/evidence-rules.md
  - fragments/writing-for-humans.md
emits: drain-report
---
# Charter

Give every remaining open cluster at `high` or `blocker` a durable backlog
home. Success means every such cluster is accounted for and every cluster
requiring a new issue is filed through completion's `--gap-file` transaction.
Each attached file becomes a `gap` artifact and a backlog issue related to
this step's issue. Writing a scratch file alone does not drain a cluster.

The workflow controls entry. In standard tracks, reconcile routes here when
open highs remain and no open blocker matches `fix-loop` first. In the
security track, an approved security vote routes here; drain any remaining
open blockers as well as highs. Rejection enters the fix loop. If the vote
never convened, the engine skips this step in the same transaction as the
vote. Draining records unresolved work; publishing remains subject to the
applicable security policy and operator gates.

# Not

Do not fix code, change the checkout, hold the tree, re-grade findings, or
merge, split, or drop clusters. The supplied judgments stand even when you
disagree. Use the gap channel only for the selected findings and the drain
failures described under Stuck. Create backlog issues through `--gap-file`,
without separate issue-creation commands.

Apply evidence-rules to faithful transfer, attribution, and your own filing
claims. Preserve the judges' evidence and its limitations as their evidence;
this step does not repeat their review or independently verify the defects.

# Method

1. **Read the complete input for this round.** Identify the assigned run,
   issue, round, and reconcile findings artifact from the brief. Use the
   supplied schema. Missing, truncated, or malformed input that prevents
   complete selection takes the Stuck path.

2. **Select mechanically.** The severity order is
   `info < low < medium < high < blocker`. Select clusters whose
   `open_severity` is `high` or `blocker`, with `held` not true and
   `operator_resolved` not true. An absent `open_severity` denotes settled
   ground under this workflow. Do not substitute historical `severity` or a
   member's severity for `open_severity`. Interpret optional fields under
   the schema; an invalid value is not an exclusion. Keep a disposition for
   every cluster whose `open_severity` is `high` or `blocker`, including
   those excluded by either flag.

3. **Check prior drains for selected clusters.** Run `docket issue show <id>`
   for this step's issue and inspect the relevant related gap issue bodies,
   including earlier rounds and earlier attempts of this round. Establish
   that the relation results are complete before treating an issue as absent.
   Match supplied cluster or member identities and provenance, consulting the
   issue's evidence where necessary. Similar titles or locations alone do not
   establish the same defect. An operational gap about a failed drain does not
   count as filing the affected defect, even if it cites that cluster's ID.
   Report a confirmed prior filing with its issue ID and current status instead
   of filing it again. Do not reopen or alter that issue.
   If an unreadable relation or ambiguous match prevents establishing prior
   filing, use Stuck.

   Extend this check across every issue drained in the same wave, not only
   this step's own issue: before preparing a gap file, compare its cluster's
   identity and evidence against every other drain-highs step's clusters and
   filings from this run, using the run's artifact index to reach their
   synthesis and reconcile artifacts. A cluster that matches one already
   filed by another issue's drain — same locus and same defect, not merely a
   similar title — is a duplicate: file nothing for it and record in the
   report which sibling filing it duplicates. This is a same-wave,
   cross-issue check; it does not require reading every historical drain.

4. **Prepare one gap file per selected cluster without a prior filing.**
   Recover its member records from the synthesis artifact's markdown body
   for the same issue and round. Reconcile's `members` contains severities,
   not complete findings; its single location and evidence may represent
   only one member. Follow `member_ids` into judge artifacts when necessary.
   For standing clusters, follow the cited prior-round record. Use the run's
   artifact index and `docket step artifacts STEP-N` to locate references,
   then `docket step artifact ARTIFACT-N` to read the full body and payload.
   Missing required member evidence takes Stuck.

   Use the archetype's permitted scratch location. Start the file directly
   with these lines, without a heading, blank line, or code fence before them:

   ```text
   <the defect in one line>
   Home: THIS repository
   Files: <distinct evidence file paths, comma-separated>
   Severity: <the cluster's open_severity>
   Labels: review-gap[, security-load-bearing]
   ```

   The first line becomes the issue title. Use the cluster's title where
   supplied; otherwise state the defect from its evidence. Keep the first
   line to one line without changing its meaning. `Files:` includes every
   distinct file named by the cluster's member `file:line` evidence, with
   location suffixes removed. Preserve the actual paths; do not infer extra
   files or replace paths with broader globs. If the complete evidence names
   no files, leave the value empty and preserve its stated scope in the body.
   The conductor promotes this line into file and scope metadata at close;
   this step does not supply `-f` or `--scope`. Keep `Severity:` in the leading
   header so the engine can assign the backlog priority from the open severity.
   Every filing carries `review-gap` in `Labels:`, marking it apart from an
   issue filed any other route for a later `/tend` pass or `docket-retro`
   reading to filter on; also state this step's `source-run:RUN-N` in the
   body below the header so the filing's provenance survives even where
   `Labels:` is not read.

   Apply `security-load-bearing` at this filing, not later at activation:
   check the cluster against `policy.toml`'s `[security]` labeling test
   (the six control classes it enumerates, and the rule that changing,
   relocating, or deleting a control's implementation all qualify). Add it
   to the same `Labels:` line when it applies, and state which control class
   in the body. This is the test's sole application site; do not re-derive
   it elsewhere.

   After a blank line, include the cluster's `open_severity`, its supplied
   identity, and every member's judge, severity, `file:line`, and evidence.
   Preserve member IDs, disposition or closure state, uncertainty, redactions,
   and evidence provenance wherever supplied. Include the cluster's
   `alternative` where present. Cite the originating findings and member
   artifacts, run, issue, and round, preserving any supplied revision or
   working-state reference. If no cluster ID is supplied, identify its
   position in the originating artifact without inventing an upstream ID.
   The reader must be able to understand the defect and recover its review
   weeks later from the backlog.

5. **Record complete coverage.** Prepare all files before submitting a
   completion. Every selected cluster must have either a confirmed existing
   issue or exactly one prepared gap file attached to this completion. Pass
   each new file with its own `--gap-file`, alongside the non-empty report,
   using the brief's recording command. An unresolved selection, evidence,
   deduplication, or filing problem requires Stuck, even if other clusters
   are ready. Completion's output lists the new issue IDs in submitted gap
   order; retain that order to map files to IDs, along with the reported step
   state. Apply the archetype's recording recovery to the saved step result,
   gap artifacts, and related issues before any retry with an uncertain
   outcome. A missing receipt does not establish that no issues were filed.

# Emit

`drain-report` (markdown): identify the run, issue, and round. Include one
line per newly filed cluster naming its gap file, and one line per excluded
`high` or `blocker` cluster stating why: held, operator-resolved, or already
filed as issue N. Include the existing issue's status for prior filings.
Preserve supplied cluster IDs, or use the artifact position established above.

A successful report is non-empty even when no files are needed. State
explicitly when no clusters qualify or every selected cluster was already
filed. The completion receipt pairs the newly attached files with issue IDs;
do not invent those IDs in the report prepared before recording.

# Stuck

If input, member evidence, selection, prior-filing state, or required filing
cannot be established, prepare a gap describing the specific missing input
or failed operation, the affected cluster references, and what would resolve
it. Preserve known existing issue IDs and any successfully prepared cluster
files. Attach the ready cluster files and the drain-failure gap with an empty
`drain-report` body, following the brief's gap-only recording protocol. Put
the explanation in the gap; even a heading or “blocked” in the report would
make its body non-empty.

An accepted gap-only completion parks the step `waiting-human`. If recording
itself fails or its outcome remains uncertain, report that state to the caller
under the archetype's recovery rules. Do not claim the step was parked without
confirmation, or submit a success report while any required drain is unresolved.
