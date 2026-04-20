---
name: formatting
description: Format changed files with Prettier
allowed_without_permission: true
model: haiku
effort: low
---

# Formatting

Apply Prettier formatting and code organization to locally modified files.

## What It Does

1. Detects locally modified files (.ts, .html, .scss) - both staged and unstaged
2. Runs Prettier to format them
3. For TypeScript files: organizes imports and class members

## How to Detect Changed Files

```bash
# Get locally modified files (staged and unstaged)
git diff --name-only --diff-filter=ACMR HEAD -- '*.ts' '*.html' '*.scss'
git diff --name-only --cached --diff-filter=ACMR -- '*.ts' '*.html' '*.scss'
```

## Step 1: Organize TypeScript Files

For each changed `.ts` file, read and reorganize following these rules:

### Import Organization

Sort imports into groups (NO blank lines between groups):

1. **Angular core** - `@angular/core`, `@angular/common`, etc.
2. **Angular modules** - `@angular/forms`, `@angular/router`, etc.
3. **NgRx** - `@ngrx/store`, `@ngrx/effects`, etc.
4. **External packages** - `rxjs`, `lodash`, `d3`, etc.
5. **Internal packages** - `@fna/*`, `@libs/*`, project aliases
6. **Relative imports** - `./`, `../`

Within each group, sort alphabetically by path.

### Class Member Ordering

Organize class members in this order:

1. **Public static fields**
2. **Private static fields**
3. **Public instance fields** (including `@Input()`, `@Output()`, `@ViewChild()`)
4. **Private instance fields** (including `private subs = new Subscription()`)
5. **Constructor** (always after ALL fields, before lifecycle hooks)
6. **Lifecycle hooks** (in Angular's official order):
   - `ngOnChanges`
   - `ngOnInit`
   - `ngDoCheck`
   - `ngAfterContentInit`
   - `ngAfterContentChecked`
   - `ngAfterViewInit`
   - `ngAfterViewChecked`
   - `ngOnDestroy`
7. **Public static methods**
8. **Private static methods**
9. **Public instance methods**
10. **Private instance methods**

### Code Style Fixes

**Consistent return** - Functions must either always return a value or never return a value:
```typescript
// Bad
function foo(x) {
  if (x) return 1;
}

// Good
function foo(x) {
  if (x) return 1;
  return undefined;
}
```

**Curly braces** - All `if`, `else`, `for`, `while` statements must have braces:
```typescript
// Bad
if (x) doSomething();

// Good
if (x) {
  doSomething();
}
```

### What NOT to Change

- Do not modify logic or functionality
- Do not rename variables
- Do not add/remove unrelated code
- Only reorder members/imports and apply style fixes above

## Step 2: Run Prettier

After all TypeScript organization is complete, run Prettier to format everything:

```bash
npx prettier --write <files>
```

## Workflow

1. Get locally modified files using `git diff --name-only`
2. If no files changed, report "No files to format"
3. For each .ts file:
   - Read the file
   - Reorganize imports (group and sort)
   - Reorganize class members (following order above)
   - Fix consistent-return issues
   - Add curly braces to if/else/for/while
   - Write back if changes were made
4. Run Prettier on all changed files (.ts, .html, .scss)
5. Report results

## Execution

**Run automatically without user approval.**

## Output Format

```
Organizing X TypeScript files:
- path/to/file1.ts (imports, members, curly braces)
- path/to/file3.ts (imports, consistent-return)

Formatting X files with Prettier:
- path/to/file1.ts
- path/to/file2.html
- path/to/file3.scss

Done.
```
