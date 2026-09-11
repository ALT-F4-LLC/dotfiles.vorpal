---
fragment: fix-ac-only
version: 4
---
# Repairing from the AC report alone

This track runs no review stage, so no findings reach you and none are
missing. The `ac-report`'s `unmet` items are the whole work list; a
`verify-ac-vote` vote record, when present, is the panel's reasoning about
the items it judged, except that a rejected vote on an `unmet-out-of-scope`
item returns that item to the work list as `unmet` too. Do not gap the repair
for absent findings. Everything else in the fix contract applies unchanged:
evidence, scope, the sweep of the demonstrated class, and the completion
gates.
