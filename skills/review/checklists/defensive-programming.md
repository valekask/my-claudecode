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

---

Total items: 12
