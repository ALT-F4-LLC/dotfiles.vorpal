# Communication-Discipline Rule-Numbering Convention — Maintained Master

**LOCAL-copy consumers:** `team-lead.md` only — this is a self-referential meta-convention
describing how rule numbering is allocated ACROSS agent files; no worker agent cites it as its
own master (contrast with the other seven reference files, which every agent LOCAL-copies).
Relocated from `src/user/claude-code/agents/team-lead.md` Rule 5 (DKT-59/60 doctrine-home
migration). Deployed at `~/.claude/skills/team-doctrine/references/team-conventions.md` —
repo: `src/user/claude-code/skills/team-doctrine/references/team-conventions.md`. Read on
demand only — never `Skill(team-doctrine)`.

**Relocation note (this file is UPDATED text, not pure verbatim-intent — per DKT-60/E3/E4):**
the source Rule 5 text named team-lead's Rule 9 as "the minimal-informative-code-comments
policy referenced by reviewers." Post-refactor (DKT-59 Phase P3), that policy's master moves to
`senior-engineer.md` as `CANONICAL:CODE-COMMENTS` (senior-engineer authors code and owns the
policy; staff-engineer/security-engineer reviewers already carry enforcement copies) —
team-lead's Rule 9 becomes a one-line pointer to that new home instead of hosting the full
policy text. team-lead's rule COUNT is unchanged by this refactor (still Rules 1-9): Rule 5
(this convention) relocates wholesale to this file, leaving a tombstone in team-lead's Rules
section rather than inline prose; Rule 9's content shrinks to a pointer as just described;
Rules 1-4 and 6-8 are unaffected.

---

## Communication Discipline rule-numbering convention

Cross-agent coherence depends on intentional asymmetry: issue-claiming execution agents (`@senior-engineer`, `@sdet`) carry rules 1-10 (standard 1-5 + shutdown + claim-before-work + ~10-min progress + Read-before-Write + Epistemic Discipline; senior-engineer uses unnumbered bullets cross-tagged to the sdet scheme, with Read-before-Edit/Write retained as a top-level paragraph above the discipline block per sr convention — the 10 rules ARE all present even though the layout differs from sdet's numbered list); doc/review agents carry: `@staff-engineer` 1-10, `@security-engineer` 1-7, `@ux-designer` 1-8 (standard 1-4 + Read-before-Write or verify + shutdown + Epistemic Discipline; @staff-engineer adds a 9th Advisor-topology rule — recommendations route through team-lead — and a 10th relay-authority rule; @ux-designer adds an 8th Proposal-voice rule — un-applied output framed as a proposal, not a completed change); `@distinguished-engineer` (the gold seat) carries its Communication Discipline as **unnumbered bullets** — NOT a numbered scheme; do not assign it a rule count — covering the same load-bearing invariants (close-every-loop, read-before-Write/Edit, shutdown routing, relay authority, saturation, visibility contract) plus the advisor-topology relaxation, and in deep-impl mode it adopts `@senior-engineer`'s execution discipline by reference; `@project-manager` carries 1-6 (no claim/progress — doesn't execute Docket issues; +Epistemic Discipline); team-lead carries 1-10 (the +Epistemic Discipline rule lives at Rule 6; Rule 9 is a one-line pointer to `senior-engineer.md`'s `CANONICAL:CODE-COMMENTS` master, which hosts the full minimal-informative-code-comments policy referenced by reviewers; Rule 10 is the Design-Complete Gate — planning/implementation locked until every required design artifact is authored and accepted). Future evolve-agents cycles should preserve this asymmetry; flag as drift if a doc agent acquires claim-first or an execution agent loses it.
