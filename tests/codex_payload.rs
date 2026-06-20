use std::{
    collections::BTreeSet,
    fs,
    path::{Path, PathBuf},
};

use toml::Value;

const CODEX_ROLES: &[&str] = &[
    "project-manager",
    "sdet",
    "security-engineer",
    "senior-engineer",
    "staff-engineer",
    "ux-designer",
];

const CODEX_SKILLS: &[&str] = &[
    "adr",
    "brief",
    "code-review-verdict",
    "design-qa",
    "design-review",
    "init-specs",
    "prd",
    "review-and-comment",
    "simplify-scout",
    "tdd",
    "ux-spec",
    "verify-ac",
    "vote",
];

const BANNED_RUNTIME_TERMS: &[&str] = &[
    "SendMessage",
    "TeamCreate",
    "TeamDelete",
    "Agent(",
    "TaskCreate",
    "Skill(",
];

const CLAUDE_ONLY_AGENT_FIELDS: &[&str] = &[
    "color",
    "permissionMode",
    "tools",
    "memory",
    "skills",
    "model",
];

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

fn assert_no_banned_terms(path: &Path, content: &str) {
    for term in BANNED_RUNTIME_TERMS {
        assert!(
            !content.contains(term),
            "{} contains Claude-only runtime term {term:?}",
            path.display()
        );
    }
}

#[test]
fn codex_agent_toml_files_match_custom_agent_schema() {
    let agents_dir = repo_root().join("src/user/codex/agents");

    let actual_roles = fs::read_dir(&agents_dir)
        .expect("src/user/codex/agents should be readable")
        .map(|entry| {
            entry
                .expect("directory entry should be readable")
                .path()
                .file_stem()
                .expect("agent file should have a stem")
                .to_string_lossy()
                .into_owned()
        })
        .collect::<BTreeSet<_>>();

    let expected_roles = CODEX_ROLES
        .iter()
        .map(|role| role.to_string())
        .collect::<BTreeSet<_>>();
    assert_eq!(actual_roles, expected_roles);

    for role in CODEX_ROLES {
        let path = agents_dir.join(format!("{role}.toml"));
        let content = fs::read_to_string(&path).expect("agent TOML should be readable");
        assert_no_banned_terms(&path, &content);

        let parsed: Value = toml::from_str(&content).expect("agent TOML should parse");
        let table = parsed.as_table().expect("agent TOML should be a table");

        assert_eq!(
            table.get("name").and_then(Value::as_str),
            Some(*role),
            "{} should declare its role name",
            path.display()
        );
        assert!(
            table
                .get("description")
                .and_then(Value::as_str)
                .is_some_and(|description| !description.trim().is_empty()),
            "{} should have a non-empty description",
            path.display()
        );
        assert!(
            table
                .get("developer_instructions")
                .and_then(Value::as_str)
                .is_some_and(|instructions| !instructions.trim().is_empty()),
            "{} should have non-empty developer_instructions",
            path.display()
        );

        for field in CLAUDE_ONLY_AGENT_FIELDS {
            assert!(
                !table.contains_key(*field),
                "{} should not include Claude-only field {field}",
                path.display()
            );
        }
    }
}

