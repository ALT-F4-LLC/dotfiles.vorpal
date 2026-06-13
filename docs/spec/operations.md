---
project: "main"
maturity: "draft"
last_updated: "2026-06-13"
updated_by: "@staff-engineer"
scope: "Operational specification for building, verifying, publishing, observing, and recovering the Vorpal-managed dotfiles environment."
owner: "@staff-engineer"
dependencies: []
---

# Operations

## Operational Model

This repository operates as a Vorpal-backed dotfiles and AI-tool configuration project. The primary operational outputs are the `dev` artifact, which provides the Rust and Protoc development toolchain, and the `user` artifact, which installs CLI tools, generated configuration, agent definitions, skills, scripts, environment variables, and host symlinks.

The local publication mechanism is a Vorpal build, not an external service deployment. `vorpal build 'user'` builds content-addressed artifacts under `/var/lib/vorpal/store/` and updates symlinks from the operator's home directory into that store. The README documents macOS on Apple Silicon as the primary supported platform, while `src/lib.rs` defines artifact systems for Darwin and Linux on aarch64 and x86_64.

## Build & Local Environment

The expected local build sequence is:

```bash
vorpal build 'dev'
vorpal build 'user'
```

The `dev` artifact is built in `src/vorpal.rs` from `Protoc` and `RustToolchain`, and it exports Rust toolchain environment variables including `PATH`, `RUSTUP_HOME`, and `RUSTUP_TOOLCHAIN`. The repository also includes `.envrc`, whose `use_vorpal` hook sources the activation script from `vorpal build --path "dev"`.

The `user` artifact is built from `UserEnvironment::new("user", SYSTEMS.to_vec())`. It includes CLI artifacts, generated configuration files, downloaded theme content, copied agent and skill directories, executable shell scripts, user environment variables, and host symlinks.

## CI

GitHub Actions workflow `.github/workflows/vorpal.yaml` runs on pull requests and pushes to `main`.

CI jobs observed:

- `test-hooks`: runs on `ubuntu-latest` and executes `bash tests/teammate-idle-hook.test.sh`.
- `build-dev`: runs on `macos-latest`, installs Vorpal via `ALT-F4-LLC/setup-vorpal-action@main`, configures an S3 registry backend, runs `vorpal build 'dev'`, and uploads `Vorpal.lock` as a workflow artifact.
- `build`: depends on `build-dev`, runs on `macos-latest`, installs Vorpal with the same S3 registry backend, and builds the matrix artifact `user`.

The workflow requires `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` from GitHub Actions secrets or variables for the S3-backed Vorpal registry bucket `altf4llc-vorpal-registry`.

## Generated Config Publication

Generated and copied configuration is published through the `user` artifact's symlink list in `src/user.rs`.

Observed symlink targets include:

