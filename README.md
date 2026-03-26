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
