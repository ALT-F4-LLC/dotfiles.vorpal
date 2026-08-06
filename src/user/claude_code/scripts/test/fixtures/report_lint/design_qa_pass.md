## Design QA: Upload progress spec

### Spec Reference
- Path: docs/ux/upload-progress.md
- Maturity / status: stable
- Surface(s): Web

### Verdict
**Pass with Issues**

### Issues

| # | Severity | Spec Section | Description |
|---|---|---|---|
| 1 | Concern | Error States | spec requires retry copy; implementation at Upload.tsx:88 shows a bare "failed" string |

### What's Implemented Well
- The percentage readout matches the spec copy exactly

### Acceptable Deviations
- None

### Recommendation
Route the Concern to @senior-engineer to align the error copy with the spec.

Design QA report emitted (Pass with Issues).
