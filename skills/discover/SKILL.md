---
name: discover
description: Establish how the application behaves TODAY in the area a proposal touches — observed in the running app and Storybook, and (full mode, the default) confirmed against code, unit tests, ADRs, git history, past task artifacts and related repos — and write the facts, each with evidence and a strength level, to `<task>-<slug>-discovery.md` so `brainstorming` decides from facts instead of assumptions. Facts only — never decisions, approaches or acceptance criteria. Read-only everywhere. Use after the proposal and before brainstorming; `--fast` limits it to the app + Storybook for simple tasks.
effort: high
---

# Discover

The **current-state** phase. It answers one question — *what does the app do today, and is that
intended?* — so the spec is built on facts, not on assumptions about existing behaviour.

**Announce at start:** "I'm using the discover skill."

Where it sits:

```
prepare → proposal → discover → brainstorming → writing-plans → …
```

Each workflow skill answers a different question, and this one stops at its own:

- **discover** — what *is*: current behaviour, with evidence
- **brainstorming** — what *should be* and why: goals, constraints, architecture, AC
- **writing-plans** — *where and how* to change the code, file by file

## Boundary (defend it)

- **Facts, never decisions.** "The daily view hides the tick row" is a fact. "So the daily view is
  out of scope" is a decision — it belongs to `brainstorming`. No approaches, no scope calls, no
  acceptance criteria, no file-level change lists, no recommendations. A sentence containing
  *should* does not belong in the discovery file.
