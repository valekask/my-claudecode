# Architecture Checklist

---

## Component Split

- [ ] **AR-1**: "Do container components own state and presentational components receive it via @Input?"
  → Check: Presentational components have no injected services, no store access, no HTTP calls. They receive data through `@Input` and emit events through `@Output`.
  → FAIL: A presentational component injects a DataService, accesses a store, or makes API calls directly.

- [ ] **AR-2**: "Is business logic in component-specific services, not in components?"
  → Check: Components delegate transformation, validation, and business rules to dedicated services. Component methods are thin orchestration — no `map()`, `filter()`, `sort()`, `reduce()`, complex conditionals, or multi-step data manipulation in component code.
  → FAIL: Component contains data transformation, validation, filtering, sorting, or computation logic. Move to:
    - ComponentStore selector/updater (if state-related)
    - Component-specific service (if reusable business logic)
    - Utility function (if pure transformation)
  → WHY: Services and stores are easy to unit test in isolation. Component tests are brittle, slow, and break on template changes.

- [ ] **AR-3**: "Is presentation logic in the component class, not the template?"
  → Check: Templates contain declarative bindings and event handlers, not complex expressions or multi-step logic.
  → FAIL: Template has complex `*ngIf` expressions, inline calculations, or multi-line ternaries. Logic should move to a computed property or selector.

## Layer Boundaries

- [ ] **AR-4**: "Is code in the correct lib type (feature/data-access/ui/utils)?"
  → Check: Feature components in `feature-*`, API services in `data-access-*`, reusable UI in `ui`, helpers in `utils`.
  → FAIL: A data-fetching service lives in a `feature-*` lib, or a feature-specific component sits in `ui`.

- [ ] **AR-5**: "Are layer boundaries respected — no upward dependencies?"
  → Check: `data-access` does not import from `feature`. `ui` does not import from `feature`. `utils` imports from nothing project-specific.
  → FAIL: A lower-level lib imports from a higher-level lib (e.g., `data-access` importing from `feature`).

- [ ] **AR-6**: "Are there circular dependencies between modules?"
  → Check: Follow import chains. A does not import B which imports A.
  → FAIL: Circular import detected. Extract shared code to a lower-level lib or redesign the dependency.

## Module Design

- [ ] **AR-7**: "Does any component inject >5 dependencies?"
  → Check: Count constructor parameters.
  → FAIL: Component or service has >5 injected dependencies. Consider introducing a facade service to group related dependencies.

- [ ] **AR-8**: "Are there pass-through methods that just delegate to another with the same API?"
  → Check: Method receives arguments and forwards them unchanged to another method with the same signature.
  → FAIL: `getUser(id) { return this.innerService.getUser(id); }` — the wrapper adds no value. Either expose the inner service or add real logic.

- [ ] **AR-9**: "Does a general-purpose module contain use-case-specific code?"
  → Check: Shared services, utils, and UI libs should not contain feature-specific logic or imports.
  → FAIL: A shared utility function imports from a specific feature module, or contains `if (feature === 'dashboard')` branches.

- [ ] **AR-10**: "Is the interface simpler than the implementation (deep module)?"
  → Check: Public API of a service/module should be smaller and simpler than its internal logic.
  → FAIL: A service has many small public methods that each do trivial work (shallow module). Callers need to know internal details to use it correctly.

## Project Constraints

- [ ] **AR-11**: "Is Angular 17 used WITHOUT signal-based APIs?"
  → Check: No usage of `signal()`, `computed()`, `effect()`, `input()`, `output()`, `model()`, `toSignal()`, `toObservable()`.
  → FAIL: Any signal-based API found. Use RxJS observables instead.

- [ ] **AR-12**: "Are protected files unchanged (package.json, nx.json, environment.prod.ts)?"
  → Check: Diff does not include changes to protected files unless explicitly requested.
  → FAIL: Protected file modified without explicit justification.

- [ ] **AR-13**: "Is inheritance depth < 3 levels?"
  → Check: Count class inheritance chain.
  → FAIL: Class extends > 2 levels deep. Prefer composition over deep inheritance.

---

Total items: 13
