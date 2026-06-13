---
project: "main"
maturity: "draft"
last_updated: "2026-06-13"
updated_by: "@staff-engineer"
scope: "Describes the observed review strategy for source, generated configuration, agent, skill, CI, dependency, and specification changes in this repository."
owner: "@staff-engineer"
dependencies: []
---

# Review Strategy Specification

## Purpose

This repository is a Rust/Vorpal dotfiles project that publishes local developer tooling, generated AI-tool configuration, agent definitions, skill definitions, shell hooks, and host symlinks. Review is therefore not limited to Rust correctness: a change can alter the operator's local environment, AI-tool permissions, credential exposure, CI registry access, or the behavior of deployed development agents.

This spec records the review strategy visible in the repository today. It is descriptive, not a branch-protection policy.

## Review Entry Points

Observed review-capable surfaces are role and skill based:

- `agents/codex/staff-engineer.toml` defines the staff-engineer as owner of architecture, TDDs, ADRs, and general code review. Its review workflow requires exact artifact scoping, reading relevant specs and designs, using `$code-review-verdict`, prioritizing correctness and maintainability risks, and leading with file/line findings.
- `agents/codex/security-engineer.toml` defines the security-engineer as owner of security review for trust boundaries, auth, secrets, crypto, sandboxing, permissions, supply chain, and privileged input surfaces. Its review workflow requires data-flow inspection, secrets and permission review, dependency risk review, and structured findings by exploitability and impact.
- `agents/codex/sdet.toml` defines the SDET as owner of acceptance-criteria verification, test evidence, and defect triage. Its workflow requires criteria-derived commands and evidence over assertion.
- `agents/codex/team-lead.toml` routes work across staff-engineer, security-engineer, project-manager, ux-designer, senior-engineer, and SDET roles. It requires dispatch briefs to include scope, write permissions, required evidence, and final-report expectations.
- `skills/codex/code-review-verdict/SKILL.md` is the Codex structured review output authority for PRs, branches, staged changes, uncommitted diffs, and explicit file sets.
- `skills/codex/review-and-comment/SKILL.md` defines a GitHub PR inline-comment flow, but requires operator approval before posting any comment.
- `skills/codex/verify-ac/SKILL.md` defines evidence-based acceptance-criteria verification for Docket issues, PRs, branches, staged changes, uncommitted diffs, or file sets.

The Claude-side review skill is more detailed and is also deployed by this repo. It states that team-lead-orchestrated code review defaults to one persistent `advisor` reviewer, opts up for TDD secondary review, security-sensitive surfaces, diffs of at least 500 LOC, or explicit operator request, and uses up to four reviewers for security-sensitive review. The current Codex role files have the same role separation but do not yet mirror that detailed panel-sizing rule.

## High-Risk Review Surfaces

Treat these paths as review-sensitive because repository evidence shows they affect generated runtime policy, host installation, supply chain, or team behavior:

- `src/user.rs`: central composition point for third-party tool artifacts, generated Claude Code/Codex/OpenCode configuration, telemetry endpoints, sandbox and permission settings, environment variables, copied agent/skill trees, executable hooks, and host symlinks.
- `src/user/claude_code.rs`, `src/user/codex.rs`, and `src/user/opencode.rs`: structured serializers for generated AI-tool policy. Review both builder calls and emitted JSON/TOML shape when these change.
- `src/file.rs`: file, download, and source-directory artifact helpers. Review shell quoting, executable bit behavior, copied-path semantics, and remote source handling.
- `src/vorpal.rs`, `src/lib.rs`, `Cargo.toml`, `Cargo.lock`, `Vorpal.toml`, and `Vorpal.lock`: build entry point, supported systems, dependency graph, source includes, and locked remote artifact sources.
- `agents/claude-code/*.md` and `agents/codex/*.toml`: deployed role definitions. They govern review authority, orchestration, security posture, implementation behavior, and verification behavior.
- `skills/claude-code/*/SKILL.md` and `skills/codex/*/SKILL.md`: deployed workflow instructions. Review frontmatter, scope, write authority, output paths, and cross-runtime terminology.
- `.github/workflows/vorpal.yaml`: CI triggers, runners, S3-backed Vorpal registry setup, AWS secret usage, artifact upload, and build commands.
- `renovate.json`: automated dependency-update behavior, including Cargo automerge policy and the custom manager for the Tokyo Night theme URL in `src/user.rs`.
- `src/user/statusline.sh`, `src/user/teammate-idle-hook.sh`, and `tests/teammate-idle-hook.test.sh`: local shell behavior used by generated AI-tool hooks and CI.
- `docs/spec/`, `docs/tdd/`, `docs/tdd/adr/`, and `docs/ux/`: review baselines and design intent. Reviewers are expected to read relevant docs before approving changes that may drift from them.

