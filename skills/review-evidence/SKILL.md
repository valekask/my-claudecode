---
name: review-evidence
description: Establish the facts behind open review findings before anyone decides on them — reproduce each one (a unit test or a browser check), collect the code, acceptance criteria and ADR guards it touches, and measure its blast radius — and write them to `<task>-<slug>-review-evidence.md`. Facts only: no opinions, no fixes, and the worktree is left exactly as found. Use after `polish` (or a failed verify) when findings are open, before deciding them — by hand, or as the first step of an orchestrator's post-review pipeline; `review-decide` reads its output.
model: sonnet
effort: high
---

# Review evidence

Turns "a reviewer says X is wrong" into "here is what actually happens, and how far a fix would
reach". The decider — a human or `review-decide` — then judges facts instead of a reviewer's claim.

**Announce at start:** "I'm using the review-evidence skill to reproduce the open findings."

**Facts only.** No recommendation, no severity opinion, no fix. The decider must not be anchored by
this step any more than by the reviewer.

## Input

`review-evidence <task>-<slug>` — the task folder `.claude/temp/<task>-<slug>/`. Read:

- `<task>-<slug>-review.md` — every item whose `**Status:**` is `open`. Use its numbers.
- `<task>-<slug>-smoke-result.json`, if present and newer than `review.md`'s last update — every
  scenario that is not `pass` becomes an item (`V-<scenario id>`).
- `<task>-<slug>-final-check.md`, if present with `verdict: fail` — each problem line becomes an item
  (`F-<n>`).
- `<task>-<slug>-spec.md` — the acceptance criteria, to name which ones an item touches.

No open item → write nothing, say so, and stop.

## Leave the worktree as you found it

Record `git status --porcelain` before you start; it must be identical when you finish. An
orchestrator decides from file freshness, so a stray edit here re-triggers review on its own.

## Per item

1. **Read the code** the item points at — enough to know how it really behaves, not just its name.
2. **Reproduce it**, cheapest proof first:
   - **Unit test** — write a test that should fail if the finding is real, run it, record pass/fail
     and the output. Then **delete it**, and paste its source into the evidence file: the fixer reuses
     it as the regression test.
   - **Browser check** — only when the finding is about what the user sees or does, and only when the
     app is already served (the caller owns the serve; never start one). Drive it with `test-browser`
     using the project's `.test-browser/` config; save screenshots and console lines to
     `.claude/temp/<task>-<slug>/assets/evidence/`. Not served → `could not check: app not served`.
   - Neither possible → `could not check` with the reason.
3. **Collect context:** the ACs it touches (by id), and any ADR guard on the code involved
   (`docs/adr/README.md` → the relevant ADR's edge cases).
4. **Measure the blast radius of the fix the finding implies** — counts, not adjectives:
   - **callers** of the code the fix would change (search; `nx graph` / `nx affected` for libraries);
   - **files outside the change** (compare with `git diff --name-only` plus untracked files);
   - **shared code** — is the code in a shared library other projects import?
   - **contract change** — would a public input/output, an API call, a stored shape or an event change?

## Output

Write `.claude/temp/<task>-<slug>/<task>-<slug>-review-evidence.md`. If one already exists from an
earlier round, rename it to `<task>-<slug>-review-evidence.r<n>.md` first (next free `n`).

````markdown
# <task> — review evidence (round <n>, <YYYY-MM-DD>)

## 2. <the finding, as review.md states it>
- **Result:** reproduced | not reproduced | could not check — <reason>
- **Proof:** <test name + output summary | screenshot path + what it shows | what was read>
- **Repro test:** (when one was written)
  ```ts
  <source>
  ```
- **Code:** <file:line — symbol> (one line each)
- **ACs touched:** AC-3, AC-7 | none
- **ADR guards:** <ADR id — the guard> | none
- **Blast radius:** callers <n> · files outside the change <n> · shared code yes/no · contract change yes/no — <what>
````

End with exactly one line, so a caller can detect completion:

> Evidence saved to `<absolute path>`.

## Never

- Recommend, rank or fix anything — that is `review-decide`'s or the user's call.
- Leave a test, a debug line or any other change in the worktree.
- Start or stop a dev server.
- Mark an item `reproduced` without a proof you ran in this session.
