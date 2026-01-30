---
name: build
description: Implement features with FNA-UI project conventions. Use when building components, services, state management, or any Angular code.
---

# Build with Project Conventions

Before implementation, apply these project-specific rules.

## Critical Constraints

- **Angular 17 WITHOUT Signals** - Never use signal-based APIs. Use RxJS observables.
- **Do NOT modify**: `package.json`, `nx.json`, `environment.prod.ts`

## Library Placement

| Type | Location | Purpose |
|------|----------|---------|
| `feature-*` | Smart components | State, routing, business logic |
| `data-access-*` | Services, NgRx | HTTP clients, `+state/` directory |
| `ui` | Presentational | `@Input`/`@Output` only, no state deps |
| `utils` | Pure functions | No Angular dependencies |

## Component Architecture

**Container (feature-*):**
- Subscribe to store/services
- Transform data to view models
- Handle business logic orchestration

**Presentational (ui):**
- `@Input()` for data, `@Output()` for events
- No NgRx, no business services
- Local UI state only

## Naming Conventions

- Subscriptions: `subscribeOn...Changes` (e.g., `subscribeOnFilterChanges`)
- Booleans: `is`, `has`, `can`, `should` prefix (positive form)
- Actions: `get`, `set`, `fetch`, `remove`, `delete`, `reset`

## Method Ordering in Components

1. Lifecycle hooks (`ngOnInit`, `ngOnDestroy`)
2. Template event handlers (`onClick`, `onSubmit`)
3. Public orchestration methods
4. Private helpers (callers before callees)

## NgRx State

Place in `+state/` directory within `data-access-*` libs:
- `*.actions.ts`
- `*.reducer.ts`
- `*.selectors.ts`
- `*.effects.ts`

## File Organization

- **Flat structure** until folder reaches 7+ files
- Then create subdirectories: `models/`, `services/`, `components/`

## Testing

- Number test sections: `describe('1. user load', ...)`
- Number test cases: `it('1.1 should load user', ...)`
- Minimum: 1 happy path + 1 failure path for non-trivial logic
- Add tests in batches of 7-8 per iteration

## Code Quality

- **Max cyclomatic complexity: 15** - Keep functions simple, extract if needed

## Execute

Now proceed with `/code-foundations:building`, applying all rules above throughout implementation.
