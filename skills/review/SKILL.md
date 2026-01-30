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

Now proceed with `/code-foundations:review-changes`, applying all checks above.

For comprehensive PR review, use `/code-foundations:review-pr` instead.
