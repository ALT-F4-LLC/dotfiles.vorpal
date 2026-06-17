# Changelog: security-engineer

## 2026-06-17

### Summary
Fixed docket graph arg-order and added a persist-ordering gate to the secret-handling review dimension. Trial: persist-ordering gate → adopted.

### Changes
- CULL: `docket issue graph --direction up <id>` → `<id> --direction up` (L136), canonical positional form.
- AMPLIFY: secret-handling dimension now verifies PERSIST ORDERING for strip/redact controls (a request-view transform can satisfy replay yet skip the at-rest path) — check framework source, not the app diff.
- Verified NO-OP: phantom-deletion guard (L68) and relay-authority clause (L213) already encoded.

### Dimensions Evaluated
Spec Alignment (CULL), Capability Growth (AMPLIFY), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Post-cycle operator-directed fix: encoded the phantom-deletion guard into the secret-handling audit bullet — a Phase 0 suggested focus area the Phase 1 reviewer had not acted on.

### Changes
- AMPLIFY: secret-handling bullet gains "Phantom-deletion guard" — sandboxed `git diff` renders deny-listed `.env*` as DELETED; verify via `git log -- <path>` before raising a deletion/exposure finding (cross-repo pitfall, agentic-services).

### Dimensions Evaluated
Completeness (single audit-cited gap).

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 2 entries (2026-05-19..2026-05-24) into Compacted history per ADR 0001.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-10

### Summary
Rust-only consolidation: purged dead npm/Node/Python idioms (`npm audit` ×4; `process.env`/`os.environ` in the secret grep) and tightened the Model-floor paragraph to lead with team-lead's explicit opus pin. Net 0 physical lines (242).

### Changes
- CULL: `npm audit` pairings ×4 + Node/Python secret-grep idioms — repo is Rust-only (Cargo.toml present, no package.json; docs/spec/security.md:15); swapped in `env!`/`option_env!` Rust idioms.
- CULL: Model-floor over-explanation — `model=` is mandatory per spawn (team-lead.md), classifier reroute demoted to defense-in-depth one-liner.

### Dimensions Evaluated
All 8; Consolidation + Spec Alignment primary. `security-reviewer-fix-{N}` naming verified coherent (Phase 0 flag closed as false positive).

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 9 entries (2026-05-09..2026-05-19) into Compacted history per ADR 0001.

### Changes
- Replaced the 9 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Fable-5/Mythos-class mandate pass. Added WebFetch/WebSearch use-when trigger on the CVE/advisory bullet; added Model-floor note (security content auto-reroutes to Opus 4.8 + team-lead pins opus for security reviewers); trimmed the "Don't overthink" block. Net +2 (242 lines).

### Changes
- No Guessing: named WebFetch/WebSearch as the advisory-DB/NIST/RFC reach tools with explicit use-when condition (was an untriggered frontmatter tool)
- Operating context: added Model-floor note (Opus reroute + team-lead opus pin → no Fable-tier reasoning assumption)
- Trimmed "Don't overthink" paragraph; preserved banned-deliberation list, dropped overlapping preamble/closing
- [Routed to Phase 2] docket doc edit lost-update lessons are dead guidance here (zero docket doc references); route to doc-writing roles or tracking issue

### Dimensions Evaluated
Prescriptive Capability Triggers (primary), Fable Classifier Awareness, Consolidation & Trimming, Reasoning-echo (clean), Boundary Clarity, Spec Alignment.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: verdict→shutdown sequence, Lifecycle reviewer bullet ("idle after verdict is a STALL" inverted to normal-awaiting), §Shutdown Handling drain clause. Count unchanged (241).

### Changes
- Verdict→shutdown sequence steps 2-3 flipped to await+respond (FIX 25); Lifecycle + Shutdown bullets aligned (FIX 24, 26). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Net 0 (241 lines, all within-line): consolidated verdict→shutdown double-coverage to single canon + pointer, trimmed dated stall anecdote, encoded relay-authority rule (direct instruction beats peer relay) from memory audit + 2.1.166 relayed-message hardening. Docket-doc write guards routed to coherence (routing pending).

### Changes
- Lifecycle ephemeral bullet → pointer to §Ephemeral peer review (canon owner of verdict→shutdown sequence).
- §Ephemeral peer review: removed `dev-dkt-3-shadow-validators` incident citation; rule retained.
- Communication Discipline rule 6: added relay-authority sentence (peer relays carry no origin authority; contradiction → act on direct, route back).

