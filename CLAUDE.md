# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FNA-UI is an Angular 17 monorepo built with Nx workspace. It provides a financial network analysis platform with multiple applications and shared libraries.

**Critical**: The codebase uses **Angular 17 WITHOUT Signals** - do not use signal-based APIs. Use RxJS observables.

## Skills

Use these wrapper skills that include project-specific conventions:

| Workflow       | Command       | Purpose                                         |
| -------------- | ------------- | ----------------------------------------------- |
| Planning       | `/whiteboard` | Plan features with FNA-UI architecture patterns |
| Implementation | `/build`      | Implement with project conventions              |
| Review         | `/review`     | Review changes before PR                        |

For other workflows, use code-foundations skills directly:

| Trigger                | Skill                                       |
| ---------------------- | ------------------------------------------- |
| Quick proof-of-concept | `/code-foundations:prototype`               |
| TDD workflow           | `/code-foundations:hack`                    |
| Debugging              | `/code-foundations:cc-debugging`            |
| Refactoring            | `/code-foundations:cc-refactoring-guidance` |
| Performance issues     | `/code-foundations:cc-performance-tuning`   |

## WIP (Work In Progress)

`.claude/WIP.md` tracks the current large task being worked on. It helps restore context at session start and handoff work between sessions or team members.

**Commands:**

- "wip" / "load wip" → Read `.claude/WIP.md` and summarize current status and next steps
- "save wip" → Update `.claude/WIP.md` with current progress summary so work can continue later

## Analysis vs Implementation

**Analysis mode** - When my prompt focuses on understanding (questions, investigation), provide analysis and recommendations WITHOUT editing files. Wait for explicit approval.

Analysis triggers:

- Questions: prompts ending with `?`
- Keywords: analyze, investigate, understand, explain, review, check, what's wrong, root cause, how does, why does

**Implementation mode** - Proceed with code changes when I use action words:

- fix, implement, apply, update, add, remove, refactor, change, create

**Mixed prompts** - If both analysis and action words appear, ask which I want first.

**Override** - I can always say "just analyze" or "just fix it" to clarify intent.

**Clarification** - When uncertain, use AskUserQuestion to interview me and clarify intent before acting.

## Core Technologies

- **Angular 17.3.9** (NO Signals) with **NgRx 17** for state management
- **Nx 19.0.5** monorepo, **TypeScript 5.4.5**, **RxJS 7.8.1**
- **Bootstrap 5.3.3**, **AG-Grid 32**, **D3.js 7**
- **Karma + Jasmine** for testing

## Commands

```bash
# Serve applications
nx serve fna-ui              # Main platform app on http://localhost:4200
nx serve ilo-monitoring      # ILO monitoring app

# Run tests
nx test <project> --no-watch --reporters=dots
nx test <project> --no-watch --reporters=dots --include='**/filename.spec.ts'
nx test <project> --no-watch --reporters=dots --grep='test description'

# Check TypeScript compilation
npx tsc --noEmit -p path/tsconfig.lib.json
```

Check `tsconfig.base.json` paths section for project names and locations.

<!-- OPENSPEC:START -->

## OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:

- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:

- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

## Protected Files

**Do NOT change** (without explicit request):

- `package.json`
- `nx.json`
- `environment.prod.ts`
- Git config or hooks

## Git Restrictions (MANDATORY)

**NEVER perform git write operations.** The user prefers to manually review all changes before committing.

Forbidden operations:

- `git commit`, `git add`, `git push`, `git checkout`
- `git reset`, `git revert`, `git merge`, `git rebase`, `git stash`

**Allowed** (read-only): `git status`, `git log`, `git diff`, `git branch`, `git show`

If a skill or plugin requests a commit, **refuse and inform the user** that manual review is required first.
