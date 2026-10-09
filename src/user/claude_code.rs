use crate::file::{FileCreate, FileSource};
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

mod settings;

// Git expands only a leading `~/`; activation expands `${HOME}`. The install
// spelling derives from this one through `home_install`, so the symlink and
// the git config always name the same file.
const GIT_ALLOWED_SIGNERS_CONFIG_PATH: &str = "~/.config/git/allowed_signers";
// The agent signing key is a plain file pair on purpose: it lives outside
// 1Password so an executor's commit never waits on the operator approving a
// signature. ssh-keygen resolves the .pub through SSH_AUTH_SOCK first and,
// finding no agent, falls back to the private key beside it, so both halves
// must be readable through the ~/.ssh read-deny.
const GIT_AGENT_SIGNING_KEY_PATH: &str = "~/.ssh/agent-signing";
const GIT_AGENT_SIGNING_KEY_PUBLIC_PATH: &str = "~/.ssh/agent-signing.pub";
const OTEL_LOGS_ENDPOINT_LOKI: &str =
    "https://alloy-forwarder.bulbasaur.eks.altf4.internal/v1/logs";
const OTEL_METRICS_ENDPOINT_MIMIR: &str =
    "https://alloy-forwarder.bulbasaur.eks.altf4.internal/v1/metrics";
const OTEL_OTLP_PROTOCOL: &str = "http/protobuf";
/// Placeholder in the auto-mode prose for the comma-joined scratch roots.
/// The roots carry the invoking user's uid, so the rows that name them are
/// expanded through `expand_scratch_roots` when the config is evaluated
/// rather than spelled out here; a test pins that no token reaches the
/// emitted settings.
const SCRATCH_ROOTS_TOKEN: &str = "{scratch_roots}";
const SENSITIVE_PATHS_DENY_READ_ONLY: &[&str] = &["~/.aws/**"];

const SENSITIVE_PATHS: &[&str] = &[
    "~/.claude.json",
    "~/.doppler/**",
    "~/.gemini/**",
    "~/.gnupg/**",
    "~/.kube/**",
    "~/.netrc",
    "~/.ssh/**",
    "~/.talos/**",
    "~/Desktop/**",
    "~/Downloads/**",
];

const SENSITIVE_PATHS_DENY_EDIT_ONLY: &[&str] = &["/Applications/**", "/Library/**", "/System/**"];

/// docket's trust allowlist and the lock its writers hold. Only the operator
/// adds or removes trust, outside the sandbox (`! docket trust add ...`), so
/// no sandboxed command and no edit tool may write either file, however the
/// command is spelled. Gates only read the allowlist, which stays allowed.
const TRUST_STORE_PATHS: &[&str] = &[
    "~/.config/docket/trust.toml",
    "~/.config/docket/trust.toml.lock",
];

const AUTO_MODE_ENVIRONMENT_CONTEXT: &[&str] = &[
    "### Org-wide",
    "**Organization**: ALT-F4 LLC (solo operator)",
    "**Cloud provider(s)**: none — self-hosted Talos homelab (the bulbasaur cluster)",
    "**Repository visibility**: ALT-F4-LLC repositories are mostly public — treat any push as publishing unless the working repo is confirmed private",
    "**Internal sharing / snippet hosting**: None configured — treat public paste/gist services as outside the trust boundary",
    "**Secrets management**: Doppler and 1Password are the secret stores — secrets live there and are injected via `doppler run` / `op run` / `op read`; never copy a secret out of them into repos, files, or external destinations",
    "**CI/CD deploy targets**: None configured",
    "**Network posture**: None configured",
    "**Source control**: All repositories under the github.com/ALT-F4-LLC organization — many are public, so only a repo's own work should be pushed to it and public visibility never clears sensitive data into it",
    "**Trusted internal domains**: *.altf4.domains (the bulbasaur homelab services) and vorpal.build",
    "**Trusted cloud buckets**: None configured",
    "**Key internal services**: bulbasaur cluster services under *.altf4.domains — mimir, loki, coder, argocd, knative, agentgateway — plus registry.altf4.domains",
    "**Internal package registry**: registry.altf4.domains",
    "**Sensitive data locations & audiences**: any file or store holding personal data, confidential business data, credentials, regulated data, or similarly sensitive material; preserve exact handles when known and share only with audiences cleared at the [named+specifics] bar; treat `.env` files, `.envrc`, and anything a repo's secret-scan tooling flags as sensitive-data locations",
    "**Data retention / declassification**: None configured",
    "**Sensitive remote targets**: the bulbasaur Kubernetes cluster (Talos/flux-managed homelab) is production — deploys, remote shells, and destructive operations against it require the operator's explicit ask; also any namespace, host, or container whose name carries `prod` or `production` as a whole word or name segment (hyphen/underscore/dot-delimited)",
    "**Protected deployment namespaces / environments**: None configured — fall back to the Sensitive remote targets heuristic",
    "**Protected IaC scopes**: IAM, RBAC, networking, quota, and node-pool resources; anything whose name or tag carries `prod` or `production` as a whole word or name segment",
    "### User-specific",
    "**Primary use of Claude Code**: software development across ALT-F4-LLC projects (Vorpal build tooling, Claude Code agent configuration, homelab GitOps)",
    "**Trusted repos**: any github.com/ALT-F4-LLC repository checked out as the working directory, with its origin remote; most are public, so only a repo's own work is committed/pushed there and secrets/sensitive data are never cleared into it by visibility alone",
    "**Checkout layout**: every ALT-F4-LLC repository lives as a bare repo at ~/Development/repository/github.com/ALT-F4-LLC/<name>.git with one worktree per branch beneath it (e.g. <name>.git/main, <name>.git/feature/<branch>) plus harness worktrees under <name>.git/<branch>/.claude/worktrees/*; all of these are the same trusted checkout",
    "**Scratch roots**: {scratch_roots}, and $TMPDIR are per-session throwaway workspaces — docket steps mirror or copy a trusted checkout into STEP-<n>.d/target, STEP-<n>-target, or STEP-<n>-probe* under them and run builds, tests, and mutations there; nothing under them is a repo of record",
    "**Org-specific CLIs**: docket (high-frequency usage across projects; also present in shell history with a bundled secret-scan script) — routine under ALT-F4-LLC repos",
    "**routine under ~/.claude/ prefix**: fixes and edits under `~/.claude` are governed by the working agreement there (source-only edits, install via `just activate`, never edit installed tree directly)",
];

const AUTO_MODE_ALLOW_RULES: &[&str] = &[
    "$defaults",
    "Bash(docket:*) in ALT-F4-LLC repositories — high-frequency org CLI; includes registry and run-state verbs (workflow register --all-projects/--project, run activate, dispatch backfill-usage, issue comment, step claim) and read-only SELECTs against the docket store at ~/.docket/issues.db, plus `~/.docket/bin/wave-claim`, the corpus-shipped script a wave's claim agent runs to claim one step and write its packet module; `docket trust add`/`docket trust rm` write the store that authorizes a step's own gates and stay outside this rule",
    "Bash(cargo:*) in ALT-F4-LLC repositories — build/test/fmt/check/clippy, including invocations prefixed with CARGO_HOME/CARGO_TARGET_DIR/GOCACHE-style cache overrides; writes only to build caches",
    "Local git operations in trusted repositories — add, commit, worktree, cherry-pick, stash, archive, cat-file, rev-parse, and other repo-local verbs, whether run from the checkout or via `git -C <trusted checkout>`, with commit messages passed inline, via a heredoc, or via `-F <file under the scratch root>`; `git push` publishes and stays outside this rule",
    "Bash(vorpal:*) in ALT-F4-LLC repositories — the org's own build tool, same standing as docket",
    "Read-only cluster reads against bulbasaur — kubectl get/describe/logs, flux get; mutations against the cluster stay outside this rule (production)",
    "Read-only search and inspection inside trusted checkouts and the Claude scratch roots ({scratch_roots}, $TMPDIR) — grep, rg, find, ls, cat, head, tail, sed -n, wc, diff, strings, jq — including a relative path or glob after `cd` into one of those roots; the sensitive home paths (~/.ssh, ~/.aws, ~/.gnupg, credential stores) are refused by the sandbox at the syscall level and by the sensitive-path-guard hook, and a relative path under these roots cannot reach them; interpreter code arguments and exec wrappers are shell indirection and stay outside this rule",
    "File operations confined to the Claude scratch roots ({scratch_roots}, $TMPDIR) — mkdir, cp -R, rm -rf, mv, tar/git-archive mirrors of a trusted checkout, and in-place edits (sed -i) of files under them; these are per-session throwaway workspaces the sandbox already lets every session write, so deleting or mutating them affects no repo; interpreter code arguments and exec wrappers are shell indirection and stay outside this rule",
    "Read-only inspection under ~/.claude — session transcripts and tool-results under ~/.claude/projects, the friction ledger, installed skills, workflows, and hooks — the operator's own harness state; edits there stay outside this rule (source-only, installed via `just activate`)",
    "Read-only gh reads against ALT-F4-LLC repositories — gh pr view/checks/list/diff, gh run list/view, gh issue view/list; every other gh verb, including every one on an ask rule, stays outside this rule",
    "Editing Claude Code and Docket definition source in the dotfiles.vorpal checkout — src/user/claude_code/{skills,agents,workflows,references}/**, src/user/claude_code/CLAUDE.md, and src/user/docket/config/** — is routine project work, not self-modification: it is source only and stays inert until the operator runs `just activate`; settings.rs, claude_code.rs, src/user/claude_code/hooks/**, the permission, sandbox and autoMode rules, and the installed trees (~/.claude, ~/.docket/config) stay outside this rule",
];

