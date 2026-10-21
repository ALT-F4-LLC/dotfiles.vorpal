#!/bin/bash

# Hold a docket-run conductor to the advisor-first standing ruling: every
# operator-bound question is reviewed by the advisor before it is asked.
#
# Runs before each AskUserQuestion call. In a session that conducts a live run
# (its own tool calls drive it: `docket next` or `docket dispatch` with
# `--run RUN-N`, or the conductor token path), a question is allowed only when,
# for each question in the call, either
#   (a) a completed advisor Agent launch since the last operator answer carries
#       a brief that names the question's header, a step id in it, or its full
#       text; or
#   (b) a run note of a run the session conducts records an advisor ruling for
#       a step id the question names.
# Otherwise the call is refused with the ruling's name, and the conductor
# launches the advisor and asks again. A launch counts as completed when its
# result is the report itself, or when a later transcript line carries its
# completion notice or hand-back.
#
# Sessions that conduct no run, subagents, and any unreadable transcript, engine
# answer or payload are allowed. A run id held only in a shell variable is not
# recognized as driven, and the hook cannot judge whether the advisor's brief
# was sound, only that it named the question.

set -uo pipefail

allow() { exit 0; }
deny() { printf '%s\n' "$1" >&2; exit 2; }

command -v jq >/dev/null 2>&1 || allow
command -v docket >/dev/null 2>&1 || allow
DATA=$(cat 2>/dev/null) || allow

[ "$(printf '%s' "$DATA" | jq -r '.tool_name // empty' 2>/dev/null)" = "AskUserQuestion" ] || allow
# A subagent's payload carries the parent's transcript, and the ruling binds the
# conductor, so a subagent is never held to it.
[ -n "$(printf '%s' "$DATA" | jq -r '.agent_id // empty' 2>/dev/null)" ] && allow
TRANSCRIPT=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || allow
QUESTIONS=$(printf '%s' "$DATA" | jq -c '[.tool_input.questions[]? | select(type == "object")]' 2>/dev/null) || allow
[ "$(printf '%s' "$QUESTIONS" | jq 'length' 2>/dev/null)" -gt 0 ] 2>/dev/null || allow

RUNS=$(docket run status --limit 0 --json 2>/dev/null \
    | jq -r '.data.runs // [] | .[].run | select(type == "string" and test("^RUN-[0-9]+$"))' 2>/dev/null) || allow

