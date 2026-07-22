# Changelog: security-engineer

## 2026-07-21

### Summary
Compacted 2 entries (2026-07-01..2026-07-01) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-21

### Summary
Q4-closure trigger wired to the deterministic `gate_check.sh --gates sdet-abuse` (I-tl4), replacing the hand-grep of the issue thread and sharing team-lead's Promised-gate check. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 3 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (I-tl4): Q4 closure now calls `gate_check.sh <issue-id> --gates sdet-abuse` (exit 1 = MISSING) instead of prose-defining its own `docket issue comment list`/`file list` grep.

### Dimensions Evaluated
Actionability; Capability Growth & Cross-Communication. B7 (no manual-staging refs), D9 (skills-not-auto-load caveat present), I-sec1 (edit_baton.sh absent) — all verified no-op.

### Rename
No rename.

## 2026-07-15

### Summary
Compacted 4 entries (2026-06-20..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-15

### Summary
READ-BEFORE-EDIT pointer's "on every TDD or ADR" scoping rephrased file-class-agnostic (same excludable-reading hazard as sdet); R7 gains the adjacency-gate outranking exception.

### Changes
- AMPLIFY[SUBSTANTIVE]: rule 6's Read sentence rephrased — the gate binds every file; TDDs/ADRs are the common case, not the scope; pitfalls.md explicitly named as binding identically.
- AMPLIFY[SUBSTANTIVE]: R7 one-liner gains the Read-before-Edit adjacency rule as a second outranking exception.

### Dimensions Evaluated
Disambiguation (multi-reading ×2).

### Rename
No rename.

## 2026-07-15

### Summary
Read-before-Edit sentence → pointer to senior-engineer.md's new master (B3; asecurity was in bug-auditor's failure set); stale-dispatch-check pointer added (R3); vote wire form deduped (I4).

### Changes
- AMPLIFY[SUBSTANTIVE] (B3): Rule 6's Read sentence → READ-BEFORE-EDIT pointer (shutdown/relay content untouched).
- AMPLIFY[SUBSTANTIVE] (R3): added stale-dispatch-check pointer on Rule 2.
- CULL[COSMETIC] (I4): wire-form paragraph replaced with a citation to Skill(vote)'s Delegation Protocol.

### Dimensions Evaluated
Consolidation & Trimming, Cross-Communication.

### Rename
No rename.

## 2026-07-15

### Summary
Self-review: no edits. All 4 findings (H11 opus-pinning, H12 evidence-staleness cadence, I10 phase_diff.sh, D1 teammate-envelope note) dispositioned without a file change. Findings: 4 → 0 sub / 0 cos / 0 rej / 1 def / 3 enc

### Changes
None this cycle — no verified finding required a definition edit.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation/Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename — all 8 pass; H11/H12/D1 already-encoded, I10 (phase_diff.sh) deferred as infra.

### Rename
No rename.

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
- 2026-06-20: Encoded `api.github.com` sandbox-TLS retry cue on the supply-chain CVE/advisory verification path. Drift: disabled (drift=0).
- 2026-06-21: Compacted 12 entries (2026-05-25..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-30: Added plan-phase @sdet abuse-case handoff for small security-sensitive work with no TDD; culled non-load-bearing Model-floor paragraph.
- 2026-06-30: Phase 2 PA: landed shift-left review triggers (outgoing recommend plan-approval mode; incoming pre-impl security review). Trial: PA plan-approval → applied.
- 2026-07-01: Trial: security plan handoffs and risk acceptance fields -> applied — added plan-phase abuse-case + plan-approval security PLAN handoffs; CVE evidence resolves Cargo.lock/cargo tree; risk_acceptance_vote_required for Blocks/deferrals/downgrades.
- 2026-07-01: Phase 2 coherence follow-up — aligned security local shutdown copy with master cleanup-evidence semantics (close ack alone is not cleanup evidence).