/// The docket verbs that write the trust store authorizing a step's own
/// gates: they ask before running, and no auto-mode allow rule may clear
/// them. The ask rules and the guard test read this table beside
/// PUBLISHING_ASK_VERBS, so a verb added here is excluded by test.
const TRUST_STORE_ASK_VERBS: &[&str] = &["docket trust add", "docket trust rm"];

/// Verbs that publish or read secrets: they ask before running, and no
/// auto-mode allow rule may clear them. Every `gh pr` verb the `pr` skill
/// invokes that publishes text or changes who can act on a PR is listed, so
/// the human sees the bytes before they are public; a skill that adds a
/// publishing `gh` verb adds a row here. `gh run view` is deliberately
/// absent: it only reads CI logs, and the `pr` skill already treats that
/// output as untrusted data rather than instructions.
const PUBLISHING_ASK_VERBS: &[&str] = &[
    "gh api",
    "gh pr close",
    "gh pr comment",
    "gh pr create",
    "gh pr edit",
    "gh pr merge",
    "gh pr ready",
    "git push",
];

/// Shell indirection: an interpreter handed code as an argument, or a wrapper
/// that runs its argument as a command the permission rules never see. A
/// `Bash(rm *)` deny stops `rm -rf build/` but not `bash -c 'rm -rf build/'`
/// (permissions reference, "What a Bash rule doesn't match"), so every such
/// form is denied outright. Deny rules match each subcommand, including one
/// nested in a subshell, a substitution, or a loop body, and are evaluated
/// before the auto-mode classifier. The `-*c` / `-*e` shapes catch combined
/// flags (`bash -lc`, `perl -pi -e`, `python3 -uc`) at the cost of a rare
/// false positive on an unrelated `-c`/`-e` flag after the program name.
/// Wrappers the harness itself strips (`timeout`, `nice`, `nohup`, bare
/// `xargs`) need no row: the rules already see the inner command.
/// AUTO_MODE_HARD_DENY_RULES restates the same rule as prose for the
/// spellings a text pattern cannot enumerate.
const SHELL_INDIRECTION_DENY_PATTERNS: &[&str] = &[
    "Bash(. *)",
    "Bash(bash -*c *)",
    "Bash(dash -*c *)",
    "Bash(env *)",
    "Bash(eval *)",
    "Bash(find * -delete*)",
    "Bash(find * -exec*)",
    "Bash(find * -ok*)",
    "Bash(flock *)",
    "Bash(node -*e *)",
    "Bash(node -*p *)",
    "Bash(node --eval *)",
    "Bash(node --print *)",
    "Bash(osascript -*e *)",
    "Bash(perl -*e *)",
    "Bash(python* -*c *)",
    "Bash(ruby -*e *)",
    "Bash(script *)",
    "Bash(setsid *)",
    "Bash(sh -*c *)",
    "Bash(source *)",
    "Bash(sudo *)",
    "Bash(watch *)",
    "Bash(xargs -*)",
    "Bash(zsh -*c *)",
];

/// Classifier-side restatement of SHELL_INDIRECTION_DENY_PATTERNS. The deny
/// rules run first and stop the enumerable text forms; this prose reaches the
/// spellings they cannot, such as code on stdin or an absolute path to the
/// same interpreter. `$defaults` keeps the built-in exfiltration rule: a list
/// without it replaces the section.
const AUTO_MODE_HARD_DENY_RULES: &[&str] = &[
    "$defaults",
    "Shell indirection is never allowed, in any spelling: a shell or interpreter handed code as an argument (`bash -c`, `sh -c`, `zsh -c`, `dash -c`, `eval`, `source` or `.`, `python -c`, `perl -e`, `node -e`/`-p`, `ruby -e`, `osascript -e`), code fed to an interpreter on stdin or through a heredoc, and wrappers that run their argument as a command the permission rules cannot see (`env`, `xargs` with flags, `find -exec`/`-execdir`/`-delete`, `sudo`, `watch`, `setsid`, `flock`, `script`). A combined-flag spelling (`bash -lc`, `perl -pi -e`) or an absolute path to the same interpreter (`/bin/bash -c`) is the same command and is refused the same way; no allow rule and no user instruction clears it",
];

const SANDBOX_TOOLCHAIN_CACHE_PATHS: &[&str] = &[
    "~/.cache/go-build",
    "~/.cache/golangci-lint-harness",
    "~/.cache/uv",
    "~/.cargo/git",
    "~/.cargo/registry",
    "~/.docker/buildx",
    "~/Development/language/go/pkg/mod",
    "~/Development/language/go/pkg/sumdb",
    "~/Library/Application Support/go",
    "~/Library/Caches/go-build",
    "~/Library/Caches/golangci-lint",
    "~/Library/Caches/pip",
    "~/Library/Caches/pip-audit",
    "~/Library/Caches/staticcheck",
    "~/go/pkg/mod",
];

/// Sandbox write allowances beyond the toolchain caches and the scratch
/// roots: harness state and the checkouts.
const SANDBOX_ALLOW_WRITE_PATHS: &[&str] = &[
    "/var/folders",
    "~/.claude/agent-memory",
    "~/.claude/cache/docs",
    "~/.claude/friction",
    "~/.config/docket",
    "~/.docket",
];

/// Where `just` writes each shebang recipe's script before running it, as a
/// sandbox write allowance: `$XDG_RUNTIME_DIR/just`, or nothing when the
/// variable is unset or empty.
///
/// On Linux the login session sets `XDG_RUNTIME_DIR` to `/run/user/<uid>`,
/// which the sandbox mounts read-only, so without this allowance `just
/// tests` and every other shebang recipe dies on "Read-only file system"
/// before its first line runs. macOS sets no `XDG_RUNTIME_DIR`; `just` then
/// falls back to `$TMPDIR` under `/var/folders`, which is already allowed,
/// so no row is needed there. Resolved from the invoking user's environment
/// when this config is evaluated, as the Go env file resolves `HOME`, so the
/// row carries the real uid on every host instead of a fixed one. Env-free
/// so the tests can pin both branches.
fn sandbox_just_tempdir(runtime_dir: Option<&str>) -> Option<String> {
    let dir = runtime_dir?.trim_end_matches('/');
    if dir.is_empty() {
        return None;
    }
    Some(format!("{dir}/just"))
}

/// The per-session throwaway workspaces every session may write: Claude
/// Code's per-user scratch root `/tmp/claude-<uid>` and its macOS spelling
/// under `/private`. The scratch Edit() allows, the sandbox write allowance,
/// the unix-socket list and the auto-mode prose all derive from this pair.
/// Env-free so the tests can pin the emitted rows for a fixed uid.
fn sandbox_scratch_roots(uid: u32) -> [String; 2] {
    [
        format!("/tmp/claude-{uid}"),
        format!("/private/tmp/claude-{uid}"),
    ]
}

/// The uid Claude Code derives its scratch root from on this host: the owner
/// of the invoking user's `HOME`, read when this config is evaluated, as the
/// Go env file resolves `HOME`. There is no fixed-uid fallback on purpose: a
/// wrong uid emits sandbox and permission rows for a directory the host never
/// uses, so a missing or unreadable `HOME` fails the build instead.
fn invoking_uid() -> Result<u32> {
    use std::os::unix::fs::MetadataExt;

    let home = std::env::var("HOME")
        .map_err(|err| anyhow::anyhow!("HOME must name the invoking user's home: {err}"))?;
    let metadata = std::fs::metadata(&home)
        .map_err(|err| anyhow::anyhow!("cannot stat HOME ({home}) to derive the uid: {err}"))?;
    Ok(metadata.uid())
}

/// Expands `SCRATCH_ROOTS_TOKEN` in one prose row to the comma-joined roots.
fn expand_scratch_roots(row: &str, scratch_roots: &[String]) -> String {
    row.replace(SCRATCH_ROOTS_TOKEN, &scratch_roots.join(", "))
}

/// The host-specific inputs `settings_with` needs, resolved from the
/// invoking user's environment when the config is evaluated.
struct HostInputs {
    just_tempdir: Option<String>,
    scratch_roots: [String; 2],
    /// True on Linux, where the sandbox's seccomp filter blocks every unix
    /// socket and the `allowUnixSockets` paths are not honored (that list
    /// is macOS-only), so `allowAllUnixSockets` is the only way to open one.
    linux: bool,
}

// Re-opens only the signing key pair inside the ~/.ssh read-deny; every
// other sensitive path stays unreadable.
const SANDBOX_ALLOW_READ_PATHS: &[&str] = &[
    GIT_AGENT_SIGNING_KEY_PATH,
    GIT_AGENT_SIGNING_KEY_PUBLIC_PATH,
];

