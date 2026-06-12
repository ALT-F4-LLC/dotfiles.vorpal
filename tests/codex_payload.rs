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
    "team-lead",
    "ux-designer",
];

const CODEX_SKILLS: &[&str] = &[
    "adr",
    "brief",
    "code-review-verdict",
    "design-qa",
    "design-review",
    "dev-team",
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
    let agents_dir = repo_root().join("agents/codex");

    let actual_roles = fs::read_dir(&agents_dir)
        .expect("agents/codex should be readable")
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

    for config_file in configured_files {
        let relative_path = config_file
            .strip_prefix("./agents/")
            .expect("config files should be relative to ./agents");
        assert!(
            repo_root()
                .join("agents/codex")
                .join(relative_path)
                .exists(),
            "{config_file} should point to an agents/codex TOML file"
        );
    }

    assert!(
        src.contains("FileSource::new(&codex_agents_name, \"agents/codex\""),
        "user build should snapshot agents/codex"
    );
    assert!(
        src.contains("\"$HOME/.codex/agents\""),
        "user build should symlink Codex agents into ~/.codex/agents"
    );
}

#[test]
fn codex_skills_have_required_frontmatter_and_no_claude_runtime_terms() {
    let skills_dir = repo_root().join("skills/codex");

    let actual_skills = fs::read_dir(&skills_dir)
        .expect("skills/codex should be readable")
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
