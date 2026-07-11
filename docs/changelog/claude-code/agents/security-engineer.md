# Changelog: security-engineer

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

## 2026-06-19

### Summary
Closed a version-resolution verification gap (lockfile/`cargo tree` authority) surfaced by the cross-project hermes pitfall; trimmed a duplicated stall-clause. Net 0 (269→269). Drift: neutral reorder of the System-Level watch-item list → adopted.

### Changes
- AMPLIFY: dependency-verification bullet now requires version-resolution facts checked against `Cargo.lock`/`cargo tree` BEFORE asserting OR correcting — a confident correction that inverts a settled fact without querying the lockfile is the same defect as the original guess (Cargo.lock confirmed present; distinct from `cargo audit` CVE-status).
- CULL: removed restated "WORKING past verdict is the stall" (canonical owner is §Ephemeral peer review).

### Dimensions Evaluated
Capability Growth (AMPLIFY), Consolidation (CULL). Role Realism / Actionability / Boundary Clarity / Completeness / Spec Alignment / Rename — RETAIN.

### Rename
No rename.

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
