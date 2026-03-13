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

- [ ] **DF-5**: "Are presentational components free of local data mutations?"
  → Check: Presentational components do not modify @Input data. They emit events and let the container/store handle the update.
  → FAIL: Presentational component does `this.items.push(...)` or `this.data.property = newValue` on an @Input.

## Reactive Patterns

- [ ] **DF-6**: "Is the async pipe used in templates instead of manual .subscribe()?"
  → Check: Templates use `| async` to unwrap observables. Components avoid subscribing just to store data in a local property for template binding.
  → FAIL: Component has `.subscribe(data => this.data = data)` when `data$ | async` in the template would suffice.

- [ ] **DF-7**: "Is OnPush change detection strategy used?"
  → Check: Components use `changeDetection: ChangeDetectionStrategy.OnPush`.
  → FAIL: Component uses default change detection without justification.

- [ ] **DF-9**: "Is `ngOnChanges` avoided — using RxJS setter + subject pattern instead?"
  → Check: Component does not implement `ngOnChanges` for reacting to input changes.
  → FAIL: `ngOnChanges` used to detect input changes. Use `@Input() set value(v) { this.value$.next(v); }` with a `Subject` or `BehaviorSubject` instead.

- [ ] **DF-10**: "Are getters avoided in templates (or trivially simple)?"
  → Check: Template-bound getters are either simple property returns (1 line, no computation) or replaced with stored values / pipes.
  → FAIL: Template calls a getter that computes a value, filters an array, or calls a method — runs on every change detection cycle causing performance issues.

## Subscription Cleanup

- [ ] **DF-12**: "Are all manual subscriptions cleaned up?"
  → Check: Manual `.subscribe()` calls use `takeUntilDestroyed()`, or are added to a `Subscription` aggregate and unsubscribed in `ngOnDestroy()`.
  → FAIL: A `.subscribe()` without cleanup mechanism — will cause memory leaks when component destroys.

- [ ] **DF-13**: "Are variables used for a single purpose only (not reused for different data)?"
  → Check: Each variable holds one kind of data throughout its lifetime.
  → FAIL: A variable is assigned different types of data at different points (`temp` used for user, then for response, then for error).

---

Total items: 11
