---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Reads the proposal, explores intent and requirements, and produces a spec before implementation."
effort: xhigh
---

# Brainstorming Proposals Into Specs

Pipeline: **Read → Clarify Intent → Discover → Classify → Explore → Design → Spec**

The spec is a contract between brainstorming and building. It specifies WHAT and WHY at the strategic level — goals, constraints, architecture, scope. Implementation details (the HOW) are discovered during plan writing and execution.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have written a spec and the user has approved it. This applies to EVERY task regardless of perceived simplicity.
</HARD-GATE>

## Working Directory Convention

All brainstorming artifacts live in a task directory:

```
.claude/temp/<task>/
  ├── <task>-proposal.md   # input (user provides)
  ├── assets/               # mockups, screenshots, diagrams, references (optional)
  └── <task>-spec.md        # output (this skill produces)
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
2. **Clarify intent** — confirm you understand the problem the proposal is trying to solve. If the proposal is clear, skip. If not, ask one focused question via AskUserQuestion. Goal: a confirmed problem statement before any codebase exploration.
3. **Search the codebase (targeted)** — explore how the area being touched currently works. Goal: understand the functionality you'll create or update, not catalogue patterns and conventions (those matter at plan-writing time). If `docs/adr/README.md` exists, scan it for ADRs relevant to this area **through the brainstorming lens: does any ADR constrain the *direction* I'm about to propose?** ADRs carry the settled *why* — decisions you must not silently re-litigate. (The *guard-level* lens — which specific code guards a change must preserve — belongs to plan-writing, not here.) **Report what you found in conversation AND record it in the spec's *ADRs Reviewed* section (see Writing the spec)** — state which ADRs you reviewed and your direction-level conclusion, even when none are relevant (e.g. *ADRs reviewed: none relevant to this area*; or *ADRs reviewed: FNA-15102 (property coloring) — relevant, constrains the render path; no conflict with the proposed direction*). Forcing the statement keeps the scan from being skipped and makes the result visible rather than silent. If `docs/adr/README.md` doesn't exist, say so once and note that in the spec section.
4. **Classify complexity** — use the classification table above to determine Simple / Medium / Complex track
5. **Assess scope** — if the proposal describes multiple independent subsystems, flag this immediately and help decompose before diving into details
6. **Ask clarifying questions** — one at a time, fill gaps not covered by the proposal, assets, or codebase. Minimum question count depends on track.
7. **Research before proposing (Medium/Complex only)** — use WebSearch/WebFetch when technology choices, new integrations, or unfamiliar patterns are involved. Apply the Convention Wins Rule (see Key Principles).
8. **Propose 2-3 approaches (Medium/Complex)** — with trade-offs and your recommendation. For Simple: state the single obvious approach.
9. **Pre-mortem (Complex only)** — for each proposed approach, identify 3-5 failure modes: "How could this fail? What are the riskiest assumptions?"
10. **Present design** — in sections scaled to complexity, get user approval after each section
11. **Write spec file** — save to `<task>-spec.md` in the same task directory. Max 7 phases — if more are needed, split into multiple specs.
12. **Spec review loop** — dispatch spec-document-reviewer subagent; fix issues and re-dispatch until approved (max 5 iterations, then surface to human)
13. **Final review** — walk user through a size-aware digest of the saved spec (size assessment → digest → menu: walk by section / save). See Final Review section.

## Process Flow

```
Read proposal + assets
        │
   Clarify intent (confirm problem statement)
        │
   Search codebase (targeted: area being touched)
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
   Final review (size assessment → digest → menu)
        │
   ✅ Spec saved — handoff line emitted; next phase runs in a fresh session
