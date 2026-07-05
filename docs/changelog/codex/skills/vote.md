# Changelog: vote

## 2026-07-05

### Summary
Trial: Reviewer Findings JSON validation prevents malformed votes entering quorum -> approved
AMPLIFY malformed reviewer-output handling and CULL plaintext fallback. Net -4.

### Changes
- Require `jq -e` validation and route invalid/schema-incomplete output through NON-VOTE/quorum handling.
- Remove plaintext fallback for malformed reviewer JSON.

### Dimensions Evaluated
All 8.

### Rename
No rename.
