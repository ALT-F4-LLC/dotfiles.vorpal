All 8 agent definitions are rewritten per the charter, in the manifest's remediation order, with every mechanical gate green. Two things need your attention: the per-agent commits are blocked by your guard hook (git writes are denied in this session's non-interactive auto permission mode), and the fleet landed at −34.5%, short of the 40–60% target — the shortfall is structurally pinned, and I documented exactly why in the metrics file rather than deleting load-bearing contracts to hit the number.

What changed

┌───────────────────────────┬─────────┬─────────┬────────┬───────────────────────────┐
│           File            │ Before  │  After  │   Δ    │       M/N/A markers       │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ team-lead.md              │ 137,218 │  76,878 │ −44.0% │ 42 → 15                   │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ senior-engineer.md        │  78,897 │  48,108 │ −39.0% │ 6 → 3                     │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ staff-engineer.md         │  67,580 │  40,785 │ −39.7% │ 16 → 7                    │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ sdet.md                   │  61,892 │  42,018 │ −32.1% │ 10 → 4                    │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ distinguished-engineer.md │  56,691 │  41,576 │ −26.7% │ 4 → 3                     │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ security-engineer.md      │  56,068 │  41,526 │ −25.9% │ 12 → 7                    │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ project-manager.md        │  48,476 │  34,446 │ −28.9% │ 11 → 8                    │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ ux-designer.md            │  46,903 │  37,485 │ −20.1% │ 7 → 5                     │
├───────────────────────────┼─────────┼─────────┼────────┼───────────────────────────┤
│ Fleet                     │ 553,725 │ 362,822 │ −34.5% │ 108 → 52, CRITICAL 12 → 7 │
└───────────────────────────┴─────────┴─────────┴────────┴───────────────────────────┘

Per agent, I deleted every manifest-named 4.x workaround (anti-overthink/anti-rumination paragraphs, 10-minute progress timers, saturation choreography, R4/R6/R7 runtime digests, banned-phrase lists, team-lead's anti-idle turn-shape invariant, the per-turn self-audit, label discipline, the 40-turn trigger, reasoning-echo R5 self-summaries), collapsed the enumerated MUST/NEVER lists into judgment statements, shrank self-verification scaffolding to its external gates (every check script survived; the prose rituals around them didn't), and added the charter's snippets where they fit (autonomy + armed-wait in team-lead's Monitor block, grounded-claims in Rule 6, the code-scope snippet in senior-engineer, the anti-injection block staff-engineer was missing). Security-engineer's opus pin is now annotated as deliberate so a fleet model sweep can't flip it.

What survived, deliberately

Every externally-consumed contract was preserved and re-verified: the parity-locked CANONICAL blocks byte-identical (doctrine_check all 4 arms PASS), tier_map.sh anchors and the Per-Role Dispatch Table, drift-guard-pinned fenced script syntax, all 14 model-census exemption substrings, team-lead Rules 1–11 and workflow steps 1–16 (skills cite Rule 7/8, steps 6/14/15/16 by number), senior-engineer's 12 numbered principles (simplify-scout couples by number and title), sdet's SP-2/Rule 7/Epistemic anchors (verify-ac cites them), ux-designer's HIG catalogue (declared single home for 3 skills), the commit skill's quoted wording, and the DONE — awaiting shutdown_request literal across its adopters. model_census fails identically on HEAD and on this tree (96 pre-existing hits from the migration docs; zero from agents).

The 34.5% vs 40–60%

I stopped where further cuts would mean deleting content rather than compressing it. The residual gap is ~24KB of parity-locked blocks (compacting them requires editing doctrine_check_manifest.tsv, which lives in scripts/ — out of scope), machine-parsed anchors and format contracts, and evidence-backed keeps whose relocation the manifest itself assigns to the Phase 3 team-doctrine restructuring. The charter's own caveat governs: reduction is a consequence of applying §1, never a goal pursued by deleting context the model can't reconstruct. The full accounting is appended to baseline-metrics.md under the after-metrics table. Team-lead did take the largest cut both absolutely (60.3KB) and proportionally (−44%).

Commits — one action needed from you

Your guard-no-commit-hook blocks git writes in this session's auto permission mode, so the 9 changed files are uncommitted. Everything is staged-ready for clean per-agent bisectable commits — either switch to an interactive permission mode (/permissions → default or acceptEdits) and tell me "commit", and I'll run one conventional commit per agent in remediation order (refactor(claude-code): rewrite <agent> agent per Claude 5 context charter, with baseline-metrics.md in a final docs commit), or run the equivalent git add <one agent file> && git commit sequence yourself.


----


The Claude 5 migration — overall summary

Scope. src/user/claude-code/ — 8 agent definitions and 17 skills — rewritten from 4.x-generation prompt style to the Claude 5 paradigm. Governed by docs/context-engineering-claude-5.md (the charter): a violation taxonomy (§1), a keep-list of what survives with imperative force (§2), per-model deltas (§3), and measurable targets (§4). Closed 2026-07-30.

