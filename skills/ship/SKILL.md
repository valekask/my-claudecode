---
name: ship
description: Finalize a verified change — capture the product summary and ADR (when warranted), then stage and commit. Use AFTER manual verification + smoke test pass. Writes docs and commits; makes no code changes and never pushes.
---

# Ship

The **finalize phase**. Run it after the change has been polished, manually verified, and smoke-tested. Ship documents the verified result and commits it — it does **not** change code (polish already did) and it **never pushes** (you push manually).

**Announce at start:** "I'm using the ship skill to capture docs and commit the verified change."

**Runs only when you invoke it** — never proactively, never on its own initiative at the end of a task.

**Precondition:** the code is already formatted, gated, and **manually verified**. If it hasn't been verified yet, stop and tell the user to verify first — ship assumes a green change.

**Core principle:** No code mutation in ship. If shipping reveals a code problem, stop and bounce back to polish + verification — do not fix code here, because that would invalidate the verification.

## The Process

### Step 1: Confirm the change is verified

Confirm (or ask) that manual verification + smoke test have passed. If not, stop here.

### Step 2: Product summary (opt-in)

Invoke the `writing-result-product` skill to produce `<task>-<slug>-result-product.md` **when** the change is user-facing — offer it otherwise, skip pure internal refactors. (That skill reads the spec + result file; it owns the format.)

### Step 3: ADR (only when warranted)

Invoke the `writing-adr` skill **only** when the change involved non-obvious constraints or edge cases that won't be recoverable from the code — costly-to-reverse decisions where genuine alternatives existed. This is opt-in judgment; never auto-write an ADR for straightforward work (noise erodes the ADR set). The result file's Decisions / Concerns and the actual code are the inputs.

### Step 4: Stage, review, and commit

1. Run `git status` and `git diff` (and `git diff --cached`) so you and the user see exactly what will be committed.
2. `git add` the change (the implementation + any ADR; result/product-summary live under `.claude/temp/` — include them only if the user tracks that directory).
3. Propose a commit message in the project's format — `<task>: (<type>:<scope>) <subject>` (see the project's `CLAUDE.md` / Git Workflow). `<type>`: feat, fix, docs, style, refactor, perf, test, build; `<subject>`: imperative present tense, lowercase first letter, no trailing dot. Show it to the user.
4. On the user's go-ahead, `git commit`.

**Commit rules (MANDATORY — from the project's git restrictions):**
- Commit only as part of running ship (this is the explicit request); show the message first.
- **Do NOT add a `Co-Authored-By:` trailer or any other footer.**
- **NEVER push.** The push is always the user's, run manually.
- Do not amend, rebase, reset, or touch git config/hooks.

### Step 5: Hand off

Report what was committed (files, message, ADR/product-summary if written) and remind the user to **push manually** when ready.

## Red Flags

**Never:**
- Change code in ship — bounce back to polish + verify instead
- Ship code that hasn't been manually verified
- Push, amend, rebase, or reset
- Add a `Co-Authored-By:` or any commit footer
- Auto-write an ADR for straightforward work
- Write a product summary for a pure internal refactor
