# Issue sizing

The one statement of how large a Docket issue may be, what its `size`
field and size label say, and when it must split. Every skill that files
an issue measures it here and passes `--size` on `docket issue create`;
`docket-plan` also applies the `small` and `trivial` labels at filing;
`docket-groom` re-measures every open issue on each pass, sizes the
unsized, and proposes the split when an issue is over the cap. A change to
a rule lands here once.

## Why size is gated

A run pays for an issue with one implement step and the review, fix, and
verify chain behind it. An issue bundling several outcomes makes that step
long, makes each review round judge several things at once, and lets one
unmet outcome park the whole issue. A step's runtime is not observable when
the issue is written, so the gate reads structure instead: the measures
below are what a filer or groomer can take from the issue body alone.

## The measures

Take four counts from the issue as it will be stored: the number of
**independent outcomes** its acceptance criteria describe, the number of
paths under `-f`, the number of distinct **directories** those paths span,
and the number of acceptance **criteria**. An outcome is independent when a
worker could deliver and verify it without delivering the others; the tell
is a criterion naming a different subsystem, verification command, or
artifact from its neighbours. A filing that carries `--scope` globs and no
`-f` path counts each distinct glob root (the path before its first
wildcard) as one directory and one verification surface, so a scope-only
filing is never read as zero-width.

## The tiers and the `size` field

The engine stores a `size` on every issue (`docket issue create --size`,
`docket issue edit --size`, filterable with `docket issue list --size`);
its vocabulary is `trivial`, `small`, `bounded`, `needs-design`, and
`unknown`, and a workflow can bind on it through a `sizes_any` match
clause. The registered corpus binds the light tracks on the `small` and
`trivial` labels, so both the field and, where a label applies, the label
are set.

| Tier | Rule | `--size` | Label | Track |
| --- | --- | --- | --- | --- |
| trivial | a typo, a config value, a doc line, or a one-line fix | `trivial` | `trivial` | trivial-change |
| small | at most two files in one directory, adds no file, every criterion verifiable from the diff or a trusted fenced command | `small` | `small` | small-change |
| bounded | one independent outcome, within the bounded ceiling below, with a known approach | `bounded` | none | the workflow its other labels bind |
| needs-design | one outcome whose approach is an open design decision the run must settle first | `needs-design` | none | a spec or investigation workflow, or docket-plan's design round |
| unknown | the filer could not measure it, or it is a bundle filed under the conduct exception below | `unknown` | none | none until groom sizes or splits it |
| oversized | above the cap: two or more independent outcomes, or one outcome past the bounded ceiling | none | none | must split |

**Default toward small and trivial.** Most work is one small, well-scoped
change. Reach for `bounded` only when the outcome genuinely cannot be
verified from a diff or a fenced command, not out of convenience. A filer
whose issue drifts toward `bounded` should first ask whether it is really
two `small` issues.

An issue meeting both the `small` and `trivial` conditions takes `small`.
Never apply the `small` or `trivial` label to a security-sensitive issue, a
ui-scoped issue (one carrying `ui`, or whose files or scope lie under a TUI
or UI surface), or one carrying any label in policy's `[security].labels`;
small-change and trivial-change run no copy-verify or render-verify step.
Such an issue keeps the matching `--size` value and carries no size label.
If a ui issue already carries a size label, remove the size label, never
the `ui` label. Confirm the binding with `docket workflow show small-change`
or `docket workflow show trivial-change`.

The brief skill's Size hint uses the same words; docket-plan carries a
confirmed hint into `--size` after its own measurement.

## The cap

An issue is oversized when any holds:

- Its acceptance criteria describe **two or more independent outcomes**.
  This is the rule; the counts below are its tells, not substitutes for it.
  One outcome with many criteria is not oversized on this ground alone;
  two outcomes with two criteria each is.
- **The bounded ceiling:** even a single outcome is oversized past
  **4 files**, **2 directories**, or **2 verification surfaces** (a Go
  package, a docs tree, a config corpus, a TUI surface each count as one).
  A wide single-outcome issue is still a bundle in effect: it usually
  decomposes into a per-surface or per-file-group piece even though no
  single criterion names two outcomes. Treat the ceiling as a prompt to
  look for that decomposition before treating the issue as irreducibly one
  thing.

Below both lines an issue may still be `bounded`. That is real work the
run's own review chain handles. The cap keeps every issue small and
independently actionable for the agents that pick it up, not merely to
catch two criteria stapled together.

### Evidence behind the cap

The cap is calibrated from 42 implement steps mined across five completed
runs in the engine project (2026-09-16), correlating each issue's stored
structure with its recorded output-token cost (`step_usage`, not the flat
`expected_cost` planning constant, which does not vary with size):

- Single-outcome issues at or under **2 files** cost 9,700-38,500 output
  tokens, needed exactly one review round and at most one fix round, and
  never parked, whatever their directory count.
- Single-outcome issues under the ceiling but wider (3-4 files, up to 2
  directories) cost more (22,000-49,600 tokens) but stayed inside one
  review-and-fix cycle.
- Issues at or past the ceiling cost sharply more and needed extra rounds:
  three single-outcome issues at 5-7 files and 2-4 directories cost
  70,600-93,100 tokens each. The issue whose implement step the operator
  observed running past an hour on 2026-09-16 (5 files, 3 directories, 4
  criteria splitting into three independent outcomes: workflow validation,
  engine routing with its mapping, and the design doc) cost 130,300
  tokens, the sample's highest, and carried no size label — over the
  ceiling and multi-outcome both.
