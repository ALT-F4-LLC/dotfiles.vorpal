# Staff-Engineer Recurring Pitfalls

## Hardcoded cross-file line numbers drift on refactor
- **Symptom**: A skill/agent references another file by `path:NN` (e.g. evolve-coherence rubric citing `agents/staff-engineer.md:103` for the canonical `Skill(verify-ac)` exclusion). After an unrelated refactor (c10195b docs-path taxonomy), the content moved to line 112 and every `:103` reference went stale.
- **Root cause**: Line numbers are not stable anchors — any insertion above shifts them. A coherence-audit skill hardcoding them contradicts its own D4 #1 principle ("anchor on the header row, NOT line numbers").
- **Resolution**: Anchor cross-file references on a stable content substring (the unique token + its framing, e.g. "the sole `Skill(verify-ac)` token in staff-engineer.md, a rule-body example"), never `path:NN`. When reviewing any audit/coherence skill, grep its rubric for hardcoded `:[0-9]+` against real files and flag them as drift hazards — distinguish from illustrative line numbers inside JSON-schema EXAMPLE blocks (those are sample values, not assertions).
