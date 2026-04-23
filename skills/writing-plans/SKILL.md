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

Read the spec file (`.claude/temp/<task>/<task>-spec.md`) and the proposal file before doing anything else. Understand the goals, constraints, architecture, and complexity classification before decomposing into tasks.

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

> **For agentic workers:** Use subagent-driven-development (recommended) or executing-plans skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

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
3. If ✅ Approved: proceed to execution handoff

**Review loop guidance:**
- Same agent that wrote the plan fixes it (preserves context)
- If loop exceeds 3 iterations, surface to human for guidance
- Reviewers are advisory — explain disagreements if you believe feedback is incorrect

## Execution Handoff

After saving the plan, announce: "Plan saved to `.claude/temp/<task>/<task>-plan.md`."

Then use the AskUserQuestion tool to offer next steps. Include a recommendation based on complexity from the spec in the question text:
- **Simple** (1-3 files, 1 pattern) → recommend Inline
- **Medium/Complex** (4+ files, multiple patterns) → recommend Subagent-Driven

```json
{
  "questions": [{
    "question": "Plan ready. What's next?",
    "header": "Next step",
    "options": [
      {"label": "Subagent-Driven", "description": "Fresh subagent per task with two-stage review, checkpoint after each task"},
      {"label": "Inline", "description": "Execute tasks step-by-step in this session, no subagents"},
      {"label": "Edit", "description": "Revise the plan before executing — tell me what to change"},
      {"label": "Done", "description": "Stop here, no execution"}
    ],
    "multiSelect": false
  }]
}
```

**If Subagent-Driven:** Use subagent-driven-development skill — fresh subagent per task, two-stage review, checkpoint after each task.

**If Inline:** Use executing-plans skill — step-by-step execution in this session.

**If Edit:** Ask the user what to change, apply the edits to the plan file, then re-offer this same question. Edit can be selected repeatedly until the user picks a terminal option.

**If Done:** Stop. Plan stays at its path for later use.