#[test]
fn codex_project_manager_preserves_portable_parity_contract() {
    let path = repo_root().join("src/user/codex/agents/project-manager.toml");
    let content = fs::read_to_string(&path).expect("project-manager agent should be readable");
    let normalized = content.split_whitespace().collect::<Vec<_>>().join(" ");

    let required_markers = [
        "Proactively owns Docket decomposition",
        "Senior-engineer may create one single ad-hoc tracking issue",
        "Issue management is Docket-only",
        "Direct file writes are limited to PRD skill output under docs/spec/",
        "Senior-engineer may answer clarification-only questions; scope, plan, status, and new issue changes route through the parent or team-lead",
        "SDET may answer clarification-only questions; new test tasks and post-verification acceptance-criteria changes require the parent or team-lead gate",
        "Peer consults must include what is blocked, the decision or evidence needed, what you already checked, affected issue IDs or files",
        "advisor, security-advisor, and ux-advisor aliases",
        "When no single issue applies, comment on the issue most affected by the decision and state the broader mirrored scope",
        "Treat `planner` and `planner-fix-*` identities as disposable",
        "verified brief, prior plan, divergence trigger, affected issue IDs, and verbatim affected-thread comments",
        "After that preamble, rely only on live repository, Docket, spec, and peer evidence",
        "TeammateIdle is a stall signal",
        "asked to shut down under team-lead orchestration",
        "outside team-lead orchestration, answer the requesting parent coordinator",
        "drain background work, stop watches",
        "Start a long-running watch only when planning waits on an external job",
        "routine decomposition leaves no watches active",
        "terse and one-purpose",
        "Do not quote the prompt or peer message back",
        "Reject unsupported overconfident phrasing",
        "evidence and residual uncertainty",
        "scope boundaries, success criteria, non-goals or invariants, and priority order if scope must be cut",
        "in-session planning checklist for exploration, risk review, issue creation, dependency/collision validation, and final sign-off",
        "this checklist is separate from durable Docket issues",
        "TDD is also required for a new external dependency introduced at a trust boundary",
        "Existing accepted TDDs or UX specs permit direct executable issues",
        "go direct and record the uncertainty in the parent Risks section",
        "Every executable issue must have verified Docket file attachments",
        "Re-check active board and in-progress file attachments",
        "Describe desired outcomes, constraints, evidence, and acceptance criteria rather than step-by-step implementation directions",
        "proactively inspect file attachments on in-progress Docket issues",
        "same-file or same-contract collisions",
        "Treat stale reads as a timestamp conflict",
        "Use the smallest hierarchy that fits",
        "likelihood, impact, mitigation",
        "must-have for required delivery, should-have for important deferrable work, and could-have for optional follow-up",
        "Roll up effort with the assumed parallelism model",
        "Status and program rollups must include per-workstream progress",
        "Prefer structured output and --quiet modes",
        "Planner-specific skill restraint is strict",
        "Use the current Vorpal inventory",
        "For standalone work, create a Docket vote proposal",
        "For team work, create a proposal with docket vote create",
        "record any recurring planning pitfall in the approved durable memory surface",
        "Recurring planning pitfall records are append-only",
        "do not overwrite prior entries",
        "same lesson is not duplicated",
        "Completion or cancellation summary for any open children touched by the plan",
    ];

    for marker in required_markers {
        assert!(
            normalized.contains(marker),
            "{} should preserve project-manager parity marker {:?}",
            path.display(),
            marker
        );
    }
}

#[test]
fn codex_ux_designer_preserves_design_only_contract() {
    let path = repo_root().join("src/user/codex/agents/ux-designer.toml");
    let content = fs::read_to_string(&path).expect("ux-designer agent should be readable");

    let required_markers = [
        "Produces design specs in `docs/ux/`",
        "does NOT write implementation code",
        "You NEVER write implementation code or edit source",
        "only `docs/ux/`",
        ".codex/agent-memory/ux-designer/",
        "ux-designer has 1 persistent name: `ux-advisor`; all other spawns ephemeral",
        "Default = single `ux-advisor` via `send_input`",
        "`ux-advisor` + `design-qa-{N}` ephemeral",
        "team-lead owns `close_agent`",
        "Format authority: `src/user/codex/skills/ux-spec/SKILL.md`",
        "per team-lead.md Consensus Integration",
    ];

    for marker in required_markers {
        assert!(
            content.contains(marker),
            "{} should preserve ux-designer design-only marker {:?}",
            path.display(),
            marker
        );
    }
}

