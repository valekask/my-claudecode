---
name: whiteboard
description: Plan and design features with FNA-UI architecture patterns. Use when starting new features, designing solutions, or planning complex work.
---

# Whiteboard with Project Architecture

Before planning, understand these architectural constraints.

## Critical Constraints

- **Angular 17 WITHOUT Signals** - Plan for RxJS observables, not signals
- **Do NOT plan changes to**: `package.json`, `nx.json`, `environment.prod.ts`

## Monorepo Structure

```
apps/
  fna-ui/           # Main platform (port 4200)
  ilo-monitoring/   # ILO monitoring app
libs/
  dashboard/        # Dashboard features and data-access
  platform/         # Platform features (gremlin, reporting, simulations)
  navbar/           # Navigation components
  shared/           # Cross-cutting (core, auth, http, models)
  ui/               # Reusable presentational components
  utils/            # Pure utility functions
```

## Library Taxonomy (Where to Place Code)

| Type | Purpose | State? | Examples |
|------|---------|--------|----------|
| `feature-*` | Smart components, routing | Yes (NgRx, services) | feature-dashboard, feature-widgets |
| `data-access-*` | Services, NgRx state | Yes (`+state/` dir) | data-access-metadata, data-access-pages |
| `ui` | Presentational components | No (inputs/outputs only) | ui-components, ui-charts |
| `utils` | Pure functions | No | date-utils, format-utils |
| `shared` | Cross-cutting concerns | Minimal | auth, http interceptors |

## Component Architecture Pattern

Plan with **container/presentational split**:

**Container (feature-*):**
- Holds state (store subscriptions, services)
- Transforms data → view models
- Orchestrates business logic
- Translates events from presentational components

**Presentational (ui):**
- `@Input()` for data
- `@Output()` for events
- No NgRx, no business services
- May have local UI-only state

**Data Flow:**
```
DataService (fetch) → Store (state) → Container (orchestrate) → Presentational (display)
```

Planning questions:
- What data sources are needed? (APIs, local storage, user input)
- What transformations are needed? (API → domain → view model)

## State Management

**Selection Guide:**

| Scope | Solution | When |
|-------|----------|------|
| Feature/Component | ComponentStore | Default choice (preferred) |
| Cross-feature | Global NgRx Store | Shared state across unrelated features |
| Trivial | Plain service | Single observable, no complex transitions |

**NgRx Global Store** - Use `data-access-*` libs with `+state/` directory:
- Actions → what happened
- Reducers → how state changes
- Selectors → derived state
- Effects → side effects (HTTP, etc.)

**ComponentStore** - Use within feature components for local state.
Reference: `libs/dashboard/feature-graph/src/lib/graphs/sorted-list/services/graph-sorted-list.store.ts`

## Layering (Top to Bottom)

1. **Presentation** - Components, pipes, directives, view models
2. **Business Logic** - Container components, component services
3. **State Management** - NgRx store, actions, reducers, selectors, effects
4. **Data Access** - HTTP services, API clients
5. **Core** - Auth, security, interceptors

Higher layers depend on lower layers, not vice versa. Data flows up through these layers.

## Execute

Now proceed with `/code-foundations:whiteboarding`, applying architecture patterns above throughout planning.