- **Read-only everywhere.** No code edits, no app or dashboard configuration changes (not even on
  an editable dashboard — a shared environment is someone else's test bed), no git writes, and no
  branch switches in any repo, including related ones.
- **Never blocks, never asks mid-run.** A missing or unfit target, a failed login, a feature behind
  a profile — each becomes a *Not checked* item with its reason, and a *Targets needed* entry when
  a better target would settle it. The caller (or the user, at the next pause) supplies the target
  and re-runs.
- **No evidence, no fact.** Anything without a screenshot, story, code reference, test name or
  commit behind it goes under *Not checked*, never under *Facts*. A browser run proves a symptom,
  not a cause — the cause comes from code (full mode) or stays unknown.

## Modes

| Mode | Sources | Use for |
|------|---------|---------|
| **full** (default) | running app + Storybook, then code, unit tests, ADRs, git lineage, past task artifacts, related repos | anything that isn't obviously simple |
| **`--fast`** | running app + Storybook only; code is read just enough to find the right screen or story | simple tasks — the user (or the orchestrator, on the user's say-so) picks it per task |

In `--fast`, almost every fact is single-source — that's expected, not a defect.

## Inputs

- **The proposal** — `<task>-<slug>-proposal.md`, plus `assets/` and any `*-prd-analysis.md` /
  attachment analysis in the task dir.
- **Verification targets** — the proposal's *Verification targets* section: app URLs/routes,
  Storybook stories, environments, each with what it's for.
- **App context** — the project's `.test-browser/` dir (base URL, app-map, credentials), resolved by
  `test-browser`. The app-map may also list default test targets and the Storybook command/port.
- **Related repos** (full mode) — named in the project's `CLAUDE.md` / `CLAUDE.local.md` (e.g. a
  backend repo and its local clone path). No clone → the repo is *Not checked*; never infer the
  server's behaviour from the frontend alone.

## The Process

### 1 — Frame the checks
Read the proposal and list the **checks**: the behaviours the change touches or assumes ("what
happens today when…", "which views show…", "how do neighbouring controls look…"). Include the
edge states the proposal's area has — empty, error, loading, boundary values, filters, timezones.

**Quick exit:** if the change has no observable surface and nothing worth confirming (a pure
config bump, a copy fix), write a three-line file with verdict `trivial` and stop.

### 2 — Resolve targets
For each check, find where it can be observed, in order:

1. the proposal's *Verification targets*;
2. links in the proposal / ticket text;
3. default test targets from `.test-browser/` (app-map);
4. navigation via the app-map (routes, widget catalog) to a page that shows the thing;
5. a Storybook story for the component — often the only way to see empty / error / extreme states.

**Check the target fits** before trusting it — the page actually shows the widget, mode or state
the check is about. A dashboard with only a sorted list does not fit a time-series check: record
the mismatch, try the next source, and if nothing fits, add a precise **Targets needed** entry
("a dashboard with a Time Series widget, editable, beta profile on").

Note the **environment version**: if the app's server runs a different branch than the task
targets (e.g. a release-branch ticket observed on an integration server), say so on every fact
it affects.

### 3 — Observe
Dispatch a **behaviour-checker** subagent (see `behaviour-checker-prompt.md` in this skill directory —
general-purpose, `model: sonnet`, `effort: medium` on the call) with the checks and the fitting
targets — one subagent per independent group of checks, in parallel when they don't share a
session. It returns per check:
`confirmed | refuted | not checked`, the observed behaviour, and evidence paths
(`assets/discovery/*.png`).

**Storybook:** when a story fits, serve it with the command/port from the app-map (or the project's
Storybook target), point the checker at the story URL, and stop the serve when done. Storybook needs
no backend and no login, so it doesn't compete with an app serve.

### 4 — Confirm (full mode only)
For each observed behaviour — and each check the browser couldn't reach — consult the sources that
can confirm it or explain it:

- **Code** — the branch or template that produces the behaviour; the modes and branches the browser
  couldn't reach; the other screens and features that read the same value.
- **Unit tests** — a test name or assertion that records the intended behaviour or a known edge case.
- **ADRs** — a documented constraint on this area (state it as a fact; `brainstorming` weighs it).
- **Git lineage** — the ticket that introduced the behaviour (`git log --follow` / `-L`), which
  answers *by design or accident?*
- **Past task artifacts** — earlier specs, decisions and UAT ledgers for the same area in
  `.claude/temp/` — a prior agreed decision is a fact the new spec must not silently override.
- **Related repos** — the server side of a contract, read on whatever branch the clone is on (say
  which).

### 5 — Grade each fact
- **confirmed** — two independent sources agree (e.g. observed + code, or story + test).
- **single source** — one source; the evidence line says which (app, Storybook, code, test, ADR, git).
- **conflict** — sources disagree (the app shows X, the code says Y). Usually data/config dependence
  or a bug. Conflicts are the most valuable finding — they go at the top of the file.

### 6 — Write the file and report
Write `<task>-<slug>-discovery.md` in the task dir (template below), then print a short summary:
verdict, fact counts by strength, conflicts, targets needed. End with exactly:

> Discovery saved to `<abs path>`.

**Re-runs:** if the file exists, keep its facts, re-check only the *Not checked* items (plus any new
targets in the proposal), and update the stamp.

## Discovery file template

```markdown
# <task> — discovery

Mode: full | fast · Verdict: normal | trivial
Sources: code @ <branch> <short-sha> · app: <env> (<version/branch>) <routes> · stories: <ids | none> · related: <repo @ branch | none>
Date: <YYYY-MM-DD>

## Targets
- Used: <target> — <what it showed>
- Needed: <precise requirement> — <which checks it would settle>

## Conflicts
- F-n — <app shows X; code/test says Y> — <evidence both sides>

## Summary
<3 lines: what exists today, the biggest surprise.>

## Facts
- **F-1** (confirmed) — <one statement of current behaviour>. Evidence: <screenshot path / story id / code ref / test name / commit>
- **F-2** (single source · app) — …

## Affected surfaces
<Other screens, modes and features that show or read what the proposal changes — each with evidence.>

## Nearby patterns
<How similar controls look and behave today — placement, iconography, wording.>

## Edge states today
<Empty · error · loading · boundary · filters · timezone — what happens now, per state checked.>

## Proposal vs reality
<Where the proposal's premise doesn't match the app — one line each, citing F-n.>

## Not checked
- <check> — <why: no fitting target / login failed / beta profile / no clone / …>

## Open questions
- **Q-1** — <an intent question only the user or product can answer> — <what it changes>
```

Keep it to about a page. `Conflicts` and `Targets` stay even when empty (`none`) so a reader sees
they were considered.

## Rules

- **Facts only** — no *should*, no approaches, no scope calls, no AC. Those are `brainstorming`'s.
- **Read-only** — code, app configuration, git, related repos.
- **Every fact has evidence and a strength level**; no evidence → *Not checked*.
- **Questions are intent-only** — a behaviour question is a check, not a question for the user.
- **Never ask mid-run** — gaps become *Not checked* / *Targets needed*.
- **Driving belongs to `test-browser`** (via the behaviour-checker subagent) — don't re-implement
  navigation, auth or selectors here.
- **No git operations** — write the discovery file and screenshots only.
