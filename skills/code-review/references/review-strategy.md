# Review Strategy

## Core Question
How do I allocate my review time to maximize value?

## Change Size Strategies

### Trivial Changes (1-10 lines)

**Examples**: Typo fixes, config value changes, single-line bug fixes, version bumps

**Strategy**: Quick verification, fast approval
1. Verify the change matches the stated intent
2. Check for hidden complexity (is this really just a typo?)
3. Ensure no unintended side effects
4. Approve

**Time budget**: 1-2 minutes

**What to watch for**:
- "Typo fix" that actually changes logic
- Config changes with security implications
- Dependency updates with breaking changes
- Changes to files that shouldn't be edited

**Output**: Brief approval or quick question. No need for full structured review.

### Small Changes (10-100 lines)

**Examples**: Bug fixes, small features, targeted refactors

**Strategy**: Focused review on primary dimension
1. Identify the primary concern (is this a security fix? performance change? new feature?)
2. Review thoroughly for that dimension
3. Quick scan of other dimensions
4. Provide focused feedback

**Time budget**: 5-15 minutes

**What to watch for**:
- Scope creep (is this really one change?)
- Missing tests for the change
- Error handling for new code paths

### Medium Changes (100-500 lines)

**Examples**: Feature implementations, significant refactors, new integrations

**Strategy**: Structured multi-dimension review
1. Read description/commit messages first
2. Understand the overall shape of the change
3. Review high-risk files first (new files, security-sensitive areas)
4. Work through each relevant dimension
5. Provide structured feedback

**Time budget**: 15-45 minutes

**What to watch for**:
- Architectural fit
- Missing observability
- Incomplete error handling
- Test coverage gaps

### Large Changes (500+ lines)

**Examples**: Major features, large refactors, migrations

**Strategy**: Risk-focused chunked review
1. **Don't review linearly** - prioritize by risk
2. Request split if changes are truly independent
3. Focus on architectural decisions and high-risk areas
4. Trust author on low-risk mechanical changes
5. Approve with follow-up items rather than blocking on minor issues

**Time budget**: 30-60 minutes, possibly spread across sessions

**Review order for large changes**:
1. Description and design context
2. Interface changes (APIs, contracts, schemas)
3. Security-sensitive code
4. Core business logic
5. Error handling and edge cases
6. Tests (verify coverage, not implementation)
7. Supporting code (utilities, helpers)

**What to watch for**:
- Should this be multiple changes?
- Are there architectural decisions buried in implementation details?
- Is there adequate test coverage for the scope?
- Are there rollback/migration concerns?

## When to Request a Split

Request split when:
- Changes are logically independent (refactor + feature + bug fix)
- Risk levels vary significantly across changes
- Different reviewers would be appropriate for different parts
- The change is too large to review confidently in one session

How to ask:
- Be specific about the suggested split
- Acknowledge the work already done
- Explain the benefit (faster review, easier rollback, clearer history)

## When to Approve with Caveats

It's often more productive to approve and track follow-ups than to block:

**Approve with follow-up when**:
- Issues are real but low-risk
- Blocking would significantly delay important work
- The author commits to addressing in a follow-up
- Issues are improvements, not correctness problems

**Block when**:
- Security vulnerabilities
- Data loss or corruption risk
- Breaking changes without migration path
- Critical missing tests

## Review Input Sources

### GitHub PRs
```bash
gh pr view <NUMBER> --json title,body,files
gh pr diff <NUMBER>
```
Context available: PR description, linked issues, CI status, reviewer comments

### Git Diffs
```bash
git diff main...<branch>           # Feature branch
git diff HEAD~5..HEAD              # Recent commits
git show <commit>                  # Single commit
git diff --cached                  # Staged changes
```
Context available: Commit messages, file history

### Patch Files
```bash
git apply --stat patch.diff        # Preview changes
git apply --check patch.diff       # Verify applies cleanly
```
Context available: Patch header, commit message if included

### Direct Code
Code shared via paste, file, or conversation.
Context available: Only what's provided - ask for more if needed

**Adjusting for limited context:**
- More questions may be needed to understand intent
- Focus on "what is this trying to do?" before "is this done well?"
- Treat commit messages as documentation
- Review commit-by-commit when commits are atomic

## Avoiding Review Anti-Patterns

### Don't Be a Blocker for Low-Value Reasons
- Style preferences not in team conventions
- "I would have done it differently" without clear benefit
- Theoretical concerns unlikely to materialize
- Demanding perfection in non-critical code

### Don't Rubber-Stamp High-Risk Changes
- Large changes deserve proportional attention
- "I trust the author" isn't a review
- Time pressure doesn't reduce risk
- When in doubt, ask questions

### Don't Review What Automation Should Catch
- Linting issues
- Formatting problems
- Type errors
- Test failures

Focus human review time on judgment calls machines can't make.
