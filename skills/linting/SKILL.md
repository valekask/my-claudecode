---
name: linting
description: Auto-fix linting issues with ESLint on changed TypeScript files
allowed_without_permission: true
---

# Linting

Apply ESLint auto-fix to all changed TypeScript files before creating PR.

## What It Does

1. Detects all changed .ts files compared to main branch
2. Runs ESLint with `--fix` to auto-fix linting issues including import optimization

## How to Detect Changed Files

Use the main branch from Claude Code's git status context (shown as "Main branch (you will usually use this for PRs)").

```bash
# Get all changed .ts files compared to main branch
# Replace {MAIN_BRANCH} with actual branch name from context
git diff --name-only --diff-filter=ACMR origin/{MAIN_BRANCH}...HEAD -- '*.ts'
```

## How to Apply Linting

```bash
# Get all changed .ts files compared to main branch
TS_FILES=$(git diff --name-only --diff-filter=ACMR origin/{MAIN_BRANCH}...HEAD -- '*.ts' | tr '\n' ' ')

# Run ESLint on .ts files (auto-fix linting issues)
if [ -n "$TS_FILES" ]; then
  npx eslint $TS_FILES --fix
fi
```

**Placeholder:**
- `{MAIN_BRANCH}` - Main branch name from Claude Code's git status context

## Workflow

1. Get main branch name from Claude Code's git status context
2. Run `git diff --name-only --diff-filter=ACMR origin/{MAIN_BRANCH}...HEAD -- '*.ts'` to get all changed TypeScript files
3. If no files changed, report "No TypeScript files to lint"
4. Run ESLint with --fix on .ts files
5. Report which files were linted

## Execution

**Run automatically without user approval.** This skill modifies files in place but does not commit changes.

## Output Format

```
Linting X changed TypeScript files (compared to {MAIN_BRANCH}):
- path/to/file1.ts
- path/to/file2.ts

ESLint: Done (X .ts files)

Linted X files successfully.
```
