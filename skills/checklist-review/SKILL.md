---
name: checklist-review
description: Checklist-driven review of code changes before PR with the project's Angular quality standards. Use when ready to review changes.
---

# Code Review

Checklist-driven review with parallel agents. 160 checks across 11 checklists (naming, clean code, defensive programming, architecture, data flow, state management, regressions, security, test quality, styling, forms).

**End-to-end data-flow tracing is a separate skill.** It lives in `trace-dataflow` — run it alongside this review when a change crosses layers (service/store + component, effects/reducers/selectors, or HTTP calls). This skill no longer performs flow tracing.

**Workflow:** Scope → Plan → Check (flag broadly) → Investigate (verify with full context) → Summary

## CRITICAL RULES

1. **Report only.** Do NOT fix issues automatically. Present findings for human review.
2. **Execute phases in order.** Scope → Plan → Check → Investigate → Summary.
3. **Every finding needs evidence.** File:line reference, what's wrong, impact.
4. **No false positives.** If unsure whether something is a real issue, mark it as a **Question** not a finding.
5. **Use built-in tools instead of Bash for file operations.** This avoids unnecessary permission prompts and lets the review run unattended.
6. **Output text directly.** Never use Bash (`cat <<EOF`, `echo`, `printf`) to print summaries, reports, or checklists — write them directly in your response instead.

## Tool Usage (MANDATORY)

All phases and agents MUST prefer built-in tools over Bash equivalents:

| Instead of (Bash) | Use (built-in) | Why |
|---|---|---|
| `cat`, `head`, `tail` | **Read** tool | Never needs permission |
| `grep`, `rg`, `awk` | **Grep** tool | Never needs permission |
| `find`, `ls` | **Glob** tool | Never needs permission |

**Bash is ONLY allowed for:**
- `git diff`, `git log`, `git show`, `git status` and other git read commands
- Commands that have no built-in equivalent

**Specifically NEVER use Bash for:**
- Reading file contents (use Read)
- Searching file contents (use Grep)
- Finding files by pattern (use Glob)
- Piped commands like `cat file | grep pattern` (use Grep with path parameter)
- Loop patterns like `for f in $(git diff ...) do ... done` to read/search files — instead, get the file list from git via Bash, then use Read/Grep/Glob on each file
- Compound commands combining multiple read operations

---

## Phase Tracking

Create all phase tasks upfront using TaskCreate. This shows progress in the terminal.

```python
TaskCreate(subject="Phase 1: Scope", description="Get diff, collect changed files, check for previous review if task dir exists", activeForm="Collecting changes")
TaskCreate(subject="Phase 2: Plan", description="Determine which agents to activate", activeForm="Planning review")
TaskCreate(subject="Phase 3: Check", description="Flag findings broadly with checking agents", activeForm="Running checking agents")
TaskCreate(subject="Phase 4: Investigate", description="Verify raw findings with full context", activeForm="Investigating findings")
TaskCreate(subject="Phase 5: Summary", description="Merge with previous, deduplicate, generate report, save if persistence active", activeForm="Generating report")
```

**Each phase MUST:**
1. `TaskUpdate(taskId=phase_id, status="in_progress")` before starting
2. Do its work
3. `TaskUpdate(taskId=phase_id, status="completed")` when done

---

## Review Persistence

Review reports **can** be saved to `.claude/temp/<task>/<task>-checklist-review.md` to track item status across iterations. Saving is **opt-in** — quick one-off reviews produce no files.

### When persistence is active

Persistence is active when **any** of these are true:
- The user passes `--save` (e.g., `/checklist-review --save`)
- The user says "save the review" (before or after the review)
- A previous report already exists for this task (sticky — once you save the first report, subsequent reviews in the same task auto-save)

### Task directory

When persistence is active and no `.claude/temp/<task>/` directory exists, ask the user for a task name in `<ticket-number>-<slug>` form (e.g., `FNA-1234-currency-filter`) and create the directory. When persistence is **not** active, do not ask for a task name.

