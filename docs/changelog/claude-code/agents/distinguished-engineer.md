# Changelog: distinguished-engineer

## 2026-07-21

### Summary
Phase 2 coherence review: disambiguated the "staff-engineer.md step 9" cross-reference — staff's file has 3+ numbered lists and unqualified "step 9" collides with its Communication rule 9.

### Changes
- FIX[COSMETIC]: Mode 2 Recusals now cites "staff-engineer.md §Responsibility 1 step 9" instead of bare "step 9", matching the qualification style already used at line 129.

### Dimensions Evaluated
Boundary Clarity (cross-reference integrity). Verified: staff-engineer.md's Responsibility 1 numbered list still runs 1-9 exactly as this cycle's Mode 1 adoption assumes (its own Phase 1 edit only added an item to a different lettered sub-list inside step 6, no renumbering).

### Rename
No rename.

## 2026-07-21

### Summary
Mode 1 TDD workflow converted from parallel restatement to by-reference adoption of staff-engineer.md's TDD Creation Workflow (the pattern Mode 4 already uses for senior's execution contract), keeping only gold-seat deltas; verbatim-quote gate hardened from when-challenged discriminator to mandatory pre-fact falsification pass. Findings: 5 → 2 sub / 0 cos / 0 rej / 1 def / 2 enc. Net −1765 bytes.

### Changes
- CULL[SUBSTANTIVE] (I-de1): Mode 1's 6-step workflow + Skeleton-round bullet replaced with by-reference adoption of staff steps 1-9; gold deltas kept local (verbatim-quote pass, ADR path/placeholder rule, Non-Goals/do-nothing, premortem, PRR); two internal cross-refs retargeted.
- AMPLIFY[SUBSTANTIVE] (H-de2): verbatim-quote gate is now a mandatory falsification pass BEFORE any load-bearing fetched claim enters an artifact — centralized pitfalls confirmed WebFetch summarization fabricating field semantics absent from the source page.

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Capability Growth, Boundary Clarity (cross-ref integrity). Deferred: H-de1 (94% fable routing, /evolve-model-distribution). Already-encoded: D9, S1-S5 (Principal-Engineer mapping reconfirmed, naming closed).

### Rename
No rename.

## 2026-07-15

### Summary
Vote wire-form payload-noun clarity fix: post-Phase-2-dedupe text asserted "plain-string, never structured `message`" then referenced "the JSON payload", parseable as contradicting the plain-string claim.

### Changes
- AMPLIFY[COSMETIC]: "the JSON payload must contain no raw embedded newlines" → "the JSON embedded in that plain-string payload must contain no raw newlines".

### Dimensions Evaluated
Disambiguation (confusable-name).

### Rename
No rename.

## 2026-07-15

### Summary
Read-before-Write/Edit bullet → pointer to senior-engineer.md's new master (B3; aadvisor was in the failure set); stale-dispatch-check pointer added (R3); vote wire form deduped (I4, newline clause retained as local delta).

### Changes
- AMPLIFY[SUBSTANTIVE] (B3): Read bullet → READ-BEFORE-EDIT pointer (content-strings delta retained).
- AMPLIFY[SUBSTANTIVE] (R3): added stale-dispatch-check pointer on the Close-every-loop bullet.
- CULL[COSMETIC] (I4): wire-form paragraph replaced with a citation to Skill(vote)'s Delegation Protocol (the no-raw-embedded-newlines clause kept as a local delta absent from the skill).

### Dimensions Evaluated
Consolidation & Trimming, Cross-Communication.

### Rename
No rename.

## 2026-07-15

### Summary
Pointed both claim-mechanism references at `docket_claim.sh` (verified present, already adopted by senior-engineer/sdet); added an awaited-deliverable timeout for silently-dropped inbound SendMessages (ties to the operator idle-pain cluster); added a sole-editor confirmation step to crash-recovery hygiene. Findings: 4 → 4 sub / 0 cos / 0 rej / 0 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (I12): deep-impl claim + Docket-CLI claim example now call `docket_claim.sh <id> distinguished-engineer` (was raw two-step edit-then-move), both sites.
- AMPLIFY[SUBSTANTIVE] (H4): new "Awaited-deliverable timeout" bullet — re-request through team-lead when an expected inbound peer deliverable hasn't arrived (session 7244e499: a 4-peer-ping delivery gap).
- AMPLIFY[SUBSTANTIVE] (H5): Crash/resume hygiene now requires confirming through team-lead that no live pre-crash instance holds the seat before claiming sole-editor status (two centralized seat-duplication pitfalls this cycle).
- D1 already-encoded (line 33).

