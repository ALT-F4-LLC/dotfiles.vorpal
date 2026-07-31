# senior-engineer pitfalls (in-repo)

## Probing guard-no-commit-hook.sh: the deployed hook blocks your probe script

**Symptom** — A Bash call that merely *contains* git-write prose is blocked with
`git writes are blocked in non-interactive permission mode 'auto'`. Hits any
heredoc, inline corpus, or `for` loop whose literal text carries a `git commit` /
`git push` / `git add` bigram — even though the command performs no git write.
Looks like a permission problem; it is a text-matcher false positive.

**Root cause** — `~/.claude/hooks/guard-no-commit-hook.sh` matches on
`.tool_input.command`, i.e. the literal Bash tool-call string. Test corpora for
this hook are made almost entirely of the strings it is designed to deny, so
writing the corpus *into the command* self-denies.

**Resolution** — Put the corpus in a data file and the runner in a script file,
both created with the **Write** tool (Write does not traverse the Bash matcher),
then invoke `bash /path/run.sh`. That command string carries no git-write
bigram, so it allows. Same trick for the prototype-generating patch script.
Do not switch permission modes or edit the hook to get a probe through.