### Previous report handling

At the start of each review, if a task directory exists, check for an existing `<task>-checklist-review.md`. If found (this also activates persistence):

1. **Read it** and extract the Summary table (the `| # | Type | Issue | Severity | Status |` table at the bottom)
2. **Carry forward resolved items.** Items with status `Fixed`, `Skipped`, or `Wontfix` are NOT re-checked. They appear in a **Previously Resolved** section of the new report with their original status.
3. **Re-check open items.** Items with status `Open` from the previous report are checked again. If the issue is gone from the diff, mark as `Fixed`. If still present, keep as `Open`.
4. **New findings** get status `Open`.

### Status values

| Status | Meaning |
|--------|---------|
| `Open` | Issue found, not yet addressed |
| `Fixed` | Issue was present in previous review, now resolved in code |
| `Skipped` | User explicitly decided to skip this item |
| `Wontfix` | User explicitly decided this is not worth fixing |

Users set `Skipped` / `Wontfix` by editing the report file manually or telling the reviewer in conversation.

---

## Phase 1: SCOPE

Determine what to review.

### Step 1.0: Check for previous review

Look for an existing review report **only if** a task directory is already known (user specified a task name, or an active task directory exists under `.claude/temp/`):

1. If a task directory exists, check for `<task>-checklist-review.md` inside it
2. If found, read the file and extract:
   - The **Summary table** (items with their statuses)
   - The **Scope** section (to compare what was reviewed before)
3. Store the previous items for use in Phase 5
4. Mark persistence as active (previous report found → sticky auto-save)

If no task directory exists, skip this step entirely — do not ask for a task name. This is a fresh review with no persistence.

### Step 1.1: Get the diff

Ask the user what to review (if not specified):
- `--staged` → `git diff --cached`
- `--unstaged` → `git diff`
- `--branch` → `git diff main...HEAD`
- A specific path → `git diff -- <path>`

Default: review all unstaged changes.

### Step 1.2: Collect changed files

Run `git diff --name-only` (with appropriate args) to get the list of changed files.
Group files by type:

| Extension / Path pattern | File type |
|---|---|
| `*.component.ts` | component |
| `*.service.ts` | service |
| `*.store.ts`, `+state/*` | store |
| `*.spec.ts` | test |
| `*.component.html` | template |
| `*.component.scss`, `*.scss` | style |
| `*.model.ts`, `*.interface.ts` | model |
| `*.module.ts` | module |
| `*.directive.ts` | directive |
| `*.pipe.ts` | pipe |
| `*.guard.ts`, `*.interceptor.ts` | infra |

---

## Phase 2: PLAN

Determine which agents to activate based on changed files. Use a fast model (haiku).

### Agent activation

**Always activate:** Agent 7: SAFETY (regressions apply to all changes)

| Agent | Activate when |
|---|---|
| Agent 1: NAMING | Any `.ts` file changed |
| Agent 2: CLEAN CODE | Any `.ts` file changed |
| Agent 3: DEFENSIVE PROGRAMMING | Any `.ts` file changed |
| Agent 4: ARCHITECTURE | component, service, store, module, directive, or infra files changed |
| Agent 5: DATA FLOW | component, service, store, module, or infra files changed |
| Agent 6: STATE MANAGEMENT | store files changed, OR files importing from `@ngrx` changed |
| Agent 7: SAFETY | Always |
| Agent 8: TEST QUALITY | Any `.service.ts`, `.store.ts`, `.utils.ts`, `.pipe.ts`, `.directive.ts`, `.guard.ts`, or `.interceptor.ts` changed — OR any `.spec.ts` changed |
| Agent 9: STYLING | Any `.scss` or `.html` file changed |
| Agent 10: FORMS | Any changed `.ts` file imports `FormBuilder`, `FormGroup`, `FormArray`, `FormControl`, `Validators`, or `ControlValueAccessor` |

