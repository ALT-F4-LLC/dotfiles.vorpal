---
project: "main"
maturity: "draft"
last_updated: "2026-06-13"
updated_by: "@staff-engineer"
scope: "Describes observed code-quality conventions for Rust generators, shell helpers, and repository documentation in this Vorpal dotfiles repository."
owner: "@staff-engineer"
dependencies: []
---

# Code Quality Specification

## Purpose

This spec records the code-quality conventions that are visible in the repository today. It focuses on style, idiom, generated-file practices, documentation conventions, and quality gates. Architecture boundaries and test strategy are intentionally left to their dedicated specs.

## Current Tooling

- The Rust package is edition 2021 and exposes a `vorpal` binary from `src/vorpal.rs`.
- No repository-local formatter or linter config was found for Rust, Markdown, TOML, YAML, JSON, or shell. There is no observed `rustfmt.toml`, `clippy.toml`, `.editorconfig`, markdownlint config, Prettier config, Taplo config, Justfile, or Makefile.
- `cargo fmt --check` is a valid local quality command and passed on 2026-06-13.
- CI does not currently run `cargo fmt`, `cargo clippy`, or `cargo test`. The observed workflow runs `bash tests/teammate-idle-hook.test.sh`, `vorpal build 'dev'`, and `vorpal build '${{ matrix.artifact }}'`.
- `cargo test --no-run` completed successfully on 2026-06-13, confirming the current Rust tests compile without executing them.

## Rust Style

- Rust code follows standard `rustfmt` layout. Keep new Rust code formatted with `cargo fmt`.
- Public generator types use `PascalCase` names (`UserEnvironment`, `FileCreate`, `ClaudeCode`, `Codex`, `Opencode`, `GhosttyConfig`, `K9sSkin`).
- Builder methods use fluent `with_*` naming, take `mut self`, return `Self`, and are commonly chained at call sites.
- Constructors are named `new` and usually accept `&str` names plus `Vec<ArtifactSystem>` where the type produces a Vorpal artifact.
- Fallible build methods return `anyhow::Result<String>` and use `?` for propagation through Vorpal SDK calls and serialization.
- Configuration structs that serialize to JSON or TOML derive `Debug`, `Clone`, `Serialize`, and `Deserialize` where appropriate. Optional fields generally use `Option<T>` with `#[serde(skip_serializing_if = "Option::is_none")]`; maps use `BTreeMap` for deterministic output ordering.
- Config enum serialization is explicit. Existing examples use `#[serde(rename_all = "camelCase")]`, `snake_case`, `lowercase`, `UPPERCASE`, `untagged`, and targeted `#[serde(rename = "...")]` attributes to match downstream configuration schemas.
- Large generated configuration surfaces tolerate many `#[allow(dead_code)]` builder methods. This is an observed pattern for schema coverage, not a general license to suppress warnings in unrelated code.
- Comments are used sparingly for sectioning large generator files and to explain generated shell/config blocks. Avoid restating obvious assignments.

## Error Handling

- Production Rust paths prefer `anyhow::Result` and `?`.
- Serialization failures in build methods are wrapped with contextual `anyhow::anyhow!` messages, as seen in the Codex and Opencode config builders.
- `expect` appears in production code only for values that should be statically TOML-serializable in the current source-defined configuration. New `expect` calls should be limited to the same kind of impossible-state assertion and should include specific messages.
- Tests use `expect` freely for fixture readability and assertion setup.
- Shell helpers differ by behavior: `statusline.sh` uses `set -euo pipefail`; `teammate-idle-hook.sh` uses `set -uo pipefail` and intentionally fails open by emitting `{}` when input parsing or `jq` availability fails.

## Generated Files and Config Builders

- The repository source of truth is Rust plus checked-in agent, skill, and script files. Generated runtime files are created as Vorpal artifacts and symlinked into user configuration locations.
- Use structured serialization for structured outputs. Observed builders use `serde_json::to_string_pretty` for JSON and `toml::to_string_pretty` for TOML.
- Use `indoc::formatdoc!` for multi-line generated text and shell snippets where indentation matters.
- Use `FileCreate` for generated file content, `FileDownload` for remote source snapshots, and `FileSource` for copying checked-in directories into Vorpal artifacts.
- Use `include_str!` for checked-in shell scripts that are emitted as generated files. Mark emitted scripts executable through `.with_executable(true)`.
- Keep checked-in agent and skill directories as the source for deployed agent/skill payloads. Current code snapshots `agents/claude-code`, `agents/codex`, `skills/claude-code`, and `skills/codex` into Vorpal artifacts before symlinking them.

