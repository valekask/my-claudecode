# Performance Checklist

---

## Change Detection & Rendering

- [ ] **PF-1**: "Are method/getter calls used as bindings in templates?"
  → Check: Template interpolations and property bindings call functions or getters (`{{ compute() }}`, `[x]="getX()"`) that run on every change-detection cycle.
  → FAIL: A non-trivial function/getter is invoked from the template instead of a precomputed property, `async` pipe, or pure pipe.

- [ ] **PF-2**: "Do `*ngFor` loops over non-trivial lists declare a `trackBy`?"
  → Check: Each `*ngFor` (or `@for`) over a list that can change has a stable `trackBy` / `track` identity.
  → FAIL: A list that re-renders on updates has no `trackBy`, forcing full DOM teardown/rebuild on every change.

- [ ] **PF-3**: "Is `ChangeDetectionStrategy.OnPush` used where the component's inputs are immutable?"
  → Check: Presentational components driven purely by `@Input()` / observables use OnPush.
  → FAIL: A pure presentational component uses default change detection, re-rendering on every global CD tick.

- [ ] **PF-4**: "Are new object/array literals created in templates or input bindings on each cycle?"
  → Check: Bindings don't construct `[x]="{ ... }"` / `[items]="[...]"` / inline arrow functions that produce a new reference every cycle.
  → FAIL: A new reference is passed to a child on each CD run, defeating OnPush and triggering needless re-renders.

## Data & Network

- [ ] **PF-5**: "Are there redundant or N+1 HTTP calls?"
  → Check: Data isn't fetched in a loop per-item when a batch endpoint exists; the same resource isn't requested multiple times where one cached call suffices.
  → FAIL: A request fires per list item, or an identical request is repeated within the same flow without sharing/caching the result.

- [ ] **PF-6**: "Are high-frequency event streams debounced/throttled?"
  → Check: Input, scroll, resize, and typeahead streams use `debounceTime`/`throttleTime`/`auditTime` before triggering work (HTTP, heavy compute).
  → FAIL: Every keystroke/scroll event triggers an HTTP call or expensive computation with no rate limiting.

- [ ] **PF-7**: "Are observable results shared instead of re-subscribed?"
  → Check: A source consumed by multiple subscribers (or the template multiple times) uses `shareReplay`/`share` or a single `async` binding — not multiple independent subscriptions that each re-run the work.
  → FAIL: The same cold observable (e.g., an HTTP call) is subscribed multiple times, duplicating the underlying work.

## Computation

- [ ] **PF-8**: "Is expensive work memoized rather than recomputed?"
  → Check: Derived values (selectors, sorting, filtering, mapping large collections) are memoized (NgRx selectors, pure pipes, cached fields) instead of recomputed on each access.
  → FAIL: A costly transformation over a large collection runs on every access/render with no memoization.

- [ ] **PF-9**: "Are large lists virtualized or paginated?"
  → Check: Rendering of large collections uses virtual scroll (CDK) or pagination rather than rendering every row.
  → FAIL: Hundreds/thousands of rows are rendered into the DOM at once with no virtualization or paging.

- [ ] **PF-10**: "Is work done at the right altitude (not inside hot loops/cycles)?"
  → Check: Allocation, parsing, regex compilation, or date construction isn't repeated inside loops or per-cycle when it could be hoisted/precomputed once.
  → FAIL: Invariant work (e.g., building a lookup map, compiling a regex) is repeated on every iteration or every CD cycle.

## Loading & Bundle

- [ ] **PF-11**: "Are heavy/rarely-used features lazy-loaded?"
  → Check: New large routes/feature modules are lazy-loaded; heavy third-party libraries are loaded on demand, not eagerly in a shared bundle.
  → FAIL: A large feature or heavy dependency is added to an eagerly loaded path, inflating initial bundle/startup.

- [ ] **PF-12**: "Are subscriptions and timers cleaned up (no accumulating work)?"
  → Check: Long-lived subscriptions, `setInterval`/`setTimeout`, and listeners are torn down (`takeUntilDestroyed`, `DestroyRef`, `ngOnDestroy`) so work doesn't accumulate across navigations.
  → FAIL: A subscription/timer/listener is never cleaned up, leaking work that compounds each time the component is recreated.

---

Total items: 12
