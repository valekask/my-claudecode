---
name: prepare
description: Scaffold a new ticket — create the working branch, the task directory, and a proposal template to fill in. Use at the very start of a Jira task, before brainstorming. The first phase of the workflow.
---

# Prepare

The **kickoff phase**. Given a ticket like `FNA-1234-currency-filter`, prepare creates the branch, the task directory, and an empty proposal for the user to fill in. After this, the user writes the proposal, then runs `brainstorming` in a fresh session.

**Announce at start:** "I'm using the prepare skill to scaffold this ticket."

## Inputs

- **Task name** in the form `<ticket-number>-<slug>` (e.g., `FNA-1234-currency-filter`). Accept it as an argument; if missing, ask for it via AskUserQuestion. Validation is **advisory**: it should look like the project's branch-naming convention (defined in the project's `CLAUDE.md` / Git Workflow) — a ticket number plus a dash-separated, lowercase slug. If it doesn't match, warn and confirm with the user rather than blocking.
- **Base branch** (optional): defaults to the repo's default branch. Accept `--base <branch>` to branch off a release branch instead.

## The Process

### Step 1: Resolve the task name

Take it from the argument or ask. Check it looks like the project's `<ticket-number>-<slug>` convention; if it doesn't, warn and confirm rather than block. This name is used for **both** the branch and the task directory/prefix.

### Step 2: Determine the base branch

Default to the repo's default branch — detect via `git symbolic-ref refs/remotes/origin/HEAD` (strip the `origin/` prefix); fall back to `main` if that fails. Use `--base <branch>` when the user specifies a release branch.

**Do NOT auto-fetch or pull.** Branch off the local base as-is; if the user wants it fresh, they pull first. (Network/write git operations stay in the user's hands.)

### Step 3: Create the branch

Create and switch to a branch named exactly `<task>` off the base:

```
git switch -c <task> <base>
```

> **Note:** Creating the branch off the default is the sanctioned way to isolate work before the first edit — the project's git workflow lets agents create branches proactively. prepare creates and switches only; it never commits.

If a branch with that name already exists, stop and tell the user rather than overwriting state.

### Step 4: Scaffold the task directory

Create `.claude/temp/<task>/` containing `<task>-proposal.md` (from the template below). Do **not** create an `assets/` directory — the user adds one only on the rare occasion they have mockups.

### Step 5: Write the proposal template

Write `<task>-proposal.md` with the template below — kept light, because `brainstorming` re-explores intent. Do not fill it in; the user does that.

```markdown
# <Ticket>

## Title
<Short title for the change.>

## Description
<What needs to change and why.>

## Technical notes
<Any constraints, hints, exact names/values, or implementation notes to honor.>
```

### Step 6: Hand off

Report the branch created and the proposal scaffolded, and tell the user to:
1. Fill in `<task>-proposal.md`
2. Run `brainstorming` (fresh session) on the proposal

## Rules

- **No commits.** Prepare creates a branch and writes files only — it does not stage or commit anything.
- Never overwrite an existing branch or an existing task directory without telling the user.
