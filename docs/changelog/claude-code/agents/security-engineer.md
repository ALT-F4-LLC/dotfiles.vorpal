# Changelog: security-engineer

## 2026-07-13

### Summary
Compacted 4 entries (2026-06-10..2026-06-19) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-12

### Summary
Phase 2 coherence: compacted the SHUTDOWN-PROTOCOL-LOCAL block to the master-pointer form (parity with the fleet-wide compaction).

### Changes
- CULL[SUBSTANTIVE]: §Shutdown Handling's 19-line SP-1/SP-2 spell-out reduced to a 3-line master pointer + Precondition.

### Dimensions Evaluated
Cross-Agent Coherence (SHUTDOWN-PROTOCOL block byte-parity across all 7 non-team-lead agents).

### Rename
No rename.

## 2026-07-12

### Summary
Findings: 6 → 5 sub / 0 cos / 0 rej / 1 def / 0 enc. Applied 5 SUBSTANTIVE fixes: corrected DA1 fabricated vote-schema fields, migrated vote-creation to vote_delegate.sh (fixes silent 0.67 threshold divergence — critical for security votes), added DR1 frontmatter-inert note, trimmed single-investigation Provider bullet, added a pre-authoring OBSERVE-live-state gate. Net +132 bytes (51,312→51,444).

### Changes
- FIX[SUBSTANTIVE] (DA1): vote-commit race guard cited nonexistent `state`/`tallied`/`committed_at`; corrected to `status == "approved"` per live docket schema (enum `open|approved|rejected|committed`, `updated_at` sole timestamp).
- AMPLIFY[SUBSTANTIVE] (IS-TL4-SEC): replaced hand-rolled `docket vote create`+delegation JSON with `vote_delegate.sh` pointer (maps criticality→threshold; security votes typically `critical`).
- AMPLIFY[SUBSTANTIVE] (DR1): documented `skills:` frontmatter does not auto-load in teammate mode.
- CULL[SUBSTANTIVE]: compressed Provider bullet; transferable access-path/train-toggle lesson preserved inline.
- AMPLIFY[SUBSTANTIVE] (HA-SEC1): pre-authoring OBSERVE-live-state gate for the recurring inferred-premise pattern.

### Dimensions Evaluated
Actionability, Spec Alignment (live docket re-verified), Consolidation & Trimming, Capability Growth, Completeness. Role Realism/Boundary Clarity/Rename: RETAIN (security≈AppSec reconfirmed).

### Rename
No rename.

## 2026-07-11

### Summary
Compacted 3 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-11

### Summary
Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net +32 bytes.

### Changes
- FIX[SUBSTANTIVE]: SP-2 LOCAL copy corrected — `name=` is the sole discriminator; report-only subagents run background-by-default since Claude Code v2.1.198, so `run_in_background` no longer discriminates. Stale phrasing contradicted team-lead.md's Phase-1-corrected copy and current harness behavior.

### Dimensions Evaluated
Spec Alignment (v2.1.198 harness behavior), Boundary Clarity (family-wide parity with 5 siblings + master).

### Rename
No rename.

## 2026-07-11

### Summary
evolve-agents cycle (SDLC role-comparison mandate): verification-only pass, no content changes. Charter confirmed as near-exact industry AppSec fit; all team-lead.md cross-references, tier claims, and docket command examples verified valid.

### Changes
(none — RETAIN across the board; see Dimensions Evaluated)

### Dimensions Evaluated
Role Realism: SDLC research confirms near-exact fit to industry AppSec Engineer (design-time threat modeling, secure code review, cross-SDLC guidance, no feature code); the "AppSec also builds security CI tooling" delta is intentional role-separation here (tooling routes to impl roles), not a gap. Boundary Clarity (cross-refs to team-lead.md L51/L96/L143 all valid), Actionability (all docket examples correct — no hit for the fleet-wide wrong-docket-example bug), Consolidation (no safe trim found; rejected a fabricated Rule-7/team-lead-Rule-6 trim as non-redundant on inspection): RETAIN. Completeness/Capability Growth/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-10

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-10

### Summary
Phase 3 disambiguation follow-up: fixed a confusable peer-name in a shutdown-routing example.

### Changes
- DISAMBIG: shutdown-routing WRONG-example `to="reviewer-staff-2"` corrected to `to="reviewer-2"` — the fabricated name matched no real roster seat, leaving a reader unable to tell whether it was real or illustrative.

