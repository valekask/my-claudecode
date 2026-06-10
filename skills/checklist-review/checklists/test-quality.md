# Test Quality Checklist


This checklist is used by Agent 5: TEST QUALITY. Unlike other agents that review only the diff,
this agent reads BOTH the implementation file and its spec file to verify logic-test alignment.

**Scope:** Services, stores, utilities, pipes, guards, interceptors.
**Skip:** Components (containers/presenters — their logic belongs in services/stores, not component tests).

---

## Spec File Basics

- [ ] **TQ-1**: "Does the spec file test the actual unit, not a mock of it?"
  → Check: The `describe()` block creates a real instance (or uses `TestBed` with minimal mocks). Assertions target the unit's behavior, not mock return values.
  → FAIL: Test creates a mock of the class being tested, or all assertions are on mock `.toHaveBeenCalled()` without verifying output/state.

- [ ] **TQ-2**: "Are mocks limited to external dependencies only (HTTP, other services)?"
  → Check: Only things crossing boundaries are mocked: HTTP calls, injected services, timers. Internal methods of the unit under test are NOT mocked.
  → FAIL: `jest.spyOn(service, 'privateHelper').mockReturnValue(...)` — mocking internal logic defeats the purpose of the test.

## Branch Coverage

- [ ] **TQ-3**: "Is every `if/else` branch in the implementation covered by at least one test?"
  → Check: Read the implementation. For each conditional (`if`, `else`, ternary, `switch` case), find a test that exercises that path.
  → FAIL: An `else` branch or `switch` case has no corresponding test. Formula: minimum tests ≥ 1 + count of `if/else if/case` branches.

- [ ] **TQ-4**: "Is every `catchError` / `catch` / error callback covered by a test?"
  → Check: For each error handling path in the implementation, find a test that triggers the error condition and verifies the handling.
  → FAIL: Error path exists in implementation but no test forces that path.

- [ ] **TQ-5**: "Are guard clauses (early returns) tested?"
  → Check: Functions with `if (!x) return` or `if (!x) throw` at the top — is there a test that triggers each guard?
  → FAIL: Guard clause exists but no test passes invalid input to trigger it.

## Edge Cases & Boundaries

- [ ] **TQ-6**: "Are empty/null/undefined inputs tested for functions that accept them?"
  → Check: If a function parameter can realistically be empty/null/undefined (from API, selector, user input), is there a test for that case?
  → FAIL: Function handles `null` input (with a guard or fallback) but no test verifies that behavior.

- [ ] **TQ-7**: "Are numeric edge cases tested (zero, negative, NaN, Infinity)?"
  → Check: Functions that do math, formatting, or date operations — are boundary numeric values tested?
  → FAIL: `formatCurrency(amount)` tested with `100` and `99.99` but not with `0`, `-1`, or `NaN`.

- [ ] **TQ-8**: "Are error, edge, and boundary cases tested — not just happy paths?"
  → Check: For non-trivial logic, tests should cover error conditions, null/empty inputs, and boundary values — not only the success scenario.
  → FAIL: Only happy-path tests exist. No tests for error callbacks, null inputs, empty arrays, zero values, or other edge cases that the implementation handles.

## Logic Correctness

- [ ] **TQ-9**: "Do test assertions verify the RIGHT thing (output/state, not implementation details)?"
  → Check: Assertions check return values, state changes, or observable side effects — not internal method call order or private state.
  → FAIL: `expect(spy.calls.count()).toBe(3)` instead of verifying the actual output. Tests break on refactor even when behavior is unchanged.

- [ ] **TQ-10**: "Are test values realistic and meaningful (not arbitrary magic numbers)?"
  → Check: Test data resembles real data the function would receive in production.
  → FAIL: `service.calculate(1, 2, 3)` — what do 1, 2, 3 represent? Use named constants or realistic values: `service.calculate(openingPrice: 150.25, closingPrice: 148.50, volume: 1000000)`.

- [ ] **TQ-11**: "Does each test have a clear single assertion focus?"
  → Check: Each `it()` block tests one behavior. Multiple assertions are fine if they verify the same behavior from different angles.
  → FAIL: One `it()` block that tests happy path, error path, and edge case together — if it fails, you don't know which scenario broke.

## Missing Test Detection

- [ ] **TQ-12**: "Are there implementation branches with NO corresponding test at all?"
  → Check: Walk through the implementation line by line. For each decision point, confirm a test exists.
  → Output: List each untested branch as: `file:line — branch description — no test found`.
  → This is the most important check. Be thorough.

## Assertion Integrity

- [ ] **TQ-13**: "Are test assertions unconditional — no `if` guards that silently skip expects?"
  → Check: Inside `it()` blocks and `subscribe` callbacks, assertions (`expect(...)`) are NOT wrapped in `if` conditions that can be falsy.
  → FAIL: `if (criteria.post_query_filter) { expect(json.includes('Custom Ratio')).toBeFalse(); }` — when `post_query_filter` is undefined, the entire assertion is skipped and the test passes silently, masking a real failure.
  → FIX: Assert the precondition first (`expect(criteria.post_query_filter).toBeDefined()`), then assert the value unconditionally. If two scenarios are possible, write two separate `it()` blocks.
  → WHY: Conditional assertions are one of the most dangerous test smells — the test appears green but validates nothing. The `if` guard converts a test failure into a silent pass.

## Environment Independence

- [ ] **TQ-14**: "Are test assertions free of locale-dependent or timezone-dependent values?"
  → Check: Test expectations do not depend on the runtime's locale, timezone, or date formatting defaults.
  → FAIL: `expect(result).toBe('15/06/2020')` — assumes `dd/MM/yyyy` locale formatting. Will fail on machines with `MM/dd/yyyy` or other locale.
  → FAIL: `expect(date.getHours()).toBe(10)` — depends on the machine's timezone. Use UTC methods or mock the timezone.
  → FIX: Use explicit format functions with a fixed locale, or assert on epoch timestamps / ISO strings instead of locale-formatted output. For timezone-dependent tests, use UTC or explicitly set the timezone in the test.
  → WHY: Tests that pass locally but fail on CI (or on a colleague's machine) due to locale/timezone differences waste debugging time and erode trust in the test suite.

---

Total items: 14
