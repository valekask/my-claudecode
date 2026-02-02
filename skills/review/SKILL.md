---
name: review
description: Review code changes before PR with FNA-UI quality standards. Use when ready to review changes, before creating PR, or for quality checks.
---

# Review with Project Standards

Apply these project-specific checks during review.

## Pre-Review Checklist

- [ ] **Scope contained** - Only intended feature/module changed; no drive-by edits
- [ ] **No hardcoded secrets** - Uses `environment.ts` or `EnvironmentConfigService`
- [ ] **Tests included** - Non-trivial functionality covered (1 happy + 1 fail minimum)
- [ ] **Tests numbered** - `describe('1. ...')`, `it('1.1 ...')`
- [ ] **Dead code removed** - No unused vars, commented blocks, temp logging
- [ ] **No Signals** - Angular 17 without signal-based APIs
- [ ] **Protected files unchanged** - `package.json`, `nx.json`, `environment.prod.ts`

## Regression Prevention

- [ ] **Tests pass** - `nx test <project> --no-watch --reporters=dots`
- [ ] **Build passes** - `nx build <project>`
- [ ] **Backward compatible** - Public exports, interfaces, routes unchanged (or intentional)
- [ ] **Critical paths work** - Login, navigation, data loading unaffected

## Architecture Compliance

- [ ] **Library taxonomy** - Code in correct lib type (feature-*, data-access-*, ui)
- [ ] **Container/Presentational split** - Smart components in feature, dumb in ui
- [ ] **NgRx in +state/** - State management in correct directory
- [ ] **Layering respected** - No upward dependencies

## Data Flow (Data-Driven Approach)

Verify clear data flow: `DataService → Store → Container → Presentational`

- [ ] **Data source traceable** - Can identify which DataService fetches the data
- [ ] **Appropriate state management** - ComponentStore for feature state (preferred), Global Store only for cross-feature
- [ ] **Single source of truth** - No duplicate state across components
- [ ] **Unidirectional flow** - Data down via @Input, events up via @Output

**ComponentStore Quality** (if applicable):

- [ ] Explicit state class with all properties at top
- [ ] Selectors for each state slice
- [ ] Derived state computed in selectors (not template logic)
- [ ] Effects handle API calls with loading/error state
- [ ] Proper error handling in effects

**Anti-patterns to Flag:**

| Pattern | Severity | Fix |
|---------|----------|-----|
| State in presentational component | High | Move to container/store |
| Direct API call in component | High | Use DataService + Store |
| Manual subscription without cleanup | High | Use async pipe or takeUntilDestroyed |
| Complex logic in template | Medium | Move to selector |
| ngOnChanges for derived state | Medium | Use reactive selector |
| Multiple sources of truth | High | Consolidate to single store |

Reference: `docs/ARCHITECTURE.md` Section 4, example: `libs/dashboard/feature-graph/src/lib/graphs/sorted-list/services/graph-sorted-list.store.ts`

## Styling

- [ ] **CSS variables preferred** - Using `var(--*)` instead of SCSS `$variables` for colors, spacing, typography

## Naming Conventions

- [ ] **Subscriptions** - `subscribeOn...Changes` pattern
- [ ] **Booleans** - `is`, `has`, `can`, `should` prefix (positive form)
- [ ] **No abbreviations** - `onItemClick` not `onItmClk`

## Method Ordering

- [ ] Lifecycle hooks first
- [ ] Template event handlers second
- [ ] Public methods third
- [ ] Private helpers last (callers before callees)

## Security

- [ ] No XSS vulnerabilities (use DomSanitizer for dynamic content)
- [ ] No injection flaws
- [ ] Input validation at system boundaries

## Code Quality

- [ ] **Cyclomatic complexity ≤ 15** - Functions not overly complex

## Branch Naming

Format: `(<type>/)<TICKET-NUMBER>(-<scope>)-subject`
Examples: `FNA-1234-simulator-feat`, `hotfix/FNA-1234-editor-bug`

## License Headers

- [ ] New `.ts` files have license headers
- Run `mvn license:update-file-header` if needed

## Additional Documentation

For detailed guidance, consult: `docs/ARCHITECTURE.md`, `docs/NAMING.md`, `docs/STYLING.md`, `docs/CLEAN_CODE.md`

## Execute

Now proceed with `/code-foundations:review`, applying all checks above.
