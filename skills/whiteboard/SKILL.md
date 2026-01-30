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

## State Management (NgRx)

Plan state in `data-access-*` libs with `+state/` directory:
- Actions → what happened
- Reducers → how state changes
- Selectors → derived state
- Effects → side effects (HTTP, etc.)

## Layering (Top to Bottom)

1. **Presentation** - Components, pipes, directives, view models
2. **Business Logic** - Container components, component services
3. **State Management** - NgRx store, actions, reducers, selectors, effects
4. **Data Access** - HTTP services, API clients
5. **Core** - Auth, security, interceptors

Higher layers depend on lower layers, not vice versa.

## Execute

Now proceed with `/code-foundations:whiteboarding`, applying architecture patterns above throughout planning.