The premise: prompt techniques built for 4.x models are not neutral on Claude 5 — several are actively counterproductive. Reasoning-echo instructions ("state your rationale before acting") are classifier-enforced refusals on Fable 5, so they're a correctness bug rather than a style preference. Anti-laziness pressure, iteration caps, and self-verification checklists are scaffolding for a failure mode these models no longer have. And two mechanisms the old definitions leaned on — assistant-turn prefill and budget_tokens — are simply removed on 4.6+, so any instruction built on them was dead code.

---
What changed, measurably

┌─────────────────────────────────────┬──────────┬──────────┬────────┐
│                                     │ baseline │   now    │   Δ    │
├─────────────────────────────────────┼──────────┼──────────┼────────┤
│ Agents (8 files)                    │ 553,725B │ 366,387B │ −33.8% │
├─────────────────────────────────────┼──────────┼──────────┼────────┤
│ team-lead.md                        │ 137,218B │  77,619B │ −43.4% │
├─────────────────────────────────────┼──────────┼──────────┼────────┤
│ Skills — loaded context (ΣSKILL.md) │ 359,713B │ 217,842B │ −39.4% │
├─────────────────────────────────────┼──────────┼──────────┼────────┤
│ MUST/NEVER/ALWAYS markers — agents  │Every one of 61 cross-file Rule N citations resolves, which was the audit's #1 sequencing hazard and it did not materialize.

The marker reduction matters more than the byte reduction. Surviving markers now each map to a named keep-list category — irreversible actions, security boundaries, authority contracts, machine-read output formats — rather than being merely fewer. team-lead.md keeps 15 (above the ≤10 guideline) as a recorded exception, because it's the only file holding spawn authority, protocol wire formats, and adjudication boundaries at once. That concentration is the architecture, not drift.

---
The most consequential finding was behavioral, not textual

Static audit was Part A. Part B installed the definitions and ran real headless cycles — and found five defects no amount of reading would have surfaced.

┌─────────────────────────────────────────┬─────────────────────────────────────────────────────────────────┬───────────────────────────────────────┬───────────┐
│                 defect                  │                          what it cost                           │                  fix                  │ verified? │
├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┼───────────┤
│ No headless-mode contract               │ A Medium cycle died mid-round-3: 97.7 min, $33.97, zero         │ Unconditional wait-arming (R15)       │ ✅ live   │
│                                         │ deliverable                                                     │                                       │           │
├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┼───────────┤
│ Security panel unbuildable on a trivial │ 3 rules collided; a lone reviewer ran where 3 seats were        │ 2-seat floor on Direct/Small (R16)    │ ✅        │
│  diff                                   │ specified                                                       │                                       │           │
├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┼───────────┤
│ Reviewers wrote scratch into the        │ 9 files (.sdet_probe.py, …) left as commit candidates           │ Rule gap closed in all 8 banners      │ ✅ cycle  │
│ working tree                            │                                                                 │ (R17)                                 │ 5         │
├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┼───────────┤
│ Spawn names drifted (3 forms, same      │ Silently defeated the one-live-instance gate, which matches     │ Canonical impl-{DOCKET-ID} (R20)      │ ✅ live   │
│ role)                                   │ names exactly                                                   │                                       │           │
├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┼───────────┤
│ Acceptance vote wouldn't converge       │ 2 lost rounds, 6 Opus spawns, on unverified "that's addressed   │ Cited before/after evidence required  │ ✅ seeded │
│                                         │ now" claims                                                     │ (R21)                                 │           │
└─────────────────────────────────────────┴─────────────────────────────────────────────────────────────────┴───────────────────────────────────────┴───────────┘

Two of these are worth dwelling on because the diagnosis changed the fix. The scratch-file leak was a rule gap, not disobedience — the rule named /tmp as prohibited and $TMPDIR as correct, and never mentioned the working tree. The agent obeyed exactly and wrote to the third destination, which happened to be the harmful one. An earlier draft proposed a blocking hook; that was rejected as the wrong instrument, since "scratch vs deliverable" is a judgment and a hook carries real false-deny risk. Similarly, B5's failure class — "the finding you raised is now addressed" — wasn't covered by the existing no-guessing doctrine, because a remediation claim isn't a fact about the system.

---
What you should expect to be different in practice


Your working tree stays clean. No .sdet_* files in git status after a review cycle.

Nothing gets committed without you. The commit gate held 3/3 cycles with permission_denials empty every time — that was agent restraint, not the harness refusing.

Reviews tell you everything, including what you didn't ask about. A cycle surfaced a pre-existing Critical unprompted (empty ADMIN_TOKEN makes compare_digest succeed on empty input). This is deliberate: restrictive review filters like "only report high-severity" are now followed literally by Claude 5 and measurably reduce recall, so review prompts ask for full coverage and filter downstream. It's the one place in the whole charter where more prescription is the right answer.

Tier selection is deterministic, so less inflation. Medium used to be a coin flip at the Small boundary because the rule offered "consult an advisor or graduate to Medium" with no way to choose — both readings were compliant. It now counts interacting open architectural dimensions, and records the count.

