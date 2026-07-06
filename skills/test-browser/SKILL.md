---
name: test-browser
description: Drive a real web app in a browser — open pages, read the accessibility tree, click/fill/select, capture screenshots + console, reusing a persistent authenticated session to minimise logins. The mechanical primitive for browser interaction; it carries no scenarios, no verdict, and no git/diff knowledge. App context (base URL, credentials, login selectors, app-map) comes from the project's `.test-browser/` dir. Reused by `smoke-test` (scenario verification) and `dogfood` (end-to-end QA). Use when you need to operate a running app in a browser, or as the driving layer another skill calls.
---

# Test-browser

The **browser-driving primitive**: it knows *how to operate a running web app* —
navigate, observe the DOM/accessibility tree, interact, capture evidence, and hold
one authenticated session so repeated runs don't re-login. It is **context-driven,
not app-coded**: everything specific to the target app (URL, credentials, login
form, UI map) lives in the project's **`.test-browser/` dir**, which this skill
discovers and reads.

It deliberately does **one** thing — drive and observe. It does **not** own test
scenarios, a pass/fail verdict, diff scoping, or any code changes. Those belong to
its callers: **`smoke-test`** (verify specific scenarios → verdict) and
**`dogfood`** (end-to-end QA + fixing). Both reuse this skill for the actual
browser work so the driving knowledge lives in exactly one place.

**Announce at start:** "I'm using the test-browser skill."

## Driver

Browser automation is the **Playwright CLI** (`@playwright/cli`, the
`playwright-cli` binary) — via Bash, no MCP. Works in any subagent context. Key
commands: `open/goto/click/fill/type`, `snapshot` (accessibility tree → element
refs like `@e1`), `console`, `requests`, `screenshot`, `-s=<session>` (persistent
named sessions), `--json`/`--raw` (machine output).

**Selector preference:** ARIA **role + accessible name** first
(`role=textbox[name="…"]`) — theme-proof and stable. Then `data-testid` if the app
has them; then developer-authored semantic classes; structural CSS last. Avoid any
framework-generated attributes / auto-ids (`_ngcontent-*`, `mat-*-N`,
`cdk-overlay-*`) — they churn. On a snapshot, elements come back as `@e1`, `@e2`
refs you pass to `click`/`fill`.

## Context — the project's `.test-browser/` dir

Everything app-specific is read from **`<project>/.test-browser/`**. This skill
carries none of it.

```
<project>/.test-browser/
├── README.md      # committed — purpose + "create .env.local with your creds"
├── app-map.md     # committed — the app's user-model: routes, chrome, selectors,
│                  #   terminology, file→route table, default base URL, login selectors
├── .env.local     # GIT-IGNORED — credentials only (+ optional base-URL override)
└── .temp/         # GIT-IGNORED — throwaway run artifacts (screenshots, console, session)
```

- **Committed (team-shared):** `README.md`, `app-map.md`. The app-map holds all
  **non-secret** config — including the **default base URL / origin**, the URL
  grammar, and the **login-form selectors** — so a teammate who clones the repo
  gets the whole "how to operate this app" model for free.
- **Git-ignored (per user):** `.env.local` (**credentials only**) and `.temp/`
  (outputs). The only local setup step is creating `.env.local` with your creds.
- **Ignore rules live in the project's root `.gitignore`** (`.test-browser/.env.local`,
  `.test-browser/.env.*.local`, `.test-browser/.temp/`) — not a nested `.gitignore`,
  so the ignore policy sits where the repo's other ignores are.

### Discovery (with a fallback chain)

Resolve the dir by walking **up from the current dir to the git top-level**, taking
the first `.test-browser/` found. Because a git **worktree** doesn't carry the
git-ignored `.env.local` from its main tree, also fall back for the **env file**
only, in order:

1. `<cwd-or-repo-root>/.test-browser/.env.local`
2. the **main working tree's** `.test-browser/.env.local`
   (`git -C <cwd> worktree list` → the first/main entry), then
3. a user-level `~/.config/test-browser/<app>/.env.local` (the `<app>` id comes from
   the app-map).

The committed `app-map.md` always travels with the checkout, so only the secrets
need the fallback.

### Missing or incomplete → scaffold or fail (don't guess)

- **No `.test-browser/` at all** → offer to **scaffold** it (see below); don't
  invent a base URL or crawl blindly against an unknown app.
- **Dir present but `.env.local` missing** (no creds resolvable via the chain) →
  **stop** and say exactly what's missing and where to put it. Never proceed to a
  login you can't complete.
- **`app-map.md` present** → use it as the baseline (below).

### Cold scaffold (first run in a project)

When asked to set up `.test-browser/` for a project:
1. Create the dir; add the **ignore rules to the project's root `.gitignore`**
   (`.test-browser/.env.local`, `.test-browser/.env.*.local`, `.test-browser/.temp/`)
   — not a nested `.gitignore`.
2. Write a `.env.local` **template** (credentials var names, no values) and tell
   the user to fill in credentials.
3. Ask for (or confirm) the **default base URL / origin**, the **URL grammar**,
   and the **app id** — these go in the committed `app-map.md`.
