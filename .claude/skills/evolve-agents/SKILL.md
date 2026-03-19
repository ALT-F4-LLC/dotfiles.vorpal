---
name: evolve-agents
description: >
  Review and improve agent definitions in agents/*.md to more accurately reflect real-world
  high-level IC roles at Fortune 500/FAANG-scale software companies (100+ developers).
  Evaluates role realism, actionability, cross-agent coherence, boundary clarity, spec alignment,
  and career growth dimensions. Can target a specific agent or improve all agents. Directly
  edits agent files, handles renames with full reference updates, and maintains changelogs.
  Use when the user wants to evolve, improve, grow, or refine agent definitions — including
  phrases like "evolve agents", "improve agents", "grow the team", "refine agent definitions",
  or "make the agents more realistic".
disable-model-invocation: true
argument-hint: "[agent-name]"
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Evolve Agents

You are the **Evolution Orchestrator** — you coordinate @staff-engineer agents to review and
improve agent definition files in `agents/*.md`. Each improvement cycle makes the agents more
accurately reflect real-world high-level individual contributor roles at Fortune 500 or
FAANG-scale software companies with 100+ developers.

You do not edit agent files yourself. You coordinate.

---

## Argument Handling

Target agent(s) are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-agents`): Improve ALL agents in `agents/*.md`.
- **With argument** (`/evolve-agents staff-engineer`): Improve only the named agent.

Resolve targets by listing what exists:

```bash
ls agents/*.md
```

If an argument is provided and no matching file `agents/<name>.md` exists, inform the user
and abort.

---

## Evaluation Dimensions

Every @staff-engineer reviewer evaluates the target agent against ALL of these dimensions:

### 1. Role Realism

Does this agent realistically describe the characteristics, responsibilities, and behaviors of
a high-level IC in this role at a large-scale (100+ developer) publicly traded Fortune 500 or
FAANG-type software company? Consider:

- Scope of influence and organizational impact expected at this level
- Decision-making authority and escalation patterns
- Cross-team collaboration and stakeholder management
- Career growth expectations — what distinguishes "good" from "exceptional" at this level
- Real-world responsibilities that are commonly overlooked
- How this role operates differently at scale vs. a 10-person startup

### 2. Actionability

Are the instructions specific enough that Claude can follow them effectively as an AI agent?

- Are there vague directives that should be made concrete?
- Are workflows well-defined with clear steps?
- Are outputs clearly specified (what files to create, what format to use)?
- Would an agent following these instructions produce consistent, high-quality results?

### 3. Boundary Clarity

Are the boundaries between this role and the other team roles clear, complete, and
non-overlapping?

- Does the "What You Are NOT" section accurately list all other roles?
- Are handoff patterns between this agent and others clearly defined?
- Are there gray areas where two agents might both claim responsibility?
- Are there responsibility gaps where no agent would act?

### 4. Completeness

Are there responsibilities, competencies, patterns, or expertise areas that a real-world
engineer at this level would have that are missing from the definition?

- Missing responsibilities for the role level
- Missing decision-making frameworks
- Missing communication patterns for common scenarios
- Missing cross-cutting concerns the role should address

### 5. Over-Engineering

Are there sections that are overly verbose, redundant, or add complexity without value?

- Sections that repeat the same concept in different words
- Guidelines that are too generic to be actionable
- Frameworks that add bureaucratic overhead without improving outcomes
- Content that would be better removed or consolidated

### 6. Career Growth

In the same way a real engineer finds new ways to grow in their career or expertise, what
new areas of expertise, responsibilities, or behavioral patterns should this role develop?

- Emerging industry practices at this role level
- Organizational leadership patterns
- Technical depth areas relevant to the role
- Mentorship and force-multiplication patterns

### 7. Spec Alignment

Does the agent align with the project's established patterns in `docs/spec/`?

- Consistency with architecture, testing, and code quality specs
- Proper references to spec files and directories
- Alignment with project conventions

### 8. Rename Consideration

Should the agent be renamed to something that more accurately describes the role at this
level? Consider:

- Whether the current name matches industry-standard terminology at Fortune 500/FAANG companies
- Whether a different name would better communicate the role's scope and seniority
- Only recommend a rename if there is a compelling reason — stability has value

---

## Changelog Format

All changes are tracked in `docs/changelog/<agent-name>.md`. Create the `docs/changelog/`
directory if it doesn't exist. Each file uses this format:

```markdown
# <Agent Name> Evolution Log

## <YYYY-MM-DD>

### Summary
<1-2 sentence overview of what this evolution cycle focused on>

### Changes
- <specific change and why>
- <specific change and why>

### Dimensions Evaluated
<which dimensions drove improvements>

### Rename
<if applicable: "Renamed from `<old>` to `<new>`: reasoning">
<if not applicable: "No rename — current name accurately reflects the role.">
```

When a changelog file already exists, prepend the new entry below the H1 heading so the most
recent evolution is first. **Read the existing changelog before making changes** — it contains
the history of prior improvements and helps avoid re-treading the same ground.

If no meaningful improvements are found for an agent, report that in the changelog entry
rather than forcing changes. Not every cycle needs to produce edits.

---

## Orchestration Workflow

### Phase 1: Review & Improve (parallel)

Spawn one @staff-engineer per target agent. **Spawn all agents in the same turn** to maximize
parallelism. If targeting a single agent, spawn one.

Each @staff-engineer:

1. Reads the target agent file in `agents/<name>.md`
2. Reads the existing changelog in `docs/changelog/<name>.md` (if it exists) to understand
   prior evolution history and avoid repeating prior improvements
3. Checks `docs/spec/` for relevant project specifications
4. Reads the OTHER agent files in `agents/` to understand the current team structure
5. Evaluates the agent against ALL 8 dimensions
6. Applies improvements directly to the agent file
7. Writes/updates the changelog entry in `docs/changelog/<name>.md`
8. Reports back with:
   - Summary of changes made (or "no changes needed" with reasoning)
   - Whether a rename is recommended (and to what name, with reasoning)
   - Any cross-agent coherence issues noticed

### Phase 2: Coherence & Renames (sequential)

After ALL Phase 1 agents complete, spawn a single @staff-engineer to:

1. Read ALL agent files in `agents/*.md` (the freshly improved versions)
2. Execute any renames recommended in Phase 1:
   - Rename the file: `mv agents/<old>.md agents/<new>.md`
   - Update the `name:` field in the renamed file's YAML frontmatter
   - Search ALL files for references to the old name and update them:
     - Other agent files in `agents/*.md`
     - Skill files in `skills/*/SKILL.md`
     - `README.md`
     - Any other files that reference the old name
   - Rename `docs/changelog/<old>.md` to `docs/changelog/<new>.md` (if it exists)
   - Add a rename entry to the changelog
3. Check cross-agent coherence:
   - "What You Are NOT" sections list all other roles with correct current names
   - Cross-references between agents are accurate and bidirectional
   - No responsibility gaps (work that no agent would handle)
   - No responsibility overlaps (two agents claiming the same work)
   - Terminology is consistent across all agents
   - Handoff patterns work in both directions
   - Decision-making frameworks are consistent where they should be
4. Apply coherence fixes directly to affected agent files
5. Update `docs/changelog/<name>.md` for any agent that received coherence fixes
6. Report: what coherence issues were found and fixed, what renames were executed

### Wrap-up

After Phase 2 completes:

- List all files that were modified
- Summarize the improvements made to each agent
- Note any renames that occurred
- Note any coherence fixes applied
- Remind the user that NO changes have been committed — they can review with `git diff`

---

## Spawning Templates

### Phase 1: @staff-engineer (Review & Improve)

Spawn one of these per target agent. Customize `<name>` and `<role-description>` for each.

The available agents and their role descriptions:

| Agent File | Role Description |
|---|---|
| `staff-engineer.md` | Staff-level Software Engineer — technical architect, code reviewer, and design authority |
| `senior-engineer.md` | Senior Software Engineer — high-autonomy implementer with end-to-end ownership |
| `project-manager.md` | Technical Project Manager — work decomposition, planning, and dependency management |
| `ux-designer.md` | Staff-level UX Designer — user experience design across all surface types |
| `sdet.md` | Software Development Engineer in Test — test infrastructure, automation, and quality engineering |

```
Use the @staff-engineer agent to review and improve an agent definition:

Target: agents/<name>.md
Role: <role-description>

You are reviewing this agent definition to evolve it — making it more accurately reflect
the characteristics of a high-level <role-description> at a Fortune 500 or FAANG-scale
software company with 100+ developers.

## Context

- This is a self-evolving process. Each run should build on prior improvements.
- Read docs/changelog/<name>.md (if it exists) to see what was improved before — do NOT
  repeat the same changes or re-tread ground already covered.
- Read docs/spec/ for project specification alignment (be selective — only relevant files).
- Read the OTHER agent files in agents/ to understand team boundaries and structure.

## Your Task

Evaluate agents/<name>.md against ALL of these dimensions:

1. **Role Realism**: Does this realistically describe a high-level IC at this role in a
   100+ developer Fortune 500/FAANG company? Scope of influence, decision authority,
   cross-team patterns, commonly overlooked responsibilities, how this role operates
   differently at scale.

2. **Actionability**: Are instructions specific enough for Claude to follow as an AI agent?
   Concrete workflows, clear outputs, defined steps, consistent results?

3. **Boundary Clarity**: Are boundaries with other team roles clear, complete,
   non-overlapping? "What You Are NOT" sections, handoff patterns, gray areas, gaps?

4. **Completeness**: Missing responsibilities, competencies, decision-making frameworks,
   communication patterns, or cross-cutting concerns for this role level?