Votes converge on round 1. The panel was never the cost problem — failure rounds were. Opus spend went $17.09 across two lost rounds → $5.09 on a converged round 1.

Rough prices, knowingly accepted: Direct ~$1.09 / 1.9 min / 1 spawn; security Small ~$5.05; Medium ~$35 (~$26 against the constrained cap, since Sonnet volume draws a separate budget). The gold author seat is 58% of a Medium and is the only real lever — left alone because no Opus-authored Medium TDD exists to justify switching. This reopens automatically if a Medium loses a vote round, exceeds $50, or five accumulate.

Effort pins are cheaper and now honest. A controlled experiment plus replay at n≈480 established that frontmatter effort: binds only for report-only subagent spawns (9/9 exact) and never for teammate spawns. Six of eight roles had reflexively pinned xhigh; most are now high. team-lead's pin was deleted — it binds nowhere. Only ~1.7% of ~420 spawns ever had binding dispatch, so most of those pins were decorative.

CI now enforces the byte ratchet. byte_ceiling_check.sh --strict runs in test-hooks. team-lead.md sits at 77,619/77,619 with zero headroom, so the next append to it fails CI until its row is raised with a stated reason.

---
The most interesting result: reduction may not be the win it looked like

Two findings inverted the migration's own premise, and they're why R6 closed today rather than spawning a prose-reduction pass.

Progressive disclosure isn't working as a reduction mechanism. Across 12 run directories, 1,040 tool calls, and 35 spawns: 9 reads into skill-local references/ and zero into team-doctrine/references/ — 17 files, 74 pointers, never once read. The existing checks verified those pointers resolve and are cited; nothing verified they're followed, and they aren't.

One relocation measurably broke something. The dispatch-ledger instruction was inline through one cycle (ledger written), moved behind disclosure before the next (not written, reference read zero times), then re-inlined (written again). Three observations with a counterfactual on each side — the closest thing to a causal result the record holds. So the record now contains one demonstrated case of adding always-resident text fixing a defect, and zero of removing text improving anything.

Meanwhile the byte targets themselves didn't survive scrutiny: four independent reviewers, one appointed solely to defend them, converged against. The fleet total was deleted (no context holds more than one agent definition, so the sum bounds nothing and charges 8× for deliberately pinned blocks); the per-file floor became a ratchet. Breach count went 15 → 2 → 0 with no content cut. And removing 44KB from team-lead.md would save ~1% of a cycle realistically, 1.9% of one 1M window.

The gate is now qualitative: a section earns its place if it fires at the point of action, or is relocatable and carries a dated record of why it hasn't moved. rule_probe.sh exists as the instrument to test any future cut, with a four-probe PASS baseline as the "before" arm.

---
Limits worth knowing

- Only three cycle shapes ran. Untested: Large/deep-impl, the doubled general panel, @ux-designer and @project-manager seats, the verification phase, the fix-loop, and resume-from-existing-issues. The Medium path is verified only through design acceptance.
- The original five fixes are verified coherent, not verified effective — all cycles ran on already-fixed definitions, so there's no before/after for them.
- Size was never manipulated as a variable. No run has ever compared a larger definition against a smaller one, and per-cycle byte state wasn't recorded, so no correlation is recoverable retrospectively.
- Much of the causal evidence is n=1 per arm. The report says so itself; a FAIL is decisive, a PASS is one observation.
- Hooks were out of scope, including stop-guard-hook.sh, the largest measured thrash source.
- One bookkeeping discrepancy is flagged rather than papered over: cycle 2's model split sums to $41.11 against a recorded $33.97 total.

---
The part designed to outlast the migration

The real risk was that the next evolve cycle would re-accrete exactly what was removed — an evolve cycle is a prescription-writing machine, and every reviewer seat it spawns is rewarded for finding something to add. So team-doctrine/references/claude-5-paradigm-gate.md now makes addition the burdened move: a fifth Content Gate check, a ninth review dimension, and an insufficient-prescription burden of proof — any finding whose remedy is more prescription is reject-class unless it names the keep-list category it lands in and points at the concrete boundary that makes softness fail.

Its first probe cycle net-removed 165 bytes. But the honest reading is in the margin: the sign flipped positive twice mid-cycle and was pulled back only by deliberate intervention. Once, a correctness fix was priced at 4× its necessary size; once, "converge this inconsistency" was resolved in the addition direction when deletion would have done. Two weak points are recorded rather than claimed fixed: correctness findings bypass the burden entirely (nobody argues a fix is prescription, and a correction applied across N carriers costs N× regardless), and the seat proposing an addition is the one who classifies whether the burden applies to it — with no mechanism checking that classification.

Still open after R6: extend the byte-ceiling mechanism to .claude/skills/ (the five evolve-* skills are 52–66KB, outside the mechanism though not the charter); probe whether systemMessage actually reaches a teammate's context; the settings.json vs src/user.rs effort divergence; an effort_census.sh that tests the name= discriminator instead of counting spawn sites; and two #EXCLUDE rows flagged REVIEW for applying the per-role convention inconsistently.