#[test]
fn codex_team_lead_delegates_actual_work() {
    let path = repo_root().join("src/user/codex/personas/team-lead.md");
    let instructions = fs::read_to_string(&path).expect("team-lead persona should be readable");

    assert!(
        instructions.contains("pure orchestration layer")
            && instructions.contains("all actual prompt work and artifact changes are delegated"),
        "{} should require team-lead to delegate actual work",
        path.display()
    );
    assert!(
        instructions.contains("single bounded role agent"),
        "{} should route trivial team-lead work through one worker, not self-work",
        path.display()
    );
    assert!(
        instructions
            .contains("Before every dispatch, choose the subagent role, model, reasoning_effort")
            && instructions.contains("Sizing: senior-engineer")
            && instructions.contains("gpt-5.3-codex-spark")
            && instructions.contains("gpt-5.4-mini")
            && instructions.contains("gpt-5.4")
            && instructions.contains("gpt-5.5")
            && instructions.contains("low effort")
            && instructions.contains("medium as the default")
            && instructions.contains("high")
            && instructions.contains("xhigh"),
        "{} should require explicit right-sized role, model, and effort selection",
        path.display()
    );
    assert!(
        !instructions.contains("Direct single-agent implementation is acceptable")
            && !instructions.contains("only when the user or parent session explicitly requests"),
        "{} should not preserve the old direct-first delegation contract",
        path.display()
    );
    assert!(
        instructions.contains("Docs-path taxonomy")
            && instructions.contains("reserved project-spec set owned by `init-specs`")
            && instructions.contains("project-manager")
            && instructions.contains("staff-engineer")
            && instructions.contains("ux-designer")
            && instructions.contains("must name the exact output path"),
        "{} should declare Codex-native docs path ownership",
        path.display()
    );
    assert!(
        instructions.contains("Closed-vs-Open dimensions")
            && instructions.contains("Do not both prescribe a shape and ask the worker to decide"),
        "{} should preserve brief-authoring discipline for open versus closed dimensions",
        path.display()
    );
    assert!(
        instructions.contains("Review and verification panels")
            && instructions.contains("Default review is one staff-engineer")
            && instructions.contains("Default verification is one sdet")
            && instructions.contains("Opt up to a doubled general review")
            && instructions.contains("Opt up security-sensitive code review to four perspectives")
            && instructions.contains("at least five modified files")
            && instructions.contains("DEGRADED: single-reviewer"),
        "{} should preserve review panel sizing and degraded fallback rules",
        path.display()
    );
    assert!(
        instructions.contains("Worker lifecycle")
            && instructions.contains("Before closing a worker")
            && instructions
                .contains("Do not dispatch a replacement worker for the same write scope")
            && instructions.contains("ask for status once"),
        "{} should preserve bounded worker lifecycle and stall recovery rules",
        path.display()
    );
    assert!(
        instructions.contains("Keep operator authority direct")
            && instructions.contains("mirror it into Docket")
            && instructions.contains("report-vs-diff mismatch"),
        "{} should preserve operator authority and visibility rules",
        path.display()
    );
    assert!(
        instructions.contains("mechanical review findings")
            && instructions.contains("batch only reviewer-named edits")
            && instructions.contains(
                "same review blocker or verification bug persists after one fresh fix attempt"
            )
            && instructions.contains("critical or high security findings"),
        "{} should preserve mechanical-batch and fix-loop cap rules",
        path.display()
    );
}

#[test]
fn codex_team_lead_execution_workflow_is_codex_native() {
    let path = repo_root().join("src/user/codex/personas/team-lead.md");
    let instructions = fs::read_to_string(&path).expect("team-lead persona should be readable");

    for term in [
        "Agent(",
        "TaskCreate",
        "TaskUpdate",
        "TaskList",
        "Monitor",
        "Bash(run_in_background",
        "TeamDelete",
        "shutdown_request",
        "shutdown_response",
        "subagent_terminated",
        "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS",
        "SendMessage",
        "Skill(",
    ] {
        assert!(
            !instructions.contains(term),
            "{} should not include Claude-only execution workflow term {term:?}",
            path.display()
        );
    }

    assert!(
        instructions.contains("spawn_agent(agent_type=\"worker\"")
            && instructions.contains("wait_agent(targets=[...]")
            && instructions.contains("close_agent(target=<agent-id>)")
            && instructions.contains("local phase ledger")
            && instructions.contains("Worker close gate"),
        "{} should describe Codex-native spawn/wait/close workflow and context tracking",
        path.display()
    );
}

#[test]
fn codex_profile_preserves_no_prose_code_comment_policy() {
    let path = repo_root().join("src/user/codex/personas/team-lead.md");
    let content = fs::read_to_string(&path).expect("team-wide policy surface should be readable");
    let normalized = content.split_whitespace().collect::<Vec<_>>().join(" ");

    assert!(
        normalized.contains("code-writing roles do not add prose or narrative comments in code")
            && normalized.contains(
                "machine-required directives, license headers, and shebangs remain allowed"
            )
            && normalized.contains(
                "staff-engineer and security-engineer flag prose or narrative comments in code under review"
            ),
        "{} should carry the team-wide no-prose-code-comments policy",
        path.display()
    );

    for role in ["senior-engineer", "sdet"] {
        let path = repo_root()
            .join("src/user/codex/agents")
            .join(format!("{role}.toml"));
        let content = fs::read_to_string(&path).expect("code-writing role should be readable");
        assert!(
            content.contains("Do not add prose or narrative comments")
                && content.contains(
                    "Machine-required directives, license headers, and shebangs are allowed"
                ),
            "{} should prohibit prose comments while allowing machine-required directives",
            path.display()
        );
    }

    for role in ["staff-engineer", "security-engineer"] {
        let path = repo_root()
            .join("src/user/codex/agents")
            .join(format!("{role}.toml"));
        let content = fs::read_to_string(&path).expect("review role should be readable");
        assert!(
            content.contains("Flag prose or narrative comments in code under review")
                && content.contains(
                    "machine-required directives, license headers, and shebangs remain allowed"
                ),
            "{} should require reviewers to flag prose-comment violations",
            path.display()
        );
    }
}

