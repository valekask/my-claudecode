---
name: smoke-test
description: Browser smoke test for any web app. Drives a real browser (Playwright CLI via Bash) through testing scenarios against a running app, reusing a persistent authenticated session to minimise logins, compares expected vs actual, captures screenshots + console on failure, and emits a machine-readable pass/fail/blocked verdict. Verify-and-report ONLY — never fixes code, never ships, never updates trackers. App-specific context (base URL, credentials, login selectors, app-map, output dir) is supplied by the invoker at run time; the skill itself carries no app knowledge. Use at a verify gate or standalone.
---

# Smoke-test

A general, **invocation-agnostic** browser smoke test: it runs identically whether
you invoke it by hand or an orchestrator dispatches it autonomously — file-driven
inputs, autonomous-until-unsure, structured verdict out. **It carries no
app-specific knowledge.** Everything about the target app (URL, credentials, login
form, UI map, where to write results) is **supplied by the invoker** (see *Inputs*).

**Announce at start:** "I'm using the smoke-test skill."

## Boundary (defend it)

- **Verify + report only.** Run the scenarios, judge expected vs actual, save
  evidence, emit a verdict. **Never fix code, never ship, never push.** A `fail`
  is reported — the fix loop is orchestrated *outside* this skill.
- **Tracker-ignorant.** Write results into the **output dir the invoker gives**;
  never edit the caller's boards/trackers. The verdict `.json` is the **seam** an
  orchestrator reads to decide advance/halt.
- **Augments the human gate, doesn't replace it.** A `pass` gathers evidence; it
  does not auto-approve or auto-advance.

## Driver

Browser automation is the **Playwright CLI** (`@playwright/cli`, the
`playwright-cli` binary) — via Bash, no MCP. Works in any subagent context. Key
commands: `open/goto/click/fill/type`, `snapshot` (accessibility tree → element
refs), `console`, `requests`, `screenshot`, `-s=<session>` (persistent named
sessions), `--json`/`--raw` (machine output).

**Selector preference:** ARIA **role + accessible name** first
(`role=textbox[name="…"]`) — theme-proof and stable. Then `data-testid` if the app
has them; then developer-authored semantic classes; structural CSS last. Avoid any
framework-generated attributes / auto-ids (they churn).

## Inputs — supplied by the invoker (nothing app-specific is hard-coded)

The invoker (an orchestrator, or you by hand) provides these via env / args /
file paths. Keep secrets + app config in a **git-ignored env file** and source it
before running.

| Input | How supplied | Notes |
|-------|--------------|-------|
| **Base URL** | `SMOKE_BASE_URL` (or `auth.sh` arg 2) | app root that triggers the auth redirect — a localhost build or a deployed env |
| **Credentials** | `SMOKE_USERNAME` / `SMOKE_PASSWORD` (env) | git-ignored; only needed if a login form appears |
| **Login selectors** | `SMOKE_LOGIN_USER` / `SMOKE_LOGIN_PASS` / `SMOKE_LOGIN_SUBMIT` (env) | optional; default to stock Keycloak (`#username` / `#password` / `#kc-login`) — override per app/IdP |
| **App-map** | a path the invoker points to | per-app "user's mental model" (routes, chrome, selector patterns, terminology). Optional but recommended |
| **Scenarios** | a path the invoker points to | steps + expected results |
| **Output dir** | a path the invoker points to | where results + evidence land |

> **Example wiring** (one caller — a management cockpit): app config + creds in a
> `…/.claude/smoke/.env.local`, app-map in `…/.claude/smoke/<app>/app-map.md`,
> outputs into a per-task folder. Those paths/names are the **caller's** convention,
> not the skill's.

## The Process

### 0 — App-map (preflight)
- Read the **app-map** the invoker points to. If none exists, run a **cold
  preflight**: crawl the seed routes, `snapshot` each, distil routes + role/name
  selectors + a per-page load landmark into an app-map.
- The app-map is a **read-mostly baseline of the stable UI** — don't auto-write it
  from a feature branch (see *App-map rules*).

