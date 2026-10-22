# docket-driven-runs.jq -- the one test of whether a session drives a run,
# shared by docket-park-notice-hook.sh and docket-advisor-first-hook.sh.
#
# Input: the text of one of the session's own tool calls (a Bash command, or
# another tool's input as a string). drives($r) is true when that call drives
# run $r: it names the run's conductor token path, or it runs `docket next` or
# a dispatch verb that moves the run (open, extend, close, abandon,
# waive-target) with `--run $r`. A read-only call (`docket dispatch verify`,
# `docket events list --run ...`) never counts, nor does a run id in prose.
def drives($r):
    test("conductor\\.d/" + $r + "([^0-9]|$)")
    or test("docket(\\s+-\\S+)*\\s+(next|dispatch\\s+(open|extend|close|abandon|waive-target))([\\s=][^\\n|;&]*)?\\s--run[ =]" + $r + "([^0-9]|$)");