#[test]
fn codex_profile_preserves_runtime_context_discipline() {
    let path = repo_root().join("src/user/codex/personas/team-lead.md");
    let content = fs::read_to_string(&path).expect("orchestration guidance should be readable");

    assert!(
        content.contains("tool use parsimonious")
            && content.contains("Avoid defensive re-reads and rechecks")
            && content.contains("Already-read results remain in session")
            && content.contains("context until compaction or a context transition")
            && content.contains("After acceptance criteria are verified, cap iterations"),
        "{} should preserve compact runtime and context discipline",
        path.display()
    );
}

#[test]
fn codex_profile_preserves_truth_first_debugging_contract() {
    let team_lead_path = repo_root().join("src/user/codex/personas/team-lead.md");
    let team_lead =
        fs::read_to_string(&team_lead_path).expect("team-lead persona should be readable");

    for marker in [
        "Truth-First Debugging",
        "`OBSERVED`",
        "`REPRODUCED`",
        "`INFERRED`",
        "falsifier",
        "discriminating evidence",
        "`unreproduced`",
    ] {
        assert!(
            team_lead.contains(marker),
            "{} should preserve Truth-First Debugging marker {:?}",
            team_lead_path.display(),
            marker
        );
    }

    assert!(
        team_lead.contains("6. **Epistemic Discipline.**")
            && team_lead.contains("7. **CLOSED persistent set + strict ephemeral lifecycle.**"),
        "{} should keep Truth-First Debugging inside Rule 6 without renumbering Rule 7",
        team_lead_path.display()
    );

    for role in CODEX_ROLES {
        let path = repo_root()
            .join("src/user/codex/agents")
            .join(format!("{role}.toml"));
        let content = fs::read_to_string(&path).expect("agent TOML should be readable");
        for marker in [
            "per team-lead.md Rule 6, Truth-First Debugging",
            "observed failure",
            "reproduction",
            "inferred cause",
        ] {
            assert!(
                content.contains(marker),
                "{} should preserve local Truth-First Debugging marker {:?}",
                path.display(),
                marker
            );
        }
    }

    for skill in ["code-review-verdict", "verify-ac", "tdd"] {
        let path = repo_root()
            .join("src/user/codex/skills")
            .join(skill)
            .join("SKILL.md");
        let content = fs::read_to_string(&path).expect("skill file should be readable");
        for marker in [
            "per team-lead.md Rule 6, Truth-First Debugging",
            "observed failure",
            "reproduction",
            "inferred cause",
        ] {
            assert!(
                content.contains(marker),
                "{} should preserve skill Truth-First Debugging marker {:?}",
                path.display(),
                marker
            );
        }
    }
}

#[test]
fn codex_brief_preserves_intake_routing_guards() {
    let path = repo_root().join("src/user/codex/skills/brief/SKILL.md");
    let content = fs::read_to_string(&path).expect("brief skill should be readable");

    assert!(
        content.contains("no more than four options")
            && content.contains("mark your best-guess")
            && content.contains("free-form correction"),
        "{} should bound clarification options while allowing correction",
        path.display()
    );
    assert!(
        content.contains("check the local\nlead-agent docs path taxonomy")
            && content.contains("Never recommend a\nroute that bypasses the declared owner")
            && content.contains("reserved `docs/spec/` names are owned by `init-specs`"),
        "{} should preserve docs-route ownership safeguards",
        path.display()
    );
}

