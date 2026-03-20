---
name: executing-plans
description: Use when you have a written implementation plan to execute inline (without subagents)
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks step-by-step in the current session, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** For better quality on medium/complex tasks, consider using subagent-driven-development instead — it provides fresh context per task and two-stage review.

## The Process

### Step 1: Load and Review Plan

1. Read plan file from `.claude/temp/<task>/<task>-plan.md`
2. Read the spec file for reference: `.claude/temp/<task>/<task>-spec.md`
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
6. **Wait for user approval** before starting next task

### Step 3: Complete Development

After all tasks are complete and verified:
1. Run a final verification (all tests pass, no compilation errors)
2. Write result summary to `.claude/temp/<task>/<task>-result.md`
3. Present the result to the user

## Result File Format

```markdown
# [Feature Name] — Implementation Result

**Plan:** `.claude/temp/<task>/<task>-plan.md`
**Spec:** `.claude/temp/<task>/<task>-spec.md`

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
- Pause after each task for user approval
- No git operations — the user manages all commits manually
