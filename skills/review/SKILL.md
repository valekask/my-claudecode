---
name: review
description: Checklist-driven review of code changes before PR with FNA-UI quality standards. Use when ready to review changes.
---

# Code Review

Checklist-driven review with parallel agents. 146 checks across 10 checklists (naming, clean code, defensive programming, architecture, data flow, state management, regressions, security, test quality, styling) plus end-to-end data flow tracing.

**Workflow:** Scope → Plan → Check (flag broadly) → Investigate (verify with full context) → Summary

## CRITICAL RULES

1. **Report only.** Do NOT fix issues automatically. Present findings for human review.
2. **Execute phases in order.** Scope → Plan → Check → Investigate → Summary.
3. **Every finding needs evidence.** File:line reference, what's wrong, impact.
4. **No false positives.** If unsure whether something is a real issue, mark it as a **Question** not a finding.

---

## Phase Tracking

Create all phase tasks upfront using TaskCreate. This shows progress in the terminal.

```python
TaskCreate(subject="Phase 1: Scope", description="Get diff, collect changed files", activeForm="Collecting changes")
TaskCreate(subject="Phase 2: Plan", description="Determine which agents to activate", activeForm="Planning review")
TaskCreate(subject="Phase 3: Check", description="Flag findings broadly with checking agents", activeForm="Running checking agents")
TaskCreate(subject="Phase 4: Investigate", description="Verify raw findings with full context", activeForm="Investigating findings")
TaskCreate(subject="Phase 5: Summary", description="Deduplicate, generate report", activeForm="Generating report")
```

**Each phase MUST:**
1. `TaskUpdate(taskId=phase_id, status="in_progress")` before starting
2. Do its work
3. `TaskUpdate(taskId=phase_id, status="completed")` when done

---

## Phase 1: SCOPE

Determine what to review.

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
| Agent 8: TRACING | Diff includes both a service/store AND a component, OR diff modifies an effect/reducer/selector, OR diff touches HTTP calls |
| Agent 9: TEST QUALITY | Any `.service.ts`, `.store.ts`, `.utils.ts`, `.pipe.ts`, `.directive.ts`, `.guard.ts`, or `.interceptor.ts` changed — OR any `.spec.ts` changed |
| Agent 10: STYLING | Any `.scss` or `.html` file changed |

### Lightweight mode

If ≤3 files changed AND no store/service files:
- **Always:** Agent 1+2+3 (if any `.ts` file) + Agent 7 (safety)
- **Add Agent 9** if any `.spec.ts` file changed
- **Add Agent 10** if any `.scss` or `.html` file changed
- **Skip:** Agent 4 (architecture), Agent 5 (data flow), Agent 6 (state management), Agent 8 (tracing)

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

**Checklist:** `defensive-programming.md` (16) = **16 checks**

**Focus:** Null/NaN guards, input validation, error handling, boundary conditions, date/time safety, output validity of recursive operations, Angular form validator correctness.

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

### Agent 8: TRACING

**No checklist.** This agent follows data flows end-to-end instead of checking rules.

**Input:** The changed files + their full source + imported files they depend on.

**Instructions for the tracing agent:**

```
You are tracing data flows through changed code in the FNA-UI Angular project.

## Changed Files
{diff output + full source of changed files}

## Instructions

### Step 1: List ALL flows (MANDATORY — complete this before tracing)

From the changed code, identify every flow. Output a numbered list using this template:

| # | Type | Flow name | Start point | End point |
|---|------|-----------|-------------|-----------|
| 1 | Data | {name} | {API call or source} | {template binding or consumer} |
| 2 | Interaction | {name} | {user event} | {UI update} |
| 3 | Error | {name} | {failure point} | {user-visible result} |

**Flow types to look for:**
- **Data flow**: Which data is fetched, where is it stored, how does it reach the template?
- **Interaction flow**: What user actions trigger changes, and how do those flow through handlers → store → UI update?
- **Error flow**: When an API call fails, what happens at each step?

**Minimum flow count:** You MUST identify at least one flow per changed service/store file. If the diff touches both a service/store AND a component, identify at least one data flow AND one interaction flow.

Do NOT proceed to Step 2 until this table is complete.

### Step 2: Trace each flow end-to-end

For EACH flow in the table above (do not skip any), walk through the actual source files:

1. **Start point**: API call or user event
2. **Each step**: Follow the data through service → effect/updater → state → selector → container → template
3. **End point**: What the user sees

At each step, check:
- Does the data shape match what the next step expects?
- Is the error case handled?
- Is loading state managed?
- Are there race conditions (e.g., user triggers action while previous is in flight)?
- Is cleanup handled (unsubscribe, cancel in-flight requests)?
- If the same API call or data operation appears in multiple code paths (e.g., single-item fetch vs batch refresh, initial load vs retry), is the error handling consistent? Flag when one path shows user-facing error feedback (notification, error state) and another silently swallows or skips.

### Step 3: Report

For each gap found, output:

### TRACE — short title
- **Flow**: {flow # and name from the table}
- **Gap at**: `path/to/file.ts:LINE`
- **Issue**: What breaks or is missing between steps (1-2 sentences)
- **Impact**: What the user sees when this breaks (1 sentence)
- **Fix**: How to close the gap (1-2 sentences)
- **Severity**: Critical | High | Medium | Low

**Severity rule for traces:** Always rate by USER-VISIBLE impact, not code-level severity. If a data flow gap causes wrong data displayed to users, that's Critical even if the code change looks small. Ask: "What will the user see when this breaks?"

If all flows are clean, output:

### TRACE — All flows verified
No gaps found in {N} traced flows: {list flow names}
```