### Dimensions Evaluated
Actionability, Capability Growth & Cross-Communication, Boundary Clarity, Consolidation.

### Rename
No rename.

## 2026-07-13 (DKT-270 Phase 3 disambiguation)

### Summary
Disambiguated the deep-research sanction: the unexplained `Skill(vote)` restriction-class pointer and the fused "team-lead/operator" routing target. Findings: 2 → 2 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: glossed "same restriction class as `Skill(vote)`" with the shared class itself (swarm-spawning entry points are main-session-only) — the trailing "no `Workflow` tool" primed a false mechanical reading
- AMPLIFY[SUBSTANTIVE]: split "team-lead/operator" into "team-lead (team mode) or the operator (standalone)" — the slash-compound hid which target applies when

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-13 (DKT-270 correction)

### Summary
Corrected the deep-research sanction in the Innovation scanning paragraph — deep-research is a bundled Workflow, not a Skill, and is not directly teammate-invokable. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: replaced the "prefer `Skill(deep-research, ...)` — a registered bundled skill" clause with the Workflow-vs-Skill distinction, the dozens-to-~97 background-subagent fan-out, the no-`Workflow`-tool teammate restriction (same class as `Skill(vote)`), and the route-to-team-lead-or-hand-roll fallback under this role's per-fetch verbatim-quote gates — cited DKT-270 investigation, independently corroborated via code.claude.com/docs/en/workflows

### Dimensions Evaluated
Actionability.

### Rename
No rename.

## 2026-07-12

### Summary
Phase 3 disambiguation: fixed a garden-path sentence in the vote-proposal instructions that this cycle's `vote_delegate.sh` migration introduced — "you do not run votes yourself: run vote_delegate.sh" read two ways since the script does perform a vote-create.

### Changes
- AMPLIFY[SUBSTANTIVE]: Consensus Voting now explicitly names the banned surfaces (`/vote`/`Skill(vote)` run the whole flow) before instructing `vote_delegate.sh` (creates the proposal only) — matches the phrasing pattern already used in the other 6 migrated files.

### Dimensions Evaluated
Disambiguation (multi-reading) — this file was the only vote_delegate.sh migration this cycle that didn't name the forbidden surface explicitly.

### Rename
No rename.

## 2026-07-12

### Summary
Phase 2 coherence: aligned the shutdown block to the shared 7-way byte-identical compact form (role-specific bullets relocated verbatim below the fences); consolidated the vote proposal onto `vote_delegate.sh` for consistency with the rest of the fleet.

### Changes
- AMPLIFY[COSMETIC]: §Shutdown Handling block gains the env-var Precondition sentence; role-specific "Applied to this role's spawn forms" bullets moved verbatim outside the CANONICAL fences to enable fleet-wide byte-identity.
- CULL[SUBSTANTIVE]: §Consensus Voting's hand-rolled `docket vote create` replaced with a `vote_delegate.sh` pointer — not a bug fix (this file already documented `--threshold` correctly), but closes the last hand-rolled proposer path fleet-wide; mis-create-supersede note and Wire form preserved.

### Dimensions Evaluated
Cross-Agent Coherence (SHUTDOWN-PROTOCOL block byte-parity across all 7 non-team-lead agents; vote plumbing consistency).

### Rename
No rename.

## 2026-07-12

### Summary
evolve-agents cycle: sanctioned `Skill(deep-research)` for external-source-dominated Mode 3 work, replaced the manual ADR-numbering paragraph with a `next_doc_number.sh` pointer (also correcting the false implication that TDDs are numbered), and named the auto-suffix respawn-collision hazard in crash/resume hygiene. Findings: 6 → 2 amp / 1 cull-to-pointer / 0 rej / 1 def / 2 enc. Net +383 bytes.