### Lightweight mode

If ≤3 files changed AND no store/service files:
- **Always:** Agent 1+2+3 (if any `.ts` file) + Agent 7 (safety)
- **Add Agent 8** if any `.spec.ts` file changed
- **Add Agent 9** if any `.scss` or `.html` file changed
- **Add Agent 10** if any changed `.ts` file imports form APIs
- **Skip:** Agent 4 (architecture), Agent 5 (data flow), Agent 6 (state management)

---

## Phase 3: CHECK

Launch activated checking agents **in parallel**. Checking agents have ONE job: **flag anything suspicious**. They do NOT need to be certain — if in doubt, flag it. The investigation phase will verify.

### Checking agent instructions

All checking agents use this mindset:
- **Err on the side of flagging.** A false flag costs nothing — the investigation phase will dismiss it.
- **Do not skip checks.** Run every check in your checklist against every applicable line in the diff.
- **Do not judge severity yet.** Just flag and describe. Severity is assigned during investigation.

### Agent 1: NAMING

**Checklist:** `naming.md` (12) = **12 checks**

**Focus:** Naming conventions only.

**Input:** Diff of all changed `.ts` files + checklist contents.

### Agent 2: CLEAN CODE

**Checklist:** `clean-code.md` (26) = **26 checks**

**Focus:** Function design, variable scope, dead code, RxJS patterns, template complexity, type safety, cyclomatic complexity.

**Input:** Diff of all changed `.ts` files + checklist contents.

### Agent 3: DEFENSIVE PROGRAMMING

**Checklist:** `defensive-programming.md` (15) = **15 checks**

**Focus:** Null/NaN guards, input validation, error handling, boundary conditions, date/time safety, output validity of recursive operations.

**Input:** Diff of all changed `.ts` files + checklist contents.

### Agent 4: ARCHITECTURE

**Checklist:** `architecture.md` (13) = **13 checks**

**Focus:** Component split, layer boundaries, module design, Angular 17 constraints.

**Input:** Diff of component, service, store, module, directive, infra files + checklist contents. Read full source files when checklist requires understanding surrounding code (e.g., checking callers, import chains, inheritance depth).

### Agent 5: DATA FLOW

**Checklist:** `data-flow.md` (14) = **14 checks**

**Focus:** Unidirectional data flow, reactive patterns, subscription cleanup, RxJS safety patterns.

**Input:** Diff of component, service, store, module, infra files + checklist contents.

### Agent 6: STATE MANAGEMENT

**Checklist:** `state-management.md` (14) = **14 checks**

**Focus:** ComponentStore vs Global Store, effects, reducers, selectors.

**Input:** Diff of store files + files importing from `@ngrx` + checklist contents. Read full source files for context on state shape, effect patterns, and selector composition.

### Agent 7: SAFETY

**Checklists:** `regressions.md` (11) + `security.md` (14) = **25 checks**

**Focus:** Breaking changes, backward compatibility, test coverage, secrets, injection, auth.

**Input:** Full diff of all changed files + checklist contents. For regression checks (RG-1, RG-2), search the broader codebase for callers of changed APIs.

### Agent 8: TEST QUALITY

**Checklist:** `test-quality.md` (14) = **14 checks**

**Focus:** Logic-test alignment. Reads both implementation AND spec files to verify tests actually cover the logic. Skips components.

**Scope:** Only `.service.ts`, `.store.ts`, `.utils.ts`, `.pipe.ts`, `.directive.ts`, `.guard.ts`, `.interceptor.ts` files and their corresponding `.spec.ts` files.
**Skip:** `.component.ts` files — components are containers/presenters; their logic belongs in services/stores.

**Input:** For each in-scope file pair: full source of implementation file + full source of spec file + diff of both.

**Instructions for the test quality agent:**

