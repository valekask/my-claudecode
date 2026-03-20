---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Reads the proposal, explores intent and requirements, and produces a spec before implementation."
---

# Brainstorming Proposals Into Specs

Help turn proposals into fully formed specs through natural collaborative dialogue.

Start by reading the proposal and any provided assets, search the codebase for relevant patterns, classify complexity, then ask questions one at a time to clarify gaps. Once you understand what you're building, present the design and get user approval, then write the spec file.

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

## Complexity Classification

After reading the proposal and exploring the codebase, classify the task:

| Dimension | Simple | Medium | Complex |
|-----------|--------|--------|---------|
| Files touched | 1-3 | 4-8 | 9+ |
| Patterns involved | 1 known | 2-3 patterns | Multiple or new patterns |
| Cross-cutting concerns | None | 1-2 | 3+ |

Classification determines ceremony level:

- **Simple** — flat checklist spec, 1-2 clarifying questions, skip approach comparison, skip pre-mortem, skip web research
- **Medium** — full process, 3-4 clarifying questions minimum, 2-3 approaches with trade-offs, web research when relevant
- **Complex** — full process, 5+ clarifying questions, 2-3 approaches with pre-mortem, web research when relevant

State the classification and reasoning to the user before proceeding.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Read proposal and assets** — read the proposal file, scan `assets/` directory if it exists, review any images or references provided
2. **Search codebase first** — search for existing patterns, conventions, and similar implementations related to the proposal. Patterns exist that users may not know about — find them before asking questions.
3. **Classify complexity** — use the classification table above to determine Simple / Medium / Complex track
4. **Assess scope** — if the proposal describes multiple independent subsystems, flag this immediately and help decompose before diving into details
5. **Ask clarifying questions** — one at a time, fill gaps not covered by the proposal, assets, or codebase. Minimum question count depends on track.
6. **Research before proposing (Medium/Complex only)** — use WebSearch/WebFetch when technology choices, new integrations, or unfamiliar patterns are involved. Apply the Convention Wins Rule (see Key Principles).
7. **Propose 2-3 approaches (Medium/Complex)** — with trade-offs and your recommendation. For Simple: state the single obvious approach.
8. **Pre-mortem (Complex only)** — for each proposed approach, identify 3-5 failure modes: "How could this fail? What are the riskiest assumptions?"
9. **Present design** — in sections scaled to complexity, get user approval after each section
10. **Write spec file** — save to `<TICKET_ID>-short-description-spec.md` in the same ticket directory. Max 7 phases — if more are needed, split into multiple specs.
11. **Spec review loop** — dispatch spec-document-reviewer subagent; fix issues and re-dispatch until approved (max 5 iterations, then surface to human)
12. **User reviews written spec** — ask user to review the spec file before proceeding

## Process Flow

