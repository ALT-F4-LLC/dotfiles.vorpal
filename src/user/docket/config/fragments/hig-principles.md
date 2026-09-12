---
fragment: hig-principles
version: 4
---
# Design quality, principles, and accessibility floors

**Design quality is a first-class product requirement.** A functioning surface
with unresolved hierarchy, awkward interactions, or incoherent styling is
unfinished. Accessibility checks establish minimums, not excellent design.
Apply these requirements to the experience introduced or changed by the task,
with effort proportional to its scope.

## Principles

The eight names and quoted taglines below are Apple's, from the Human Interface
Guidelines [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
page. The operational interpretations and house requirements are ours.

1. **Purpose:** "Make something meaningful." Organize the experience around
   what people came to accomplish. Make the primary workflow excellent and the
   product's value understandable through its content and behavior.
2. **Agency:** "Let people do things their own way." Make optional guidance
   skippable, preserve work through failures, and support undo or recovery
   where possible. Make irreversible consequences clear before commitment.
3. **Responsibility:** "Act in people’s best interest." Explain permissions at
   the point of need, minimize data collection, protect people's information,
   and anticipate misuse.
4. **Familiarity:** "Build on what people know." Use recognizable platform and
   domain conventions. Keep concepts, names, and behaviors consistent, and
   make availability and changes understandable.
5. **Flexibility:** "Adapt to diverse contexts and needs." Design accessibility
   in from the start. Support the input methods, devices, and contexts
   relevant to the audience, with deliberate adaptation for each supported
   platform.
6. **Simplicity:** "Be clear and direct." Establish hierarchy, remove
   unnecessary decisions, and keep essential information and actions
   discoverable. Choose the words needed to understand and act.
7. **Craft:** "Care about every detail." Resolve typography, spacing,
   alignment, content density, imagery, motion, and wording into a coherent
   whole. Prototype and refine consequential design decisions.
8. **Delight:** "Make it human." Choose the feeling appropriate to the product
   and express it through the experience. Calm, confidence, and satisfying
   responsiveness can matter as much as playfulness.

**Resolve actual conflicts in context.** Accessibility floors and protections
for safety, privacy, and informed choice constrain every option. Among options
that meet them, prioritize the person's task and control, and weigh
consistency, clarity, craft, and emotional fit against that context. Record
material tradeoffs and their user consequences briefly.

## Make design decisions before expanding implementation

**Establish the direction.** For a new surface or substantial redesign, briefly
state the audience, primary task, first useful outcome, and intended
character. Inspect the existing product, design system, content, and
available references. Translate relevant references into specific choices
about hierarchy, layout, typography, density, color, imagery, and motion, and
describe how those choices fit this product; adjectives such as "modern" or
"premium" are insufficient.

**Explore uncertainty proportionally.** When a consequential design choice is
unsettled, compare plausible alternatives with small sketches or prototypes
before spreading the pattern. Choose based on the task, content, and audience,
and follow a settled direction for local changes. Make routine choices
yourself; keep assumptions visible when they materially affect the result.

**Compose the whole experience.** Establish the information hierarchy and path
from entry to useful completion before assembling components. Use scale,
grouping, spacing, and alignment to express importance and relationships, and
make the next useful action recognizable. Reuse the established design
system, and extend it coherently when the task requires it.

**Resolve a representative flow.** Use real wording and representative
content, including long labels, realistic data density, and sparse results.
Mark synthetic examples as such; do not invent product capabilities or
endorsements. Work through the primary action, its result, and consequential
loading, empty, error, degraded, and overloaded states before expanding the
pattern. Preserve input and provide supported recovery when an operation
fails.

## House floors: the checkable minimums

**Meet all applicable [WCAG 2.2](https://www.w3.org/TR/WCAG22/) Level A and AA
criteria for web content.** The reminders below are not an exhaustive
conformance checklist. For native software, use platform accessibility APIs
and [WCAG2ICT guidance](https://www.w3.org/TR/wcag2ict-22/) to apply relevant
requirements; WCAG2ICT is informative guidance, not a separate conformance
standard. Respect platform accessibility settings and, as a house
requirement, honor reduced-motion preferences for nonessential motion.

- **Contrast and meaning:** normal text meets 4.5:1; large text meets 3:1 (at
  least 18 pt, or 14 pt bold). Necessary non-text information identifying
  controls, states, and graphical objects meets 3:1 against adjacent colors.
  Apply the relevant WCAG exceptions. Color alone never carries information:
  use labels, shapes, patterns, or another understandable distinction.
- **Input and focus:** functionality is keyboard-operable, subject to WCAG's
  path-dependent-input exception, with visible focus and no keyboard traps.
  Focus order preserves meaning and operability, including the keyboard
  conventions within composite controls. Focused components are not entirely
  hidden by authored content. Pointer targets meet 24 by 24 CSS px or the
  criterion's spacing and other exceptions. Provide alternatives to dragging
  where required, and accessible authentication where applicable.
- **Semantics and feedback:** use native semantics first, and expose
  accessible names, roles, values, and states. Associate instructions and
  errors with their controls. Make relevant status messages available to
  assistive technology without moving focus, and avoid redundant live
  announcements. Use actual table structure and associated headers for
  tabular data on the web; use the platform equivalent elsewhere. Give
  informative images and charts appropriate text alternatives. Each chart
  series has a non-color identifier that remains understandable in the
  delivered view.
- **Adaptation:** text resizes to 200% without loss of content or
  functionality, subject to the criterion's exceptions. Ordinary vertically
  scrolling web content reflows at 320 CSS px; legitimately two-dimensional
  portions may retain two-dimensional layout. Keep controls and essential
  information usable across supported viewports, text settings, and themes.

**Feedback fits the action and medium.** Acknowledge input promptly and make
outcomes perceivable through the interface and its accessibility mechanisms.
The changed content or control state can provide the feedback. For delayed
work, distinguish pending, successful, and failed operations, and offer
cancellation where supported. Additional toasts and animations must serve a
useful purpose. Do not announce success before it is established.

**Adapt to the medium.** CLI: clear command hierarchy, discoverable flags,
stdout for result data, stderr for diagnostics and progress, and meaningful
exit status; quiet operation can use exit status as its feedback. TUI:
keyboard operation, `NO_COLOR` support, and usability at 80 columns. Test
terminal experiences with their intended terminal and assistive technology.
APIs: coherent resources, predictable errors, and pagination where needed.
Config: useful defaults and validation errors identifying the offending file
and key, plus line and column when available.

## Verify the delivered experience

**Measure contrast and inspect the render.** Use WCAG's specified contrast
method with the effective foreground and background colors, accounting for
opacity and backgrounds; do not substitute antialiased screenshot pixels for
text-contrast measurement. Also inspect the result at actual delivery size
and expected viewport, theme, and compression. Preserve essential meaning
through accessible text alternatives and non-color cues when a render
degrades.

**Evaluate what was built.** For visual changes, inspect actual rendered
views and operate the affected flow. Check the whole composition, reading
order, primary action, content extremes, and consequential states against
the chosen direction. Select automated and manual accessibility checks
according to the affected behavior and risk, including keyboard,
assistive-technology, resize, and reflow checks where relevant. Fix observed
defects and inspect the affected result again. A build, screenshot, or
automated scan alone does not establish usability or accessibility.

**Make findings and completion claims checkable.** State the surface and
state, the observed problem, and its effect on the person. Name the
applicable principle when one fits; a missing principle never suppresses a
finding, and a principle name alone never substantiates one. Distinguish
observed defects, design judgments, and hypotheses requiring user evidence.
Report what was actually inspected and any remaining gaps. If rendering or
interaction was unavailable, identify what remains unverified. Do not claim
user validation or improved adoption without supporting evidence.
