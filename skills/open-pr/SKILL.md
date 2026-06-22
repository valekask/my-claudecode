---
name: open-pr
description: Draft a pull request, show a preview (from → to, title, description), open it only after you approve, then create it via the Bitbucket Cloud REST API. Pushes the feature branch to a same-name remote branch on approval — never to the base branch. Use when asked to "make a PR", "open a PR", "create a PR", or "raise a PR".
---

# Open PR

Turns the current branch into a **Bitbucket Cloud** pull request. The skill **drafts** the PR, shows you a **preview**, and waits for your **approval** before touching the remote. On approval it pushes the feature branch safely and creates the PR via the Bitbucket REST API — in that order, never before.

**Announce at start:** "I'm using the open-pr skill to draft a PR and show you a preview before opening it."

**Runs only when you invoke it** — never proactively.

**The two non-negotiables:**
1. **Nothing reaches the remote before your approval.** No push, no PR creation until you say "approved" / "proceed" / "do it".
2. **The push only ever targets a remote branch of the same name as the current branch.** Never push to, or set upstream to, the base branch. This is the guard against the past mistake where a branch tracked the base and a push landed directly on it.

## Prerequisites

- **`BITBUCKET_API_TOKEN`** + **`BITBUCKET_EMAIL`** — a Bitbucket Cloud **API token** and the Atlassian **email** it belongs to, both exported in the user's shell env (e.g. `~/.zshenv`). Bitbucket REST API requests authenticate with **Basic auth** as `email:api_token` — the **email**, not the username (`username:token` returns 401 on the API; the username is only for git over HTTPS). The token must belong to the Bitbucket **identity that actually has access to the target repo** — if access is inherited via a group or a secondary account, mint the token while signed in as *that* identity. The API token is the app-password replacement; app passwords are deprecated. A scoped token needs **all three** of `read:repository` (required to reach any `/repositories/{ws}/{repo}/…` path — including PRs), `read:pullrequest`, and `write:pullrequest`; scopes are fixed at creation, so a missing one means recreating the token. The skill reads both env vars from the environment; neither is passed as an argument. (`BITBUCKET_USERNAME` / `BITBUCKET_URL` may also be set for other tooling, but this skill does not use them.)
- **`jq`** and **`curl`** on PATH (used to build the request body safely and call the API).

## Inputs

- **Base branch** (optional): the PR target. Defaults to the repo's default branch. Accept `--base <branch>` to target a release branch instead.
- Everything else (from-branch, title, body) is derived — see below.

## The Process

### Step 1: Determine the from-branch and base-branch

- **Repo guard:** confirm `git rev-parse --show-toplevel` is the repo you intend to open a PR for — under orchestration the cwd may not be the target project. Everything below (branches, and the workspace/repo slug in Step 5) derives from *this* repo's `origin`. (**Worktree-safe:** if the branch lives in a git worktree, run open-pr from inside it — the guard resolves to the worktree root, `git branch --show-current` reports the worktree's branch, and the push targets it. The worktree must still exist at PR time, since the push comes *from* it.)
- **From-branch (the PR head):** `git branch --show-current`.
  - If it's empty (detached HEAD) → **STOP** and tell the user; you can't open a PR from a detached HEAD.
- **Base-branch (the PR target):** default to the repo's default branch — detect via `git symbolic-ref refs/remotes/origin/HEAD` (strip the `origin/` prefix); fall back to `main` if that fails. Override with `--base <branch>`.
- **Guard:** if the from-branch **equals** the base/default branch → **STOP**. You never open a PR from the default branch into itself; the user is on the wrong branch.

### Step 2: Draft the title and description

Build the draft from what's actually on the branch — do not invent scope:

- Commits on the branch: `git log <base>..HEAD --oneline`
- Change shape: `git diff <base>...HEAD --stat`
- Task artifacts, if present under `.claude/temp/<task>-<slug>/` (where `<task>-<slug>` matches the branch name): the spec gives *what + why*, the result file gives *what shipped*. These are the best body sources when they exist.

Draft:
- **Title** — follow the commit header format `<task>: (<type>:<scope>) <subject>` (see the **Pull request convention** in `docs/CONTRIBUTING.md`), e.g. `FNA-16973: (feat:ilo) reorder timeline toolbar to group time-related controls`. Take `<task>` from the branch name; pick the `<type>` and `<scope>` that best summarize the whole PR. If `docs/CONTRIBUTING.md` is absent, the format still holds: `<type>` ∈ feat|fix|docs|style|refactor|perf|test|build, `<scope>` project-defined.
- **Description** — a short summary of *what* changed and *why*, plus anything a reviewer needs (testing notes, edge cases). Keep it to what the branch actually contains.

### Step 3: Show the preview and ask for approval

Present exactly this shape, then **stop and wait**:

