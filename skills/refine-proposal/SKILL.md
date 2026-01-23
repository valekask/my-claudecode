---
name: refine-proposal
description: Refine initial proposals through dialog before OpenSpec. Use when you have a rough proposal and want to identify gaps and alternatives.
thinking: ultrathink
---

# Refine Proposal

Validate concepts and refine proposals through iterative dialog before creating OpenSpec specifications.

**Core principle:** Understand the problem deeply before proposing solutions. Catch conceptual gaps early.

## When to Use

- Before creating OpenSpec change proposals
- When you have a rough idea from a ticket
- When you need to validate the approach
- When you're unsure if existing solutions exist

## Invocation

```
let's refine <path-to-proposal>
/refine-proposal <path-to-proposal>
```

## Process Overview

```
+---------------------------------------------------------------------------+
|  Phase 1: PROBLEM ANALYSIS (requires approval to continue)                |
|  - Analyze current behavior and implementation                            |
|  - Identify root cause of the problem                                     |
|  - Present findings -> Get user approval                                  |
+---------------------------------------------------------------------------+
|  Phase 2: FEASIBILITY & DUPLICATE CHECK                                   |
|  - Search codebase for existing similar solutions                         |
|  - Validate concept feasibility                                           |
|  - Identify reusable patterns                                             |
+---------------------------------------------------------------------------+
|  Phase 3: REQUIREMENTS DIALOG                                             |
|  - Ask clarifying questions (one at a time)                               |
|  - Explore alternatives when meaningful                                   |
|  - Resolve ALL questions (no open questions allowed)                      |
+---------------------------------------------------------------------------+
|  Phase 4: FINAL PROPOSAL                                                  |
|  - Create <name>-final.md with all decisions made                         |
|  - Include specific file/location details                                 |
|  - Ready for OpenSpec                                                     |
+---------------------------------------------------------------------------+
```

---

## Phase 1: Problem Analysis

**Goal:** Understand the actual problem before proposing solutions.

### Steps

1. **Read the proposal file**

2. **Analyze current implementation:**
   - Use Grep/Glob to find related code
   - Read key files to understand current behavior
   - Map the data flow and state management

3. **Identify root cause:**
   - What is the actual problem (not symptoms)?
   - Why does current implementation not meet needs?
   - What constraints exist?

4. **Present findings and get approval:**

```markdown
## Current Behavior Analysis

### How it works now
[Describe current implementation with specific file references]
- `src/lib/services/foo.service.ts:45` - handles X
- `src/lib/+state/bar.reducer.ts:120` - stores Y

### Root Cause
[Explain the actual problem, not symptoms]

### Key Constraints
- [Constraint 1]
- [Constraint 2]

---
Does this analysis match your understanding? [Approve to continue]
```

**STOP HERE** - Wait for user approval before proceeding to Phase 2.

---

## Phase 2: Feasibility & Duplicate Check

**Goal:** Ensure we're not reinventing the wheel.

### Validation Checklist

| Check | Action |
|-------|--------|
| **Duplicate Detection** | Search codebase for existing similar implementations using Grep/Glob |
| **Pattern Reuse** | Identify existing patterns that could be extended |
| **Architecture Alignment** | Verify approach fits with CLAUDE.md and project conventions |
| **Feasibility** | Confirm the concept is technically viable |

### Search Commands

```bash
# Search for similar functionality
rg "keyword" --type ts
rg "pattern" libs/

# Find related services/components
glob "**/similar*.ts"
glob "**/*feature*.service.ts"
```

### Report Findings

If existing solution found:
- Present the existing implementation
- Ask: "Should we extend this, or is there a reason to create new?"

If no existing solution:
- Confirm: "No existing implementation found for X"
- Identify reusable patterns

---

## Phase 3: Requirements Dialog

**Goal:** Resolve ALL questions through dialog. No open questions in final output.

### Question Categories

| Category | Purpose |
|----------|---------|
| **Clarity** | What exactly should happen? Edge cases? |
| **Scope** | What's in/out? Dependencies? |
| **Alternatives** | Is there a simpler/better approach? |
| **Integration** | How does this affect existing features? |
| **Data** | What data flows? API changes? |
| **State** | Where should state live? Which store? |

### Guidelines

- Ask questions **one at a time** using AskUserQuestion tool
- Ask 3-7 questions total (adapt to complexity)
- **Propose alternatives** when they're meaningfully better - don't miss opportunities
- **Resolve everything** - if uncertain, ask. No "Open Questions" section in output
- Skip obvious questions

### Question Format

Use AskUserQuestion with clear options:

```
Question: "Where should the saved state be stored?"
Options:
- DashboardMetadataState (in libs/dashboard/data-access-metadata) - keeps it with other dashboard metadata
- New dedicated store - if this grows into a larger feature
- Local component state - if persistence not needed across sessions
```

---

## Phase 4: Final Proposal

**Goal:** Create implementation-ready proposal with all decisions made.

### Output File

Create `<original-name>-final.md`:

```markdown
# <Feature Name> - Refined Proposal

**Ticket:** <ticket-number>
**Date:** <date>
**Status:** Ready for OpenSpec

---

## Problem Analysis

### Current Behavior
[How it works now with specific file:line references]

### Root Cause
[The actual problem identified in Phase 1]

### Constraints
- [Constraint 1]
- [Constraint 2]

---

## Proposed Solution

### Summary
[2-3 sentence description of the solution]

### Technical Approach
[Key technical decisions with specific locations]

Example:
- Remove `pages` array from `AutoSavePagesService` (`libs/dashboard/data-access-metadata/src/lib/services/auto-save-pages.service.ts:25`)
- Add `lastSavedPages` to `DashboardMetadataState` (`libs/dashboard/data-access-metadata/src/lib/+state/metadata.reducer.ts`)
- Create selector `selectLastSavedPages` in `metadata.selectors.ts`

### Scope

**In scope:**
- [Item 1]
- [Item 2]

**Out of scope:**
- [Item 1 - reason]

---

## Implementation Phases

### Phase 1: [Name]
- [ ] [Specific change] in `path/to/file.ts`
- [ ] [Specific change] in `path/to/other.ts`

### Phase 2: [Name]
- [ ] [Specific change] in `path/to/file.ts`

---

## Existing Code to Reuse

[Patterns/code found in Phase 2 that can be reused]
- `path/to/existing.ts:45` - [what it does, how to reuse]

---

## Q&A Summary

### Q1: [Question]
**Decision:** [Final decision made]

### Q2: [Question]
**Decision:** [Final decision made]

---

## Verification Checklist

Items to verify during implementation:

- [ ] [Relevant item 1]
- [ ] [Relevant item 2]
- [ ] [Relevant item 3]

```

### Checklist Items Selection

Select ONLY relevant items from the Analysis Checklist below. All items are unchecked - they represent things to verify during implementation.

---

## Analysis Checklist (Reference)

Use to select relevant verification items. Not all apply to every feature.

### UI States
- Loading state handling
- Error state display
- Empty state (no data)
- Nullish values handling
- Boundary values (min/max)
- Long strings / text overflow

### Responsive & Layout
- Window resize behavior
- Widget expand/collapse
- Panel resize (left panel, timebar)
- Different widget sizes
- Different layouts (a/aa/aaa)

### Data & API
- API endpoint changes
- Request/response shape
- Pagination handling
- Sorting/filtering behavior
- Data transformation
- Caching strategy

### State Management
- NgRx actions in `+state/*.actions.ts`
- Reducers in `+state/*.reducer.ts`
- Selectors in `+state/*.selectors.ts`
- Effects in `+state/*.effects.ts`
- State persistence

### Integration Points
- Global filters interaction
- Timebar/frame changes
- Cross-widget communication
- Config application (command/UI)

### Performance
- Large data handling (1k+ elements)
- Lazy loading needs
- Debouncing/throttling
- Memory considerations

### Error Handling
- API failure recovery
- Validation errors
- User feedback

### Auto-Update
- Empty timeseries handling
- Data auto update (add/update/remove)
- State transitions

### Testing
- Unit test scenarios
- Integration test scenarios
- Edge case coverage

### Migration
- Breaking changes
- Backward compatibility
- Data migration

---

## Example Session

```
User: let's refine .claude/plans/FNA-1234-auto-save-refactor.md

AI: [Uses extended thinking to analyze deeply]
    [Reads proposal]
    [Searches codebase for auto-save related code]
    [Reads AutoSavePagesService, related reducers, effects]

AI: ## Current Behavior Analysis

    ### How it works now
    - `AutoSavePagesService` (libs/.../auto-save-pages.service.ts:15)
      maintains a local `pages` array
    - On save, it compares current pages with `pages` array
    - `DashboardMetadataEffects` (libs/.../metadata.effects.ts:89)
      triggers save on page changes

    ### Root Cause
    The `pages` array in the service is lost on navigation,
    causing unnecessary saves when returning to dashboard.

    ### Key Constraints
    - Must not break existing auto-save behavior
    - Performance: comparison happens frequently

    Does this match your understanding?

User: Yes, that's correct

AI: [Searches for existing patterns]

    Found related pattern:
    - `lastSavedConfig` in `WidgetConfigState` uses similar approach
      (libs/.../widget-config.reducer.ts:45)

    No duplicate implementation found for page-level tracking.

    [AskUserQuestion: "Where should lastSavedPages be stored?"]
    Options:
    - DashboardMetadataState (consistent with other metadata)
    - AutoSaveState (new dedicated slice)
    - Keep in service with persistence (simpler but less NgRx-ish)

User: DashboardMetadataState

AI: [AskUserQuestion: "Should we track per-dashboard or globally?"]
    Options:
    - Per-dashboard (more accurate, more complex)
    - Global (simpler, covers main use case)

User: Per-dashboard

AI: [Creates FNA-1234-auto-save-refactor-final.md]

    Done! Created .claude/plans/FNA-1234-auto-save-refactor-final.md

    Key decisions:
    - Store in DashboardMetadataState (per-dashboard)
    - Reuse pattern from WidgetConfigState
    - Remove pages array from service

    Ready for OpenSpec.
```

---

## Integration with OpenSpec

After refining:

1. Use `-final.md` as input for OpenSpec `proposal.md`
2. Problem Analysis -> informs `proposal.md` "Why" section
3. Technical Approach -> informs `design.md`
4. Implementation Phases -> informs `tasks.md`
5. Q&A Summary -> documents decisions
6. Verification Checklist -> informs test scenarios

---

## Red Flags - Stop and Investigate

- **Vague problem statement** - Can't identify root cause
- **No existing patterns found** - Unusual for established codebase
- **Multiple unrelated changes bundled** - Should split
- **User unsure about requirements** - Need more discovery
- **Conflicting constraints** - Need stakeholder input

---

## When to Propose Alternatives

**Always propose when:**
- Simpler solution achieves same goal
- Existing pattern in codebase could be reused
- User might not be aware of platform capabilities
- Proposed approach has known pitfalls
- Found similar implementation that could be extended

**Format:**
```
I found an alternative approach worth considering:
[Describe alternative with specific code references]

Trade-offs:
- Pro: [benefit]
- Con: [drawback]

[AskUserQuestion with options]
```
