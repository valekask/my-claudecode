# Forms Checklist

---

## Form Setup

- [ ] **FM-1**: "Are all validators registered before the first validation pass?"
  → Check: Custom validators (via `setValidators`, `setAsyncValidators`) are attached to controls BEFORE the first call to `updateValueAndValidity()`.
  → FAIL: `this.form.updateValueAndValidity()` called, then `this.formArray.setValidators(customValidator())` — the initial validation misses the custom validator. Move `setValidators` before `updateValueAndValidity`.
  → WHY: The first validation pass determines initial form state (valid/invalid). Validators added after it don't take effect until the next trigger (user input or explicit re-validation), so the form may appear valid when it shouldn't.

- [ ] **FM-2**: "Do form control value types match their validator expectations?"
  → Check: Validators are appropriate for the control's value type.
  → FAIL: `fb.control([] as string[], [Validators.required])` — `Validators.required` checks for truthy values, but an empty array `[]` is truthy. Validation passes with zero selections. Use `Validators.minLength(1)` for array controls.
  → FAIL: `fb.control('', [Validators.min(0)])` — `Validators.min` expects a number, not a string. The validator silently passes or behaves unexpectedly on string values.
  → WHY: Angular validators have type assumptions that aren't enforced by TypeScript. `Validators.required` is the most common trap — it works for strings and null but not for empty arrays or objects.

- [ ] **FM-3**: "Are form controls created with correct initial values and types?"
  → Check: Initial values match the expected type of the control. Number controls initialized with numbers (not strings), array controls with arrays, etc.
  → FAIL: `fb.control('0')` for a numeric field — downstream code does `control.value + 1` and gets `'01'` (string concatenation).
  → FAIL: `fb.control(null)` without specifying the type — TypeScript infers `FormControl<null>` and `value` is always `null`.

## Validation Layer

- [ ] **FM-4**: "Is domain/business validation in a shared validator or service, not in the component?"
  → Check: Validation logic that requires domain knowledge (business rules, entity relationships, domain calculations) lives in a reusable validator function or a service — not inline in the component class.
  → FAIL: Component contains `if (settlementDate < getNextBusinessDay(currency))` inside a form setup method. This is domain logic — if another component needs the same rule, it must duplicate it.
  → PASS: `settlementDateValidator(currencyService)` as a shared validator factory that encapsulates the business rule.
  → Litmus test: would this rule need to be enforced if there were a second entry point (another component, bulk import, API)? If yes → shared validator/service. If no, it's only about this form's UX → component.

- [ ] **FM-5**: "Are domain validation rules surfaced to the user through the form?"
  → Check: If a service or backend enforces a business rule, the form should validate it client-side too — or at minimum, map server-side validation errors back to the correct form control.
  → FAIL: Service rejects an amount exceeding a threshold, but the form has no validator for it — the user submits, gets a generic error toast, and has no field-level feedback.
  → FAIL: Backend returns field-level validation errors but the component ignores them or shows a generic message instead of calling `control.setErrors()`.

- [ ] **FM-6**: "Is presentation validation kept in the component/template (not pushed into services)?"
  → Check: Simple constraints like `required`, `maxLength`, `pattern`, `email` are defined at the form control level — not wrapped in a service call.
  → FAIL: A service method that just checks `value != null && value.length > 0` — this is `Validators.required`, not domain logic. Keep it at the control level.

## Data Extraction

- [ ] **FM-7**: "Is `getRawValue()` used when disabled controls must be included?"
  → Check: When the form contains disabled controls whose values are needed (e.g., read-only fields that are part of the submission payload), `getRawValue()` is used instead of `.value`.
  → FAIL: `this.form.value` used for submission when some controls are disabled — disabled control values are excluded from `.value`, causing missing fields in the payload.

- [ ] **FM-8**: "Is the form value copied before mutation (no mutation of borrowed references)?"
  → Check: Code does not mutate objects obtained from `FormGroup.value` or `getRawValue()`. These are live references to the form's internal state — mutating them silently changes the form without triggering validation, `valueChanges`, or dirty tracking.
  → FAIL: `const val = this.form.value; val.items.push(newItem);` — mutates the form's internal array.
  → FAIL: `const data = this.form.getRawValue(); data.currencyCodes = filtered;` — overwrites a form reference property.
  → FIX: `const data = structuredClone(this.form.getRawValue());` or spread/destructure before modifying.

## Form Lifecycle

- [ ] **FM-9**: "Are dynamic validators added and removed correctly?"
  → Check: When validators are added or removed at runtime (e.g., conditional required fields), `updateValueAndValidity()` is called after the change to re-evaluate form state.
  → FAIL: `control.setValidators([Validators.required])` without calling `control.updateValueAndValidity()` — the form's validity state is stale until the next user interaction.
  → FAIL: `control.clearValidators()` without `updateValueAndValidity()` — the control may still show as invalid.

- [ ] **FM-10**: "Does form reset clear all custom state (errors, status, dynamic validators)?"
  → Check: When a form is reset (e.g., after successful submission, or when switching context), custom errors set via `setErrors()`, dynamically added validators, and programmatic status changes are also cleared.
  → FAIL: `this.form.reset()` but custom errors from `control.setErrors({ serverError: true })` persist — `reset()` clears values and marks as pristine/untouched but does NOT clear errors set via `setErrors()`.

- [ ] **FM-11**: "Does disable/enable maintain validation integrity?"
  → Check: Disabling a form group disables all its controls and excludes them from validation. If validation should still apply to some controls within a disabled group, handle them individually.
  → FAIL: `this.form.disable()` disables all controls, then `this.form.updateValueAndValidity()` — the form is always valid because disabled controls are excluded from validation. If intent was to show as read-only but still validate, disable individual controls instead.

## Submission

- [ ] **FM-12**: "Is form validity checked before submission?"
  → Check: Submit handler checks `this.form.valid` (or `this.form.invalid`) before proceeding with the action.
  → FAIL: Submit handler reads form values and sends API request without checking validity — invalid data reaches the backend.
  → NOTE: Also check that `markAllAsTouched()` is called when the form is invalid, so validation errors become visible to the user.

- [ ] **FM-13**: "Do submission errors map back to the correct form controls?"
  → Check: When the backend returns field-level validation errors, they are mapped to the corresponding form control via `control.setErrors()` — not just shown as a generic toast or alert.
  → FAIL: Backend returns `{ errors: { amount: 'exceeds limit' } }` but the component shows `showToast('Submission failed')` — the user doesn't know which field to fix.

## Custom Validator Coverage

- [ ] **FM-14**: "Does the custom validator handle the full value domain of the control?"
  → Check: Verify the validator's condition logic against edge values the control type can actually produce.
  → Common traps by type:
    - **Number controls**: negative values, `0`, `NaN` (empty input parsed), decimals, `Infinity`
    - **String controls**: empty string `''`, whitespace-only `'  '`, special characters
    - **Boolean-like checks on numbers**: `!!value` or truthiness checks — `0` is falsy, negative numbers are truthy
  → FAIL: Validator uses `value > threshold` assuming positive input, but the control accepts negative numbers — negative values bypass the intended range.
  → FAIL: Validator uses `!!control.value` as a "has value" check on a number control — `0` is treated as "no value."
  → WHY: Custom validators often encode implicit assumptions about the input domain that aren't enforced by the control type. These pass code review because the logic looks correct for the "happy path" but breaks on edge values the input can actually produce.

---

Total items: 14
