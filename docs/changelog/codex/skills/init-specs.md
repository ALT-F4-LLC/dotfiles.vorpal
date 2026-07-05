# Changelog: init-specs

## 2026-07-05

### Summary
Trial: Ledger-backed verification and fallback prompts improve spawn-failure recovery -> approved
AMPLIFY ledger-backed verification and no-subagent fallback prompts while preserving explicit-only metadata and pinned worker defaults. Net 0.

### Changes
- AMPLIFY: verification now keys generated files off ledger rows reported in Step 2.
- AMPLIFY: emit fallback prompt files and operator-run `codex exec` guidance when spawning is unavailable.

### Dimensions Evaluated
All 8.

### Rename
No rename.
