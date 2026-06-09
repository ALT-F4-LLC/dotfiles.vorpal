# Team-Lead Recurring Pitfalls

Append-only. Format: symptom → root cause → resolution. Harvested by evolve-* cycles; never cleared.

## evolve-skills / evolve-agents: changelog↔file drift

- **Symptom:** A skill's changelog entry from a prior cycle claims an edit (e.g. "removed the circular ux-designer.md cite", "added a §7 `docket doc list` reconfirm clause") that is NOT present in the live file. Multiple Phase 1 reviewers independently flag the same drift across the skill family in one cycle (2026-06-08: ux-spec, verify-ac, adr, prd all noted stale 2026-06-04/06-05 narratives).
- **Root cause:** The orchestrator wrote the changelog entry before confirming the Edit actually landed (an Edit can silently no-op on a non-unique/whitespace-mismatched OLD_STRING), OR a later refactor (e.g. the 2026-06-08 file-based-docs change) superseded the edit and the append-only changelog was never reconciled. Changelogs are never rewritten, so a falsely-claimed edit persists forever and misleads the next cycle into a NO-OP hunt.
- **Resolution:** After applying each edit, `grep` the LIVE file to confirm the change is present BEFORE writing the changelog that claims it. When a reviewer reports "changelog says X but file lacks it", treat the LIVE FILE as truth (do not re-apply blindly — the file may be correct and the changelog stale). Never retroactively edit a prior changelog entry; just ensure the current entry is accurate. Bias Phase 1 briefs toward "verify-then-recommend, report NO-OP with line ref" so already-correct files aren't churned.
