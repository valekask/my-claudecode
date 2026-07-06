---
name: dogfood
description: End-to-end QA of the active change in a real browser — map the user journeys the diff touches, walk each as the product's personas judging function AND experience, fix small safe breakages in place (with a regression test), escalate the big/ambiguous ones, run the suite, and write a durable report. The quality-gate-with-autofix superset of smoke-test. Mutates code (fixes + tests) but does NOT auto-commit by default. Drives the browser via test-browser. Manual-invoke; use as an extra quality gate on a completed small/medium change before ship.
---

# Dogfood

**Dogfood the active branch end-to-end**: don't just check that changed pages
render — walk the **user journeys** the diff touches as a real user would, judge
both **correctness and experience**, **fix** the small safe breakages you find
(each with a regression test), **escalate** the ones that need a human, verify the
suite, and leave a **durable report**. It is the QA-with-autofix superset of
`smoke-test` (which only verifies + reports).

It **drives the browser via the `test-browser` skill** and is **diff-scoped** —
proportional to the change, never a full-app sweep.

**This skill modifies code** (fixes + regression tests). It is **manual-invoke
only** and, by default, **does not commit** (see the git boundary). Use it as an
extra quality gate on a completed small/medium change, *before* ship.

**Announce at start:** "I'm using the dogfood skill."

## Boundary

- **Diff-scoped.** Test only the user-visible journeys the change touches. A
  one-route change → one small journey; don't sweep the whole app.
- **Mutates code, gated.** Applies **only small, well-understood, low-risk** fixes
  in the working tree, each with a regression test. Everything else is
  **escalated**, not forced (see the safe-fix boundary).
- **Git boundary — does NOT auto-commit by default.** Fixes and regression tests
  land in the **working tree**; it **proposes** a commit per fix (message + scope)
  but leaves committing to the human/workflow unless explicitly authorized to
  commit. (This respects a "commit only when asked" rule; a workflow that *wants*
  per-fix commits can opt in.)
- **Never pushes, never touches external trackers.**
- **Verify-only sub-work reuses `smoke-test`/`test-browser`** — don't
  re-implement driving or verdict mechanics.

## Inputs

- **The diff** — the active branch vs its base (or a named PR/branch).
- **App context** — `test-browser` resolves it from `.test-browser/`.
- **Personas** — from the project's product/strategy/vision docs if present; else
  ask for (or infer) the 1–2 primary personas. Used to judge *experience*, not
  just function.
- **Output dir** — where the durable report lands. Invoker-supplied; default
  `docs/dogfood-reports/<date>-<branch>.md`. An orchestrator (management cockpit)
  points it at the **task dir**.

## The Process

### 1 — Diff analysis
Understand every change vs trunk. Identify the **user-visible** surface (ignore
pure-internal changes with no observable behaviour).

### 2 — Journey mapping
For each user journey the diff touches, map it as a small **flow** (a Mermaid
`flowchart` is a good form): entry point → actions → branches → side effects →
**true end state** (e.g. "email sent → lands in the correct thread", not just "the
button clicked"). Journeys, not isolated widgets.

### 3 — Persona grounding
Ground each flow in the product's **personas**. You'll judge two things per step:
- **Function** — right data, right destination, no errors.
- **Experience** — friction a functional test misses. Record these as **"paper
  cuts"** (small frictions that pass functionally but degrade the experience).

### 4 — Drive + judge (via test-browser)
Walk each flow in the browser through `test-browser`. For every step, judge
function **and** experience. Capture evidence (screenshots, console) on anything
broken or rough.

### 5 — Fix / escalate (the loop)
For each defect:
- **Safe to fix?** — small, well-understood, low-risk, within the change's scope.
  - **Yes** → fix in the working tree, **add a regression test that fails before /
    passes after**, re-drive the flow to confirm. Record it (and propose a
    per-fix commit; don't commit unless authorized).
  - **No** → **escalate**: record under **"Decisions for a human"** with the
    trade-offs. Anything that needs an **architecture/schema decision**, **changes
    product behaviour**, **spans many files**, or has **plausible competing
    solutions** is escalated, not forced.
- Re-test after each fix before moving on. Repeat across all flows until the matrix
  is complete or blocked on escalations.

### 6 — Suite verification
Before declaring the branch "ready", run the **project's existing test suite** plus
the **new regression tests**. Not ready until both the browser matrix and the
automated suite pass.

### 7 — Durable report
Write the report to the output dir. Include:
- the tested **journeys** (flowcharts),
- the **test matrix** (per-flow function/experience result),
- **autonomous fixes** applied (+ their regression tests),
- **paper cuts** / experiential issues,
- **Decisions for a human** (escalations, with trade-offs),
- learnings + a **final verdict** (reflecting both automated results and open
  escalations — nothing hidden or forced).

## Safe-fix boundary (the rule)

Fix autonomously only when the change is **small, well-understood, low-risk, and
in scope**. **Escalate** (don't fix) when it requires an architecture/schema
decision, changes product behaviour, spans many files, or has plausible competing
solutions. A scenario can **pass functionally but still carry paper cuts** —
record those; they don't block, but they surface.

## Stopping / blocked states
- **Blocked on a human decision** → surface it clearly; on resume, **don't
  silently re-run** blocked scenarios.
- The **verdict** reflects both the automated matrix and human escalations.

## Relationship to the other browser skills
- **`test-browser`** — the driving primitive dogfood uses for all browser work.
- **`smoke-test`** — the verify-only floor (scenarios → verdict, no fixing).
  Dogfood is its superset: journeys + personas + fixing + suite + durable report.
  Use `smoke-test` for a quick change-verification gate; use `dogfood` for a
  deeper QA-and-fix pass on a completed change.

## Rules
- **Diff-scoped, manual-invoke, mutates code.**
- **No auto-commit by default** — fixes land in the working tree; propose commits,
  don't make them unless authorized. **Never push / never touch trackers.**
- **Safe-fix only; escalate the rest** — never force an architectural or
  behaviour-changing fix.
- **Not "ready" until the browser matrix AND the automated suite (incl. new
  regression tests) pass.**
- **Reuse `test-browser`** for driving; don't re-implement it.
