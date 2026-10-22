# Discovery

How a simplify-code tick finds its units: which dimensions it searches, how many
read-only agents it spends, and what each returns. The workflow
`simplify-code.js` implements it; the skill's §1 launches it. A change to a
dimension or a cap lands in the workflow and here together.

## Dimensions

A round searches along three axes at once. Each is a separate scout, so one
scout's blind spot is another's find.

1. **Catalog sections.** One scout per pattern section of the
   [catalog](catalog.md): Comments and noise, Dead code, Needless
   indirection, Duplication, Control flow and error handling, Naming and
   shape. A section scout returns only that section's entries.
   *Report only* and *Leave alone* are not pattern sections: the first
   belongs to the report-only signal, the second is the refuters' defense
   list.
2. **Angles.** At `deep`, each section runs twice. The lexical scout leads
   with each entry's Signal (grep, LSP); the semantic scout ignores the
   signals and reads the largest and most-changed files as a maintainer, to
   catch variants a pattern search misses.
3. **Signals.** Four scouts that find units by evidence other than a pattern:
   - `unused`: the repository's own lint, typecheck, and build output (the
     diagnostics the repository already produced, passed in by the skill when
     any exist; the skill runs no build or lint) as ground truth for
     unused imports, parameters, locals, functions, and exports, confirmed
     by search across the tree.
   - `churn`: files ranked by git touches over six months; the top twenty
     are read for any entry, because cruft in a hotspot is read most.
   - `duplicates`: near-identical bodies and blocks across files, by
     normalized comparison or the repository's clone detector.
   - `report-only`: every item in the catalog's Report only section, tree
     wide, each with its enclosing symbol.

   At `simple`, one `combined` scout runs all four signals.

All scouts are read-only: search, read, LSP, and read-only git. None builds,
tests, or writes, so they leave the checkout exactly as they found it.

## Refutation

After scouting, the workflow merges units by path, drops the excluded
ones (tests, generated and vendored files, ledgered paths, security
boundaries), ranks the rest, and sends the top units to refuters. A refuter
defaults to refuted and must confirm each numbered item is real: the code is
where the item says, its entry applies, and no Risk field or Leave alone case
covers it. At `deep`, two refuters lead from different angles (false positive,
evidence) and both must uphold an item. A refuter that returned nothing
refutes nothing. An item a refuter explicitly rejected is remembered by its
key and passed back as `refutedKeys`, so later rounds do not re-find it
until its path changes. A key a kept or unvoted item shares is not
remembered. The skill passes the keys of skipped, declined, and filed
findings the same way.

Units ranked below the cut, units whose refutation failed, and units with an
item that got no vote come back as `unverified`, each with a reason. Those
items are nothing yet; the same unit's confirmed findings still count.

## Depth

The operator picks a named level, never a number. The caps are hard: the
workflow refuses to start a round whose plan exceeds its cap, and refuses to
seat an agent past it.

| Depth | Agents (cap) | Scouts | Units refuted | Refuters each |
| --- | --- | --- | --- | --- |
| `simple` | 10 | 6 section + 1 combined signal | 3 | 1 |
| `standard` | 15 | 6 section + 4 signal | 5 | 1 |
| `deep` | 30 | 12 section (2 angles) + 4 signal | 6 | 2 |

A depth passed with the invocation wins; otherwise the recorded depth in
`simplify-state.md` wins; otherwise an attended invocation asks, once, a
named-level question, and an unattended one uses `simple`.