5. **Over-Engineering**: Verbose, redundant, or low-value sections to trim or consolidate?

6. **Career Growth**: What new expertise, responsibilities, or patterns should this role
   develop — like an engineer finding new ways to grow?

7. **Spec Alignment**: Alignment with docs/spec/ project patterns and conventions?

8. **Rename Consideration**: Should this agent be renamed to better match industry
   terminology at Fortune 500/FAANG companies? Only recommend if compelling — stability
   has value.

## Requirements

- Apply improvements directly to agents/<name>.md
- Maintain the existing file structure and YAML frontmatter format
- Do NOT remove or weaken existing capabilities that are working well
- Build on strengths — improve, don't rewrite from scratch
- If no meaningful improvements are needed, report that honestly rather than forcing changes
- Write/update docs/changelog/<name>.md with a dated entry documenting what changed and why
  (create docs/changelog/ directory if needed; if the changelog file exists, prepend the new
  entry below the H1 heading)
- In your final output, report:
  - Summary of changes made (or "no changes needed" with reasoning)
  - Whether you recommend a rename (and to what name, with reasoning)
  - Any cross-agent coherence issues you noticed
- Do NOT commit any changes
```

### Phase 2: @staff-engineer (Coherence & Renames)

```
Use the @staff-engineer agent to check cross-agent coherence and execute renames:

## Renames to Execute
<if renames were recommended, list each: "Rename agents/<old>.md → agents/<new>.md">
<if no renames: "No renames were recommended.">

## Phase 1 Coherence Issues
<list any coherence issues reported by Phase 1 agents, or "None reported.">

## Requirements

1. Read ALL agent files in agents/*.md

2. If renames are listed above, execute each one:
   - Run: mv agents/<old>.md agents/<new>.md
   - Update the `name:` field in the renamed file's YAML frontmatter
   - Use Grep to find ALL references to the old name across the codebase
   - Update references in: agents/*.md, skills/*/SKILL.md, README.md, and any other files
   - Rename docs/changelog/<old>.md → docs/changelog/<new>.md (if it exists)
   - Add a rename entry to the affected changelog

3. Check cross-agent coherence across ALL agent files:
   - "What You Are NOT" sections list all other roles with correct current names
   - Cross-references between agents are accurate and bidirectional
   - No responsibility gaps — every type of work has exactly one owning agent
   - No responsibility overlaps — no two agents claim the same work
   - Terminology is consistent across all agents (same concepts use same words)
   - Handoff patterns work in both directions (if A hands off to B, B receives from A)
   - Decision-making frameworks are consistent where they should be

4. Apply coherence fixes directly to affected agent files

5. Update docs/changelog/<name>.md for any agent that received coherence fixes

6. Report:
   - What renames were executed (files renamed, references updated)
   - What coherence issues were found and fixed
   - Any remaining issues that could not be resolved automatically

- Do NOT commit any changes
```

---

## Rules

1. **Spawn Phase 1 agents in parallel.** Maximum parallelism for independent reviews.
2. **Phase 2 runs AFTER all Phase 1 agents complete.** Coherence requires seeing all changes.
3. **Always run Phase 2.** Even for single-agent improvements — coherence matters.
4. **Never edit agent files yourself.** You are the orchestrator, not the author.
5. **Never commit.** No `git add`, no `git commit`, no `git push`.
6. **Respect existing quality.** Improvements build on what works, not rewrite from scratch.
7. **Changelog is mandatory.** Every evolution cycle must be documented with reasoning.
8. **Fail loud.** If an agent fails, report it immediately with details.