/// Commands that need a network the sandbox cannot grant (the bulbasaur
/// cluster, AWS, the Doppler API) run unsandboxed rather than through a
/// per-call lift; the permission rules and the auto-mode classifier still
/// gate what they do.
///
/// MEASURED (2026-09-03, no dangerouslyDisableSandbox, ~/Desktop
/// deny-read): the match is over TOP-LEVEL simple commands of the whole Bash
/// call, not the call's first token — `cd /tmp/claude && git --version && ls
/// ~/Desktop`, `ls ~/Desktop; git --version`, and `set -e; git --version; ls
/// ~/Desktop` all ran the ENTIRE call unsandboxed (`ls ~/Desktop` succeeded)
/// once `git *` was in this list, whichever position the excluded command
/// sat in and whatever preceded or followed it. Excluded only when the
/// matching command sits inside a control-flow construct instead of
/// appearing as a top-level simple command: `cd /tmp/claude && set -e; for x
/// in 1; do git --version; done; ls ~/Desktop` ran sandboxed (the loop hid
/// `git` from the matcher). A `cd`/env-var PREFIX on the matching command
/// itself, as opposed to a separate command joined by `&&`/`;`, was not
/// probed. So: any entry in this list makes the WHOLE call run unsandboxed
/// the moment that command appears anywhere at top level in it, including
/// alongside unrelated commands this list was never meant to exempt — an
/// executor whose sandbox lift was denied can run anything unsandboxed by
/// appending `; git --version` (or any other listed command) to its call.
/// `git` is absent for exactly this reason: local git needs no network
/// (`github.com`/`api.github.com` are already in the network allowlist for
/// what does), so nothing here needed the exclusion. The other entries were
/// not re-probed and keep the same fail-open exclusion shape — narrowing this
/// list further, or replacing it with a command-position-aware mechanism, is
/// unassessed.
const SANDBOX_EXCLUDED_COMMANDS: &[&str] = &[
    "aws *",
    "docker *",
    "doppler *",
    "gh *",
    "kubectl *",
    "terraform *",
    "vorpal *",
];

const SANDBOX_NETWORK_ALLOWED_DOMAINS: &[&str] = &[
    "api.github.com",
    "api.osv.dev",
    "crates.io",
    "github.com",
    "proxy.golang.org",
    "static.crates.io",
    "sum.golang.org",
    "vuln.go.dev",
];

/// Each entry becomes a seatbelt subpath rule for both bind and connect. The
/// scratch roots join this list so test suites that listen on a unix socket
/// under their step directory run sandboxed; with only these two service
/// sockets, every such bind was refused.
const SANDBOX_UNIX_SOCKETS: &[&str] = &[
    "~/.orbstack/run/docker.sock",
    "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock",
];

/// Git configuration every session carries, exported as the
/// `GIT_CONFIG_KEY_n` / `GIT_CONFIG_VALUE_n` pairs git reads from the
/// environment; `GIT_CONFIG_COUNT` follows the list length.
const GIT_CONFIG: &[(&str, &str)] = &[
    ("user.signingkey", GIT_AGENT_SIGNING_KEY_PUBLIC_PATH),
    ("gpg.ssh.program", "ssh-keygen"),
    ("gpg.format", "ssh"),
    (
        "gpg.ssh.allowedSignersFile",
        GIT_ALLOWED_SIGNERS_CONFIG_PATH,
    ),
];

const PERMISSION_ALLOW_RULES: &[&str] = &[
    "Bash(docket * --help 2>&1)",
    "Bash(docket * --help)",
    "Bash(docket --version *)",
    "Bash(docket --version)",
    "Bash(docket config get:*)",
    "Bash(docket dispatch verify *)",
    "Bash(docket doc show *)",
    "Bash(docket doctor *)",
    "Bash(docket events list:*)",
    "Bash(docket guard stop *)",
    "Bash(docket issue list:*)",
    "Bash(docket issue show:*)",
    "Bash(docket next *)",
    "Bash(docket plan *)",
    "Bash(docket project list:*)",
    "Bash(docket registry audit *)",
    "Bash(docket run report:*)",
    "Bash(docket run status:*)",
    "Bash(docket run verify-pins *)",
    "Bash(docket schema list *)",
    "Bash(docket step artifact:*)",
    "Bash(docket step artifacts:*)",
    "Bash(docket step gates *)",
    "Bash(docket step list *)",
    "Bash(docket step render:*)",
    "Bash(docket step show:*)",
    "Bash(docket trust list:*)",
    "Bash(docket vote list *)",
    "Bash(docket vote result:*)",
    "Bash(docket vote show:*)",
    "Bash(docket workflow list:*)",
    "Bash(docket workflow show:*)",
    "Bash(git add:*)",
    "Bash(git branch:*)",
    "Bash(git commit:*)",
    "Bash(git diff:*)",
    "Bash(git log:*)",
    "Bash(git show:*)",
    "Bash(git status:*)",
    "Bash(git worktree list:*)",
    "Bash(go build:*)",
    "Bash(go env GO*)",
    "Bash(go test:*)",
    "Bash(go tool golangci-lint:*)",
    "Bash(go vet:*)",
    "Bash(gofmt:*)",
    "Bash(just --list)",
    "Bash(just build)",
    "Bash(just crossref-check)",
    "Bash(just doc-validate)",
    "Bash(just frozen-drift-check)",
    "Bash(just qa-test)",
    "Bash(just sdet-abuse)",
    "Bash(just secret-scan)",
    "Bash(just self-hygiene)",
    "Bash(just tests)",
    "Bash(just vuln-scan)",
    "Bash(make:*)",
    "Bash(terraform fmt -check *)",
    "Bash(terraform validate *)",
    "Bash(vorpal run:*)",
    "Bash(~/.claude/workflows/*)",
    "Bash(~/.docket/bin/wave-claim:*)",
    "WebFetch(domain:api.github.com)",
    "WebFetch(domain:claude.ai)",
    "WebFetch(domain:code.claude.com)",
    "WebFetch(domain:crates.io)",
    "WebFetch(domain:docs.claude.ai)",
    "WebFetch(domain:github.com)",
    "WebFetch(domain:raw.githubusercontent.com)",
    "WebSearch",
    "Workflow",
];

/// Directory components installed as `~/.claude/<name>` from
/// `src/user/claude_code/<name>`. `references` is on-demand reading material
/// CLAUDE.md points at (the full working agreement and harness guidance) so
/// the per-turn memory file carries only the rules every turn needs; nothing
/// under it loads on its own.
const DIRECTORY_COMPONENTS: &[&str] = &["agents", "hooks", "references", "skills", "workflows"];

pub struct ClaudeCode {
    name: String,
    systems: Vec<ArtifactSystem>,
}

fn component_name(user: &str, component: &str) -> String {
    format!("{user}-claude-code-{component}")
}

fn claude_home(entry: &str) -> String {
    format!("${{HOME}}/.claude/{entry}")
}

/// The activation spelling of a `~/`-relative path: activation expands
/// `${HOME}`, not `~`.
fn home_install(config_path: &str) -> String {
    let relative = config_path.strip_prefix("~/").unwrap_or(config_path);
    format!("${{HOME}}/{relative}")
}

fn owned<S: AsRef<str>>(rows: impl IntoIterator<Item = S>) -> Vec<String> {
    rows.into_iter().map(|s| s.as_ref().to_string()).collect()
}

/// Edit() denies for every sensitive path, sorted so the emitted list is
/// stable.
fn sensitive_path_edit_deny_patterns() -> Vec<String> {
    let mut paths: Vec<&str> = SENSITIVE_PATHS
        .iter()
        .chain(SENSITIVE_PATHS_DENY_EDIT_ONLY)
        .chain(TRUST_STORE_PATHS)
        .copied()
        .collect();
    paths.sort_unstable();
    paths.into_iter().map(|p| format!("Edit({p})")).collect()
}

fn sandbox_filesystem_deny_read_paths() -> Vec<String> {
    let mut paths: Vec<String> = SENSITIVE_PATHS
        .iter()
        .chain(SENSITIVE_PATHS_DENY_READ_ONLY)
        .map(|p| p.strip_suffix("/**").unwrap_or(p).to_string())
        .collect();
    paths.sort_unstable();
    paths
}

/// The settings.json this build emits, before it is written to the store.
/// Reads the host-specific inputs, `XDG_RUNTIME_DIR`, the uid behind
/// `HOME`, and the host OS, and hands them to `settings_with`.
fn settings() -> Result<settings::ClaudeCodeSettings> {
    Ok(settings_with(HostInputs {
        just_tempdir: sandbox_just_tempdir(std::env::var("XDG_RUNTIME_DIR").ok().as_deref()),
        scratch_roots: sandbox_scratch_roots(invoking_uid()?),
        linux: std::env::consts::OS == "linux",
    }))
}