4. **Crawl the seed routes** and distil an initial `app-map.md` (routes +
   role/name selectors + a per-page load landmark + login selectors + a file→route
   table stub).
5. Write a short `README.md` (purpose, the one setup step, what's git-ignored).

## Auth (reuse-or-login)

The auth guard reads its inputs from the **environment**. Credentials come from
`.env.local`; the **base URL** and **login selectors** come from the committed
`app-map.md` — so before calling the guard, **export the app-map's values** (the
skill reads them from the map). Then:
```sh
set -a && . <resolved .env.local> && set +a          # TEST_BROWSER_USERNAME / _PASSWORD
export TEST_BROWSER_BASE_URL="<default-origin from app-map, or an override>/<route>"
export TEST_BROWSER_LOGIN_USER=… TEST_BROWSER_LOGIN_PASS=… TEST_BROWSER_LOGIN_SUBMIT=…  # from app-map
scripts/auth.sh <session> "$TEST_BROWSER_BASE_URL"   # prints REUSED | LOGGED_IN | FAILED
```
- `REUSED` / `LOGGED_IN` → proceed. `FAILED` → report **blocked** to the caller.
- One **persistent session** is kept alive so the app reuses/refreshes its own
  token, minimising interactive logins. **Don't `close-all` between runs.**
- Env the guard reads: `TEST_BROWSER_BASE_URL` (required; or pass as arg 2),
  `TEST_BROWSER_USERNAME` / `TEST_BROWSER_PASSWORD` (only if a login form appears;
  the **only** secrets, from `.env.local`), and `TEST_BROWSER_LOGIN_USER` /
  `_LOGIN_PASS` / `_LOGIN_SUBMIT` (login-form selectors, from the **app-map**;
  default to stock Keycloak if unset).
- **Base URL** = app entry origin **+ route** (not the SSO/auth URL). The app-map
  holds the **default origin** (the common case) + the route grammar; a per-user /
  per-run value overrides the origin via `TEST_BROWSER_BASE_URL` (e.g. localhost
  port vs a deployed env).
- **Why a persistent session, not token injection / `storageState` reuse:** if the
  app uses OIDC authorization-code + PKCE with id_token **nonce** validation
  (common), a restored profile or injected bearer fails on bootstrap
  (`wrong state/nonce`) — a live session is the reliable reuse path. `auth.sh`
  self-recovers a stranded `/login/callback` once before falling back to login.
- **Known quirk — retry once on a cold `FAILED`.** On a cold/stranded session the
  **first** `auth.sh` call can return `FAILED`: its one-shot recovery kicks a fresh
  OIDC flow but *returns before that flow settles*. A **single retry** then returns
  `REUSED`. So **don't treat the first `FAILED` as `blocked`** — retry once, and
  only report `blocked` if it fails again. (Root cause is being addressed on the
  auth-provider side; observed across sessions and manual browser use.)

## App-map — the baseline UI model

- Read the **`app-map.md`** the project supplies (see its own conventions). It's a
  **user's mental model** — routes, chrome, selector patterns, terminology — that
  lets you **infer** new/variant UI from patterns rather than re-crawling.
- **On a miss** (an element the map names won't resolve, or an unmapped screen):
  resolve it **live for this run only** via `snapshot` — note it as a "live
  fallback"; **do not silently rewrite the app-map.**
- **Branch-aware staleness:** on a **feature branch** a miss is *expected* (quiet
  fallback); on the **default branch** a persistent miss means the baseline is
  stale → surface "app-map looks out of date". The app-map's sole writer is a
  deliberate manual refresh (a re-crawl), typically after a feature merges.

## Interacting (the loop callers drive through you)

- **Navigate:** base URL + the app-map route; wait for the page's **load landmark**
  before asserting.
- **Observe:** `snapshot` for the interactive-element refs; `console` / `requests`
  when a caller needs error or network evidence.
- **Act:** click/fill/select by the preferred selectors; on a miss, resolve live.
- **Capture:** `screenshot` for evidence the caller will reference by path;
  `console` dump when something errors.
- **Human-pause for unautomatable steps.** For flows that *cannot* be driven
  headlessly — real OAuth consent, a payment provider, an emailed/SMS code — **stop
  and ask the human to complete that step**, then continue. Never fake or skip it
  silently. (Routine app login is handled by `auth.sh`; this is only for genuine
  third-party/out-of-band steps.)

## Boundary (defend it)

- **Drive and observe only.** No scenario list, no pass/fail roll-up, no diff
  analysis, no code edits, no commits, no tracker writes. A caller decides what to
  test and what the result means.
- **Never print the password** (pass via env; suppress fill output).
- **Don't `close-all`** the session between runs — that defeats token reuse.
- **Read-mostly on the app-map:** live fallbacks for the current run; the baseline
  changes only by a deliberate refresh.

## Outputs

This skill produces **evidence**, not verdicts: screenshots, console/request dumps,
and live-fallback notes, written into the **output dir the caller supplies**
(default for ad-hoc use: `<project>/.test-browser/.temp/`). The caller
(`smoke-test` / `dogfood`) composes these into a report + verdict.
