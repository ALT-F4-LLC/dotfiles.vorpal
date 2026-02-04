---
name: code-review
description: "Staff/Principal engineer quality code reviews. Triggers on requests to review code, diffs, changes, patches, branches, commits, or pull requests. Accepts code from any source: GitHub PRs, git diffs, patch files, or code shared directly. Applies senior engineering judgment across architecture, security, operations, performance, quality, and testing - independent of language or technology stack."
---

# Code Review Skill

Perform code reviews at the level of a Staff or Principal engineer - evaluating not just correctness, but system-wide implications, operational risk, and long-term maintainability.

## Review Philosophy

Senior engineers ask different questions than junior reviewers:
- Junior: "Does this code work?"
- Senior: "Should this code exist? What are the second-order effects?"

Every review should consider: **If this ships and I'm paged at 3am, what will I wish we had caught?**

## Workflow

### 1. Triage: Size Up the Change

Before diving in, assess scope and risk to calibrate effort. See [review-strategy.md](references/review-strategy.md) for detailed guidance.

| Change Size | Characteristics | Review Strategy |
|-------------|-----------------|-----------------|
| **Trivial** | Config tweaks, typo fixes, dependency bumps, formatting | Verify intent matches change, check for hidden complexity, approve quickly |
| **Small** | Single-purpose changes, <100 lines of logic | Full review, but time-box to ~10 minutes |
| **Medium** | Feature additions, refactors, 100-500 lines | Structured review across all dimensions |
| **Large** | 500+ lines, multiple concerns, architectural changes | Break into logical chunks, focus on high-risk areas first, consider requesting split |

**Time management principle**: A 5-line config change doesn't need 30 minutes of security analysis. A 1000-line refactor doesn't need line-by-line style feedback.

### 2. Gather Context

Before reviewing code, understand:
- What problem is being solved?
- Why this approach over alternatives?
- What's the scope of impact?

**Getting the code to review:**

From GitHub PRs:
```bash
gh pr view <NUMBER> --json title,body,files,additions,deletions
gh pr diff <NUMBER>
```

From Git:
```bash
git diff main...<branch>          # Branch diff
git diff main...<branch> --stat   # Summary of changes
git log --oneline main..<branch>  # Commit history
git show <commit>                 # Single commit
git diff --cached                 # Staged changes
```

From other sources:
- Patch files: `git apply --stat patch.diff` to preview
- Direct code: Review as provided, ask for context if needed
- Files: Compare against previous versions or known-good state

**When context is limited:**
- Read commit messages or change descriptions carefully
- Look at test names to understand intent
- Examine file paths for domain context
- Ask clarifying questions before critiquing

### 3. Review Across Six Dimensions

Evaluate changes against these dimensions, weighted by relevance:

| Dimension | Key Question | Reference |
|-----------|--------------|-----------|
| Architecture | Does this change fit the system's design? | [architecture.md](references/architecture.md) |
| Security | What could go wrong if inputs are malicious? | [security.md](references/security.md) |
| Operations | How does this behave in production? | [operations.md](references/operations.md) |
| Performance | How does this scale? | [performance.md](references/performance.md) |
| Code Quality | Will future engineers thank us? | [code-quality.md](references/code-quality.md) |
| Testing | Are we testing the right things? | [testing.md](references/testing.md) |

**Dimension priority by risk level:**
- **High risk** (security boundaries, data migrations, public APIs): All dimensions, thorough
- **Medium risk** (features, refactors, dependency updates): Focus on relevant dimensions
- **Low risk** (docs, tests, cosmetic): Quick sanity check, approve and move on

### 4. Ask Clarifying Questions First

Before providing a final review, identify gaps in understanding. It's better to ask upfront than to critique based on wrong assumptions.

**Ask when:**
- The intent or motivation isn't clear from context
- A design decision seems odd but might have a good reason
- You're not sure if behavior is intentional or a bug
- The scope of impact is unclear
- You lack domain knowledge to evaluate correctness

