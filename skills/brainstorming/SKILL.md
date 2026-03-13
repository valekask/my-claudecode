---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Reads the proposal, explores intent and requirements, and produces a spec before implementation."
---

# Brainstorming Proposals Into Specs

Help turn proposals into fully formed specs through natural collaborative dialogue.

Start by reading the proposal and any provided assets, then ask questions one at a time to clarify gaps. Once you understand what you're building, present the design and get user approval, then write the spec file.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have written a spec and the user has approved it. This applies to EVERY task regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Spec"

Every task goes through this process. A config change, a single-component fix, a utility function — all of them. "Simple" tasks are where unexamined assumptions cause the most wasted work. The spec can be short (a few sentences for truly simple tasks), but you MUST present it and get approval.

## Working Directory Convention

All brainstorming artifacts live in a ticket directory:

```
.claude/temp/<TICKET_ID>-short-description/
  ├── <TICKET_ID>-short-description-proposal.md   # input (user provides)
  ├── assets/                                       # mockups, screenshots, diagrams, references (optional)
  └── <TICKET_ID>-short-description-spec.md        # output (this skill produces)
```

- The `assets/` directory may contain images, mockups, Figma exports, PDFs, or any reference material. Check it early — these assets often answer questions before you need to ask them.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Read proposal and assets** — read the proposal file, scan `assets/` directory if it exists, review any images or references provided
2. **Explore project context** — check relevant source files, docs, recent commits related to the proposal
3. **Assess scope** — if the proposal describes multiple independent subsystems, flag this immediately and help decompose before diving into details
4. **Ask clarifying questions** — one at a time, fill gaps not covered by the proposal or assets
5. **Propose 2-3 approaches** — with trade-offs and your recommendation
6. **Present design** — in sections scaled to complexity, get user approval after each section
7. **Write spec file** — save to `<TICKET_ID>-short-description-spec.md` in the same ticket directory
8. **Spec review loop** — dispatch spec-document-reviewer subagent; fix issues and re-dispatch until approved (max 5 iterations, then surface to human)
9. **User reviews written spec** — ask user to review the spec file before proceeding

## Process Flow

```
Read proposal + assets
        │
   Explore project context
        │
   Scope appropriate? ──no──► Decompose into sub-tasks
        │ yes                        │
        │                    Brainstorm first sub-task
        │◄───────────────────────────┘
   Ask clarifying questions (one at a time)
        │
   Propose 2-3 approaches
        │
   Present design sections
        │
   User approves? ──no──► Revise and re-present
        │ yes
   Write spec file
        │
   Spec review loop
        │
   Review passed? ──no──► Fix issues, re-dispatch
        │ yes
   User reviews spec
        │
   Changes requested? ──yes──► Update spec, re-run review
        │ no
   ✅ Spec approved — ready for implementation
```

**The terminal state is an approved spec file.** Do NOT start implementation. The user will decide when and how to proceed.

## The Process

**Reading the proposal:**

- Read the proposal markdown file in the ticket directory
- Check for `assets/` directory — if it exists, read/view all files inside (images, mockups, diagrams, PDFs)
- Assets often contain crucial visual context. A mockup can answer dozens of questions. Study them carefully before asking the user anything.
- Note what the proposal covers well and where it has gaps

**Assessing scope:**

- Before asking detailed questions, assess scope: if the proposal describes multiple independent subsystems, flag this immediately
- Don't spend questions refining details of a task that needs to be decomposed first
- If too large for a single spec, help decompose into sub-tasks. Each sub-task gets its own spec cycle.

**Clarifying gaps:**

- Ask questions one at a time to fill gaps not already covered by the proposal and assets
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message
- Focus on: purpose, constraints, success criteria, edge cases
- Skip questions already answered by the proposal or visible in the assets

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing approach
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Smaller, well-bounded units are easier to implement reliably

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work, include targeted improvements as part of the design
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## After the Design

**Writing the spec:**

- Write the validated design to `<TICKET_ID>-short-description-spec.md` in the ticket directory
- The spec should be self-contained: someone reading only this file should understand what to build and why
- Do NOT commit the file — the user manages git operations manually

**Spec Review Loop:**

After writing the spec file:

1. Dispatch spec-document-reviewer subagent (see `spec-document-reviewer-prompt.md` in this skill directory)
2. If Issues Found: fix, re-dispatch, repeat until Approved
3. If loop exceeds 5 iterations, surface to human for guidance

**User Review Gate:**

After the spec review loop passes, ask the user to review the written spec:

> "Spec written to `.claude/temp/<TICKET_ID>-short-description/<TICKET_ID>-short-description-spec.md`. Please review it and let me know if you want any changes before we move to implementation."

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only consider the spec done once the user approves.

## Key Principles

- **Proposal-first** - Always start by reading what the user already wrote. Don't re-ask what's already documented.
- **Assets are answers** - Mockups and diagrams often resolve ambiguity better than questions. Study them.
- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on
- **No git operations** - Write files only. The user handles all git operations.