- `~/.vorpal/bin/vorpal`
- `~/.config/bat/config`
- `~/.config/bat/themes/tokyonight.tmTheme`
- `~/.claude/agents`
- `~/.claude/settings.json`
- `~/.claude/skills`
- `~/.claude/statusline.sh`
- `~/.claude/teammate-idle-hook.sh`
- `~/.codex/agents`
- `~/.codex/config.toml`
- `~/.agents/skills`
- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/Library/Application Support/k9s/skins/tokyo_night.yaml`
- `~/.config/nvim/after/ftplugin/markdown.vim`
- `~/.config/opencode/opencode.json`

Agent and skill publication uses `FileSource` artifacts that copy repo directories into Vorpal output artifacts. Claude Code agents come from `agents/claude-code`, Codex agents from `agents/codex`, Claude Code skills from `skills/claude-code`, and Codex skills from `skills/codex`.

## Environment Management

Local development is centered on the Vorpal-generated `dev` environment. `.envrc` activates that environment by sourcing the `bin/activate` script from the built `dev` artifact.

The `user` artifact exports:

- `EDITOR=nvim`
- `GOPATH=$HOME/Development/language/go`
- A `PATH` prefix for VMware Fusion, Go binaries, OpenCode, Vorpal, and local user binaries

Codex configuration additionally excludes cloud-provider credential environment variables from shell inheritance patterns for `AWS_*`, `AZURE_*`, and `GCP_*`, while inheriting the rest of the shell environment.

## Observability

Observed observability mechanisms are focused on AI-tool runtime visibility rather than infrastructure service monitoring.

Claude Code configuration sets OTLP logs and metrics environment variables pointing at `loki.bulbasaur.altf4.domains` and `mimir.bulbasaur.altf4.domains`, enables telemetry, and configures export intervals. Codex configuration includes OTLP log and metric exporters to the same Loki and Mimir endpoints with environment `"dev"` and `log_user_prompt` disabled.

The generated Claude status line script reads session JSON from stdin and displays model, agent, project directory, git branch and change counts, context usage, cost, duration, and line-change totals. It caches git status data in `/tmp` for five seconds.

The TeammateIdle hook emits a JSON `systemMessage` reminder for ephemeral teammates and fails open to `{}` for malformed input or missing dependencies. CI includes a shell test for this hook's JSON validity, empty-input behavior, malformed-input behavior, and command-injection safety.

## Rollback & Recovery

No repository-wide rollback runbook was observed.

The current recovery model appears to rely on Git and repeatable Vorpal rebuilds:

- Configuration source changes can be reverted in Git.
- A subsequent `vorpal build 'user'` republishes generated configuration through the symlinked Vorpal store paths.
- `Vorpal.lock` records source URLs, platforms, and digests for downloaded artifacts and is uploaded by CI after the `dev` build.

One existing TDD documents the same pattern for an agent prose change: revert the PR and rebuild so the symlinked directory picks up the reverted content. That is evidence of an established local pattern, but it is not a general operations runbook.

## Automation & Dependency Updates

Renovate is configured for Cargo dependency updates. It groups `serde` and `serde_json`, automerges minor and patch updates for stable Cargo crates, requires manual review for major Cargo updates, and has a regex custom manager for the Tokyo Night bat theme version embedded in `src/user.rs`.

The CI workflow does not currently show Renovate-specific gates beyond the normal pull request workflow.

## Gaps & Risks

- No general rollback or incident recovery runbook is present for failed `vorpal build`, bad symlink publication, S3 registry outage, damaged local store state, or broken generated AI-tool configuration.
- CI builds `dev` and `user`, but no local smoke command or post-build validation checklist is documented for verifying that expected symlinks point to valid store outputs after publication.
- The README documents `aarch64-darwin` as the primary supported platform, while code declares four artifact systems. Operational support expectations for Linux and x86_64 targets are not documented.
- The workflow depends on GitHub Actions secrets and variables for the S3-backed registry, but credential rotation, least-privilege policy, and outage fallback are not documented in this repo.
- Observability endpoints are configured for Claude Code and Codex, but there are no observed alert rules, dashboards, retention policy, or operator runbooks for interpreting logs and metrics.
- Generated configuration publication overwrites or replaces several user-home configuration paths through symlinks. The repo does not document backup, first-run migration, or manual recovery steps for pre-existing files at those targets.
- `Vorpal.lock` is uploaded from CI after `build-dev`, but the repo does not document when operators should update, review, or restore the lockfile.
- The `user` artifact symlink for `~/.vorpal/bin/vorpal` points at a local repository path under `ALT-F4-LLC/vorpal.git/main/target/debug/vorpal`; portability and bootstrap expectations for hosts without that path are not documented.

## Evidence Sources

- `README.md`: project purpose, artifact model, symlink targets, prerequisites, build commands, CI summary, S3 registry note, and dependency-update summary.
- `.github/workflows/vorpal.yaml`: CI triggers, jobs, runners, Vorpal setup, S3 registry configuration, AWS secret and variable usage, artifact upload, and build commands.
- `Vorpal.toml`: Rust source includes for Vorpal builds.
- `Vorpal.lock`: locked external source URLs, digests, and platforms.
- `.envrc`: local `dev` environment activation through `vorpal build --path "dev"`.
- `src/vorpal.rs`: construction of `dev` and `user` artifacts and development environment variables.
- `src/user.rs`: user artifact dependencies, generated configuration, telemetry settings, environment variables, copied agent and skill directories, and symlink publication.
- `src/file.rs`: helper artifacts for created files, downloaded sources, and copied source directories.
- `src/user/statusline.sh`: runtime status-line observability behavior.
- `src/user/teammate-idle-hook.sh` and `tests/teammate-idle-hook.test.sh`: hook behavior and CI-covered validation.
- `renovate.json`: dependency-update automation policy.
- `docs/tdd/team-lead-readonly-orchestration.md`: observed rollback wording for symlinked agent publication.