## Frequent-Change Signals

`git log --name-only --since=2026-03-01` shows the highest recent churn in agent and skill instructions, with `src/user.rs` also recurring frequently. A path-constrained history pass over current directories showed `src/user.rs` as the most frequently changed source file, followed by docs/spec bootstrap files, TDDs, workflow/config files, agent files, skill files, tests, and individual generator modules.

Review strategy should therefore assume two common failure modes:

- instruction drift across parallel agent and skill ecosystems;
- generated-config drift where `src/user.rs` changes deployment behavior without a generated-output diff in review.

## Reviewer Routing

Use staff-engineer review for:

- Rust generator changes, build orchestration, module boundaries, helper APIs, generated-file practices, and non-security architecture changes;
- agent and skill instruction changes that affect role boundaries, review authority, docs ownership, or orchestration;
- docs/spec, TDD, ADR, and changelog changes where spec drift or architectural precedent matters.

Use security-engineer review for:

- sandbox, permission, command allow/deny, credential, telemetry, hook, shell execution, environment inheritance, network egress, MCP/OAuth, local file access, or generated symlink changes;
- CI secret usage, S3 registry access, mutable GitHub Action refs, dependency/source changes, Renovate rules, and supply-chain behavior;
- agent/skill changes that alter security authority, threat-modeling expectations, or handling of privileged inputs.

Use SDET verification for:

- acceptance-criteria verification, test additions, test adequacy, CI gaps, regression checks, shell hook behavior, and generated-payload schema checks;
- verifying claimed fixes after staff or security review findings.

Use UX/design review only when a change affects a user-facing workflow or developer-facing interaction design. The current repository has no observed `docs/ux/` directory.

## CI And Local Gates

Observed GitHub Actions gates are:

- `test-hooks` on `ubuntu-latest`, running `bash tests/teammate-idle-hook.test.sh`;
- `build-dev` on `macos-latest`, using `ALT-F4-LLC/setup-vorpal-action@main` with S3 registry credentials, running `vorpal build 'dev'`, and uploading `Vorpal.lock`;
- `build` on `macos-latest`, depending on `build-dev`, using the same Vorpal setup, and running `vorpal build 'user'`.

Observed gaps in CI gates:

- CI does not explicitly run `cargo test`;
- CI does not explicitly run `cargo fmt --check` or `cargo clippy`;
- CI does not run shell linting;
- CI does not publish generated Claude Code, Codex, or OpenCode config diffs for reviewer inspection.

For local review evidence, prefer the narrowest commands that exercise the changed surface:

- Rust/config-builder changes: `cargo fmt --check` and `cargo test`.
- Hook changes: `bash tests/teammate-idle-hook.test.sh`.
- Codex agent/skill payload changes: `cargo test`, because `tests/codex_payload.rs` checks role inventory, schema shape, banned Claude runtime terms, skill frontmatter, and `src/user.rs` Codex wiring.
- Vorpal artifact, symlink, tool inventory, or lockfile changes: `vorpal build 'dev'` and/or `vorpal build 'user'` when credentials and Vorpal setup are available.
- CI workflow changes: inspect `.github/workflows/vorpal.yaml` directly and verify changed jobs are exercised by an appropriate PR or local equivalent.

## PR And Change-Review Conventions

No CODEOWNERS file, CONTRIBUTING guide, pull request template, or branch-protection declaration was observed in the repository. Review ownership is encoded in agent and skill instructions rather than repository-hosting metadata.

When reviewing a PR through `skills/codex/review-and-comment/SKILL.md`, comments are drafted one finding at a time and are posted only after explicit operator approval. The skill forbids modifying the PR branch and requires normal approval flow for network or credentialed GitHub operations.

