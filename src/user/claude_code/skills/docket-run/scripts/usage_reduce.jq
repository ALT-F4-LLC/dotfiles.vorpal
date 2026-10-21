# usage_reduce.jq — the reduction half of usage_join.sh: partition a wave's
# agents, sum their usage per step (or per seat), and emit the back-fill rows.
#
# This is docket-workflow-usage.js's classify() and reduceRows() in jq,
# including its key unquoting. One deliberate difference: with no relay to
# misreport it, a transcript with no user message is filed as wave overhead at
# once, where the workflow rechecks first and files it so only on a repeat.
# Labels and error text are worded for this reader; the rows, overhead sums,
# skips and model observations are the workflow's. Seats sort by codepoint,
# the workflow by UTF-16 unit; seat names are ASCII slugs, so the two agree.
# tests/docket-run-usage-join.test.sh runs both over the same transcripts and
# diffs the rows byte for byte; change one and that test names the other.
#
# Run as: jq -s -f usage_reduce.jq --arg mode steps|seats --argjson exclude '[...]'
# Input: [{file, extract}], one per agent transcript in directory order, where
# extract is usage_extract.jq's object for that transcript.
# Output: {rows, overhead, skipped, errors, model_observations}, shaped as
# docket-workflow-usage.js returns them (the shape, not the label wording).

