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
/// The per-session throwaway workspaces every session may write. The scratch
/// Edit() allows, the sandbox write allowance and the unix-socket list derive
/// from this pair; the auto-mode prose names both roots and a test keeps it
/// in step.
const SANDBOX_SCRATCH_ROOTS: &[&str] = &["/tmp/claude-501", "/private/tmp/claude-501"];
const SENSITIVE_PATHS_DENY_READ_ONLY: &[&str] = &["~/.aws/**"];

const SENSITIVE_PATHS: &[&str] = &[
    "~/.claude.json",
    // config.env carries the Grafana Cloud access-policy token that
    // `agento11y login` writes; the plugin hooks read it outside the sandbox.
    "~/.config/agento11y/**",
    "~/.config/gh/**",
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

const SENSITIVE_PATHS_DENY_EDIT_ONLY: &[&str] = &[
    "/Applications/**",
    "/Library/**",
    "/System/**",
    "~/.config/docket/trust.toml",
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
    "**Scratch roots**: /tmp/claude-501, /private/tmp/claude-501, and $TMPDIR are per-session throwaway workspaces — docket steps mirror or copy a trusted checkout into STEP-<n>.d/target, STEP-<n>-target, or STEP-<n>-probe* under them and run builds, tests, and mutations there; nothing under them is a repo of record",
    "**Org-specific CLIs**: docket (high-frequency usage across projects; also present in shell history with a bundled secret-scan script) — routine under ALT-F4-LLC repos",
    "**routine under ~/.claude/ prefix**: fixes and edits under `~/.claude` are governed by the working agreement there (source-only edits, install via `just activate`, never edit installed tree directly)",
];

const AUTO_MODE_ALLOW_RULES: &[&str] = &[
    "$defaults",
    "Bash(docket:*) in ALT-F4-LLC repositories — high-frequency org CLI; includes registry and run-state verbs (workflow register --all-projects/--project, run activate, dispatch backfill-usage, issue comment, step claim) and read-only SELECTs against the docket store at ~/.docket/issues.db; `docket trust add`/`docket trust rm` write the store that authorizes a step's own gates and stay outside this rule",
    "Bash(cargo:*) in ALT-F4-LLC repositories — build/test/fmt/check/clippy, including invocations prefixed with CARGO_HOME/CARGO_TARGET_DIR/GOCACHE-style cache overrides; writes only to build caches",
    "Local git operations in trusted repositories — add, commit, worktree, cherry-pick, stash, archive, cat-file, rev-parse, and other repo-local verbs, whether run from the checkout or via `git -C <trusted checkout>`, with commit messages passed inline, via a heredoc, or via `-F <file under the scratch root>`; `git push` publishes and stays outside this rule",
    "Bash(vorpal:*) in ALT-F4-LLC repositories — the org's own build tool, same standing as docket",
    "Read-only cluster reads against bulbasaur — kubectl get/describe/logs, flux get; mutations against the cluster stay outside this rule (production)",
    "Read-only search and inspection inside trusted checkouts and the Claude scratch roots (/tmp/claude-501, /private/tmp/claude-501, $TMPDIR) — grep, rg, find, ls, cat, head, tail, sed -n, wc, diff, strings, jq — including a relative path or glob after `cd` into one of those roots; the sensitive home paths (~/.ssh, ~/.aws, ~/.gnupg, credential stores) are refused by the sandbox at the syscall level and by the sensitive-path-guard hook, and a relative path under these roots cannot reach them; interpreter code arguments and exec wrappers are shell indirection and stay outside this rule",
    "File operations confined to the Claude scratch roots (/tmp/claude-501, /private/tmp/claude-501, $TMPDIR) — mkdir, cp -R, rm -rf, mv, tar/git-archive mirrors of a trusted checkout, and in-place edits (sed -i) of files under them; these are per-session throwaway workspaces the sandbox already lets every session write, so deleting or mutating them affects no repo; interpreter code arguments and exec wrappers are shell indirection and stay outside this rule",
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
    "~/.claude/agent-memory",
    "~/Development/repository/github.com/ALT-F4-LLC",
    "/var/folders",
    "~/.claude/cache/docs",
    "~/.docket",
    // The whole config directory, not just trust.toml.lock: `docket trust
    // add` writes a temp file beside trust.toml and renames it, so a
    // lock-only allowance failed every sandboxed trust write. The Edit()
    // deny on trust.toml and the trust-guard hook still hold the executor
    // line.
    "~/.config/docket",
    "~/.claude/friction",
];

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
    "Bash(docket config get:*)",
    "Bash(docket events list:*)",
    "Bash(docket issue list:*)",
    "Bash(docket issue show:*)",
    "Bash(docket project list:*)",
    "Bash(docket run report:*)",
    "Bash(docket run status:*)",
    "Bash(docket step artifact:*)",
    "Bash(docket step artifacts:*)",
    "Bash(docket step render:*)",
    "Bash(docket step show:*)",
    "Bash(docket trust list:*)",
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
    "Bash(go test:*)",
    "Bash(go tool golangci-lint:*)",
    "Bash(go vet:*)",
    "Bash(gofmt:*)",
    "Bash(make:*)",
    "Bash(vorpal run go:1.26.0 *)",
    "Bash(~/.claude/workflows/*)",
    "WebFetch(domain:api.github.com)",
    "WebFetch(domain:claude.ai)",
    "WebFetch(domain:code.claude.com)",
    "WebFetch(domain:crates.io)",
    "WebFetch(domain:docs.claude.ai)",
    "WebFetch(domain:github.com)",
    "WebFetch(domain:mimir.bulbasaur.altf4.domains)",
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
/// Pure so a test can serialize it without a build context; the tests pin
/// the emitted permission lists.
fn settings() -> settings::ClaudeCodeSettings {
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
            "claude-opus-5-5",
            serde_json::json!({ "effortLevel": "medium" }), // default
        )
        .with_model_setting(
            "claude-sonnet-5",
            serde_json::json!({ "effortLevel": "high" }), // default
        )
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
        // The plugin id names this marketplace, so a fresh machine needs its
        // source declared here rather than in the live plugin state an
        // `agento11y claude` launch leaves behind.
        .with_extra_known_marketplace(
            "agento11y",
            serde_json::json!({ "source": { "source": "github", "repo": "grafana/agento11y" } }),
        )
        .with_enabled_plugin("agento11y-claude-code@agento11y", true)
        .with_enabled_plugin("gopls-lsp@claude-plugins-official", true)
        .with_enabled_plugin("rust-analyzer-lsp@claude-plugins-official", true)
        .with_enabled_plugin("typescript-lsp@claude-plugins-official", true)
        .with_env("ANTHROPIC_DEFAULT_FABLE_MODEL", "claude-fable-5-1")
        .with_env("ANTHROPIC_DEFAULT_HAIKU_MODEL", "claude-haiku-4-5")
        .with_env("ANTHROPIC_DEFAULT_OPUS_MODEL", "claude-opus-5-5")
        .with_env("ANTHROPIC_DEFAULT_SONNET_MODEL", "claude-sonnet-5")
        .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
        .with_env("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB", "0") // REASON: Must be 0 for 'with_permission_default_mode('auto')'
        .with_env("GIT_CONFIG_COUNT", &GIT_CONFIG.len().to_string());

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
            Some("Bash"),
            "bash ~/.claude/hooks/sandbox-friction-hook.sh",
            "command",
        )
        .with_hook(
            "PreToolUse",
            Some("Read|Grep|Glob"),
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
            allow: owned(AUTO_MODE_ALLOW_RULES),
            environment: owned(AUTO_MODE_ENVIRONMENT_CONTEXT),
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
    for root in SANDBOX_SCRATCH_ROOTS {
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

    builder
        .with_sandbox_allow_unsandboxed_commands(false)
        .with_sandbox_auto_allow_bash(true)
        .with_sandbox_fail_if_unavailable(true)
        .with_sandbox_excluded_commands(owned(SANDBOX_EXCLUDED_COMMANDS))
        .with_sandbox_filesystem_allow_write(owned(
            SANDBOX_TOOLCHAIN_CACHE_PATHS
                .iter()
                .chain(SANDBOX_ALLOW_WRITE_PATHS)
                .chain(SANDBOX_SCRATCH_ROOTS),
        ))
        .with_sandbox_filesystem_deny_read(sandbox_filesystem_deny_read_paths())
        .with_sandbox_filesystem_allow_read(owned(SANDBOX_ALLOW_READ_PATHS))
        .with_sandbox_network_allowed_domains(owned(SANDBOX_NETWORK_ALLOWED_DOMAINS))
        .with_sandbox_network_allow_unix_sockets(owned(
            SANDBOX_UNIX_SOCKETS.iter().chain(SANDBOX_SCRATCH_ROOTS),
        ))
        .with_sandbox_network_allow_mach_lookup(owned(["com.apple.trustd.agent"]))
        .with_sandbox_network_allow_local_binding(true)
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

        let settings_json = serde_json::to_string_pretty(&settings())?;

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
        claude_home, component_name, home_install, permission_ask_patterns,
        sandbox_filesystem_deny_read_paths, settings, sorted_permission_patterns,
        AUTO_MODE_ALLOW_RULES, AUTO_MODE_HARD_DENY_RULES, GIT_ALLOWED_SIGNERS_CONFIG_PATH,
        PERMISSION_ALLOW_RULES, PUBLISHING_ASK_VERBS, SANDBOX_ALLOW_READ_PATHS,
        SANDBOX_SCRATCH_ROOTS, SENSITIVE_PATHS, SENSITIVE_PATHS_DENY_EDIT_ONLY,
        SENSITIVE_PATHS_DENY_READ_ONLY, SHELL_INDIRECTION_DENY_PATTERNS,
    };
    use crate::file::FileCreate;

    /// The settings.json this build emits, as the harness reads it.
    fn emitted_settings() -> serde_json::Value {
        serde_json::to_value(settings()).expect("settings serialize")
    }

    /// The rows of one emitted string array.
    fn strings(rows: &serde_json::Value) -> Vec<String> {
        rows.as_array()
            .expect("an array of rules")
            .iter()
            .map(|row| row.as_str().expect("a string rule").to_string())
            .collect()
    }

    /// The two auto-mode allow rules keyed to the scratch roots: read-only
    /// search and confined file operations.
    fn scratch_root_rules() -> Vec<&'static str> {
        let rules: Vec<&str> = AUTO_MODE_ALLOW_RULES
            .iter()
            .copied()
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
        for rule in [
            "Bash(make:*)".to_string(),
            format!("Bash(vorpal run {alias} *)"),
        ] {
            assert!(
                PERMISSION_ALLOW_RULES.contains(&rule.as_str()),
                "missing allow rule: {rule}"
            );
        }
        assert!(
            fragment.contains(&format!("vorpal run {alias} build ./...")),
            "the fragment's build example uses the pinned alias"
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
    fn auto_mode_allow_rules_name_the_sandbox_scratch_roots() {
        // The read-only search and scratch-mutation rules are keyed to the
        // same roots the sandbox lets every session write. If the scratch
        // roots move, the classifier rules must move with them.
        for rule in scratch_root_rules() {
            for root in SANDBOX_SCRATCH_ROOTS {
                assert!(rule.contains(root), "{root} is missing from: {rule}");
            }
        }
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
        // followed by the shell-indirection patterns, and nothing else: a
        // row added anywhere in `settings()` lands here. No row may be a
        // Read() deny, which would re-arm the harness's compound-cd ask (see
        // the comment where the Edit() denies are built).
        let deny = strings(&emitted_settings()["permissions"]["deny"]);

        let mut sensitive: Vec<&str> = SENSITIVE_PATHS
            .iter()
            .chain(SENSITIVE_PATHS_DENY_EDIT_ONLY)
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
}
