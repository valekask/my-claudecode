# Clean Code Guideline

Focused, project-specific coding conventions complementing architecture, naming, and styling docs. 

## 1. Functions & Parameters
- Prefer 0–2 params; use a single options object if >2 logical inputs.
- Keep functions small and single-purpose: one abstraction level below the name.
- Avoid mixing concerns (validation + API + view mapping) in one function.
- Fail fast with guard clauses (`if (!input) {return;}`).
- Surface side-effects clearly in names (e.g. `saveUser()`, `updateCache()`).
- Don't over-shrink: avoid micro-functions that only forward a call or return a property without adding semantic clarity or reuse.

### Abstraction Levels
Every function name sets an expectation for the level of detail inside:
- High-level orchestration name (e.g. `initializeWorkspace`) should call lower-level helpers (`loadUser()`, `setupStreams()`)—not embed raw HTTP request code and DOM mutation directly.
- Mid-level transformation (`mapUserDtoToModel`) should focus only on mapping, not logging, caching, or emitting events.
- Low-level primitive (`parseDate()`) should perform a single atomic operation.

Rules:
1. One abstraction level per function body—avoid mixing wire protocol (HTTP), domain conversion, and UI binding together.
2. If comments describe multiple “steps” each at different conceptual levels, split them.
3. A function calling many helpers of divergent abstraction (e.g. `fetchUsers(); attachDomListeners(); renderWidget();`) is a red flag—extract into sequential top-level phases or separate responsibility services.
4. Names should NOT contain multiple verbs that signal different layers (e.g. `fetchAndRenderAndTrack()` → split).
5. If a function both returns a value and triggers side-effects (e.g. network + store mutation), clarify in name or split into pure + effect parts.

Refactor Signals:
- Function > ~25 LOC with mixed comments like `// fetch`, `// map`, `// update UI`.
- Parameter list contains both domain objects and raw infrastructure handles (e.g. `HttpClient`, `ChangeDetectorRef`)—separate orchestration from pure logic.
- Needs multiple conditional branches for type-specific handling—consider polymorphism or strategy.

Example (Before):
```ts
loadAndRenderUser(id: string) {
  const resp = this.http.get(`/api/users/${id}`); // HTTP (infra)
  const user = this.mapDto(resp);                // mapping (domain)
  this.cd.detectChanges();                       // UI (presentation)
  this.analytics.track('user_loaded');           // side-effect (tracking)
  return user;
}
```
Improved (After):
```ts
loadUser(id: string) { return this.http.get(`/api/users/${id}`); }
mapUser(resp: UserDto): User { /* mapping only */ }
renderUser(user: User): void { this.viewModel = user; }
trackUserLoaded(user: User): void { this.analytics.track('user_loaded'); }

loadAndRenderUser(id: string): void {
  const dto = this.loadUser(id);
  const user = this.mapUser(dto);
  this.renderUser(user);
  this.trackUserLoaded(user);
}
```
Result: Each function now holds a consistent abstraction, making testing and future changes (e.g. swap tracking) isolated.

### Function Granularity
Healthy function size is a balance: small enough to be readable, large enough to hold a coherent semantic unit.

Guidelines:
- Avoid micro-wrappers (<3 LOC) that merely delegate (`getUser()` that just returns `this.user`). Inline unless part of an interface contract.
- Prefer 5–15 LOC for orchestration; <10 LOC for pure transformations; >20 LOC triggers review for possible split.
- Do not split solely to satisfy an arbitrary line count—only when distinct responsibilities emerge.
- If two adjacent functions are always called sequentially and neither is reused independently, consider merging.
- Eliminate trivial pass-throughs introduced during earlier refactors.

Refactor Examples:
- `getItems()` returning `this.items` → inline property access unless required by interface.
- `mapUser()` calling `sanitizeUser()` calling `stripMetadata()` each 2 LOC → consolidate into a single `mapUser()` with clear internal steps.

Checklist:
1. Does the function name reflect a single clear intent? If not, split.
2. Would inlining increase clarity? If yes, remove the indirection.
3. Is the function reused in multiple places? If yes, keep even if tiny.
4. Does the function hide complexity (algorithm, protocol)? Keep even if currently short.

## 2. Control Flow
- Prefer positive checks (`if (isConnected)` vs double negations).
- Minimize nesting via early returns and small extracted helpers.
- Replace repetitive branching with polymorphism or factory functions.
- Throw explicit errors for invalid state instead of silent booleans.

## 3. Naming Essentials
- US English everywhere; avoid abbreviations and slang.
- A/HC/LC pattern for verbs: `fetchUserMetrics`, `shouldRefreshTokens`.
- Boolean names in positive form: `hasData`, `isAuthorized`, `canExport`.
- Avoid context duplication: `MenuItem.handleClick()` not `handleMenuItemClick()`.

## 4. Objects & Classes
- High cohesion: methods should operate on the class’s own data.
- Avoid long call chains; respect Law of Demeter.
- Use small, explicit base + extensions instead of large conditional blocks.
- Keep data-only structures separate from behavior classes (models vs services).

