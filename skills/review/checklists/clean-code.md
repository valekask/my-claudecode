# Clean Code & Smells Checklist

---

## Functions

- [ ] **CC-1**: "Does each function have 0–3 parameters? If >3, is a single options object used?"
  → Check: Count function parameters.
  → FAIL: Function has >3 parameters without using an options/config object.
  → NOTE: 3 parameters are acceptable when types are distinct and the call site reads naturally (e.g., `computeRange(from, to, currencies)`). Flag 3-param functions only when multiple params share the same type and could be swapped silently.

- [ ] **CC-2**: "Is each function body at a single abstraction level?"
  → Check: Read the function — does it mix HTTP calls, data mapping, DOM manipulation, or analytics tracking in one body?
  → FAIL: Function contains operations from 2+ abstraction layers (e.g., raw HTTP call + DOM manipulation + analytics tracking). Split into separate functions per layer.

- [ ] **CC-3**: "Are functions ≤25 lines? (>20 triggers review for possible split)"
  → Check: Count lines of function body.
  → FAIL: Function exceeds 25 LOC with mixed comments like `// fetch`, `// map`, `// update UI` indicating multiple responsibilities.

- [ ] **CC-4**: "Does any function name contain multiple verbs from different layers?"
  → Check: Function name like `fetchAndRenderAndTrack()` signals mixed concerns.
  → FAIL: Name contains 2+ verbs indicating different responsibilities. Split into separate functions.

- [ ] **CC-5**: "Are functions that return values AND trigger side effects clearly named or split?"
  → Check: A function both returns data and mutates state or triggers network calls.
  → FAIL: Caller can't tell from the name that side effects occur. Either clarify in name (`saveAndReturnUser()`) or split into pure + effect parts.

## Scope & Variables

- [ ] **CC-6**: "Do all variables have the smallest scope possible?"
  → Check: Variables are declared in the innermost block where they're needed, not at class/file level when only used in one method.
  → FAIL: Class-level field used only in a single method. Or variable declared at top of function but only used 50+ lines later.

- [ ] **CC-7**: "Are references to variables as close together as possible?"
  → Check: Distance between variable declaration and its usage.
  → FAIL: Variable declared then unused for 30+ lines before first reference.

- [ ] **CC-8**: "Are boolean variables used to document complex conditions?"
  → Check: Complex conditions are extracted into named booleans.
  → FAIL: `if (age > 18 && hasLicense && !isSuspended && passedTest)` instead of `const isEligibleDriver = age > 18 && hasLicense && !isSuspended && passedTest`.

## Component & Class Size

- [ ] **CC-9**: "Are components and services at a manageable size?"
  → Check: Components ≤300 lines, Services ≤250 lines as soft guidelines. These are signals, not hard limits — a 260-line service with clear structure is fine; a 180-line service with tangled logic is not.
  → FAIL: File significantly exceeds guideline AND the excess indicates structural problems (mixed responsibilities, god class). Don't flag size alone if the code is well-organized.

- [ ] **CC-10**: "Does any class have >7 data members (fields/properties)?"
  → Check: Count class fields (excluding injected dependencies).
  → FAIL: Class has >7 data fields. Consider grouping related fields into a sub-object or splitting the class.

## Method Ordering

- [ ] **CC-11**: "Is method ordering correct? (lifecycle → handlers → public → private)"
  → Check: 1) Lifecycle hooks (`ngOnInit`, etc.) first, 2) Template event handlers (`onSaveClick()`) second, 3) Public orchestration methods third, 4) Private helpers last.
  → FAIL: Private methods mixed among public handlers. Or lifecycle hooks placed after other methods.

- [ ] **CC-12**: "Are callers positioned above callees?"
  → Check: When a method calls another method, the caller appears above the callee in the file.
  → FAIL: Need to scroll up to find caller after reading callee — reading flow is bottom-to-top.

## Control Flow

- [ ] **CC-13**: "Is nesting depth ≤3 levels?"
  → Check: Count indentation levels within any function.
  → FAIL: 4+ levels of nesting. Use guard clauses (`if (!x) return`), extract helper methods, or invert conditions.

- [ ] **CC-14**: "Are conditions expressed positively? (prefer `if (isConnected)` over `if (!isDisconnected)`)"
  → Check: Conditional checks avoid double negation.
  → FAIL: `if (!isNotReady)` or `if (!isDisconnected)` — use positive form.

- [ ] **CC-15**: "Are there no side effects in conditions?"
  → Check: No assignments or mutations inside `if`, `while`, or ternary conditions.
  → FAIL: `if (x = getValue())` or `while (items.pop())` — separate assignment from test.

- [ ] **CC-16**: "Are functions below complexity threshold? (cyclomatic complexity ≤15)"
  → Check: Count branches (`if`, `else if`, `case`, `&&`, `||`, `?.`, ternary) in a function. Functions with many branches are hard to understand and test.
  → FAIL: Function has >15 branches/conditions. Split into smaller functions, use early returns, or extract complex conditions into named booleans.
  → NOTE: Aligns with project ESLint `complexity` rule (max 15).

