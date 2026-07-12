# Docket CLI Reference — Maintained Master

**LOCAL-copy consumers:** `project-manager.md`, `sdet.md`, `senior-engineer.md` — each carries a
compact, role-scoped `CANONICAL:DOCKET-CLI-LOCAL` copy replacing what was previously divergent
inline command tables (DKT-185 consolidation). Source of truth for the table below is
`project-manager.md`'s original copy, byte-exact verified against live `docket --help` (version
b59dd2f). Deployed at `~/.claude/skills/team-doctrine/references/docket-cli.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/docket-cli.md`. Read on demand only —
never `Skill(team-doctrine)`.

---

## Docket CLI Reference

<!-- CANONICAL:DOCKET-CLI:BEGIN -->

```
docket init / version / board --json [--expand] [-a ASSIGNEE] [-l] [-p] / next --json [--limit N] [-l] [-p] [-T] [-s] / stats
docket plan --json [--root ID] [--label LABEL] [-s STATUS]
docket issue create -t TITLE [-d DESC] [-p PRIORITY] [-T TYPE] [-l LABEL] [--parent ID] [-f FILE ...] [-a ASSIGNEE] [-s STATUS]
docket issue list --json [-a ASSIGNEE] [-s STATUS] [-p PRIORITY] [-l LABEL] [-T TYPE] [--parent ID] [--tree] [--roots] [--sort FIELD:DIR] [--limit N] [--all]
docket issue show <id> --json / edit <id> [-t] [-d] [-s] [-p] [-T] [-a] [-f FILE ...] [--parent ["none"|"0"]] / delete <id> [-f] [--orphan]   # edit -f REPLACES all file attachments — prefer issue file add/remove
docket issue move <id> <status> / close <id> / reopen <id>
docket issue comment list <id> / comment add <id> -m "text"   # comment add (and doc comment add) take ONLY -m <text> — no --body, no -b, no positional message arg
docket issue link add <id> blocks|depends_on|relates_to|duplicates <target> / link list <id> / link remove <id> <relation> <target_id>
docket issue file add <id> <paths> / file list <id> / file remove <id> <paths>
docket issue graph <id> [--mermaid] [--depth N] [--direction up|down|both]
docket issue label add <id> <labels> [--color HEX] / label rm <id> <labels> / label list / label delete <label> [-f]
docket issue log <id> [--limit N]
docket export [-f FILE] [-o json|csv|markdown] [-l LABEL] [-s STATUS] / import [--merge] [--replace]
docket doc create -t TITLE [-d DESC|@path|-] [-T TYPE] [-s STATUS] / doc show <id> --json / doc list --json / doc edit <id> [-t] [-d] [-s] [-T] / doc delete <id> [--cascade] [-f] / doc link add <doc-id> --issue <issue-id> / doc link remove <doc-id> --issue <issue-id> / doc comment add <id> -m "text" / doc comment list <id>   # durable spec/PRD→issue traceability
docket vote create -c CRITICALITY -d DESC -n VOTERS [--threshold FLOAT] [-r|--rationale TEXT] [--created-by NAME] [--domain-tags TAGS] [--files-changed FILES] [--escalation-reason TEXT]   # --threshold CLI-defaults to 0.67 regardless of -c criticality
docket vote cast <id> -v approve|approve-with-concerns|reject --voter NAME [--role ROLE] [--summary TEXT] [--confidence F] [--domain-relevance F] [--findings TEXT|-] [--findings-json JSON|-]
docket vote show <id> / result <id> / list [-s STATUS] [-c CRITICALITY] [-d DOMAIN-TAG] [--limit N] [--all]   # list defaults to open only; --all includes committed/rejected
docket vote link <proposal-id> --issue <id> / unlink <proposal-id> --issue <id>   # bind votes to issues for operator traceability
```

Global: `--quiet` (structured-only), `--watch`/`--interval` (live), `--json` (everywhere). Aliases: `docket i`/`issue ls`, `docket d`/`doc ls`, `docket v`/`vote ls`.
**Status:** backlog (create default) | todo | in-progress | review (schema-valid but intentionally unused — review happens via SendMessage/comments, not a status transition) | done | **Priorities:** critical | high | medium | low | none (create default) | **Types:** bug | feature | task (default) | epic | chore
**Grooming foot-gun:** `issue delete <id> --orphan` promotes sub-issues to roots — preserve work when removing a wrong parent (the `edit -f` replace-warning lives on the edit line above).

<!-- CANONICAL:DOCKET-CLI:END -->
