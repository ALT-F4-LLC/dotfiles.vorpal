---
project: "dotfiles.vorpal"
maturity: "proof-of-concept"
last_updated: "2026-06-09"
updated_by: "@staff-engineer"
scope: "Test strategy, coverage, and CI verification for the Vorpal-based dotfiles config program"
owner: "@staff-engineer"
dependencies: []
---

# Testing

This document describes the testing posture of `dotfiles.vorpal` **as it exists today**, not an aspirational target. The honest summary: the repository has one automated test, it covers one shell script, and the ~5,300 lines of Rust that define the dotfiles environment have **no automated tests at all**. Build success is the only signal that the Rust code is correct.

## Test Inventory

The entire automated test surface is one file.

| Test | Type | Target | Runner | Cases |
|---|---|---|---|---|
| `tests/teammate-idle-hook.test.sh` | Shell integration | `src/user/teammate-idle-hook.sh` | `bash` + `jq` | 5 |

There is no `cargo test` surface. A search of `src/` for `#[test]`, `#[tokio::test]`, `#[cfg(test)]`, and `mod tests` returns nothing. There is no `tests/*.rs` integration-test crate, no `.cargo/` config, no coverage tooling (`tarpaulin`, `llvm-cov`, `grcov`), no test fixtures directory, and no mocking framework.

### What the one test covers

`tests/teammate-idle-hook.test.sh` is a self-contained, dependency-light bash harness (it requires only `bash` and `jq`). It exercises the `TeammateIdle` hook script through five cases:

- `case_agent_type_present` — valid JSON with an `agent_type`, asserts exit 0, valid JSON output, and that the agent type appears in the emitted `systemMessage`.
- `case_no_agent_type` — empty JSON object, asserts a generic reminder is still emitted.
- `case_malformed_stdin` — non-JSON input, asserts fail-open behavior (exit 0, empty `{}`, no `systemMessage`).
- `case_empty_stdin` — empty input, asserts the generic reminder path.
- `case_injection_safety` — feeds a `$(touch <sentinel>)` payload in the `agent_type` field and asserts the payload is JSON-escaped into the message and **never executed** (the sentinel file must not appear).

This is a genuinely good test for what it targets: it covers the happy path, two empty/degenerate inputs, malformed input, and a security-relevant injection case. The harness reports a `N passed, M failed` tally and exits non-zero on any failure, which is correct for CI gating.

### What is untested

Everything that is not the idle hook. Specifically:

- **All Rust artifact-definition code** (`src/lib.rs`, `src/vorpal.rs`, `src/file.rs`, `src/user.rs`, and `src/user/*.rs` — bat, claude_code, ghostty, k9s, opencode). This includes `FileCreate`/`FileDownload`/`FileSource` builders, the `UserEnvironment` assembly, and pure functions like `get_output_path`. None have unit tests.
- **The two other shipped shell scripts**: `src/user/statusline.sh` and the build-embedded copy of the hook (the hook is also `include_str!`-embedded into the Rust build and copied to `~/.claude/teammate-idle-hook.sh` at install time — only the source-tree copy is tested).
- **The generated config payloads** (Ghostty, k9s skin, opencode permissions, Claude Code settings) — there is no assertion that the strings these builders emit are valid for their consuming tools.
- **The end-to-end Vorpal build/install** — there is no test that the produced artifacts install correctly or that symlinks resolve.

## Test Pyramid

Calling this a "pyramid" overstates it. The breakdown by automated test count:

| Layer | Count | Proportion | Notes |
|---|---|---|---|
| Unit | 0 | 0% | No Rust unit tests; pure functions like `get_output_path` are untested |
| Integration | 1 | 100% | The shell hook test invokes the real script via a subprocess |
| End-to-end | 0 | 0% | The `vorpal build` jobs validate compilation, not installed behavior |

The single test is best classified as **integration** (it runs the real script as a subprocess and asserts on its observable output and side effects), not unit. So the practical shape is not a pyramid but a single point: one integration test, zero everything else.

## CI Verification

CI is defined in `.github/workflows/vorpal.yaml` and runs on `pull_request` and on `push` to `main`. Three jobs:

