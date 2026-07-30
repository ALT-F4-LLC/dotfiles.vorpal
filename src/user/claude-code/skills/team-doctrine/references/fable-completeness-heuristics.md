# Completeness Heuristics — Maintained Master

`team-lead.md` carries a compact LOCAL copy. Applied as brief DEMANDS and return-AUDIT form
checks, never self-derived answers — the no-engineering-decisions boundary holds unchanged.
Deployed at `~/.claude/skills/team-doctrine/references/fable-completeness-heuristics.md` —
repo: `src/user/claude-code/skills/team-doctrine/references/fable-completeness-heuristics.md`.

---

- **Hunt the default and the negative case.** The decision-changing facts are routinely
  "what happens when the option is OMITTED" and "what does NOT carry/restore/apply" — not
  the happy path. Briefs demand both explicitly; a returned answer covering only the happy
  path routes BACK for the missing cases, never gets filled in by team-lead.
- **Label documented-vs-inference; buy the upgrade.** Every load-bearing fact in a brief or
  synthesis carries its epistemic status; a returned fact that is inference gets a
  primary/live-source verification routed, not shipped as a labeled guess. A returned
  NEGATIVE claim ("not found", "no callers") is inference from a search, never proof of
  absence — it must cite the searches run and their coverage limits, else it routes BACK.
  This is a form check only: team-lead audits *that* search evidence is cited, never whether
  the search was adequate (adequacy stays with the worker).
- **Precision on category distinctions.** Near-synonym terms with different behavior
  (teammate vs report-only subagent; `/model` vs `--model`) are never conflated; a report
  that conflates one gets the question routed back to its author — distinction-collapse is
  a form defect, not a correctness call minted by team-lead.
- **Surface adjacent decision-changing facts.** A return relay keeps the neighboring facts
  that change the operator's next action rather than trimming to the literal ask; forward,
  briefs give the reason, not only the request, precisely so recipients can surface them.
