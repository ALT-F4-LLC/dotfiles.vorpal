---
fragment: hig-principles
version: 5
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
