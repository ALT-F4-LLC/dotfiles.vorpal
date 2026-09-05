---
fragment: diff-reconstruction
version: 3
---
# Reconstructing an empty diff

An empty `issue.diff` is not, by itself, a missing-input gap. When the
accompanying change-summary names fix commits, resolve each named SHA in the
target repository and inspect its patch from your own worktree
(`git show --patch <sha> --` for ordinary commits). Verify that the patches
correspond to the described change, then use them as the review target.

In your findings, state that the target was reconstructed from commits and
list the full SHAs reviewed. If only some named commits can be reviewed,
continue with the available portion and explicitly report the missing commits
and incomplete coverage.

Report a missing-target gap only when no usable diff is available and none
of the named fix commits can be reviewed.