- Every multi-outcome issue but one needed more than one review round and
  at least one fix round; the exception was caught in a single round
  anyway. Bundling outcomes consistently cost an extra round, not just more
  tokens.

Both thresholds come from where the sample's cost and rework step up, not
an invented target. Revisit these two numbers first when a later retro can
correlate structure with recorded usage across more runs.

The ceiling was re-checked against the conduct filing path on 2026-09-16:
the 55 done issues carrying `conduct` or `tribunal` across the engine and
dotfiles projects (no `loop-bound` issue existed yet) — eight through a run,
47 worked directly. The check found no reason to move either number:

- The one conduct-path issue with usage recorded after the wave-usage
  attribution fixes, a panel condition at 7 files and 4 directories, cost
  70,600 implement output tokens — already one of the three over-ceiling
  anchors above.
- In the four earlier runs, whose absolute usage predates those fixes and
  only orders steps within one run, the one filing over the directory line
  (4 files, 3 directories) was its run's most expensive implement step:
  two attempts and four to six times its peers' cache-creation tokens.
- The two under-ceiling filings needing a second review and fix round were
  one file each but bundled five and six panel conditions from distinct
  clusters — the multi-outcome ground, which the one-condition-one-issue
  rule now applies at filing. The ceiling did not catch these and is not
  meant to.
- The gap on this path is measurement input, not the threshold: 36 of the
  55 stored no `-f` path, reading zero files at the gate, while nine
  landed at 5-11 files and seven of those nine had declared at most one
  path. The `-f` requirement on every conduct filing and the scope-root
  rule under The measures close this.
- One 10-file, one-directory config edit inside a single corpus sat over
  the file line and landed cheaply as a small route-tend issue — the
  mechanical single-surface case the decomposition prompt above already
  covers, not a reason to raise the line.

## The gate at filing

`--size` is never omitted on `docket issue create` for a non-epic issue;
an epic is a container and carries no size. Before the create, take the
four measures for the issue as drafted and pick the tier:

- Under the cap: file it with its tier's `--size`, and, for docket-plan,
  its label.
- Over the cap: file one issue per independent outcome, each with its own
  `-f`, `--scope`, criteria, and `--size`, linked with `depends_on` only
  where one outcome cannot start before another.
- The conduct exception: a filer with no room to decompose (a conduct
  filing mid-wave, a leftover from `finish`) files the bundle as one issue
  with `--size unknown`, the `blocked` label, and a first line
  `Oversized: <n> outcomes; split at groom`, so groom finds it without
  re-reading the body. `unknown` is a request for groom, never a size a
  routing label may sit on.

Only docket-plan applies the `small` and `trivial` labels at filing; every
other filer sets the field and leaves labels to groom, as its own filing
contract says.

## The gate at groom

`docket-groom` measures every open non-epic issue on each pass:

- **Unsized:** `size` is null or `unknown`. Measure it and set the field as
  a field fill, after confirming with `docket workflow show` that no
  registered workflow declares `sizes_any`, so the fill changes no
  binding. If one does, the fill is approval-gated like any other
  eligibility change. An `unknown` that turns out to be a bundle is
  oversized, below.
- **Mis-sized:** the stored `size`, or the `small`/`trivial` label, no
  longer matches the tier the measures give, because a criteria repair or
  scope widen moved it. Correct the field as a field fill and the label
  under the stale-size-label rule.
- **Oversized:** over the cap. This is a split proposal in groom's approval
  step. A run-included or claimed issue cannot be split while protected:
  groom records the finding and comments the pieces, and the split waits
  for the run to release it.

No routing label goes on an issue whose `size` is null or `unknown`: an
unsized issue is not run-ready, and groom lists it as unrouted with the
size as what would settle it.

## Splitting an oversized issue

The split unit is the **independent outcome** when the issue names two or
more (the multi-outcome ground); when oversized on the bounded ceiling
alone, decompose by file or verification-surface group instead, picking the
grouping that lets each piece land and verify on its own (commonly: one
piece per directory, or one piece per surface the criteria name). Either
way the shape is the same:

- The original keeps its id, history, links, and parent, and is rescoped
  to the first piece: title, criteria, `-f`, `--scope`, and `size`
  narrowed to that piece, with the removed criteria quoted in a comment
  that names where each one went.
- Each further piece becomes a new issue in the same project with the
  original's parent epic, kind, priority, and labels other than size and
  routing labels, its own `-f`, `--scope`, and `--size`, and the criteria
  that belong to it carried verbatim. Its idempotency key derives from the
  proposal, so a retry returns the same issue.
- `depends_on` links between the pieces exist only where one piece
  cannot start until another lands. Independent pieces stay unlinked so
  a run can schedule them in one wave.
- Every resulting piece is re-measured against this same reference before
  it is filed: a split that produces another oversized piece is split
  again, not filed as is.
- Routing and size labels are re-judged per piece after the split, never
  copied from the original.

A split changes intended work, so it is approval-gated wherever it happens:
groom proposes and applies it on the operator's say-so, and docket-plan
shows the pieces in its confirmation round before recording them.
