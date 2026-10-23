def bootstrap_candidate: .type == "user"
    and (.message.content | type == "string"
        and startswith("[Workflow harness — user request]") | not);
def bootstrap_text: .message.content | if type == "string" then . else tojson end;
def brief_head: sub("^\\[Workflow harness —[^\\n]*\\n"; "") | .[0:200];
def cast_join: if brief_head
        | contains("You are executing one step of a Docket run") then null
    else capture("(?:^|\\n|\\\\n)[ \\t]*(?:Cast with:[ \\t]*)?(?:cd\\s+\\S+\\s+&&\\s+)?docket vote cast\\s+(?<proposal>\\S+)\\s+--voter\\s+(?<voter>\\S+)") end;
[inputs | fromjson? | select(type == "object")] as $lines
| ([$lines[] | select(bootstrap_candidate)] | .[0]) as $first
| (if $first == null then null else ($first | bootstrap_text) end) as $boot
| ($boot // "") as $b
| (reduce ($lines[] | select(.type == "assistant") | .message
            | select((.usage // {}) != {} and (.id // "") != "")) as $m
        ({}; .[$m.id] = $m) | [.[]]) as $messages
| ([$lines[] | select(.type == "assistant")
            | select((.message.usage // {}) != {} and (.message.id // "") != "")
            | {model: .message.model, effort: .effort}]) as $served
| {
    bootstrap: ($boot != null),
    cast: (($b | cast_join) // null),
    record: (($b | capture("docket step (?:claim|record|complete)\\s+(?<step>STEP-\\d+)") | .step) // null),
    probe: ($b | (
        contains("WAVE PROBE: not a step execution")
        or contains("You are a DIAGNOSTIC PROBE inside a running Docket wave")
        or (contains("Run exactly this one command:") and contains("read-only probe reporting what the"))
        or test("Run exactly this one command:(?:\\\\n|\\s)+`?docket\\s+(?:[a-z-]+\\s+)?(?:show|context|list|tally|next|log)\\b"))),
    exec: ($b | contains("You are executing one step of a Docket run")),
    claim_agent: ($b | contains("WAVE CLAIM: not a step execution")),
    usage_join: ($b | brief_head | (contains("You are a read-only scout.") or contains("You are a read-only measurement relay for one transcript file."))),
    step_mention: (($b | [match("STEP-\\d+")][0].string) // null),
    reseat: ($b | contains("THIS IS A SECOND ATTEMPT AT YOUR SEAT")),
    tool_uses: ([$lines[] | select(.type == "assistant") | .message.content
                 | if type == "array"
                   then .[] | select(type == "object" and .type == "tool_use" and .name != "StructuredOutput") | .id // empty
                   else empty end]
                | unique | length),
    models_observed: ([$messages[].model | select(type == "string" and . != "" and . != "<synthetic>")] | unique),
    last_model: (($served | last | .model | select(type == "string" and . != "" and . != "<synthetic>")) // null),
    efforts_observed: ([$served[].effort | select(type == "string" and . != "")] | unique),
    model_observation_complete: ($messages | length > 0 and all(.[];
        (.model | type) == "string" and .model != "" and .model != "<synthetic>")),
    usage: (
        $messages | map(.usage)
        | {
            input_tokens:          (map(.input_tokens // 0) | add // 0),
            output_tokens:         (map(.output_tokens // 0) | add // 0),
            cache_creation_tokens: (map(.cache_creation_input_tokens // 0) | add // 0),
            cache_read_tokens:     (map(.cache_read_input_tokens // 0) | add // 0)
        })
  }