```
You are reviewing test quality for the Angular project.
Your job is to verify that tests actually cover the implementation logic — not just that tests exist.

## Checklist
{contents of test-quality.md}

## File Pairs to Review
{for each in-scope implementation file + its spec file: full source of both + diff}

## Instructions

For EACH file pair:

### Step 1: Map the implementation
Read the implementation file. List every decision point:
- Each `if/else` branch
- Each `switch` case
- Each `catchError` / `catch` block
- Each guard clause (early return)
- Each observable pipe with conditional logic

### Step 2: Map the tests
Read the spec file. For each `it()` block, determine which implementation branch it exercises.

### Step 3: Find gaps
Compare the maps. Report:

For each finding, output:

### [TQ-ID] FLAG — short title
- **File**: `path/to/file.ts:LINE` → `path/to/file.spec.ts`
- **Issue**: What is not covered or incorrectly tested (1-2 sentences)
- **Confidence**: HIGH | MEDIUM | LOW

### Step 4: If no spec file exists
If an in-scope implementation file has no corresponding spec file, output a single finding:

### [TQ-12] FLAG — No spec file for {filename}
- **File**: `path/to/file.ts`
- **Issue**: Implementation file has no corresponding spec file. All branches are untested.
- **Confidence**: HIGH
```

### Agent 9: STYLING

**Checklist:** `styling.md` (13) = **13 checks**

**Focus:** Design system usage, CSS variables, Bootstrap utilities, selector specificity, property ordering, template–SCSS class matching.

**Input:** Diff of all changed `.scss` and `.html` files + checklist contents. Read `libs/ui/src/assets/scss/` variable files when checking if a hardcoded value exists in the design system. For ST-8 (Bootstrap deprecations), check both `.scss` class references and `.html` template class attributes.

### Agent 10: FORMS

**Checklist:** `forms.md` (14) = **14 checks**

**Focus:** Form setup correctness, validation layer separation (domain vs presentation), data extraction safety, form lifecycle, submission flow.

**Input:** Diff of all changed `.ts` files that import form-related APIs (`FormBuilder`, `FormGroup`, `FormArray`, `FormControl`, `Validators`, `ControlValueAccessor`) + their corresponding `.html` templates + checklist contents. Read full source files to trace the form lifecycle: setup → validation → data extraction → submission.

### Checking agent prompt template (for agents 1, 2, 3, 4, 5, 6, 7, 9, 10)

```
You are a checking agent reviewing code changes for the Angular project.
Your job is to FLAG anything suspicious. Err on the side of reporting — the investigation phase will verify your findings.

## Your Checklist
{contents of assigned checklist file(s)}

## Changed Files
{diff output}

## Instructions

### New files vs modified files

For **file-level metrics** (line count, class member count, dependency count, complexity thresholds):
- **New files** (all lines are additions): apply the check normally.
- **Modified files** (some lines changed): only flag if the change MADE THE METRIC WORSE. Do not flag a 310-line file that was only touched on 2 lines — unless those 2 lines pushed it over the threshold.

For **line-level checks** (naming, null guards, dead code, etc.): focus on lines in the diff plus surrounding context needed to understand them.

### Checking process

For each checklist item:
1. Determine if it applies to the changed code
2. If it applies, check pass/fail using the criteria in the checklist
3. If FAIL or UNCERTAIN: flag it

**IMPORTANT:** Only use check IDs from YOUR assigned checklist. Do not invent IDs or use IDs from other agents' checklists. If you find an issue that doesn't match any of your checks, skip it — another agent will catch it.

**Do not skip any check.** Run every check against every applicable line. If a check has zero applicable lines, move on, but do not skip it without considering the diff.

For each flagged item, output EXACTLY this format:

### [CHECKLIST-ID] FLAG — short title
- **File**: `path/to/file.ts:LINE`
- **Issue**: What looks wrong or suspicious (1-2 sentences)
- **Confidence**: HIGH (clearly fails the check) | MEDIUM (likely fails) | LOW (suspicious, needs verification)

If a check passes for all applicable lines, do not output anything for it.
```

