---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
effort: xhigh
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** The spec should already exist in the task's working directory (produced by brainstorming skill).

## `--agentic` mode

Invoked as `writing-plans --agentic` (used by an orchestrator running tasks with little human attention). It changes **how high the bar is for interrupting the user** — not what the skill produces. The plan, the review loop, and the quality of the work are identical.

**In `--agentic` mode:**

- **Surface only these**, from the *Surface Decisions* scan below: **critical surface** (auth/permissions, migrations/persisted state, money math), **backend contract** change, a **genuine design fork** (two structurally different approaches that are actually comparable), a **spec gap** the plan cannot resolve without guessing, **scope growth** beyond the spec, or an **ADR conflict**.
- **Decide everything else yourself** — reuse vs new, logic location, convention questions, simpler alternatives — and write the decision plus its reasoning into the relevant phase's rationale so it is reviewable after the fact rather than asked about beforehand.
- **Skip the Final Review menu.** When nothing surfaced, save the plan and emit the handoff directly. If something did surface, ask about it, apply the answer, then save.
- **Never skip** the *Scope Check*, the reuse/behaviour-confirmation reads, or the plan review loop. Autonomy is about who gets asked, not about doing less work.

Without the flag, behave exactly as documented below — the interactive path is unchanged.

**Save plans to:** `.claude/temp/<task>-<slug>/<task>-<slug>-plan.md`
- Plans live alongside the proposal and spec in the same task directory

## Step 1: Read the Spec

Read the spec file (`.claude/temp/<task>-<slug>/<task>-<slug>-spec.md`), the proposal file, and any files in `assets/` before doing anything else. Understand the goals, constraints, architecture, and complexity classification before decomposing into tasks.

**Spec is *what*, plan re-decides *how*.** The spec is the contract for goals, scope, and architectural intent. If the spec leaks implementation details (a specific service, a global singleton, a particular abstraction, a fixed file location) and a simpler or better-located alternative exists in the live codebase, you can — and should — re-decide. Surface the choice rather than blindly implementing the elaborate version. The planner has codebase context the brainstormer didn't; use it.

**User Technical Notes are honored by default.** If the spec has a "User Technical Notes" section, treat its items as the author's direct instructions and follow them as written. These are NOT the leaked implementation details described above that you may freely re-decide — they are deliberate author choices, so the bar for overriding is a concrete problem, not merely a nicer alternative. If an item looks wrong, conflicts with the live codebase, or is ambiguous, do not silently follow or silently drop it — raise it in the Surface Decisions step below and discuss with the user.

**Fresh context preferred.** This skill works best when invoked in a new Claude Code session — the spec + proposal + assets are the only inputs the planner needs. Inheriting brainstorm dialogue carries forward rejected paths, hedged framings, and conversational baggage that bias decomposition. If the spec leaves something ambiguous in a fresh session, that's a spec gap worth surfacing back to brainstorming, not papering over with remembered context.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.
- **Impact tracing** — when modifying a function's signature or behavior, grep for ALL callers to build the complete file list. Include indirect callers through shared services and utilities, not just direct callers in the target area. When adding state that depends on another piece of state, trace ALL triggers that can change the source state, not just the primary use case. When several symbols or state sources need tracing, this is independent read-only work — fan it out to parallel search agents (one per symbol/area), each returning its caller/trigger list, then merge the results.
- **ADR constraints** — if `docs/adr/README.md` exists, scan it for ADRs relevant to the files you'll create or modify **through the plan-writing lens: does any ADR name a guard in these files that the plan must preserve, not remove?** Their *Edge cases & non-obvious constraints* section names those guards — carry each into the relevant task's rationale. The spec's *ADRs Reviewed* section (written during brainstorming) already cleared the *direction* level; start from it, then run this guard-level scan against the live files. **Report what you found in conversation AND record it in the plan's *ADRs Reviewed* section (see Plan Document Header)** — list only the ADRs that impose a guard, with the match count in the header: the guard each imposes and the task that preserves it. In conversation, emit it as a **discrete labeled block**, never woven into other narration (a result buried mid-paragraph is not "visible"):

> **ADRs reviewed** (guard lens — 2 matches):
> - `0001` auth — guards the cookie-refresh path; preserved by task 3. No conflict.
> - `FNA-1234` mapping — guards binder ordering; task 5 keeps it.

