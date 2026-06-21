# Standards Drift Checklist

Checks whether the change drifts from the project's **documented** standards — the
decisions and rules that live outside the code: `docs/adr/` (Architecture Decision
Records), `CLAUDE.md` (project conventions + protected files), and the established
patterns in neighbouring code.

**Inputs required:** before checking, read `docs/adr/README.md` (and any ADR relevant
to the changed area), the project `CLAUDE.md`, and a sample of the existing files
adjacent to the change. Drift can only be judged against these sources.

---

## Architecture Decision Records

- [ ] **SD-1**: "Does the change contradict an accepted ADR?"
  → Check: Cross-reference the changed area against `docs/adr/README.md`. The change must not re-introduce an approach an ADR rejected, or violate a constraint an ADR established.
  → FAIL: The diff implements something an accepted ADR explicitly decided against (e.g., uses a pattern the ADR superseded).

- [ ] **SD-2**: "Does the change remove or weaken a guard/constraint an ADR put in place?"
  → Check: If an ADR documents a guard, invariant, or defensive check as deliberate, the change must not delete or loosen it without a superseding ADR.
  → FAIL: A check/guard whose *why* is recorded in an ADR is removed with no new ADR superseding that decision.

- [ ] **SD-3**: "Does a non-obvious architectural change have (or warrant) an ADR?"
  → Check: A change with non-recoverable rationale (trade-offs, constraints) should be backed by an ADR, per the project's ADR policy.
  → FAIL: A complex/architectural change lands with rationale that exists nowhere durable, and no ADR is added or referenced.

## Project Conventions (CLAUDE.md)

- [ ] **SD-4**: "Does the change comply with the rules in `CLAUDE.md`?"
  → Check: Compare the diff against the project's `CLAUDE.md` Code Conventions (state management, naming, file organization, testing, styling rules).
  → FAIL: The diff violates an explicit `CLAUDE.md` rule (e.g., a "NO X" / "no async/await" style constraint is broken).

- [ ] **SD-5**: "Are Protected Files left untouched (unless the task explicitly required it)?"
  → Check: Compare changed files against the `CLAUDE.md` Protected Files list (dependency manifests, build/monorepo config, prod env files, git config/hooks).
  → FAIL: A protected file was modified without the change being an explicit, intended part of the task.

- [ ] **SD-6**: "Do debug logs follow the documented logging convention?"
  → Check: If `CLAUDE.md` mandates a debug-logging format (e.g., `console.log` with `JSON.stringify(value, null, 2)` for non-primitives), new logs follow it.
  → FAIL: Debug logging deviates from the documented format, or stray debug logs are left in non-debug code.

- [ ] **SD-7**: "Were dependencies added/changed against the manifest policy?"
  → Check: New libraries or version bumps in dependency manifests are intended and consistent with how the project manages dependencies.
  → FAIL: A dependency is added/upgraded incidentally or against the project's stated manifest-change policy.

## Consistency With Existing Code

- [ ] **SD-8**: "Is the change consistent with established patterns in adjacent code?"
  → Check: New code follows the structure, idioms, and conventions of the surrounding module (folder layout, file naming, error handling, state patterns) rather than introducing a one-off style.
  → FAIL: The change introduces a divergent pattern where a well-established local convention already exists, without justification.

- [ ] **SD-9**: "Does the change reuse existing utilities/abstractions instead of reinventing them?"
  → Check: Functionality that already exists (shared helpers, services, pipes, base classes) is reused rather than re-implemented inline.
  → FAIL: The diff re-implements something the project already provides, drifting from the canonical abstraction.

- [ ] **SD-10**: "Is terminology consistent with the project's domain language?"
  → Check: Names for domain concepts match those used in existing code, ADRs, and docs — no synonyms introduced for an already-named concept.
  → FAIL: The change names an existing domain concept differently (a synonym), fragmenting the ubiquitous language.

---

Total items: 10