When reviewing a local artifact through `code-review-verdict`, scope must be explicit: PR, branch, staged changes, uncommitted diff, or file paths. The review output format is findings first, with evidence, tests run or not run, and residual risk.

## Evidence Expectations

Every review verdict should separate observed fact from inference. Evidence should include:

- exact reviewed scope and diff source;
- files read and relevant line references for findings;
- related specs or TDDs consulted;
- commands run and outcomes, including tests not run with rationale;
- generated-output inspection when builder code changes generated policy;
- residual risk when CI lacks a matching automated gate.

For high-risk paths, do not approve from source intent alone. Examples:

- A permission-builder change in `src/user.rs` needs review of the generated permission behavior or serialized config shape.
- An agent/skill instruction change needs review of the deployed source path and the corresponding Rust `FileSource`/symlink path when deployment behavior is relevant.
- A dependency or source URL change needs review of `Cargo.lock`, `Vorpal.lock`, `renovate.json`, and any CI or remote-cache implications.
- A shell hook change needs execution evidence and injection/JSON-safety coverage where input is parsed.

## Gaps & Risks

- There is no repository-level CODEOWNERS, PR template, or CONTRIBUTING file to enforce reviewer assignment outside the agent workflow.
- No branch-protection or required-status-check policy is visible from repository files.
- CI does not run the Rust tests or formatting checks that the current specs identify as relevant local gates.
- CI does not produce generated config diffs, so reviewers must manually inspect source builders and, when possible, emitted JSON/TOML.
- Codex review instructions are simpler than the Claude-side review instructions; the detailed single-reviewer/default opt-up panel rule is observed in Claude assets but not fully mirrored in Codex assets.
- Agent and skill instruction changes can drift across Claude Code and Codex ecosystems because they are parallel source trees with different file formats and only partial automated schema coverage.
- `src/user.rs` concentrates tool inventory, security policy, telemetry, copied source trees, and symlink publication in one file, so unrelated-looking edits can have broad deployment effects.
- Renovate can automerge minor and patch Cargo updates for stable crates, but no repository-local policy describes when an automerged dependency change still needs human review.
- `ALT-F4-LLC/setup-vorpal-action@main` is mutable; supply-chain review depends on inspecting workflow/action behavior beyond this repository when that action changes.

## Evidence Sources

- `README.md`
- `.github/workflows/vorpal.yaml`
- `Cargo.toml`
- `Cargo.lock`
- `Vorpal.toml`
- `Vorpal.lock`
- `renovate.json`
- `.envrc`
- `.gitignore`
- `src/lib.rs`
- `src/vorpal.rs`
- `src/file.rs`
- `src/user.rs`
- `src/user/claude_code.rs`
- `src/user/codex.rs`
- `src/user/opencode.rs`
- `src/user/statusline.sh`
- `src/user/teammate-idle-hook.sh`
- `tests/codex_payload.rs`
- `tests/teammate-idle-hook.test.sh`
- `agents/codex/team-lead.toml`
- `agents/codex/staff-engineer.toml`
- `agents/codex/security-engineer.toml`
- `agents/codex/sdet.toml`
- `agents/claude-code/team-lead.md`
- `agents/claude-code/staff-engineer.md`
- `agents/claude-code/security-engineer.md`
- `skills/codex/code-review-verdict/SKILL.md`
- `skills/codex/review-and-comment/SKILL.md`
- `skills/codex/verify-ac/SKILL.md`
- `skills/claude-code/code-review-verdict/SKILL.md`
- `docs/spec/architecture.md`
- `docs/spec/security.md`
- `docs/spec/operations.md`
- `docs/spec/testing.md`
- `docs/spec/performance.md`
- `docs/spec/code-quality.md`
- `docs/tdd/team-lead-readonly-orchestration.md`

## Verification

- Confirmed `docs/spec/review-strategy.md` did not exist before writing this file.
- Confirmed existing peer specs under `docs/spec/` were skimmed for overlap.
- Confirmed no CODEOWNERS, pull request template, or CONTRIBUTING file was found by repository search.
- Confirmed the observed GitHub Actions workflow and Renovate policy from checked-in files.
- Confirmed pre-existing unrelated staged modifications were limited to `agents/codex/team-lead.toml`, `skills/codex/init-specs/SKILL.md`, and `tests/codex_payload.rs` before writing this spec.
