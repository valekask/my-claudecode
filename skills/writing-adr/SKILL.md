---
name: writing-adr
description: Use to capture an Architecture Decision Record — a committed snapshot of why complex code is the way it is, plus the edge cases and non-obvious constraints that are unrecoverable from the code itself. Invoke when complex code warrants durable context, or at the end of an implementation.
---

# Writing ADRs

Capture a **decision + its context at a moment in time** into a committed file under `docs/adr/`.

The pain this solves: coming back to complicated code months later, the *why* and especially the *edge cases* are gone — neither humans nor agents have enough context. The code is the **primary source** for *what it does now*; an ADR is the **only place intent lives** (*why it's this way, what each guard protects, what breaks if removed*). Unlike behavior-describing docs, an ADR doesn't go stale — it records a moment in time. The only risk is silent reversal, which superseding handles.

## The Gate (no auto-write)

ADRs are **never** generated automatically. Write one only when judgment says it earns its place. Record a decision only when **all three** hold:

1. **Costly to reverse** — or the code is complex enough that we'll genuinely puzzle over it again.
2. **Reasoning isn't obvious from the code** — intent / forces can't be reconstructed by reading it.
3. **Genuine alternatives or constraints existed** — there was a real choice, with a specific rationale.

**If any of the three is missing, skip the ADR.** A simple, self-explanatory, or easily reversible change does not get one — noise erodes the signal that makes the folder worth reading.

When invoked at the end of an implementation, **offer** an ADR only if the work involved non-obvious constraints; let the user decide.

## Two types

| | Feature-level | System-wide |
|---|---|---|
| **File** | `docs/adr/<ticket-number>-<slug>.md` | `docs/adr/NNNN-<component>.md` |
| **Example** | `docs/adr/FNA-15102-property-based-coloring.md` | `docs/adr/0001-auth.md` |
| **Shape** | Session snapshot + mandatory edge cases | Stable decision record |
| **Purpose** | Quickly recover what/why for a complex task | Document durable, system-shaping choices |
| **When** | Authored at implementation time for complicated code (the weekly pain) | When a stable, system-wide decision is made or debated — let one appear from real friction, don't backfill speculatively |

Start minimal. Grow the set from real friction, not speculatively.

## Choosing the type

Default to **feature-level** — it's the common implementation-time case. At invocation, confirm before writing:

> Writing a feature-level ADR (`<ticket-number>-...`). Or did you mean a system-wide one?

Write a **system-wide** ADR only on explicit request (e.g. "write a system-wide ADR for the timeline"). In that case the user typically names the sources directly — a feature area or directory (e.g. "source is `libs/feature-timeline`"). Use those plus that area's git history; the brainstorm/plan/execute artifacts below usually don't apply.

## Where the content comes from

An ADR needs both halves — the *why* and the *edge cases* — which live in different places. Gather them before writing:

- **Why / intent / forces** → the spec (`.claude/temp/<task>/<task>-spec.md`) and brainstorming context.
- **Structural decisions** → the plan (`.claude/temp/<task>/<task>-plan.md`) — reuse choices, traced callers, where code landed. Good fodder for *Key decisions*.
- **Decisions made / concerns** → the result file (`.claude/temp/<task>/<task>-result.md`), if present. Raw input, not a substitute.
- **Edge cases & non-obvious constraints** → **read the actual code.** This is the #1 payload and it is *not* in any doc. Open the implemented files, find each guard / special case, and articulate what it protects against and what breaks if removed.
- **Verification pointer** → the ticket / PR, so a reader (or agent) can follow it into git history (the primary source).

**Writing retroactively** (for code you didn't just implement, or any system-wide ADR): the temp artifacts often won't exist. Then **read git history as a source** — `git log` / `git show` on the relevant files for commit messages and diffs that explain intent — alongside the code itself.

## Feature-level template

```markdown
# <ticket-number>: <short decision sentence — one readable line; push detail to Summary>

- **Status:** Accepted | Proposed | Superseded by <id>
- **Date:** YYYY-MM-DD
- **Ticket(s):** <ticket-number>
- **Key files:** 2-4 anchors (ticket/PR has the full list)
  - `libs/.../foo.component.ts`
  - `libs/.../bar.service.ts`

## Summary
<2-3 sentences: what this task changed. Fast-orientation hook. Keep it short.>

## Why
<Lead with the problem/symptom (or the requirement) in plain language — what was wrong or
what we set out to achieve — THEN the forces that made it non-trivial. The whole section is
the part NOT recoverable from code; don't open on the technical mechanism.>

## Key decisions
<What we chose and why; one bullet each. Fold deliberate trade-offs/limitations in here.
Omit a rejected option unless it keeps tempting people back.>
- <decision> — <why; what it rules out>

## Edge cases & non-obvious constraints   ← REQUIRED
<For each guard/special case: what it protects against, what breaks if removed.
If truly none, write "None" — and reconsider whether this needed an ADR.>
- <guard/constraint> — protects against <X>; removing it breaks <Y>

## References   (optional — omit when empty)
<Related/superseded ADRs, a design doc that informed the decision.>
```

Rules:
- **Title is a sentence**, not a topic label (ADR convention) — but keep it to **one readable line**; push the rest into Summary. A title that needs three clauses is doing Summary's job.
- **Metadata (Status/Date/Ticket/Key files) is a bullet list**, not bare consecutive lines — bare lines collapse into one run-on paragraph when rendered.
- **`Key files`** lists 2–4 anchor files where the non-obvious logic lives — *not* a full manifest — as a nested list, one path per line. The ticket/PR carries the complete list and is the entry into git history.
- **`Edge cases & non-obvious constraints` is the only mandatory body section** beyond Summary. It carries the value that justified the ADR.
- Don't fill a section for its own sake — keep everything except Edge cases minimal, present it only when it has signal.

## System-wide template

```markdown
# NNNN: <short decision sentence — one readable line>

- **Status:** Accepted | Proposed | Superseded by <id>
- **Date:** YYYY-MM-DD

## Context
<The problem / forces that made this decision non-trivial.>

## Decision
<What we chose.>

## Consequences
<Trade-offs accepted (+ / -). Downstream effects worth calling out.>

## Alternatives considered   (optional — only if a rejected option keeps tempting people)

## References   (optional)
<Related/superseded ADRs, docs.>
```

## File naming & numbering

- **Feature:** `<ticket-number>-<kebab-slug>.md`, slug derived from the decision/task.
- **System-wide:** `NNNN-<kebab-component>.md`. To pick `NNNN`, list `docs/adr/`, find the highest existing system-wide number, increment, zero-pad to 4 digits.
- Create `docs/adr/` only when the first ADR is written.

## README index

Keep `docs/adr/README.md` as the index — it's the entry point agents scan to find *relevant* ADRs cheaply (read one file, match by decision/area, open only the hits). Use a table per type so the decision, area, and status are visible without opening each file:

```markdown
# Architecture Decision Records

Why our code is the way it is. Code is the primary source for *what*; these record *why*
and the edge cases that aren't recoverable from code. Append-only — never edit an accepted
ADR's decision, supersede it. **Scan this index first** to find ADRs relevant to the area
you're touching, and skip anything `Superseded`.

## System-wide
| ADR | Decision | Status |
|-----|----------|--------|
| [0001](0001-auth.md) | Auth via session cookies, not JWT | Accepted |

## Feature-level
| ADR | Decision | Area | Status |
|-----|----------|------|--------|
| [FNA-15102](FNA-15102-property-based-coloring.md) | Color rows by domain property | timeline grid | Accepted |
```

After writing an ADR, add a row to the matching table — the one-line Decision (+ Area) is what lets an agent judge relevance from the index alone.

## CLAUDE.md note (target repo)

Once `docs/adr/` exists, the target repo's `CLAUDE.md` should carry a short pointer so agents know the project has ADRs and use them — when changing code *and* when reading/explaining it. Don't reference this skill by name (a project may not have it installed). Suggested note:

```markdown
## Architecture Decision Records

This project keeps Architecture Decision Records in `docs/adr/` — they record *why* complex
code is the way it is: intent, trade-offs, and edge cases not recoverable from the code.
Code is primary for *what*; ADRs are authoritative for *why*. `docs/adr/README.md` indexes them.

- Before proposing or implementing architectural changes, scan `docs/adr/README.md` and read
  any ADRs relevant to the area you're touching.
- When explaining or analyzing how code works, consult `docs/adr/README.md` too — the code
  shows *what*; the ADR holds the *why* and edge cases the code can't tell you.
- When implementing complex code with non-obvious constraints, consider capturing one in `docs/adr/`.
- Never edit an accepted ADR's decision — supersede it.
```

## Lifecycle

- Carry a `Status` field. Change a decision by **superseding**: write a new ADR, set the old one's `Status: Superseded by <id>`, and cross-link in `References`. **Never edit the decision of an accepted ADR** — a clean supersede pointer is what reads well on the return visit.

## Git

Write the ADR file and update the README index. **Do not commit** — the user commits manually.

## Red flags

**Never:**
- Auto-write an ADR — the gate is a judgment call, surfaced to the user.
- Write the Edge cases section from the result file or spec alone — **read the code's guards.**
- Enumerate 10+ files in `Key files` — list 2–4 anchors, point to the ticket/PR for the rest.
- Edit an accepted ADR's decision instead of superseding.
- Add a Concerns / Known Issues section — transient issues go stale; deliberate trade-offs belong in Key decisions.
- Commit on your own — the user owns all commits.
