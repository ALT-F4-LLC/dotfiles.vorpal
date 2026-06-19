# Team-Lead Orchestration Pitfalls

Append-only. Harvested by evolve-* cycles. Each entry: symptom → root cause → resolution.

---

## 2026-06-19 — evolve-skills cycle

**Pitfall: `disallowed-tools` in Agent() spawn templates is non-executable**
- Symptom: Phase 1 reviewer recommends adding `disallowed-tools: ["Edit","Write"]` to the `prompt=` body of an `Agent()` spawn call to enforce read-only behavior.
- Root cause: `disallowed-tools` is an agent-definition frontmatter field — it applies to the referenced `subagent_type` definition at load time, NOT to the orchestrator's `Agent()` call. The spawn call accepts only `tools`, `model`, and `prompt`; a `disallowed-tools` line inside the prompt body is inert prose.
- Resolution: Reject as Content Gate failure (Executable: no). Tool restriction on a teammate comes from the subagent definition's own frontmatter (`agents/*.md` or the registered definition). Prose "Read-only. No Edit/Write." in the prompt is the correct and only available mechanism from the orchestrator side.

**Pitfall: CANONICAL tags are invalid as biodiversity niche-token filters**
- Symptom: Biodiversity invariant instructs reviewers to use a "CANONICAL tag" (e.g. `CANONICAL:HARVEST`) as the niche-defining token for `grep -lE` carrier-count checks.
- Root cause: A CANONICAL tag is intentionally present in EVERY carrier of that block family (byte-parity requirement). Grepping for it always returns the full family population, making it indistinguishable from monoculture regardless of actual niche diversity.
- Resolution: Use only "niche-defining behavior keyword" (a capability keyword or rule name unique to the niche). Applied lockstep to evolve-agents + evolve-skills in the 2026-06-19 cycle. Verify with `grep -h "defining behavior keyword" <files> | sort -u` → 1 unique sub-clause.

**Pitfall: evolve-config changelog path confusion — two different paths for two different things**
- Symptom: Phase 1 reviewer of evolve-config writes the skill-evolution changelog to `docs/changelog/config/claude-code.md` instead of `docs/changelog/skills/evolve-config.md`.
- Root cause: evolve-config's own SKILL.md documents `docs/changelog/config/<artifact-name>.md` as the path where it writes config-genome change records (changes to `src/user.rs` etc.). A reviewer reading this conflates the artifact changelog with the skill-definition changelog.
- Resolution: When evolve-skills edits evolve-config/SKILL.md, the changelog always goes to `docs/changelog/skills/evolve-config.md` (consistent with all other skills in the family). `docs/changelog/config/claude-code.md` is written by evolve-config at runtime when it actually evolves the config sources — a completely separate path. Verify the correct path before writing.

**Pitfall: `day=N` (singular) causes evolve-skills to abort — accept as alias for `days=N`**
- Symptom: Operator types `/evolve-skills day=7 drift=7`; skill aborts at pre-flight step 5 because `day=7` is not stripped by the parser (only `days=` and `drift=` are), so it is treated as a skill-name token, validated as a skill directory, fails, and aborts.
- Root cause: Argument-handling only strips `days=N`, not the common typo `day=N`.
- Resolution: Accept `day=N` as an alias for `days=N` in both the bullet description and the Parsing line. Applied in evolve-skills 2026-06-19 cycle; consider applying the same alias in evolve-agents and evolve-config for consistency.