### Changes
- AMPLIFY (IS-DE1): Mode 3 now prefers `Skill(deep-research, "<question>")` (registered bundled skill, invocable in teammate mode though absent from frontmatter) over hand-rolled WebSearch/WebFetch fan-out for external-source-dominated scans/investigations — built-in adversarial verification + cited report subsumes the per-fetch verbatim-quote choreography; manual path reserved for targeted single-source lookups.
- CULL→POINTER (IS-DE3): replaced Mode 1 step 3's manual numbering-collision procedure with a one-line pointer to `next_doc_number.sh` (invoked by `Skill(adr)`); corrected the scope error that TDDs are numbered — they are never number-prefixed (tdd/SKILL.md).
- AMPLIFY (HA-DE2): named the concrete auto-suffix respawn-collision hazard (`advisor-2` vs a self-resuming original) in Crash/resume hygiene — the resolution was present but the under-encoded WHY was flagged as not sticking across consecutive-date pitfall entries.

### Dimensions Evaluated
Completeness/Capability Growth (deep-research sanction), Consolidation & Trimming + Actionability (numbering pointer + scope fix), Boundary Clarity (crash-hygiene WHY). Sandbox-bind (line 159) and vorpal-gofmt-fallback (line 49) lessons verified ALREADY-ENCODED. Role Realism/Rename/Spec Alignment: RETAIN (SDLC research reconfirmed Principal-Engineer fit).

### Rename
No rename.

## 2026-07-11

### Summary
evolve-agents cycle (SDLC role-comparison mandate): reviewed against Phase 0 findings and external SDLC role research — no changes needed. Findings: 4 → 0 sub / 0 cos / 0 rej / 1 def / 3 enc.

### Changes
(none — RETAIN across the board; see Dimensions Evaluated)

### Dimensions Evaluated
Role Realism: SDLC research maps this role's actual charter to industry "Principal Engineer" scope (not industry "Distinguished"/VP-equivalent); declined the optional naming-clarification note — line 29's "beyond staff in problem class, never in process authority" already neutralizes the concern behaviorally, and no agent routes by title semantics, so the note would be Non-redundant-gate-failing. No rename (would be pure churn). Read-before-Edit, docket examples, and Rule 8(c) cross-refs all already correctly encoded (3 Phase 0 findings verified ALREADY-ENCODED). Error-concentration in 2 sessions (215 total, historical audit) noted as a pattern to watch, not a groundable text change. Boundary Clarity/Actionability/Completeness/Capability Growth/Spec Alignment: RETAIN.

### Rename
No rename.

## 2026-07-10

### Summary
Phase 3 disambiguation follow-up: fixed 3 stale "Rule 8(e)" cross-references (the letter no longer exists after this cycle's team-lead.md Rule 8 relettering).

### Changes
- FIX: 3 "team-lead.md Rule 8(e)" cross-references corrected to "Rule 8(c)" (team-lead.md's Rule 8 opt-up triggers were relettered (c)/(d)/(e)→(a)/(b)/(c) earlier this cycle; this file's own copies were missed in that pass).

### Dimensions Evaluated
Boundary Clarity (stale cross-reference).

### Rename
No rename.

## 2026-07-10

### Summary
Phase 2 coherence follow-up: flagged vote-delegation JSON as a plain-text payload.

### Changes
- AMPLIFY: appended a wire-form clarification to the vote-delegation paragraph — the JSON is sent as a plain-text string, never SendMessage's structured `message` object (`delegation_*` are vote-skill conventions, not real `message.type` values). Matches team-lead.md:360's receiving-side fix (bug-audit FIX-9, fleet-wide sweep).

### Dimensions Evaluated
Actionability (cross-agent coherence sweep).

### Rename
No rename.

## 2026-07-10

### Summary
First tracked changelog entry for @distinguished-engineer (the team's gold/Fable-5 seat) — establishes the file so the "already-present" check and per-agent historical audits stop grepping a nonexistent file. Substantive edit: removed a now-stale cross-doc caveat. Net -200 bytes.

### Changes
- CULL: removed the §What You Are NOT caveat instructing readers to distrust staff-engineer.md's persistent-advisor prose "until the deferred cross-doc sweep lands" — innovation-scan grep confirmed the sweep HAS landed (tier-split now at 5 sites in staff-engineer.md); the caveat had become active misinformation about a peer file's correct state. The tier-split AUTHORITY rule itself is preserved.

### Dimensions Evaluated
Consolidation & Trimming (primary), Boundary Clarity. Role Realism/Actionability/Completeness/Capability Growth/Spec Alignment/Rename: RETAIN. (Historical audit corroborates: centralized pitfalls.md holds 20 dated entries — memory is mature, not thin as a "newer role" framing might assume; no such framing was found in the file, so no edit needed there.)

### Rename
No rename.
