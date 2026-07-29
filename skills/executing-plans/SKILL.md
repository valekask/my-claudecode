---
name: executing-plans
description: Use when you have a written implementation plan to execute inline (without subagents)
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks step-by-step in the current session, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** For better quality on medium/complex tasks, consider using subagent-driven-development instead — it provides fresh context per task and two-stage review.

## `--agentic` mode

Invoked as `executing-plans --agentic` (used by an orchestrator running tasks with little human attention). It removes the **per-task approval pause** only — the critical plan review, following each step exactly, and every verification the plan specifies run unchanged.

**In `--agentic` mode:**

- **No pause between tasks.** Execute the plan through to the end, reporting each task's completion without waiting for approval.
- **Raise Step 1 plan concerns only when they block execution** — a gap you'd have to guess at, a contradiction, a step you can't follow. Smaller reservations go in the result file's *Concerns* section instead of stopping for them.
- **Stop and ask when execution departs from the plan's structure:**
  - a file needs creating that the plan didn't list, or code needs to live somewhere the plan didn't name
  - an import crosses a boundary the plan didn't authorize
  - shared code (global utils, shared UI, anything with consumers outside this task) needs editing and the plan didn't say so
  - the work turns out to need a **refactor** the plan didn't scope
  - a **critical surface** (auth/permissions, migrations/persisted state, money math) or a **backend contract** (API shape, shared models) is involved and the plan didn't already settle the approach
- **Also stop** on anything irreversible, on a verification that fails twice on the same task, and on a genuinely ambiguous instruction where two readings produce materially different code.
- **Report, don't ask, at the end** — write the result file and hand off exactly as normal.

**No review stages here.** Inline execution has no spec reviewer and no code-quality reviewer, so the plan's own verifications are the only check on each task. Unattended, that gap is widest on medium/complex work — prefer `subagent-driven-development --agentic` there, and keep this skill for plans small enough that a bad task is obvious in the diff.

Without the flag, the per-task pause in Step 2 applies unchanged.

## The Process

### Step 1: Load and Review Plan

1. Read plan file from `.claude/temp/<task>-<slug>/<task>-<slug>-plan.md`
2. Read the spec file for reference: `.claude/temp/<task>-<slug>/<task>-<slug>-spec.md`
3. Review critically — identify any questions or concerns about the plan
4. If concerns: Raise them with the user before starting
5. If no concerns: Create task tracking and proceed

### Step 2: Execute Tasks

For each task:
1. Mark task as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed
5. **Pause and report to user:** summarize what was done, files changed, any concerns
6. **Wait for user approval** before starting next task (in `--agentic` mode: report and continue — see [`--agentic` mode](#--agentic-mode))

### Step 3: Complete Development

After all tasks are complete and verified:
1. Run a final verification (all tests pass, no compilation errors)
2. Write result summary to `.claude/temp/<task>-<slug>/<task>-<slug>-result.md`
3. Present the result to the user
4. **Hand off:** the result is saved — tell the user to run `polish` (fresh session) before manual verification

## Result File Format

```markdown
# [Feature Name] — Implementation Result

**Plan:** `.claude/temp/<task>-<slug>/<task>-<slug>-plan.md`
**Spec:** `.claude/temp/<task>-<slug>/<task>-<slug>-spec.md`

## Summary
[What was built, 2-3 sentences]

## Tasks Completed
- Task 1: [name] — [brief status]
- Task 2: [name] — [brief status]

## Files Changed
- `path/to/file.ts` — [what changed]

## Decisions Made
- [Any decisions made during implementation that weren't in the plan]

## Concerns / Known Issues
- [Anything the user should be aware of]

## Test Results
[Summary of test runs]
```

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing progress
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Stop when blocked, don't guess
- Pause after each task for user approval — except in `--agentic` mode, where the structural stop triggers replace the pause
- No git operations — the user manages all commits manually
