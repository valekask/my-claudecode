---
name: executing-simple
description: Implement a Simple-tier spec inline, straight from the spec, with no plan phase — locate the code, make the change, add unit tests, write the result file. Use when a `<task>-<slug>-spec.md` exists but no plan does, and the task is small enough that planning it would be pure overhead. If a plan exists, use subagent-driven-development instead.
---

# Executing Simple

## Overview

The **inline lane for Simple-tier work**. Implements the spec directly in the current worktree — locate the code, make the change, add unit tests where the project's convention expects them, write the result file. No plan, no subagents, no reviews.

**Announce at start:** "I'm using the executing-simple skill to implement this spec inline."

**Which executor:** the rule is the artifact, not a judgment call.

| What exists in the task dir | Executor |
| --- | --- |
| a `<task>-<slug>-plan.md` | `subagent-driven-development` |
| a spec but **no** plan | `executing-simple` (this skill) |

If a plan exists, stop and use `subagent-driven-development` — a plan means someone decomposed the work and approved a structure, and this skill would throw that away.

## Input

**The spec:** `.claude/temp/<task>-<slug>/<task>-<slug>-spec.md`, produced by `brainstorming` (typically `brainstorming --agentic`). Not the proposal — the proposal is raw input to brainstorming and carries no approved decisions.

The spec must already carry:

- **numbered Acceptance Criteria** (`AC-1`, `AC-2`, …)
- a **ratified complexity tier** (`Simple` / `Medium` / `Complex`)

This skill **reads both and writes neither**. If either is missing, the spec isn't finished — stop and report `needs full flow`; `brainstorming` owns that artifact.

Read the spec, the proposal for context, and anything in `assets/` before touching code. Scan `docs/adr/README.md` for ADRs covering the area you're about to change.

## What this skill does

1. **Locate the code** the spec describes — read enough of it to know how it actually behaves, not just what it's named.
2. **Make the change**, following the project's conventions (`CLAUDE.md`, `docs/`).
3. **Add unit tests** where the project's convention expects them for the code you touched.
4. **Run the tests you added and the ones covering the code you changed.** Not the full suite, not a build, not a lint pass — those belong to `polish`.
5. **Write the result file** to `.claude/temp/<task>-<slug>/<task>-<slug>-result.md` (format below).
6. **Emit the handoff line exactly**, then stop:

> Result saved to `<absolute path to <task>-<slug>-result.md>`.
> Use polish skill before verification.

The `Result saved to` line mirrors `Spec saved to` / `Plan saved to`, so an orchestrator can detect completion from terminal text plus the artifact on disk. Emit it verbatim — a paraphrase is undetectable.

## What this skill must NOT do

These boundaries are **load-bearing**: another skill owns each one, and duplicating it here means two skills drift on the same artifact.

- **Never write or amend a spec, or add/renumber/reword Acceptance Criteria.** `brainstorming` owns the spec and its AC.
- **No worktree or branch creation** — management's `scaffold` owns isolation.
- **No quality gates and no formatting pass** — `polish` owns the build, the reviews, and the formatter. Don't run them "while you're here".
- **No serving the app and no browser verification** — `smoke-test` (or management's smoke worker) owns that.
- **No git writes: no commit, no push, no PR, no Jira/tracker update** — `ship` and `open-pr` own those.
- **No subagents.** Inline execution is the entire point; the two-stage review belongs to `subagent-driven-development`.

## Bail: stop, report `needs full flow`, change nothing further

Without a plan there is no approved structure, so **the spec is the structure**. Bail the moment reality departs from it:

- a file must be **created**, or code must **live somewhere**, that the spec didn't imply
- an **import crosses a boundary** the spec didn't authorize
- **shared code** (anything with consumers outside this task) needs editing and the spec didn't say so
- the work needs a **refactor** the spec didn't scope
- a **one-way escalator** surfaces mid-flight that the spec didn't settle: auth/permissions, a migration or persisted state, money/currency math
- a requirement is **ambiguous** enough that two readings produce materially different code

**How to bail:** stop editing immediately, leave what you've already written in place (don't revert — the diff is evidence), and report:

- which trigger fired, and where (`file:line` when it's a code fact)
- what the full flow would need to settle — the specific decision `brainstorming` or `writing-plans` has to make
- what's already changed, so the next session starts from a known state

**A bail is a success condition for this skill, not a failure.** The lane exists because Simple work doesn't need a plan; discovering mid-flight that this work *isn't* Simple is exactly the signal it's meant to produce. Silently improvising past a trigger is the failure — that's how unplanned structure lands in the codebase with nobody having approved it.

## Acceptance Criteria: what's traced and what isn't

**The plan phase is what normally maps each AC to a unit test or explicitly declines it.** Skipping the plan means this lane's ACs are **browser-proven or waived** — proven later by `smoke-test`, or waived as having no machine-observable surface. Unit tests are still written; they're just **not AC-traced**.

Say this in the result file rather than leaving it implicit: downstream `ship` gates read that ledger, and an untraced AC that looks traced is worse than one that's honestly marked. List the spec's AC in the result file with, for each, either the test that happens to cover it or `browser` / `waived`.

## `--agentic` mode

Invoked as `executing-simple --agentic` (used by an orchestrator running tasks with little human attention). It changes **who gets interrupted**, not what the skill does or where it stops.

- **Never ask a question.** Interactively, a small ambiguity can be resolved by asking; unattended, the same ambiguity is a **bail** — report `needs full flow` and stop.
- **Report at the end, don't check in during.** No progress prompts, no "shall I continue".
- **Every bail trigger is unchanged.** Autonomy here means fewer interruptions, never a wider licence to improvise.

Without the flag, you may ask **one** focused question when a single ambiguity is blocking and the answer is obviously small; anything larger is still a bail.

## Result File Format

```markdown
# [Feature Name] — Implementation Result

**Spec:** `.claude/temp/<task>-<slug>/<task>-<slug>-spec.md`
**Lane:** executing-simple (no plan phase — AC are browser-proven or waived, not AC-traced)

## Summary
[What was built, 2-3 sentences]

## Files Changed
- `path/to/file.ts` — [what changed]

## Tests Added
- `path/to/file.spec.ts` — [what it covers]

## Acceptance Criteria
- AC-1: [covered by `path/to/file.spec.ts` | browser | waived — reason]
- AC-2: …

## Decisions Made
- [Any decision made during implementation that the spec didn't settle]

## Concerns / Known Issues
- [Anything the next session should know]

## Test Results
[What you ran and the outcome — the tests you added plus those covering the changed code]
```

If the run ended in a bail, write the result file anyway with a **Bail** section at the top: the trigger, what the full flow must settle, and what's already changed.

## Remember

- Plan exists → `subagent-driven-development`. Spec only → this skill.
- The spec is the structure; departing from it is a bail, not a judgment call.
- Read the code before changing it — a matching name is a hypothesis, not proof of behavior.
- Tests for what you touched; the full suite, build, and formatter belong to `polish`.
- No git operations — the user manages commits, `ship` and `open-pr` own the rest.
- Emit `Result saved to <abs path>` verbatim.