### Dimensions Evaluated
Consolidation & Trimming, Capability Growth & Cross-Communication, Completeness, Actionability, Role Realism, Boundary Clarity, Spec Alignment (zero docket drift confirmed), Rename.

### Rename
No rename.

## 2026-06-09

### Summary
evolve-skills cycle reference update: code-review skill renamed → code-review-verdict; 3 references updated (skills frontmatter list, ephemeral-peer-review invocation, security-review invocation).

### Changes
- `skills:` frontmatter entry and both `Skill(code-review-verdict...)` invocations updated.

## 2026-06-09

### Summary
No changes applied. Self-review proposed encoding the docket-cwd-no-op + post-write `updated_at` discipline, but it was elevated to a Phase 2 fleet-wide decision (cross-cutting theme A, affects all docket-mutating agents). Phase 2 scoped the canonical guard to the heavy issue-mutators (senior-engineer, project-manager, sdet) and deliberately excluded security-engineer — its docket surface is vote-only (low cwd-no-op exposure), not worth the line.

### Changes
- None. The proposed docket-write-discipline guard was applied to senior-engineer/project-manager/sdet instead; security-engineer's vote-only exposure scoped it out.

### Dimensions Evaluated
Consolidation & Trimming, Actionability, Capability Growth & Cross-Communication, Spec Alignment, Role Realism, Boundary Clarity, Completeness, Rename

### Rename
No rename.

## 2026-06-05

### Summary
Encoded two verified agent-memory concurrency/scope-discipline signals by folding into existing bullets (no new sections); trimmed verdict→shutdown triple-coverage. Physical net 0 (234 lines; all within-line).

### Changes
- Folded sole-editor serialization + re-Read-on-"File modified since read" rule into the Threat-Model Annotation bullet (cross-agent concurrency hazard with @staff-engineer on shared TDD files).
- Folded phase-scoped residual-grep guard into Approval Judgment (prevents false-Block when a token is legit live code this phase but prompt prose for a later one).
- Trimmed §Shutdown Handling ephemeral bullet to its unique `background_tasks`/`session_crons` drain detail; §Ephemeral peer review (L114) remains canonical owner of the verdict→shutdown sequence (verified).

### Dimensions Evaluated
Capability Growth & Cross-Communication · Actionability · Consolidation & Trimming (HIGHEST) · Spec Alignment (no docket/frontmatter drift). NO-OPs confirmed: canonical name anchoring, doubled-reviewer pattern, no-code-comments gate.

### Rename
No rename.

## 2026-05-30

### Summary
Phase 2 coherence: removed the dangling `§6 continuity preamble` pointer (2× — L35, L114). No §6 heading exists; the preamble is defined in team-lead.md §Teammate Stall & Crash Recovery. Within-line; 234 lines.

### Changes
- `§6 continuity preamble` → `continuity preamble` (×2). Fleet-symmetric sweep across sdet/senior-engineer/team-lead.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — dangling cross-ref) · Terminology consistency.

### Rename
No rename.

## 2026-05-30

### Summary
Two Consolidation & Trimming edits (net -2 lines; 236→234) collapsing redundant restatements of team-lead.md step-14 reconciliation mechanics (Blocker-blocks / Approve+Block / DEGRADED-annotation) into pointers — team-lead owns the canon and the file already referenced it. The "4 parallel reviewers" composition (load-bearing) preserved. Zero behavioral loss.

### Changes
- §Doubled Security-Track Composition: folded inline reconciliation mechanics + the degraded-fallback paragraph into one pointer-based sentence.
- §Review Output: removed the duplicate step-14 reconciliation clause; kept the operator-routing rule.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 2 dedups vs team-lead step 14) · Boundary Clarity (security-verdict-binds preserved) · Spec Alignment (no Task() drift; frontmatter consistent with fleet)

### Rename
No rename.

## 2026-05-30 (Phase 2 — coherence)

### Summary
Fixed a rule-numbering drift surfaced by Phase 2 cross-agent review: the §Doubled Security-Track Composition degraded-fallback reference pointed at "step 14 reconciliation rule 7", but team-lead.md step 14's list has 6 rules (degraded-fallback = rule 6). Now agrees with ux-designer.md (corrected rule-7→rule-6 the same cycle) and team-lead.md.

### Changes
- §Doubled Security-Track Composition: "step 14 reconciliation rule 7" → "rule 6".

### Dimensions Evaluated
Spec Alignment (cross-agent rule-numbering coherence)

### Rename
No rename.

## 2026-05-30