### Dimensions Evaluated
Boundary Clarity (confusable-name).

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
Trimmed a third redundant SP-1 restatement in §Shutdown Handling. Net -69 bytes. (The vote-delegation bare-object FIX-9 finding — confirmed against vote/SKILL.md L42-44 as a real `invalid_union` rejection — is deferred to a fleet-wide Phase 2 fix rather than applied per-file, since it's shared/parity-bound across all 8 agents.)

### Changes
- CULL: removed redundant "Approve with NO reason (SP-1...)" sentence from the security-advisor shutdown bullet — already stated in the CANONICAL:SHUTDOWN-PROTOCOL block and Communication Discipline rule 6.

### Dimensions Evaluated
Consolidation & Trimming (primary). Actionability (FIX-9 deferred to Phase 2). Role Realism/Boundary/Completeness/Capability Growth/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-01

### Summary
Phase 3 Disambiguation follow-up: normalized security shutdown report fields.

### Changes
- DISAMBIG: updated local SP-1 to require scope or changed files, checks run, unresolved risks, and explicit `safe_to_close` close readiness.

### Dimensions Evaluated
Phase 3 Disambiguation; shutdown schema.

### Rename
No rename.

## 2026-07-01

### Summary
Phase 2 coherence follow-up: aligned security local shutdown copy with master cleanup-evidence semantics.

### Changes
- FIX: SP-2 now states close acknowledgement alone is not cleanup evidence; team-lead records explicit closed-agent evidence or degraded cleanup.

### Dimensions Evaluated
Canonical shutdown sense parity, close handling.

### Rename
No rename.

## 2026-07-01

### Summary
Trial: security plan handoffs and risk acceptance fields -> applied.

### Changes
- AMPLIFY: plan-phase abuse-case + plan-approval security PLAN handoffs; CVE evidence now resolves `Cargo.lock` / `cargo tree` and panel packets before dependency verdicts.
- AMPLIFY: verdicts require `risk_acceptance_vote_required` plus handoff evidence for Blocks, deferrals, or Critical/High downgrades.
- CULL: persistent `security-advisor` close handling now uses active-obligation semantics and minor-consult wrap-up.

### Dimensions Evaluated
Capability Growth, Completeness, Cross-Communication, Lifecycle Semantics.

### Rename
No rename.

## 2026-06-30

### Summary
Phase 2 (operator-approved PA): landed the PA shift-left review triggers — outgoing (recommend team-lead dispatch @senior-engineer in plan-approval mode) + incoming (review a team-lead-routed plan on a security-sensitive surface before the diff). Net +2 (287→289). Trial: PA plan-approval → applied.

### Changes
- AMPLIFY: outgoing trigger — security-sensitive impl about to start → recommend team-lead run @senior-engineer in plan-approval mode so security-advisor reviews the PLAN before the diff.
- AMPLIFY: incoming trigger (FIX 2 receiver symmetry) — @senior-engineer PLAN routed by team-lead (plan-approval mode) on a security-sensitive surface → pre-impl security review delivered to team-lead as a plan note.

### Dimensions Evaluated
6 (Capability Growth) AMPLIFY×2. 1/2/3/4/5/7/8 RETAIN.

### Rename
No rename.

## 2026-06-30

### Summary
Added a plan-phase @sdet abuse-case handoff for small security-sensitive work with no TDD (today such work has no Testing-Strategy handoff, so security tests only appear post-diff), offset by culling the non-load-bearing Model-floor paragraph. Net -1 (288→287). PA shift-left plan-review trigger deferred to Phase 2 (needs team-lead PA counterpart).

### Changes
- AMPLIFY: new outgoing trigger — Small security-sensitive change with NO TDD → plan-phase abuse-case consult to @sdet. Signal: Phase 0 agent finding (3), non-TDD path has no abuse-case handoff.
- CULL: removed Model-floor paragraph — informational (agent can't choose its model); grounding clause covered by Comm Discipline rule 5 + No Guessing. Signal: MODEL ROUTING (110× opus, 100% pinned, floor never corrective). Reconciliation-safe (not a pin change).
- Deferred: PA shift-left review trigger → Phase 2 (cross-cutting; needs team-lead PA primitive + senior-engineer plan-mode receiver).

### Dimensions Evaluated
All 8. 5 (Consolidation) → 1 CULL. 6 (Capability Growth) → 1 AMPLIFY (PA deferred). 1/2/3/4/7/8 RETAIN.

### Rename
No rename.

## 2026-06-21

### Summary
Compacted 12 entries (2026-05-25..2026-06-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 12 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-20

### Summary
Encoded the `api.github.com` sandbox-TLS retry cue on the supply-chain CVE/advisory verification path. Net 0 (283→283). Drift: disabled (drift=0).

### Changes
- AMPLIFY (cited: historical-audit — security-engineer has zero pitfalls memory + gh-api supply-chain dead-end): the Dependency-CVEs rule now notes that `gh api`/`curl api.github.com` SHA/advisory checks fail on the first sandboxed call with a TLS error and must retry with a bounded `dangerouslyDisableSandbox: true` (cross-refs sdet sandbox-interaction patterns); closes a dead-end where a first-call TLS error reads as "advisory feed unreachable."

### Dimensions Evaluated
1 Role Realism RETAIN · 2 Actionability RETAIN · 3 Boundary Clarity RETAIN · 4 Completeness AMPLIFY · 5 Consolidation RETAIN · 6 Cross-Comm RETAIN · 7 Spec Alignment RETAIN · 8 Rename RETAIN.

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
- 2026-05-25: Phase 1 self-review — `.env*` sandbox-denied workaround, rule 6 shutdown WRONG/RIGHT example, Cross-agent pointers collapsed. Net -3.
- 2026-05-25: Phase 2 coherence — dropped dead "(P7a)" cross-reference from R7 exception clause (fleet-wide cleanup).
- 2026-05-26: Phase 1 — per-name idle semantics (security-advisor idle-OK vs security-reviewer-N STALL) + verdict→shutdown sequence; drain caveat. Net +4.
- 2026-05-26: Phase 2 — stripped 8 dangling docs/tdd/* citations; redirected to team-lead.md anchors.
- 2026-05-26: Parallel-panel disambiguation for security-reviewer-1/-2; fix-{N} convention; Shutdown dedup; docket export rollup surface. Net 0.
- 2026-05-30: Authn/authz glob/separator/POSIX check + [SEC→@{recipient}] canonical token fix + secret-handling dedup. Within-line.
- 2026-05-30: Phase 2 coherence — degraded-fallback reference corrected from rule 7 → rule 6. Within-line.
- 2026-05-30: Consolidation — §Doubled Security-Track + §Review Output step-14 mechanics collapsed to pointers. Net -2.
- 2026-05-30: Phase 2 coherence — dangling `§6 continuity preamble` pointer removed ×2 (fleet sweep). Within-line.
- 2026-06-05: Sole-editor rule + phase-scoped residual-grep guard folded; verdict→shutdown triple-coverage trimmed. Net 0.
- 2026-06-09: NO-OP — docket-cwd guard scoped out (vote-only surface; applied to SE/PM/SDET instead). Net 0.
- 2026-06-09: evolve-skills reference update: code-review → code-review-verdict; 3 references updated.
- 2026-06-09: Consolidated verdict→shutdown double-coverage to one pointer; encoded relay-authority rule. Net 0 (241 lines).
- 2026-06-09: Shutdown flip — verdict→shutdown sequence + Lifecycle reviewer bullet inverted to normal-awaiting. Count unchanged (241).
- 2026-06-09: Fable-5 mandate pass — WebFetch/WebSearch use-when trigger on CVE bullet; Model-floor note added; "Don't overthink" trimmed. Net +2 (242 lines).
- 2026-06-09: Compacted 9 entries (2026-05-09..2026-05-19) into Compacted history per ADR 0001 (DKT-264).
- 2026-06-10: Rust-only consolidation — purged dead npm/Node/Python idioms; tightened Model-floor paragraph. Net 0 (242 lines).
- 2026-06-10: Compacted 2 entries (2026-05-19..2026-05-24) into Compacted history per ADR 0001.
- 2026-06-10: Encoded phantom-deletion guard into the secret-handling audit bullet (sandboxed `git diff` renders deny-listed `.env*` as DELETED; verify via `git log -- <path>` before flagging).
- 2026-06-17: Fixed docket graph arg-order; added persist-ordering gate to secret-handling review dimension. Trial: persist-ordering gate → adopted.
- 2026-06-19: Closed version-resolution verification gap (lockfile/`cargo tree` authority); trimmed duplicated stall-clause. Net 0 (269→269). Drift: neutral reorder of the System-Level watch-item list → adopted.
