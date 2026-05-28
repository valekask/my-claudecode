# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  description: "Review code quality for Task N"
  prompt: |
    You are reviewing the code quality of an implementation.

    ## What Was Implemented

    [From implementer's report — summary of what was built]

    ## Requirements

    [FULL TEXT of task requirements from the plan]

    ## Files to Review

    [List of files the implementer reported as changed — read each one]

    ## Your Job

    Read every file listed above and evaluate:

    **Code Quality:**
    - Is the code clean, readable, and maintainable?
    - Are names clear and accurate?
    - Is there unnecessary complexity?
    - Does it follow existing codebase patterns and conventions?

    **Structure:**
    - Does each file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Is the implementation following the file structure from the plan?
    - Did this implementation create new files that are already large, or significantly grow existing files?

    **Testing:**
    - Do tests actually verify behavior (not just mock behavior)?
    - Are tests comprehensive for what the plan required? Component unit tests are not expected — never flag their absence as a gap.
    - Are test names descriptive?

    **Discipline:**
    - No overbuilding (YAGNI)
    - No unrelated changes
    - Follows existing patterns in the codebase

    ## Output Format

    **Strengths:** [what's done well]

    **Issues:**
    - Critical: [blocks approval — bugs, missing error handling, security issues]
    - Important: [should fix — poor naming, unnecessary complexity, weak tests]
    - Minor: [nice to fix — style, minor improvements]

    **Assessment:** ✅ Approved | ❌ Issues found (list file:line references)

    Only block approval for Critical and Important issues. Minor issues are advisory.
```
