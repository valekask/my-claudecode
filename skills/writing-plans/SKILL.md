---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** The spec should already exist in the task's working directory (produced by brainstorming skill).

**Save plans to:** `.claude/temp/<task-description>/<task-description>-plan.md`
- Plans live alongside the proposal and spec in the same task directory

## Step 1: Read the Spec

Read the spec file (`.claude/temp/<task>/<task>-spec.md`), the proposal file, and any files in `assets/` before doing anything else. Understand the goals, constraints, architecture, and complexity classification before decomposing into tasks.

**Fresh context preferred.** This skill works best when invoked in a new Claude Code session — the spec + proposal + assets are the only inputs the planner needs. Inheriting brainstorm dialogue carries forward rejected paths, hedged framings, and conversational baggage that bias decomposition. If the spec leaves something ambiguous in a fresh session, that's a spec gap worth surfacing back to brainstorming, not papering over with remembered context.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.
- **Impact tracing** — when modifying a function's signature or behavior, grep for ALL callers to build the complete file list. Include indirect callers through shared services and utilities, not just direct callers in the target area. When adding state that depends on another piece of state, trace ALL triggers that can change the source state, not just the primary use case.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Surface Decisions Before Writing Tasks

Pause between mapping files and writing tasks. Scan for high-leverage decisions the plan would otherwise resolve silently — these are the moments where sub-optimal choices get baked in and only caught at Final Review (or worse, after execution).

**Scan for:**

- **Reuse candidates** — before planning any new file/function/service, grep for existing similar functionality. If matches exist, ask: extend the existing one, or create new? (This is the most common source of sub-optimal plans — Claude proposes new code where extension would be cleaner.)
- **Structural ambiguities** — spec gaps the plan would resolve by guessing (where a new utility lives, whether to split a service, how to wire two pieces together). Ask rather than guess.
- **Scope concerns** — phases that look bigger than the spec implies, or implementations that pull in items adjacent to but not in the spec. Flag and ask: split, defer, or keep together?
- **Convention deviation** — when the obvious implementation would break an existing codebase pattern. Surface the choice rather than silently follow either path.

**How to surface:**

1. Compile 1-3 highest-leverage items across the four categories — exhaustive lists become noise. Skip categories where nothing material is flagged.
2. Use AskUserQuestion (one question at a time). Multiple-choice when there's a clear set of options, open-ended when not.
3. If nothing material is flagged across all four categories, say "no surface decisions needed" and proceed straight to task writing.

**What not to ask:**

- Implementation-detail choices (variable names, exact function signatures) — those belong at execution time
- Anything the spec already answers — re-read the spec first
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

> **For agentic workers:** Implemented via `subagent-driven-development` or `executing-plans`, auto-routed by spec complexity. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

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

**Step 2 — Build the digest.** Summarize the saved plan into sections grouped by **natural seams** — model picks the seams each time. Examples: Setup & foundations / Core feature work / Migration & cleanup / Tests. Each section names the phases it covers, the goal of that group (1-2 lines), and the files or subsystems touched. Headlines + Goal + Architecture from the plan header are the spine; phase details live in the file.

**Step 3 — Tiny tier flow.** Show the full digest as one block, then emit the Save handoff (see Save below). No menu needed at this size.

**Step 4 — Small/Medium/Large/Mega tier menu.** Use AskUserQuestion:

```json
{
  "questions": [{
    "question": "Plan saved to `.claude/temp/<task>/<task>-plan.md`. Final review — how would you like to proceed?",
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

> Plan saved to `.claude/temp/<task>/<task>-plan.md`.
> Use subagent-driven-development skill to execute plan at `.claude/temp/<task>/<task>-plan.md`.