#[test]
fn user_config_registers_existing_codex_agent_files() {
    let src = fs::read_to_string(repo_root().join("src/user.rs"))
        .expect("src/user.rs should be readable");

    let configured_files = src
        .lines()
        .filter_map(|line| {
            let start = line.find("\"./agents/")? + 1;
            let end = start + line[start..].find('"')?;
            Some(line[start..end].to_string())
        })
        .collect::<BTreeSet<_>>();

    let expected_files = CODEX_ROLES
        .iter()
        .map(|role| format!("./agents/{role}.toml"))
        .collect::<BTreeSet<_>>();
    assert_eq!(configured_files, expected_files);
    assert!(
        !configured_files.contains("./agents/team-lead.toml"),
        "team-lead should be a root-session profile/persona, not a spawnable Codex agent"
    );

    for config_file in configured_files {
        let relative_path = config_file
            .strip_prefix("./agents/")
            .expect("config files should be relative to ./agents");
        assert!(
            repo_root()
                .join("src/user/codex/agents")
                .join(relative_path)
                .exists(),
            "{config_file} should point to an src/user/codex/agents TOML file"
        );
    }

    assert!(
        src.contains("let codex_agents_name =")
            && src.contains("let codex_agents = FileSource::new(")
            && src.contains("&codex_agents_name,")
            && src.contains("\"src/user/codex/agents\","),
        "user build should snapshot src/user/codex/agents"
    );
    assert!(
        src.contains("\"$HOME/.codex/agents\""),
        "user build should symlink Codex agents into ~/.codex/agents"
    );
    assert!(
        src.contains("$HOME/.codex/team-lead.config.toml")
            && src.contains("include_str!(\"user/codex/personas/team-lead.md\")"),
        "user build should install a team-lead profile backed by persona instructions"
    );
}

#[test]
fn user_config_routes_codex_metrics_through_alloy_otel() {
    let src = fs::read_to_string(repo_root().join("src/user.rs"))
        .expect("src/user.rs should be readable");
    let metrics_endpoint = r#""endpoint": "https://otel.bulbasaur.altf4.domains/v1/metrics""#;

    assert!(
        src.contains(".with_analytics_enabled(true)"),
        "Codex analytics should be enabled before exporting metrics"
    );
    assert!(
        src.contains(metrics_endpoint),
        "Codex metrics should flow through Alloy OTLP HTTP before Mimir remote write"
    );
}

#[test]
fn codex_skills_have_required_frontmatter_and_no_claude_runtime_terms() {
    let skills_dir = repo_root().join("src/user/codex/skills");

    let actual_skills = fs::read_dir(&skills_dir)
        .expect("src/user/codex/skills should be readable")
        .filter_map(|entry| {
            let entry = entry.expect("directory entry should be readable");
            entry
                .file_type()
                .expect("file type should be readable")
                .is_dir()
                .then(|| entry.file_name().to_string_lossy().into_owned())
        })
        .collect::<BTreeSet<_>>();

    let expected_skills = CODEX_SKILLS
        .iter()
        .map(|skill| skill.to_string())
        .collect::<BTreeSet<_>>();
    assert_eq!(actual_skills, expected_skills);

    for skill in CODEX_SKILLS {
        let path = skills_dir.join(skill).join("SKILL.md");
        let content = fs::read_to_string(&path).expect("skill file should be readable");
        assert_no_banned_terms(&path, &content);

        assert!(
            content.starts_with("---\n"),
            "{} should start with YAML frontmatter",
            path.display()
        );
        let frontmatter_end = content[4..]
            .find("\n---")
            .expect("skill frontmatter should close")
            + 4;
        let frontmatter = &content[4..frontmatter_end];

        let name_line = frontmatter
            .lines()
            .find(|line| line.starts_with("name: "))
            .expect("skill frontmatter should include name");
        assert_eq!(name_line, format!("name: {skill}"));

        assert!(
            frontmatter.contains("description:"),
            "{} should include a description",
            path.display()
        );
        assert!(
            !frontmatter.contains("allowed-tools:")
                && !frontmatter.contains("disallowed-tools:")
                && !frontmatter.contains("argument-hint:"),
            "{} should not carry Claude skill frontmatter",
            path.display()
        );
    }
}

#[test]
fn codex_init_specs_always_delegates_to_staff_engineers() {
    let path = repo_root().join("src/user/codex/skills/init-specs/SKILL.md");
    let content = fs::read_to_string(&path).expect("init-specs skill should be readable");

    assert!(
        content.contains(
            "Always delegates spec\n  authoring to parent-led Codex staff-engineer subagents"
        ) || content.contains(
            "Always delegates spec authoring to parent-led Codex staff-engineer subagents"
        ),
        "{} should require delegated spec authoring",
        path.display()
    );
    assert!(
        content.contains("Dispatch one Codex `staff-engineer` subagent per target file"),
        "{} should dispatch one staff-engineer worker per spec file",
        path.display()
    );
    assert!(
        content.contains("updated_by: \"@staff-engineer\"")
            && content.contains("owner: \"@staff-engineer\""),
        "{} should attribute delegated specs to staff-engineer workers",
        path.display()
    );
    assert!(
        !content.contains("Direct mode")
            && !content.contains("@codex")
            && !content.contains("write the specs from the current Codex session"),
        "{} should not preserve direct-mode spec authoring",
        path.display()
    );
}
