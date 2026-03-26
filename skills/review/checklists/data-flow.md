# Data Flow Checklist

---

## Data Flow Direction

- [ ] **DF-1**: "Is the data source traceable — can you identify which DataService fetches the data?"
  → Check: Starting from the template, trace data back: template ← container ← store/service ← DataService ← API.
  → FAIL: Data origin is unclear, comes from multiple uncoordinated sources, or the chain is broken.

- [ ] **DF-2**: "Does data flow follow DataService → Store → Container → Presentational?"
  → Check: Data is fetched in a DataService, stored/transformed in a store, passed to container via selectors, passed to presentational via @Input.
  → FAIL: A component fetches data directly from a DataService bypassing the store. Or a presentational component accesses the store.

- [ ] **DF-3**: "Is there a single source of truth for each piece of state?"
  → Search: Grep for the state property name. Is the same data stored in multiple components, services, or stores?
  → FAIL: Same data duplicated across stores or components. Changes to one copy don't propagate to the other.

- [ ] **DF-4**: "Is data passed down via @Input and events up via @Output (unidirectional)?"
  → Check: Presentational components receive data through @Input and communicate back via @Output events only.
  → FAIL: Child component directly mutates parent data, calls parent methods via injected reference, or uses two-way binding for state (not form controls).

- [ ] **DF-5**: "Is code free of mutations on borrowed references (objects it doesn't own)?"
  → Check: Code does not mutate objects obtained from external sources. These are references to shared state — mutating them causes side effects in the owner.
  → Borrowed references include:
    - `@Input()` values from parent components
    - Store selector snapshot values
    - Return values from shared services
  → FAIL: `this.items.push(...)` on an @Input. `selectorResult.items.splice(...)` on a store snapshot.
  → WHY: Mutating store snapshots can corrupt shared state. Mutating @Input values breaks unidirectional data flow.
  → NOTE: Form value reference mutations (`FormGroup.value`, `getRawValue()`) are covered by the Forms checklist (FM-8).

## Reactive Patterns

- [ ] **DF-6**: "Is the async pipe used in templates instead of manual .subscribe()?"
  → Check: Templates use `| async` to unwrap observables. Components avoid subscribing just to store data in a local property for template binding.
  → FAIL: Component has `.subscribe(data => this.data = data)` when `data$ | async` in the template would suffice.

- [ ] **DF-7**: "Is OnPush change detection strategy used?"
  → Check: Components use `changeDetection: ChangeDetectionStrategy.OnPush`.
  → FAIL: Component uses default change detection without justification.

- [ ] **DF-8**: "Is `ngOnChanges` avoided — using RxJS setter + subject pattern instead?"
  → Check: Component does not implement `ngOnChanges` for reacting to input changes.
  → FAIL: `ngOnChanges` used to detect input changes. Use `@Input() set value(v) { this.value$.next(v); }` with a `Subject` or `BehaviorSubject` instead.

- [ ] **DF-9**: "Are getters avoided in templates (or trivially simple)?"
  → Check: Template-bound getters are either simple property returns (1 line, no computation) or replaced with stored values / pipes.
  → FAIL: Template calls a getter that computes a value, filters an array, or calls a method — runs on every change detection cycle causing performance issues.

## Subscription Cleanup

- [ ] **DF-10**: "Are all manual subscriptions cleaned up?"
  → Check: Manual `.subscribe()` calls use `takeUntilDestroyed()`, or are added to a `Subscription` aggregate and unsubscribed in `ngOnDestroy()`.
  → FAIL: A `.subscribe()` without cleanup mechanism — will cause memory leaks when component destroys.

- [ ] **DF-11**: "Are variables used for a single purpose only (not reused for different data)?"
  → Check: Each variable holds one kind of data throughout its lifetime.
  → FAIL: A variable is assigned different types of data at different points (`temp` used for user, then for response, then for error).

## RxJS Safety Patterns

- [ ] **DF-12**: "Is `takeUntil` the last operator before `subscribe`?"
  → Check: When `takeUntil` is used for subscription cleanup, it must be the last operator in the pipe (before `subscribe`). Operators placed after `takeUntil` can still process and emit values after the source completes.
  → FAIL: `.pipe(takeUntil(this.destroy$), map(x => transform(x))).subscribe(...)` — the `map` after `takeUntil` can still execute during teardown.
  → PASS: `.pipe(map(x => transform(x)), takeUntil(this.destroy$)).subscribe(...)`
  → WHY: Operators after `takeUntil` may process values emitted synchronously during unsubscription, leading to logic executing after the component is destroyed (null references, state updates on destroyed components).

- [ ] **DF-13**: "Are there nested subscribes (subscribe inside subscribe)?"
  → Check: No `.subscribe()` call appears inside another `.subscribe()` callback.
  → FAIL: `obs1$.subscribe(a => { obs2$.subscribe(b => { ... }) })` — creates a new inner subscription on every outer emission without cleanup. Use `switchMap`, `concatMap`, `mergeMap`, or `combineLatest` instead.
  → WHY: Nested subscribes cause memory leaks (inner subscriptions are never cleaned up), make error handling difficult (inner errors don't propagate to outer), and defeat RxJS's compositional design. This is the RxJS equivalent of callback hell.

- [ ] **DF-14**: "Does `shareReplay` include `{ refCount: true }` when used for caching?"
  → Check: `shareReplay` calls use the config object form with `refCount: true`, unless the source is intentionally kept alive regardless of subscribers.
  → FAIL: `shareReplay(1)` — the legacy shorthand keeps the source subscription alive forever, even after all subscribers unsubscribe. This causes memory leaks and prevents cleanup of HTTP connections or timers.
  → PASS: `shareReplay({ bufferSize: 1, refCount: true })` — source unsubscribes when subscriber count drops to zero.
  → EXCEPTION: `shareReplay(1)` is acceptable for application-lifetime observables that should never unsubscribe (e.g., root-level config/auth streams).

---

Total items: 14
