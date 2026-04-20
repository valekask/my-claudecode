# Claude Code Skills & Configuration

Custom skills and configuration for Claude Code, designed around a structured development workflow that takes features from idea to implementation through collaborative planning.

## Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| **brainstorming** | Before any creative work | Turns proposals into approved specs through collaborative dialogue |
| **writing-plans** | After spec is approved | Creates bite-sized implementation plans from specs (TDD, DRY, YAGNI) |
| **executing-plans** | After plan is written | Executes plan inline, step-by-step in current session |
| **subagent-driven-development** | After plan is written | Executes plan via fresh subagent per task with two-stage review |
| **review** | Before PR | Checklist-driven code review with 11 specialized agents (159 checks) |
| **debug** | Bug or unexpected behavior | Root-cause-first investigation before attempting fixes |
| **formatting** | Before PR | Prettier + import/member ordering for changed files |

## Based on superpowers

Our skills are based on [obra/superpowers](https://github.com/obra/superpowers), with these additions tuned to our workflow (some ideas also drawn from [ryanthedev/code-foundations](https://github.com/ryanthedev/code-foundations)):

#### `brainstorming`

| Addition | Why it matters |
|---|---|
| **Codebase exploration first** | Explore the relevant code before asking questions — understand patterns and conventions so the spec is grounded in how things actually work. |
| **Complexity classification (Simple / Medium / Complex)** | Measures each approach by files touched, patterns involved, and cross-cutting concerns. An elegant approach that forces broad refactoring often loses to a good-enough one that fits the current code. |
| **Convention Wins Rule** | Codebase consistency beats "best practice" unless there's a concrete defect. Deviations must be justified in the spec. |
| **Scope + hardest-part bullets per approach** | Each approach declares *what it touches* and *the riskiest piece* — comparable at a glance. |
| **Pre-mortem for Complex tasks** | Per approach: 3-5 failure modes — "what would make us regret this in 3 months?" |
| **Spec content boundary** | Specs define **what + why** (goals, constraints, architecture), never pseudocode, signatures, or step-by-step how — those belong in the plan. |
| **Spec reviewer subagent (iteration cap)** | Before user review, a reviewer subagent checks for gaps, placeholders, and contradictions (max 5 iterations). |

#### `writing-plans`

| Addition | Why it matters |
|---|---|
| **Trace callers** | Before changing a function, list every caller (direct and indirect) and confirm they still work. Prevents silent breakage in untouched dependent code. |
| **Better test coverage** | Every scenario in the spec's Testing Approach gets a concrete plan step with test code — edge cases, error paths, and constraint violations, not just the happy path. |
| **Dead code cleanup** | When a plan replaces a function or component, it must check remaining callers and remove what's no longer used. Prevents drift from half-finished migrations. |

#### `executing-plans`

| Addition | Why it matters |
|---|---|
| **Per-task user checkpoint** | After each task: pause, report what changed, wait for approval before the next. Execution becomes a dialogue, not a black box. |
| **Spec cross-check during plan review** | Executor reads both plan and spec, checks for drift (does the plan actually implement the spec?), and raises concerns before writing any code. |
| **Result summary artifact** | Concise record of what was built, decisions made during implementation, and test results — handoff material for review. |

## Development Workflow

```
 brainstorming          Proposal → Spec
       │
 writing-plans          Spec → Implementation Plan
       │
       ├── executing-plans                 (simple tasks, inline)
       └── subagent-driven-development     (medium/complex, distributed)
       │
   manual verification
       │
 review + formatting    Code review → PR-ready
```

1. **Brainstorm** (`/brainstorming`) — Read proposal, explore codebase, classify complexity, ask clarifying questions, propose approaches, write and validate a spec
2. **Plan** (`/writing-plans`) — Decompose spec into bite-sized tasks with exact file paths, complete code snippets, and test commands
3. **Execute** — Choose execution strategy based on complexity:
   - **Simple** → `/executing-plans` (inline, current session)
   - **Medium/Complex** → `/subagent-driven-development` (isolated subagents with review)
4. **Verify** — Manual verification of implemented changes
5. **Review** (`/review`) — Run checklist-driven review, then `/formatting` before PR

## Artifacts

All artifacts live in `.claude/temp/<task>/` where `<task>` is a short descriptive name (e.g., `add-currency-filter`).

| Artifact | File | Created By | Description |
|----------|------|-----------|-------------|
| **Proposal** | `<task>-proposal.md` | User | Initial feature request, requirements, context |
| **Assets** | `assets/` | User | Mockups, screenshots, diagrams, reference material |
| **Spec** | `<task>-spec.md` | `brainstorming` | Approved specification: goals, constraints, architecture, scope (what + why, not how) |
| **Plan** | `<task>-plan.md` | `writing-plans` | Implementation plan: file structure, bite-sized tasks, code snippets, test commands |
| **Result** | `<task>-result.md` | `executing-plans` | Summary of implementation: files changed, decisions made, test results |

## Supporting Skills

These skills are used independently at any point in the workflow:

- **debug** — Use when encountering bugs or unexpected behavior. Enforces "no fixes without root cause" — investigates through evidence before proposing changes.
- **review** — 11 parallel checking agents covering naming, clean code, defensive programming, architecture, data flow, state management, regressions, security, test quality, styling, and forms.
- **formatting** — Detects modified files and applies Prettier formatting, import sorting (6 groups), and class member ordering.