### Summary
Three changes (236 lines; within-line). Added the audit's validated glob/separator/POSIX-bracket pattern-matching check to the authn/authz review dimension (two PROVEN weft pitfalls: path.Match/doublestar silent DENY across `/` in URI-shaped capabilities → under-permissioning; verbatim-bracket glob→regexp translators activating RE2 POSIX classes → over-grant; both need sequence-level, not lockstep, abuse cases). Fixed the fabricated `[SEC→@agent]` visibility token (canonical `[{ROLE}→@{recipient}]`; nowhere fleet-wide). Offset by collapsing the triple-redundant secret-handling failure-string restatement.

### Changes
- §Review Workflow step 3 authn/authz dimension: added pattern-match-semantics check (enumerate `*`/separator/bracket against the actual identifier shape; require sequence-level abuse cases).
- §Cross-agent pointers: replaced fabricated `[SEC→@agent]` with canonical `[SEC→@{recipient}]` per the `[{ROLE}→@{recipient}]` convention.
- §No Guessing secret-handling audits: collapsed the duplicate failure-string example; retained the DO/DON'T.

### Dimensions Evaluated
Capability Growth (PRIMARY — historical-driven authz match-semantics check) · Spec Alignment (visibility-token coherence) · Consolidation (secret-handling dedup)

### Rename
No rename.

## 2026-05-26

### Summary
Clarified `security-reviewer-1`/`-2` are PARALLEL-panel for consensus voting (NOT sequential rework rounds, per audit hint flagging operator-transcript ambiguity); introduced `security-reviewer-fix-{N}` for fix-loop respawns matching @staff-engineer's `tdd-author-fix-{N}` convention. Consolidated §Shutdown Handling restatement to defer the verdict→shutdown sequence to its §Ephemeral peer review canonical home, retaining only unique drain/peer-consult caveats. Added one-line `docket export -o markdown -l <label>` surface in §System-Level Security Thinking for cross-issue vuln-class rollups. Net 0 lines (text density shifted; bullets stayed single-line).

### Changes
- L33 Lifecycle: spelled out `security-reviewer-1`/`-2` as parallel-panel pair (not sequential rounds) + `security-reviewer-fix-{N}` for fix-loops.
- §Ephemeral peer review: fix-loop respawn name aligned to `security-reviewer-fix-{N}`.
- §Shutdown Handling: dropped redundant verdict→shutdown sequence restatement; deferred to §Ephemeral peer review; retained drain + peer-consult caveats.
- §System-Level Security Thinking: added `docket export -o markdown -l <label>` for recurring vuln-class trend rollups.

