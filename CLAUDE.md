# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FNA-UI is an Angular 17 monorepo built with Nx workspace. It provides a financial network analysis platform with multiple applications and shared libraries. The codebase uses **Angular 17 WITHOUT Signals** - do not use signal-based APIs.

## Git Restrictions (MANDATORY)

**NEVER perform git write operations.** The user prefers to manually review all changes before committing.

Forbidden operations:
- `git commit` - NEVER commit changes
- `git add` - NEVER stage files
- `git push` - NEVER push to remote
- `git checkout` - NEVER switch branches or discard changes
- `git reset` - NEVER reset commits
- `git revert` - NEVER revert commits
- `git merge` - NEVER merge branches
- `git rebase` - NEVER rebase branches
- `git stash` - NEVER stash changes

**Allowed git operations** (read-only):
- `git status`, `git log`, `git diff`, `git branch`, `git show`, `git ls-tree`, `git merge-base`, `git rev-parse`

If a skill or plugin requests a commit, **refuse and inform the user** that manual review is required first.

## WIP (Work In Progress)

`.claude/WIP.md` tracks the current large task being worked on. It helps restore context at session start and handoff work between sessions or team members.

**Commands:**
- "wip" / "load wip" → Read `.claude/WIP.md` and summarize current status and next steps
- "save wip" → Update `.claude/WIP.md` with current progress summary so work can continue later

## Core Technologies

- **Angular 17.3.9** (NO Signals)
- **Nx 19.0.5** for monorepo management
- **NgRx 17** for state management (Store, Effects, Entity, Component Store)
- **TypeScript 5.4.5**
- **RxJS 7.8.1** for reactive programming
- **Bootstrap 5.3.3** with custom SCSS
- **AG-Grid 32** for data tables
- **D3.js 7** for visualizations
- **Karma + Jasmine** for testing

## Commands

### Development
```bash
# Serve applications
nx serve fna-ui              # Main platform app on http://localhost:4200
nx serve ilo-monitoring      # ILO monitoring app
```

### Build and test commands
- Check `tsconfig.base.json` file and path section to see project names and locations.
- Check `README.md` for other build and test commands.

Main commands:
```bash
# Run single project tests
nx test <project> --no-watch --reporters=dots

# Run specific test
nx test <project> --no-watch --reporters=dots --include='**/filename.spec.ts'

# Run a specific test suite or test case (within a file)
nx test <project> --no-watch --reporters=dots --grep='outlier indicators'

# Check TypeScript compilation
npx tsc --noEmit -p path/tsconfig.lib.json
```

<!-- OPENSPEC:START -->
## OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

## Code Foundations Skills

Use code-foundations skills proactively when working on features. These skills provide structured workflows that improve code quality.

### When to Use Each Skill

| Trigger | Skill | Purpose |
|---------|-------|---------|
| Starting a new feature or complex task | `/code-foundations:whiteboarding` | Plan implementation before coding |
| Implementing a whiteboard plan | `/code-foundations:building` | Execute plans with checklist tracking |
| Quick proof-of-concept needed | `/code-foundations:prototype` | Validate ideas with minimal code |
| TDD workflow | `/code-foundations:hack` | Write test → pass → refactor → repeat |
| Debugging any bug or error | `/code-foundations:cc-debugging` | Systematic debugging approach |
| Refactoring existing code | `/code-foundations:cc-refactoring-guidance` | Safe refactoring patterns |
| Performance issues | `/code-foundations:cc-performance-tuning` | Measure-first optimization |
| Reviewing changes before commit | `/code-foundations:review-commit` | Quick sanity check |
| Reviewing PR or larger changes | `/code-foundations:review-pr` | Comprehensive review |

### Mandatory Usage

**Always use code-foundations skills when:**
- Implementing new features (use whiteboarding → building)
- Fixing non-trivial bugs (use cc-debugging)
- Refactoring code (use cc-refactoring-guidance)
- Optimizing performance (use cc-performance-tuning)
- Creating PRs (use review-pr or review-changes)

**Do NOT skip these skills** - they ensure consistent quality and prevent rework.

## Architecture

### Monorepo Structure