When none impose a guard, a single line is the whole block — it is the proof the scan ran:

> **ADRs reviewed** (guard lens — 0 matches):
> - None impose a guard on the files this plan touches.

The forced block keeps the scan from being skipped and leaves a visible record. If `docs/adr/README.md` doesn't exist, say so once in the block and note that in the plan section.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Surface Decisions Before Writing Tasks

Pause between mapping files and writing tasks. Scan for high-leverage decisions the plan would otherwise resolve silently — these are the moments where sub-optimal choices get baked in and only caught at Final Review (or worse, after execution).

**Scan for:**

- **Reuse candidates** — before planning any new file/function/service/util (including ones the spec proposes), grep for existing similar functionality. Two common misses: (a) spec-proposed services that could extend something existing — a spec naming `FooService` doesn't force net-new code; (b) duplicate utils under different names — a planned `formatCurrency` may already exist as `currencyFormatter`. For utils, grep by capability (`format`, `parse`, `validate`, `normalize`), not by exact target name, and check the project's typical util homes (`*.utils.ts`, `*.helpers.ts`, `lib/utils/`). If matches exist, ask: extend the existing one, or create new? **Before treating any match as a reuse or modification target, read it deeply enough to confirm it actually behaves the way the plan assumes** — a similar name, shape, or nearby location is a hypothesis, not proof of equivalent behavior. If it looks similar but works differently, say so and leave it alone rather than planning a change to it. Confirm before proposing to touch it — don't defer the deep read until someone questions the change. When you have several planned units to check, fan out the *locating* step — parallel search agents grepping by capability, one per unit, each reporting whether a candidate exists and where — but do the behavior-confirmation read yourself, inline: that judgment is the part that must not be delegated to a summary.
- **Simpler alternative** — when the spec (or your draft plan) calls for a new service, global singleton, DI token, app-module init hook, or other architectural machinery, ask: could this be done with local component state plus existing primitives instead? If yes, surface as a decision. Example: a global service holding a `BehaviorSubject` initialised at app start may be replaceable by local state loaded on open and persisted on close.
- **Logic location** — for each file the plan will touch, ask: does the logic naturally belong here, or is it being piled onto a generic file (e.g. adding feature-specific code to a shared `binder.ts`)? If wrong home, propose moving it to a service or util in the feature's natural directory.
- **Structural ambiguities** — spec gaps the plan would resolve by guessing (where a new utility lives, whether to split a service, how to wire two pieces together). Ask rather than guess.
- **Scope concerns** — phases that look bigger than the spec implies, or implementations that pull in items adjacent to but not in the spec. Flag and ask: split, defer, or keep together?
- **Convention deviation** — when the obvious implementation would break an existing codebase pattern. Surface the choice rather than silently follow either path.
- **Critical surface** — the plan touches authentication/permissions, a data migration or persisted state, or money/currency math. These fail silently and expensively, so the approach gets confirmed even when it looks obvious.
- **Backend contract** — the plan changes an API call shape, a request/response model, or anything else shared with the backend. A contract change has consumers the plan can't see, so it is never a silent decision.

**How to surface:**

1. Compile 1-3 highest-leverage items across the categories — exhaustive lists become noise. Skip categories where nothing material is flagged.
2. Use AskUserQuestion (one question at a time). Multiple-choice when there's a clear set of options, open-ended when not.
3. If nothing material is flagged, say "no surface decisions needed" and proceed straight to task writing.

**What not to ask:**

