---
name: prepare
description: Scaffold what you're about to work on — a new task (branch + directory + proposal), a UAT/follow-up round (branch + uat ledger), or a discussion (discussion file, no branch). Routes by explicit mode (`uat` / `discuss`) or infers from the task-folder state and confirms. Use at the start of a Jira task, when opening post-ship follow-ups, or to capture a ticket conversation.
---

# Prepare

The **scaffolding skill**. It sets up the right artifacts for one of three things you're about to start, then hands off. It creates branches and files only — it never commits.

| Mode | Trigger | Creates | Branch? |
|------|---------|---------|---------|
| **new** | `prepare <task>-<slug>` (default) | `<task>-<slug>/` + `<task>-<slug>-proposal.md` | yes — `<task>-<slug>` |
| **uat** | `prepare uat <task>-<slug>` | `<task>-<slug>-uat.md` ledger | yes — `<task>-<slug>-uat` |
| **discuss** | `prepare discuss <task>-<slug>` | `<task>-<slug>-discussion.md` | no |

**Announce at start:** "I'm using the prepare skill to scaffold this \<new task / UAT round / discussion>."

## Naming conventions

Branch names follow **`docs/CONTRIBUTING.md`** — the single source of truth for branch/commit/PR conventions (the project's `CLAUDE.md` supplies the scope values). Directory and file names are the workflow's own artifacts; they reuse the same `<task>-<slug>` stem, summarized here (and in the README):

```
branch:     <task>-<slug>            (follow-up rounds add a <branch-type>: <task>-<slug>-uat)
directory:  .claude/temp/<task>-<slug>/
file:       <task>-<slug>-<file-type>.md
```

- **`<task>`** — the Jira ticket number (e.g. `FNA-1234`).
- **`<slug>`** — `<scope>-<subject>`; `<scope>` is project-defined (omit it for cross-cutting changes).
- **`<branch-type>`** (branch only, optional) — `uat` (default follow-up round) | `bugfix`. Primary work omits it.
- **`<file-type>`** — the artifact: `proposal` | `spec` | `plan` | `result` | `review` | `result-product` | `uat` | `discussion`.

Throughout this skill, `<task>-<slug>` is the identifier the user supplies (e.g. `FNA-1234-timeline-hover`); it names both the branch and the task directory.

## Inputs

- **Mode** (optional): the literal token `uat` or `discuss` as the first argument. Omit it for a new task, or to let the skill infer from folder state and confirm. See [Step 1](#step-1-resolve-the-mode).
- **Task name** in the form `<task>-<slug>` (e.g., `FNA-1234-timeline-hover`). Accept it as an argument; if missing, ask for it via AskUserQuestion. Validation is **advisory**: it should look like the convention above — a ticket number plus a `<scope>-<subject>` slug. If it doesn't match, warn and confirm with the user rather than blocking.
- **Base branch** (optional, modes that branch): defaults to the repo's default branch. Accept `--base <branch>` to branch off a release/integration branch instead.

## The Process

> **Working directory.** prepare creates the branch and `.claude/temp/<task>-<slug>/` **relative to the current working directory**, and `git switch` acts on the repo there. Under orchestration the cwd may not be the target project — before creating anything, confirm `git rev-parse --show-toplevel` is the repo you mean to work in.

### Step 1: Resolve the mode

**Explicit wins.** If the first argument is `uat` or `discuss`, use that mode — no guessing. This is your escape hatch when inference would get it wrong.

**Otherwise infer from the task folder, then confirm — never act on a silent guess:**

- **No `.claude/temp/<task>-<slug>/` folder** → **new** task. Unambiguous; proceed without asking.
- **Folder exists with a `<task>-<slug>-result*.md`** → you're past shipping, so intent is ambiguous (fixing vs. talking). Ask via AskUserQuestion: **uat** or **discuss**?
- **Folder exists but no result** → you're likely resuming mid-flight. Ask whether you meant **discuss** (add a discussion to this task) or something else, rather than assuming.

A wrong inference then costs one confirmation, not a stray branch.

### Step 2: Resolve the task name

Take it from the argument or ask. Check it looks like the `<task>-<slug>` convention above; if it doesn't, warn and confirm rather than block.

---

## Mode: new task

The **kickoff phase** of the build workflow. Creates the branch, the task directory, and an empty proposal for the user to fill in. After this, the user writes the proposal, then runs `brainstorming` in a fresh session.

### Step N1: Determine the base branch

Default to the repo's default branch — detect via `git symbolic-ref refs/remotes/origin/HEAD` (strip the `origin/` prefix); fall back to `main` if that fails. Use `--base <branch>` when the user specifies a release branch.

**Do NOT auto-fetch or pull.** Branch off the local base as-is; if the user wants it fresh, they pull first. (Network/write git operations stay in the user's hands.)

### Step N2: Create the branch

Create and switch to a branch named exactly `<task>-<slug>` off the base (primary feature work — no `<branch-type>` suffix):

```
git switch -c <task>-<slug> <base>
```

> **Note:** Creating the branch off the default is the sanctioned way to isolate work before the first edit — the project's git workflow lets agents create branches proactively. prepare creates and switches only; it never commits.

If a branch with that name already exists, stop and tell the user rather than overwriting state.

### Step N3: Scaffold the directory and proposal

Create `.claude/temp/<task>-<slug>/` containing `<task>-<slug>-proposal.md` (from the [proposal template](#proposal-template)). Do **not** create an `assets/` directory — the user adds one only on the rare occasion they have mockups. Do not fill the proposal in; the user does that.

### Step N4: Hand off

Report the branch created and the proposal scaffolded, and tell the user to:
1. Fill in `<task>-<slug>-proposal.md`
2. Run `brainstorming` (fresh session) on the proposal

---

## Mode: uat

Opens a **post-ship follow-up round** — UAT feedback, bugfixes, and change requests on work that already shipped. Creates an isolated branch and a `<task>-<slug>-uat.md` ledger to track items and their status.

### Step U1: Check the task state

The folder `.claude/temp/<task>-<slug>/` should already exist (this is post-ship work).
- If it does **not** exist, stop and tell the user — `prepare uat` is for an existing task, not a new one.
- If it exists but has **no** `<task>-<slug>-result*.md`, warn that nothing has shipped yet and confirm before continuing (they may have meant `discuss`, or to keep building on the original branch).
- If `<task>-<slug>-uat.md` already exists, do **not** overwrite it — the round is already open; just report it and stop.

### Step U2: Create the UAT branch

The original task branch is usually merged or gone, so branch off the **integration base**, not the old branch. Detect the base the same way as new-task mode (`git symbolic-ref refs/remotes/origin/HEAD`, fall back to `main`); honor `--base <branch>` for a release/integration branch. The round uses `uat` as its `<branch-type>`:

```
git switch -c <task>-<slug>-uat <base>
```

If a `<task>-<slug>-uat` branch already exists, stop and tell the user rather than overwriting.

### Step U3: Scaffold the UAT ledger

Write `.claude/temp/<task>-<slug>/<task>-<slug>-uat.md` from the [UAT ledger template](#uat-ledger-template). Seed it with any items the user has already named; otherwise leave the example row for them to replace.

### Step U4: Hand off

Report the branch and ledger. Tell the user to:
1. List the follow-up items in `<task>-<slug>-uat.md`, each tagged `uat` / `bug` / `change`.
2. Implement them (use `executing-plans` / `subagent-driven-development`, or the management `fast-track` skill for small, already-clear fixes).
3. Update each item's **Status** and record the commit under **Fixed by** as it lands; then `polish` → verify → `ship` as usual.

---

## Mode: discuss

Captures a **conversation and a proposed answer** for a ticket that needs thought, not (yet) code. No branch — discussion-only tickets stay out of git. Keep it to 1–2 topics per file; the file is optional and lightweight.

### Step D1: Ensure the task folder

Create `.claude/temp/<task>-<slug>/` if it doesn't already exist. (A discussion can be the very first artifact for a ticket, or sit alongside an existing task's files.)

### Step D2: Scaffold the discussion file

Write `.claude/temp/<task>-<slug>/<task>-<slug>-discussion.md` from the [discussion template](#discussion-template). If the file already exists, do **not** overwrite it — append a new `## Topic:` section instead (or tell the user it's there, if there's nothing new to add).

### Step D3: Hand off

Report the file. Tell the user to:
1. Fill in the topic(s) and the proposed answer.
2. Paste the proposed answer into the ticket when settled.
3. If it turns into code work, run `prepare <task>-<slug>` to add the branch and proposal.

---

## Templates

### Proposal template

Kept light, because `brainstorming` re-explores intent.

```markdown
# <task>

## Title
<Short title for the change.>

## Description
<What needs to change and why.>

## Technical notes
<Any constraints, hints, exact names/values, or implementation notes to honor.>
```

### UAT ledger template

```markdown
# <task> — UAT / Follow-ups

**Result:** `.claude/temp/<task>-<slug>/<task>-<slug>-result.md`
**Branch:** `<task>-<slug>-uat`

Post-ship work on already-shipped code. Tag each item `uat` (acceptance feedback),
`bug` (defect found after ship), or `change` (new/changed requirement).

| # | Type | Item | Status | Fixed by |
|---|------|------|--------|----------|
| 1 | <uat\|bug\|change> | <what to change and why> | open | — |

**Status:** `open` → `in-progress` → `done` · `wontfix` (note why in the Item cell).
**Fixed by:** the commit SHA that resolved the item.
```

### Discussion template

```markdown
# <task> — Discussion

Conversation and proposed answers for a ticket that needs thought, not (yet) code.
Keep it to 1–2 topics per file.

## Topic: <short title>

**Question / context**
<What's being asked or decided, in enough detail to stand alone later.>

**Discussion**
<Options weighed, constraints, references — the thinking.>

**Proposed answer**
<The answer to give / the decision, ready to paste into the ticket.>
```

## Rules

- **No commits.** Prepare creates branches and writes files only — it does not stage or commit anything.
- **Explicit mode always wins** over inference; inference never acts on a silent guess — it confirms first.
- Never overwrite an existing branch, proposal, UAT ledger, or discussion file without telling the user. (Discussion is the one exception: append a new topic section rather than overwrite.)
- **discuss** never creates a branch.
