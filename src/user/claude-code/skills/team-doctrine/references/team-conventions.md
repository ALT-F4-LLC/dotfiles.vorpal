# Communication-Discipline Rule-Numbering Convention — Maintained Master

Meta-convention describing how Communication-Discipline rule numbering is allocated across
agent files; `team-lead.md` cites it. Deployed at
`~/.claude/skills/team-doctrine/references/team-conventions.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/team-conventions.md`.

---

## Communication Discipline rule-numbering convention

Cross-agent coherence depends on intentional asymmetry, so the per-agent schemes differ by
design:

- **Issue-claiming execution agents** (`@senior-engineer`, `@sdet`): rules 1-10 (standard
  1-5 + shutdown + claim-before-work + progress + Read-before-Write + Epistemic Discipline).
  senior-engineer uses unnumbered bullets cross-tagged to the sdet scheme — the 10 rules are
  all present even though the layout differs.
- **Doc/review agents**: `@staff-engineer` 1-10 (adds a 9th Advisor-topology rule —
  recommendations route through team-lead — and a 10th relay-authority rule);
  `@security-engineer` 1-7; `@ux-designer` 1-8 (adds an 8th Proposal-voice rule).
- **`@distinguished-engineer`** (capability-bound seat): unnumbered bullets — do NOT assign it a rule
  count; covers the same load-bearing invariants, and in deep-impl mode adopts
  `@senior-engineer`'s execution discipline by reference.
- **`@project-manager`**: 1-6 (no claim/progress — it doesn't execute Docket issues).
- **team-lead**: 1-11 — Epistemic Discipline at Rule 6; Rule 9 is a one-line pointer to
  `senior-engineer.md`'s `CANONICAL:CODE-COMMENTS` master; Rule 10 is the Design-Complete
  Gate; Rule 11 is the Tool-envelope check.

Future evolve-agents cycles preserve this asymmetry; flag as drift if a doc agent acquires
claim-first or an execution agent loses it.