### Severity guide (used in Investigation phase, not during checking)

| Severity | Criteria | NOT Critical/High |
|---|---|---|
| **Critical** | User-visible broken behavior, data loss, data corruption, security breach. The feature does not work correctly. | Console.log, environment file changes, missing tests, code smells |
| **High** | Broken contracts (callers get wrong data), race conditions with visible effect, missing error handling that crashes at runtime, memory leaks | Code duplication, naming issues, architecture preferences |
| **Medium** | Missing tests, code smells, naming violations, unnecessary complexity, debug artifacts (console.log), unintended file changes (environment files) | Style preferences |
| **Low** | Style preferences, minor improvements, documentation gaps, magic numbers | |

**Key rule:** Critical means "this will break in production for users." If the app still works but the code is ugly, it's not Critical.

---

## Phase 4: INVESTIGATE

Verify raw findings from Phase 3 with full file context. This phase turns raw flags into confirmed findings or dismisses them as false positives.

### Step 4.1: Collect raw findings

Gather all flags from all checking agents into a single list. Group them **by file** for efficient investigation.

### Step 4.2: Launch investigation agents

Batch raw findings **by file** — all findings for the same file go to the same investigation agent. If a file has many findings (>8), split into two batches. Launch investigation agents **in parallel**.

Each investigation agent reads the **full source file** (not just the diff) with **20+ lines of context** around each flagged line.

**Investigation agent prompt:**

```
You are an investigation agent verifying flagged code review findings for the Angular project.
Each finding below was flagged by a checking agent. Your job is to read the full source code and verdict each one.

## Findings to Investigate
{list of findings for this file, with file:line references}

## Instructions

For EACH finding:
1. Read the full source file around the flagged line (20+ lines of context)
2. Determine if the finding is a real issue or a false positive
3. Verdict it as one of:

**CONFIRMED** — Real issue. Output:

### [CHECKLIST-ID] CONFIRMED — short title
- **File**: `path/to/file.ts:LINE`
- **Issue**: What is wrong (1-2 sentences, refined with full context)
- **Impact**: Why this matters (1 sentence)
- **Fix**: How to fix it (1-2 sentences, or "obvious" if self-evident)
- **Severity**: Critical | High | Medium | Low

**FALSE_POSITIVE** — Not an issue. Output:

### [CHECKLIST-ID] FALSE_POSITIVE — short title
- **File**: `path/to/file.ts:LINE`
- **Reason**: Why this is not an issue (1-2 sentences referencing the full context)

**QUESTION** — Cannot determine with available context. Output:

### [CHECKLIST-ID] QUESTION — short title
- **File**: `path/to/file.ts:LINE`
- **Issue**: What looks suspicious (1-2 sentences)
- **Unknown**: What context is missing to determine pass/fail

Use the severity guide:
- **Critical**: User-visible broken behavior, data loss, data corruption, security breach
- **High**: Broken contracts, race conditions with visible effect, missing error handling that crashes, memory leaks
- **Medium**: Missing tests, code smells, naming violations, debug artifacts
- **Low**: Style preferences, minor improvements, documentation gaps, magic numbers
```

### Step 4.3: Collect verdicts

Gather all investigation results. The output of this phase is:
- **CONFIRMED findings** → go to Summary as real findings
- **FALSE_POSITIVE findings** → listed in report for transparency (collapsed/brief)
- **QUESTION findings** → go to Summary as Questions

---

## Phase 5: SUMMARY

Merge all agent outputs into a single report. Optionally save to disk for future review iterations.

### Step 5.0: Merge with previous review

If a previous review report was loaded in Phase 1:

