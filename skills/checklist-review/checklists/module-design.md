# Module Design Checklist

Checks the change against the Module Design rules in the `writing-plans` skill's
`module-design.md` — read that file first; it holds the rules and their reasoning, this file only
the code-level checks. Each item names the rule it comes from.

Unlike most agents, this one reads across files: an owner, its consumers, its utils and its specs.
A flag is a reason to read the code, never a count that fails on its own.

**Only what the change introduced or made worse.** A problem that already existed on the base
branch is not a finding — unless the change adds to it (one more caller-set field, one more copy).

**Checks overlap.** MD-1/MD-2/MD-4 and MD-7/MD-8/MD-9 often share one root cause. Flag it once,
citing every check it breaks, rather than once per check.

---

## Contract (rule 1)

- [ ] **MD-1**: "Does every input arrive through the contract?"
  → Check: Inputs come as method parameters, `@Input`, or a snapshot taken at the call. Compare changed signatures with the base branch.
  → FAIL: A parameter was removed and the owner now reads the value from an injected global (`OptionsService`, a root store) instead; or the owner reads a value at some later moment that the caller should have passed at the call.

- [ ] **MD-2**: "Are there public fields that callers set before calling?"
  → Check: Public mutable fields on services and stores, and who writes them.
  → FAIL: `exportService.timeZoneId = tz; exportService.export()` — the caller pushes context through fields instead of passing it in.

## Ownership (rule 2)

- [ ] **MD-3**: "Does each behaviour have exactly one owner?"
  → Check: Where the decisions, rules, state and state changes of each changed behaviour live.
  → FAIL: The same rule decided in two places (component and service, or two components); a component making a decision the owning store or service should make; the same wiring copied into two components; an owner doing another owner's job (a data service timing UI paint, a component keeping a second copy of the owner's data).

- [ ] **MD-4**: "Can consumers use the owner without knowing its internals?"
  → Check: The public API is smaller and simpler than what it hides (deep module). Callers make one call per intent.
  → FAIL: Callers must call several methods in a set order, read internal fields, or branch on the owner's internal modes; many small public methods that each do trivial work (shallow module); helpers that decide what happens are public instead of private.

## State (rule 3)

- [ ] **MD-5**: "Is the job's state one named value?"
  → Check: A process or result is one union keyed by a `status` / `kind` field with per-state data. Count changeable fields per owner.
  → FAIL: State derived from nullable fields (`isExporting$ = format !== null`); one field standing for several states; two fields that must agree; an owner gaining changeable fields past 4 without asking whether one union would replace them.

- [ ] **MD-6**: "Do outcomes reach the caller as state or data?"
  → Check: How refused, cancelled and failed results surface.
  → FAIL: An outcome visible only as a side effect (a notification, a log), so callers and tests can't see it; a function named `build*` / `get*` that shows a message and returns `EMPTY`.

## Utils (rule 4)

- [ ] **MD-7**: "Do utils only compute?"
  → Check: Every changed or added function in a `*.utils.ts` file or a utils library.
  → FAIL: A util returns a mode, tier or policy flag the caller branches on (`getExportBuildMode() → 'worker' | 'too-big'`); a util shows a message, injects a service or has another side effect; behaviour rules (limits, allowed actions) defined in a util instead of the owner.

- [ ] **MD-8**: "Is new shared code earned by a second consumer?"
  → Check: New exports added to a shared library (utils, ui, shared) and how many features use them.
  → FAIL: A new shared util or symbol used by one feature only; a domain-specific function added to the domain-free utils library.

## Flow (rule 5)

- [ ] **MD-9**: "How many files does a reader open to follow the main flow?"
  → Check: Trace the main user question the change serves from the entry point to the result, in reading order, counted by the rule in `module-design.md`. Count the base branch the same way. When a plan exists, compare with its *Flow map*.
  → FAIL: A file in the flow that only passes calls through; logic of one owner spread across files a reader must combine; the actual path notably longer than the plan's Flow map with no recorded reason. Never flag a short path that merges unrelated jobs as good — rule 5 cuts both ways.

## Tests (rule 6)

- [ ] **MD-10**: "Do tests go through the contract?"
  → Check: What the specs import and call, and who else uses those exports.
  → FAIL: An export used only by specs; a layer, injection token or wrapper whose only other user is a test; the contract widened so a test can reach inside.

---

Total items: 10
