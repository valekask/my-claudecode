# Naming Checklist

---

## Clarity & Intent

- [ ] **NM-1**: "Is the name short, intuitive, and descriptive (S-I-D)?"
  → Check: Read the name in isolation — can someone guess what it refers to?
  → FAIL: Name is ambiguous, could refer to multiple things, or requires reading surrounding code to understand.

- [ ] **NM-2**: "Does the function name follow A/HC/LC pattern (action + high context + low context)?"
  → Check: Function name starts with a verb and includes the domain context. Examples: `fetchUserMetrics`, `shouldRefreshTokens`.
  → FAIL: Name is vague (`process()`, `handle()`, `manage()`) or missing context (`getData()` instead of `getUserMessages()`).

- [ ] **NM-3**: "Are booleans in positive form with is/has/can/should prefix?"
  → Check: Boolean variables and methods use positive phrasing.
  → FAIL: Uses negative form (`isNotReady`, `isDisconnected`) causing double negation in conditions, or missing prefix (`empty` instead of `isEmpty`).

- [ ] **NM-4**: "Are abbreviations avoided?"
  → Check: Names are spelled out fully.
  → FAIL: Uses abbreviations like `onItmClk`, `usr`, `btn`, `msg`, `cfg` instead of `onItemClick`, `user`, `button`, `message`, `config`.

## Consistency

- [ ] **NM-5**: "Is context duplication avoided?"
  → Check: Name doesn't repeat the class/module context it lives in.
  → FAIL: `MenuItem.handleMenuItemClick()` instead of `MenuItem.handleClick()`. `UserService.getUserById()` instead of `UserService.getById()`.

- [ ] **NM-6**: "Is the same name used everywhere for this purpose — and ONLY this purpose?"
  → Check: Search codebase for this name. Does it always mean the same thing? Is a different name used elsewhere for the same concept?
  → FAIL: `items` means products in one file and menu entries in another. Or same data called `users` in one place and `people` in another.

- [ ] **NM-7**: "Are singular/plural used correctly for single vs array values?"
  → Check: Arrays/collections use plural, single values use singular.
  → FAIL: `const friend = ['Bob', 'Tony']` or `const friends = 'Bob'`.

## Project Conventions

- [ ] **NM-8**: "Do subscriptions follow `subscribeOn...Changes` pattern?"
  → Check: RxJS subscription setup methods use the project naming convention.
  → FAIL: Subscription method named `listenToData()`, `watchItems()` instead of `subscribeOnDataChanges()`.

- [ ] **NM-9**: "Do variable names reflect the expected result at the usage site?"
  → Check: Where the variable is consumed, does the name make sense?
  → FAIL: `const hasData = itemCount > 3` used in `<Button disabled={!hasData}>` — should be `const disabled = itemCount <= 3`.

- [ ] **NM-10**: "Are named constants used instead of magic numbers/strings?"
  → Check: No literal values like `86400`, `365`, `'pending'`, `500` in logic.
  → FAIL: `if (timeout > 86400)` instead of `if (timeout > SECONDS_PER_DAY)`. `if (status === 'pending')` instead of using an enum.

## Precision

- [ ] **NM-11**: "Are vague status/generic words avoided?"
  → Check: Names like `status`, `data`, `info`, `temp`, `result`, `flag` are replaced with specific alternatives.
  → FAIL: `blinkStatus` instead of `cursorVisible`. `getCount()` instead of `getActiveItemCount()`.

- [ ] **NM-12**: "Are type names descriptive enough to document declarations?"
  → Check: Custom types/interfaces convey meaning beyond primitive types.
  → FAIL: Using `Pair<string, number>` or `Record<string, any>` where a named interface (`UserScore { name: string; score: number }`) would clarify intent.

---

Total items: 12
