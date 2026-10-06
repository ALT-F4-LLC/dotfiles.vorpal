# Activating a run

Consumer: the docket-run skill, whose activation paragraph in **Before the
loop** points here. Read this file in full before any activation or
re-activation, whether the panel or the operator decides it. The
activation authority, the panel's return, the token capture, and the
roster rules stay in [SKILL.md](../SKILL.md).

**Stale install:** diff the dotfiles checkout's corpus source against the
installed corpus:

```bash
DOCKET_SRC=~/Development/repository/github.com/ALT-F4-LLC/dotfiles.vorpal.git/main/src/user/docket
diff -r "$DOCKET_SRC/config" "$HOME/.docket/config"; diff -r "$DOCKET_SRC/bin" "$HOME/.docket/bin"
```

Surface any divergence; a stale pin cannot be fixed mid-run (SKILL.md's
**Pins vs disk** says why corpus installs wait between runs). `docket
doctor` runs this check too; at activation with no `--run`,
`skipped: true` is expected since the run holds no pins yet.

**Transition debris:** a `.docket/config/` full of symlinks is the
retired link-farm model. Any symlink `find .docket/config -type l`
reports is a stop-and-report for the operator to delete; real files there
are legitimate. A repo with no `.docket` is normal and this check is
vacuous. Both tree checks run before the panel; neither is a panel
matter.

**A third check, last before the panel: no activation proposal is
already standing for this run.** An activation ballot is a conversational
gate that nothing sweeps automatically: `run abandon` auto-closes only
ballots the run's own vote steps opened. Before `docket vote create`,
list what is standing:

```bash
docket vote list --json          # open proposals only, by default
```

There is no `--run` filter; match on description and `linked_issues`
against the run's issue roster (`docket issue list --run RUN-N`), then `docket vote show <id>` to
confirm. Reconcile every match:

- **Adopt it** when it names this run and the same binding. Pass its id
  to tribunal.js as `voteId`; top up missing seats per SKILL.md's **A
  panel that cannot finish escalates** if short of quorum.
- **Close it** when superseded: `docket vote close <id> --reason
  "superseded by a fresh activation proposal for RUN-N"`. `--reason` is
  required.

Skip this and ballots accumulate silently, showing the operator
outstanding work that does not exist and admitting a panel past a reap
hold.

Then `docket run activate $RUN --dry-run`, and put the binding to the
panel: issues bound, steps, pins, any lint (`scope_warnings`, verbatim),
plus what the three checks said, as the proposal's context.

**Hand-check every binding for wrong-one routing.** The dry-run flags zero
matches or several but cannot flag exactly-one-wrong match, since every
`[match]` block discriminates on labels alone and a missing label binds
`standard-change` silently. For each `bound_issues[]` row, read the
issue's labels, title, and scope and map them against the corpus's
`labels_any`/`unless_labels` (`~/.docket/config/workflows/*.toml`): an
issue bound to the baseline whose title or scope lives in a variant's
domain (TUI/UI paths without `ui`, canonically) is a routing flag, put
into the proposal context verbatim. Fixing it before the gate is one
`docket issue label add` plus a fresh dry-run; after activation, only
re-docket-planning can fix it.
