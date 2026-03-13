# State Management Checklist

Source: old-review-prompts/review-state-management.prompt.md, docs/ARCHITECTURE.md §4

---

## Store Selection

- [ ] **SM-1**: "Is ComponentStore used for feature state, Global Store only for cross-feature?"
  → Check: If state doesn't survive component destruction → ComponentStore. If state is shared across multiple unrelated features or persists across navigation → Global Store. For trivial single-observable cases → plain service.
  → FAIL: Global Store used for state that only one component needs (overengineered). Or complex feature state managed without any store (underengineered).

- [ ] **SM-2**: "Is global data minimized?"
  → Check: Count items in the global NgRx store. Each should have a clear justification for being global.
  → FAIL: Store contains state that is only consumed by one feature — should be a ComponentStore instead.

## ComponentStore Pattern

- [ ] **SM-3**: "Does ComponentStore have explicit state class with all properties at top?"
  → Check: State shape is defined in a dedicated class/interface at the top of the file with all properties visible.
  → FAIL: State properties are ad-hoc, scattered, or not typed. No single place to see the complete state shape.

- [ ] **SM-4**: "Are selectors defined for each state slice?"
  → Check: Each state property has a corresponding `select()` call exposed as a public observable.
  → FAIL: Components access store state directly or inline `this.select(s => s.property)` in multiple places instead of a reusable selector.

- [ ] **SM-5**: "Are effects handling API calls with loading/error state?"
  → Check: Effects set `loading: true` before API call, `loading: false` + data on success, `error: true` on failure.
  → FAIL: API call in effect without loading state management, or error silently swallowed.

- [ ] **SM-6**: "Are all UI states handled: loading, empty, error, data?"
  → Check: Template has branches for all 4 states. A selector like `emptyState$` computes the current state from `data$`, `loading$`, `error$`.
  → FAIL: Only the happy path (data present) is handled. Missing loading spinner, error message, or empty state display.

## NgRx Global Store

- [ ] **SM-7**: "Are actions named `[Source] Event` format (not imperative commands)?"
  → Check: Actions describe what happened, not what to do. Good: `[User API] Load Users Success`. Bad: `[User] Update User`.
  → FAIL: Action names are imperative (`SET_DATA`, `UPDATE_STATE`) or generic (`UPDATE`).

- [ ] **SM-8**: "Are reducers pure functions (no HTTP, DOM, Date.now(), side effects)?"
  → Check: Reducer function body contains only state transformations using spread operators. No API calls, no DOM access, no `new Date()`.
  → FAIL: Reducer dispatches actions, makes async calls, accesses `window`/`document`, or uses `Date.now()`.

- [ ] **SM-9**: "Are there direct state mutations (push/splice instead of spread)?"
  → Search: Look for `.push()`, `.splice()`, `.sort()` (mutating), direct property assignment on state objects.
  → FAIL: `state.users.push(newUser)` instead of `{ ...state, users: [...state.users, newUser] }`.

## Effects & Operators

- [ ] **SM-10**: "Do effects use the correct flattening operator?"
  → Check: `switchMap` for search/navigation (cancels previous — ok to lose). `concatMap` for writes/saves (queues — order matters). `mergeMap` for independent fire-and-forget (parallel — no dependency).
  → FAIL: `switchMap` used for save/write operations — can silently cancel and lose user data.

- [ ] **SM-11**: "Do effects have `catchError` returning error actions?"
  → Check: Every effect with an API call has a `catchError` that returns an error action and keeps the effect stream alive.
  → FAIL: Missing `catchError` (unhandled rejection crashes the effect stream) or `catchError` without returning an action.

- [ ] **SM-12**: "Does catchError handle the error before completing the stream?"
  → Check: Every `catchError` in effects processes the error (log, notification, state update) before returning. Returning `EMPTY` is fine IF the error is handled first.
  → PASS: `catchError(err => { this.notificationService.showError(err); return EMPTY; })` — error handled, stream completes intentionally.
  → FAIL: `catchError(() => EMPTY)` or `catchError(() => of(null))` with no error handling — silently swallows the error.

## Selectors

- [ ] **SM-13**: "Are selectors memoized via createSelector (not manual functions)?"
  → Check: Derived state uses `createSelector` (global store) or `this.select()` with combiner (ComponentStore).
  → FAIL: Component computes derived state manually by calling a function on every change detection: `get filteredItems() { return this.items.filter(...); }`.

- [ ] **SM-14**: "Is there logic in components that belongs in selectors?"
  → Check: Components don't transform store data before using it in templates.
  → FAIL: Component subscribes to store, then filters/maps/transforms the data in the component class. Move transformation to a selector.

---

Total items: 14
