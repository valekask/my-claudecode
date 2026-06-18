---
name: polish
description: Pre-verification quality pass on a completed change — formats, selects and runs the right quality gates for the risk, and auto-applies only meaningful, high-confidence fixes. Use after execution and BEFORE manual verification / smoke test. Mutates code; does not commit or write docs.
---

# Polish

The **mutation phase** of the workflow. Run it after execution and **before** manual verification + smoke test, so verification happens on clean, gated code. Polish formats, picks the right gates for the change, runs them, and auto-applies only the findings that are clearly worth fixing — surfacing everything else for the human.

**Announce at start:** "I'm using the polish skill to format, run quality gates, and apply safe fixes before verification."

**Runs only when you invoke it** — never proactively. It performs the formatting / build / review gate your workflow otherwise does by hand, so it must be an explicit request.

**Core principle:** Polish is the only phase that changes code after execution. Because manual verification runs *after* polish, polish must leave the code in a state worth verifying — and must NOT silently make changes that need re-thinking. Safe, mechanical fixes auto-apply; anything needing judgment is surfaced, not applied.

## Why this runs before verification

If auto-fix ran *after* you manually verified, your verification would be stale — the code changed underneath it. Polish front-loads all mutation so the sequence is: **execution → polish (mutate) → manual verify + smoke (on clean code) → ship (no code changes)**.

## The Process

### Step 1: Format

Run the `formatting` skill on the changed files first, so the gates review formatted code (avoids churn between formatting and review).

### Step 2: Build

Run the project's **full build** to verify the whole project still compiles/packages (e.g., `mvn package`; for an Nx/Angular project, the project's build / `tsc` command). If the build fails, **stop and surface it** — there's no point reviewing or shipping a change that doesn't build.

### Step 3: Select gates (risk-proportional — announce your choice)

Inspect the diff (`git diff` / changed file types) and choose gates. Do NOT run everything every time. State which gates you're running and why. You report the full **review ledger** at the end (Step 7) — every gate listed, ran or skipped — so each gate you skip needs a stated reason its trigger didn't fire. Silence is not an option.

| Gate | Run when |
|------|----------|
| **Primary code reviewer** (see below) | **Always** — the baseline correctness review |
| **`/security-review`** (built-in) | Diff touches security-sensitive surface: auth, guards, interceptors, input handling, secrets, external HTTP, file/URL handling |
| **`trace-workflow`** | Diff adds or modifies conditional logic (branches/switches/guards in services, stores, utils, effects, reducers, selectors) |
| **`trace-dataflow`** | Diff crosses layers: service/store **and** component, or effects/reducers/selectors, or HTTP calls |
| **`checklist-review`** (project-specific Angular agents) | Larger or architectural changes (roughly 9+ files, or structural component/service/store/module changes). Skip for small, generic diffs — the primary reviewer + built-ins cover that ground |

#### Primary code reviewer (pluggable)

The primary reviewer is **configurable** — currently being evaluated. Two options:

- **CodeRabbit** (`coderabbit:coderabbit-review`) — different engine (independent signal), tuned with project-specific custom rules.
- **Built-in `/code-review`** — Claude-based, effort-tunable (low→max; pick by risk), broader scope (bugs + reuse/simplification), no external dependency.

**Default:** CodeRabbit, unless the user specifies otherwise (e.g., `polish --reviewer=builtin`).

**Compare mode** (opt-in, e.g. `polish --compare`): run **both**, then report each reviewer's findings side by side, highlighting **unique catches** (what each found that the other missed) and overlap. Use this to evaluate which reviewer gives better signal on this codebase before standardizing on one. Note: compare mode is for evaluation — don't run both as the steady state (double latency/noise).

### Step 4: Run gates and collect findings

The selected gates are independent reviewers, so **dispatch them concurrently** — launch them in a single batch rather than one after another, and gather findings as they return. (Some gates, like `checklist-review`, fan out their own internal agents; that's fine — they parallelize underneath.) Collect all findings into one list with: source gate, file:line, severity, and confidence.

### Step 5: Triage and auto-fix (bounded, meaningful-only)

For each finding, classify:

**Auto-apply** only when ALL hold:
- **Confidence:** High (clearly a real issue, not a maybe)
- **Severity:** Critical or High (correctness, security, user-visible behavior)
- **Fix safety:** mechanical and well-scoped — a single clear change, no architectural or spec-interpretation judgment

**Surface, do NOT auto-fix** when any hold:
- Medium or Low severity (style, naming, smells, doc gaps)
- Low/uncertain confidence
- The fix needs design judgment, touches architecture, changes behavior, or reinterprets the spec

**Bounded loop:** after applying fixes, re-run the relevant gate **and the build** (or re-check the specific findings) to confirm they're resolved and nothing regressed. Max **3** fix→recheck iterations per gate; if findings persist, stop and surface them — something needs human input.

### Step 6: Persist the full report

Save **all** findings (every severity, fixed and surfaced) to `.claude/temp/<task>-<slug>/<task>-<slug>-review.md`, led by the **review ledger** (Step 7) so the record on disk shows what ran and what was skipped, not just the findings. This is the record you mine later to tune the reviewer's rules and the checklists — don't drop the Low/Medium items just because they weren't auto-fixed.

### Step 7: Summarize and hand off

Lead with the **review ledger** — every gate listed in this order, each as a short prose line (not a table, so nothing interesting gets squeezed out): **status** + the info that matters for that gate. For a gate that ran, give its result — findings count, notable catches, what was auto-fixed vs surfaced. For a skipped gate, give the reason its trigger didn't fire. Every gate appears exactly once, even when skipped.

1. **Primary reviewer** — always runs; name which one actually ran per the chosen option (CodeRabbit by default, the built-in `/code-review` under `--reviewer=builtin`, or both under `--compare`) and report its findings and notable catches.
2. **checklist-review** — ran (result) or skipped (why, e.g. small generic diff below the threshold).
3. **trace-workflow** — ran (result) or skipped (why, e.g. no conditional logic touched).
4. **trace-dataflow** — ran (result) or skipped (why, e.g. change stays within one layer).
5. **`/security-review`** — ran (result) or skipped (why, e.g. no security-sensitive surface).

Then:
- **Auto-fixed:** list each fix (file:line, what changed) — these need a fresh look during verification
- **Needs your attention before verify:** surfaced findings that polish did not fix, with severity
- Build/test status

End with the handoff: the change is ready for **manual verification + smoke test**; `ship` comes after.

## Red Flags

**Never:**
- Auto-apply Medium/Low findings or anything needing judgment — surface them
- Run all gates indiscriminately — select by risk and say why
- Report only the gates that ran — every gate appears in the review ledger, skipped ones with a reason
- Loop fix→recheck more than 3 times on one gate — escalate instead
- Drop Low/Medium findings from the saved report
- Perform any git operations (no add, no commit) — that's `ship`, and only after verification
- Treat polish as the end — manual verification still happens after it
