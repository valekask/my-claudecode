---
name: advisor
description: Get an independent, deeper read on ONE hard decision from a stronger model before committing to it — consulted by `brainstorming` and `writing-plans` at key moments (a failure/edge-state decision, the author's own hedge, a user-visible `unconfirmed` call, a named risk only partly covered, and a pre-mortem before the gate). Dispatches a fresh subagent on Opus at max effort with a short evidence brief — never the author's reasoning — and returns a recommendation to the caller. Read-only; writes nothing. Use when a skill says to consult the advisor, or directly as /advisor <decision>.
---

# Advisor

A second, deeper read at the moments where a wrong call is expensive and invisible until later. The
author keeps the decision; the advisor checks it against the evidence with fresh eyes.

**Independence is the point.** The advisor gets the decision and pointers to evidence — never the
author's reasoning or transcript — so it reads the code and artifacts itself instead of agreeing with a
framing. Same model family as the author, so the clean brief and the higher effort are what make it a
different read.

## When to consult

Triggers come from a review of recent tasks: these are the moments where a spec or plan decision later
caused rework or shipped a defect. The approach choice — which looks hardest — never did.

**While writing — the moment one of these appears:**

1. **Failure, invalid-input or lifecycle decision** — what happens when a call fails or input is
   malformed, or what creates and clears new state. Above all a fallback that *fails open* (keeps going
   with defaults) on auth, saved data, or anything the user sees.
2. **Your own hedge** — you are about to write "known risk… if X then Y", "accepted / not fixed", "no
   precedent in the repo", or "cheaper than wiring it". The hedge is the doubt; consult instead of
   writing it down.
3. **`unconfirmed` call on user-visible behaviour** — copy, what is shown or hidden, when a notice
   appears. (`unconfirmed` on scope cuts or internal timing is *not* a trigger — those held up.)
4. **A named risk only partly covered** — the spec/plan names a risk area (persisted state, shared code
   read by many surfaces) but the ACs or tasks cover only some of the places it lives.
5. **A shared-library edit for a single consumer**, or a new abstraction added only for testability.

**Once, before the gate — the pre-mortem** (Medium/Complex tier): before the spec or plan goes to its
review loop, ask "which decision here fails worst, and do the ACs / tasks cover it?" Brief it with the
document path and the Decisions section's ids.

**Never for:**

- Anything reading the code answers — read it yourself.
- Product or scope questions — those go to the user (or become `unconfirmed` in `--agentic`).
- Behaviour you only have from an ADR's or doc's wording, with no discovery fact behind it — the
  advisor would trust the same wording. Observe it instead (`discover`'s behaviour-checker).
- The approach choice when it rests on codebase precedent, an ADR or a backend contract — in every
  task checked it held.

**Cap: 3 consults per phase**, the pre-mortem included. Needing more means the spec is unsettled —
surface that to the user instead.

## How to consult

Dispatch one subagent with the template in `advisor-prompt.md`: **Agent tool, `general-purpose`,
`model: opus`, `effort: max`** — set both on the call, never leave them to the session.

The brief holds:

- **Decision** — one question, stated so it can be answered.
- **Options** — 2–4, each with its trade-off as you see it (or the single choice you're about to make).
- **Leaning + confidence** — which one and how sure (high / medium / low).
- **Doubt** — exactly what you're unsure about; for a trigger-2 hedge, quote it.
- **Evidence** — paths, not prose: spec/plan/discovery file with `F-n` ids, ADRs, code files and
  symbols. The advisor reads them itself.
- **Constraints** — what can't change (User Technical Notes, binding requirements, ADR guards).

Leave out how you got here. If you need a paragraph to explain your reasoning, the decision is not yet
stated as a question.

## What comes back

The format is fixed in `advisor-prompt.md`: recommendation, confidence, as many reasons as the decision
needs (often 1–2, each citing its source), the main risk, what the brief missed, and whether it needs a
human.

**What you do with it:**

- **Agree** → decide, and add "settled by: advisor" to that line in the Decisions section.
- **Disagree** → you may still decide your way, but tag the decision **`unconfirmed`** with one line on
  the advisor's objection, so it surfaces at the human gate. Never drop an objection silently.
- **Needs human** → ask the user (interactive) or record it as `unconfirmed` (`--agentic`).
- **Premise wrong** (the advisor says the evidence doesn't support the brief) → re-read the evidence
  before deciding anything; the decision changes, not just its wording.

No artifact is written: the answer is for the calling skill, and its trace is the Decisions line.

## Invoked directly

`/advisor <decision>` from any session: build the same brief from the question and the files the user
names, dispatch the same subagent, and relay its answer as returned. Ask for the evidence paths if none
are given — an advisor without evidence is just a second opinion from memory.