```
apps/
  fna-ui/           # Main platform application
  ilo-monitoring/   # ILO monitoring application
libs/
  dashboard/        # Dashboard-related feature and data-access libs
  platform/         # Platform-level features (gremlin, reporting, simulations)
  navbar/           # Navigation bar components
  shared/           # Shared libs (core, auth, http, models, storage, options)
  ui/               # Reusable UI components library
  utils/            # Utility functions
```

### Library Taxonomy

Libraries follow Nx conventions with specific prefixes:
- **`feature-*`**: Smart components with routing, state management, and business logic
- **`data-access-*`**: Services, NgRx state (+state directory), HTTP clients
- **`ui`**: Presentational/dumb components only
- **`utils`**: Pure utility functions
- **`shared`**: Cross-cutting concerns (auth, http interceptors, models)

### Component Architecture Pattern

The codebase follows a **strict container/presentational split**:

**Container Components:**
- Hold state (subscribe to store, services)
- Transform data into view models for presentational components
- Handle business logic orchestration
- Translate events from presentational components
- Located in `feature-*` libs

**Presentational Components:**
- Receive data via `@Input()` only
- Emit events via `@Output()` only
- No direct state management dependencies (no NgRx, no services with business logic)
- May have local UI-only state
- Located in `ui` libs or nested within features

**Component-Specific Services:**
- Encapsulate business logic outside of components
- Transform data models to view models
- Validation, calculations, data manipulation
- Should NOT directly know about NgRx store
- Provided at component level when possible (not root)

### State Management (NgRx)

- **Actions**: `libs/<domain>/data-access-*/src/lib/+state/*.actions.ts`
- **Reducers**: `libs/<domain>/data-access-*/src/lib/+state/*.reducer.ts`
- **Selectors**: `libs/<domain>/data-access-*/src/lib/+state/*.selectors.ts`
- **Effects**: `libs/<domain>/data-access-*/src/lib/+state/*.effects.ts`

State is organized by domain (e.g., `dashboard/data-access-metadata`, `dashboard/data-access-pages`, `dashboard/data-access-selection`).

### Layering

Code is organized into logical layers (top to bottom):
1. **Presentation**: Presentational components, pipes, directives, view models
2. **Business Logic**: Container components, component-specific services, data models
3. **State Management**: NgRx store, actions, reducers, selectors, effects
4. **Data Access**: HTTP services, API clients
5. **Core**: Auth, security, HTTP interceptors, session management

**Rule**: Higher layers can depend on lower layers, but not vice versa.

### File Organization Within a Library

- **Flat structure** until a folder reaches 7+ files
- Once threshold reached, create subdirectories for `models/`, `services/`, `components/`
- Larger features: group related components in folders with their own `shared/` directory for local models/services

Example:
```
libs/feature-widgets/
  src/lib/
    small/
      models/
      services/
      settings/
      small-widget.component.ts
      small-widget.component.html
    large/
      +state/
      header/
      footer/
      widget/
      shared/
        models/
        services/
      large-widget.component.ts
```

## Code Style Requirements

### Language & Conventions
- **US English only**: `color` not `colour`, `initialize` not `initialise`
- **No Angular Signals**: This project uses Angular 17 without signals
- Use RxJS observables for reactive patterns
- **End of line**: Use `LF` (Unix-style line endings) as specified in `.editorconfig`

### Naming (A/HC/LC Pattern)
- Functions: `prefix? + action + HighContext + LowContext?`
    - Examples: `getUserMessages`, `onClickOutside`, `shouldDisplayMessage`
- Booleans: Use positive form with `is`, `has`, `can`, `should`, `will` prefixes
    - Good: `isConnected`, `hasData`, `canClose`
    - Bad: `isDisconnected`, `empty`, `disabled` (as boolean names)
- Data or store subscription methods: `subscribeOn...Changes`
    - Examples: `subscribeOnFilterChanges`, `subscribeOnSelectionChanges`, `subscribeOnStatusChanges`
- No abbreviations: `onItemClick` not `onItmClk`
- Action verbs: `get`, `set`, `fetch`, `remove`, `delete`, `compose`, `convert`, `reset`

### Method Ordering in Components
Methods must be ordered as follows (callers above callees):
1. Public lifecycle hooks (`ngOnInit`, `ngOnDestroy`, etc.)
2. Template event handlers (e.g., `onClick`, `onSubmit`)
3. Public orchestration methods
4. Private helper methods (caller methods should appear before called methods)