/// Pure so a test can serialize it without a build context or a host
/// environment; the tests pin the emitted permission lists.
fn settings_with(host: HostInputs) -> settings::ClaudeCodeSettings {
    let HostInputs {
        just_tempdir,
        scratch_roots,
        linux,
    } = host;
    let expand = |rows: &[&str]| -> Vec<String> {
        rows.iter()
            .map(|row| expand_scratch_roots(row, &scratch_roots))
            .collect()
    };
    let mut builder = settings::ClaudeCodeSettings::default()
        .with_advisor_model("fable")
        .with_agent_push_notif_enabled(true)
        .with_always_thinking_enabled(false)
        .with_attribution_commit("")
        .with_attribution_pr("")
        .with_attribution_session_url(false)
        .with_auto_memory_enabled(false)
        .with_auto_updates_channel("latest")
        .with_away_summary_enabled(false)
        .with_cleanup_period_days(7)
        .with_effort_level("medium")
        .with_feedback_survey_rate(0.0)
        .with_include_git_instructions(false)
        .with_input_needed_notif_enabled(true)
        .with_isolate_peer_machines(true)
        .with_model("opus")
        .with_model_setting(
            "claude-fable-5-1",
            serde_json::json!({ "effortLevel": "high" }), // default
        )
        .with_model_setting(
            "claude-haiku-5-5",
            serde_json::json!({ "effortLevel": "medium" }), // default
        )
        .with_model_setting(
            "claude-opus-5-5",
            serde_json::json!({ "effortLevel": "medium" }), // default
        )
        .with_model_setting(
            "claude-sonnet-5-5",
            serde_json::json!({ "effortLevel": "high" }), // default
        )
        // Docket queue and run reads routinely exceed the 30000 default; at
        // the 128000 ceiling they return inline instead of to a file that
        // invites interpreter post-processing the hard_deny refuses.
        .with_bash_output_max_chars(128000)
        .with_output_style("Concise")
        .with_permission_default_mode("auto")
        .with_permission_disable_bypass_permissions_mode("disable")
        .with_preferred_notif_channel("ghostty")
        .with_remote_control_at_startup(false)
        .with_sandbox_enabled(true)
        .with_show_thinking_summaries(true)
        .with_skill_listing_budget_fraction(0.02)
        .with_spinner_tips_enabled(false)
        .with_status_line("bash ~/.claude/statusline.sh")
        .with_status_line_padding(0)
        .with_teammate_mode("in-process")
        .with_tui("fullscreen")
        .with_worktree_base_ref("head")
        .with_enabled_plugin("gopls-lsp@claude-plugins-official", true)
        .with_enabled_plugin("rust-analyzer-lsp@claude-plugins-official", true)
        .with_enabled_plugin("typescript-lsp@claude-plugins-official", true)
        .with_env("ANTHROPIC_DEFAULT_FABLE_MODEL", "claude-fable-5-1")
        .with_env("ANTHROPIC_DEFAULT_HAIKU_MODEL", "claude-haiku-5-5")
        .with_env("ANTHROPIC_DEFAULT_OPUS_MODEL", "claude-opus-5-5")
        .with_env("ANTHROPIC_DEFAULT_SONNET_MODEL", "claude-sonnet-5-5")
        .with_env("CLAUDE_CODE_ENABLE_TELEMETRY", "1")
        .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
        .with_env("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB", "0") // REASON: Must be 0 for 'with_permission_default_mode('auto')'
        .with_env("GIT_CONFIG_COUNT", &GIT_CONFIG.len().to_string())
        .with_env("OTEL_EXPORTER_OTLP_LOGS_ENDPOINT", OTEL_LOGS_ENDPOINT_LOKI)
        .with_env("OTEL_EXPORTER_OTLP_LOGS_PROTOCOL", OTEL_OTLP_PROTOCOL)
        .with_env(
            "OTEL_EXPORTER_OTLP_METRICS_ENDPOINT",
            OTEL_METRICS_ENDPOINT_MIMIR,
        )
        .with_env("OTEL_EXPORTER_OTLP_METRICS_PROTOCOL", OTEL_OTLP_PROTOCOL)
        .with_env(
            "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE",
            "cumulative",
        )
        .with_env("OTEL_LOGS_EXPORTER", "otlp")
        .with_env("OTEL_LOGS_EXPORT_INTERVAL", "15000")
        .with_env("OTEL_METRICS_EXPORTER", "otlp")
        .with_env("OTEL_METRIC_EXPORT_INTERVAL", "15000");

    for (i, (key, value)) in GIT_CONFIG.iter().enumerate() {
        builder = builder
            .with_env(&format!("GIT_CONFIG_KEY_{i}"), key)
            .with_env(&format!("GIT_CONFIG_VALUE_{i}"), value);
    }

    // Hooks stay as literal `.with_hook(...)` rows on a `settings_builder`
    // chain: the sdet-abuse gate reads this source text to prove every
    // enforcing hook is registered.
    let settings_builder = builder
        // Workflow only: docket-run launches waves, tribunals and joins
        // through the Workflow tool, never the Agent tool, so the
        // project-wide `guard spawn --active` hold has nothing to stop on
        // an Agent spawn. Matching `Agent` too blocked every Explore
        // helper and tend worker in every session of the repo whenever one
        // write-class reap went unacknowledged.
        .with_hook(
            "PreToolUse",
            Some("Workflow"),
            "bash ~/.claude/hooks/docket-spawn-guard-hook.sh",
            "command",
        )
        .with_hook(
            "PostToolUse",
            Some("Workflow"),
            "bash ~/.claude/hooks/docket-wave-audit-hook.sh",
            "command",
        )
        .with_hook(
            "Stop",
            None,
            "bash ~/.claude/hooks/docket-run-guard-hook.sh",
            "command",
        )
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/docket-trust-guard-hook.sh",
            "command",
        )
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/docket-commit-guard-hook.sh",
            "command",
        )
        .with_hook(
            "SessionStart",
            None,
            "bash ~/.claude/hooks/docket-session-start-hook.sh",
            "command",
        )
        // herdr installs this hook itself, through the ~/.claude/hooks
        // symlink into the current store; the corpus does not ship it and
        // the next `just activate` rebuilds without it. Guard the wiring so
        // a rebuilt store does not raise a hook error on every session
        // start until herdr reinstalls.
        .with_hook_timeout(
            "SessionStart",
            Some("*"),
            "test -x ~/.claude/hooks/herdr-agent-state.sh && bash ~/.claude/hooks/herdr-agent-state.sh session || true",
            "command",
            10,
        )
        .with_hook(
            "PostToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/sandbox-friction-hook.sh",
            "command",
        )
        .with_hook(
            "PermissionDenied",
            None,
            "bash ~/.claude/hooks/sandbox-friction-hook.sh",
            "command",
        )
        .with_hook(
            "PreToolUse",
            Some("Read|Grep|Glob|Write"),
            "bash ~/.claude/hooks/sensitive-path-guard-hook.sh",
            "command",
        )
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/sandbox-bypass-guard-hook.sh",
            "command",
        )
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/docket-sibling-guard-hook.sh",
            "command",
        )
        .with_auto_mode(settings::AutoMode {
            allow: expand(AUTO_MODE_ALLOW_RULES),
            environment: expand(AUTO_MODE_ENVIRONMENT_CONTEXT),
            hard_deny: owned(AUTO_MODE_HARD_DENY_RULES),
            ..Default::default()
        });

    let mut builder = settings_builder
        // Workflow scriptPath requires the directory to be readable as an
        // added directory; the Bash(~/.claude/workflows/*) allow covers only
        // Bash invocations.
        .with_permission_additional_directories(owned(["~/.claude/workflows"]));

    for rule in PERMISSION_ALLOW_RULES {
        builder = builder.with_permission_allow(rule);
    }
    for root in &scratch_roots {
        builder = builder.with_permission_allow(&format!("Edit({root}/**)"));
    }
    for verb in TRUST_STORE_ASK_VERBS.iter().chain(PUBLISHING_ASK_VERBS) {
        builder = builder.with_permission_ask(&format!("Bash({verb}:*)"));
    }
    for pattern in sensitive_path_edit_deny_patterns() {
        builder = builder.with_permission_deny(&pattern);
    }
    // Shell indirection is denied before the classifier runs.
    for pattern in SHELL_INDIRECTION_DENY_PATTERNS {
        builder = builder.with_permission_deny(pattern);
    }

    // No Read() deny rules on purpose. With any Read() deny configured the
    // harness turns every `cd <dir> && grep <relative path>` into a hard
    // ask the auto-mode classifier may not answer (its
    // deniedPathInsideDirectory circuit breaker); the sensitive roots are
    // refused instead by the sandbox denyRead list for Bash and by the
    // sensitive-path-guard hook for Read/Grep/Glob.

    let builder = builder
        .with_sandbox_allow_unsandboxed_commands(false)
        .with_sandbox_auto_allow_bash(true)
        .with_sandbox_fail_if_unavailable(true)
        .with_sandbox_excluded_commands(owned(SANDBOX_EXCLUDED_COMMANDS))
        .with_sandbox_filesystem_allow_write(
            owned(
                SANDBOX_TOOLCHAIN_CACHE_PATHS
                    .iter()
                    .chain(SANDBOX_ALLOW_WRITE_PATHS)
                    .copied()
                    .chain(scratch_roots.iter().map(String::as_str)),
            )
            .into_iter()
            .chain(just_tempdir)
            .collect(),
        )
        .with_sandbox_filesystem_deny_write(owned(TRUST_STORE_PATHS))
        .with_sandbox_filesystem_deny_read(sandbox_filesystem_deny_read_paths())
        .with_sandbox_filesystem_allow_read(owned(SANDBOX_ALLOW_READ_PATHS))
        .with_sandbox_network_allowed_domains(owned(SANDBOX_NETWORK_ALLOWED_DOMAINS))
        .with_sandbox_network_allow_unix_sockets(owned(
            SANDBOX_UNIX_SOCKETS
                .iter()
                .copied()
                .chain(scratch_roots.iter().map(String::as_str)),
        ))
        .with_sandbox_network_allow_mach_lookup(owned(["com.apple.trustd.agent"]))
        .with_sandbox_network_allow_local_binding(true);

    // Linux only: seccomp otherwise refuses socket(AF_UNIX) everywhere,
    // including the allowUnixSockets paths above. macOS enforces that
    // per-path list, and this key would widen it to every socket
    // (docker.sock, the 1Password agent), so it is never emitted there.
    if linux {
        builder.with_sandbox_network_allow_all_unix_sockets(true)
    } else {
        builder
    }
}