```
PR preview — approve to open:

  <from_branch>  →  <base_branch>   (on origin)

Title:
  <title>

Description:
  <description>

On approval I will:
  1. git push -u origin HEAD   → pushes <from_branch> to origin/<from_branch>
                                  (upstream = same-name remote branch, never <base_branch>)
  2. create the PR via the Bitbucket REST API (<from_branch> → <base_branch>)
```

Then ask the user to reply **"approved" / "proceed" / "do it"** to open it, or to tell you what to change. Iterate on the title/base/description until they approve.

**Do NOT push or create the PR until the user explicitly approves.** That approval is the explicit, in-the-moment authorization for the push (the project's git rules require this for any push — the preview makes it informed).

### Step 4: On approval — push the feature branch safely

Push the **current branch** to a **same-name** remote branch and set its upstream:

```
git push -u origin HEAD
```

`HEAD` resolves to the current branch and pushes it to `origin/<from_branch>`, setting upstream to that same-name branch. This is the only sanctioned push.

**Forbidden — never do any of these:**
- `git push origin HEAD:<base>` or `git push -u origin <from>:<base>` (pushes/tracks the base — the exact past mistake)
- `git push -u origin HEAD:<anything-but-the-from-branch-name>`
- `git push --force` / `--force-with-lease` (no force-pushing here)

**After pushing, verify the upstream** points at the from-branch, not the base:

```
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

It must read `origin/<from_branch>`. If it reads `origin/<base>` or anything else, **STOP** and tell the user — the tracking is wrong.

(If the branch is already on the remote, a plain `git push` to update it is fine — still same-name only.)

### Step 5: Create the PR (Bitbucket REST API)

Bitbucket Cloud has no `gh`-style CLI, so the PR is created with a direct REST call authenticated by Basic auth (`BITBUCKET_EMAIL:BITBUCKET_API_TOKEN`).

**Preflight — stop if any fails:**
- `BITBUCKET_API_TOKEN` or `BITBUCKET_EMAIL` is empty/unset → **STOP**: tell the user to create a Bitbucket API token and export both `BITBUCKET_API_TOKEN` and `BITBUCKET_EMAIL` (see Prerequisites). Do not proceed.
- The `origin` host is not `bitbucket.org` → **STOP**: this step only knows Bitbucket Cloud.

**Derive workspace + repo slug from `origin`** (never hardcode — the skill may run in different checkouts):

```sh
url=$(git remote get-url origin)
slug=$(printf '%s' "$url" | sed -E 's#^(https?://)?([^@/]+@)?bitbucket\.org[:/]##; s#\.git$##')
workspace=${slug%%/*}
repo=${slug#*/}
```

**Create the PR** with the approved title, description, and branches. Build the JSON body with `jq -n` (never string-interpolate) so quotes/newlines in the title or description can't break the payload or inject fields:

```sh
curl -sS --fail-with-body -X POST \
  -u "$BITBUCKET_EMAIL:$BITBUCKET_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.bitbucket.org/2.0/repositories/$workspace/$repo/pullrequests" \
  -d "$(jq -n \
        --arg t '<title>' --arg d '<description>' \
        --arg s '<from_branch>' --arg b '<base_branch>' \
        '{title:$t, description:$d,
          source:{branch:{name:$s}}, destination:{branch:{name:$b}}}')"
```

- Set `source.branch.name` = `<from_branch>` and `destination.branch.name` = `<base_branch>` **explicitly** — never let either be inferred.
- `--fail-with-body` makes curl exit non-zero on an HTTP error while still printing the response body. On error, **STOP** and show the user the body. Common cases:
  - `401` / `403`, or a body about "may not have access to this repository" — token missing or lacks a required scope (`read:repository` + `write:pullrequest`). Scopes are fixed at creation; recreate the token with the full set.
  - `400` — a PR for this source→destination already exists. Don't retry; instead `GET .../pullrequests?q=source.branch.name="<from_branch>"&state=OPEN` and show the user the existing PR.

### Step 6: Report

Parse the response JSON: print the PR's web URL (`.links.html.href`) and number (`.id`). Confirm the from → base branches and that the upstream is the same-name remote branch.

## Red Flags

**Never:**
- Push or create the PR before the user's explicit approval
- Push to, or set the upstream to, the **base branch** — only `origin/<from_branch>`
- Use a `HEAD:<base>` refspec or any refspec whose target isn't the from-branch's own name
- Force-push
- Open a PR from the default branch
- Create the PR with a different head/base than the approved `<from_branch>` → `<base_branch>`, or with a title/body other than the approved draft
- Reach for a GitHub tool (`gh`) — this is **Bitbucket Cloud**; the PR is created via its REST API (Step 5)
- Echo, log, or pass `BITBUCKET_API_TOKEN` as a command argument — read it only from the environment
- Edit code, commit, amend, rebase, or reset — this skill only pushes the existing branch and opens the PR