# The runs this session's own tool calls drive.
CALLS=$(jq -c 'select(.type == "assistant") | .message.content? | arrays | .[]
    | select(.type == "tool_use") | (.input.command? // (.input | tostring))' "$TRANSCRIPT" 2>/dev/null) || allow
DRIVEN=""
for R in $RUNS; do
    printf '%s\n' "$CALLS" | jq -e --arg r "$R" \
        'select(test("conductor\\.d/" + $r + "([^0-9]|$)") or test("docket(\\s+-\\S+)*\\s+(next|dispatch)\\b[^\\n|;&]*--run[ =]" + $r + "([^0-9]|$)"))' \
        >/dev/null 2>&1 && DRIVEN="${DRIVEN:+$DRIVEN }$R"
done
[ -n "$DRIVEN" ] || allow

# (a) The questions no completed advisor brief since the last operator answer
# names. The transcript is read whole: it is needed only here, once per question.
# An answer is a tool_result of an earlier AskUserQuestion that is not an error:
# this hook's own refusal, a classifier denial and any other hook error are
# written the same way and must not void the reviews before them. An operator's
# rejection of the call is an error result that still counts.
# A launch is complete when its result is the report itself, or when a later
# line carries its completion: a completed task notice (in a user line, a
# queued-command attachment or a queue-operation line) or a hand-back whose
# origin names it. Assistant text never counts, so a quoted id completes nothing.
UNCOVERED=$(jq -sc --argjson qs "$QUESTIONS" '
    def text: if type == "string" then .
              elif type == "array" then map(select(type == "object" and .type == "text") | (.text // "")) | join("\n")
              else "" end;
    . as $L
    | ($L | to_entries | map(.key as $i | .value as $l | select($l.type == "assistant")
        | ($l.message.content? | arrays | .[] | select(.type == "tool_use")
           | {i: $i, id, name, input}))) as $uses
    | ($L | to_entries | map(.key as $i | .value as $l | select($l.type == "user")
        | ($l.message.content? | arrays | .[] | select(.type == "tool_result")
           | {i: $i, tid: .tool_use_id, err: (.is_error == true), text: (.content | tostring)}))) as $results
    | ($uses | map(select(.name == "AskUserQuestion") | .id)) as $ask
    | ([$results[] | select(.tid as $t | $ask | index($t))
        | select((.err | not) or (.text | test("The user doesn.t want to proceed|User rejected tool use|Tool use was rejected")))
        | .i] | max // -1) as $last
    | ([ $L | to_entries[] | .key as $i | .value as $l
         | (if $l.type == "user" then
              [($l.message.content? | text), (if ($l.origin.handback? == true) then "from=\"" + ($l.origin.from // "") + "\"" else "" end)]
            elif $l.type == "attachment" then [($l.attachment.prompt? | text)]
            elif $l.type == "queue-operation" then [($l.content? | text)]
            else [] end)
         | .[] | select(length > 0)
         | ( (select(contains("<status>completed</status>")) | scan("<task-id>([0-9A-Za-z]+)</task-id>") | {i: $i, id: .[0]}),
             (scan("from=\"([0-9A-Za-z]+)\"") | {i: $i, id: .[0]}) ) ]) as $completions
    | [ $uses[] | select(.name == "Agent" and (.input.subagent_type? == "advisor") and .i > $last)
        | . as $a
        | ($results | map(select(.tid == $a.id)) | first) as $r
        | select($r != null)
        | (if ($r.text | contains("Async agent launched")) then
             (($r.text | capture("agentId: (?<a>[0-9A-Za-z]+)")? | .a) as $aid
              | $aid != null and ($completions | any(.id == $aid and .i > $r.i)))
           else true end) as $done
        | select($done)
        | ($a.input.prompt // "" | ascii_downcase) ] as $briefs
    | [ $qs[]
        | . as $q
        | (($q.header // "") | ascii_downcase) as $h
        | (($q.question // "") | ascii_downcase) as $text
        | ([ (($q.header // "") + " " + ($q.question // "")) | scan("STEP-[0-9]+") ] | unique) as $ids
        | select(($briefs | any(. as $b
                 | (($h != "" and ($b | contains($h)))
                    or ($text != "" and ($b | contains($text)))
                    or ($ids | any(. as $i | $b | test(($i | ascii_downcase) + "([^0-9]|$)")))))) | not)
        | {header: ($q.header // ""), ids: $ids} ]' "$TRANSCRIPT" 2>/dev/null) || allow
[ "$(printf '%s' "$UNCOVERED" | jq 'length' 2>/dev/null)" -gt 0 ] 2>/dev/null || allow

# (b) A run note recording an advisor ruling for the step.
NOTES=""
for R in $DRIVEN; do
    N=$(docket run note list "$R" --json 2>/dev/null | jq -c '[.data.notes[]? | .text // ""]' 2>/dev/null) || continue
    NOTES="${NOTES}"$'\n'"$N"
done
MISSING=""
while IFS= read -r U; do
    [ -n "$U" ] || continue
    if printf '%s\n' "$NOTES" | jq -es --argjson ids "$(printf '%s' "$U" | jq -c '.ids')" \
            'flatten | any(.[]; (ascii_downcase | contains("advisor")) and (. as $t | $ids | any(. as $i | $t | test($i + "([^0-9]|$)"))))' \
            >/dev/null 2>&1; then
        continue
    fi
    H=$(printf '%s' "$U" | jq -r '.header | if . == "" then "(no header)" else . end')
    MISSING="${MISSING:+$MISSING, }$H"
done < <(printf '%s' "$UNCOVERED" | jq -c '.[]')

[ -n "$MISSING" ] || allow

deny "AskUserQuestion refused by the advisor-first standing ruling (docket-run, 'Standing ruling: the advisor answers first'): no completed advisor review since the last operator answer names the question(s) ${MISSING}, and no run note records an advisor ruling for them. Launch the advisor with a brief that carries the drafted question and its options, take its pick as (Recommended), then ask; ask only when its answer is not clear. A recorded advisor ruling in a run note also satisfies this."