### Agent 9: TEST QUALITY

**Checklist:** `test-quality.md` (14) = **14 checks**

**Focus:** Logic-test alignment. Reads both implementation AND spec files to verify tests actually cover the logic. Skips components.

**Scope:** Only `.service.ts`, `.store.ts`, `.utils.ts`, `.pipe.ts`, `.directive.ts`, `.guard.ts`, `.interceptor.ts` files and their corresponding `.spec.ts` files.
**Skip:** `.component.ts` files — components are containers/presenters; their logic belongs in services/stores.

**Input:** For each in-scope file pair: full source of implementation file + full source of spec file + diff of both.

**Instructions for the test quality agent:**

```
You are reviewing test quality for the FNA-UI Angular project.
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

### Agent 10: STYLING

**Checklist:** `styling.md` (12) = **12 checks**

**Focus:** Design system usage, CSS variables, Bootstrap utilities, selector specificity, property ordering.

**Input:** Diff of all changed `.scss` and `.html` files + checklist contents. Read `libs/ui/src/assets/scss/` variable files when checking if a hardcoded value exists in the design system. For ST-11 (Bootstrap deprecations), check both `.scss` class references and `.html` template class attributes.

### Checking agent prompt template (for agents 1, 2, 3, 4, 5, 6, 7, 10)

```
You are a checking agent reviewing code changes for the FNA-UI Angular project.
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
You are an investigation agent verifying flagged code review findings for the FNA-UI Angular project.
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

Merge all agent outputs into a single report.

### Step 5.1: Deduplicate

Merge CONFIRMED findings that describe the same underlying problem:
- Same file:line confirmed by multiple agents → merge into one finding (keep the highest severity and most impactful description)
- Same root cause across multiple files (e.g., "duplicated pattern in 9 components" + "logic in component instead of selector") → merge into one finding, list all affected files
- When merging, prefer the TRACING agent's framing (user-visible impact) over checklist agents' framing (rule violation)
- FALSE_POSITIVE items: include in the Dismissed Findings section (both notable passes and routine dismissals)
- QUESTION items: include in the Questions section

### Step 5.2: Generate report

```markdown
# Code Review Report

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
{Only include when Agent 9 (Test Quality) was activated. Summarize aggregate test coverage patterns across all reviewed files — this is the holistic view, not individual findings (those stay in Findings above).}

{List systemic test gaps as bullet points, e.g.:}
- {pattern} untested in {N} stores/services
- {file} has only {N} meaningful test covering {what}; {list of untested branches}
- {selectors/utilities} have zero test coverage

## Data Flow Traces
{Summary of traced flows — gaps found or all clean}

## Review Coverage

| Agent | Checks | Passed | Failed | Notes |
|-------|--------|--------|--------|-------|
| NAMING | 12 | X | X | {brief summary or "All passed"} |
| CLEAN CODE | 26 | X | X | {brief summary or "All passed"} |
| DEFENSIVE | 15 | X | X | {brief summary or "All passed"} |
| ARCHITECTURE | 13 | X | X | {brief summary or "All passed"} |
| DATA FLOW | 14 | X | X | {brief summary or "All passed"} |
| STATE MGMT | 14 | X | X | {brief summary or "All passed"} |
| SAFETY | 25 | X | X | {brief summary or "All passed"} |
| TRACING | {N flows} | {clean flows} | {gaps + questions} | {brief summary} |
| TEST QUALITY | 13 | X | X | {brief summary or "All passed"} |
| STYLING | 12 | X | X | {brief summary or "All passed"} |

{Only include rows for activated agents. "Failed" = confirmed findings, not raw flags.}

## Dismissed Findings
{Only include FALSE_POSITIVE verdicts that were flagged with HIGH confidence during checking. These are findings that looked clearly wrong but turned out fine — showing the review was thorough. Skip MEDIUM and LOW confidence dismissals.}

- **[CHECK-ID]** {what was flagged} — **Reason:** {why it's not an issue, referencing full context}

## Summary

| # | Type | Issue | Severity |
|---|------|-------|----------|
| 1 | {CATEGORY or TRACE} | {short description} | Critical/High/Medium/Low |
| 2 | {CATEGORY: ID} | {short description} | Critical/High/Medium/Low |
| ... | | | |

**Ready to merge?** [Yes / No / With fixes]

**Reasoning:** {1-2 sentence technical assessment}
```

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
- `4. [TRACE] Daily mode detection broken for multi-currency`

---

## Agents Overview

| Agent | Phase | Checklists | Checks | When |
|---|---|---|---|---|
| 1: NAMING | Check | naming | 12 | Any `.ts` file |
| 2: CLEAN CODE | Check | clean-code | 26 | Any `.ts` file |
| 3: DEFENSIVE PROGRAMMING | Check | defensive-programming | 16 | Any `.ts` file |
| 4: ARCHITECTURE | Check | architecture | 13 | Component/service/store/module/directive/infra files |
| 5: DATA FLOW | Check | data-flow | 14 | Component/service/store/module/infra files |
| 6: STATE MANAGEMENT | Check | state-management | 14 | Store files or `@ngrx` imports |
| 7: SAFETY | Check | regressions + security | 25 | Always |
| 8: TRACING | Check | (trace-based, no checklist) | — | Service/store + component in same diff, or effects/HTTP touched |
| 9: TEST QUALITY | Check | test-quality | 14 | Service/store/util/pipe/directive/guard/interceptor or spec files changed |
| 10: STYLING | Check | styling | 12 | Any `.scss` or `.html` file changed |
| Investigation | Investigate | (verifies raw findings) | — | Always (after Check phase) |
| **Total** | | 10 checklists | **146** | |