impl ClaudeCode {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,
        }
    }

    pub async fn build(
        self,
        context: &mut ConfigContext,
    ) -> Result<(Vec<String>, Vec<(String, String)>)> {
        let mut artifacts = Vec::new();
        let mut symlinks = Vec::new();

        for component in DIRECTORY_COMPONENTS {
            let artifact = FileSource::new(
                &component_name(&self.name, component),
                &format!("src/user/claude_code/{component}"),
                self.systems.clone(),
            )
            .build(context)
            .await?;

            symlinks.push((get_env_key(&artifact), claude_home(component)));
            artifacts.push(artifact);
        }

        let settings_json = serde_json::to_string_pretty(&settings()?)?;

        // Single-file components: (component, content, executable, install path).
        let files = [
            (
                "settings",
                settings_json.as_str(),
                false,
                claude_home("settings.json"),
            ),
            (
                "memory",
                include_str!("claude_code/CLAUDE.md"),
                false,
                claude_home("CLAUDE.md"),
            ),
            (
                "allowed-signers",
                include_str!("claude_code/allowed_signers"),
                false,
                home_install(GIT_ALLOWED_SIGNERS_CONFIG_PATH),
            ),
            (
                "statusline",
                include_str!("claude_code/statusline.sh"),
                true,
                claude_home("statusline.sh"),
            ),
        ];

        for (component, content, executable, target) in files {
            let name = component_name(&self.name, component);
            let artifact = FileCreate::new(&name, self.systems.clone(), content)
                .with_executable(executable)
                .build(context)
                .await?;

            symlinks.push((
                FileCreate::output_file_path(&get_env_key(&artifact), &name),
                target,
            ));
            artifacts.push(artifact);
        }

        Ok((artifacts, symlinks))
    }
}

#[cfg(test)]
mod tests {
    use super::{
        claude_home, component_name, home_install, owned, sandbox_filesystem_deny_read_paths,
        sandbox_just_tempdir, sandbox_scratch_roots, settings, settings_with, HostInputs,
        AUTO_MODE_ALLOW_RULES, AUTO_MODE_HARD_DENY_RULES, GIT_ALLOWED_SIGNERS_CONFIG_PATH,
        PERMISSION_ALLOW_RULES, PUBLISHING_ASK_VERBS, SANDBOX_ALLOW_READ_PATHS,
        SCRATCH_ROOTS_TOKEN, SENSITIVE_PATHS, SENSITIVE_PATHS_DENY_EDIT_ONLY,
        SENSITIVE_PATHS_DENY_READ_ONLY, SHELL_INDIRECTION_DENY_PATTERNS, TRUST_STORE_ASK_VERBS,
        TRUST_STORE_PATHS,
    };
    use crate::file::FileCreate;

    /// A uid no real host is likely to share, so a test that passes cannot be
    /// leaning on the machine it runs on: neither the macOS 501 nor the Linux
    /// 1000 default.
    const TEST_UID: u32 = 4242;
    /// The Linux runtime dir for that uid.
    const TEST_RUNTIME_DIR: &str = "/run/user/4242";

    /// The settings this build emits on a Linux host whose session sets
    /// XDG_RUNTIME_DIR, for one runtime dir value and the test uid.
    fn settings_for(runtime_dir: Option<&str>) -> serde_json::Value {
        settings_on(runtime_dir, true)
    }

    /// The settings this build emits for one runtime dir value, the test
    /// uid, and either host OS: Linux when `linux` is true, macOS otherwise.
    fn settings_on(runtime_dir: Option<&str>, linux: bool) -> serde_json::Value {
        serde_json::to_value(settings_with(HostInputs {
            just_tempdir: sandbox_just_tempdir(runtime_dir),
            scratch_roots: sandbox_scratch_roots(TEST_UID),
            linux,
        }))
        .expect("settings serialize")
    }

    /// The settings.json this build emits on a Linux host whose session sets
    /// XDG_RUNTIME_DIR, as the harness reads it. Fixed input, not the test
    /// runner's environment, so the result is the same on every machine.
    fn emitted_settings() -> serde_json::Value {
        settings_for(Some(TEST_RUNTIME_DIR))
    }

    /// The emitted write allowances for one XDG_RUNTIME_DIR value.
    fn allow_write_for(runtime_dir: Option<&str>) -> Vec<String> {
        strings(&settings_for(runtime_dir)["sandbox"]["filesystem"]["allowWrite"])
    }

    /// The rows of one emitted string array.
    fn strings(rows: &serde_json::Value) -> Vec<String> {
        rows.as_array()
            .expect("an array of rules")
            .iter()
            .map(|row| row.as_str().expect("a string rule").to_string())
            .collect()
    }

    /// The two emitted auto-mode allow rules keyed to the scratch roots:
    /// read-only search and confined file operations. Read from the emitted
    /// settings, since the source rows carry a token the emit expands.
    fn scratch_root_rules() -> Vec<String> {
        let rules: Vec<String> = strings(&emitted_settings()["autoMode"]["allow"])
            .into_iter()
            .filter(|r| r.contains("scratch roots"))
            .collect();
        assert_eq!(rules.len(), 2, "expected the search and file-op rules");
        rules
    }

    // A rule may name a `gh pr <sub>` verb in slash-compressed form (the gh
    // reads rule uses "gh pr view/checks/list/diff" for four verbs) rather
    // than spelling the whole verb out as a literal substring. Whole-literal
    // `rule.contains(verb)` misses that spelling entirely: DOT-1472 measured
    // an allow rule naming "gh pr view/edit/ready, gh pr view/close/comment"
    // with no exclusion clause passing every existing assertion. For a two-
    // word verb (anything but `gh pr <sub>`), fall back to the plain
    // substring test; for a `gh pr <sub>` verb, treat it as named when `sub`
    // appears in the slash-run immediately following any `gh pr ` occurrence
    // in the rule.
    fn rule_names_verb(rule: &str, verb: &str) -> bool {
        if rule.contains(verb) {
            return true;
        }
        let Some(sub) = verb.strip_prefix("gh pr ") else {
            return false;
        };
        rule.split("gh pr ").skip(1).any(|after| {
            let run = after
                .split(|c: char| c.is_whitespace() || c == ',' || c == ';')
                .next()
                .unwrap_or_default();
            run.split('/').any(|tok| tok == sub)
        })
    }

    #[test]
    fn allowed_signers_install_path_names_the_file_git_reads() {
        // Activation expands `${HOME}`; git expands only a leading `~/`. The
        // spellings must differ and still resolve to one file, or the symlink
        // lands somewhere git never looks and %G? goes back to N.
        assert!(GIT_ALLOWED_SIGNERS_CONFIG_PATH.starts_with("~/"));
        assert_eq!(
            home_install(GIT_ALLOWED_SIGNERS_CONFIG_PATH),
            "${HOME}/.config/git/allowed_signers"
        );
    }

    #[test]
    fn allowed_signers_roster_carries_the_agent_signing_key() {
        let roster = include_str!("claude_code/allowed_signers");

        // The key ~/.ssh/agent-signing.pub holds, scoped to git's namespace.
        // Drop this line and every agent-signed commit verifies as U instead
        // of G, silently.
        assert!(roster.contains(
            "namespaces=\"git\" ssh-ed25519 \
             AAAAC3NzaC1lZDI1NTE5AAAAIDAUWPpoXS64HKvi6LIuEdhWkmAaMBB7XNB8QGmfYejg"
        ));
    }

    #[test]
    fn component_artifacts_are_namespaced_by_user_and_component() {
        assert_eq!(
            component_name("user", "settings"),
            "user-claude-code-settings"
        );
        assert_eq!(
            component_name("user", "statusline"),
            "user-claude-code-statusline"
        );
    }

    #[test]
    fn install_destinations_live_under_the_home_claude_directory() {
        assert_eq!(
            claude_home("settings.json"),
            "${HOME}/.claude/settings.json"
        );
        assert_eq!(claude_home("agents"), "${HOME}/.claude/agents");
    }

    #[test]
    fn single_file_components_link_to_the_file_not_the_artifact_directory() {
        let output = "/var/lib/vorpal/store/artifact/output/user/abc123";

        let source = FileCreate::output_file_path(output, &component_name("user", "settings"));

        assert_eq!(
            source,
            "/var/lib/vorpal/store/artifact/output/user/abc123/user-claude-code-settings"
        );
        assert_ne!(source, output);
    }

    #[test]
    fn sandbox_read_denials_cover_every_sensitive_path() {
        let denied = sandbox_filesystem_deny_read_paths();

        for path in SENSITIVE_PATHS.iter().chain(SENSITIVE_PATHS_DENY_READ_ONLY) {
            let expected = path.strip_suffix("/**").unwrap_or(path);

            assert!(
                denied.contains(&expected.to_string()),
                "sandbox read denials are missing {expected}"
            );
        }
    }

