---
name: writing-result-product
description: Write the product-facing summary of a completed change — a plain-language companion to the result file, for managers / PMs / stakeholders (no file paths, no code). Use when a user-facing change is done and you want a copy-paste-ready summary; typically invoked from the ship phase.
---

# Writing a Product Summary

Produce a **product-facing** companion to the implementation result file, written for managers / PMs / stakeholders — copy-paste-ready, no engineering jargon.

**Announce at start:** "I'm using the writing-result-product skill to write the product summary."

## When to Use

- A change is complete and its result file exists (run from `ship`, or on explicit request)
- **Opt-in:** produce on request, or offer it for user-facing features
- **Skip** pure internal refactors and non-visual plumbing — a product summary adds noise there, not value

## Inputs

Read these first; don't re-derive intent you can read off the artifacts:

- `.claude/temp/<task>-<slug>/<task>-<slug>-spec.md` — the *what + why* (goals, scope)
- `.claude/temp/<task>-<slug>/<task>-<slug>-result.md` — what shipped, decisions made, edge cases
- The actual change (diff) when the artifacts are thin on a behavioral detail

## Rules

- **Plain language, behavior-focused.** Write for someone who will paste it straight to a manager.
- **NO file paths, NO code, NO task/review-loop mechanics.**
- Don't invent outcomes — every claim traces to the spec, result, or code.
- **No git operations** — the user manages commits.

## Save to

`.claude/temp/<task>-<slug>/<task>-<slug>-result-product.md`

## Template

```markdown
# <Feature Name> — Product Summary

**Ticket:** <task>
**Status:** <e.g., Implemented, tested, and committed (not yet merged)>
**Area:** <where in the product this lives>

## What we shipped
<The headline: what's new, in 2-4 sentences a non-engineer understands.>

## What the user sees   (UI features only — omit for non-visual work)
<State/indicator table or short description of the visible behavior.>

## How it behaves
<The behavioral contract: what happens on interaction, the important rules, what's preserved.>

## Decisions made   (when a behavioral choice isn't obvious)
<Product/behavioral choices a stakeholder might question — why it works this way and not an
alternative a user might expect. Plain-language *why*, not technical or architectural reasoning.>

## Scope notes   (when there are meaningful boundaries)
<What was deliberately not changed; new settings/state or the lack of them; reused machinery.>

## Known edge cases (non-blocking)   (when any)
<Plain-language risk disclosure; invite a follow-up decision ("let us know if worth a follow-up").>
```
