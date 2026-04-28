# Claude Code Skills & Configuration

> Built on top of [obra/superpowers](https://github.com/obra/superpowers), with additions tuned to our workflow (some ideas drawn from [ryanthedev/code-foundations](https://github.com/ryanthedev/code-foundations)). **Bolded items in skill descriptions mark additions on top of the base library.**

Custom skills and configuration for Claude Code, designed around a structured development workflow that takes features from idea to implementation through collaborative planning.

## Development Workflow

1. **Proposal** (manual) - create a proposal file with the task description. Drop reference assets (mockups, screenshots, diagrams) if any
2. **Brainstorm** - turn the proposal into an approved spec
3. **Plan** - decompose the spec into a bite-sized implementation plan
4. **Execute** - implement the plan with a fresh subagent per task in isolated context
5. **Review** - checklist-driven quality gate
6. **Format** - apply Prettier and code organization
7. **Create PR** (manual)

## Skills

### Workflow skills

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

#### `writing-plans`

Translates a spec into an implementation plan - the **how** for the spec's _what + why_. Bite-sized steps with exact file paths, complete code, and verification commands.

**Understanding the spec:**

- Read the spec + proposal first
- Split into separate plans if the spec covers multiple independent subsystems

**Designing the file structure:**

- Map which files to create or modify; each file has one clear responsibility
- **Trace callers** - when changing a function's signature or behavior, grep for every caller (direct and indirect) and add them to the file list

**Writing the tasks:**

- Each step is bite-sized (2-5 min) with exact file paths, complete code, and verification commands
- **Comprehensive test coverage** - every scenario in the spec's Testing Approach maps to a concrete plan step

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

### Quality gates

#### `review`

Checklist-driven review of changes before PR. **160 checks across 11 parallel agents** (naming, clean code, defensive programming, architecture, data flow, state management, regressions, security, test quality, styling, forms) plus end-to-end data flow tracing.

**Scoping:**

- Pick the diff to review (staged / unstaged / branch / path)
- Activate agents based on changed file types

**Checking:**

- Agents flag broadly in parallel - false positives are fine
- **Investigation phase** verifies each flag with full file context, classifies severity, and dismisses false positives

**Reporting:**

- Single merged report grouped by severity (Critical / High / Medium / Low)
- Verdict: Yes / No / With fixes
- **Persistence is opt-in** - saves to `<task>-review.md` with `--save`, on user request, or automatically on every later review once a report exists. Tracks Open / Fixed / Skipped / Wontfix across iterations

Reports findings - does not auto-fix.

#### `formatting`

Applies Prettier and code organization to locally modified files.

**Organizing TypeScript:**

- Group and sort imports (Angular core → modules → NgRx → external → internal → relative)
- Reorder class members per Angular's lifecycle convention
- Add curly braces to single-line blocks; enforce consistent-return

**Formatting:**

- Run Prettier on all changed `.ts`, `.html`, `.scss` files

## Artifacts

All artifacts live in `.claude/temp/<task>/` where `<task>` is a short descriptive name (e.g., `add-currency-filter`).

| Artifact     | File                 | Created By        | Description                                                                                                                                               |
| ------------ | -------------------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Proposal** | `<task>-proposal.md` | User              | Initial feature request, requirements, context                                                                                                            |
| **Assets**   | `assets/`            | User              | Mockups, screenshots, diagrams, reference material                                                                                                        |
| **Spec**     | `<task>-spec.md`     | `brainstorming`   | Approved specification: goals, constraints, architecture, scope (what + why, not how)                                                                     |
| **Plan**     | `<task>-plan.md`     | `writing-plans`   | Implementation plan: file structure, bite-sized tasks, code snippets, test commands                                                                       |
| **Result**   | `<task>-result.md`   | `executing-plans` | Summary of implementation: files changed, decisions made, test results                                                                                    |
| **Review**   | `<task>-review.md`   | `review`          | Review report with item status tracking (Open / Fixed / Skipped / Wontfix) across iterations. Opt-in - only saved when requested or a prior report exists |