    #[test]
    fn sandbox_allows_all_unix_sockets_on_linux() {
        // The Linux seccomp filter refuses socket(AF_UNIX) even under the
        // allowUnixSockets paths, so Linux needs the blanket switch.
        assert_eq!(
            emitted_settings()["sandbox"]["network"]["allowAllUnixSockets"],
            serde_json::Value::Bool(true)
        );
    }

    #[test]
    fn sandbox_keeps_per_path_unix_sockets_on_macos() {
        // macOS enforces the per-path list; the blanket switch would open
        // docker.sock and the 1Password agent. Apart from that key, the
        // two hosts emit identical settings.
        let macos = settings_on(Some(TEST_RUNTIME_DIR), false);
        assert!(
            macos["sandbox"]["network"]
                .get("allowAllUnixSockets")
                .is_none(),
            "macOS settings carry allowAllUnixSockets"
        );
        let mut linux = emitted_settings();
        linux["sandbox"]["network"]
            .as_object_mut()
            .expect("a network object")
            .remove("allowAllUnixSockets");
        assert_eq!(macos, linux);
    }

    #[test]
    fn sandbox_write_allowances_open_the_just_tempdir_under_the_session_runtime_dir() {
        // Linux: `just` stages every shebang recipe's script under
        // $XDG_RUNTIME_DIR/just and the sandbox mounts that runtime
        // directory read-only, so without this row `just tests` errors
        // before its first line. The row follows the session's own uid.
        let allow_write = allow_write_for(Some(TEST_RUNTIME_DIR));
        let expected = format!("{TEST_RUNTIME_DIR}/just");
        assert!(
            allow_write.contains(&expected),
            "sandbox write allowances are missing {expected}: {allow_write:?}"
        );
        assert!(
            !allow_write
                .iter()
                .any(|p| p.starts_with("/run/user/") && *p != expected),
            "a /run/user row other than the session's own: {allow_write:?}"
        );

        // A trailing slash on the variable does not double the separator.
        assert_eq!(
            sandbox_just_tempdir(Some("/run/user/4242/")).as_deref(),
            Some("/run/user/4242/just")
        );
    }

    #[test]
    fn sandbox_write_allowances_add_no_just_row_without_a_runtime_dir() {
        // macOS sets no XDG_RUNTIME_DIR and `just` falls back to $TMPDIR
        // under /var/folders, which is already allowed; an empty value is
        // treated as unset. Neither case may invent a /run/user path.
        for runtime_dir in [None, Some(""), Some("/")] {
            let allow_write = allow_write_for(runtime_dir);
            assert!(
                !allow_write.iter().any(|p| p.ends_with("/just")),
                "{runtime_dir:?} emitted a just row: {allow_write:?}"
            );
            assert!(allow_write.contains(&"/var/folders".to_string()));
        }
    }

    #[test]
    fn sandbox_read_allowances_reopen_only_the_agent_signing_key_pair() {
        assert_eq!(
            SANDBOX_ALLOW_READ_PATHS,
            ["~/.ssh/agent-signing", "~/.ssh/agent-signing.pub"]
        );
        assert!(sandbox_filesystem_deny_read_paths().contains(&"~/.ssh".to_string()));
    }

    #[test]
    fn sandbox_read_denials_carry_no_directory_glob_suffix() {
        for path in sandbox_filesystem_deny_read_paths() {
            assert!(
                !path.ends_with("/**"),
                "{path} keeps a glob suffix the sandbox reads literally"
            );
        }
    }

    #[test]
    fn sandbox_read_denials_exclude_the_edit_only_system_paths() {
        let denied = sandbox_filesystem_deny_read_paths();

        for path in SENSITIVE_PATHS_DENY_EDIT_ONLY {
            let stripped = path.strip_suffix("/**").unwrap_or(path);

            assert!(
                !denied.contains(&stripped.to_string()),
                "{stripped} is edit-denied only and must stay readable"
            );
        }
    }

    #[test]
    fn permission_allow_rules_cover_the_corpus_hygiene_shapes() {
        // The vorpal-toolchain fragment prescribes `vorpal run go:<alias>
        // ...` and the repository's own `make <target>` gates, each as its
        // own top-level command. A bare invocation of either must match a
        // deterministic allow rule: one that matches none lands in front of
        // the classifier, which refused an executor's hygiene gates 76 times
        // in one session and cost an operator gate. The `GOCACHE=` prefix
        // matches no allow rule and stays with the classifier on purpose: an
        // allow rule over an assignment would clear whatever the value
        // expands.
        let fragment = include_str!("docket/config/fragments/vorpal-toolchain.md");
        let alias = fragment
            .lines()
            .find(|line| line.starts_with("| go "))
            .and_then(|line| line.split('`').nth(1))
            .and_then(|invocation| invocation.strip_prefix("vorpal run "))
            .and_then(|invocation| invocation.split(' ').next())
            .expect("the fragment's table pins the go alias");
        for rule in ["Bash(make:*)", "Bash(vorpal run:*)"] {
            assert!(
                PERMISSION_ALLOW_RULES.contains(&rule),
                "missing allow rule: {rule}"
            );
        }
        assert!(
            fragment.contains(&format!("vorpal run {alias} build ./...")),
            "the fragment's build example uses the pinned alias"
        );
        let mut in_sh_block = false;
        for line in fragment.lines() {
            if line.starts_with("```") {
                in_sh_block = line == "```sh";
                continue;
            }
            if !in_sh_block {
                continue;
            }
            for segment in line.split("&&").map(str::trim) {
                let name = segment.split('=').next().unwrap_or_default();
                assert!(
                    !segment.contains('=')
                        || name.is_empty()
                        || !name.chars().all(|c| c.is_ascii_uppercase() || c == '_'),
                    "the fragment's sh block prefixes an assignment: {segment}"
                );
            }
        }
        assert!(
            !fragment.contains("Set `GOCACHE`"),
            "the fragment's prose does not tell executors to set a GOCACHE prefix"
        );
        assert!(
            !PERMISSION_ALLOW_RULES
                .iter()
                .any(|rule| rule.starts_with("Bash(export ") || rule.contains("GOCACHE=")),
            "no deterministic allow rule clears an assignment's value"
        );

        let mut rules: Vec<&str> = PERMISSION_ALLOW_RULES.to_vec();
        rules.sort_unstable();
        rules.dedup();
        assert_eq!(
            rules, PERMISSION_ALLOW_RULES,
            "allow rules are sorted and unique"
        );
    }

    #[test]
    fn permission_allow_rules_cover_the_workflow_just_gates() {
        // An executor runs each completion gate as a bare `just <gate>`. A
        // gate with no deterministic allow rule lands in front of the
        // auto-mode classifier, which refused build, tests, self-hygiene and
        // secret-scan for an implement step. Table-form gates such as
        // ac-commands are engine-run and skipped.
        let justfile = include_str!("../../justfile");
        let workflows = [
            include_str!("docket/config/workflows/standard-change.toml"),
            include_str!("docket/config/workflows/security-change.toml"),
        ];
        let mut checked = 0;
        for source in workflows {
            let workflow: toml::Value = toml::from_str(source).expect("workflow parses");
            let steps = workflow
                .get("step")
                .and_then(toml::Value::as_array)
                .expect("workflow declares [[step]] tables");
            for gate in steps
                .iter()
                .filter_map(|step| step.get("gates").and_then(toml::Value::as_array))
                .flatten()
                .filter_map(toml::Value::as_str)
            {
                if !justfile.lines().any(|line| line == format!("{gate}:")) {
                    continue;
                }
                let rule = format!("Bash(just {gate})");
                assert!(
                    PERMISSION_ALLOW_RULES.contains(&rule.as_str()),
                    "missing allow rule for workflow gate {gate}: {rule}"
                );
                checked += 1;
            }
        }
        assert!(checked > 0, "the workflows declare just gates");
        for rule in PERMISSION_ALLOW_RULES {
            assert!(
                !(rule.starts_with("Bash(just") && rule.contains('*')),
                "a just allow rule is a bare gate command, not a wildcard: {rule}"
            );
        }
    }

    #[test]
    fn auto_mode_allow_rules_keep_the_defaults_first_and_stay_unique() {
        assert_eq!(AUTO_MODE_ALLOW_RULES[0], "$defaults");

        let mut rules: Vec<&str> = AUTO_MODE_ALLOW_RULES.to_vec();
        rules.sort_unstable();
        rules.dedup();
        assert_eq!(rules.len(), AUTO_MODE_ALLOW_RULES.len());
    }

    #[test]
    fn auto_mode_definition_source_rule_excludes_the_harness_controls() {
        // Agents may edit skill and workflow prose without a self-modification
        // refusal, but never the files that define their own permissions,
        // sandbox, or hooks. Dropping an exclusion must fail this test.
        let rules: Vec<&&str> = AUTO_MODE_ALLOW_RULES
            .iter()
            .filter(|r| r.starts_with("Editing Claude Code and Docket definition source"))
            .collect();
        assert_eq!(
            rules.len(),
            1,
            "expected exactly one definition-source rule"
        );

        let (_, excluded) = rules[0]
            .split_once("just activate`;")
            .expect("the rule names its exclusions after the activation clause");
        for control in [
            "settings.rs",
            "claude_code.rs",
            "src/user/claude_code/hooks/**",
            "permission, sandbox and autoMode rules",
            "~/.claude",
            "~/.docket/config",
        ] {
            assert!(
                excluded.contains(control),
                "{control} must stay outside the rule"
            );
        }
        assert!(excluded.contains("stay outside this rule"));
    }

