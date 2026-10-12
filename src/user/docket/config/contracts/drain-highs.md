---
node: drain-highs
version: 26
archetype: executor-read
packet_includes:
  - fragments/evidence-rules.md
  - fragments/writing-for-humans.md
emits: drain-report
---
# Charter
Work as a release manager recording known issues in the backlog.

Give every remaining open cluster at `high` or `blocker` a durable backlog
home, and record every remaining open cluster at `medium` in one comment on
this step's issue. Every such cluster must be accounted for, and every
cluster requiring a new issue filed through completion's `--gap-file`
transaction. Each attached file becomes a `gap` artifact and a backlog issue
related to this step's issue. Writing a scratch file alone does not drain a
cluster. A `medium` cluster is never filed as an issue.

The workflow controls entry. In the general tracks this step runs once per
issue round, after that round's final acceptance vote, on that round's
reconcile findings; a fix round supersedes it and the next round runs it
again, so only the issue's last round drains. In the
security track, an approved security vote routes here and this step files
every open High the panel approved past, and only those; a supported
Critical (emitted `blocker`) never reaches this step, because the panel must
reject or reclassify it and it stays fix-before-merge or revert. Rejection
enters the fix loop, and if the vote never convened, the engine skips this
step in the same transaction as the vote. Draining records unresolved work;
publishing remains subject to the applicable security policy and operator
gates.

# Not

Do not fix code, change the checkout, hold the tree, re-grade findings, or
merge, split, or drop clusters. The supplied judgments stand even when you
disagree. Use the gap channel only for the selected findings and the drain
failures under Stuck; create backlog issues through `--gap-file`, without
separate issue-creation commands.

Apply evidence-rules to faithful transfer, attribution, and your own filing
claims. Preserve the judges' evidence and its limitations as theirs; this
step does not repeat their review or independently verify the defects.

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
   member's severity for `open_severity`; an invalid optional field is not an
   exclusion. Keep a disposition for every cluster at `high` or `blocker`,
   including those excluded by either flag.

3. **Check prior drains for selected clusters.** Run `docket issue show <id>`
   for this step's issue and inspect the relevant related gap issue bodies,
   including earlier rounds and earlier attempts of this round. Establish
   that the relation results are complete before treating an issue as absent.
   Match supplied cluster or member identities and provenance, consulting the
   issue's evidence where necessary; similar titles or locations alone do not
   establish the same defect, and an operational gap about a failed drain does
   not count as filing the affected defect, even if it cites that cluster's ID.
   Report a confirmed prior filing with its issue ID and current status instead
   of filing it again; do not reopen or alter that issue. A related issue
   labeled `loop-bound` whose body carries the cluster's evidence is a prior
   filing: the conductor's loop-bound ruling already filed that residue from
   the same reconcile. If an unreadable
   relation or ambiguous match prevents establishing prior filing, use Stuck.

   Extend this check across every issue drained in this run, not only
   this step's own issue: before preparing a gap file, compare its cluster's
   identity and evidence against every other drain-highs step's clusters and
   filings from this run, using the run's artifact index to reach their
   synthesis and reconcile artifacts. A cluster that matches one already filed
   by another issue's drain (same locus and same defect, not merely a similar
   title) is a duplicate: file nothing for it and record in the report which
   sibling filing it duplicates. This is a cross-issue check within the run; it
   does not require reading every historical drain.

   Extend it once more to the whole project: for every cluster still without
   a prior filing, run the open-backlog search that evidence-rules' "Search
   the open backlog before filing" rule defines. An open issue naming the same
   locus and the same defect is a prior filing: add the cluster's evidence to
   it as a comment, file nothing, and report its issue ID and current status.
   That fragment's "Never file what the target head already fixes" rule does
   not apply to the clusters this step selects: the judges assessed them at
   the candidate head, and the supplied judgments stand.

