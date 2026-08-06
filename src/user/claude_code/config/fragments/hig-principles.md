---
fragment: hig-principles
version: 1
---
# Design principles and accessibility floors

The eight principles are Apple's, adopted by name from the Human Interface Guidelines
"Design principles" page (taglines verbatim). Cite them **by name**: "violates Familiarity
— the same concept is named two ways across surfaces" is checkable; "bad usability" is
not. A finding that names no principle is still reported — the principle grounds a
finding, it never gates raising one.

1. **Purpose** — "Make something meaningful." Every decision traces to what makes the
   product genuinely useful; the most important workflows are made truly great. A surface
   that cannot state what it is for fails this regardless of polish.
2. **Agency** — "Let people do things their own way." Get people directly to the task;
   do not lock them into flows or modes; make guided flows skippable. Build forgiveness
   in — actions reversible or recoverable, and recovery never costs someone their work.
3. **Responsibility** — "Act in people's best interest." Be transparent about what the
   product does and why; give a rationale when asking permission; collect only what is
   needed; anticipate misuse before it happens.
4. **Familiarity** — "Build on what people know." Draw on real-world and platform
   convention; once a behavior or appearance is established, apply it everywhere (same
   concept = same name). Show when controls are available and when content changes.
5. **Flexibility** — "Adapt to diverse contexts and needs." Accessibility is a priority
   from the start, multiple input methods are first-class, and every platform gets the
   same care — adaptation, never a port.
6. **Simplicity** — "Be clear and direct." Not minimalism: include just what is
   necessary, choose exactly the words needed, establish hierarchy so people know where
   they are and what comes next.
7. **Craft** — "Care about every detail." Deliberate decisions, precise wording, smooth
   motion; prototype, iterate, discard what does not work.
8. **Delight** — "Make it human." Name the emotion the surface should inspire; do not
   mistake delight for decoration — polish never gets in the way of the task.

**When principles conflict**, resolve in this order and write down which one won and why:
Purpose and Agency (does it serve the task) > Flexibility (the accessibility floor) >
Familiarity (consistency) > Simplicity > Craft and Delight. Polish never outranks
function.

## House floors — the checkable minimums

- **WCAG 2.2 AA is the floor.** Text and interactive-control contrast meets 4.5:1 for
  normal text, 3:1 for large text and UI components. Color is never the sole state
  indicator. Every interactive element is keyboard-reachable and operable, focus order
  matches reading order and is visibly indicated, and there are no keyboard traps.
  Native semantics come before ARIA; roles, labels, and live regions announce state
  changes. Tabular data uses real table structure with associated headers — aligned
  columns of text linearize into unlabeled cells. Each data series carries a non-color
  channel (pattern, direct label, annotation); a color-to-series legend alone is not
  enough.
- **Design for the error case first** — quality lives in error, empty, degraded, and
  overloaded states (Agency).
- **Design for the medium** — a pattern is adapted to a surface, never ported into it
  (Flexibility). CLI: command hierarchy, flag ergonomics, stdout for data and stderr for
  status. TUI: keyboard-first, NO_COLOR, an 80-column floor. Interfaces: resource
  modeling, error shapes, and pagination. Config: zero-config defaults, validation
  errors pointing at the exact line.
- **Feedback is mandatory** — every action produces an immediate visible response;
  silence is the worst outcome a surface can offer (Familiarity).

**Rendered effect, not token value.** For anything visual, the target is the effect at
real delivery resolution — compressed, streamed, or on a small viewport — not the CSS or
token value. A cue that satisfies the contrast contract on paper can fail to read once
compressed, so measure the render, and pair every color or visual cue with a text
fallback so a degraded render still carries meaning.