## Dead Code & Hygiene

- [ ] **CC-17**: "Is there dead code? (unused imports, unused inputs/outputs, commented blocks, HTML comments, temp logs)"
  → Check: No unused imports, no unused `@Input()`/`@Output()` declarations, no commented-out code blocks, no HTML comments (`<!-- -->`), no `console.log` / `debugger` statements.
  → FAIL: Any of these found in the diff. An `@Input()` declared but never referenced in the component's class or template. An HTML comment in a template (code should be self-explanatory).

- [ ] **CC-18**: "Is there duplicated logic across methods or files?"
  → Search: Look for similar code patterns in the changed files and their neighbors.
  → FAIL: Same logic (>3 lines) appears in multiple places. Extract to a shared function or service.

## RxJS Patterns

- [ ] **CC-19**: "Are `.subscribe()` bodies empty except adding to subs aggregate?"
  → Check: Logic lives in `.pipe()` operators (`tap`, `map`, etc.), not in the subscribe callback.
  → FAIL: `.subscribe(data => { /* 10+ lines of logic */ })` — move logic to pipe operators.

- [ ] **CC-20**: "Are error extraction patterns centralized (shared service, not ad-hoc catchError)?"
  → Check: Error handling uses a shared error extractor or interceptor, not custom `catchError` in every effect/subscription.
  → FAIL: Each effect/subscription has its own error parsing logic duplicated across files.

## Template Complexity

- [ ] **CC-21**: "Are template expressions simple? No method calls in bindings, no complex logic in `*ngIf`/`*ngFor`?"
  → Check: Template conditions are single booleans or simple comparisons. No method calls like `{{ getTotal() }}`, `[class.active]="isActive()"`, or `*ngIf="hasPermission()"` — these execute on every change detection cycle and degrade performance. Use properties, pre-computed values, selectors, or pipes instead.
  → FAIL: `*ngIf="items.length > 0 && !loading && !error && hasPermission"` or `[class.active]="a && (b || c) && !d"` — extract to a named boolean or selector. Method calls in bindings like `{{ calculateTotal() }}` or `[value]="getFormattedDate()"` — replace with a property set in the component class or a pipe.
  → FAIL (redundant binding): `[class.loading]="loading"` inside `*ngIf="loading"` — the condition is always true since the structural directive already guards it. Use static `class="loading"` instead.

- [ ] **CC-22**: "Is `trackBy` used in `*ngFor` for lists?"
  → Check: Every `*ngFor` that iterates over data (not static small arrays) has a `trackBy` function.
  → FAIL: `*ngFor="let item of items"` without `trackBy` — Angular re-renders the entire list on any change, causing performance issues and losing DOM state.

- [ ] **CC-23**: "Are impure pipes avoided in templates?"
  → Check: Custom pipes used in templates are pure (default). No pipes marked with `pure: false` that run on every change detection cycle.
  → FAIL: Impure pipe (`@Pipe({ pure: false })`) used in a template binding — re-executes on every change detection cycle even when input hasn't changed. Use a pure pipe, move logic to a selector, or pre-compute the value in the component.

## Type Safety

- [ ] **CC-24**: "Are generic containers avoided when a specific type exists?"
  → Check: No `any`, `Pair<X,Y>`, `Record<string, any>`, or untyped objects where a named interface would clarify intent.
  → FAIL: Using `any` without justification, or `{ [key: string]: any }` instead of a typed interface.

- [ ] **CC-25**: "Do functions have explicit return types?"
  → Check: Named functions and methods declare their return type. Catches bugs at the declaration site instead of distant call sites.
  → FAIL: `function getData() { ... }` instead of `function getData(): Observable<Item[]> { ... }`.
  → EXCEPTION: Trivial inline arrow callbacks (e.g., `.map(x => x.id)`, `.pipe(tap(() => this.refresh()))`) where the type is obvious from context.

- [ ] **CC-26**: "Do all code paths return a value matching the declared return type?"
  → Check: Functions with a non-void return type return a value on every branch, AND the returned values match the declared type.
  → FAIL (missing return): `function getLabel(type: string): string { if (type === 'A') return 'Alpha'; }` — falls off end returning `undefined`.
  → FAIL (type mismatch): Function declares `{ dateFrom: number; dateTo: number }` but a branch returns `{ dateFrom: null, dateTo: null }`. The return type should be `{ dateFrom: number | null; dateTo: number | null }` or the function should throw instead of returning null fields.
  → WHY: Callers trust the declared return type. Returning null where number is declared causes runtime errors at distant call sites (e.g., `result.dateFrom.toFixed(2)` throws). TypeScript strict mode catches this, but `as` casts and incomplete `strictNullChecks` configs let it through.

---

Total items: 26
