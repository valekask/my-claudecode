# Contribution Guideline

The single source of truth for **branch**, **commit**, and **pull-request** conventions. The workflow skills, the management workspace, and each project all defer to this file instead of restating the rules — copy it to a project to make it that project's convention.

The **only** project-specific piece is the **scope list**, which lives in the project's `CLAUDE.md`, not here (see [Scope](#scope)). Keeping it out of this file is deliberate: the grammar below rarely changes, so a copied CONTRIBUTING.md stays current even as scopes evolve per project.

- [Vocabulary](#vocabulary)
- [Branch name convention](#branch-name-convention)
- [Commit message convention](#commit-message-convention)
- [Pull request convention](#pull-request-convention)
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

Regular task branches have **no prefix**. Prefixes mark long-lived **integration branches** you branch *from* — never per-task work. The common ones:

- `release/` — preparing a new production release
- `hotfix/` — a critical production fix
- `feature/` — a long-lived integration line / release train, when a project uses one as its default branch

The exact set of integration branches (and their full names) is **project-defined** — see the project's `CLAUDE.md`.

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
feature/FNA-1234-monitoring-26.x
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

**Footer** (optional) — additional issue references only. **Never** add a `Co-Authored-By:` trailer (or any other tool/agent attribution footer).

### Example

```
FNA-1234: (fix:editor) correctly highlight script
```

## Pull request convention

- **Title** — follow the commit header format: `<task>: (<type>:<scope>) <subject>` (e.g. `FNA-16973: (feat:ilo) reorder timeline toolbar to group time-related controls`). Same `<type>` / `<scope>` / `<subject>` rules as a commit; pick the type and scope that best summarize the PR as a whole.
- **Base** — the appropriate integration branch (the repo default, unless targeting a `release/` or `hotfix/` line).
- **Reviewers** — set your technical leads.
- **After merge** — make sure the branch is closed/deleted.

Two ways to open one:

- **Automated** — the `open-pr` skill drafts the PR, shows a preview, and on your approval pushes the branch to a **same-name** remote branch and creates the PR via the Bitbucket Cloud REST API.
- **Manual** — confirm the build is stable, push your branch, create the PR in Bitbucket against the appropriate base, and set reviewers.

## Scope

`<scope>` values are **project-specific** and defined in the project's `CLAUDE.md`, not in this file. Examples seen across projects: `platform`, `dashboard`, `timeline`, `network-widget`, `widgets`, `ilo-template`. Use the **empty** scope for changes that span many areas.
