# Regressions Checklist

---

## Breaking Changes

- [ ] **RG-1**: "If a public method signature changed — are ALL callers updated?"
  → Search: Grep for the old method name/signature across the workspace.
  → FAIL: Any caller still uses the old signature, passes wrong argument count/types, or would break at runtime.

- [ ] **RG-2**: "If interface properties were removed or renamed — are ALL consumers updated?"
  → Search: Grep for the old property name across the workspace.
  → FAIL: Any file still references the removed/renamed property.

- [ ] **RG-3**: "If behavior changed — are existing callers aware and compatible?"
  → Check: Review each call site. Does the new behavior (return value, side effects, timing) work correctly for existing consumers?
  → FAIL: A caller depends on the old behavior (e.g., expected null but now gets undefined, expected sync but now async).

- [ ] **RG-4**: "Are public exports from the library preserved?"
  → Check: Compare the `index.ts` or `public-api.ts` barrel exports before and after.
  → FAIL: A previously exported symbol is no longer exported, breaking downstream consumers.

- [ ] **RG-5**: "Are route paths unchanged (or intentionally migrated with redirects)?"
  → Check: If routing files changed, verify existing URLs still resolve.
  → FAIL: A route path changed without redirect or migration plan.

## Scope

- [ ] **RG-6**: "Is the change scoped to intended files only — no drive-by edits?"
  → Check: Review `git diff --stat`. Every changed file should relate to the ticket/feature.
  → FAIL: Files outside the feature/module were modified without justification (formatting-only changes, unrelated refactors mixed in).

## Critical Path Verification

- [ ] **RG-7**: "Are critical paths unaffected (login, navigation, data loading)?"
  → Check: If the change touches shared services, routing, or auth — verify these core flows still work.
  → FAIL: Change in a shared module could break login, navigation, or primary data loading flows.

## Test Coverage

- [ ] **RG-8**: "Does every new/changed non-component `.ts` file have a corresponding `.spec.ts` file?"
  → Check: For each changed `.service.ts`, `.store.ts`, `.utils.ts`, `.pipe.ts`, `.guard.ts`, `.interceptor.ts`, `.directive.ts`, `.model.ts` — verify a matching `.spec.ts` exists.
  → SKIP: `.component.ts` files (containers/presenters — logic belongs in services/stores), `.module.ts`, `.interface.ts`, barrel `index.ts`.
  → FAIL: A service, store, or utility was added or changed with no corresponding spec file.

- [ ] **RG-9**: "Is new non-trivial logic covered by ≥1 happy path + 1 failure path test?"
  → Check: For each new function/branch with business logic, find corresponding test cases.
  → FAIL: New logic has no tests, or only has happy path without error/edge cases.

- [ ] **RG-10**: "Are boundary values tested (empty input, single item, max size)?"
  → Check: Tests include empty arrays, null/undefined inputs, single-element cases, and maximum expected sizes.
  → FAIL: Tests only cover the "middle of the road" case, missing boundaries.

- [ ] **RG-11**: "Are tests numbered with `describe('1. ...')`, `it('1.1 ...')` pattern?"
  → Check: New test files follow the project's numbered test convention.
  → FAIL: Tests use unnumbered descriptions.

---

Total items: 11
