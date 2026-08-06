# Graph fleet subtree — new system; old fleet stays default until M5
Spec of record: docs 03 (runtime), 04 (nodes), 05 (pipelines) of the approved
graph-engine design. Implement, don't re-design; deviations become DKT issues
per 08 §3.
Never edit or copy src/user/claude-code/** from here; distillation happens
only in M2 sessions from per-contract named sources.
Sizes are diagnostics: skills ~2–4KB, archetypes ~1KB; hooks are one-line
`docket guard` shims holding no policy.
Bash writes to .claude/{agents,skills,hooks} are sandbox-denied — wire through
the dotfiles render path or Edit/Write tools.
.docket/config/ is machine-authored (bootstrap/retro), human-approved in
conversation; hand-editing it violates T9.
