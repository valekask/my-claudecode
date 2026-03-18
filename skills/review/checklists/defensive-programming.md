# Defensive Programming Checklist

---

## Null & Undefined Safety

- [ ] **DP-1**: "Does code check for null/undefined before accessing properties?"
  → Check: Any variable from external source (API response, selector, function parameter) accessed with `.property` or `[index]` without null guard.
  → FAIL: `response.data.items.map(...)` without checking `response.data` exists. Use optional chaining (`?.`) or explicit guard.

- [ ] **DP-2**: "Are optional parameters handled with defaults or guards?"
  → Check: Function parameters that could be undefined/null are either given defaults or checked before use.
  → FAIL: `function format(value) { return value.toFixed(2) }` — crashes if `value` is undefined. Add default or guard.

## Numeric Safety

- [ ] **DP-3**: "Are numeric inputs guarded against NaN and Infinity?"
  → Check: Functions that receive numeric input (especially from external sources) and pass it to operations that throw on invalid values: `new Date(n).toISOString()`, `n.toFixed()`, `Math.log(n)`, division.
  → FAIL: `new Date(timestamp).toISOString()` without checking `isNaN(timestamp)` or `!isFinite(timestamp)`. NaN propagates silently until it throws at a distant call site.

- [ ] **DP-4**: "Are division operations guarded against zero?"
  → Check: Any division (`/`, `%`) where the divisor could be zero.
  → FAIL: `total / count` where `count` comes from data that could be zero. Returns `Infinity` or `NaN`.

## Empty Input & Boundary Conditions

- [ ] **DP-5**: "What happens when input is an empty string, empty array, or zero?"
  → Check: Functions that receive collections or strings — do they handle the empty case?
  → FAIL: `items[0].name` without checking `items.length > 0`. Or `str.split('/')[1]` without checking the string contains `/`.

- [ ] **DP-6**: "Are array index accesses bounds-checked?"
  → Check: Direct index access (`arr[i]`, `arr[arr.length - 1]`) on arrays that could be empty or shorter than expected.
  → FAIL: `results[results.length - 1]` on a potentially empty array returns `undefined`, then `.property` throws.

- [ ] **DP-7**: "Are type coercion edge cases handled?"
  → Check: Values from external sources (query params, form inputs, API responses) that are expected to be numbers but arrive as strings, or vice versa.
  → FAIL: `parseInt(value)` without checking `isNaN()` on the result. Or `value === 0` when `value` is `"0"` (string).

## Error Handling

- [ ] **DP-8**: "Are error handlers non-empty? (no swallowed errors)"
  → Check: Every `catch` block, `catchError` operator, and error callback does something meaningful (log, rethrow, return fallback).
  → FAIL: Empty `catch {}` or `catchError(() => EMPTY)` without logging — hides bugs.

- [ ] **DP-9**: "Do async operations have error paths?"
  → Check: Every `subscribe()`, `Promise.then()`, `async/await` has corresponding error handling.
  → FAIL: `.subscribe(data => ...)` without error callback or `catchError` in the pipe — unhandled errors crash silently.

- [ ] **DP-10**: "Are error messages actionable without leaking internals?"
  → Check: Error messages help debugging but don't expose stack traces, internal paths, or sensitive data to end users.
  → FAIL: `catch(e) { showToast(e.message) }` where `e.message` contains internal details.

## Input Validation at Boundaries

- [ ] **DP-11**: "Is external input validated at entry point (API response, user input, URL params)?"
  → Check: Data crossing trust boundaries (API responses, form inputs, route params, localStorage) is validated for expected type and shape before use.
  → FAIL: API response used directly without checking expected fields exist: `this.data = response` then template accesses `data.items.length`.

- [ ] **DP-12**: "Are enum/union values validated against unexpected values?"
  → Check: When a value is expected to be one of a known set (status codes, type discriminators), is there a default/fallback case?
  → FAIL: `switch(status)` without `default` case — new status values from API silently fall through.

## Date & Time Safety

- [ ] **DP-13**: "Are UTC-created dates accessed with UTC methods (and vice versa)?"
  → Check: When a Date is created with `Date.UTC()`, `new Date('...Z')`, or any UTC source, all property access uses UTC methods (`getUTCFullYear()`, `getUTCMonth()`, `getUTCDate()`, `getUTCHours()`). Conversely, dates created with local constructors use local methods.
  → FAIL: `const d = new Date(Date.UTC(2024, 0, 1)); d.getFullYear()` — uses local `getFullYear()` on a UTC date. In UTC+X timezones this returns the wrong year/month/day (off-by-one at midnight boundaries).
  → FAIL: `const d = convertToBusinessDayByCurrency(...); new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))` — if `convertToBusinessDayByCurrency` returns a UTC-based date, mixing in local accessors causes timezone-dependent bugs.
  → WHY: This is one of the most common date bugs in timezone-aware code. The mismatch is silent — no error, no NaN — just wrong values that only manifest in certain timezones.

- [ ] **DP-14**: "Does date arithmetic handle calendar boundaries (month/year rollover)?"
  → Check: Date calculations that compare or subtract date components (day, hour, minute) also account for month and year differences. Comparing only partial components (e.g., day + hour) fails when dates span different months.
  → FAIL: `targetDay * 24 * 60 + targetHour * 60 - utcDay * 24 * 60 - utcHour * 60` — if UTC is Feb 1 00:30 and target timezone is Jan 31 19:30, the day difference wraps incorrectly because month is ignored.
  → FIX: Build full Date objects from all components (year, month, day, hour, minute) and subtract, or use a single numeric representation (epoch millis) for comparison.
  → WHY: Date component math that ignores higher-order components (month, year) silently produces wrong results at calendar boundaries.

## Output Validity

- [ ] **DP-15**: "Do recursive or filtering operations avoid producing structurally invalid output (empty containers, orphaned groups)?"
  → Check: When code recursively filters, prunes, or transforms nested structures (tree nodes, filter groups, menu hierarchies), verify that the result doesn't contain empty parent containers that downstream consumers treat as invalid.
  → FAIL: `filterOutExcludedColumns` removes all children from a group but keeps the parent with `filters: []`. The empty group serializes to the backend as an invalid/ambiguous filter structure.
  → FIX: After recursing into children, check if the result is empty and remove the parent too: filter/prune bottom-up (recurse first, then filter), not top-down.
  → WHY: Recursive operations that only check the current level miss structural invariants. An empty `[]` is valid as a value but invalid as a "group with no members" in domain-specific structures. This class of bug survives unit tests because tests rarely construct deeply nested inputs.

## Framework-Specific Safety

- [ ] **DP-16**: "Are Angular form validators correct for the control's value type?"
  → Check: Form control validators match the data type of the control's value.
  → FAIL: `fb.control([] as string[], [Validators.required])` — `Validators.required` checks for truthy values, but an empty array `[]` is truthy. Validation passes with zero selections. Use `Validators.minLength(1)` for array controls.
  → FAIL: `fb.control('', [Validators.min(0)])` — `Validators.min` expects a number, not a string. The validator silently passes or behaves unexpectedly on string values.
  → WHY: Angular validators have type assumptions that aren't enforced by TypeScript. `Validators.required` is the most common trap — it works for strings and null but not for empty arrays or objects.

---

Total items: 16
