# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

<One-paragraph description: what the project does, main applications, and any key technical constraint that shapes how code must be written.>

## Analysis vs Implementation

**Analysis mode** — When the prompt focuses on understanding (questions, investigation), provide analysis and recommendations WITHOUT editing files. Wait for explicit approval.

Analysis triggers:
- Questions: prompts ending with `?`
- Keywords: analyze, investigate, understand, explain, review, check, what's wrong, root cause, how does, why does

**Implementation mode** — Proceed with code changes when using action words:
- fix, implement, apply, update, add, remove, refactor, change, create

**Mixed prompts** — If both analysis and action words appear, ask which mode first.

**Bug reports** — When something is reported as broken or incorrect ("doesn't work", "works incorrectly", "this is broken"), treat as analysis first: diagnose root cause, explain findings, propose fix, wait for approval before changing code.

**Override** — "just analyze" or "just fix it" to clarify intent.

**Clarification** — When uncertain, use AskUserQuestion to interview me and clarify intent before acting. Ask one question at a time, never multiple questions at once.

## Core Technologies

<List key frameworks, languages, libraries, and testing tools with major versions. Call out constraints like "NO Signals" or "no async/await" that must be respected.>

## Commands

```bash
# <Run tests>
# <Run a single test file>
# <Type-check / compile>
# <Lint / format>
```

<Note where to find project names, paths, or tooling config (e.g., `tsconfig.base.json`, `nx.json`, `pyproject.toml`).>

## Code Conventions

<Project-specific rules for code style, architecture patterns, naming, file organization, state management, testing, and styling. Keep each rule short; link to `docs/` for longer explanations.>

**Debug logging.** When asked to add logs, use `console.log` with `JSON.stringify(value, null, 2)` for any non-primitive value so nested objects print in full.

## Memory

Do not save to memory without explicit approval. Ask first.

## Protected Files

**Do NOT change** (without explicit request):
- <dependency manifests, e.g., `package.json`, `requirements.txt`>
- <build/monorepo config, e.g., `nx.json`, `tsconfig.base.json`>
- <production environment files, e.g., `environment.prod.ts`>
- Git config or hooks

## Git Restrictions (MANDATORY)

**NEVER perform git write operations.** The user prefers to manually review all changes before committing.

Forbidden operations:
- `git commit`, `git add`, `git push`, `git checkout`
- `git reset`, `git revert`, `git merge`, `git rebase`, `git stash`

**Allowed** (read-only): `git status`, `git log`, `git diff`, `git branch`, `git show`

If a skill or plugin requests a commit, **refuse and inform the user** that manual review is required first.