### Abstraction Levels
- **One level of abstraction per function**
- Do not mix HTTP calls + data mapping + UI updates in a single method
- Extract complex logic into private methods or services

### Testing
- Test sections must be numbered: `describe('1. user load', ...)`
- Test names must be numbered: `it('1.1 should load user when ID is valid', ...)`
- Focus on main cases first (happy path + failure path), then edge cases
- Non-trivial logic requires at least 1 happy path test + 1 failure test
- Add tests in batches of 7-8 per iteration, so they are easy to execute and review

### ESLint Rules Enforced
- **Complexity limit**: Max cyclomatic complexity of 15
- **Consistent return**: Functions must consistently return values
- **Member ordering**: Static before instance, public before private
- **Module boundaries**: `@nrwl/nx/enforce-module-boundaries` enforced

## Development Constraints

### What NOT to Change (without explicit request)
- `package.json`
- `nx.json`
- `environment.prod.ts`
- Git config or hooks

### What to Always Check
- No hardcoded secrets, API keys, or URLs (use `environment.ts` or `EnvironmentConfigService`)
- No commented-out code or unused imports
- Build passes: `nx build <project>`
- Tests pass: `nx test <project> --no-watch --reporters=dots`
- Backward compatibility maintained (public APIs, interfaces, routes unchanged)

### Security
- Avoid XSS, SQL injection, command injection, and OWASP Top 10 vulnerabilities
- Use DomSanitizer for dynamic content
- Validate input at system boundaries only (user input, external APIs)

### Scope of Changes
- **Change ONLY the requested feature/module**
- No drive-by refactoring or "improvements" outside the scope
- Do not add unnecessary abstractions, error handling for impossible scenarios, or feature flags
- Remove unused code completely (no `_vars`, `// removed` comments)

## Pre-Review Checklist

Before proposing changes to human review, verify:

- **Scope contained**: Only intended feature/module changed; no drive-by edits.
- **No hardcoded secrets**: Use `environment.ts` or `EnvironmentConfigService`.
- **Tests included**: Non-trivial functionality covered (≥1 happy path + 1 fail path; numbered).
- **Dead code removed**: Unused vars, commented blocks, temp logging.
- **Build passes**: `nx build <project>` succeeds.

## Regression Prevention

After making changes, verify no existing functionality broken:

- **Tests green**: `nx test <project> --no-watch --reporters=dots` passes (yours + existing).
- **Backward compatibility**: Public exports, interfaces, routes, inputs unchanged or intentionally versioned.
- **Critical paths functional**: Verify key flows outside change scope remain operational (login, navigation, data loading).

If any check fails → revise before human review.

## Git Workflow

### Branch Naming
Format: `(<type>/)<TICKET-NUMBER>(-<scope>)-subject`

Examples:
```
FNA-1234-simulator-feat
FNA-1234-timeline-hover-bug
hotfix/FNA-1234-editor-scripting-bug
release/FNA-9272-20.1.1
```

### Branch
- Main branch: `FNA-14222-ilo-monitoring-2.0---porting-dashboards`

## Additional Documentation

Refer to these files in the `docs/` directory for more details:
- `ARCHITECTURE.md` - Detailed architecture patterns
- `STRUCTURE.md` - File and directory organization
- `NAMING.md` - Comprehensive naming conventions
- `STYLING.md` - CSS/SCSS guidelines
- `CONTRIBUTING.md` - Git workflow and PR process
- `CHECKLIST.md` - Pre-deployment checklist
- `CLEAN_CODE.md` - DRY, SRP, SOLID, KISS principles with examples

### Documentation Conflict Resolution

When guidance conflicts between documents, follow this precedence (highest first):
1. `docs/CLEAN_CODE.md`
2. `docs/ARCHITECTURE.md`
3. `docs/STRUCTURE.md`
4. `docs/NAMING.md`
5. `docs/STYLING.md`
6. `README.md`
7. `.claude/CLAUDE.md` (this file)

If ambiguity remains, raise a note in review.

### License Headers
License headers are added only to TypeScript (.ts) files.

Maven commands for managing copyright headers:
```bash
mvn license:update-file-header  # Add/update headers to .ts files
```
