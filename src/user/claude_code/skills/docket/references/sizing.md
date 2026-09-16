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
verify chain behind it. An issue that bundles several outcomes makes that
step long, makes each review round judge several things at once, and lets
one unmet outcome park the whole issue. The runtime of a step is not
observable when the issue is written, so the gate reads structure instead:
the measures below are what a filer and a groomer can take from the issue
body alone.

## The measures

Take four counts from the issue as it will be stored: the number of
**independent outcomes** its acceptance criteria describe, the number of
paths under `-f`, the number of distinct **directories** those paths span,
and the number of acceptance **criteria**. An outcome is independent when
a worker could deliver and verify it without delivering the others; the
tell is a criterion that names a different subsystem, a different
verification command, or a different artifact from its neighbours.

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
verified from a diff or a fenced command; do not default to it out of
convenience. A filer who finds an issue drifting toward `bounded` should
first ask whether it is really two `small` issues.

An issue meeting both the `small` and `trivial` conditions takes `small`.
Never apply the `small` or `trivial` label to a security-sensitive issue,
to a ui-scoped issue (one carrying `ui`, or whose files or scope lie under
a TUI or UI surface), or to one carrying any label in policy's
`[security].labels`; small-change and trivial-change run no copy-verify
or render-verify step. Such an issue keeps the matching `--size` value
and carries no size label. If a ui issue already carries a size label,
remove the size label, never the `ui` label. Confirm the binding with
`docket workflow show small-change` or `docket workflow show trivial-change`.

The brief skill's Size hint uses the same words; docket-plan carries a
confirmed hint into `--size` after its own measurement.

## The cap

An issue is oversized when any holds:

- Its acceptance criteria describe **two or more independent outcomes**.
  This is the rule; the counts below are its tells, not substitutes for
  it. One outcome with many criteria is not oversized on this ground
  alone; two outcomes with two criteria each is.
- **The bounded ceiling:** even a single outcome is oversized past
  **4 files**, **2 directories**, or **2 verification surfaces** (a Go
  package, a docs tree, a config corpus, a TUI surface each count as
  one). A wide single-outcome issue is still a bundle in effect: it
  usually decomposes into a per-surface or per-file-group piece even
  though no single criterion names two outcomes. Treat the ceiling as a
  prompt to look for that decomposition before treating the issue as
  irreducibly one thing.

Below both lines an issue may still be `bounded`. That is real work the
run's own review chain handles. The cap exists to keep every issue small
and independently actionable for the agents that pick it up, not merely
to catch two criteria stapled together.

### Evidence behind the cap

The cap is calibrated from 42 implement steps mined across five completed
runs in the engine project (2026-09-16), correlating each issue's stored
structure with its actual recorded output-token cost (`step_usage`, not
the flat `expected_cost` planning constant, which does not vary with size):

- Every single-outcome issue at or under **2 files** cost 9,700-38,500
  output tokens and needed exactly one review round, one fix round or
  fewer, and never parked, whatever its directory count.
- Single-outcome issues wider than that but still under the ceiling
  (3-4 files, up to 2 directories) cost more per issue (22,000-49,600
  tokens) but stayed inside one review-and-fix cycle.
- Every issue at or past the ceiling cost sharply more and needed extra
  rounds: three single-outcome issues at 5-7 files and 2-4 directories
  cost 70,600-93,100 tokens each. The issue whose implement step the
  operator observed running past an hour on 2026-09-16 (5 files, 3
  directories, 4 criteria splitting into three independent outcomes:
  workflow validation, engine routing with its mapping, and the design
  doc) cost 130,300 tokens, the highest of the sample, and carried no
  size label. It failed both grounds above: over the ceiling and
  multi-outcome.
- Every multi-outcome issue in the sample but one needed more than one
  review round and at least one fix round; the sole exception was caught
  in a single round anyway. Bundling outcomes did not just cost more, it
  consistently cost an extra round.

Both thresholds come from where the sample's cost and rework actually
step up, not from an invented target. When a later retro can correlate
structure with recorded usage across more runs, revisit these two numbers
first.

## The gate at filing

`--size` is never omitted on `docket issue create` for a non-epic issue;
an epic is a container and carries no size. Before the create, take the
four measures for the issue as drafted and pick the tier:

- Under the cap: file it with its tier's `--size`, and, for docket-plan,
  its label.
- Over the cap: file one issue per independent outcome instead, each with
  its own `-f`, `--scope`, criteria, and `--size`, linked with
  `depends_on` only where one outcome cannot start before another.
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

- **Unsized:** `size` is null or `unknown`. Measure it and set the field
  as a field fill, after confirming with `docket workflow show` that no
  registered workflow declares `sizes_any`, so the fill changes no
  binding. If one does, the fill is approval-gated like any other
  eligibility change. An `unknown` that turns out to be a bundle is
  oversized, below.
- **Mis-sized:** the stored `size`, or the `small`/`trivial` label, no
  longer matches the tier the measures give, because a criteria repair or
  a scope widen moved it. Correct the field as a field fill and the label
  under the stale-size-label rule.
- **Oversized:** over the cap. This is a split proposal in groom's
  approval step. A run-included or claimed issue cannot be split while
  protected: groom records the finding and comments the pieces, and the
  split waits for the run to release it.

No routing label goes on an issue whose `size` is null or `unknown`: an
unsized issue is not run-ready, and groom lists it as unrouted with the
size as what would settle it.

## Splitting an oversized issue

The split unit is the **independent outcome** when the issue names two or
more (the multi-outcome ground); when it is oversized on the bounded
ceiling alone, decompose by file or verification-surface group instead,
picking the grouping that lets each piece land and verify on its own
(commonly: one piece per directory, or one piece per surface the criteria
name). Either way the shape is the same:

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

A split is a change to intended work, so it is approval-gated wherever it
happens: groom proposes it and applies it on the operator's say-so, and
docket-plan shows the pieces in its confirmation round before recording
them.
