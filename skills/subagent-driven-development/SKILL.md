---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks — dispatches fresh subagent per task with two-stage review and user checkpoint
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each (spec compliance first, then code quality), and a user checkpoint before moving to the next task.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) + user checkpoint = high quality, controlled iteration

## When to Use

- You have an implementation plan (`.claude/temp/<task>/<task>-plan.md`)
- Tasks are mostly independent
- You want automated review gates per task
- For simpler tasks or when subagents aren't needed, use executing-plans instead

## The Process

```
Read plan + spec → Extract all tasks → Create task tracking
    │
    ▼
┌─────────────────────────────────────────────┐
│  Per Task:                                   │
│                                              │
│  1. Dispatch implementer subagent            │
│     └─ Questions? → Answer, re-dispatch      │
│     └─ Implements, tests, self-reviews       │
│                                              │
│  2. Dispatch spec reviewer subagent          │
│     └─ Issues? → Implementer fixes → re-review│
│                                              │
│  3. Dispatch code quality reviewer subagent  │
│     └─ Issues? → Implementer fixes → re-review│
│                                              │
│  4. ✅ Task complete                          │
│  5. Report to user, wait for approval        │
└─────────────────────────────────────────────┘
    │
    ▼ (user says "continue")
    │
    Next task... (repeat)
    │
    ▼ (all tasks done)
    │
Write result file → Offer ADR (if warranted) → Present to user
```

## Handling Implementer Status

Implementer subagents report one of four statuses:

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch. Common case: the task depends on a prior task's output — provide context about what the previous implementer built and which files were created/modified.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch
2. If the task is too large, break it into smaller pieces
3. If the plan itself is wrong, escalate to the user

**Never** ignore an escalation or force retry without changes. If the implementer said it's stuck, something needs to change.

## User Checkpoint

After each task completes (both reviews pass), **always pause and report to the user:**

> **Task N complete: [task name]**
> - Files changed: [list]
> - Spec review: ✅
> - Code quality review: ✅
> - Concerns: [any, or "none"]
>
> Ready for Task N+1: [next task name]. Continue?

**Wait for user approval before starting the next task.** The user may want to:
- **"continue"** — proceed to next task
- **"skip task N"** — mark task as skipped, note it in the result file, warn if downstream tasks depend on it
- **"stop"** — stop execution, write result file with completed tasks so far, remaining tasks listed as "not started"
- **Review changes** — user inspects code before continuing
- **Adjust the plan** — user modifies upcoming tasks
- **Provide context** — user gives additional information for the next task

## Handling Task Dependencies

When Task N depends on Task N-1 (e.g., Task 2 uses a service created in Task 1), the controller must provide dependency context to the implementer:

- Summarize what the previous task built
- List files created/modified by the previous task
- Highlight any interfaces or APIs the current task should use

The implementer should not need to rediscover what prior tasks produced — the controller bridges that gap.

## Review Loop Limits

If a spec or code quality review loop exceeds **3 iterations** (reviewer finds issues → implementer fixes → reviewer still finds issues), stop and escalate to the user. Something is fundamentally misaligned — continuing the loop wastes time.

## Providing File Context to Reviewers

Since no git commits are made during execution, reviewers cannot use SHA-based diffs. Instead:

**For spec reviewer:** Provide the task requirements + the implementer's report of files changed. The reviewer reads those files directly.

**For code quality reviewer:** Provide the implementer's report of files changed + what was implemented. The reviewer reads those files directly and evaluates quality.

The controller (you) tracks which files each implementer reports as changed and passes that list to reviewers.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file: .claude/temp/add-currency-filter/add-currency-filter-plan.md]
[Extract all 3 tasks with full text and context]
[Create task tracking]

Task 1: Filter component

[Dispatch implementer subagent with full task text + context]

Implementer: "Before I begin - should the filter use single or multi-select?"

You (controller): "Multi-select, per the spec section 2.3"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Status: DONE
  - Implemented CurrencyFilterComponent with multi-select
  - Tests: 5/5 passing
  - Files changed: currency-filter.component.ts, currency-filter.component.html,
    currency-filter.component.spec.ts
  - Self-review: All good

[Dispatch spec reviewer with task requirements + files list]
Spec reviewer: ✅ Spec compliant

[Dispatch code quality reviewer with files list + implementation summary]
Code quality reviewer: ✅ Approved. Clean implementation.

[Mark Task 1 complete]

→ USER CHECKPOINT:
  "Task 1 complete: Filter component
   Files changed: 3 files
   Both reviews passed, no concerns.
   Ready for Task 2: Filter service. Continue?"

User: "continue"

Task 2: Filter service
[... same flow ...]

→ USER CHECKPOINT:
  "Task 2 complete: Filter service. Continue?"

User: "looks good, continue"

Task 3: Dashboard integration
[... same flow ...]

[All tasks complete]
[Write .claude/temp/add-currency-filter/add-currency-filter-result.md]
[Present result to user]
```

## Result File Format

```markdown
# [Feature Name] — Implementation Result

**Plan:** `.claude/temp/<task>/<task>-plan.md`
**Spec:** `.claude/temp/<task>/<task>-spec.md`

## Summary
[What was built, 2-3 sentences]

## Tasks Completed
- Task 1: [name] — [status + brief notes]
- Task 2: [name] — [status + brief notes]

## Files Changed
- `path/to/file.ts` — [what changed]

## Review Summary
- Task 1: spec ✅, quality ✅
- Task 2: spec ✅, quality ✅ (1 issue fixed in review loop)

## Decisions Made
- [Any decisions made during implementation not in the plan]

## Concerns / Known Issues
- [Anything the user should be aware of]

## Test Results
[Summary of test runs]
```

## Capturing an ADR (optional)

After the result file is written, if any task involved **non-obvious constraints or edge cases** that won't be recoverable from the code later, **offer** to capture a feature-level ADR via the `writing-adr` skill:

> This task added non-obvious guards in [files]. Want me to capture an ADR (`docs/adr/FNA-xxxxx-...`) so the *why* survives?

This is opt-in — never auto-write. The result file (decisions, concerns) plus the implemented code are the inputs `writing-adr` needs. Don't offer for straightforward work; noise erodes the ADR set's value.

## Red Flags

**Never:**
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed review issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance
- **Start code quality review before spec compliance is ✅**
- Move to next task while either review has open issues
- **Move to next task without user approval at checkpoint**
- Perform any git operations — the user manages all commits manually

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)
- If truly blocked, escalate to user at checkpoint