```

**The terminal state is a saved spec file with a handoff line.** Do NOT start implementation and do NOT auto-invoke `/writing-plans` in this session. The handoff line tells the user to run `/writing-plans` in a fresh session — that's how the next phase begins.

## The Process

**Reading the proposal:**

- Read the proposal markdown file in the ticket directory
- Check for `assets/` directory — if it exists, read/view all files inside (images, mockups, diagrams, PDFs)
- Assets often contain crucial visual context. A mockup can answer dozens of questions. Study them carefully before asking the user anything.
- Note what the proposal covers well and where it has gaps

**Clarifying intent:**

- Before exploring the codebase, confirm you understand the problem the proposal is trying to solve
- If the proposal is clear and unambiguous, skip this step
- If anything is unclear, ask one focused question via AskUserQuestion (single question, multiple choice when possible)
- Goal: a confirmed problem statement so the codebase search is targeted, not generic

**Searching the codebase (targeted):**

- Explore the area the change will touch — the functionality you'll create or update
- Goal: understand how it currently works, not catalogue patterns or conventions (those matter at plan-writing time)
- Look at: the files involved, their callers, recent commits in that area
- Skip questions that the code already answers

**Assessing scope:**

- Before asking detailed questions, assess scope: if the proposal describes multiple independent subsystems, flag this immediately
- Don't spend questions refining details of a task that needs to be decomposed first
- If too large for a single spec, help decompose into sub-tasks. Each sub-task gets its own spec cycle.

**Clarifying gaps:**

- Ask questions one at a time to fill gaps not already covered by the proposal, assets, and codebase
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message
- Focus on: purpose, constraints, success criteria, edge cases
- If the feature involves forms or user input, ask about validation: what are the rules, and would any need to be enforced from a second entry point? If yes, those belong in shared validators/services — clarify this early so the spec places them correctly.
- If the user states a specific value, name, format, or instruction they want honored exactly, capture it verbatim for the **User Technical Notes** section of the spec (see Writing the spec) rather than paraphrasing it away
- Skip questions already answered by the proposal, visible in the assets, or discoverable in the codebase

**Research before proposing (Medium/Complex only):**

- Use WebSearch/WebFetch when the task involves technology choices, new integrations, or patterns not yet in the codebase
- When there are multiple independent research questions, dispatch them as parallel research agents — one per question — each returning a short digest. Research output is naturally a summary, so little nuance is lost by delegating; this is a clean fan-out, unlike the codebase search above.
- Check current best practices — your training knowledge may be outdated
- Compare findings against existing codebase conventions
- Apply the **Convention Wins Rule**: codebase consistency is the default. Only recommend deviation when there's a concrete defect (bugs, security, performance). Document any deviation explicitly in the spec with rationale.
- When research reveals a better approach but the codebase uses a different one, document it as: "We considered X (current best practice) but chose Y for codebase consistency. Consider migrating to X in a dedicated effort."

**Exploring approaches:**

- **Medium/Complex:** Propose 2-3 structurally different approaches with trade-offs. Present options conversationally with your recommendation and reasoning. Lead with your recommended option and explain why. For each approach, include:
  - **Scope** — what areas/components it touches
  - **Hardest part** — the single riskiest or most complex piece

  This helps the user gauge relative effort and compare options without needing deep technical knowledge.
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
- **Testing approach default:** test the ComponentStore / service / util that holds the logic, not the component. Do not propose component unit tests — the user requests them explicitly when needed.
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

- Write the validated design to `<task>-spec.md` in the task directory
- The spec should be self-contained: someone reading only this file should understand what to build and why
- **Max 7 phases.** If more are needed, split into multiple specs — each gets its own brainstorming cycle.
- Do NOT commit the file — the user manages git operations manually

**What specs define (what + why):** goals and success criteria; constraints and boundaries; scope (in/out); architecture and data flow; error handling strategy; testing approach.

**Include an *ADRs Reviewed* section.** Near the top of the spec (after the goals/overview), add a short section that records the ADR scan from step 3: every ADR you weighed and your direction-level conclusion for each, or a single line stating none were relevant. This is the visible record of the scan and the breadcrumb the plan-writing phase reads before its own guard-level scan. Use ADR IDs and short labels in prose — IDs are not code syntax, so the hard rules above do not apply here. For example:

> ## ADRs Reviewed
> - FNA-15102 (property coloring) — relevant; constrains the render path. Proposed direction does not conflict.
> - None others relevant to this area.

If `docs/adr/README.md` doesn't exist, the section says so in one line.

**Hard rules — do NOT write any of these in the spec.** The reviewer rejects on sight; write the spec right the first time rather than cleaning up afterward.

- Fenced code blocks (` ```ts `, ` ```js `, ` ```typescript `, etc.)
- Function signatures with typed parameters: `foo(x: Type)`, `bar(x: T): R`
- Type annotations or generics: `: Observable<...>`, `BehaviorSubject<string[]>`
- Decorators: `@Injectable(...)`, `@Component(...)`, `@Input(...)`
- Template literals with interpolation: `` `${foo}-${bar}` ``
- Exact file paths with extensions: `libs/foo/bar.ts`, paths ending in `.ts/.tsx/.html/.scss` — use directory hints in prose instead
- Pseudocode, algorithms, or step-by-step implementation instructions
- Framework-specific boilerplate

**Rule of thumb:** names in prose are fine; code syntax is not.