## Documentation Conventions

- Technical design documents under `docs/tdd/` start with YAML frontmatter containing project metadata, maturity, `last_updated`, `updated_by`, scope, owner, dependencies, and status.
- Skill files start with YAML frontmatter containing at least `name` and `description`, followed by an H1 matching the skill name in title case.
- Codex skill files are validated by tests to start with YAML frontmatter, include a matching `name:`, include `description:`, and omit Claude-only skill frontmatter fields.
- Agent changelog files under `docs/changelog/agents/` and skill changelog files under `docs/changelog/skills/` use an H1 of `Changelog: <name>` and dated sections with `Summary`, `Changes`, `Dimensions Evaluated`, and `Rename`.
- Existing docs use concise Markdown sections and evidence-oriented prose. Continue to state observed facts separately from assumptions or gaps.

## Naming and Organization

- Rust modules under `src/user/` are organized by generated target or tool (`bat`, `claude_code`, `codex`, `ghostty`, `k9s`, `opencode`).
- User-facing artifact names are constructed from the environment name plus a target suffix, for example `user-codex`, `user-opencode`, and `user-k9s-skin`.
- Builder option names mirror the downstream config field whenever practical. For generated schemas, prefer preserving downstream terminology over inventing repo-specific aliases.
- Agent roles and skill names use lowercase hyphenated filenames and directory names (`staff-engineer`, `code-review-verdict`, `init-specs`).

## Review Expectations

- Before approving a code-quality-sensitive change, verify the relevant generator output path, serialization format, and checked-in source path rather than relying on README descriptions alone.
- For Rust changes, run at least `cargo fmt --check`; run compile or test commands appropriate to the changed surface.
- For generated payload changes, inspect both the source file and the Rust path that snapshots or emits it.
- For skill and agent changes, preserve frontmatter shape and avoid carrying runtime terms or platform-specific fields into the wrong agent ecosystem.

## Gaps & Risks

- There is no explicit CI gate for Rust formatting, Clippy, or Rust tests. Formatting passed locally, but CI will not currently enforce it.
- There is no repository-local formatting policy file, editor config, or Markdown/TOML/YAML lint configuration. Style is therefore enforced by convention and review.
- Large builder modules contain broad schema surfaces and many dead-code builder methods. This is useful for config coverage but can hide unused or drifting fields without focused review.
- Some generated text uses shell heredocs and string templates. These require careful review for quoting and interpolation behavior when adding dynamic content.
- Documentation conventions are observable but not centralized outside this bootstrap spec set. Future docs may drift unless specs or review checklists become the review baseline.
- CI builds Vorpal artifacts, but the quality workflow does not currently capture generated config diffs for review. Reviewers must inspect source builders and payload files directly.

## Evidence Sources

- `Cargo.toml`
- `Vorpal.toml`
- `.github/workflows/vorpal.yaml`
- `README.md`
- `src/lib.rs`
- `src/vorpal.rs`
- `src/file.rs`
- `src/user.rs`
- `src/user/bat.rs`
- `src/user/claude_code.rs`
- `src/user/codex.rs`
- `src/user/ghostty.rs`
- `src/user/k9s.rs`
- `src/user/opencode.rs`
- `src/user/statusline.sh`
- `src/user/teammate-idle-hook.sh`
- `tests/codex_payload.rs`
- `tests/teammate-idle-hook.test.sh`
- `skills/codex/init-specs/SKILL.md`
- `skills/codex/tdd/SKILL.md`
- `agents/codex/staff-engineer.toml`
- `agents/claude-code/staff-engineer.md`
- `docs/tdd/team-lead-readonly-orchestration.md`
- `docs/changelog/skills/init-specs.md`
- `docs/changelog/agents/staff-engineer.md`

## Verification

- Confirmed `docs/spec/` had no existing target files before writing this spec.
- Confirmed only unrelated pre-existing worktree modifications were present before writing: `agents/codex/team-lead.toml`, `skills/codex/init-specs/SKILL.md`, and `tests/codex_payload.rs`.
- Ran `cargo fmt --check` successfully on 2026-06-13.
- Ran `cargo test --no-run` successfully on 2026-06-13.