- Implementation-detail choices (variable names, exact function signatures) — those belong at execution time
- Anything the spec already answers and you have no concrete reason to revisit — re-read the spec first. (Architectural details the spec leaked are fair game when a simpler alternative exists — that's what *Simpler alternative* and *Logic location* are for.)
- Style preferences not relevant to plan structure

Apply user answers when writing tasks. Bake the decision into the relevant phase's rationale where it materially shapes the plan.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Implemented via `subagent-driven-development` (the default), or `executing-plans` for simple inline execution. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**ADRs Reviewed (N matches):**
- [ADR ID + label] — guard it imposes; the task that preserves it. (Carried forward from the spec's *ADRs Reviewed* section, then refreshed against the live files.)
- [When 0 matches: a single line — none impose a guard on the files this plan touches.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS
````

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD
- No git operations — the user manages all commits manually
- **Spec test traceability** — every test scenario in the spec's Testing Approach section must map to a concrete plan step with test code. If the spec says "verify X receives Y", the plan must have a step that writes that test.
- **Acceptance criteria traceability** — read the spec's **Acceptance Criteria** (`AC-1`, `AC-2`, …) and decide, per AC, whether it is provable by a unit test at the level this project tests (ComponentStore / service / util).
  - **Unit-testable AC** → a concrete plan step whose test proves it, with the AC id cited in the step (`covers AC-2`).
  - **AC you decline** → list it explicitly in the plan with a one-line reason (e.g. "AC-1: user-visible timing, verify in the browser"; "AC-5: third-party rendering, manual check"). Do NOT drop it silently: `smoke-test` declines AC too, and an AC declined by both must be visible to the human rather than lost between the two skills.
  - Every AC appears in exactly one of those two lists. An AC in neither is a gap in the plan.
- **Cleanup after replacement** — when a plan replaces a function call with a new one, add a cleanup step: check if the old function has remaining callers; if not, remove it and update exports. Don't leave dead code behind.

## Plan Review Loop

After writing the complete plan:

1. Dispatch a single plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
   - Provide: path to the plan document, path to spec document
2. If ❌ Issues Found: fix the issues, re-dispatch reviewer for the whole plan
3. If ✅ Approved: proceed to Final Review

**Review loop guidance:**
- Same agent that wrote the plan fixes it (preserves context)
- If loop exceeds 3 iterations, surface to human for guidance
- Reviewers are advisory — explain disagreements if you believe feedback is incorrect

## Final Review

After the plan review loop passes, the plan is on disk. Walk the user through a size-aware digest before emitting the Save handoff. The goal is skim-able, sectioned review — not re-reading the full plan file.

**Step 1 — Size assessment.** Estimate digest size based on phase count and task density:

| Tier   | Plan scope                       | Digest                          |
|--------|----------------------------------|---------------------------------|
| Tiny   | 1-2 phases / trivial             | Single block, no menu           |
| Small  | 3-5 phases                       | 1-2 sections                    |
| Medium | 6-10 phases                      | 3-5 sections                    |
| Large  | 10-20 phases (multi-subsystem)   | 5-10 sections                   |
| Mega   | 20+ phases                       | 10-15 sections + suggest split  |

(Adjust slightly based on density — a focused 8-phase plan with thin tasks may digest as Small.)

**Step 2 — Build the digest.** Summarize the saved plan into sections grouped by **natural seams** — model picks the seams each time. Examples: Setup & foundations / Core feature work / Migration & cleanup / Tests. Each section names the phases it covers, the goal of that group (1-2 lines), and the files or subsystems touched. Headlines + Goal + Architecture from the plan header are the spine; phase details live in the file. **Always include the *ADRs Reviewed* result as a one-line entry** (which ADRs impose guards and the tasks that preserve them, or "none relevant") so the user sees what was taken into account.

**Step 3 — Tiny tier flow.** Show the full digest as one block, then emit the Save handoff (see Save below). No menu needed at this size.

**Step 4 — Small/Medium/Large/Mega tier menu.** Use AskUserQuestion:

```json
{
  "questions": [{
    "question": "Plan saved to `.claude/temp/<task>-<slug>/<task>-<slug>-plan.md`. Final review — how would you like to proceed?",
    "header": "Final review",
    "options": [
      {"label": "Walk by section", "description": "Show one section at a time"},
      {"label": "Save", "description": "Emit the handoff line and exit"}
    ],
    "multiSelect": false
  }]
}
```

If the user has feedback at any point — during the walk, after a section, or before picking from the menu — address it: revise the plan, re-run the plan review loop, then re-enter Final Review. Don't channel comments through a menu option; just respond to what they say.

**Walk by section:** show one section, then AskUserQuestion (Next / Save). After the last section, auto-emit the Save handoff. If the user types feedback instead of picking Next or Save, treat it as discussion — revise and re-enter Final Review.

**Save:** emit this exact text and stop. Do NOT auto-invoke `subagent-driven-development` or `executing-plans` in this session — execution belongs in a fresh session.

> Plan saved to `.claude/temp/<task>-<slug>/<task>-<slug>-plan.md`.
> Use subagent-driven-development skill to execute plan at `.claude/temp/<task>-<slug>/<task>-<slug>-plan.md`.
