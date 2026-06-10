# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

<One-paragraph description: what the project does, main applications, and any key technical constraint that shapes how code must be written.>

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

## Architecture Decision Records

This project keeps Architecture Decision Records in `docs/adr/` — they record *why* complex code is the way it is: the intent, trade-offs, and edge cases that aren't recoverable from the code. Code is the primary source for *what* the code does; ADRs are authoritative for *why*. `docs/adr/README.md` indexes them all.

- **Before proposing or implementing architectural changes, scan `docs/adr/README.md`** and read any ADRs relevant to the area you're touching — don't re-litigate a settled decision or remove a guard.
- **When explaining or analyzing how code works, consult `docs/adr/README.md` too** — the code shows *what*; the ADR holds the *why* and edge cases the code can't tell you.
- When implementing complex code with non-obvious constraints, consider capturing one as an ADR in `docs/adr/`.
- Never edit an accepted ADR's decision — supersede it with a new record.

## Protected Files

**Do NOT change** (without explicit request):
- <dependency manifests, e.g., `package.json`, `requirements.txt`>
- <build/monorepo config, e.g., `nx.json`, `tsconfig.base.json`>
- <production environment files, e.g., `environment.prod.ts`>
- Git config or hooks