    #[test]
    fn scratch_roots_follow_the_invoking_uid_on_both_platforms() {
        // Claude Code's scratch root is /tmp/claude-<uid>; macOS also reaches
        // it through /private. The macOS default uid and the Linux default
        // uid both derive from the same rule, with no fixed fallback.
        assert_eq!(
            sandbox_scratch_roots(501),
            ["/tmp/claude-501", "/private/tmp/claude-501"]
        );
        assert_eq!(
            sandbox_scratch_roots(1000),
            ["/tmp/claude-1000", "/private/tmp/claude-1000"]
        );
    }

    #[test]
    fn emitted_settings_carry_the_derived_scratch_roots_and_no_fixed_uid() {
        // Every row derived from the scratch roots carries the uid the config
        // was evaluated for: the sandbox write allowance, the unix-socket
        // list, the scratch Edit() allows, and the auto-mode environment and
        // allow prose the classifier reads. A fixed claude-501 path, or an
        // unexpanded token, would name a directory a Linux host never uses.
        let emitted = emitted_settings();
        let roots = sandbox_scratch_roots(TEST_UID);

        let allow_write = strings(&emitted["sandbox"]["filesystem"]["allowWrite"]);
        let unix_sockets = strings(&emitted["sandbox"]["network"]["allowUnixSockets"]);
        let permission_allow = strings(&emitted["permissions"]["allow"]);
        for root in &roots {
            assert!(allow_write.contains(root), "allowWrite lacks {root}");
            assert!(unix_sockets.contains(root), "allowUnixSockets lacks {root}");
            let edit = format!("Edit({root}/**)");
            assert!(permission_allow.contains(&edit), "allow lacks {edit}");
        }

        for rule in scratch_root_rules() {
            for root in &roots {
                assert!(rule.contains(root), "{root} is missing from: {rule}");
            }
        }
        let environment = strings(&emitted["autoMode"]["environment"]);
        let scratch_rows: Vec<&String> = environment
            .iter()
            .filter(|row| row.starts_with("**Scratch roots**"))
            .collect();
        assert_eq!(scratch_rows.len(), 1, "expected one scratch-roots row");
        for root in &roots {
            assert!(
                scratch_rows[0].contains(root),
                "{root} is missing from: {}",
                scratch_rows[0]
            );
        }

        let json = serde_json::to_string(&emitted).expect("settings serialize");
        assert!(
            !json.contains("claude-501"),
            "a fixed claude-501 path was emitted"
        );
        assert!(
            !json.contains(SCRATCH_ROOTS_TOKEN),
            "an unexpanded scratch-roots token was emitted"
        );
    }

    #[test]
    fn scratch_roots_token_appears_only_where_the_emit_expands_it() {
        // The prose rows spell the roots through the token; a literal root in
        // the source would go stale on any host but the one it was written on.
        let source_rows = AUTO_MODE_ALLOW_RULES
            .iter()
            .chain(super::AUTO_MODE_ENVIRONMENT_CONTEXT)
            .chain(AUTO_MODE_HARD_DENY_RULES);
        for row in source_rows {
            assert!(
                !row.contains("/tmp/claude-"),
                "a literal scratch root in a source row: {row}"
            );
        }
        let tokenized = AUTO_MODE_ALLOW_RULES
            .iter()
            .chain(super::AUTO_MODE_ENVIRONMENT_CONTEXT)
            .filter(|row| row.contains(SCRATCH_ROOTS_TOKEN))
            .count();
        assert_eq!(
            tokenized, 3,
            "expected the environment row and two allow rules"
        );
    }

    #[test]
    fn auto_mode_allow_rules_never_clear_publishing_or_secret_verbs() {
        // Every rule that names a publishing or secret-bearing verb must name
        // it as excluded. The classifier reads these as prose, so the check is
        // textual: the verb may appear only alongside "outside" or "ask".
        for rule in AUTO_MODE_ALLOW_RULES {
            for verb in TRUST_STORE_ASK_VERBS.iter().chain(PUBLISHING_ASK_VERBS) {
                if rule_names_verb(rule, verb) {
                    assert!(
                        rule.contains("outside") || rule.contains("ask"),
                        "{verb} is named without an exclusion in: {rule}"
                    );
                }
            }
            for verb in ["doppler", "op read", "op run"] {
                assert!(!rule.contains(verb), "{verb} must never be allow-listed");
            }
        }

        // The `gh` rule names none of PUBLISHING_ASK_VERBS's three-word `gh
        // pr` phrases as substrings (it lists `gh pr view/checks/list/diff`
        // in slash-compressed form), so the loop above never executes for
        // it. Assert on it unconditionally instead: deleting its exclusion
        // clause must fail this test even though no verb string matches.
        let gh_rules: Vec<&&str> = AUTO_MODE_ALLOW_RULES
            .iter()
            .filter(|r| r.starts_with("Read-only gh reads"))
            .collect();
        assert_eq!(gh_rules.len(), 1, "expected exactly one gh reads rule");
        assert!(
            gh_rules[0].contains("outside") || gh_rules[0].contains("ask"),
            "the gh reads rule must exclude every other gh verb: {}",
            gh_rules[0]
        );
    }

    #[test]
    fn sensitive_path_guard_hook_roster_matches_the_sensitive_read_set() {
        // The hook stands in for the Read() deny rules, so its embedded list
        // must be exactly the set the sandbox denies reads of. Drift either
        // way is a silent hole: a root the hook lacks is readable through the
        // Read tool, a root only the hook has is readable through Bash.
        let hook = include_str!("claude_code/hooks/sensitive-path-guard-hook.sh");
        let start = hook
            .find("SENSITIVE_ROOTS='")
            .expect("hook declares SENSITIVE_ROOTS");
        let body = &hook[start + "SENSITIVE_ROOTS='".len()..];
        let end = body.find('\'').expect("SENSITIVE_ROOTS is closed");
        let mut roster: Vec<&str> = body[..end].lines().filter(|l| !l.is_empty()).collect();
        roster.sort_unstable();

        let mut expected: Vec<&str> = SENSITIVE_PATHS
            .iter()
            .chain(SENSITIVE_PATHS_DENY_READ_ONLY)
            .copied()
            .collect();
        expected.sort_unstable();

        assert_eq!(roster, expected);
    }

    #[test]
    fn emitted_ask_rules_equal_an_explicit_literal_set() {
        // Independent ground truth: this literal set is NOT derived from the
        // ask-verb tables, so a verb quietly dropped from either, or an ask
        // row added anywhere in `settings()`, changes the emitted array
        // relative to a set that never moves with it.
        let mut expected = vec![
            "Bash(docket trust add:*)".to_string(),
            "Bash(docket trust rm:*)".to_string(),
            "Bash(gh api:*)".to_string(),
            "Bash(gh pr close:*)".to_string(),
            "Bash(gh pr comment:*)".to_string(),
            "Bash(gh pr create:*)".to_string(),
            "Bash(gh pr edit:*)".to_string(),
            "Bash(gh pr merge:*)".to_string(),
            "Bash(gh pr ready:*)".to_string(),
            "Bash(git push:*)".to_string(),
        ];
        let mut actual = strings(&emitted_settings()["permissions"]["ask"]);
        expected.sort_unstable();
        actual.sort_unstable();
        assert_eq!(actual, expected);
    }

    #[test]
    fn every_publishing_gh_verb_the_pr_skill_invokes_has_an_ask_row() {
        // Cross-check against the skill's own text rather than against
        // PUBLISHING_ASK_VERBS itself: a mutant that deletes rows from the
        // constant still leaves this assertion something independent to
        // fail against, since the skill file the verbs are extracted from
        // does not move when the constant does. `gh pr view`, `checks`,
        // `list`, and `diff` are read verbs (the exact set the gh reads rule
        // in AUTO_MODE_ALLOW_RULES lists); every OTHER `gh pr <verb>` the
        // skill invokes, plus a bare `gh api`, must have an ask row.
        const READ_GH_PR_VERBS: &[&str] = &["view", "checks", "list", "diff"];

        let skill = include_str!("claude_code/skills/pr/SKILL.md");
        let ask_patterns = strings(&emitted_settings()["permissions"]["ask"]);

        let mut publishing_verbs: Vec<String> = skill
            .split("gh pr ")
            .skip(1)
            .map(|after| {
                after
                    .split(|c: char| !c.is_ascii_lowercase())
                    .next()
                    .unwrap_or_default()
            })
            .filter(|verb| !verb.is_empty() && !READ_GH_PR_VERBS.contains(verb))
            .map(|verb| format!("gh pr {verb}"))
            .chain(skill.contains("gh api").then(|| "gh api".to_string()))
            .collect();
        publishing_verbs.sort_unstable();
        publishing_verbs.dedup();

        assert!(
            !publishing_verbs.is_empty(),
            "expected the pr skill to invoke at least one publishing gh verb"
        );
        for verb in publishing_verbs {
            let pattern = format!("Bash({verb}:*)");
            assert!(
                ask_patterns.contains(&pattern),
                "{verb} is invoked by the pr skill but has no permission-ask row"
            );
        }
    }

