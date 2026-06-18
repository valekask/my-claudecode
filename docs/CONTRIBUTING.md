# Contribution Guideline

The single source of truth for **branch**, **commit**, **pull-request**, and **artifact-naming** conventions. The workflow skills, the management workspace, and each project all defer to this file instead of restating the rules — copy it to a project to make it that project's convention.

The **only** project-specific piece is the **scope list**, which lives in the project's `CLAUDE.md`, not here (see [Scope](#scope)). Keeping it out of this file is deliberate: the grammar below rarely changes, so a copied CONTRIBUTING.md stays current even as scopes evolve per project.

- [Vocabulary](#vocabulary)
- [Branch name convention](#branch-name-convention)
- [Commit message convention](#commit-message-convention)
- [Pull request convention](#pull-request-convention)
- [Artifact & directory naming](#artifact--directory-naming)
- [Scope](#scope)

## Vocabulary

- **`<task>`** — the Jira ticket number (e.g. `FNA-1234`). Links the work to the issue tracker and keeps names unique and searchable.
- **`<slug>`** — `<scope>-<subject>`: 2–3 lowercase, dash-separated words.
  - **`<scope>`** — the affected part of the project. **Project-defined** — see [Scope](#scope). Omit for changes that span many areas.
  - **`<subject>`** — a couple of words on what changes.
- **`<branch-type>`** — an optional branch suffix marking a **follow-up round on already-shipped work** (see [Branch type](#3-branch-type-optional)).

## Branch name convention

```
(<prefix>/)<task>-<slug>(-<branch-type>)
```

Lowercase, dash-separated, one purpose per branch.

### 1. Prefix (rare — omit by default)

Regular task branches have **no prefix**. Use a prefix only for the two integration branches you branch *from*, not for per-task work:

- `release/` — preparing a new production release
- `hotfix/` — a critical production fix

### 2. `<task>-<slug>` (always)

- **`<task>`** — the ticket number; always present.
- **`<slug>` = `<scope>-<subject>`** — the project scope plus a short description. Omit the scope if the change spans many areas (`<task>-<subject>`).

### 3. `<branch-type>` (optional)

Omit by default. Add it only for a follow-up round on work that already shipped:

- **`uat`** — UAT feedback / acceptance follow-ups. The default follow-up round.
- **`bugfix`** — a post-ship defect round that doesn't warrant a `hotfix/` release branch.

### Examples

```
FNA-1234-timeline-hover
FNA-1234-network-widget-filters
FNA-1234-timeline-hover-uat
FNA-1234-network-widget-filters-bugfix
release/FNA-9272-20.1.1
hotfix/FNA-1234-editor-scripting
```

## Commit message convention

Header only by default; body and footer are optional. Keep every line ≤ 100 characters.

```
<task>: (<type>:<scope>) <subject>

<body>      (optional)

<footer>    (optional)
```

**`<task>`** — the Jira ticket number. Because it already leads the header, a footer issue-reference is **redundant** — omit the footer unless you're cross-referencing *other* tickets.

**`<type>`** — the kind of change:

- **feat** — a feature
- **fix** — a bug fix
- **docs** — documentation
- **style** — formatting only; no meaning change
- **refactor** — neither fixes a bug nor adds a feature
- **perf** — a performance improvement
- **test** — adds or corrects tests
- **build** — build system or external dependencies

**`<scope>`** — the affected part of the project; **project-defined** (see [Scope](#scope)). Use the empty scope for cross-cutting changes.

**`<subject>`** — imperative, present tense ("change", not "changed"); lowercase first letter; no trailing dot. It should complete "If applied, this commit will _…_".

**Body** (optional) — what & why, not how; for changes whose motivation isn't obvious from the diff.

**Footer** (optional) — additional issue references only.

### Example

```
FNA-1234: (fix:editor) correctly highlight script
```

## Pull request convention

- **Title** — a concise imperative summary; lead with the `<task>` reference.
- **Base** — the appropriate integration branch (the repo default, unless targeting a `release/` or `hotfix/` line).
- **Reviewers** — set your technical leads.
- **After merge** — make sure the branch is closed/deleted.

Two ways to open one:

- **Automated** — the `open-pr` skill drafts the PR, shows a preview, and on your approval pushes the branch to a **same-name** remote branch and creates the PR via the Bitbucket Cloud REST API.
- **Manual** — confirm the build is stable, push your branch, create the PR in Bitbucket against the appropriate base, and set reviewers.

## Artifact & directory naming

Workflow artifacts share the branch's `<task>-<slug>` stem (without the prefix or branch-type):

```
directory:  .claude/temp/<task>-<slug>/        (one folder per ticket)
file:       <task>-<slug>-<file-type>.md
```

- **One folder per ticket.** Every artifact for a ticket lives together — `proposal`, `spec`, `plan`, `result`, `result-product`, `review`, `uat`, `discussion`. A follow-up round adds files to this folder rather than creating a new one (only the *branch* carries the `<branch-type>` suffix).
- **`<file-type>`** is the artifact kind: `proposal` | `spec` | `plan` | `result` | `review` | `result-product` | `uat` | `discussion`.

> `uat` appears as both a `<file-type>` and a `<branch-type>` — same word, two dimensions: the **file** (`<task>-<slug>-uat.md`) is the follow-up ledger; the **branch** (`<task>-<slug>-uat`) is the round that works through it.

## Scope

`<scope>` values are **project-specific** and defined in the project's `CLAUDE.md`, not in this file. Examples seen across projects: `platform`, `dashboard`, `timeline`, `network-widget`, `widgets`, `ilo-template`. Use the **empty** scope for changes that span many areas.
