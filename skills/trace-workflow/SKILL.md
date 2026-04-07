---
name: trace-workflow
description: Trace functions for decision-point correctness — finds inconsistent conditional branches, missing cases, nullish gaps, and cross-function mismatches. Use during implementation or review to verify logic.
---

# Trace Workflow

Branch-level correctness verification. Finds bugs that flow-level tracing misses — inconsistent sibling branches, missing cases, nullish gaps, dead branches, and cross-function branch mismatches.

**Rule:** Report only. Do NOT fix issues automatically. Present findings for human review.

---

## Scoping

Determine what to trace based on user input:

| Input | Action |
|-------|--------|
| No args | `git diff` (unstaged changes) |
| `--staged` | `git diff --cached` |
| `--branch` | `git diff main...HEAD` |
| `path/to/file.ts` | All decision points in that file |
| `path/to/file.ts:functionName` | Decision points in that specific function |

**Important:** When working from a diff, identify which functions contain changes, then read the **full source** of those functions. You need all sibling branches for comparison, not just the changed lines.

---

## Analysis (internal — do NOT output)

The following steps are your reasoning process. Perform them thoroughly but do NOT include their output in the report. Only output the final report (Step 4).

### Step 1: INVENTORY

Enumerate every decision point in the target code. A decision point is any place where code takes one of multiple paths based on a condition.

**What to look for:**

- `if / else if / else` chains
- `switch / case / default` blocks
- Ternary expressions (`condition ? a : b`)
- Type narrowing checks (`type === 'X'`, `instanceof`, `in` operator)
- Optional chaining that implies a nullish path (`obj?.prop` — what happens when `obj` is nullish?)
- `catchError` / `catch` blocks (the error path vs the success path)
- Guard clauses (early returns)
- Logical operators used for branching (`value || fallback`, `value && action`)
- RxJS conditional operators (`filter`, `takeWhile`, `iif`)

Build a numbered inventory of all decision points with function name, location, decision type, and branch count.

**Completeness check:** Before proceeding, verify you haven't skipped any decision points. Scan the code one more time.

### Step 2: CONDITION MATRIX

For EACH decision point in the inventory, build a condition matrix capturing:

1. **What condition triggers this branch?**
2. **What inputs does this branch use?**
3. **What does this branch produce/do?**
4. **Can any of the inputs be null/undefined?**

**For nullish risk assessment**, evaluate realistically:
- Where does the input come from? (API response, form control, store state, function parameter)
- Is the type nullable? (`| null`, `| undefined`, optional `?`)
- Is there an upstream guard that guarantees non-null?
- If the input comes from an external source (API, user input), assume it CAN be nullish unless explicitly validated upstream

### Step 3: CROSS-CHECK

For each decision point's matrix, systematically check for these four issue types:

#### 3.1 Asymmetry

Compare sibling branches. If one branch applies a transformation, check that all sibling branches that handle the same kind of input apply it too.

**Questions to ask:**
- Does branch A format/quote/transform a value that branch B uses raw?
- Does branch A validate an input that branch B assumes is valid?
- Does branch A handle an edge case (empty string, zero, negative) that branch B ignores?
- If a helper function exists, do all branches that should use it actually use it?

#### 3.2 Missing branch

Check for input combinations that have no explicit handling:

- `if/else if` chain with no `else` — what happens for values that don't match any condition?
- `switch` with no `default` — are all possible values of the discriminant covered?
- Enum-based branching — are all enum members handled?
- Boolean conditions — is only the truthy case handled?

#### 3.3 Nullish gap

Using nullish risk from the matrix:

- For each input flagged as potentially nullish, is there a null check before use?
- Property access chains (`a.b.c.d`) — can any intermediate be null?
- Array access (`arr[i]`) — can the array be empty or the index out of bounds?
- Values from maps/objects (`map.get(key)`, `obj[key]`) — what if the key doesn't exist?

**Do NOT flag nullish gaps where:**
- TypeScript strict types guarantee non-null (and the type is not `any`)
- An upstream guard already checks for null
- The value comes from a source that provably cannot be null

#### 3.4 Dead branch

Check for branches that can never execute:

- Condition is a subset of a previous condition in the chain
- Type narrowing makes a branch unreachable
- Constant value makes condition always true/false

### Step 3.5: CROSS-FUNCTION CHECK

After completing per-function analysis, check for branch mismatches **between** functions in the diff:

**When to perform:** Only when the diff touches:
- Return types or return values of functions
- Enum/union type definitions
- Functions that add new branches producing new output shapes

**What to check:**
- If function A was changed to return a new shape (new branch, new enum value, added `| null`), find callers of A within the diff scope and check they handle the new shape
- If an enum/union type gains a new member, check all switch/if chains on that type
- If a function's return type now includes `null`/`undefined` where it didn't before, check callers for null handling

**Track:** Count how many cross-function checks you performed and how many issues were found. Tag any findings from this step with `[cross-function]`.

---

## Step 4: REPORT (this is the only output)

Only report **Critical** and **High** severity findings. Skip Medium and Low entirely.

### Severity rules

| Severity | Criteria |
|----------|----------|
| Critical | Wrong data displayed, data corruption, security issue |
| High | Silent failure, feature doesn't work for specific input |
| Medium | (do not report) Edge case that's unlikely but produces wrong behavior |
| Low | (do not report) Dead code, unreachable branch, cosmetic inconsistency |

### Clean report

If all decision points pass cross-checks:

```
TRACE: {N} decision points across {M} functions — all clean.
```

### Issues found report

```
TRACE: {N} decision points across {M} functions — {X} issues.

### TRACE-1: {short descriptive title}
`file.ts:LINE` — `functionName`, branch `condition`
{What's wrong — 1-2 sentences. Be specific about the missing/inconsistent transformation.}
{What the user sees when this breaks — 1 sentence.}
Fix: {How to fix — 1-2 sentences.}
⚠ Confidence: {only if uncertain — e.g., "check whether X is validated upstream before fixing"}

### TRACE-2: {title} [cross-function]
`file.ts:LINE` — `functionName`, branch `condition`
...
```

**Group findings by function** — keep findings for the same function adjacent so a downstream agent can fix them in one pass.

**Confidence notes:** Add `⚠ Confidence:` only when the skill cannot determine full context — e.g., unclear whether an upstream guard exists, or a type comes from an external package. Omit when confident.

**Cross-function tag:** Append `[cross-function]` to the title of any finding discovered via cross-function checking (Step 3.5).

### Footer

Always end with:

```
Cross-function checks: {N} performed, {X} issues found.
```

Omit this line if no cross-function checks were performed (i.e., the diff didn't touch return types, enums, or output shapes).