    #[test]
    fn shell_indirection_deny_patterns_equal_an_explicit_literal_set() {
        // Independent ground truth, not derived from the constant: a row
        // quietly dropped from SHELL_INDIRECTION_DENY_PATTERNS fails here.
        let mut expected = vec![
            "Bash(. *)",
            "Bash(bash -*c *)",
            "Bash(dash -*c *)",
            "Bash(env *)",
            "Bash(eval *)",
            "Bash(find * -delete*)",
            "Bash(find * -exec*)",
            "Bash(find * -ok*)",
            "Bash(flock *)",
            "Bash(node --eval *)",
            "Bash(node --print *)",
            "Bash(node -*e *)",
            "Bash(node -*p *)",
            "Bash(osascript -*e *)",
            "Bash(perl -*e *)",
            "Bash(python* -*c *)",
            "Bash(ruby -*e *)",
            "Bash(script *)",
            "Bash(setsid *)",
            "Bash(sh -*c *)",
            "Bash(source *)",
            "Bash(sudo *)",
            "Bash(watch *)",
            "Bash(xargs -*)",
            "Bash(zsh -*c *)",
        ];
        let mut actual: Vec<&str> = SHELL_INDIRECTION_DENY_PATTERNS.to_vec();
        expected.sort_unstable();
        actual.sort_unstable();
        assert_eq!(actual, expected);
    }

    #[test]
    fn shell_indirection_deny_patterns_are_sorted() {
        // Uniqueness and the `Bash(...)` shape follow from the literal-set
        // test above; source order is the one property it does not pin.
        let mut sorted: Vec<&str> = SHELL_INDIRECTION_DENY_PATTERNS.to_vec();
        sorted.sort_unstable();
        assert_eq!(sorted, SHELL_INDIRECTION_DENY_PATTERNS.to_vec());
    }

    #[test]
    fn emitted_deny_rules_are_the_edit_and_indirection_rows_only() {
        // The deny array is the sorted Edit() row for every sensitive path
        // and trust-store file, followed by the shell-indirection patterns,
        // and nothing else: a row added anywhere in `settings()` lands here.
        // No row may be a Read() deny, which would re-arm the harness's
        // compound-cd ask (see the comment where the Edit() denies are built).
        let deny = strings(&emitted_settings()["permissions"]["deny"]);

        let mut sensitive: Vec<&str> = SENSITIVE_PATHS
            .iter()
            .chain(SENSITIVE_PATHS_DENY_EDIT_ONLY)
            .chain(TRUST_STORE_PATHS)
            .copied()
            .collect();
        sensitive.sort_unstable();
        let expected: Vec<String> = sensitive
            .iter()
            .map(|p| format!("Edit({p})"))
            .chain(owned(SHELL_INDIRECTION_DENY_PATTERNS))
            .collect();

        assert_eq!(deny, expected);
        assert!(
            deny.iter().all(|rule| !rule.starts_with("Read(")),
            "a Read() permission deny is back"
        );
    }

    #[test]
    fn auto_mode_hard_deny_keeps_the_defaults_and_names_every_indirection_form() {
        // Without `$defaults` the list replaces the built-in exfiltration
        // rule instead of extending it (auto-mode configuration reference,
        // "Override the block and allow rules").
        assert_eq!(AUTO_MODE_HARD_DENY_RULES[0], "$defaults");

        let prose = AUTO_MODE_HARD_DENY_RULES[1..].join("\n");
        for form in [
            "bash -c",
            "sh -c",
            "zsh -c",
            "dash -c",
            "eval",
            "source",
            "python -c",
            "perl -e",
            "node -e",
            "ruby -e",
            "osascript -e",
            "stdin",
            "heredoc",
            "env",
            "xargs",
            "find -exec",
            "-delete",
            "sudo",
            "watch",
            "setsid",
            "flock",
            "script",
        ] {
            assert!(prose.contains(form), "hard_deny prose does not name {form}");
        }
    }

    #[test]
    fn auto_mode_allow_rules_never_clear_shell_indirection() {
        // The two scratch-root rules once allowed python3/perl one-liners and
        // python3 heredocs; those are indirection and now sit under the deny
        // rules, so no allow rule may name an interpreter again.
        for rule in AUTO_MODE_ALLOW_RULES {
            for word in ["python", "perl", "one-liner", "bash -c", "eval", "xargs"] {
                assert!(
                    !rule.contains(word),
                    "{word} is named in an allow rule: {rule}"
                );
            }
        }

        for rule in scratch_root_rules() {
            assert!(
                rule.contains("shell indirection") && rule.contains("outside this rule"),
                "scratch-root rule must exclude shell indirection: {rule}"
            );
        }
    }

    #[test]
    fn auto_mode_deny_lists_serialize_in_snake_case() {
        // The live schema reads `hard_deny`/`soft_deny` while the rest of the
        // block is camelCase. A camelCased key is silently ignored, which
        // would drop the indirection rule and, worse, the `$defaults` splice.
        let mode = settings::AutoMode {
            environment: vec!["$defaults".to_string()],
            allow: vec!["$defaults".to_string()],
            soft_deny: vec!["$defaults".to_string()],
            hard_deny: owned(AUTO_MODE_HARD_DENY_RULES),
            classify_all_shell: Some(false),
        };
        let json = serde_json::to_value(&mode).expect("AutoMode serializes");
        let keys: Vec<&str> = json
            .as_object()
            .expect("AutoMode is an object")
            .keys()
            .map(String::as_str)
            .collect();

        assert!(keys.contains(&"hard_deny"), "keys: {keys:?}");
        assert!(keys.contains(&"soft_deny"), "keys: {keys:?}");
        assert!(keys.contains(&"classifyAllShell"), "keys: {keys:?}");
        assert!(!keys.contains(&"hardDeny"), "keys: {keys:?}");
        assert!(!keys.contains(&"softDeny"), "keys: {keys:?}");
        assert_eq!(json["hard_deny"][0], "$defaults");
    }

    #[test]
    fn sandbox_read_denials_are_sorted_and_unique() {
        let denied = sandbox_filesystem_deny_read_paths();
        let mut expected = denied.clone();

        expected.sort_unstable();
        expected.dedup();

        assert_eq!(denied, expected);
    }

    #[test]
    fn permission_denied_friction_hook_has_no_matcher() {
        // PermissionDenied matches on tool name, so a matcher drops every
        // refusal from a tool it does not name (Edit classifier refusals
        // reached no friction row while this was `Bash`).
        let settings = emitted_settings();
        let entries = settings["hooks"]["PermissionDenied"]
            .as_array()
            .expect("a PermissionDenied hook list");
        let friction: Vec<_> = entries
            .iter()
            .filter(|entry| {
                entry["hooks"].as_array().is_some_and(|hooks| {
                    hooks.iter().any(|hook| {
                        hook["command"] == "bash ~/.claude/hooks/sandbox-friction-hook.sh"
                    })
                })
            })
            .collect();

        assert_eq!(friction.len(), 1);
        assert!(friction[0].get("matcher").is_none());
    }

    #[test]
    fn trust_store_is_unwritable_from_a_session() {
        // The trust allowlist lives under ~/.config/docket, which stays a
        // writable sandbox root for the rest of docket's config. The sandbox
        // denies writes to the allowlist and its lock, and an Edit rule
        // denies the edit tools, so no command spelling or Write call can add
        // trust; only the operator does, outside the sandbox.
        let settings = emitted_settings();
        let deny_write = strings(&settings["sandbox"]["filesystem"]["denyWrite"]);
        let allow_write = strings(&settings["sandbox"]["filesystem"]["allowWrite"]);
        let deny = strings(&settings["permissions"]["deny"]);
        for path in TRUST_STORE_PATHS {
            assert!(
                deny_write.iter().any(|p| p == path),
                "sandbox denyWrite lacks {path}: {deny_write:?}"
            );
            let rule = format!("Edit({path})");
            assert!(deny.contains(&rule), "permissions deny lacks {rule}");
        }
        assert!(
            allow_write.iter().any(|p| p == "~/.config/docket"),
            "the rest of docket's config stays writable"
        );
    }

    #[test]
    fn sensitive_path_guard_covers_write() {
        // executor-read holds the Write tool for its own scratch dir; the
        // guard confines that Write, so it must be registered on Write too.
        let settings = emitted_settings();
        let entries = settings["hooks"]["PreToolUse"]
            .as_array()
            .expect("a PreToolUse hook list");
        let guard: Vec<_> = entries
            .iter()
            .filter(|entry| {
                entry["hooks"].as_array().is_some_and(|hooks| {
                    hooks.iter().any(|hook| {
                        hook["command"] == "bash ~/.claude/hooks/sensitive-path-guard-hook.sh"
                    })
                })
            })
            .collect();

        assert_eq!(guard.len(), 1);
        let mut tools: Vec<&str> = guard[0]["matcher"]
            .as_str()
            .expect("the guard has a matcher")
            .split('|')
            .collect();
        tools.sort_unstable();
        assert_eq!(tools, ["Glob", "Grep", "Read", "Write"]);
    }
}
