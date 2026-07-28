# Claude Code Skills & Configuration

> Built on top of [obra/superpowers](https://github.com/obra/superpowers), with additions tuned to our workflow (some ideas drawn from [ryanthedev/code-foundations](https://github.com/ryanthedev/code-foundations)). **Bolded items in skill descriptions mark additions on top of the base library.**

Custom skills and configuration for Claude Code, designed around a structured development workflow that takes features from idea to implementation through collaborative planning.

## Philosophy

Each skill operates at one level of abstraction and defends its boundary:

- **Brainstorm** - _what & why_: goals, constraints, architecture at a high level
- **Plan** - _structural how_: files, callers, reuse, where new code lands
- **Execute** - _coding how_: conventions, exact code, verification

A few principles fall out of this:

- **Value compounds upstream.** Pinning down _what & why_ early makes planning and execution cheap; most collaboration happens during brainstorming.
- **Skills hand off explicitly** rather than leaking concerns - "that belongs to planning" is a feature, not a deferral.
- **The user is the integrator.** Skills don't try to be end-to-end; the human carries intent across phases and catches reuse, scope, and architecture issues at the right level.

## Development Workflow

1. **Prepare** - create the branch, task directory, and an empty proposal template
2. **Proposal** (manual) - fill in the proposal; drop reference assets (mockups, screenshots, diagrams) into `assets/`
3. **Brainstorm** - turn the proposal into an approved spec
4. **Plan** - decompose the spec into a bite-sized implementation plan
5. **Execute** - implement the plan with a fresh subagent per task in isolated context (writes the result file)
6. **Polish** - format, build, run the relevant reviews, and auto-apply only meaningful fixes
7. **Verify** (manual + `smoke-test`) - confirm behavior on the polished code
8. **Ship** - write the product summary + ADR (when warranted), then commit
9. **Open PR** - `open-pr` pushes the branch and opens the PR, both behind your approval

Steps 3-6 each run in a **fresh session**. Polish mutates code _before_ verification so verification is meaningful; ship makes no code changes and never pushes - it hands off to `open-pr`, which owns the push.

**After ship**, `prepare uat <task>-<slug>` opens a follow-up round (its own branch + a `<task>-<slug>-uat.md` ledger) for UAT feedback, bugfixes, and change requests on shipped work; the items run back through Execute → Polish → Verify → Ship. **Off to the side**, `prepare discuss <task>-<slug>` captures a ticket conversation and a proposed answer (`<task>-<slug>-discussion.md`, no branch) for tickets that need thought, not code.

## Skills

### Workflow skills

#### `prepare`

Scaffolds what you're about to work on, in one of three modes. Explicit mode (`uat` / `discuss`) wins; with no mode it infers from the task-folder state and confirms before acting — never on a silent guess.

- **new task** (`prepare <task>-<slug>`, default) - creates the working branch (off the repo's default branch, or a release branch via `--base`), the task directory, and a light `<task>-<slug>-proposal.md` (ticket / title / description / technical notes) for the user to fill in. Hands off to `brainstorming`.
- **uat** (`prepare uat <task>-<slug>`) - opens a post-ship follow-up round on an existing task: a `<task>-<slug>-uat` branch off the integration base (the original branch is usually merged) and a `<task>-<slug>-uat.md` ledger for UAT feedback, bugfixes, and change requests. Hands off to execution (`executing-plans` / `subagent-driven-development` / `fast-track`).
- **discuss** (`prepare discuss <task>-<slug>`) - captures a ticket conversation and a proposed answer in `<task>-<slug>-discussion.md`. **No branch** - discussion-only tickets stay out of git.
- **Branch/files only** - creates and switches; does not fetch, pull, or commit. Checks the name against the naming convention (advisory — warns, doesn't block); the grammar (`<task>-<slug>[-<branch-type>]`) lives in `docs/CONTRIBUTING.md`, and the project's `CLAUDE.md` supplies the scope values.

#### `brainstorming`

Turns a proposal into an approved spec - a contract specifying **what + why** (goals, constraints, architecture, acceptance criteria).

**Understanding the proposal:**

- Read the proposal file and any reference assets (mockups, screenshots, diagrams)
- **Clarify intent** - confirm the problem statement; ask one focused question only if the proposal is unclear
- **Targeted codebase exploration** - understand how the area being touched currently works (not generic pattern hunting)
- **Classify task complexity (Simple / Medium / Complex)** - sets ceremony level
- Assess scope - flag and decompose if multiple subsystems
- Ask clarifying questions one at a time to fill any remaining gaps

**Exploring approaches:**

- Research best practices when relevant (Medium / Complex)
- Propose 2-3 approaches with trade-offs; lead with the recommended one
- **Each approach states its scope and hardest part**
- **Convention wins** - codebase consistency over "best practice" unless there's a concrete defect

**Presenting the design:**

- Present in sections, get approval after each
- Cover architecture, data flow, error handling, testing approach
- **Acceptance criteria** - numbered `AC-1`, `AC-2`, … each **observable and falsifiable**, stating what must be true, never _how_ it gets verified. Choosing the mechanism is a downstream decision: `writing-plans` maps the unit-testable ones to test steps, `smoke-test` turns the UI-observable ones into browser scenarios, and **both must account for every AC** - covered or explicitly declined with a reason, so one that falls between them surfaces at manual verify instead of vanishing

**Final review (before handoff):**

- **Size-aware digest** - skim-able sectioned summary grouped by natural seams (1-5 sections depending on spec size)
- Five-option menu: walk by section / show full digest / approve / save / discuss
- Approve hands off to `writing-plans` (fresh session recommended for clean context)

#### `writing-plans`

Translates a spec into an implementation plan - the **how** for the spec's _what + why_. Bite-sized steps with exact file paths, complete code, and verification commands. Best invoked in a **fresh session** so the spec + proposal + assets are the only inputs.

**Understanding the spec:**

- Read the spec + proposal first
- Split into separate plans if the spec covers multiple independent subsystems

**Designing the file structure:**

- Map which files to create or modify; each file has one clear responsibility
- **Trace callers** - when changing a function's signature or behavior, grep for every caller (direct and indirect) and add them to the file list

**Surfacing decisions (before writing tasks):**

- **Reuse check** - before planning new code, grep for existing similar functionality; ask before creating new
- **Spec gaps** - surface structural ambiguities the plan would otherwise resolve by guessing
- **Scope concerns** - flag phases that look bigger than the spec implies; ask split/defer/keep
- 1-3 highest-leverage items max via AskUserQuestion; skip if nothing material is flagged

**Writing the tasks:**

- Each step is bite-sized (2-5 min) with exact file paths, complete code, and verification commands
- **Comprehensive test coverage** - every scenario in the spec's Testing Approach maps to a concrete plan step
- **AC traceability** - reads the spec's acceptance criteria and splits them: unit-testable AC get a plan step citing `covers AC-n`; the rest are listed as declined with a reason (never dropped silently). Every AC lands in exactly one list

**Final review (before execution):**

- Same size-aware digest pattern as brainstorm - sectioned summary grouped by natural seams
- Five-option menu: walk by section / show full digest / approve / save / discuss
- **Approve routes** to `subagent-driven-development` (the default for now) - no second menu, with a `switch to inline` override to `executing-plans`

#### `executing-plans`

Implements the plan task-by-task. Each task is implemented by a fresh subagent in isolated context, then reviewed in two stages, with a user checkpoint before the next task.

**Setup:**

- Read plan + spec, extract all tasks, create task tracking

**Task loop (per task):**

- Dispatch an implementer subagent with the task's full text and the context it needs (never your session history)
- **Spec compliance review** subagent runs first - implementer fixes any issues, re-review until clean
- **Code quality review** subagent runs second - same loop
- **User checkpoint** - report files changed, review status, and any concerns; wait for "continue" before the next task
- Bridge dependencies between tasks - summarize what prior subagents built

**Wrapping up:**

- Write a result summary with files changed, review history, and test results

#### `writing-adr`

Captures an **Architecture Decision Record** - a committed snapshot under `docs/adr/` of _why_ complex code is the way it is, plus the edge cases and non-obvious constraints that aren't recoverable from the code. Code is the primary source for _what_; ADRs are the durable secondary source for _why_.

**Gating:**

- **Never auto-written** - opt-in judgment call. Record only when the change is costly to reverse, the reasoning isn't obvious from code, and genuine alternatives existed
- Invoked from `ship` (after verification) when a change warrants one. Execution records the inputs (decisions / concerns / non-obvious constraints) in the result file; `ship` decides whether to capture the ADR

**Two types:**

- **Feature-level** (`<task>-<slug>.md`) - immutable session snapshot (summary / why / key decisions) with a **mandatory edge-cases section**; change by superseding; the default
- **System-wide** (`NNNN-<component>.md`) - living, system-shaping decisions, edited in place to stay current; on explicit request

**Sources:**

- Spec, plan, and result file from the workflow artifacts; the **actual code** for edge cases (read the guards); **git history** when writing retroactively
- Lifecycle: feature-level ADRs are immutable (supersede to change); system-wide ADRs are living (edit in place, log each decision change in a linked feature-level ADR). Writes the file but does not commit (the user commits)

#### `writing-result-product`

Writes the **product-facing summary** (`<task>-<slug>-result-product.md`) - a plain-language companion to the result file for managers / PMs / stakeholders, with no file paths or code. Reads the spec (what + why) and the result file (what shipped, edge cases).

- **Opt-in** - on request, or offered for user-facing features; skipped for pure internal refactors
- Invoked from `ship`; moved out of `subagent-driven-development` to keep execution lighter

### Quality gates

#### `checklist-review`

Checklist-driven review of changes before PR. **207 checks across 14 parallel agents** (naming, clean code, defensive programming, architecture, data flow, state management, regressions, security, test quality, styling, forms, performance, migration safety, standards drift). End-to-end data-flow tracing now lives in the separate `trace-dataflow` skill.

**Scoping:**

- Pick the diff to review (staged / unstaged / branch / path)
- Activate agents based on changed file types

**Checking:**

- Agents flag broadly in parallel - false positives are fine
- **Investigation phase** verifies each flag with full file context, classifies severity, and dismisses false positives

**Reporting:**

- Single merged report grouped by severity (Critical / High / Medium / Low)
- Verdict: Yes / No / With fixes
- **Persistence is opt-in** - saves to `<task>-<slug>-checklist-review.md` with `--save`, on user request, or automatically on every later review once a report exists. Tracks Open / Fixed / Skipped / Wontfix across iterations

Reports findings - does not auto-fix.

#### `trace-workflow` & `trace-dataflow`

Two focused, report-only correctness reviews that complement `checklist-review` (and each other). Both are narrower and faster than the full checklist run — reach for them when logic or cross-layer wiring is the risk.

- **`trace-workflow` — branch-level.** Verifies decision-point correctness _within and across functions_: asymmetric sibling branches, missing cases (no `else` / no `default` / unhandled enum), nullish gaps, dead branches, and cross-function mismatches. **Use when** a change adds or modifies conditional logic. Reports Critical/High only.
- **`trace-dataflow` — flow-level.** Traces data, interaction, and error flows _end-to-end across layers_ (service → effect/updater → state → selector → container → template): data-shape mismatches between steps, unhandled error/loading states, race conditions, missing cleanup, inconsistent error handling across paths. **Use when** a change crosses layers — service/store + component, effects/reducers/selectors, or HTTP calls.

Rule of thumb: _logic changed_ → `trace-workflow`; _wiring crossed layers_ → `trace-dataflow`; both can apply to the same change.

#### `formatting`

Applies Prettier and code organization to locally modified files.

**Organizing TypeScript:**

- Group and sort imports (Angular core → modules → NgRx → external → internal → relative)
- Reorder class members per Angular's lifecycle convention
- Add curly braces to single-line blocks; enforce consistent-return

**Formatting:**

- Run Prettier on all changed `.ts`, `.html`, `.scss` files

#### `polish`

The **pre-verification quality pass** - the one phase that mutates code after execution. Runs after execution and _before_ manual verification, so verification happens on clean, gated code.

- **Format** first (runs `formatting`), then **select gates by risk**: a **pluggable primary reviewer** (CodeRabbit or built-in `/code-review`) always, plus `/security-review`, `trace-workflow`, `trace-dataflow`, `checklist-review`, or `/simplify` (surface-only) when the change warrants them
- **Effort-tuned primary review** - when the built-in reviewer runs, its effort level (`low` → `max`) is **judged from the diff**, not from file count alone: mechanical diffs get `low`, cross-layer or security-sensitive work `high`, migrations / auth / money math `xhigh`-`max`. A higher level only costs time and tokens — it never widens what polish auto-applies — so unsure means go up a level. The level and its reason land in the ledger
- **Compare mode** (`--compare`) runs both reviewers and reports each one's unique catches — for evaluating which to standardize on; pins the built-in to `medium` so the comparison is apples-to-apples
- **Auto-applies only meaningful fixes** - High-confidence + Critical/High + mechanical. Everything else (Medium/Low, uncertain, judgment-dependent) is surfaced, not changed. Bounded to 3 fix→recheck loops per gate
- Saves the **full report** (all severities) to `<task>-<slug>-review.md` for rule-tuning; makes no commits

### Verification

Browser verification is **layered**: `test-browser` owns the mechanics, `smoke-test` owns scenarios and the verdict. The split keeps driving knowledge in exactly one place.

#### `test-browser`

The **browser-driving primitive** - operates a running web app and observes it: navigate, read the accessibility tree, click/fill/select, capture screenshots + console. **Carries no scenarios, no verdict, and no git/diff knowledge** - those belong to its callers.

- **Driver is the Playwright CLI** (`playwright-cli`) via Bash, no MCP - so it works from any subagent context; `snapshot` returns the accessibility tree as `@e1`-style refs to pass to `click`/`fill`
- **Context-driven, not app-coded** - everything app-specific (base URL, credentials, login form, app-map) is read from the project's **`.test-browser/` dir**, so the same skill serves any web app
- **Persistent authenticated session** - holds one named session and reuses it across runs, re-logging in only when it expires; credentials come from a git-ignored env file
- **Theme-proof selectors** - ARIA role + accessible name first, then `data-testid`, then semantic classes, structural CSS last; framework-generated attributes (`_ngcontent-*`, `mat-*-N`, `cdk-overlay-*`) are avoided because they churn

#### `smoke-test`

The **scenario-verification layer** for the Verify phase — judges a set of scenarios (steps + expected results) against a running app and emits a machine-readable verdict. **Drives the browser via `test-browser`**; owns only _what to test_ and _what the result means_. **Verify-and-report only** — never fixes code or ships.

- **App-map driven** - reads a per-app "user's mental model" (routes, chrome, selector patterns, terminology) to drive the app like a user and **infer** new/variant UI from patterns; a stable baseline with per-run **live fallback** for in-flux screens
- **Scenarios from a diff** - can propose them via the app-map's file→route table, so a change suggests its own coverage
- **Scenarios derived from the spec's AC** - the primary source is the acceptance criteria, not the diff: each scenario cites the AC it `covers`, and any AC it **declines** is listed with a reason (so an AC that neither the plan nor the smoke run covers stays visible). Diff-mapping via the app-map's file→route table is the fallback for ad-hoc runs with no spec
- **Verdict** - `pass` / `fail` / `blocked` rolled up over per-scenario ✅/❌/⚠️/⏭️, with screenshots + console capture on failure. **Two files only** - the scenario file annotated in place with actuals (that _is_ the human-readable record) plus a machine-readable `.json`. **Halts on non-`pass`**
- **Augments the manual verify checkpoint** - gathers evidence and a verdict; the human still gives final sign-off. Scenarios + verdict live in the task dir (or `.test-browser/.temp/` for ad-hoc runs). Runs the same invoked by hand or driven by an external orchestrator

### Finishing

#### `ship`

The **finalize phase**, run _after_ manual verification + smoke test pass. Documents the verified change and commits it - **no code changes, never pushes itself**.

- Invokes `writing-result-product` (user-facing changes) and `writing-adr` (when warranted)
- Shows `git status` / `git diff`, proposes a commit message in the repo's style, then commits on your go-ahead
- **Hands off to `open-pr`** - after committing it asks whether to open a PR for the branch (offered only on a non-default branch with an `origin` remote); declining leaves the branch local and unpushed
- **Never** adds a `Co-Authored-By:` footer, amends, rebases, or pushes - pushing belongs to `open-pr`, behind its own approval

#### `open-pr`

Opens a pull request from the current branch. Drafts the PR, shows a **preview** (`from → base`, title, description), and waits for your **approval** before anything touches the remote - then pushes the branch and creates the PR via the **Bitbucket Cloud REST API** (`gh` has no Bitbucket equivalent).

- **Preview-then-approve** - nothing is pushed or opened until you reply "approved" / "proceed"; that approval is the explicit, in-the-moment push authorization
- **Safe-push guard** - only ever pushes the current branch to a **same-name** remote branch (`git push -u origin HEAD`) and verifies the upstream afterwards; never pushes to, or tracks, the base branch (guards against the past "branch tracked the base, push landed on it" mistake)
- **Derives** workspace + repo slug from `origin`; base branch defaults to the repo default (override with `--base`); title/body drafted from the branch's commits and any task artifacts
- **Auth via env** - reads `BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN` (Basic auth uses the email, not the username); the token must belong to the identity with repo access. Never edits code, commits, amends, or force-pushes

### Session mechanics

#### `herdr`

Spawns and drives **fresh Claude sessions in their own [Herdr](https://herdr.dev) tabs** - so surfacing a subtask and _starting_ it are one step instead of "now go open a tab by hand". Since the workflow runs each phase in a fresh session, this is the primitive that makes that automatable. **Carries no project knowledge**: which trees are off-limits, which command to run, and where to record the spawn are all caller-supplied policy.

- **Fresh tab = fresh session = clean context** per unit of work; `./herdr-spawn.sh` wraps the one reliable recipe (`--cwd`, `--label`, `--prompt '/<skill>'`, `--no-focus`) and enforces the caller's guardrails
- **Watch, read, close** - `herdr agent wait <pane>` settles on `idle`/`done`/`blocked` (**omit `--until`** - a finished turn reports `done`, so pinning `idle` times out), then `herdr pane read` picks up the worker's RESULT block; `blocked` means it's asking a human, not finished
- **Phase boundaries via `/clear`** - a long-lived session can be driven through phases by prompting `/clear` between them; the new `agent_session.value` is the only reliable confirmation the clear landed, and the `agent_prompt_stalled` error it returns is a false failure for client-side slash commands
- **Requires running inside a Herdr pane** (`HERDR_ENV=1`) - otherwise it stops and says so rather than guessing

## Artifacts

All artifacts live in `.claude/temp/<task>-<slug>/` and are named `<task>-<slug>-<file-type>.md`, where:

- **`<task>`** is the Jira ticket number (e.g. `FNA-1234`),
- **`<slug>`** is `<scope>-<subject>` — 2–3 lowercase dash-separated words (e.g. `timeline-hover`); the scope vocabulary is project-defined,

so a full path looks like `.claude/temp/FNA-1234-timeline-hover/FNA-1234-timeline-hover-spec.md`. Branches follow the same stem: `<task>-<slug>` (follow-up rounds add a branch-type: `<task>-<slug>-uat`). **`docs/CONTRIBUTING.md`** is the authoritative source for the branch, commit, and PR conventions; the artifact/directory naming above is the workflow's own.

| Artifact            | File                                                                             | Created By                            | Description                                                                                                                                                                                                              |
| ------------------- | -------------------------------------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Proposal**        | `<task>-<slug>-proposal.md`                                                             | `prepare` (template) + User (content) | Initial feature request, requirements, context. `prepare` scaffolds the template; the user fills it in                                                                                                                   |
| **Assets**          | `assets/`                                                                        | User                                  | Mockups, screenshots, diagrams, reference material (user creates the dir when needed)                                                                                                                                    |
| **Spec**            | `<task>-<slug>-spec.md`                                                                 | `brainstorming`                       | Approved specification: goals, constraints, architecture, scope (what + why, not how). Carries the numbered **Acceptance Criteria** (`AC-1`, `AC-2`, …) that `writing-plans` and `smoke-test` read                        |
| **Plan**            | `<task>-<slug>-plan.md`                                                                 | `writing-plans`                       | Implementation plan: file structure, bite-sized tasks, code snippets, test commands. Cites the AC each test step proves, and lists the AC it declines with reasons                                                        |
| **Result**          | `<task>-<slug>-result.md`                                                               | `executing-plans`                     | Summary of implementation: files changed, decisions made, test results                                                                                                                                                   |
| **Smoke scenarios** | `<task>-<slug>-smoke.md` + `<task>-<slug>-smoke-result.json`                             | `smoke-test`                          | Browser scenarios derived from the spec's AC (each citing `covers: AC-n`, declined AC listed with reasons), annotated in place with per-scenario ✅/❌/⚠️/⏭️ + actual, plus the machine-readable verdict an orchestrator reads |
| **Review**          | `<task>-<slug>-review.md` (`polish`), `<task>-<slug>-checklist-review.md` (`checklist-review`) | `polish` / `checklist-review`         | `polish` saves the consolidated findings (all severities) to `<task>-<slug>-review.md` for rule-tuning. `checklist-review` run standalone tracks item status (Open / Fixed / Skipped / Wontfix) in `<task>-<slug>-checklist-review.md` |
| **Product Summary** | `<task>-<slug>-result-product.md`                                                       | `writing-result-product`              | Product-facing summary for managers / stakeholders - what shipped and how it behaves, in plain language (no file paths or code). Opt-in - produced on request or offered for user-facing features (invoked from `ship`)  |
| **UAT / Follow-ups** | `<task>-<slug>-uat.md`                                                                 | `prepare uat` (template) + User        | Post-ship work ledger: UAT feedback, bugfixes, and change requests on shipped code. Each item tagged `uat` / `bug` / `change` with a status (`open` → `in-progress` → `done` · `wontfix`) and the fixing commit                |
| **Discussion**      | `<task>-<slug>-discussion.md`                                                            | `prepare discuss` (template) + User    | Optional conversation + proposed answer for a ticket that needs thought, not (yet) code. 1–2 topics per file; no branch                                                                                                  |

> **ADRs are the exception.** Unlike the temp artifacts above, an Architecture Decision Record (`writing-adr`) is **committed** and lives in `docs/adr/`, not `.claude/temp/`. It's a durable record of _why_, not a per-task working file.