### 1 — Auth (reuse-or-login)
Source the invoker's env file, then run the guard:
```sh
set -a && . <env-file> && set +a
scripts/auth.sh smoke "$SMOKE_BASE_URL"   # prints REUSED | LOGGED_IN | FAILED
```
- `REUSED` / `LOGGED_IN` → proceed. `FAILED` → verdict `blocked`.
- One persistent session is kept alive so the app reuses/refreshes its own token,
  minimising interactive logins. **Don't `close-all` between runs.**
- **Why a persistent session, not token injection / `storageState` reuse:** *if*
  the app authenticates via OIDC authorization-code + PKCE with id_token **nonce**
  validation (common), a restored profile or injected bearer fails on bootstrap
  (`wrong state/nonce`) — a live session is the reliable reuse path. (A bearer may
  still work for direct *API* testing, just not for driving the browser UI.)

### 2 — Run scenarios
For each scenario, in the same session:
- Navigate (app-map route + base URL); wait for the page's load landmark.
- Perform the steps via the preferred selectors. On a **miss** (element absent, or
  a mapped selector won't resolve) resolve it **live for this run only** — note it,
  do **not** write it to the app-map.
- Capture the actual result; compare to expected. Mark ✅ / ❌ / ⚠️ / ⏭️.
- **Evidence:** screenshot on every ❌ and ⚠️; one final-state shot on ✅; dump
  `console` on every ❌.

### 3 — Verdict + evidence
- **Per-scenario:** ✅ pass · ❌ fail · ⚠️ known (documented deviation) · ⏭️ skipped.
- **Overall (roll-up):**
  - `fail` — any unresolved ❌ (test ran, change is wrong)
  - `blocked` — couldn't complete (auth FAILED, app won't serve, page errors before the scenario, browser crash)
  - `pass` — all ✅ (plus any ⚠️ / ⏭️)
- Write the outputs. **Halt on non-`pass`** — report and stop; never advance or ship.

## App-map rules

- **Baseline only.** Reflects the stable UI. The sole writer is a deliberate manual
  refresh (`--preflight`), typically after a feature merges to the default branch.
- **On-miss = live fallback, never persisted.** Resolve for this run, report it as
  a "live fallback". Accumulated fallbacks are a changelog for the next refresh.
- **Branch-aware staleness signal:** on a **feature branch** a miss is *expected*
  (quiet fallback); on the **default branch** a miss means the baseline is stale →
  surface "app-map looks out of date".

## Outputs (into the invoker's output dir)

| File | Content |
|------|---------|
| `<name>-smoke.md` | scenarios + expected (input), with per-scenario ✅/❌/⚠️/⏭️ + actual filled in per cycle |
| `<name>-smoke-result.md` | human report: per-scenario expected/actual, evidence links, overall verdict |
| `<name>-smoke-result.json` | **machine record** the orchestrator parses (shape below) |
| `assets/smoke/*.png`, `*.log` | screenshots + console dumps, referenced by path |

Verdict `.json` shape:
```json
{
  "id": "<scenario-set id>",
  "verdict": "pass|fail|blocked",
  "auth": "REUSED|LOGGED_IN",
  "base_url": "…",
  "counts": { "pass": 0, "fail": 0, "known": 0, "skipped": 0 },
  "scenarios": [
    { "id": "S1", "name": "…", "status": "pass|fail|known|skipped",
      "expected": "…", "actual": "…", "evidence": ["assets/smoke/S1.png"] }
  ],
  "live_fallbacks": [ "…elements resolved live, not in the app-map…" ],
  "started": "ISO-8601", "finished": "ISO-8601"
}
```

## Rules

- **Never** fix code, ship, push, or edit the caller's trackers/boards.
- **Never** print the password (pass via env var, suppress fill output).
- **Autonomous until unsure.** Run the whole scenario set without prompting; only
  stop to escalate on a genuine `fail`/`blocked` or a real ambiguity.
- **Don't `close-all`** the session between runs — that defeats the token reuse.
  Re-login happens only when the session is dead or the IdP session expired.