```
Read proposal + assets
        │
   Search codebase for patterns
        │
   Classify complexity (Simple / Medium / Complex)
        │
   Scope appropriate? ──no──► Decompose into sub-tasks
        │ yes                        │
        │                    Brainstorm first sub-task
        │◄───────────────────────────┘
   Ask clarifying questions (one at a time)
        │
   [Medium/Complex] Research best practices
        │
   [Medium/Complex] Propose 2-3 approaches
   [Simple] State single approach
        │
   [Complex] Pre-mortem: failure modes per approach
        │
   Present design sections
        │
   User approves? ──no──► Revise and re-present
        │ yes
   Write spec file (max 7 phases)
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

**The terminal state is an approved spec file.** Do NOT start implementation.

After the user approves the spec, suggest the next step:

> "Spec approved. Next step: use `/writing-plans` to create the implementation plan from this spec."

## The Process

**Reading the proposal:**

- Read the proposal markdown file in the ticket directory
- Check for `assets/` directory — if it exists, read/view all files inside (images, mockups, diagrams, PDFs)
- Assets often contain crucial visual context. A mockup can answer dozens of questions. Study them carefully before asking the user anything.
- Note what the proposal covers well and where it has gaps

**Searching the codebase:**

- Before asking the user anything, search for existing patterns, conventions, and similar implementations
- Look at: relevant source files, docs, recent commits related to the proposal area
- Identify what conventions already exist — these are the baseline for any design
- Skip questions that the codebase already answers

**Assessing scope:**

- Before asking detailed questions, assess scope: if the proposal describes multiple independent subsystems, flag this immediately
- Don't spend questions refining details of a task that needs to be decomposed first
- If too large for a single spec, help decompose into sub-tasks. Each sub-task gets its own spec cycle.

**Clarifying gaps:**

- Ask questions one at a time to fill gaps not already covered by the proposal, assets, and codebase
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message
- Focus on: purpose, constraints, success criteria, edge cases
- Skip questions already answered by the proposal, visible in the assets, or discoverable in the codebase

**Research before proposing (Medium/Complex only):**

- Use WebSearch/WebFetch when the task involves technology choices, new integrations, or patterns not yet in the codebase
- Check current best practices — your training knowledge may be outdated
- Compare findings against existing codebase conventions
- Apply the **Convention Wins Rule**: codebase consistency is the default. Only recommend deviation when there's a concrete defect (bugs, security, performance). Document any deviation explicitly in the spec with rationale.
- When research reveals a better approach but the codebase uses a different one, document it as: "We considered X (current best practice) but chose Y for codebase consistency. Consider migrating to X in a dedicated effort."

**Exploring approaches:**

- **Medium/Complex:** Propose 2-3 structurally different approaches with trade-offs. Present options conversationally with your recommendation and reasoning. Lead with your recommended option and explain why.
- **Simple:** State the single obvious approach that follows existing conventions. No comparison needed.

**Pre-mortem (Complex only):**

- For each proposed approach, analyze 3-5 failure modes
- Ask: "How could this fail? What are the riskiest assumptions? What would make us regret this choice in 3 months?"
- Focus on: integration risks, performance under load, edge cases, maintenance burden
- Keep it lightweight — bullet points, not essays

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
- **Max 7 phases.** If more are needed, split into multiple specs — each gets its own brainstorming cycle.
- Do NOT commit the file — the user manages git operations manually

**What specs include vs. what they don't:**

| Specs define (what + why) | Specs do NOT include (how) |
|---------------------------|---------------------------|
| Goals and success criteria | Pseudocode or algorithms |
| Constraints and boundaries | Function signatures |
| Scope (in/out) | Exact file paths (use directory hints) |
| Architecture and data flow | Step-by-step implementation instructions |
| Error handling strategy | Internal variable names |
| Testing approach | Framework-specific boilerplate |

The implementation agent discovers the *how* by searching the current codebase. Over-specifying implementation details makes specs brittle and conflicts with what the implementer finds.

**Spec Review Loop:**

After writing the spec file:

1. Dispatch spec-document-reviewer subagent (see `spec-document-reviewer-prompt.md` in this skill directory)
2. If Issues Found: fix, re-dispatch, repeat until Approved
3. If loop exceeds 5 iterations, surface to human for guidance

**User Review Gate:**

After the spec review loop passes, ask the user to review the written spec:

> "Spec written to `.claude/temp/<TICKET_ID>-short-description/<TICKET_ID>-short-description-spec.md`. Please review it and let me know if you want any changes before we move to implementation."

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only consider the spec done once the user approves.

## What To Do When...

- **User wants to skip planning** — Emphasize: spec files enable context refresh, catch issues before code, and serve as documentation. The spec can be short, but it must exist.
- **Requirements are vague** — Ask one clarifying question at a time. Don't guess.
- **User rejects all approaches** — Ask what's missing or what constraint wasn't captured, then regenerate approaches.
- **Spec review reveals a gap** — Fix it in the spec and present the correction during user review.
- **More than 7 phases needed** — Split into multiple specs. Each sub-spec gets its own brainstorming cycle.
- **Research suggests a better approach than codebase convention** — Document both options. Default to convention. Flag the alternative for a future dedicated migration effort.

## Key Principles

- **Convention over novelty** - A consistent solution that follows codebase patterns is better than a superior approach that introduces inconsistency. Default to existing conventions. Only deviate when there's a concrete defect (bugs, security, performance), and flag any deviation explicitly in the spec with rationale and migration notes.
- **Proposal-first** - Always start by reading what the user already wrote. Don't re-ask what's already documented.
- **Search before asking** - Patterns exist that users may not know about. Search the codebase before asking questions — skip anything the code already answers.
- **Assets are answers** - Mockups and diagrams often resolve ambiguity better than questions. Study them.
- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Propose 2-3 approaches before settling (Medium/Complex). Simple tasks get one approach.
- **Incremental validation** - Present design, get approval before moving on
- **Spec says what, not how** - Define goals, constraints, and architecture. Leave implementation details for the building phase to discover.
- **No git operations** - Write files only. The user handles all git operations.
