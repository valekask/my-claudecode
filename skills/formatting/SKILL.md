---
name: formatting
description: Format changed files with Prettier
allowed_without_permission: true
---

# Formatting

Apply Prettier formatting to locally modified files.

## What It Does

1. Detects locally modified files (.ts, .html, .scss) - both staged and unstaged
2. Runs Prettier to format them

## How to Apply Formatting

```bash
# Get locally modified files (staged and unstaged)
git diff --name-only --diff-filter=ACMR HEAD -- '*.ts' '*.html' '*.scss'
git diff --name-only --cached --diff-filter=ACMR -- '*.ts' '*.html' '*.scss'

# Run Prettier on changed files
npx prettier --write <files>
```

## Workflow

1. Get locally modified files using `git diff --name-only`
2. If no files changed, report "No files to format"
3. Run Prettier on all changed files
4. Report which files were formatted

## Execution

**Run automatically without user approval.**

## Output Format

```
Formatting X files:
- path/to/file1.ts
- path/to/file2.html

Done.
```
