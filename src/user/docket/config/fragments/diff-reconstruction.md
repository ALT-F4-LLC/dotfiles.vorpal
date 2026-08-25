---
fragment: diff-reconstruction
version: 2
---
# Reconstructing an empty diff

An empty `issue.diff` beside a change-summary that names commits is not a missing
input: the fix landed as ordinary commits before this step ran. Review those
commits (`git show <sha>` in your own worktree) as the diff under judgment, and
say in your findings that the target was reconstructed that way (an earlier run set this
pattern). Gap only when neither the diff nor any named commit is reachable.
