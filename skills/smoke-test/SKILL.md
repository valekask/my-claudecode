---
name: smoke-test
description: Verify a web app against a set of scenarios and emit a machine-readable pass/fail/blocked verdict. Drives the browser via the test-browser skill, judges expected vs actual per scenario, captures evidence on failure, and writes a verdict the caller (or an orchestrator) reads. Can propose scenarios from a diff via the app-map's file→route table. Verify-and-report ONLY — never fixes code, ships, or updates trackers. Use at a verify gate or standalone; scenarios + verdict live in the task dir (or `.test-browser/.temp/` for ad-hoc runs).
---

# Smoke-test

The **scenario-verification** layer. Given a set of test scenarios (steps +
expected results), it drives them in a real browser, judges expected vs actual,
and emits a **machine-readable verdict** (`pass`/`fail`/`blocked`). It runs
identically whether you invoke it by hand or an orchestrator dispatches it.

It **reuses the `test-browser` skill** for all browser work (navigation, auth,
selectors, evidence) — this skill owns only *what to test* and *what the result
means*, never the driving mechanics.

**Announce at start:** "I'm using the smoke-test skill."

## Boundary (defend it)

- **Verify + report only.** Run the scenarios, judge expected vs actual, save
  evidence, emit a verdict. **Never fix code, never ship, never push, never edit
  trackers/boards.** A `fail` is reported — the fix loop is orchestrated *outside*
  this skill (that's `dogfood`'s job, or a human's).
- **Augments the human gate, doesn't replace it.** A `pass` gathers evidence; it
  does not auto-approve or auto-advance. **Halt on non-`pass`.**
- **Driving belongs to `test-browser`.** Don't re-implement navigation/auth/
  selectors here — call the `test-browser` skill.

## Inputs

- **Scenarios** — steps + expected results. In order of preference: supplied by the
  invoker (a path the caller points to), **derived from the spec's acceptance
  criteria** (the primary path — see below), or **proposed from a diff** (fallback
  for ad-hoc runs with no spec).
- **App context** — resolved by `test-browser` from the project's `.test-browser/`
  dir (base URL, credentials, app-map). This skill doesn't read it directly.
- **Output dir** — where the verdict + report land. **Invoker-supplied**; defaults
  to `<project>/.test-browser/.temp/` for ad-hoc runs. Orchestrators (e.g. a
  management cockpit) point it at the **task dir** so the verdict travels with the
  task and the cockpit can read it.

### Deriving scenarios from acceptance criteria (primary)

When the task dir has a spec with an **Acceptance Criteria** section and no scenario
set exists yet, derive the scenarios from the AC — not from the diff. The AC state
what must be true; the diff only shows what was built, so AC are the source that can
still catch a criterion nobody implemented.

1. Read the numbered AC from `<task>-<slug>-spec.md`.
2. For each AC, decide whether it is **observable in the UI**. If yes, write one or
   more scenarios that would prove it — behaviour-level steps + expected results,
   routes from the app-map (`test-browser` resolves selectors live).
3. **Every scenario cites the AC it covers** (`covers: AC-2`). One AC may need
   several scenarios; one scenario may cover several AC.
4. **Account for every AC — never silently drop one.** An AC you do not turn into a
   scenario is listed as **declined** with a one-line reason (e.g. "AC-4: store-level
   logic, no UI surface — expect unit coverage"; "AC-6: perf feel, not
   machine-observable"). Declined AC go in the scenario file *and* the verdict, so a
   criterion no one covers is visible rather than lost between skills.
5. If an AC is observable but you cannot construct a scenario because the UI for it
   does not appear to exist, that is **not** a decline — record it as a scenario that
   fails, because a missing implementation is exactly what the AC is there to catch.
6. Write the set to the scenario file in the output dir and surface it so a human can
   adjust before/after the run.

### Proposing scenarios from a diff (fallback)

For ad-hoc runs with no spec/AC to work from ("smoke-test the current changes"):
1. Get the diff (`git diff` — branch/staged/PR per the caller).
2. Map changed files → affected routes using the **file→route table in the
   app-map** (`.test-browser/app-map.md`). Missing/rough table → note it; test the
   obvious affected routes + homepage.
3. Draft scenarios covering the changed routes' success criteria + the obvious
   regressions; behaviour-level steps with expected results (`test-browser`
   resolves selectors live per the app-map).
4. Write them to the scenario file in the output dir and proceed. Surface the
   proposed set so a human can adjust before/after the run.

## The Process

### 0 — Preflight (delegated)
Hand off to **`test-browser`** to resolve `.test-browser/` and run the auth guard.
If it reports the dir/creds missing or auth `FAILED` → verdict **`blocked`**
(don't guess). If the app isn't serving → **`blocked`**.

### 1 — Run scenarios (via test-browser)
For each scenario, in the same persistent session, using `test-browser` to drive:
- Navigate (app-map route + base URL); wait for the load landmark.
- Perform the steps via the preferred selectors; a miss resolves **live for this
  run only** (noted, not persisted to the app-map).
- Capture the actual result; compare to expected. Mark ✅ / ❌ / ⚠️ / ⏭️.
- **Evidence:** screenshot on every ❌ and ⚠️; one final-state shot on ✅; dump
  `console` on every ❌.

### 2 — Verdict + evidence
- **Per-scenario:** ✅ pass · ❌ fail · ⚠️ known (documented deviation) · ⏭️ skipped.
- **Overall (roll-up):**
  - `fail` — any unresolved ❌ (test ran, change is wrong)
  - `blocked` — couldn't complete (missing context, auth FAILED, app won't serve,
    page errors before the scenario, browser crash)
  - `pass` — all ✅ (plus any ⚠️ / ⏭️)
- Write the outputs (below). **Halt on non-`pass`** — report and stop; never
  advance or ship.

## Outputs (into the invoker's output dir)

| File | Content |
|------|---------|
| `<task>-<slug>-smoke.md` | scenarios + expected (input), with per-scenario ✅/❌/⚠️/⏭️ + actual filled in, the `covers: AC-n` mapping, and any **declined AC** with reasons |
| `<task>-<slug>-smoke-result.json` | **machine record** the orchestrator parses (shape below) |
| `assets/smoke/*.png`, `*.log` | screenshots + console dumps, referenced by path |

**Two files, no separate human report.** The annotated `<task>-<slug>-smoke.md` *is* the
human-readable record — scenarios, expected, actual, evidence paths, verdict, all in
one place. Report the outcome in your response; don't write a third file that
restates it.

Verdict `.json` shape:
```json
{
  "id": "<scenario-set id>",
  "verdict": "pass|fail|blocked",
  "auth": "REUSED|LOGGED_IN",
  "base_url": "…",
  "counts": { "pass": 0, "fail": 0, "known": 0, "skipped": 0 },
  "scenarios": [
    { "id": "S1", "name": "…", "status": "pass|fail|known|skipped",
      "covers": ["AC-2"],
      "expected": "…", "actual": "…", "evidence": ["assets/smoke/S1.png"] }
  ],
  "declined_ac": [ { "id": "AC-4", "reason": "store-level logic, no UI surface" } ],
  "live_fallbacks": [ "…elements resolved live, not in the app-map…" ],
  "started": "ISO-8601", "finished": "ISO-8601"
}
```

Scenarios + verdict are **task-scoped** — they belong in the **task dir**
(with the task's spec/plan/result), not in `.test-browser/`. Only the throwaway
run artifacts (screenshots, console) sit under `.test-browser/.temp/`.

## Rules

- **Never** fix code, ship, push, or edit the caller's trackers/boards.
- **Delegate all driving to `test-browser`** — auth, selectors, navigation,
  evidence capture, the persistent session.
- **Autonomous until unsure.** Run the whole scenario set without prompting; only
  stop to escalate on a genuine `fail`/`blocked` or a real ambiguity.
- **Halt on non-`pass`** — report and stop; the fix loop lives outside this skill.
- **Account for every acceptance criterion** — covered by a scenario or explicitly
  declined with a reason. An AC that appears in neither list is a bug in this run.
