## Review (general — @staff-engineer)

### Summary
Adds a retry wrapper around the upload path.

### Scope Reviewed
- Source: uncommitted
- Files changed: 2 (uploader.go, uploader_test.go)
- Reference docs: None applicable

### Risk Assessment
- Blast radius: upload path only
- Rollback complexity: trivial
- Confidence: high — covered by the new table test

### Findings

**Blockers** (1):
- uploader.go:42 — G1 swallowed error on the retry branch — return the wrapped error

**Concerns** (0):
- None

**Suggestions** (0):
- None

**Questions** (0):
- None

**Praise**:
- Clean table-driven test at uploader_test.go:10

**Overrides Recognized** (0):
- None

### Hard Gates Triggered
- **G1 (swallowed error):** uploader.go:42 — discarded retry error — return it
- **G2 (unguarded shared mutation):** None
- **G3 (unparsed boundary input):** None
- **G4 (surface-not-invariant patch):** None
- **G5 (unexecuted AC regex):** None

### Dimension Checklist
| Dimension | Status |
|---|---|
| Architecture | pass |
| Security (general) | pass |
| Operations | pass |
| Performance | N/A |
| Code Quality (12 principles) | concern |
| Testing | pass |

### Recommendation
**Block** — the swallowed error at uploader.go:42 must be returned before merge.

### Next Steps
Route the Blocker to @senior-engineer for the fix.

Code review emitted (Block).
