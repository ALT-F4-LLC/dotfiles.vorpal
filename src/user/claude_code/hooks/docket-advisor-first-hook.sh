#!/bin/bash

# Hold a docket-run conductor to the advisor-first standing ruling: every
# operator-bound question is reviewed by the advisor before it is asked.
#
# Runs before each AskUserQuestion call. In a session that conducts a live run
# (its own tool calls drive it: `docket next` or a run-moving `docket dispatch`
# verb with `--run RUN-N`, or the conductor token path, as docket-driven-runs.jq
# beside this hook tests it), a question is allowed only when, for each
# question in the call, either
#   (a) a completed advisor Agent launch since the last operator answer carries
#       a brief that names the question's header as a header ("header Scope"),
#       a step id in it, or its full text; or
#   (b) a run note of a run the session conducts records an advisor ruling for
#       a step id the question names.
# Otherwise the call is refused with the ruling's name, and the conductor
# launches the advisor and asks again. A launch with a non-error result counts
# as completed when the result is the report itself, or when a later transcript
# line carries its completion notice or hand-back.
#
# Sessions that conduct no run, subagents, a missing docket-driven-runs.jq, and
# any unreadable transcript, engine answer or payload are allowed. A run id held
# only in a shell variable is not recognized as driven, and the hook cannot
# judge whether the advisor's brief was sound, only that it named the question.

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

# The test of whether a call drives a run lives beside this hook, shared with
# the park-notice hook; without it nothing can be judged, so allow.
HOOK_DIR="${0%/*}"
[ "$HOOK_DIR" = "$0" ] && HOOK_DIR="."
DRIVES_DEF=$(cat "${HOOK_DIR}/docket-driven-runs.jq" 2>/dev/null) && [ -n "$DRIVES_DEF" ] || allow

# The runs this session's own tool calls drive. A malformed or partly written
# transcript line is skipped, never fatal.
CALLS=$(jq -Rc '(try fromjson catch null) | objects | select(.type == "assistant") | .message.content? | arrays | .[]
    | select(type == "object" and .type == "tool_use") | (.input.command? // (.input | tostring))' "$TRANSCRIPT" 2>/dev/null) || allow
DRIVEN=""
for R in $RUNS; do
    printf '%s\n' "$CALLS" | jq -e --arg r "$R" "$DRIVES_DEF"' select(drives($r))' >/dev/null 2>&1 \
        && DRIVEN="${DRIVEN:+$DRIVEN }$R"
done
[ -n "$DRIVEN" ] || allow

# (a) The questions no completed advisor brief since the last operator answer
# names. The transcript is streamed line by line, skipping malformed lines, and
# each line is cut down to the few fields the check reads before it is kept: a
# tool_use's id, name and advisor brief, a tool_result's head, and the task
# ids a completion notice or hand-back names. i is the transcript line number.
# An answer is a tool_result of an earlier AskUserQuestion that is not an error:
# this hook's own refusal, a classifier denial and any other hook error are
# written the same way and must not void the reviews before them. An operator's
# rejection of the call is an error result that still counts.
# A launch with a non-error result is complete when that result is the report
# itself, or when a later line carries its completion: a completed task notice
# (in a user line, a queued-command attachment or a queue-operation line) or a
# hand-back whose origin names it. Assistant text never counts, so a quoted id
# completes nothing.
# A brief names a question when it carries the question's full text, a step id
# in it, or its header introduced as one ("header CI row", "Header: CI row"),
# compared case-blind with punctuation and runs of spaces folded: a bare header
# word such as "scope" elsewhere in an unrelated brief covers nothing.
UNCOVERED=$(jq -Rnc --argjson qs "$QUESTIONS" '
    def text: if type == "string" then .
              elif type == "array" then map(select(type == "object" and .type == "text") | (.text // "")) | join("\n")
              else "" end;
    def done_ids($i): select(length > 0)
        | ( (select(contains("<status>completed</status>")) | scan("<task-id>([0-9A-Za-z]+)</task-id>") | {k: "done", i: $i, id: .[0]}),
            (scan("from=\"([0-9A-Za-z]+)\"") | {k: "done", i: $i, id: .[0]}) );
    def fold: " " + (ascii_downcase | gsub("[^a-z0-9]+"; " ") | sub("^ +"; "") | sub(" +$"; "")) + " ";
    [ inputs | input_line_number as $i | (try fromjson catch null) | objects | . as $l
      | if $l.type == "assistant" then
            $l.message.content? | arrays | .[] | select(type == "object" and .type == "tool_use")
            | {k: "use", i: $i, id, name,
               brief: (if .name == "Agent" and (.input.subagent_type? == "advisor") then (.input.prompt? // "" | tostring) else null end)}
        elif $l.type == "user" then
            ($l.message.content? | arrays | .[] | select(type == "object" and .type == "tool_result")
             | {k: "res", i: $i, tid: .tool_use_id, err: (.is_error == true), text: (.content | tostring | .[0:4000])}),
            (($l.message.content? | text), (if ($l.origin.handback? == true) then "from=\"" + ($l.origin.from // "") + "\"" else "" end) | done_ids($i))
        elif $l.type == "attachment" then ($l.attachment.prompt? | text | done_ids($i))
        elif $l.type == "queue-operation" then ($l.content? | text | done_ids($i))
        else empty end ] as $E
    | ($E | map(select(.k == "use"))) as $uses
    | ($E | map(select(.k == "res"))) as $results
    | ($E | map(select(.k == "done"))) as $completions
    | ($uses | map(select(.name == "AskUserQuestion") | .id)) as $ask
    | ([$results[] | select(.tid as $t | $ask | index($t))
        | select((.err | not) or (.text | test("The user doesn.t want to proceed|User rejected tool use|Tool use was rejected")))
        | .i] | max // -1) as $last
    | [ $uses[] | select(.brief != null and .i > $last)
        | . as $a
        | ($results | map(select(.tid == $a.id)) | first) as $r
        | select($r != null and ($r.err | not))
        | (if ($r.text | contains("Async agent launched")) then
             (($r.text | capture("agentId: (?<a>[0-9A-Za-z]+)")? | .a) as $aid
              | $aid != null and ($completions | any(.id == $aid and .i > $r.i)))
           else true end) as $done
        | select($done)
        | ($a.brief | fold) ] as $briefs
    | [ $qs[]
        | . as $q
        | (($q.header // "") | fold) as $h
        | (($q.question // "") | fold) as $text
        | ([ (($q.header // "") + " " + ($q.question // "")) | scan("STEP-[0-9]+") ] | unique) as $ids
        | select(($briefs | any(. as $b
                 | (($h != "  " and ($b | contains(" header" + $h)))
                    or ($text != "  " and ($b | contains($text)))
                    or ($ids | any(. as $id | $b | contains(" " + ($id | ascii_downcase | sub("-"; " ")) + " ")))))) | not)
        | {header: ($q.header // ""), ids: $ids} ]' "$TRANSCRIPT" 2>/dev/null) || allow
[ "$(printf '%s' "$UNCOVERED" | jq 'length' 2>/dev/null)" -gt 0 ] 2>/dev/null || allow

# (b) A run note recording an advisor ruling for the step. A note list the
# engine cannot answer allows, as any unreadable engine answer does.
NOTES=""
for R in $DRIVEN; do
    N=$(docket run note list "$R" --json 2>/dev/null | jq -ce '[.data.notes[]? | .text // ""]' 2>/dev/null) || allow
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
