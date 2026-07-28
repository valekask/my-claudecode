# Naming Checklist

The human-facing source for these conventions is the project's `docs/NAMING.md`. This checklist is the agent-facing form of the same rules — when one changes, update both.

---

## Clarity & Intent

- [ ] **NM-1**: "Is the name short, intuitive, and descriptive (S-I-D)?"
  → Check: Read the name in isolation — can someone guess what it refers to? The name must also read naturally, close to common speech.
  → FAIL: Name is ambiguous, could refer to multiple things, or requires reading surrounding code to understand. Or it uses an invented/unnatural verb form: `shouldPaginatize`, `isPaginatable` instead of `shouldPaginate`, `hasPagination`.

- [ ] **NM-2**: "Does the function name follow A/HC/LC pattern (action + high context + low context)?"
  → Check: Function name starts with a verb and includes the domain context. Examples: `fetchUserMetrics`, `shouldRefreshTokens`.
  → FAIL: Name is vague (`process()`, `handle()`, `manage()`) or missing context (`getData()` instead of `getUserMessages()`).
  → NOT a failure: context omitted where the language makes it idiomatic — a pure `filter(list, predicate)` operating on an array needs no `filterArray`.

- [ ] **NM-3**: "Are booleans in positive form with an allowed prefix?"
  → Check: Boolean names start with either a form of "to be" (`is`, `was`, `will` — by far the most common) or an auxiliary verb (`has`, `can`, `should`, `must`), and use positive phrasing.
  → FAIL: Uses negative form (`isNotReady`, `isDisconnected`) causing double negation in conditions, or missing prefix (`empty` instead of `isEmpty`). The prefix may be omitted only where the surrounding type makes the name unambiguous on its own.
  → NOT a failure: the negative form when consumers would otherwise negate it at nearly every usage site (see NM-9 — the name should reflect the expected result). Angular `@Input` boolean setters using an imperative verb, since templates invoke them rather than other code.

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

## File Naming (added & renamed files only)

Applies ONLY to files **added or renamed** in this diff. Never flag a pre-existing file that the diff merely edited. Every finding MUST state the exact proposed new filename — if you can't name a better one, don't flag it.

Terminology: **stem** = the file name with its type suffix and extension stripped (`filter-server-config-parser` in `filter-server-config-parser.utils.ts`).

- [ ] **NM-13**: "Is the file name kebab-case and lowercase?"
  → Check: Words separated by hyphens, no camelCase, no underscores, no capitals.
  → FAIL: `parserUtils.ts`, `parser_utils.ts`, `Parser.utils.ts`.

- [ ] **NM-14**: "Does the stem name a thing, not a bucket?"
  → Check: Strip the suffix. What's left must name the domain concept the file is about. Note: `.utils.ts` is an established suffix in this project and is fine — the requirement is on the stem, not the suffix.
  → FAIL: Stem is a container word carrying no domain meaning — `utils.ts`, `helpers.ts`, `common.ts`, `misc.ts`, `shared.ts`, `data.ts`, `helpers.utils.ts`. Fix by naming the concept: `filter-server-config-parser.utils.ts`.

- [ ] **NM-15**: "Is the stem specific enough for where the file lives?"
  → Check: A single-word stem is acceptable only when its context comes from the path — the immediate directory names that same concept (`theme/theme.service.ts`, `hint/hint.service.ts`), or the lib is dedicated to it (`libs/utils/src/lib/currency/currency.utils.ts`). If the file sits in a generic bucket directory (`utils/`, `services/`, `helpers/`, `shared/`, `lib/`, `src/`) and the code is specific to one feature/module, the stem must carry that feature or intent.
  → FAIL: `feature-grouping/src/lib/services/grouping.utils.ts`; `filters.utils.ts` inside `feature-filters/src/lib/utils/`; `blob.service.ts` in a `services/` dir. Fix: `ilo-template-filters.utils.ts`, `csv-export-blob.service.ts`.

- [ ] **NM-16**: "Does the file name match the identifier(s) inside it?"
  → Check: One primary namable identifier → the file name reflects it (kebab-case of the same words, in the same order): `csv-export-blob.service.ts` → `CsvExportBlobService`. Multiple identifiers → the name states their common theme.
  → FAIL: `blob.service.ts` exporting `CsvExportBlobService`. `data.utils.ts` exporting only `parseFilterServerConfig`. Words reordered between file and class. Or the exports share no common theme, so no honest name exists — split the file instead of renaming it.

- [ ] **NM-17**: "For a single-word stem, is the basename unique in the repo?"
  → Check: Run this ONLY when the stem is a single word — skip multi-word stems entirely, they're specific enough. Then search the repo for the basename.
  → FAIL: The same basename already exists in an unrelated feature (two `resources.service.ts`, two `filters.utils.ts`) — imports, file search, and stack traces become ambiguous. Prefix the new one with its feature.