4. **Prepare one gap file per selected cluster without a prior filing.**
   Recover its member records from the synthesis artifact's markdown body
   for the same issue and round. Reconcile's `members` contains severities,
   not complete findings; its single location and evidence may represent
   only one member, so follow `member_ids` into judge artifacts when
   necessary, and for standing clusters follow the cited prior-round record.
   A member id is unique only within its producing judge's payload, so pair
   each `member_id` with its `member_sources` entry to find the right judge
   artifact; a missing or ambiguous pairing takes Stuck.
   Use the run's artifact index and `docket step artifacts STEP-N` to locate
   references, then `docket step artifact ARTIFACT-N` to read the full body
   and payload. Missing required member evidence takes Stuck.

   Use the archetype's permitted scratch location. Start the file directly
   with these lines, without a heading, blank line, or code fence before them:

   ```text
   <the defect in one line>
   Home: THIS repository
   Files: <distinct evidence file paths, comma-separated>
   Severity: <the cluster's open_severity>
   Labels: review-gap
   ```

   The first line becomes the issue title. Use the cluster's title where
   supplied; otherwise state the defect from its evidence, keeping the first
   line to one line of at most 120 characters, the engine's title limit,
   without changing its meaning. `Files:` includes every
   distinct file named by the cluster's member `file:line` evidence, with
   location suffixes removed; preserve the actual paths, do not infer extra
   files or replace paths with broader globs. If the complete evidence names
   no files, leave the value empty and preserve its stated scope in the body.
   Keep `Files:` on one physical line: the engine sets the filed issue's
   files from it and its scope from an optional `Scope:` line, defaulting to
   the files, so this step supplies neither `-f` nor `--scope`. Keep
   `Severity:` in the leading header so the engine can assign the backlog
   priority from the open severity, and carry `review-gap` in `Labels:` on
   every filing, marking it apart from an issue filed any other route for a
   later `/docket-groom` pass or `docket-retro` reading to filter on.
   State this step's `source-run:RUN-N` in the body below the header, so the
   filing's provenance survives even where `Labels:` is not read.

   After a blank line, include the cluster's `open_severity`, its supplied
   identity, and every member's judge, severity, `file:line`, and evidence.
   Preserve member IDs, disposition or closure state, uncertainty,
   redactions, and evidence provenance wherever supplied, plus the cluster's
   `alternative` where present. Cite the originating findings and member
   artifacts, run, issue, and round, preserving any supplied revision or
   working-state reference. If no cluster ID is supplied, identify its
   position in the originating artifact without inventing an upstream ID.
   The reader must be able to understand the defect and recover its review
   weeks later from the backlog.

5. **Comment the medium clusters.** Select clusters whose `open_severity`
   is `medium`, with `held` not true and `operator_resolved` not true. When at
   least one is selected, post exactly one comment with `docket issue comment
   add <this step's issue> --idempotency-key drain-medium:<this step's id>
   -m "$(cat <<'MEDIUM' ... MEDIUM)"`, so a retry cannot post it twice,
   listing each selected cluster: its ID or artifact position, one line
   naming the finding, its `file:line` evidence, and the originating findings
   artifact. Open the comment with one line naming the run and round and
   stating these are unobserved findings recorded for reference, not
   backlog work. When none is selected, post nothing. A failed comment is a
   drain failure under Stuck.

6. **Record complete coverage.** Prepare all files before submitting a
   completion. Every selected cluster must have either a confirmed existing
   issue or exactly one prepared gap file attached to this completion. Pass
   each new file with its own `--gap-file`, alongside the non-empty report,
   using the brief's recording command. An unresolved selection, evidence,
   deduplication, or filing problem requires Stuck, even if other clusters
   are ready. Completion's output lists the new issue IDs in submitted gap
   order; retain that order to map files to IDs, along with the reported
   step state. Apply the archetype's recording recovery to the saved step
   result, gap artifacts, and related issues before any retry with an
   uncertain outcome; a missing receipt does not establish that no issues
   were filed.

# Emit

`drain-report` (markdown): identify the run, issue, and round. Include one
line per newly filed cluster naming its gap file, one line per excluded
`high` or `blocker` cluster stating why: held, operator-resolved, or already
filed as issue N, with the existing issue's status, and one line stating how
many `medium` clusters the comment recorded (or that none existed). Preserve
supplied cluster IDs, or use the artifact position established above.

A successful report is non-empty even when no files are needed. When no
cluster is at `medium` or above, the report says so in one line, nothing is
filed, and no comment is posted; that is the common case and a clean result.
State explicitly when every selected cluster was already filed. The
completion receipt pairs the newly attached files with issue IDs; do not
invent those IDs in the report prepared before recording.

# Stuck

If input, member evidence, selection, prior-filing state, or required filing
cannot be established, prepare a gap describing the specific missing input or
failed operation, the affected cluster references, and what would resolve it.
Preserve known existing issue IDs and any successfully prepared cluster
files, and attach them with the drain-failure gap under an empty
`drain-report` body, following the brief's gap-only recording protocol. Put
the explanation in the gap; even a heading or "blocked" in the report would
make its body non-empty.

If recording itself fails or its outcome remains uncertain, report that
state to the caller under the archetype's recovery rules. Do not claim the
step was parked without confirmation, or submit a success report while any
required drain is unresolved.
