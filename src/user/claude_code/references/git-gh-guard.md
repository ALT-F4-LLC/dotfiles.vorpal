# Git and gh in the sandbox

An agent may run every `git` and `gh` command except three:

1. a push to a default branch (`main`, `master`, or the branch GitHub
   reports as the repository's default);
2. a pull request merge;
3. an override of a Git or GitHub permission that exists outside the
   sandbox: credentials and sign-in, hook and signing bypasses, rerouting
   config, and GitHub access controls. Ordinary repository administration is
   not an override.

The operator runs an excepted command themselves as `! <command>`.

Read this when `git-gh-guard-hook.sh` refuses a command, when a git or gh
command fails in the sandbox, or before changing the hook, the sandbox
exclusions or the auto-mode rows in `src/user/claude_code.rs`.

## How it is enforced

| Layer | What it does |
|---|---|
| `git-gh-guard-hook.sh` (PreToolUse, Bash) | Reads every Bash call and exits 2 on an excepted spelling, before the permission flow, for the main session, subagents and workflow agents |
| `autoMode.hard_deny` | The classifier's copy of the three exceptions, plus shell indirection, for spellings the hook cannot read. No allow rule and no stated intent clears a `hard_deny` row |
| `autoMode.allow` | Clears git in trusted repositories and gh reads and routine repository work against ALT-F4-LLC repositories |
| `permissions.ask` | Holds no git or gh row |
| `sandbox.excludedCommands` | `gh *` and the git forms listed under "What leaves the sandbox" |
| Sandbox unix sockets | No SSH agent socket, so no sandboxed process can push with its own `ssh` options |
| GitHub | `enforce_admins` on a default branch makes branch protection bind the admin token too. It reads `true` on this repository's `main`; the terraform-github repository owns the setting for the others |

## What leaves the sandbox

A Bash call leaves the sandbox only when the excluded entries cover every
top-level command in it and nothing pins it inside: `cd`, an assignment
prefix, control flow, a pipe into another command or a file redirect keeps
the whole call sandboxed (measured with `vorpal run`, another excluded
command; the doc comment on `SANDBOX_EXCLUDED_COMMANDS` holds the record).
That list is not complete: an absolute destination also pins `git clone`
and `git worktree add`, as the paragraph under the table records.
The hook does not rely on that: on the git rows below it refuses an
environment prefix and any redirect but a descriptor duplication such as
`2>&1` and a redirect to `/dev/null`; `>&file` is a file redirect. A call that
leaves reaches the auto-mode classifier; a sandboxed call does not. No
permission allow rule names an excluded git verb, so `git branch` has none.

| Excluded form | What the sandbox denied it | What the hook requires outside the sandbox |
|---|---|---|
| `git push` | SSH | The only command; `git push [flags] <remote> <branch>...`; a configured github.com remote; a literal destination that is not a default branch |
| `git fetch`, `git ls-remote` | SSH | A configured github.com remote or a github.com URL; flags from an allowlist; `--no-recurse-submodules` when the repository has submodules |
| `git pull` | SSH | A configured github.com remote, and with no remote named every remote a github.com URL; flags from an allowlist (no `-s`, `-X`, `--rebase=interactive`, `-e`, `--no-verify`, `--no-gpg-sign`); no hook file in the repository; `--no-recurse-submodules` when the repository has submodules |
| `git clone` | SSH | A github.com URL; flags from an allowlist (no `-c`, `--upload-pack`, `--template`, `--separate-git-dir`, `--recurse-submodules`); a destination under a Claude scratch root or the project (only a relative one runs; see below) |
| `git remote update`, `git remote prune` | SSH | Every remote the call names a github.com URL; `update` with no remote checks every configured remote, and `prune` needs a remote named; no remote group; `update` is refused when the repository has submodules |
| `git submodule update`, `init`, `sync` | SSH, repository `config` | Every URL in `.gitmodules` (the file, the index copy and the HEAD copy), in the local config and in each git directory under `modules` a github.com URL; those git directories (the one each submodule name maps to, and every directory there with a `HEAD` file, in any letter case, and an `objects` entry or a `commondir` file) hold only allowlisted config and `core.worktree`, no hook, no legacy remote file and no `commondir`; `modules` is a plain directory in which every directory can be listed, and each submodule name holds only letters, digits and `._/@+=-`; nothing under `modules` is a symbolic link; each submodule path in the index is reached without a symbolic link and its `.git` is absent or a one-line gitfile into `modules` with no NUL byte; no hook file in the repository; no `--recursive` |
| `git worktree add` | read-only `worktrees` directory | A destination under a Claude scratch root or the project (only a relative one runs; see below); no `--force`; no hook file in the repository |
| `git worktree remove`, `move` | read-only `worktrees` directory | A registered worktree other than the checkout the call runs in; no `--force`; for `move`, the destination rule above |
| `git worktree prune` | read-only `worktrees` directory | `-n`, `-v` and `--expire` only |
| `git branch -u`, `--set-upstream-to`, `--unset-upstream` | repository `config` | No other branch flag in the call but `-q` |
| `git config set`, `git config unset` | repository `config` | The repository's own config only; a key on the hook's allowlist that is not a dangerous key or a submodule key; under `remote.` only `tagopt` and `prune`; no `pushremote`; `branch.<name>.remote` names a configured remote and `branch.<name>.merge` a `refs/heads/` name. `user.name` and `user.email` are writable |
| `gh` | keyring and API work sandboxed; excluded for the classifier | The three exceptions in every position; `gh repo clone` follows the clone destination rule |

Every row but `gh` also requires: every word a plain literal, no environment
prefix, no git option before the subcommand but the pager, lock and advice
switches (`-p`, `--paginate`, `-P`, `--no-pager`, `--no-optional-locks`,
`--no-advice`,
which also keep the call sandboxed), and (except `git clone`) the
session's project repository with only allowlisted keys in its local config.
Every row but `gh`, `git fetch` and `git ls-remote` must also be the only
command in the call; a fetch may share a call with other commands, and that
call stays sandboxed unless all of them are excluded. Beside a command that
is not excluded (`cd <dir> &&`, `echo`, `ls`) the call stays sandboxed:
`git push` is refused there unless it is a push between scratch
repositories, and the other rows get the loose checks.

Write the destination of `git clone` and `git worktree add` relative to the
project, such as `.claude/worktrees/<name>`. A destination written as an
absolute path kept the call sandboxed (measured on Claude Code 2.1.323,
inside the project and under `/tmp`; the cause is not established): the SSH
clone failed on the host key and the worktree on the `worktrees` directory.
The destination rule in the table is what the hook accepts, not what runs:
a scratch root can only be written absolutely, so an SSH clone or a new
worktree there does not work, and neither does a new directory beside the
worktrees of a bare repository (`..` is refused, the absolute path stays
sandboxed). `git worktree remove <absolute path>` left the sandbox and
worked. `git worktree move`, `git worktree prune`, `git remote prune`,
`gh repo clone` and the submodule rows were not run on the harness. A clone
made outside the sandbox holds files the sandbox protects from writes
(`.git/config`, `.git/hooks`, and a `.zshrc` or `.zprofile` in the tree),
so a sandboxed `rm -rf` of it stops partway and the operator removes the
rest. A worktree has no such leftover: `git worktree remove` runs outside
the sandbox.

The loose checks refuse what overrides a git permission in the project:
`--no-verify`, `--no-gpg-sign`, a dangerous config key, `git remote add` or
`set-url`, a hook-manager switch. A scratch repository is exempt from them,
and the hook counts a call as scratch only when the git command names the
repository itself: `git -C <absolute dir> ...`, the first `-C` word an
absolute path written out literally. Git obeys that word whatever the shell
did before it. The shell's own directory is never followed: not a `cd` in
the call, and not the directory the call starts in, because a `cd` can fail
or be skipped and a wrapper, a function or a sourced file can move the shell
with no `cd` word. Under that word the hook requires all of:

- Every directory on the path exists before the call starts. A repository
  the call itself makes (`git init new && git -C /tmp/.../new ...`) is
  worked on in the next call.
- No word in the `-C` path that the shell expands (`~`, a variable, a
  glob), and no `..` that steps back over a symbolic link. Git is called by
  name, with no other command in front: no wrapper (`env`, `command`,
  `xargs`, `time`) and no command the hook does not know (`foo git -C ...`).
- The directory is outside every repository, wherever it lies, or the
  checkout and its git directory both lie under `/tmp` or `/var/folders`,
  the repository is not the project (a linked worktree of the project is
  the project), and none of `config`, `HEAD`, `refs`, `refs/heads`,
  `objects`, `packed-refs`, `hooks` and `info` in the git directory is a
  symbolic link.
- The call names no variable that moves the repository git reads (`GIT_DIR`,
  `GIT_WORK_TREE`, `GIT_COMMON_DIR`, `GIT_NAMESPACE`, `GIT_INDEX_FILE`,
  `GIT_OBJECT_DIRECTORY`, `GIT_CEILING_DIRECTORIES` and the like) anywhere
  in its text, and the git command carries no `--git-dir` or `--work-tree`.
  A call that could set one under a computed name also counts as the
  project: `export`, `declare`, `typeset`, `readonly`, `local`, `read`,
  `mapfile`, `readarray`, `getopts` or `printf -v` with a word the shell
  expands, and any `eval`, `source`, `.` or `trap`.
- The hook's own lookup of the repository works. A git that fails for any
  reason but "not a git repository" makes the call count as the project.

A scratch verdict never loosens `git config --global` or `--system`, a
config file named as `-f<path>`, in a short-flag cluster (`-zf <path>`), by
an abbreviated `--file` or by a second `--file`, a negated scope or file
flag (`--no-file`), a config file that is a symbolic link,
`git config --edit` with a scope or any named file, or `git config`
behind `xargs`. The hook reads `git config` the way git does: flags end at
`--` and at the first key, so `git config core.hooksPath /x --get` is a
write; any unambiguous prefix of a long flag counts (`--uns`, `--rem`),
and `--fix` is `--fixed-value`, not `--file`; and
removing or renaming a section that holds a dangerous key (`core`,
`remote.origin`, `commit`, `user`) is a dangerous write. A push between scratch
repositories needs a destination that is a repository itself and passes the
same test, and a command beside it that keeps the call sandboxed:
`git -C <absolute dir> push origin main; echo done`.

A command word the shell computes does not hide the command behind it:
`env "$V" gh pr merge 5` and `$retry gh pr merge 5` are read as
`gh pr merge 5` and refused.

A lone `-h` after `git pull` or `git clone`, and a lone `-h` or `--help`
after a three-word form such as `git worktree add`, prints usage and passes
without the repository checks. It still takes no environment prefix, no file
redirect and no git option before the subcommand but the switches named
above. `git pull --help` and `git clone --help` are refused: git turns them
into `git help <verb>`, which runs the viewer the repository's config
names. `git help pull` stays
sandboxed and works. A help flag after `git push`, `git fetch` or
`git branch -u` is refused as an unknown argument, and so is
`git ls-remote --help`; `git ls-remote -h` is its `--heads` flag and passes.

A destination "under the project" is a new directory beside the worktrees of
a bare repository, a path inside the project's checkout, or a checkout's
`.claude/worktrees/<name>`. It is never inside a `.git` or `.claude`
directory otherwise, in any letter case, and its path holds only letters,
digits and `._/@+=,:-`. A Claude scratch root is `/tmp/claude`,
`/tmp/claude-<suffix>` or any path under `/var/folders`. A path there with a
`tasks`,
`bash-edit-diff` or `plugin-tool-staging` component does not count as
scratch.

A repository "has submodules" when `.gitmodules` exists as a file, in the
index or in HEAD, when the index holds a gitlink, or when the git directory
has an entry under `modules` or a `modules` it cannot list. Any entry under
the git directory's `remotes` or
`branches` (a legacy remote definition), or such a name that is a file, a
symbolic link or a directory that cannot be listed, makes every row but
`git clone` and `gh` refuse. The rows that refuse any hook file (`git pull`,
`git worktree add` and the submodule verbs) also refuse a `hooks` directory
that cannot be listed; the other rows test the hooks they run by name.

## Forms that work

- Push: `git push -u origin <branch>` as its own call. A repeat push and
  `--force-with-lease` of the session's own branch are fine.
- Update from the remote: `git pull --rebase origin <branch>` as its own
  call, or `git fetch origin` as its own call and then a local merge or
  rebase.
- New worktree: `git worktree add -b <branch> ../<name> origin/main` does
  not pass (`..`), and an absolute path stays sandboxed and fails; name the
  path from the checkout, `.claude/worktrees/<name>`. A sibling worktree
  beside the checkout of a bare repository is the operator's to add.
- Upstream: `git switch -c x --no-track origin/y`, then
  `git branch -u origin/y x` as its own call. Git needs the remote-tracking
  ref to exist: a repository whose remote has no fetch refspec has none, and
  there only a local upstream (`git branch -u main x`) is accepted.
- Branch delete and rename stay sandboxed, where git cannot update the
  repository config. `git branch -d` deletes the branch, prints `could not
  lock config file` and exits 0. `git branch -m` renames the branch, prints
  `branch is renamed, but update of config-file failed` and exits 128; an
  upstream the branch had stays under the old name. Repair it with
  `git branch -u <upstream> <new>`, `git config unset branch.<old>.remote`
  and `git config unset branch.<old>.merge`, each as its own call. Not
  measured: `git branch -c`, which copies a config section, and a rename of
  a branch another worktree has checked out, which also writes the
  read-only `worktrees` directory.
- Config: `git config set <key> <value>`. The older `git config <key>
  <value>` stays sandboxed and fails on the repository config.
- Scratch repository: make it in one call (`git init /tmp/claude-.../r`),
  then name it in later calls as `git -C /tmp/claude-.../r ...` with the
  path written out. `cd <dir> && git commit --no-verify` is refused; a plain
  `cd <dir> && git commit` needs no exemption and passes.
- No terminal exists for any Bash call, sandboxed or not. Use
  `git commit --fixup=<sha>` then `git rebase --autosquash <base>`,
  `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>`,
  `GIT_EDITOR=true git rebase --continue`, and
  `printf 'y\nn\n' | git add -p`.

## What is refused by design

- A push beside any other command, `git push` with no remote and branch, and
  `git push origin HEAD`: name the branch, in its own call.
- `gh pr create` without `--head`, because gh would push the branch itself.
- A brace list in a git or gh command (`git add {a,b}.rs`,
  `git commit {--no-verify,-m} x`): the shell makes several words of it and
  the hook reads one. Write the words out. `stash@{0}`, `HEAD@{1}` and
  `repos/{owner}/{repo}` are not brace lists and pass.
- A bare `{`, `}` or `]]` among the words of a git or gh command
  (`git commit -m { --no-verify`, `{ git status }`): zsh ends the command
  there and bash reads an argument. Quote the word, or close a group with
  `;` first (`{ git status; }`).
- A push from any repository other than the session's project repository to
  a network remote. A push between scratch repositories is allowed only in
  a call that stays sandboxed and names the scratch path literally as
  `git -C <absolute dir>`; `git -C "$TMPDIR/r"` and `cd "$(mktemp -d)"`
  leave the target unknown.
- The scratch exemption for a call that does not name the repository as
  `git -C <absolute dir>`: after a `cd`, from a session directory that is a
  scratch repository, or through a relative `-C` word.
- Every verb that leaves the sandbox, in a repository whose local config
  holds a key outside the allowlist or that has a hook the verb runs:
  husky's `core.hooksPath`, git-lfs, a partial clone, a submodule URL off
  github.com. The operator runs the command there.
- `git remote add/set-url/rename/remove/set-branches`,
  `gh repo set-default <repo>`, `gh config set`, `gh alias`, `gh extension`,
  `gh auth` other than `status`.
- `--no-verify`, `--no-post-rewrite`, `--no-verify-signatures`,
  `--no-gpg-sign` (`git tag --no-sign` too),
  `git send-email --no-validate` and a hook manager's off switch
  (`HUSKY=0`, `HUSKY_SKIP_HOOKS`, `LEFTHOOK=0`) in a repository of record.
  A flag word that an expansion could complete to one of them is refused:
  `--no-verify"$e"`, `--no-"$x"`, `-a"$x"`, `"$d"-no-verify`, and a word
  that starts with an expansion and whose literal text is only dashes or a
  negated flag (`"$pkg-$ver"`, `"$y-$m-$d"`, `"$b"-no-ff`). An expansion
  that is a
  flag's value or starts a name passes: `-m"$msg"`, `-S"$KEY"`,
  `--author="$A"`, `-am "$msg"`, `"$v"-rc1`.
- A git or gh command in the text handed to another command to run: after
  `-c`, a cluster ending in it (`-lc`) or a cluster holding it behind a
  shell (`sh -ce`), as in `nix develop -c bash -c 'git commit ...'`,
  `direnv exec . sh -c '...'`, `"$SHELL" -c '...'`,
  `docker exec c sh -c "gh pr merge $n"` and `ssh host bash -c 'git pull'`;
  behind a runner (`nix`, `nix-shell`, `direnv`, `find -exec`), also joined
  to a flag (`doppler run --command="gh pr merge 5"`); or in a heredoc fed
  to a shell behind one. A name the call looked up or keeps in a loop
  variable, a default or an array is refused behind a runner when one of
  its subcommands follows (`doppler run -- $(which gh) pr merge 5`,
  `for g in gh; do nix develop -c $g pr merge 5; done`). Text with an expansion in it and text
  that spans lines are read the same way, and the name behind a path counts
  (`/opt/homebrew/bin/gh pr merge 5`). Run git or gh as its own command. A
  package or path named `git` in that text passes
  (`docker run img bash -c 'apt-get install -y git'`).
- `git remote "$v" ...`: the subcommand is spelled out.
- `git worktree` with `--force`; `git submodule` with `--recursive`;
  `git submodule add`, `deinit` and `set-url`, and `git switch` or
  `git checkout` setting an upstream, which stay sandboxed and fail on the
  repository config.
- `gh gist create/edit`, `gh repo create/fork/delete` and
  `gh release create/upload/delete` beside another command or behind a
  wrapper: each must be the only command and start with `gh`, so the
  classifier sees it.
- An unquoted variable in a `gh api` endpoint (quote it), and a comment body
  holding a bot merge command (`/merge`) even as prose.
- Harmless spellings the reader refuses because it fails closed:
  `gh pr -R o/r list` (flag before the subcommand), `git submodule foreach
  git ...`, `curl ... | sh` beside a git command, an unknown git global
  option, backticks holding a backslash, `$[ ]` arithmetic, a quote inside
  arithmetic that names git, any `GH_*` prefix outside a short list
  (`GH_DEBUG=api gh pr view 5`), `direnv exec . git status`,
  `cmd=(git status); "${cmd[@]}"`, `git -C <dir> pull` and the other
  excluded verbs behind `-C` as a sole command, `ln` or `cp` of a path
  ending in `git` or `gh` that is not an existing directory, a search for
  command text behind a computed name or a runner
  (`"$RG" -c "git push" docs/`, `find . -exec grep -l git {} +`), any
  program given command text after `-c` (`psql -c "select 'git commit'"`,
  `python3 -c "print('git status')"`, `ag -c "git push" docs/`),
  `find . -name git`, and gh or git run from a flake
  (`nix run nixpkgs#gh -- pr list`), a path to the program followed by an
  expansion in a shell's text (`bash -c 'ls -l /usr/bin/git "$dir"'`), and
  a variable whose value starts with `git` or `gh`, handed to a runner
  (`msg='gh is broken'; nix develop -c ./notify "$msg"`), and, in a call
  that looks git or gh up, a variable behind a runner with a word after it
  that is also a git or gh subcommand
  (`which git; nix develop -c ./tool "$X" status`).

## Residual risk

- The hook reads text and is not a boundary against a command built to get
  past it. A script file, an interpreter, a variable set in an earlier call,
  or a glob that resolves to gh without spelling it runs sandboxed where the
  hook reads nothing; sandboxed `gh` reads its keyring token and reaches
  `api.github.com`. Behind an excluded runner (`doppler`, `docker`,
  `vorpal`) the same script runs outside the sandbox, with the SSH agent in
  reach and only the classifier in front of it. Example the hook allows: `printf 'gh pr merge 5\n' > f;
  sh f`. The `hard_deny` rows cover what the classifier sees; a sandboxed
  call is auto-allowed and never reaches it.
- With `enforce_admins` on, GitHub refuses a direct write to a protected
  default branch. A pull request merge that meets the rules stays open to
  such a script, and so does every repository terraform-github does not
  manage.
- The classifier sees only a call that leaves the sandbox. `gh api` writes
  and `gh pr create/comment/edit` beside other commands reach no classifier.
- The repository checks read state before the command runs. A process left
  running by an earlier sandboxed call can change sandbox-writable state in
  between, and so can the call itself: a command earlier in the call that
  replaces a scratch directory with a link to the project (`mv`, `ln -s`),
  ahead of a `git -C` on that name, is judged as scratch.
- The temp roots of the scratch exemption are all of `/tmp` and
  `/var/folders`, wider than the Claude scratch roots a clone or worktree
  destination must lie under. A repository the operator keeps under `/tmp`
  counts as scratch.
- The `git submodule` rows refuse some harmless repositories: a submodule
  whose remote has a branch named `objects/x` or `commondir`, a submodule
  with a linked worktree or a `config.worktree` file, and a relative URL in
  `.gitmodules`. The operator runs those themselves.
- `git worktree remove` of another session's clean checkout passes the hook;
  git's own lock and dirty-tree checks and the classifier stand there.
- Writes to `.git/config` and `.git/hooks` by other programs are not read;
  the sandbox's write protection of those paths is the control.
- Contents of `--body-file`, `--input` and `-F k=@file` are not read, and
  neither are shell aliases or functions defined outside the call.
- Hook-manager switches with generic names (pre-commit's `SKIP=`,
  `PRE_COMMIT_ALLOW_NO_CONFIG=`) are not read.
- A variable that holds a git or gh command, passed to a command the hook
  does not know (`cmd='gh pr merge 5'; retry 3 $cmd`), is not read, and
  neither is a flag kept in one (`f=(--no-verify); git commit "${f[@]}"`,
  `git commit "$@"`, `${x:+--no-verify}`), an array that puts a wrapper
  first, behind such a command or a runner (`cmd=(env gh pr merge 5); retry
  "${cmd[@]}"`, `... nix develop -c "${cmd[@]}"`), a looked-up name behind
  a runner with a flag's value before its subcommand
  (`for g in git; do nix develop -c $g -C . push origin main; done`), a
  stored command that does not start with the name
  (`cmd='cd repo && gh pr merge 5'; eval "$cmd"`), text a command
  substitution reads from a heredoc (`bash -c "$(cat <<'EOF'`, the command,
  `EOF`, `)"`), or a command appended to the
  positional parameters (`set -- "$@" gh pr merge 5; "$@"`).
- Tool calls run under zsh. The hook reads the zsh forms it knows (`=gh`,
  `noglob`, a command after `[[ ]]` or in a `{ }` group closed with `;`)
  and refuses a git or gh command with a bare `{`, `}` or `]]` among its
  words; a word-splitting expansion of a stored command (`$=cmd`) is the
  variable case above.
- Text handed to a program on another machine or in a container is read
  where the git or gh command is written out as words
  (`ssh host gh pr merge 5`) or follows a `-c` style flag
  (`ssh host bash -c 'git pull'`). Quoted as one word with no such flag
  (`ssh host 'gh pr merge 5'`, `tmux new -d 'gh pr merge 5'`,
  `su --command='gh pr merge 5' user`) or fed on standard input with no
  shell named (`ssh host <<< 'gh pr merge 5'`) it is not read; over ssh it
  runs with that machine's credentials.
- Text handed to another command is refused only for a command-shaped
  mention: `git` or `gh` followed by one of its subcommands, a flag or an
  expansion. Text that builds the name (`bash -c "g$x pr merge 5"`,
  `bash -c 'g=gh; $g pr merge 5'`) is not read, and neither is text piped into a
  shell behind a runner (`echo 'gh pr merge 5' | nix develop -c bash`).
- Nested submodules over SSH are out of reach.

## Command evaluation

The tables list every command that needed a ruling. Sources: `git <cmd> -h`
and the man text of 165 commands of git 2.54.0 (the 174 that
`git --list-cmds=builtins,main` lists, less ten internal helpers named with
`--`, plus `git cvsserver`, which `git help -a` documents and this build
does not install), and `gh <cmd> --help` for all 215
commands of gh 2.87.3. Every command not named is unconditional: local,
read-only, or a write that touches none of the three exceptions.

The hook refuses a `git <word>` it does not know, because the word is then
an alias or an external `git-<word>` program. That covers git's internal
helpers (`submodule--helper`, the `remote-*` transports, the `credential*`
helpers) and any third-party subcommand but `git lfs`.

Disposition is the evaluation: **block** falls in an exception; **resolve**
is fine or blocked depending on arguments; **decide** is outside the
exceptions as worded but close enough that the operator ruled. The rulings:

- **block** rows are denied by the hook. Under the narrow reading of
  exception 3 these are allowed instead, as repository administration or
  local state the classifier judges: `git remote set-head`,
  `git symbolic-ref` and `git update-ref` on `refs/remotes/origin/HEAD`,
  `git maintenance start/register`, `git hook run`,
  `gh repo edit --enable-auto-merge` and the merge-method flags, and
  `gh api` writes that delete a repository, add a webhook or set an Actions
  secret.
- **resolve** rows are decided from the arguments, as "What leaves the
  sandbox" describes. `gh api` writes to `git/refs`, `contents`, `merges`
  and `merge-upstream` need a literal non-default branch or base.
- **decide** rows are allowed and left to the classifier: `gh pr review
  --approve`, `gh pr ready`, `gh workflow run`, `gh secret`, `gh variable`,
  `gh repo edit` of ordinary settings, `gh repo delete/archive/rename`,
  `gh release`, `gh gist`, codespace commands, and local destructive git.
  `gh repo edit --default-branch`, `--visibility`, `--allow-forking` and
  the security-analysis flags, and `gh repo create --push`, are denied.

### Push to the default branch

A text rule on `git push` cannot decide this: the destination depends on
the refspec, the current branch, and config.

| Command | Why it needs evaluation | Disposition |
|---|---|---|
| `git push` with no refspec | destination comes from `push.default`, the branch upstream, `remote.<n>.push`; on `main` it pushes `main` | resolve |
| `git push <remote> <refspec>...` | `main`, `HEAD` while on main, `x:main`, `+x:main`, `x:refs/heads/main`, `x:heads/main`, `x:HEAD`, `:main`, `@:main` | resolve |
| `git push <path>`, `file://`, `ext::`, a remote name not in the repo config, `--repo=<x>` | a local target runs its own receive hooks; if `git push` leaves the sandbox, those hooks run outside it | block |
| `gh pr checkout`, `gh pr create`, `gh repo sync` with no argument | run `git` in the current directory's repository outside the sandbox, so its config and hooks apply there | resolve (trusted repo only) |
| `git push --all` / `--branches` / `--mirror` | pushes every local branch, the default included; `--mirror` also deletes | block |
| `git push` with a wildcard refspec (`refs/heads/*:refs/heads/*`) | may include the default branch | block |
| `git push -d` / `--delete` / `--prune` | can delete the default branch | resolve |
| `git push --force` / `--force-with-lease` / `--force-if-includes` | to a non-default branch is inside the request ("any other branch is fine"); the built-in classifier rule *Git Destructive* still judges it | decide |
| `git push --recurse-submodules=on-demand` | pushes submodule branches the parent refspec does not name | resolve |
| `git push --tags`, `git push <remote> tag <t>` | tags, not branches | allow |
| `git send-pack` | plumbing push; runs no pre-push hook | resolve or block |
| `git http-push` | plumbing push over DAV | block |
| `git subtree push` | wraps `git push` | resolve |
| `git remote-http`, `remote-https`, `remote-ftp`, `remote-ftps`, `remote-ext`, `remote-fd` | transport helpers accept a `push` command on stdin | block |
| `git p4 submit`, `git send-email`, `git imap-send` | publish to Perforce or by mail; not GitHub, not a branch push | decide |
| `gh repo sync <owner/repo>` | updates the default branch of a GitHub repository from its parent; `--force` hard-resets it. Without an argument it only updates the local checkout | resolve |
| `gh repo create --push`, `--source` | pushes local commits to a new repository's default branch | decide |
| `gh pr create` | pushes the head branch when it is not on the remote; `--head` skips that | allow |
| `gh pr update-branch`, `gh pr revert`, `gh issue develop` | write a non-default branch or open a PR | allow |
| `gh api` writes to `repos/{o}/{r}/git/refs/heads/<default>` | moves or deletes the default branch | block |
| `gh api PUT/DELETE repos/{o}/{r}/contents/<path>` | commits to the default branch when no `branch` field is sent | resolve |
| `gh api POST repos/{o}/{r}/merges`, `.../merge-upstream` | merges into a named base, which may be the default branch | resolve |
| `gh api graphql` mutations `createCommitOnBranch`, `updateRef`, `updateRefs`, `createRef`, `deleteRef`, `mergeBranch` | same effects through GraphQL | resolve |

Built-in rule that matters: *Git Push Destination* in the default auto-mode
allow list says "Pushing to any branch of the session's repo is ordinary —
the default branch included". The hook and the `hard_deny` row exist
because of it: with neither, a push to `main` is approved.

### Merge a pull request

| Command | Why | Disposition |
|---|---|---|
| `gh pr merge` (`-m`, `-s`, `-r`, `-d`) | the merge itself | block |
| `gh pr merge --auto` | arms a merge that fires later without a further command | block |
| `gh pr merge --admin` | merges past unmet requirements; also exception 3 | block |
| `gh pr merge --disable-auto` | cancels an armed merge | allow |
| `gh api PUT repos/{o}/{r}/pulls/{n}/merge` | REST merge | block |
| `gh api graphql` mutations `mergePullRequest`, `enablePullRequestAutoMerge`, `enqueuePullRequest` | GraphQL merge, auto-merge, merge queue | block |
| `gh pr review --approve` | an approval can complete an armed auto-merge or a required review | decide |
| `gh pr comment` / `gh issue comment` carrying a bot command (`/merge`, `bors r+`) | the comment is the merge | resolve |
| `gh pr ready` | can release an armed auto-merge | decide |
| `gh workflow run` | a workflow can merge or push with its own token | decide |
| `git push <remote> <pr-head>:main` | GitHub marks the PR merged; covered under "Push to the default branch" | block |

`git merge`, `git rebase` and `git cherry-pick` are local, and `git pull`
merges only into the local branch. All four stay allowed.

### Override a permission that exists outside the sandbox

#### GitHub side

| Command | Why | Disposition |
|---|---|---|
| `gh auth login`, `logout`, `refresh`, `switch`, `setup-git` | change the account, token scopes, or git's credential helper | block |
| `gh auth token`, `gh auth status --show-token` | print the token; any sandboxed process could then act with it unguarded | block |
| `gh ssh-key add/delete`, `gh gpg-key add/delete`, `gh repo deploy-key add/delete` | add or remove keys that grant access | block |
| `gh auth git-credential` (hidden) | credential helper; prints the token | block |
| `gh repo set-default`, `gh repo fork --remote/--clone`, `gh repo clone ... -- <git flags>` | write git config outside the sandbox; clone passes `--template` and `-c` through | block or resolve |
| `gh secret set/delete` | Actions, Dependabot, Codespaces secrets | decide (width of exception 3) |
| `gh variable set/delete` | Actions variables; can steer a workflow | decide (width of exception 3) |
| `gh repo edit --default-branch`, `--visibility`, merge-method and auto-merge toggles; `gh api PATCH repos/{o}/{r}`; `POST .../branches/{b}/rename` | changing the default branch moves the meaning of exception 1; the others change who can merge and how | block |
| `gh repo edit` (description, topics, homepage, feature toggles) | repository metadata | decide (width of exception 3) |
| `gh repo delete`, `archive`, `unarchive`, `rename` | repository-level administration | decide (width of exception 3) |
| `gh api --input <file>`, `-F k=@<file>` | the body is not in the command text and a sandbox-writable file can change after a check; outside the sandbox the file may be any host path | resolve |
| `gh repo create`, `gh repo fork` | new public surface; the built-in classifier rules *Create Public Surface* and *Public Data-Sharing Upload* already stop these | decide |
| `gh workflow enable/disable` | turns CI on or off | decide (width of exception 3) |
| `gh run cancel`, `gh run delete`, `gh cache delete` | can remove a required check's result | decide |
| `gh issue lock/unlock`, `gh pr lock/unlock`, `gh issue transfer/delete` | change who may write | decide |
| `gh codespace ports visibility` | exposes a port publicly | decide |
| `gh api` writes to `branches/*/protection`, `rulesets`, `collaborators`, `teams`, `invitations`, `keys`, `hooks`, `actions/permissions`, `actions/secrets`, `environments`, `orgs/*`, `user/keys`, `user/gpg_keys`, and `PATCH`/`DELETE repos/{o}/{r}` | the access controls themselves | block |
| `gh api graphql` mutations on branch protection rules, rulesets, collaborators, repository settings | same through GraphQL | block |
| `gh api --hostname`, `-R/--repo`, `GH_REPO`, `GH_HOST`, `GH_TOKEN`, `GH_CONFIG_DIR` prefixes | retarget the call or swap the credential | resolve |
| `gh alias set/import` (`--shell` or a `!` expansion) | defines a `gh <name>` that runs arbitrary shell outside the sandbox | block |
| `gh extension install/upgrade/exec/create`, any `gh <extension>` | runs unreviewed code outside the sandbox with gh's token | block |
| `gh codespace ssh/cp/code/jupyter/create` | opens a remote machine whose own token can push | decide |
| `gh copilot`, `gh agent-task create` | start another agent with its own permissions | decide |
| `gh config set` | changes gh's protocol, editor, browser, prompt | block |
| `gh gist create/edit/delete`, `gh release create/edit/delete/upload` | publication; built-in classifier rules already stop most | decide |

`gh ruleset list/view/check`, `gh auth status`, every `list`, `view`,
`status`, `diff`, `checks`, `search`, `download`, `verify` command are
reads.

#### Git side

| Command | Why | Disposition |
|---|---|---|
| `git config` writes (`set`, `unset`, `edit`, `--global`, `--system`, `--file`) | `core.hooksPath`, `core.sshCommand`, `credential.*`, `url.*.insteadOf`, `remote.*.url`, `remote.*.push`, `commit.gpgsign`, `gpg.*`, `user.signingkey`, `alias.*`, `core.fsmonitor`, `safe.directory`, `protocol.*.allow`, `include.path`. The sandbox refuses the write for the repo and global files; `git config set` and `unset` leave the sandbox, where the hook passes only allowlisted keys | block |
| `git -c <k>=<v>`, `--config-env`, `GIT_CONFIG_*`, `GIT_SSH_COMMAND`, `GIT_SSH`, `GIT_ASKPASS`, `GIT_DIR`, `GIT_EXEC_PATH` prefixes | the same overrides for one command | resolve |
| `git remote add`, `set-url`, `rename`, `remove`, `set-head`, `set-branches` | change where a push goes or which branch counts as default (built-in rule *Remote Repoint*) | block |
| `git symbolic-ref` / `git update-ref` on `refs/remotes/*/HEAD` | changes the locally recorded default branch | block |
| `--no-verify` on `commit`, `merge`, `am`, `push`, `pull`, `rebase`; `--no-validate` or `-c sendemail.validate=` on `send-email`; `--no-post-rewrite` on `commit`; `--no-verify-signatures` on `merge` and `pull` | skips a hook or a signature check that exists outside the sandbox | block |
| `--no-gpg-sign` on `commit`, `merge`, `rebase`, `cherry-pick`, `revert`, `am`, `commit-tree`; `-c commit.gpgsign=false` | skips the signing requirement in `~/.config/git/config` | block |
| `git credential fill/approve/reject`, `git credential-osxkeychain`, `git credential-store`, `git credential-cache` | read (to stdout) or plant stored credentials | block |
| `git hook run`, files under `.git/hooks` | hooks are access controls and persistence; the sandbox refuses the write | resolve |
| `--receive-pack`/`--exec` on `push`/`send-pack`, `--upload-pack` on `fetch`/`pull`/`clone`/`ls-remote`/`fetch-pack`, `git archive --remote --exec`, `ext::` URLs | run a named program in place of the remote helper | block |
| `git maintenance start/register` | installs a launchd job and writes global config | block |
| `git daemon`, `git http-backend`, `git shell`, `git upload-pack`, `git receive-pack`, `git upload-archive` | serve this repository to others | decide |
| `git submodule add/update/foreach`, `git clone` of a repository outside the org | pulls and may run outside code (built-in rule *Untrusted Code Integration*) | decide; `clone` and `submodule update` outside the sandbox follow "What leaves the sandbox" |
| `git rebase --exec`, `git bisect run`, `git filter-branch`, `git difftool -x`, `git mergetool`, `git grep -O`, `git for-each-repo` | run an arbitrary command; inside the sandbox this is contained | allow sandboxed, block unsandboxed |

Local destructive commands (`git reset --hard`, `git clean -fd`,
`git checkout -- .`, `git restore .`, `git stash drop/clear`,
`git branch -D`, `git worktree remove --force`, `git reflog expire`,
`git gc --prune=now`, `git update-ref -d`) are outside the three exceptions.
The built-in classifier rule *Irreversible Local Destruction* judges them.
Disposition: decide.

## Upstream delta (git 2.54.0 → 2.56.1, gh 2.87.3 → 2.104.0)

None of these exist in the installed versions; each needs a row when the
tools are upgraded.

| Command (upstream) | Why it needs evaluation | Exception | Disposition |
|---|---|---|---|
| `gh skill publish` (gh 2.90.0) | runs `git push` for unpushed commits with no prompt, creates a release, edits repo topics; with `--tag` nothing is confirmed | 1 | block on the default branch, else decide |
| `gh skill install`, `gh skill update` (2.90.0) | write skill files that coding agents load, at project or user scope or any `--dir` | 3 | block |
| `gh skill search` (2.90.0) | interactive mode can hand results to `gh skill install` | 3 | decide |
| `gh aw`, `gh stack`, `gh webhook` stubs (2.90.0–2.100.0) | an unknown command can offer to install an official extension; under CI it installs with no prompt | 3 | block |
| `gh auth login/refresh --expiring`, `gh auth token --no-refresh`, `gh auth status --no-refresh` (2.103.0) | `gh auth status` may refresh an expiring token by default | 3 | block the writes; `status` stays a read |
| `gh config set api_host`, `expiring_credentials` (2.100.0, 2.103.0) | `api_host` redirects API calls for a host | 3 | block |
| `gh secret set/delete --app agents` (2.93.0) | new secret store | 3 | same as `gh secret` |
| `gh repo delete --accept-cascading-deletion-of-private-forks` (2.104.0) | deletes forks too | 3 | same as `gh repo delete` |
| `gh repo edit --squash-merge-commit-message` (2.88.0) | repository setting | 3 | same as `gh repo edit` |
| `gh codespace ports forward --all-interfaces` (2.98.0) | installed 2.87.3 binds every interface by default; fixed upstream | 3 | decide |
| `gh discussion *`, `gh issue artifact *`, `gh repo read-dir/read-file`, `--attach` on pr/issue commands | content writes and reads, uploads of local files | none | allow |
| `git push <remote-group>` (git 2.55.0) | one name in `remotes.<name>` pushes to several remotes in turn | 1 | resolve per member remote |
| `git refs create/update/delete/rename` (2.56.0) | porcelain for `update-ref`; can move `refs/remotes/*/HEAD` | 3 | same as `git update-ref` |
| `git hook run -j`, `hook.<event>.jobs`, `hook.<event>.enabled`, `hook.<name>.parallel` (2.55.0) | config-defined hooks; `hook.<event>.enabled=false` switches an event's hooks off | 3 | block via the `git config`/`-c` rows |
| `promisor.acceptFromServerUrl` (2.56.0) | lets a server create remotes and update stored auth fields | 3 | block via the `git config`/`-c` rows |
| `[includeIf "worktree:<glob>"]` (2.56.0) | any config key, hooks and credential helpers included, can be pulled in by worktree path | 3 | block via the `git config` rows |
| `git history fixup/drop`, `git branch --delete-merged`, `git replay --linearize` | local history and branch rewrites | none | allow |
| git 2.54.1 / 2.55.1 / 2.56.1 | fix six CVEs; installed 2.54.0 predates them and Apple backports are unknown | n/a | upgrade recommended |

## Regenerating the help text

The tables were built from the installed tools' own help. After an upgrade:

```sh
git --version; gh --version
git --list-cmds=builtins,main          # every git command
git <command> -h                       # usage, per command
git help <command>                     # man text, per command
gh help reference                      # every gh command with its flags
gh <command> --help                    # per command
claude auto-mode defaults              # the built-in classifier rules
```

Diff the command lists against the tables above, and give each new command
or flag a disposition.

## Verification

`tests/git-gh-guard-hook.test.sh` pins the hook's verdicts and runs on macOS
(BSD awk) and on Linux under mawk and gawk. Tests in
`src/user/claude_code.rs` hold the excluded git rows equal to the forms the
hook checks strictly, and keep permission rules off the excluded verbs.

Measured on the running harness (Claude Code 2.1.323) with an earlier
version of the hook, each as its own call: `git fetch`, `git ls-remote`,
`gh pr list`, a push of a new branch, a signed commit, a second push and
removal of the branch all ran; a push to `main`, `gh pr merge` and a
`gh api` DELETE of branch protection were refused, from the main session and
from a subagent. A sandboxed commit signs with the `~/.ssh/agent-signing`
key pair, so signing needs no agent socket.

Measured with this version of the hook, from the main session only:
`git pull`, `git remote update`, `git ls-remote`, `git config set` and
`unset`, `git branch -u` and `--unset-upstream`, `git worktree add` and
`remove`, an SSH `git clone` to a relative destination and a dry-run push
of a new branch ran; a push to `main`, `gh pr merge` and six spellings that
hide one of them (behind `env`, a brace list, a runner, a looked-up name)
were refused. The push, fix and push-again cycle was not repeated.

After a change to the excluded rows, check first that the patterns match no
more than written: `git remote show origin` and `git config <key> <value>`
must still fail in the sandbox.

Not verified: how the classifier applies the `hard_deny` rows (the hook
refuses first, and a probe would need a spelling built to pass the hook),
and the workflow-agent seat.