1. **Resolved items** (status `Fixed`, `Skipped`, `Wontfix`) — collect into a **Previously Resolved** list. Do not re-check.
2. **Previously Open items** — check each against current findings:
   - If the same issue (same file + same checklist ID or similar description) appears in current findings → keep as `Open`, use the current finding's details
   - If the issue is no longer in the diff → mark as `Fixed`
   - If the issue is still in the code but was not flagged (e.g., agent wasn't activated) → keep as `Open` with a note
3. **New findings** from current review → add as `Open`

### Step 5.1: Deduplicate

Merge CONFIRMED findings that describe the same underlying problem:
- Same file:line confirmed by multiple agents → merge into one finding (keep the highest severity and most impactful description)
- Same root cause across multiple files (e.g., "duplicated pattern in 9 components" + "logic in component instead of selector") → merge into one finding, list all affected files
- When merging, prefer framing by user-visible impact over rule-violation framing
- FALSE_POSITIVE items: include in the Dismissed Findings section (both notable passes and routine dismissals)
- QUESTION items: include in the Questions section

### Step 5.2: Generate report

```markdown
# Code Review Report

## Meta
- **Task**: {task name}
- **Review**: #{N} ({date})
- **Previous**: #{N-1} ({date}) — {X open, Y fixed, Z skipped} | or "None (first review)"

## Scope
- **Target**: {what was reviewed}
- **Files**: {count} files changed
- **Agents run**: {list of activated agents}

## Strengths
{What's well done — be specific. Reference file:line where good patterns are used.}

## Findings

### Critical

{Numbered findings. IMPORTANT: insert a blank line between each finding for readability. Example:}

1. [CATEGORY: ID] title
   - **File**: ...
   - **Issue**: ...
   - **Impact**: ...
   - **Fix**: ...

2. [CATEGORY: ID] title
   - **File**: ...
   - **Issue**: ...
   - **Impact**: ...
   - **Fix**: ...

### High

{Same format as Critical — blank line between each finding}

### Medium

{Same format — blank line between each finding}

### Low

{Same format — blank line between each finding}

## Questions
{Items where the reviewer needs more context — list with **Unknown** section}

## Test Quality Summary
{Only include when Agent 8 (Test Quality) was activated. Summarize aggregate test coverage patterns across all reviewed files — this is the holistic view, not individual findings (those stay in Findings above).}

{List systemic test gaps as bullet points, e.g.:}
- {pattern} untested in {N} stores/services
- {file} has only {N} meaningful test covering {what}; {list of untested branches}
- {selectors/utilities} have zero test coverage

## Review Coverage

| Agent | Checks | Passed | Failed | Notes |
|-------|--------|--------|--------|-------|
| NAMING | 12 | X | X | {brief summary or "All passed"} |
| CLEAN CODE | 26 | X | X | {brief summary or "All passed"} |
| DEFENSIVE | 15 | X | X | {brief summary or "All passed"} |
| FORMS | 13 | X | X | {brief summary or "All passed"} |
| ARCHITECTURE | 13 | X | X | {brief summary or "All passed"} |
| DATA FLOW | 14 | X | X | {brief summary or "All passed"} |
| STATE MGMT | 14 | X | X | {brief summary or "All passed"} |
| SAFETY | 25 | X | X | {brief summary or "All passed"} |
| TEST QUALITY | 13 | X | X | {brief summary or "All passed"} |
| STYLING | 13 | X | X | {brief summary or "All passed"} |

{Only include rows for activated agents. "Failed" = confirmed findings, not raw flags.}

## Dismissed Findings
{Only include FALSE_POSITIVE verdicts that were flagged with HIGH confidence during checking. These are findings that looked clearly wrong but turned out fine — showing the review was thorough. Skip MEDIUM and LOW confidence dismissals.}

- **[CHECK-ID]** {what was flagged} — **Reason:** {why it's not an issue, referencing full context}

## Previously Resolved
{Only include if this is review #2 or later. List items from prior reviews that are no longer open.}

| # | Type | Issue | Severity | Status | Resolved in |
|---|------|-------|----------|--------|-------------|
| {original #} | {CATEGORY: ID} | {short description} | {severity} | Fixed/Skipped/Wontfix | Review #{N} |

{If no previously resolved items, omit this section.}

## Summary

| # | Type | Issue | Severity | Status |
|---|------|-------|----------|--------|
| 1 | {CATEGORY} | {short description} | Critical/High/Medium/Low | Open |
| 2 | {CATEGORY: ID} | {short description} | Critical/High/Medium/Low | Open |
| 3 | {CATEGORY: ID} | {short description} | Critical/High/Medium/Low | Fixed |
| ... | | | | |

{Status values: Open, Fixed, Skipped, Wontfix. Items carried from previous reviews keep their original number. New items get the next available number.}

**Ready to merge?** [Yes / No / With fixes]

**Reasoning:** {1-2 sentence technical assessment — only consider `Open` items for merge readiness}
```

### Step 5.3: Save report to disk (conditional)

**Only save when persistence is active** (user passed `--save`, said "save the review", or a previous report was loaded in Phase 1).

When saving:

1. If no task directory exists yet, ask the user for a task name in `<ticket-number>-<slug>` form (e.g., `FNA-1234-currency-filter`) and create `.claude/temp/<task>/`
2. Write the full report to `.claude/temp/<task>/<task>-checklist-review.md` using the Write tool
3. If the file already exists, overwrite it (the new report contains all historical context in the Previously Resolved section)
4. Tell the user: `Review saved to .claude/temp/<task>/<task>-checklist-review.md`

When **not** saving: skip this step silently. The report is already displayed in the conversation.

**Tip for users:** To mark items as `Skipped` or `Wontfix`, either:
- Edit the status in the Summary table of `<task>-checklist-review.md` directly
- Tell the reviewer in conversation (e.g., "skip item #3, wontfix #5") before running the next review

### Decision criteria for merge readiness

| Condition | Verdict |
|---|---|
| 0 Critical, 0 High | **Yes** |
| 0 Critical, any High | **With fixes** (list which High items must be resolved) |
| Any Critical | **No** |

---

### Finding format in final report

When merging findings into the summary report, expand the checklist ID prefix to its full category name:

**Format:** `{number}. [{FULL CATEGORY}: {ID}] title`

Examples:
- `1. [CLEAN CODE: CC-17] console.log left in production code`
- `2. [REGRESSION: RG-2] Removed properties break drill-down modal`
- `3. [DEFENSIVE: DP-3] NaN input causes runtime RangeError`
- `4. [FORMS: FM-1] Custom validator registered after initial validation pass`

---

## Agents Overview

| Agent | Phase | Checklists | Checks | When |
|---|---|---|---|---|
| 1: NAMING | Check | naming | 12 | Any `.ts` file |
| 2: CLEAN CODE | Check | clean-code | 26 | Any `.ts` file |
| 3: DEFENSIVE PROGRAMMING | Check | defensive-programming | 15 | Any `.ts` file |
| 4: ARCHITECTURE | Check | architecture | 13 | Component/service/store/module/directive/infra files |
| 5: DATA FLOW | Check | data-flow | 14 | Component/service/store/module/infra files |
| 6: STATE MANAGEMENT | Check | state-management | 14 | Store files or `@ngrx` imports |
| 7: SAFETY | Check | regressions + security | 25 | Always |
| 8: TEST QUALITY | Check | test-quality | 14 | Service/store/util/pipe/directive/guard/interceptor or spec files changed |
| 9: STYLING | Check | styling | 13 | Any `.scss` or `.html` file changed |
| 10: FORMS | Check | forms | 14 | Files importing form APIs (`FormBuilder`, `FormGroup`, etc.) |
| Investigation | Investigate | (verifies raw findings) | — | Always (after Check phase) |
| **Total** | | 11 checklists | **160** | |
