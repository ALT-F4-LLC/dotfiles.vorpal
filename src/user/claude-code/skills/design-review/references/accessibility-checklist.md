# Accessibility checklist — shared by design-review (spec-level) and design-qa (implementation-level)

Minimum bar; expand for the artifact's surface. Each row has two verbs: at spec time
(design-review) the artifact must SPECIFY the property; at QA time (design-qa) the reviewer
MEASURES it on the rendered output — token values alone prove neither.

| Check | Spec-level (design-review) | Implementation-level (design-qa) |
|---|---|---|
| **Color contrast** | Text and interactive-control contrast ratios specified to meet WCAG 2.2 AA (4.5:1 normal text, 3:1 large text/UI components); color never the sole indicator | Measure actual rendered contrast ratios (not token values); confirm color is not the sole indicator |
| **Keyboard navigability** | Every interactive element reachable and operable via keyboard alone; focus order matches visual/reading order and is visibly indicated; no keyboard traps | Drive every interactive element via keyboard; confirm focus order, visible focus, no traps |
| **Semantic / ARIA correctness** | Native semantic elements/roles specified before ARIA; ARIA roles/labels/live-regions correct and announcing state changes; heading/landmark structure supports screen-reader navigation | Inspect rendered markup/accessibility tree for correct semantics, accurate ARIA, and announced state changes |
| **Data-visualization output** | Each series encoded with a non-color channel (pattern, direct label, annotation) in addition to color; marks and axis/label text meet AA contrast; a color→series legend alone is insufficient | Measure rendered contrast of marks against background and between adjacent series; confirm categories stay distinguishable without hue |
| **Data-table semantics** | Tabular data specified as real table structure with associated row/column headers — never layout-only or ASCII-art tables a screen reader linearizes into unlabeled cells | Inspect the rendered markup/accessibility tree for genuine table structure (header cells, scope/association, caption); aligned divs or spaced text are screen-reader-hostile |

**Rendered-effect rule (visual surfaces).** The design must specify — and QA must verify —
the rendered EFFECT at real delivery resolution (screenshare, streamed video, small
viewport), not just the CSS/token value: a subtle cue that meets the token contract can fail
to read once compressed. Every color/visual cue pairs with a text fallback so a degraded
render still carries meaning.
