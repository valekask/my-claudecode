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

## Protected Files

**Do NOT change** (without explicit request):
- <dependency manifests, e.g., `package.json`, `requirements.txt`>
- <build/monorepo config, e.g., `nx.json`, `tsconfig.base.json`>
- <production environment files, e.g., `environment.prod.ts`>
- Git config or hooks
