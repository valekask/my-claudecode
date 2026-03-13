# Styling Checklist

Source: docs/STYLING.md, .coderabbit.yaml

---

## Design System Usage

- [ ] **ST-1**: "Are design system variables used instead of hardcoded values?"
  → Check: No hardcoded colors, font sizes, spacers, or border-radius that exist in `libs/ui/src/assets/scss/` (colours, spacings, vars, custom-bootstrap).
  → FAIL: `color: #6c757d` or `padding: 12px` when a design system variable or CSS variable exists for that value.

- [ ] **ST-2**: "Are CSS custom properties used for design tokens? Are utility classes used where possible?"
  → Check: Two rules:
    1. **CSS variables over hardcoded values or SCSS variables** for colors, spacing, typography — use `var(--name)` (e.g., `var(--primary)`, `var(--border-color)`). This project uses **unprefixed** CSS variables, NOT the Bootstrap `--bs-` prefix.
    2. **Bootstrap utility classes over custom CSS** for common patterns — if a Bootstrap utility exists (`d-flex`, `gap-2`, `text-center`), prefer it over writing custom SCSS.
  → FAIL: Hardcoded `color: #6c757d` or SCSS `$border-color` where `var(--border-color)` exists. Also FAIL if `--bs-` prefixed variables are used — use unprefixed versions.
  → EXCEPTION: SCSS variables are OK for build-time calculations, Sass maps/loops, and values that never change at runtime (breakpoints).

- [ ] **ST-3**: "Are Bootstrap 5 utility classes used instead of custom CSS where possible?"
  → Check: Common layout/spacing/display patterns use Bootstrap utilities (`d-flex`, `gap-2`, `mt-3`, `text-center`) rather than custom SCSS rules.
  → FAIL: Custom `.centered { display: flex; justify-content: center; }` when `d-flex justify-content-center` would suffice.

## Selectors & Specificity

- [ ] **ST-4**: "Are ID selectors avoided in component styles?"
  → Check: Module/component styles use class selectors only. ID selectors reduce reusability.
  → FAIL: `#main-panel { ... }` in a component SCSS file.

- [ ] **ST-5**: "Are element selectors avoided in component styles?"
  → Check: Component styles target classes, not bare elements like `div`, `span`, `p`.
  → FAIL: `div { padding: 10px; }` — use a class name instead.

- [ ] **ST-6**: "Is `!important` avoided?"
  → Check: No `!important` flags. They break the cascade and are difficult to override.
  → FAIL: `color: red !important;` — fix specificity or restructure selectors instead.

- [ ] **ST-7**: "Is selector depth minimal (≤3 levels)?"
  → Check: No deeply nested selectors that enforce dependency on HTML structure.
  → FAIL: `.container .content .sidebar .item .label { ... }` — flatten with meaningful class names.

## Bootstrap Deprecations

- [ ] **ST-8**: "Are deprecated Bootstrap 5 classes avoided in templates and SCSS?"
  → Check: No deprecated or removed Bootstrap classes in `.html` or `.scss` files. Common deprecated classes and their replacements:

  **v5.3 deprecations (removed in v6):**
  | Deprecated | Replacement |
  |---|---|
  | `.text-muted` | `.text-body-secondary` |
  | `.btn-close-white` | `data-bs-theme="dark"` on close button or parent |
  | `.dropdown-menu-dark` | `data-bs-theme="dark"` on dropdown or parent |
  | `.navbar-dark` | `data-bs-theme="dark"` on navbar |
  | `.carousel-dark` | `data-bs-theme="dark"` on carousel |

  **v5.0 renames (from Bootstrap 4):**
  | Deprecated | Replacement |
  |---|---|
  | `.float-left` / `.float-right` | `.float-start` / `.float-end` |
  | `.border-left` / `.border-right` | `.border-start` / `.border-end` |
  | `.rounded-left` / `.rounded-right` | `.rounded-start` / `.rounded-end` |
  | `.ml-*` / `.mr-*` | `.ms-*` / `.me-*` |
  | `.pl-*` / `.pr-*` | `.ps-*` / `.pe-*` |
  | `.sr-only` | `.visually-hidden` |
  | `.font-weight-*` | `.fw-*` |
  | `.font-italic` | `.fst-italic` |
  | `.text-monospace` | `.font-monospace` |
  | `.no-gutters` | `.g-0` |
  | `.btn-block` | `.d-grid` + `.gap-*` |
  | `.badge-pill` | `.rounded-pill` |
  | `.close` | `.btn-close` |
  | `.custom-control` / `.custom-checkbox` / `.custom-radio` | `.form-check` |
  | `.custom-switch` | `.form-check.form-switch` |
  | `.custom-select` | `.form-select` |

  → FAIL: Any deprecated class found in changed `.html` or `.scss` files. AI code generators frequently use `text-muted` and other deprecated classes.

## Structure & Organization

- [ ] **ST-9**: "Are CSS properties ordered correctly? (box → border → background → text → other)"
  → Check: Properties grouped by category: display/position/sizing first, then border, background, text, other.
  → FAIL: Properties in random order mixing `color` between `display` and `width`.

- [ ] **ST-10**: "Are state rules kept inside the module/component?"
  → Check: State classes (`.hidden`, `.disabled`, `.active`, `.expanded`) are scoped within the component, not defined globally.
  → FAIL: Global state class that leaks across components.

- [ ] **ST-11**: "Are class names semantic and following naming conventions?"
  → Check: Layout classes use standard names: `container`, `header`, `footer`, `content`, `sidebar`. Long class names may indicate the element should be its own component.
  → FAIL: `.div1`, `.blue-box`, `.style2` — use names that describe meaning, not appearance.

---

Total items: 11