**Locations at directory-hint altitude.** Refer to where code lives in words — "a formatting util in the shared utils directory" — not slash-path notation like `shared/utils`. This holds even without a file extension: path notation is the planner's altitude, not the spec's. The writing-plans phase resolves exact paths against the live codebase (per the *what vs how* contract at the top of this skill).

✅ "Use ComponentStore for the list state."
✅ "Service named `ColorMapService` in the dashboard data-access lib."
✅ "A formatting util in the shared utils directory."
✅ "Key format: workspace name + dashboard name + `colorMap` suffix."

❌ `class ColorMapStore extends ComponentStore<State>`
❌ `@Injectable({ providedIn: 'root' })`
❌ `shared/utils/format.ts` — and even `shared/utils` (path notation; write it in prose)
❌ `` `${workspaceName}-${dashboardName}-colorMap` ``

**Exception — the User Technical Notes section.** The hard rules above do NOT apply inside a section titled **User Technical Notes**. This is the one sanctioned place for verbatim author instructions — exact names, values, key formats, even short code snippets the user wants honored as written. Lead the section with one line stating the contract:

> Direct instructions from the spec author. The planning and implementation phases honor these by default; if an item looks wrong, conflicts with the codebase, or is ambiguous, that phase raises it with the user rather than silently following or dropping it.

Include this section only when the user has given such direct instructions — omit it otherwise, and never invent entries. Use it for author preferences ("I want this exact name"). Things that *must* hold for an external reason (matches stored data, an API contract) are binding requirements — put those under Constraints with the rationale, where the planner cannot re-decide them. Keep the section short: it is an escape hatch, not a place to pre-write the implementation.

The implementation agent discovers the *how* by searching the current codebase. Over-specifying implementation details makes specs brittle and conflicts with what the implementer finds.

**Spec Review Loop:**

After writing the spec file:

1. Dispatch spec-document-reviewer subagent (see `spec-document-reviewer-prompt.md` in this skill directory)
2. If Issues Found: fix, re-dispatch, repeat until Approved
3. If loop exceeds 5 iterations, surface to human for guidance

**Final Review:**

After the spec review loop passes, the spec is on disk. Walk the user through a size-aware digest before handing off to implementation. The goal is skim-able, sectioned review — not re-reading the whole file.

**Step 1 — Size assessment.** Estimate digest size based on spec phases and complexity:

| Tier   | Spec scope                | Digest                              |
|--------|---------------------------|-------------------------------------|
| Tiny   | 1-2 phases / trivial      | Single block, no menu               |
| Small  | 3-5 phases                | 1-2 sections                        |
| Medium | 6-7 phases                | 3-5 sections                        |
| Large  | Past the 7-phase cap      | Suggest splitting before continuing |

Specs cap at 7 phases — most reviews are Tiny/Small/Medium. Large means the spec needs splitting upstream rather than a bigger menu here.

**Step 2 — Build the digest.** Summarize the saved spec into sections grouped by **natural seams** — model picks the seams each time. Examples: Goals & scope / Architecture / Data flow / Error & edges / Testing. Each section: short headline + 1-3 lines of substance. Skim-able under 30 seconds. The full file is on disk; the digest is the review surface. **Always include the *ADRs Reviewed* result as a one-line entry** (which ADRs were weighed and the direction conclusion, or "none relevant") so the user sees what was taken into account.

**Step 3 — Tiny tier flow.** Show the full digest as one block, then emit the Save handoff (see Save below). No menu needed at this size.

**Step 4 — Small/Medium/Large tier menu.** Use AskUserQuestion:

```json
{
  "questions": [{
    "question": "Spec saved to `.claude/temp/<task>/<task>-spec.md`. Final review — how would you like to proceed?",
    "header": "Final review",
    "options": [
      {"label": "Walk by section", "description": "Show one section at a time"},
      {"label": "Save", "description": "Emit the handoff line and exit"}
    ],
    "multiSelect": false
  }]
}
```

If the user has feedback at any point — during the walk, after a section, or before picking from the menu — address it: revise the spec, re-run the spec review loop, then re-enter Final Review. Don't channel comments through a menu option; just respond to what they say.

**Walk by section:** show one section, then AskUserQuestion (Next / Save). After the last section, auto-emit the Save handoff. If the user types feedback instead of picking Next or Save, treat it as discussion — revise and re-enter Final Review.

**Save:** emit this exact text and stop. Do NOT auto-invoke `/writing-plans` in this session — the next phase belongs in a fresh session.

> Spec saved to `.claude/temp/<task>/<task>-spec.md`.
> Use writing-plans skill to make a plan for `.claude/temp/<task>/<task>-spec.md`.

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