### Dimensions Evaluated
Boundary Clarity (PRIMARY — paired-panel vs sequential-rounds disambiguation) · Consolidation (shutdown sequence dedup) · Capability Growth (docket export surface)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 8 dangling docs/tdd/* citations)

### Summary
Stripped 8 dangling citations to `docs/tdd/reviewer-doubling-lifecycle.md` (Phase 0 verified file does not exist in this repo). Redirected references to team-lead.md anchors (Rule 7, Rule 8, step 14 reconciliation rules, §Runtime Discipline).

### Changes
- L34 idle-semantics bullet: dropped "+ reviewer-doubling-lifecycle.md §4.4" tail.
- L37 cross-agent pointers: dropped "+ reviewer-doubling-lifecycle.md §4.2 row 2" tail.
- L101 step 9 secondary review: replaced "TDD §4.4 rule 8" + "TDD §4.3" with team-lead Rule 8 + step 14 anchors.
- L110 doubled-track block: replaced "TDD §4.3" with team-lead step 14 anchor.
- L112 degraded fallback: replaced "TDD §4.3 rule 7" with team-lead step 14 reconciliation rule 7 anchor.
- L133 Review Output: replaced "TDD §4.3" with step 14 anchor.
- L171 divergence trigger: replaced "docs/tdd/reviewer-doubling-lifecycle.md §4.3" with step 14 anchor.
- L223 Runtime Discipline opener: replaced "§4.5 applicability matrix" with team-lead.md §Runtime Discipline anchor.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — per-name idle semantics + verdict→shutdown sequence)

### Summary
Closed the dev-dkt-3-shadow-validators stall by encoding per-name idle semantics (`security-advisor` idle-OK vs `security-reviewer-N` ephemeral) and numbered verdict→`shutdown_request` SAME-turn sequence with the documented incident named as the negative example. Split Shutdown Handling by name; added `background_tasks`/`session_crons` drain caveat (async-shutdown is by design). Net +4 lines (277 → 281).

### Changes
- §Operating Context + Lifecycle: replaced "Stateless subagent" framing (contradicted persistent-advisor model); restructured Lifecycle into named-lifecycle distinction — `security-advisor` (idle NORMAL) vs `security-reviewer-N` (idle after verdict = STALL).
- §Ephemeral peer review: encoded numbered verdict→shutdown sequence — (1) SendMessage verdict, (2) `shutdown_request` as FINAL tool call same turn, (3) await `shutdown_approved`. Documented `security-reviewer-2` 1.5min idle in `dev-dkt-3-shadow-validators` as the negative example.
- §Shutdown Handling: split by name — `security-advisor` long-lived approve criteria; `security-reviewer-N` mandatory same-turn shutdown_request + `background_tasks`/`session_crons` drain before emitting.

### Dimensions Evaluated
Actionability (PRIMARY — verdict→shutdown sequence) · Boundary Clarity (per-name idle semantics) · Capability Growth (drain rule + documented incident as exemplar) · Completeness (async-shutdown caveat)

### Rename
No rename.

## 2026-05-25 (Phase 2 coherence — P7a drop)

### Summary
Single coherence fix: dropped dead "(P7a)" cross-reference from R7 exception clause. No agent canonically labels its Read-before-Edit/Write rule as "P7a"; the parenthetical was fleet-wide dead reference.

### Changes
- §R7 exception clause: dropped "(P7a)" suffix

### Dimensions Evaluated
Actionability (dead-reference removal)

### Rename
No rename.

## 2026-05-25 (Phase 1 self-review — `.env*` workaround + shutdown negative example)

### Summary
Two audit-driven additions plus a trim. Closed the recurring `.env*` sandbox-block on legitimate secret audits (5 historical denied-read errors in one session) by adding a §No Guessing bullet prescribing the documented detour (`ls -la`, grep usage sites, consult `docs/spec/security.md`, route to operator). Reinforced rule 6 shutdown routing with a concrete WRONG/RIGHT negative example for the doubled-security-track recipient ambiguity. Trimmed Cross-agent pointers from 4 bullets to 1 inline sentence. Net −3 (280 → 277). Note: reviewer applied edits directly during review (read-only protocol violation); team-lead accepted since changes pass Content Gate.

### Changes
- §No Guessing: new bullet — `.env*` sandbox-denied alternatives (`ls -la`, grep `dotenv\|process.env\|std::env::var\|os.environ`, `docs/spec/security.md`, operator escalation for real values)
- §Communication Discipline rule 6: appended WRONG/RIGHT negative-example clause for shutdown routing on doubled security tracks
- §Cross-agent pointers: collapsed 4-bullet list to 1 inline sentence; dropped Epistemic Discipline pointer (covered by rule 7)
- §Operating context: prose cleanup (semicolon merge)

### Dimensions Evaluated
Actionability (PRIMARY — `.env*` workaround unblocks recurring audit detour) · Cross-Agent Coherence (negative-example pattern proposed fleet-wide for shutdown routing) · Consolidation & Trimming

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-09: Phase 1 self-review (initial entry). Trimmed redundant preambles and verbose Review Output paragraph; merged duplicate incoming triggers per…
- 2026-05-09: Phase 2 coherence: anchored canonical teammate name "security-advisor" to team-lead.md §Spawning Templates so naming stays consistent if…
- 2026-05-13: Rebalanced documentation-vs-direct-action axis per operator pain. Added Threat-Model Annotation tier between full security TDD and inline review…
- 2026-05-16: Added Communication Discipline (rules 1-6) with rule 5 (verify load-bearing claims) emphasized for security sign-off; fixed misleading `docket…
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).…
- 2026-05-17: pass 2: Trimmed three blocks for parity with peers and to remove intra-doc duplication: Design Review's dimension list redirected to…
- 2026-05-17: Phase 2 coherence: Cross-agent coherence: added canonical `TeammateIdle` stall-signal line and Read-before-Edit/Write reflex.
- 2026-05-19: Targeted self-review responding to historical-audit signals: codified the respawn-recovery handoff (4× operator pattern), added a vote-commit…
- 2026-05-19: Phase 2 coherence: Universal-mirror visibility contract alignment (Phase 2 canonical decision). Conditional-mirror language replaced with…
- 2026-05-19: Activated the dormant `.claude/agent-memory/security-engineer/` channel via a shutdown-time memory check, tailored to security context: explicitly excludes
- 2026-05-24: Two coherence fixes. (1) Closed the 6 historical shutdown-routing errors by making the routing rule explicit at rule 6. Security review doubling (4 parallel