def units: ["input_tokens", "output_tokens", "cache_creation_tokens", "cache_read_tokens"];
def zero: {input_tokens: 0, output_tokens: 0, cache_creation_tokens: 0, cache_read_tokens: 0};
def add_usage($u): reduce units[] as $k (.; .[$k] += ($u[$k] // 0));
def mention($x): if $x.step_mention then ", mentions \($x.step_mention)" else "" end;

# One layer of surrounding quotes and the whitespace around it, as the
# workflow's unquote() strips from every key the ledger joins on.
def unquote: if type == "string"
  then gsub("^\\s+|\\s+$"; "") | sub("^\"(?<a>.*)\"$"; .a) | sub("^'(?<a>.*)'$"; .a) | gsub("^\\s+|\\s+$"; "")
  else . end;
def normalize_keys:
  (if (.record | type) == "string" then .record |= unquote else . end)
  | (if (.step_mention | type) == "string" then .step_mention |= unquote else . end)
  | (if (.cast | type) == "object" then .cast |= (.proposal |= unquote | .voter |= unquote) else . end);

# One agent's bucket. A usage-join agent is set aside first, then the three
# questions in the one order that cannot misfile a read: briefed to cast?
# briefed only to read? briefed to record? The first yes wins.
def classify($x; $mode; $file):
  (if ($x.cast | type) == "object" and (($x.cast.proposal // "") != "") and (($x.cast.voter // "") != "")
   then [$x.cast.proposal, $x.cast.voter] else null end) as $seat
  | if $mode == "seats" then
      if $seat == null then {bucket: "unattributed", key: null, label: $file}
      else {bucket: "row", key: $seat, label: ($seat | join("/"))} end
    elif $seat != null then
      {bucket: "seated", key: $seat, label: "\($file) (\($seat | join("/")))"}
    elif ($x.bootstrap | not) then
      # No relay to misreport it: a transcript with no user message has none.
      {bucket: "overhead", key: null, label: "no user message\(mention($x))"}
    elif $x.usage_join then
      if $x.record != null then
        {bucket: "error", key: null, label: "\($file): reads as a usage-join agent but names \($x.record | tojson)"}
      else {bucket: "overhead", key: null, usageJoin: true, label: "usage-join agent\(mention($x))"} end
    else
      ($x.probe and ($x.exec | not)) as $probe
      | (if $probe then null else $x.record end) as $record
      | if $record == null then
          if $x.exec then
            {bucket: "error", key: null, label: "\($file): opens as a step executor but names no `docket step claim/record STEP-N`: the bootstrap brief and the record join have drifted"}
          else
            {bucket: "overhead", key: null,
             label: "\(if $x.claim_agent then "claim agent" elif $probe then "read-only probe" else "not a wave agent" end)\(mention($x))"}
          end
        elif ($record | test("^STEP-[0-9]+$") | not) then
          {bucket: "error", key: null, label: "\($file): the record join returned \($record | tojson), not a STEP-N id"}
        else {bucket: "row", key: $record, label: $record} end
    end;

# The models and effort a transcript's own assistant turns record.
def model_ok: type == "string" and test("^[a-z0-9][a-z0-9.-]*$");
def observation($file; $x; $c; $mode):
  # Unquote first, so a quoted "<synthetic>" is skipped like a bare one.
  (($x.models_observed // []) | map(select(type == "string") | unquote | select(. != "" and . != "<synthetic>"))) as $relayed
  | ($relayed | map(unquote | select(model_ok))) as $named
  | ($named | unique) as $models
  | (($x.last_model | type) == "string" and $x.last_model != "") as $has_last
  | (if $has_last and ($x.last_model | unquote | model_ok) then ($x.last_model | unquote) else null end) as $last
  | (($x.efforts_observed // []) | map(select(type == "string" and . != "")) | unique) as $efforts
  | {
      file: $file,
      kind: (if $c.bucket == "overhead" then "overhead" elif $mode == "seats" then "seat" else "step" end),
      key: $c.key,
      models: $models,
      last_model: $last,
      complete: ($x.model_observation_complete == true and ($models | length) > 0
                 and (($relayed | length) - ($named | length)) == 0
                 and (($has_last and $last == null) | not)),
      source: "assistant.message.model",
      effort_source: "assistant.effort",
      effort_resolved: (if ($efforts | length) == 1 then $efforts[0] else "unknown" end)
    };

# The metadata a back-fill row carries: what one transcript proves, or null.
def served_metadata($o):
  if ($o.complete | not) or $o.last_model == null then null
  else {model_resolved: $o.last_model}
       + (if $o.effort_resolved != "unknown" then {effort_resolved: $o.effort_resolved} else {} end)
       + (if ($o.models | length) > 1 then {models_observed: $o.models} else {} end) end;


# Seats mode reads only the transcripts briefed to cast, as the workflow's
# scout selects them; every other agent is a steps-mode concern.
(if $mode == "seats" then map(select(.extract.cast != null)) else . end) as $inputs
| reduce $inputs[] as $in (
    {totals: {}, order: [], overhead: {agents: [], sums: zero}, skipped: [], errors: [],
     obs: [], silent: [], usage_join_agents: 0, lane_agents: 0};
    ($in.file) as $file | ($in.extract | normalize_keys) as $x
    | classify($x; $mode; $file) as $c
    | if $c.bucket == "error" then .errors += [$c.label]
      else
        (if $c.usageJoin then .usage_join_agents += 1
         elif $c.bucket == "row" or $c.bucket == "seated" then .lane_agents += 1 else . end)
        | if $c.bucket == "seated" or $c.bucket == "unattributed" then
            .skipped += [{file: $file, reason: $c.bucket, key: $c.key, label: $c.label}]
          else
            observation($file; $x; $c; $mode) as $o
            | .obs += [$o]
            | if $c.bucket == "overhead" then
                .overhead.agents += [{file: $file, label: $c.label}]
                | .overhead.sums |= add_usage($x.usage)
              else
                (if $mode == "seats" then $c.key[1] else $c.key end) as $name
                | (if $mode == "seats" then $c.key | join(" ") else $c.key end) as $id
                | if ($exclude | index($name)) != null then
                    .skipped += [{file: $file, reason: "excluded", key: $c.key, label: $c.label}]
                  elif (units | any(. as $u | ($x.usage[$u] // 0) > 0) | not) then
                    .silent += [{file: $file, id: $id, c: $c}]
                  else
                    (if .totals | has($id) then . else .order += [$id] | .totals[$id] = {key: $c.key, sums: zero, tool_uses: 0, files: 0, observation: null} end)
                    | .totals[$id].sums |= add_usage($x.usage)
                    | .totals[$id].tool_uses += (if ($x.tool_uses | type) == "number" and ($x.tool_uses | floor) == $x.tool_uses then $x.tool_uses else 0 end)
                    | .totals[$id].files += 1
                    | .totals[$id].observation = $o
                  end
              end
          end
      end)
# A directory of only usage-join agents is another join's workflow, not the lane.
| (if $mode == "steps" and .usage_join_agents > 0 and .lane_agents == 0 then
     .errors += ["lane mismatch: the directory holds \(.usage_join_agents) usage-join agent(s) (scout, extract) and no lane executor; it is a usage-join workflow directory, not the lane's. This run measured nothing for the lane and is not the lane's join: point the reader at the lane's own workflow directory"]
   else . end)
# A claimant with no usage is a dead spawn beside a live transcript for the same
# key, and an error alone: silence is not a zero row.
| . as $s
| reduce $s.silent[] as $q (.;
    if .totals | has($q.id) then .skipped += [{file: $q.file, reason: "dead-spawn", key: $q.c.key, label: $q.c.label}]
    else .errors += ["\($q.file) (\($q.c.label)): transcript carries no usage"] end)
| . as $s
| (if $mode == "seats" then [$s.order[] | $s.totals[.]] | sort_by([.key[0], .key[1]])
   else [$s.order[] | $s.totals[.]] | sort_by(.key | split("-")[1] | tonumber) end) as $sorted
| {
    rows: ($sorted | map(
        . as $t
        | if $mode == "seats" then
            [units[] as $u | {proposal: $t.key[0], voter: $t.key[1], unit: $u, quantity: $t.sums[$u]}]
            + [{proposal: $t.key[0], voter: $t.key[1], unit: "tool_uses", quantity: $t.tool_uses}]
          else
            [range(0; 4) as $i | units[$i] as $u
             | {step: $t.key, unit: $u, quantity: $t.sums[$u]}
               + (if $i == 0 and $t.files == 1 and served_metadata($t.observation) != null
                  then {metadata: served_metadata($t.observation)} else {} end)]
          end) | add // []),
    overhead: $s.overhead,
    skipped: $s.skipped,
    errors: $s.errors,
    model_observations: $s.obs
  }
