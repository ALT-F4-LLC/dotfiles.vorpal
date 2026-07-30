# Recurring-Pitfalls Memory Convention — Maintained Master

The 7 team agents carry byte-identical `CANONICAL:PITFALLS-LOCAL` pointer blocks
(parity-registered in `doctrine_check_manifest.tsv`); the full body is single-homed here.
Deployed at `~/.claude/skills/team-doctrine/references/pitfalls.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/pitfalls.md`.

---

<!-- CANONICAL:PITFALLS:BEGIN -->
**Recurring-pitfalls memory — two homes, chosen by content.** Before shutdown (ephemerals:
before or with the final report; team-lead/persistent advisors: before emitting or approving
`shutdown_request`), if this session surfaced a RECURRING pitfall — a failure/stall/diagnosis
class that has appeared before or will plausibly recur, NOT routine work or a one-shot
incident — append ONE entry in `symptom → root cause → resolution` form to exactly one home,
never both. **Classification test:** *"Would this lesson help an agent in my role working in
a DIFFERENT repository?"* YES → centralized `~/.claude/agent-memory/{role}/pitfalls.md`
(decide by root cause, not symptom — a lesson with a general root cause and a repo-specific
instantiation still files centralized only). NO → in-repo
`.claude/agent-memory/{role}/pitfalls.md`. `~/.claude/scripts/pitfalls_check.sh <role>
<in-repo|centralized>` (repo: `src/user/claude-code/scripts/pitfalls_check.sh`) resolves the
path, creates the directory if absent, and prints it for the append. Skip the write entirely
if nothing recurring surfaced — per-issue detail belongs in Docket. Both homes are harvested
by the `evolve-*` cycles: always APPEND — never overwrite, hand-edit, or remove prior
entries — and check for duplicates first (including the harvested ledger).
**Distill-time ledgering (sole sanctioned mutation, both homes):** when an edit you land
encodes an existing entry's resolution into a git-tracked definition, run
`~/.claude/scripts/pitfalls_distill.sh <role> <in-repo|centralized> --entry "<entry
first-line prefix>" --encoded-in <tracked-path> --evidence "<grep pattern>"` (repo:
`src/user/claude-code/scripts/pitfalls_distill.sh`) in the same session — it replaces that
ONE entry with a ledger line per the retention-compaction master and prints the removed
entry verbatim; MIRROR that text into the change's durable record. Docket-tracked
dispositions are NOT distillations — leave those entries live for the Phase 4 safety net.
**Boundedness:** the in-repo file's safety net is the evolve-agents History Compaction phase
(full text recoverable via git history once committed); the centralized file has no
git-backed recovery — its boundedness is the write gate above plus distill-time ledgering,
and apart from that mutation it is read-only ingest for harvest.
<!-- CANONICAL:PITFALLS:END -->
