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
- Use **ComponentStore** to manage and **update** state

**Presentational (ui):**
- `@Input()` for data, `@Output()` for events
- No NgRx, no business services
- **Read state only** - never update state directly, emit events instead

## Data Flow (Data-Driven Approach)

Follow this flow - code should work around the data:

```
DataService (fetch) → Store (state) → Container (orchestrate) → Presentational (display)
```

**State Management Selection:**

| Scope | Solution | When |
|-------|----------|------|
| Feature/Component | ComponentStore | Default choice (preferred) |
| Cross-feature | Global NgRx Store | Shared state across unrelated features |
| Trivial | Plain service | Single observable, no complex transitions |

**ComponentStore Pattern** (see `libs/dashboard/feature-graph/src/lib/graphs/sorted-list/services/graph-sorted-list.store.ts`):

1. Explicit state class at top with all properties
2. Selectors for each state slice (`readonly data$ = this.select(...)`)
3. Derived selectors for complex UI logic (`emptyState$`, `isValid$`)
4. Updaters for state mutations
5. Effects for side effects (API calls with loading/error handling)
6. Handle all UI states: loading, empty (no data), error, data

**Data Transformation Location:**

| Transform | Where |
|-----------|-------|
| API response → domain model | Effect or DataService |
| Domain model → view model | Selector |
| User input → API request | Container or Updater |

## Reactive Patterns

- **Avoid `ngOnChanges`** - Use RxJS observables with `setter + subject` pattern instead:
  ```typescript
  private readonly inputValue$ = new BehaviorSubject<string>('');
  @Input() set value(v: string) { this.inputValue$.next(v); }
  ```
- **Use ComponentStore** for complex component state instead of manual state management
- Prefer declarative streams over imperative lifecycle hooks
- **Avoid getters in templates** - runs on every change detection. Use component state or pipes instead (simple getters are acceptable)

## Styling

- **Prefer CSS variables** over SCSS variables for colors, spacing, typography (see `docs/STYLING.md`)

## Naming Conventions

- Subscriptions: `subscribeOn...Changes` (e.g., `subscribeOnFilterChanges`)
- Booleans: `is`, `has`, `can`, `should` prefix (positive form)
- Actions: `get`, `set`, `fetch`, `remove`, `delete`, `reset`

## Control Flow

- **Guard clauses** - Fail fast with early returns to reduce nesting

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
