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
7. **Verify** (manual + smoke test) - confirm behavior on the polished code
8. **Ship** - write the product summary + ADR (when warranted), then commit
9. **Push** (manual)

Steps 3-6 each run in a **fresh session**. Polish mutates code _before_ verification so verification is meaningful; ship makes no code changes and never pushes.

## Skills

### Workflow skills

#### `prepare`

Kicks off a ticket. Given a name like `FNA-1234-currency-filter`, it creates the working branch (off the repo's default branch, or a release branch via `--base`), the task directory, and a light `<task>-proposal.md` (ticket / title / description / technical notes) for the user to fill in.

- **Branch only** - creates and switches; does not fetch, pull, or commit
- Checks the name against the project's `<ticket-number>-<slug>` convention (advisory — warns, doesn't block); uses it for both the branch and the task prefix
- Hands off to the user: fill the proposal, then run `brainstorming` in a fresh session

#### `brainstorming`

Turns a proposal into an approved spec - a contract specifying **what + why** (goals, constraints, architecture).

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

- **Feature-level** (`<ticket-number>-<slug>.md`) - immutable session snapshot (summary / why / key decisions) with a **mandatory edge-cases section**; change by superseding; the default
- **System-wide** (`NNNN-<component>.md`) - living, system-shaping decisions, edited in place to stay current; on explicit request

**Sources:**

- Spec, plan, and result file from the workflow artifacts; the **actual code** for edge cases (read the guards); **git history** when writing retroactively
- Lifecycle: feature-level ADRs are immutable (supersede to change); system-wide ADRs are living (edit in place, log each decision change in a linked feature-level ADR). Writes the file but does not commit (the user commits)

#### `writing-result-product`

Writes the **product-facing summary** (`<task>-result-product.md`) - a plain-language companion to the result file for managers / PMs / stakeholders, with no file paths or code. Reads the spec (what + why) and the result file (what shipped, edge cases).

- **Opt-in** - on request, or offered for user-facing features; skipped for pure internal refactors
- Invoked from `ship`; moved out of `subagent-driven-development` to keep execution lighter

### Quality gates

#### `checklist-review`

Checklist-driven review of changes before PR. **160 checks across 11 parallel agents** (naming, clean code, defensive programming, architecture, data flow, state management, regressions, security, test quality, styling, forms). End-to-end data-flow tracing now lives in the separate `trace-dataflow` skill.

**Scoping:**

- Pick the diff to review (staged / unstaged / branch / path)
- Activate agents based on changed file types

**Checking:**

- Agents flag broadly in parallel - false positives are fine
- **Investigation phase** verifies each flag with full file context, classifies severity, and dismisses false positives

**Reporting:**

- Single merged report grouped by severity (Critical / High / Medium / Low)
- Verdict: Yes / No / With fixes
- **Persistence is opt-in** - saves to `<task>-checklist-review.md` with `--save`, on user request, or automatically on every later review once a report exists. Tracks Open / Fixed / Skipped / Wontfix across iterations

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

- **Format** first (runs `formatting`), then **select gates by risk**: a **pluggable primary reviewer** (CodeRabbit or built-in `/code-review`) always, plus `/security-review`, `trace-workflow`, `trace-dataflow`, or `checklist-review` when the change warrants them
- **Compare mode** (`--compare`) runs both reviewers and reports each one's unique catches — for evaluating which to standardize on
- **Auto-applies only meaningful fixes** - High-confidence + Critical/High + mechanical. Everything else (Medium/Low, uncertain, judgment-dependent) is surfaced, not changed. Bounded to 3 fix→recheck loops per gate
- Saves the **full report** (all severities) to `<task>-review.md` for rule-tuning; makes no commits

### Finishing

#### `ship`

The **finalize phase**, run _after_ manual verification + smoke test pass. Documents the verified change and commits it - **no code changes, never pushes**.

- Invokes `writing-result-product` (user-facing changes) and `writing-adr` (when warranted)
- Shows `git status` / `git diff`, proposes a commit message in the repo's style, then commits on your go-ahead
- **Never** adds a `Co-Authored-By:` footer, amends, rebases, or pushes - the push is always manual

## Artifacts

All artifacts live in `.claude/temp/<task>/` where `<task>` is `<ticket-number>-<slug>` (e.g., `FNA-1234-currency-filter`).

| Artifact            | File                                                                             | Created By                            | Description                                                                                                                                                                                                              |
| ------------------- | -------------------------------------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Proposal**        | `<task>-proposal.md`                                                             | `prepare` (template) + User (content) | Initial feature request, requirements, context. `prepare` scaffolds the template; the user fills it in                                                                                                                   |
| **Assets**          | `assets/`                                                                        | User                                  | Mockups, screenshots, diagrams, reference material (user creates the dir when needed)                                                                                                                                    |
| **Spec**            | `<task>-spec.md`                                                                 | `brainstorming`                       | Approved specification: goals, constraints, architecture, scope (what + why, not how)                                                                                                                                    |
| **Plan**            | `<task>-plan.md`                                                                 | `writing-plans`                       | Implementation plan: file structure, bite-sized tasks, code snippets, test commands                                                                                                                                      |
| **Result**          | `<task>-result.md`                                                               | `executing-plans`                     | Summary of implementation: files changed, decisions made, test results                                                                                                                                                   |
| **Review**          | `<task>-review.md` (`polish`), `<task>-checklist-review.md` (`checklist-review`) | `polish` / `checklist-review`         | `polish` saves the consolidated findings (all severities) to `<task>-review.md` for rule-tuning. `checklist-review` run standalone tracks item status (Open / Fixed / Skipped / Wontfix) in `<task>-checklist-review.md` |
| **Product Summary** | `<task>-result-product.md`                                                       | `writing-result-product`              | Product-facing summary for managers / stakeholders - what shipped and how it behaves, in plain language (no file paths or code). Opt-in - produced on request or offered for user-facing features (invoked from `ship`)  |

> **ADRs are the exception.** Unlike the temp artifacts above, an Architecture Decision Record (`writing-adr`) is **committed** and lives in `docs/adr/`, not `.claude/temp/`. It's a durable record of _why_, not a per-task working file.