- [ ] **NM-18**: "Does the type suffix carry a distinction the repo's established suffixes don't already cover?"
  → Check: First list comparable files (siblings + same-lib files) to see which suffixes are established in this repo — do not rely on memory. If the suffix is already in use → PASS, flag nothing.
  → FAIL (suffix is a synonym): The suffix restates what `.utils` or `.service` already means — `.helper.ts`, `.helpers.ts`, `.common.ts`, `.functions.ts`, `.misc.ts`. Same concept under two names. Fix: use the established suffix (`.utils.ts`) and put the meaning in the stem.
  → FLAG FOR VERIFICATION (suffix is new but distinct): `.adapter`, `.manager`, `.facade`, `.builder` name roles the established set doesn't cover, so a new one may be justified. Do NOT call it wrong. Flag it and write the verification test into the finding itself: "`<file>` introduces suffix `.<x>`, not used elsewhere in this repo. Verify the contents match what `.<x>` promises — adapter = translates between two shapes; manager = owns the lifecycle/state of a resource; facade = single entry point over several collaborators; builder = incremental construction. If they match, this is fine and sets precedent for the suffix. If the file is just pure functions, rename to `.utils.ts`."
  → Note: `.mapper` is NOT on that list — shape transformation is named `convert` in this project (see NM-19), so a mapper file belongs in `.utils.ts` with a `convert*` export.

## Action Vocabulary

- [ ] **NM-19**: "Does the action verb come from the project's vocabulary, with no synonym introduced?"
  → Check: The established verbs are `get`, `set`, `reset`, `fetch`, `remove`, `delete`, `compose`, `convert`, plus `build`, `format`, `parse`, `normalize` (widely established in the codebase). A new verb is fine when it names a role none of these cover — a verb that merely restates one of them is not.
  → FAIL: `mapData()` where the project uses `convert` for shape transformation (`convertData`). `retrieveUser()` / `loadUser()` where `fetch`/`get` is the convention. `eraseItem()` where `delete` is.

- [ ] **NM-20**: "Do `get` and `fetch` match sync vs async?"
  → Check: `get` accesses data already in hand and returns immediately. `fetch` is a request taking indeterminate time (HTTP, async). Read the body to decide.
  → FAIL: `getUsers()` that issues an HTTP call or returns a cold `Observable` from the API layer — should be `fetchUsers()`. Or `fetchFruitCount()` that just reads `this.fruits.length` — should be `getFruitCount()`.

- [ ] **NM-21**: "Do `remove`/`delete` and `add`/`create` match what the code does?"
  → Check: `remove` takes something out of a destination (pairs with `add`); `delete` erases it from existence (pairs with `create`). `add` needs a destination, `create` does not. Read the body: does it filter a collection, or destroy the entity?
  → FAIL: `deleteFilter()` that only filters a selected-filters array (should be `removeFilter`). `removePost()` that calls the delete endpoint (should be `deletePost`). `createItemToList()` — `create` takes no destination.

## Booleans

- [ ] **NM-22**: "Does the boolean read as a state, not a command or an interface?"
  → Check: A boolean name must not sound like an instruction to the object, an adjective-ambiguous word, or a capability interface.
  → FAIL: `showPopup` (sounds like it shows the popup → `canShowPopup` / `hasShownPopup`), `empty` (adjective or verb? → `isEmpty`), `withElements` (sounds like it holds them → `hasElements`), `closeable` (reads like an interface → `canClose`), `closingWindow` (a bool or a window? → `closesWindow`).

## Language & Casing

- [ ] **NM-23**: "Are identifiers English and camelCase?"
  → Check: Names use English words; variables, functions, methods, and properties are camelCase.
  → FAIL: `amigos`, `primerNombre` instead of `friends`, `firstName`. `page_count`, `should_update` for a TypeScript identifier.

- [ ] **NM-24**: "Is all authored text in the diff English?"
  → Check: Comments, JSDoc, TODO/FIXME notes, log and error message strings, thrown `Error` messages, and test titles (`describe`/`it`) are written in English. Non-Latin script (Cyrillic, CJK, Greek) is a definite failure; Latin-alphabet non-English (`// tarkista arvo`) is also a failure when recognizable.
  → NOT a failure: i18n/locale/translation files and message catalogs (foreign text is their purpose); test fixtures that deliberately exercise encoding, locale, or collation; verbatim quotes of third-party content.
  → FAIL: `// проверяем что фильтр применился`, `throw new Error('Некорректный фильтр')`, `it('должен конвертировать фильтры', …)`.

---

Total items: 24