## 5. Component Method Ordering
- Order public lifecycle & template-triggered methods by first call (top → bottom).
- Place all private helper methods last to reduce cognitive jumping.
- Example pattern:
  1. `ngOnInit()` / other lifecycle
  2. Template event handlers (`onSaveClick()`)
  3. Public orchestration (`loadWorkspace()`)
  4. Private helpers (`mapDto()`, `buildRequest()`).

### Call Order Proximity
Goal: read a component/service top-to-bottom following execution flow with minimal jumping. Position callers above their callees when practical.

Core rules:
- Lifecycle hooks first (`constructor`, then `ngOnInit`, then other Angular hooks in occurrence order: `ngOnChanges`, `ngAfterViewInit`, etc.).
- Public API & template-bound handlers next (`onFilterChange()`, `onSubmit()`), ordered by typical user interaction sequence.
- Public orchestration methods (that combine multiple private helpers) below handlers.
- Private helpers grouped at bottom; optionally group by semantic region with short comment banners.

Services:
- Exported/public methods first in likely usage order (highest-level orchestration first, then more granular fetch/update calls).
- Internal/private pure transformation, mapping, parsing, validation helpers last.

Factories / Strategy classes:
- Static `create(...)` or factory entry first.
- Decision/dispatch methods next.
- Concrete strategy implementations (if co-located) afterwards or split into separate files.

Full Example (Numbered Ordering):
```ts
export class ExampleComponent implements OnInit {

  // 1️⃣ Lifecycle hook comes first among public methods
  ngOnInit(): void {
    this.a(); // calls private method 'a'
  }

  // 2️⃣ First public method triggered by the template
  onButtonClick(): void {
    this.loadData(); // calls another public method
  }

  // 3️⃣ Public method called from another public method
  loadData(): void {
    this.b(); // calls private method 'b'
    const data = this.fetchData();
    console.log('Data loaded:', data);
  }

  // 4️⃣ All private methods are at the bottom
  private a(): void {
    console.log('Private method A called from ngOnInit');
    this.c();
  }

  private b(): void {
    console.log('Private method B called from loadData');
    this.d();
  }

  private c(): void {
    console.log('Private method C called from A');
  }

  private d(): void {
    console.log('Private method D called from B');
  }

  private fetchData(): string {
    return 'Hello from the server!';
  }
}
```

Checklist Before Reordering:
- Ensure no cyclic dependencies emerge (a private helper calling a public method appearing above it is fine; avoid mutual recursion hidden by ordering).
- Preserve logical reading order; don’t sort alphabetically if it harms flow.
- Confirm template references still point to correct public method names.

Common Mistakes:
- Mixing private helpers among public handlers → increases scroll + cognitive context switching.
- Scattering related private helpers (e.g. parsing vs validation) in different sections—group them.
- Placing subscription setup below emitters causing temporal coupling confusion.

Tip: If a public method needs >3 private helpers, consider extracting a component-specific service and keep the component orchestration thin.

## 6. RxJS & Subscriptions
- Use `observable$.pipe(...)` with `tap`, `map`, etc; avoid logic in `subscribe`.
- Keep `.subscribe()` bodies empty except adding to `subs` aggregate.
- Centralize error extraction (shared error extractor service) instead of ad-hoc `catchError` chains.
- Manage via `subs = new Subscription();` + `this.subs.add(stream$.subscribe());` + `ngOnDestroy()` clean-up.

## 7. Common Anti-Patterns (Avoid)
- Deeply nested conditionals → replace with guard clauses or strategy.
- Bloated components (>300 lines) → extract service or split into presentational pieces.
- Inline business logic in templates.
- Negative boolean names (`isNotReady`) causing mental double negation.
- Unmanaged subscriptions leading to memory leaks.

## 8. Refactor Checklist
Before changing a public surface:
- Identify consumers via search.
- Preserve or deprecate with clear transitional naming (`oldMethod` forwarding to `newMethod`).
- Update tests + public exports.
- Run `nx test <lib>` and confirm build.

## 9. When Adding New Code
1. Select proper lib type (feature/data-access/ui/utils/shared).
2. Generate schematic if possible (`nx generate ...`).
3. Implement container/presentational split early.
4. Introduce dedicated service for transformation/business logic.
5. Add minimal tests (numbered) → run.
6. Ensure exports minimal; apply Prettier/ESLint.
7. Confirm layering boundaries (no direct HTTP in presentational comp).

## 10. Review Signals
Refactor triggers:
- Repeated conditional blocks for type differences → introduce polymorphism.
- Functions exceeding 25–30 lines or multiple responsibility verbs in comments.
- Boolean flags proliferating in function params (consider object or split functions).

---
This document complements `ARCHITECTURE.md`, `NAMING.md`, `STRUCTURE.md`, `STYLING.md`. Update incrementally; keep rules actionable and enforced in PR review.
