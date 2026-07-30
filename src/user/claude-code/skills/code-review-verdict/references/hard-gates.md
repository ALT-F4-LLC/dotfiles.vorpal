# Hard Gates G1-G5 — full symptom patterns

Read before emitting any gate Blocker (or ruling one out on a borderline symptom). The
gates fire only on the objective, mechanically detectable symptom — judgment calls belong
in Concern-class findings under the dimension rubric.

| Gate | Symptom (what to look for in the diff) | Override marker |
|---|---|---|
| **G1 — Swallowed error** | A `catch`/`rescue`/`except` block with no rethrow AND no logged context AND no meaningful handling on a path that touches untrusted input, network, or persistence. Patterns: empty catch `{}`; `catch { /* ignore */ }`; discarded result (`_ = err`, `_, _ := ...` for an `error` return); `.unwrap()` / `.expect()` / a bare ! force-unwrap operator on data the function does not control. NOT fired by deliberate panics on programmer-error invariants where a clear stack is the right move. | `// OVERRIDE: code-philosophy/6 — <reason>` on or immediately above the catch/discard site |
| **G2 — Unguarded shared mutation** | Shared or module-global mutable state accessed without a lock, channel, actor, or single-owner pattern. NOT fired by `Mutex`/`RwLock`/atomic-guarded access, message-passing, single-owner goroutines/tasks, or local mutation inside a function whose result escapes as a new value. | `// OVERRIDE: code-philosophy/4 — <reason>` on the unguarded access |
| **G3 — Unparsed boundary input** | Untrusted input (HTTP body/query/header, env var, CLI arg, queue payload, DB row, third-party API response, file off disk) consumed without a schema parse into a precise type at first contact. NOT fired by data flowing through internal calls after it has been parsed once at the boundary. | `// OVERRIDE: code-philosophy/5 — <reason>` on the consumption site |
| **G4 — Surface-not-invariant patch** | Fix that papers over an edge case rather than addressing the underlying contract. Patterns: a `null` check added where the real bug is that upstream data is the wrong shape; a retry loop wrapped around a non-idempotent operation; defensive guards that mask a real invariant violation; a snapshot or test updated to make a failing case pass without diagnosing why. Detection requires reading the issue to understand what the code was supposed to *uphold* — flag when the diff looks like symptom-masking. | `// OVERRIDE: code-philosophy/11 — <reason>` on the affected block |
| **G5 — Unexecuted AC regex** | TDD/spec/AC diff introduces or modifies a regex intended to gate verification, with no evidence it was executed against the actual target files. Patterns: AC says match `Lifecycle:.*persistent name` but the target uses `**Lifecycle**:` (markdown-bold inserts `**` between word and colon); AC requires literal adjacency where the target has intervening words; expected hit count does not match actual `grep -lE` output; under `grep -E` a `\|` is a LITERAL pipe, so `'a\|b'` returns 0 on a correct file — the alternation must be bare `|` under `-E`. Detection: when a diff edits regex in `docs/tdd/` or `docs/spec/`, run `~/.claude/scripts/g5_check.sh <scope>` — it extracts every added backtick `grep`, executes each against the tree, and reports `[RAN <n> hits]` / `[FAIL]` / `[REJECTED]` / `[TIMEOUT]` per command plus a `[BRE-PIPE-WARNING]` static flag (exit 0 all clean, 1 a candidate failed/rejected/warned, 2 no candidates in scope). Any count mismatch, exit-1 line, or BRE-pipe warning is a Blocker. | `// OVERRIDE: code-philosophy/5 — <reason>` on the AC block (AC regex is the verification's parse contract) |

**Override recognition.** Before emitting a Blocker for any gate, scan the diff and the
immediately adjacent lines for an `OVERRIDE: code-philosophy/<id>` comment matching the
gate (any comment syntax — `//`, `#`, `--`, `;`). When present: no Blocker for that
occurrence; list the override verbatim under **Overrides Recognized** with file:line and
the reason text. The override is *surfaced*, not silently honored — the operator decides
whether the reason holds.

**Block means return-for-fix, not discard.** A gate-triggered Blocker names the file/line,
the gate (G1..G5), the symptom observed, and the required mitigation; the calling agent
routes it back for a fix pass and the diff returns for re-review. Hitting a hard gate is
the review system working — surface it loudly.