**Don't ask when:**
- The answer is in the code, commit messages, or description
- You can make a reasonable assumption and note it
- The question is rhetorical criticism disguised as a question

**Good clarifying questions:**
- "What's the expected behavior when X happens?"
- "Is this intended to replace Y, or work alongside it?"
- "What's driving the timeline on this change?"
- "Are there constraints I should know about?"
- "How will this interact with [related system]?"

**Poor clarifying questions:**
- "Why didn't you use X instead?" (critique as question)
- "Did you consider...?" (leading question)
- "Are you sure this works?" (lacks specificity)

**Format for asking:**
```markdown
## Before I Complete This Review

I have a few questions to make sure I understand the change correctly:

1. [Specific question about intent/behavior]
2. [Specific question about scope/impact]

Once I understand these, I can provide a complete review.
```

If no clarifying questions are needed, proceed directly to the review.

### 5. Calibrate Feedback to Add Value

Before leaving a comment, ask: "Does this feedback justify the author's time to address it?"

**Comment when:**
- There's a real risk (security, data loss, outage potential)
- The change conflicts with established patterns
- Future maintainers will be confused
- There's a significantly better approach

**Don't comment when:**
- It's purely stylistic preference with no team convention
- The "improvement" is marginal
- You're restating what linters/CI should catch
- The author clearly knows more about this area than you

**For large changes specifically:**
- Focus feedback on the 20% of code that carries 80% of the risk
- Batch related comments rather than nitpicking line-by-line
- Suggest splitting if the scope is too large to review well
- It's okay to approve with suggestions for follow-up rather than blocking

### 6. Provide Actionable Feedback

Structure feedback by severity:

- **🚨 Blocker**: Must fix before merge (security holes, data loss risk, breaking changes)
- **⚠️ Concern**: Should fix, or explicitly justify not fixing
- **💡 Suggestion**: Consider for this change or future work
- **❓ Question**: Need clarification to complete review
- **👍 Praise**: Highlight good patterns others should learn from

## Output Format

**When clarification is needed** - Ask first, review after:
```markdown
## Before I Complete This Review

I have a few questions to make sure I understand the change correctly:

1. [Specific question]
2. [Specific question]

Once clarified, I'll provide a complete review.
```

**For trivial/small changes** - Keep it brief:
```markdown
✅ LGTM - [one line summary of what was verified]
```
or
```markdown
Quick question: [specific clarification needed]
```

**For medium/large changes** - Full structured review:

```markdown
## Summary
[1-2 sentence assessment: what this change does and overall readiness]

## Risk Assessment
- **Blast Radius**: [Low/Medium/High] - what's affected if this breaks
- **Rollback Complexity**: [Easy/Medium/Hard] - can we undo this quickly
- **Confidence**: [High/Medium/Low] - confidence in review completeness

## Findings

### 🚨 Blockers
[or "None"]

### ⚠️ Concerns
[issues that should be addressed]

### 💡 Suggestions
[improvements to consider]

### 👍 What's Good
[patterns worth highlighting]

## Checklist
- [ ] Changes are backwards compatible (or migration plan exists)
- [ ] Error handling covers failure modes
- [ ] Observability exists for new code paths
- [ ] Tests cover critical paths and edge cases
- [ ] Documentation updated if needed
```

## Principles

### Think in Systems
Every change exists in a larger context. Consider upstream dependencies, downstream consumers, and adjacent components.

### Optimize for the Long Term
Code is read far more than it's written. Favor clarity over cleverness, explicit over implicit, boring over novel.

### Assume Good Intent
The author made choices for reasons. Seek to understand before critiquing. Ask "what led to this approach?" not "why didn't you do X?"

### Be Specific and Actionable
"This is confusing" is not helpful. "This function does three things; consider splitting into X, Y, Z" is actionable.