```mermaid
flowchart TD
    PR["pull_request / push to main"] --> TH["test-hooks (ubuntu-latest)"]
    PR --> BD["build-dev (macos-latest)"]
    TH -->|"bash tests/teammate-idle-hook.test.sh"| THR{"pass?"}
    BD -->|"vorpal build 'dev'"| BDR{"compiles?"}
    BD --> UP["upload Vorpal.lock artifact"]
    BD --> B["build (macos-latest, matrix: user)"]
    B -->|"vorpal build 'user'"| BR{"compiles?"}
    THR -->|no| FAIL["CI fails"]
    BDR -->|no| FAIL
    BR -->|no| FAIL
    THR -->|yes| OK["CI passes"]
    BDR -->|yes| OK
    BR -->|yes| OK
```

- **`test-hooks`** (ubuntu-latest) — the only job that runs an actual test. Executes `bash tests/teammate-idle-hook.test.sh`. This is the entire automated-test gate.
- **`build-dev`** (macos-latest) — runs `vorpal build 'dev'` and uploads the resulting `Vorpal.lock`. This validates that the dev-environment artifact graph compiles and resolves, which transitively compiles the Rust program. It does not run any test.
- **`build`** (macos-latest, depends on `build-dev`, matrix over the `user` artifact) — runs `vorpal build 'user'`, validating the user-environment artifact builds. Also no tests.

The build jobs are a meaningful safety net for the Rust code in one narrow sense: a non-compiling change or an unresolvable artifact reference fails CI. But "it compiles" is a weak correctness signal for code whose output is shell scripts and config strings interpolated via `formatdoc!` — a builder can compile and emit a syntactically broken config.

## Test Conventions & Tooling

The conventions that exist are entirely within the one shell test, and they are sound enough to be worth codifying for any future shell tests:

- `set -uo pipefail` at the top (note: not `-e`, deliberately, so the harness can capture non-zero exits from the hook and assert on them).
- Named `assert_*` helpers (`assert_exit_zero`, `assert_valid_json`, `assert_system_message_contains`, `assert_empty_object`, etc.) with a `PASS`/`FAIL` counter and a final tally.
- Preconditions checked up front (`jq` present, hook file exists) with a distinct fatal exit code (`2`) separate from test-failure exit (`1`).
- `mktemp -d` scratch directories for side-effect assertions (the injection sentinel), cleaned up afterward.

For Rust there are **no** conventions yet because there is no Rust test code. Should Rust tests be introduced, the natural fit is `#[cfg(test)] mod tests` inline modules for the pure functions (`get_output_path`, the `chmod_mode` logic in `FileCreate::build`) and snapshot-style assertions (e.g., `insta`) for the `formatdoc!`-generated config payloads, since those are the highest-value, lowest-cost targets.

## Gaps & Risks

- **No Rust test coverage (highest risk).** ~5,300 lines of Rust define the entire dotfiles environment with zero automated tests. The `formatdoc!` string interpolation in `src/file.rs` and the config builders in `src/user/*.rs` are exactly the kind of code where a typo produces a silently-broken config that still compiles and still builds. CI cannot catch this.
- **Security-relevant code is largely untested.** Only the idle hook's injection safety is tested. The `FileCreate::build` path writes attacker-influenceable-in-principle content into shell heredocs (`cat << 'EOF'`), and `statusline.sh` is shipped untested. The single injection test is good but isolated; there is no systematic input-safety coverage of the config-generation paths. (Coordinate with `security.md`, the goal-bearing sibling spec, on whether these paths warrant a threat-model entry.)
- **The tested hook and the shipped hook can diverge.** The test targets the source-tree `src/user/teammate-idle-hook.sh`, but the build embeds it via `include_str!` and installs it to `~/.claude/`. The test validates the source, not the installed artifact, and nothing asserts the install/symlink step succeeds.
- **"Build passes" masquerades as "tested."** Two of three CI jobs only confirm compilation. A reader skimming the green checkmarks could reasonably but wrongly conclude the Rust code is verified. The distinction (compiles vs. behaves correctly) should be explicit to anyone relying on CI.
- **No coverage measurement.** With no coverage tooling, there is no objective signal of how much of either the shell or (nonexistent) Rust test surface is exercised — coverage is effectively unknowable beyond manual inspection.
- **Single-tool dependency in the test.** The shell test hard-requires `jq` and fatally exits if it is absent. CI provides `jq` on ubuntu-latest, so this is low-risk today, but it is an undeclared environmental dependency.
