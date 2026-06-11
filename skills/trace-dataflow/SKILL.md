---
name: trace-dataflow
description: Trace data, interaction, and error flows end-to-end through changed code — finds data-shape mismatches between steps, unhandled error/loading states, race conditions, missing cleanup, and inconsistent error handling across paths. Use when a change spans a service/store and a component, touches effects/reducers/selectors, or modifies HTTP calls.
effort: xhigh
---

# Trace Data Flow

End-to-end flow verification. Follows each data/interaction/error flow through the actual source — service → effect/updater → state → selector → container → template — and checks that the pieces line up at every step. This catches integration gaps that branch-level tracing (`trace-workflow`) and rule checklists miss: a value the service returns in one shape but the template reads in another, an error path that silently swallows, a loading state that never clears.

**Rule:** Report only. Do NOT fix issues automatically. Present findings for human review.

**Relationship to `trace-workflow`:** complementary, not overlapping. `trace-workflow` verifies *branch-level* decision correctness within and across functions (asymmetric siblings, missing cases, nullish gaps, dead branches). `trace-dataflow` verifies *flow-level* integration across layers. Run `trace-dataflow` when a change crosses layer boundaries; run `trace-workflow` when a change adds or modifies conditional logic.

---

## When to Run

This skill earns its cost when the change crosses layers. Run it when **any** of these are true:

- The diff touches both a service/store **and** a component
- The diff modifies an effect, reducer, or selector
- The diff touches HTTP calls

For changes that stay within a single function or layer, prefer `trace-workflow` or a rule-based review instead.

---

## Scoping

Determine what to trace based on user input:

| Input | Action |
|-------|--------|
| No args | `git diff` (unstaged changes) |
| `--staged` | `git diff --cached` |
| `--branch` | `git diff main...HEAD` |
| `path/to/file.ts` | Flows originating in or passing through that file |

**Important:** When working from a diff, read the **full source** of the changed files plus the files they depend on (the service the component calls, the selector the container reads, the effect the action triggers). You are tracing across files — the diff alone is not enough.

---

## Analysis (internal — do NOT output Steps 1-2)

Steps 1 and 2 are your reasoning process. Perform them thoroughly, but only output the final report (Step 3).

### Step 1: List ALL flows (MANDATORY — complete before tracing)

From the changed code, identify every flow. Output a numbered list using this template:

| # | Type | Flow name | Start point | End point |
|---|------|-----------|-------------|-----------|
| 1 | Data | {name} | {API call or source} | {template binding or consumer} |
| 2 | Interaction | {name} | {user event} | {UI update} |
| 3 | Error | {name} | {failure point} | {user-visible result} |

**Flow types to look for:**

- **Data flow** — which data is fetched, where is it stored, how does it reach the template?
- **Interaction flow** — what user actions trigger changes, and how do those flow through handlers → store → UI update?
- **Error flow** — when an API call fails, what happens at each step?

**Minimum flow count:** identify at least one flow per changed service/store file. If the diff touches both a service/store **and** a component, identify at least one data flow **and** one interaction flow.

Do NOT proceed to Step 2 until this list is complete.

### Step 2: Trace each flow end-to-end

For EACH flow in the list (do not skip any), walk through the actual source files:

1. **Start point** — API call or user event
2. **Each step** — follow the data through service → effect/updater → state → selector → container → template
3. **End point** — what the user sees

At each step, check:

- Does the data shape match what the next step expects?
- Is the error case handled?
- Is loading state managed?
- Are there race conditions (e.g., user triggers an action while a previous one is in flight)?
- Is cleanup handled (unsubscribe, cancel in-flight requests)?
- If the same API call or data operation appears in multiple code paths (single-item fetch vs batch refresh, initial load vs retry), is error handling **consistent**? Flag when one path shows user-facing error feedback (notification, error state) and another silently swallows or skips.

---

## Step 3: REPORT (this is the only output)

For each gap found, output:

### TRACE — short title
- **Flow**: {flow # and name from the list}
- **Gap at**: `path/to/file.ts:LINE`
- **Issue**: What breaks or is missing between steps (1-2 sentences)
- **Impact**: What the user sees when this breaks (1 sentence)
- **Fix**: How to close the gap (1-2 sentences)
- **Severity**: Critical | High | Medium | Low

**Severity rule:** Always rate by USER-VISIBLE impact, not code-level severity. If a data-flow gap causes wrong data displayed to users, that's Critical even if the code change looks small. Ask: "What will the user see when this breaks?"

| Severity | Criteria |
|----------|----------|
| Critical | Wrong data displayed, data loss, data corruption, security breach |
| High | Broken contract between layers, race condition with visible effect, unhandled error that crashes or silently fails |
| Medium | Missing loading state, edge case with degraded but non-broken behavior |
| Low | Cosmetic inconsistency, minor cleanup gap with no user-visible effect |

### Clean report

If all flows trace cleanly:

```
TRACE — All flows verified
No gaps found in {N} traced flows: {list flow names}
```
