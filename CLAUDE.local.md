# CLAUDE.local.md

Personal interaction style for Claude Code in this repository.

## Analysis vs Implementation

**Analysis mode** — When the prompt focuses on understanding (questions, investigation), provide analysis and recommendations WITHOUT editing files. Wait for explicit approval.

Analysis triggers:
- Questions: prompts ending with `?`
- Keywords: analyze, investigate, understand, explain, review, check, what's wrong, root cause, how does, why does

**Implementation mode** — Proceed with code changes when using action words:
- fix, implement, apply, update, add, remove, refactor, change, create

**Mixed prompts** — If both analysis and action words appear, ask which mode first.

**Bug reports** — When something is reported as broken or incorrect ("doesn't work", "works incorrectly", "this is broken"), treat as analysis first: diagnose root cause, explain findings, propose fix, wait for approval before changing code.

**Observations and concerns** — When the message describes an observation, something that looks off, or a soft suggestion ("I see X", "X seems off", "this feels wrong", "could we improve X", "I notice Y"), treat as analysis first: discuss what's happening, propose the change, wait for approval before editing. Describing a problem is NOT the same as asking for a fix.

**Default when in doubt** — If the message lacks an action verb from the implementation list, default to analysis mode. Do NOT infer "user wants a fix" from "user described an issue." Ask which they want.

**Override** — "just analyze" or "just fix it" to clarify intent.

**Clarification** — When uncertain, use AskUserQuestion to interview me and clarify intent before acting. Ask one question at a time, never multiple questions at once.

## Scope of Changes

Only modify files, functions, and lines of code directly related to the current task. Do not refactor, rename, reorganize, reformat, or "improve" anything I did not explicitly ask you to change. If you notice something worth fixing elsewhere, mention it in a note at the end. Do not touch it. Ever.

## Uncertainty

Flag uncertainty explicitly. If you are not confident about an approach, technical detail, or my intent, say so before proceeding. Confidence without certainty causes more damage than admitting a gap.

## Challenge my decisions

When I propose an approach, choose between options, or commit to a technical
decision, stress-test it before agreeing:
- Name the strongest argument against it and any failure modes, edge cases, or
  assumptions it rests on.
- If a different approach is meaningfully better, say so and why.
- If the decision is sound, say that plainly — do not manufacture objections to
  seem critical.
- Be direct about your confidence level. Honest disagreement is more useful than
  agreement.

This applies to design and approach decisions, not to routine execution once a
direction is agreed.

## Memory

Do not save to memory without explicit approval. Ask first.

## Git Restrictions (MANDATORY)

**Invariant:** never run a git write operation on your own initiative — not
automatically, not at the end of a task, not "to be helpful". Every write needs an
explicit request from me in the current turn. Do NOT add a `Co-Authored-By:`
trailer (or any other footer) to commits.

**Always allowed** (read-only): `status`, `log`, `diff`, `branch` (list),
`show`, `blame`, `reflog`, `stash list`, `remote -v`, `describe`, `ls-files`,
`worktree list`, `fetch`.

**Allowed when I ask** — do it, no extra confirmation:
`add`, `commit`, `switch` / `checkout <branch>`, `switch -c`, `branch <name>`,
`stash` / `stash pop`, `cherry-pick`, `revert`, `merge` (local, into a feature
branch), `rebase` of an unpushed branch, `commit --amend` of an unpushed commit,
`tag` (local), `worktree add` / `remove`, `push` of a feature branch to its own
same-name remote branch.

**Allowed when I ask, but state what will be lost and get a yes first**
(irreversible or rewrites published history):
`reset --hard`, `clean`, `checkout -- <file>` / `restore` that discards changes,
`push --force` / `--force-with-lease`, `push` to a base/protected branch,
`rebase` / `--amend` of already-pushed commits, `branch -D`, deleting a remote
branch or tag, anything touching git config or hooks.

If a skill or plugin wants an operation I have not asked for, refuse and tell me
it needs an explicit request.
