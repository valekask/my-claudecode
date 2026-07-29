---
name: ship
description: Finalize a verified change — capture the product summary and ADR (when warranted), then stage and commit. Use AFTER manual verification + smoke test pass. Writes docs and commits; makes no code changes and never pushes.
---

# Ship

The **finalize phase**. Run it after the change has been polished, manually verified, and smoke-tested. Ship documents the verified result and commits it — it does **not** change code (polish already did) and it **never pushes** — after committing it offers to hand off to `open-pr`, which owns the push and the PR.

**Announce at start:** "I'm using the ship skill to capture docs and commit the verified change."

**Runs only when you invoke it** — never proactively, never on its own initiative at the end of a task.

**Precondition:** the code is already formatted, gated, and **manually verified**. If it hasn't been verified yet, stop and tell the user to verify first — ship assumes a green change.

**Core principle:** No code mutation in ship. If shipping reveals a code problem, stop and bounce back to polish + verification — do not fix code here, because that would invalidate the verification.

## `--agentic` mode

Invoked as `ship --agentic` (used by an orchestrator finalizing a change with little human attention). It removes the **three prompts** — the verification question, the commit go-ahead, and the hand-off offer. Nothing else changes.

**In `--agentic` mode:**

- **Read the verdict instead of asking (Step 1).** Take `smoke-test`'s verdict JSON from the task dir (`.claude/temp/<task>-<slug>/`) and proceed only on `"verdict": "pass"`. On `fail` / `blocked` — or when **no verdict file exists** — **stop and report**. An unattended ship must never assume a green change it cannot see; a `dogfood` report with every journey passing counts as the verdict.
- **Decide the product summary and the ADR yourself (Steps 2-3)** by the criteria already documented there: user-facing change at `Medium`/`Complex` tier → write the product summary (`Simple` tier skips it); non-obvious constraints that won't be recoverable from the code → write the ADR. Don't offer, don't ask, and record the call plus its reasoning in the report. The ADR bar does not drop because nobody is watching — still no ADR for straightforward work.
- **Invoking the skill is the commit go-ahead (Step 4.4).** Still confirm the repo, still `git add` only what Step 4 lists, still show the proposed message in the report, still commit exactly once. The commit stays local and revertible — that is what makes it the one git write this flag may authorize.
- **Chain or stop at Step 5, don't ask.** If the commit landed on a non-default branch, `origin` exists, and the caller asked for a PR, hand off to `open-pr --agentic`. Otherwise report the commit and stop.

**Never removed by the flag:** the repo guard, the no-code-mutation rule, the no-push rule, and the no-footer rule. If shipping reveals a code problem, stop and bounce back to polish — do not fix it here because the pipeline is unattended.

Without the flag, the interactive path below is unchanged.

## The Process

### Step 1: Confirm the change is verified

Confirm (or ask) that manual verification + smoke test have passed. If not, stop here. (In `--agentic` mode, read the verdict file instead of asking.)

### Step 2: Product summary (opt-in)

Invoke the `writing-result-product` skill to produce `<task>-<slug>-result-product.md` **when the change is user-facing *and* the spec's complexity tier is `Medium` or `Complex`**. (That skill reads the spec + result file; it owns the format.)

**Skip it for `Simple`-tier changes** — write one only if asked. A one-screen tweak doesn't need a stakeholder document, and a summary nobody reads costs the same attention as one they do. Skip pure internal refactors at every tier. When the tier isn't recorded anywhere (no spec, ad-hoc work), judge by the same bar: would a manager or PM actually need this described? If not, skip and say so in the report.

### Step 3: ADR (only when warranted)

Invoke the `writing-adr` skill **only** when the change involved non-obvious constraints or edge cases that won't be recoverable from the code — costly-to-reverse decisions where genuine alternatives existed. This is opt-in judgment; never auto-write an ADR for straightforward work (noise erodes the ADR set). The result file's Decisions / Concerns and the actual code are the inputs.

### Step 4: Stage, review, and commit

1. **Confirm the repo.** Run `git rev-parse --show-toplevel` and confirm it's the target project — under orchestration the cwd may differ from where you intend to commit. Stop if it's the wrong repo. (**Worktree-safe:** if the work lives in a git worktree, run ship from inside it — `--show-toplevel` resolves to the worktree root and the commit lands on its branch, no special handling needed.) Then run `git status` and `git diff` (and `git diff --cached`) so you and the user see exactly what will be committed.
2. `git add` the change (the implementation + any ADR; result/product-summary live under `.claude/temp/` — include them only if the user tracks that directory).
3. Propose a commit message following the **Commit message convention** in `docs/CONTRIBUTING.md` (authoritative) — `<task>: (<type>:<scope>) <subject>`, header only by default (no body/footer unless the change warrants it). If that file isn't present in the repo, the format still holds: `<type>` ∈ feat|fix|docs|style|refactor|perf|test|build, `<scope>` is project-defined, `<subject>` is imperative present tense, lowercase first letter, no trailing dot. Show it to the user.
4. On the user's go-ahead, `git commit`. (In `--agentic` mode the invocation *is* the go-ahead — see [`--agentic` mode](#--agentic-mode).)

**Commit rules (MANDATORY — from the project's git restrictions):**
- Commit only as part of running ship (this is the explicit request); show the message first.
- **Do NOT add a `Co-Authored-By:` trailer or any other footer.**
- **NEVER push from ship.** Pushing is `open-pr`'s job — hand off to it (Step 5) instead.
- Do not amend, rebase, reset, or touch git config/hooks.

### Step 5: Hand off

1. Report what was committed (files, message, ADR/product-summary if written).
2. **Ask about the next step:** offer to continue with the `open-pr` skill to open a PR for this branch. Offer it only when the commit landed on a **non-default** branch and the repo has an `origin` remote — otherwise just report and stop.
3. If the user says yes, invoke `open-pr` — it drafts, previews, and waits for its **own** approval before pushing the feature branch and creating the PR. If the user declines, stop there; the branch stays local and unpushed.

Ship never pushes, not even when handing off — each skill owns its own task, and the push belongs to `open-pr`.

## Red Flags

**Never:**
- Change code in ship — bounce back to polish + verify instead
- Ship code that hasn't been manually verified
- Push, amend, rebase, or reset — even while handing off to `open-pr`
- Add a `Co-Authored-By:` or any commit footer
- Auto-write an ADR for straightforward work
- Write a product summary for a pure internal refactor, or for a `Simple`-tier change unless asked
