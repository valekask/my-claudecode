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

Inspect the diff (`git diff` / changed file types) and choose gates. Do NOT run everything every time. State which gates you're running and why. You report the full **review ledger** at the end (in `review.md`, Step 6, and as the Gates table in chat, Step 7) — every gate listed, ran or skipped — so each gate you skip needs a stated reason its trigger didn't fire. Silence is not an option.

| Gate | Run when |
|------|----------|
| **Primary code reviewer** (see below) | **Always** — the baseline correctness review |
| **`/security-review`** (built-in) | Diff touches security-sensitive surface: auth, guards, interceptors, input handling, secrets, external HTTP, file/URL handling |
| **`trace-workflow`** | Diff adds or modifies conditional logic (branches/switches/guards in services, stores, utils, effects, reducers, selectors) |
| **`trace-dataflow`** | Diff crosses layers: service/store **and** component, or effects/reducers/selectors, or HTTP calls |
| **`checklist-review`** (project-specific Angular agents) | Larger or architectural changes (roughly 9+ files, or structural component/service/store/module changes). Skip for small, generic diffs — the primary reviewer + built-ins cover that ground |
| **`checklist-review --only=module-design`** | Medium diffs (roughly 4–8 files) that add or restructure component, service, store or `.utils.ts` logic, when the full `checklist-review` isn't selected (it already includes this agent). Skip for small or mechanical diffs |
| **`/simplify`** (simplification pass — **surface-only**) | Diff adds or substantially changes logic. Skip for trivial or config-only diffs. **Run it review-only** — collect its proposals; do NOT let it mutate code here. Its findings are always *surfaced*, never auto-applied (simplification is judgment-level — see Step 5) |

#### Primary code reviewer (pluggable)

The primary reviewer is **configurable** — currently being evaluated. Two options:

- **CodeRabbit** (`coderabbit:coderabbit-review`) — different engine (independent signal), tuned with project-specific custom rules.
- **Built-in `/code-review`** — Claude-based, effort-tunable (low→max; pick by risk), broader scope (bugs + reuse/simplification), no external dependency. Invoke the **built-in** skill — not the plugin skill named `coderabbit:code-review`, which is a different reviewer despite the similar name.

**Default:** CodeRabbit, unless the user specifies otherwise (e.g., `polish --reviewer=builtin`).

**CodeRabbit must see new files.** Run it as `coderabbit review --agent --uncommitted --include-untracked`. Without `--include-untracked` it reviews tracked changes only, so every new file of the change — a new module, a new spec, the ADR — goes unreviewed while the ledger still reports "0 findings". Never `git add` to work around this; the flag is the fix.

**Effort level (built-in reviewer only).** The built-in reviewer takes an effort level — `/code-review low` through `max`. **Judge the level from the diff, don't just count files.** The table is the starting point; risk overrides it.

| Diff shape | Start at |
|---|---|
| ≤3 files, no service/store logic, no security-sensitive surface | `low` |
| 4–8 files, or any service/store/effect logic | `medium` |
| 9+ files, structural component/service/store/module changes, or security-sensitive surface (auth, guards, interceptors, input handling, secrets, external HTTP) | `high` |
| Complex multi-layer change (component + store + HTTP in one diff), persisted-state/schema migration, or non-trivial logic on a security-sensitive surface | `xhigh` |
| Highest-consequence work: auth/permission logic, data migrations that can corrupt or lose data, money/currency math, or any change that is hard to roll back — plus a final pass over a large feature branch before PR | `max` |

Escalate a level above the table when the diff is small but consequential — a two-line change to an auth guard, a persisted-state migration, or anything whose failure is silent rather than loud. Drop to `low` for mechanical diffs (renames, config, generated code) regardless of file count. **State the level you picked and why** as part of announcing your gate selection.

The only cost of a higher level is time and tokens, and it does not widen what polish will change on its own — the Step 5 triage rules (High/Critical + high confidence + mechanical) still bound auto-fix, so deeper review produces more *surfaced* findings, not more autonomous mutation. Prefer going a level up when genuinely unsure.

Under `--compare`, pin the built-in reviewer to `medium` — comparing it against CodeRabbit is meaningless if its effort varies between runs.

**Compare mode** (opt-in, e.g. `polish --compare`): run **both**, then report each reviewer's findings side by side, highlighting **unique catches** (what each found that the other missed) and overlap. Use this to evaluate which reviewer gives better signal on this codebase before standardizing on one. Note: compare mode is for evaluation — don't run both as the steady state (double latency/noise).

### Step 4: Run gates and collect findings

The selected gates are independent reviewers, so **dispatch them concurrently** — launch them in a single batch rather than one after another, and gather findings as they return. (Some gates, like `checklist-review`, fan out their own internal agents; that's fine — they parallelize underneath.) Collect all findings into one list with: source gate, file:line, severity, and confidence.

**Dispatch each gate as a subagent with an explicit model and effort** — set them on the Agent call, never leave them to the session default. A gate's depth should match the kind of thinking it does, not whatever effort the session happens to run at:

| Gate | Model | Effort | Why |
|------|-------|--------|-----|
| `trace-workflow`, `trace-dataflow` | session (Opus) | `xhigh` | deep reasoning across functions and layers — where the subtle bugs are |
| `/security-review` | session (Opus) | `high` | low volume, high consequence |
| `checklist-review` | session (Opus) | `medium` | orchestrates and merges; it sets its own per-agent levels inside |
| `checklist-review --only=module-design` | session (Opus) | `medium` | one judgment agent reading across files |
| `/simplify` | session (Opus) | `medium` | judgment-level proposals, surfaced only |
| Primary reviewer — CodeRabbit | `sonnet` | `medium` | runs an external tool and parses its output |
| Primary reviewer — built-in `/code-review` | session | its own level (the table above) | the level argument controls its depth |

The subagent invokes the gate's skill through the Skill tool, so a skill's own `effort:` still applies while it runs — keep the two in step.

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
- It is a **simplification proposal** from `/simplify` — these are always surfaced for human review, never auto-applied here (simplification is judgment-level)

**Every finding at Medium or above — auto-fixed or surfaced — is written up so the user can decide without opening code or the app.** Confirm it by reading the code first; a finding you cannot confirm drops to Low, marked `unconfirmed`. Then give it:

- **Kind** — `Bug` (wrong behaviour, crash, data loss, security, a broken AC) or `Improvement` (everything else: structure, reuse, simplification, style). `/simplify` proposals are always `Improvement`.
- **Severity** — Critical / High / Medium.
- **Problem** — what goes wrong for the user or the code, and when, in one plain sentence. No gate jargon, no checklist ids.
- **Fix** — the concrete change you propose (what, and where in words), one sentence. For an auto-fixed item: what you changed.
- **Size** — small / medium / large.
- **Recommend** — `fix now`, `later` (out of scope — a follow-up), or `skip` (not worth it), plus a few words why.
- **Status** — the item's current state: `open` (surfaced, not decided), `fixed`, `later`, `skip` or `accepted`. An auto-fixed item starts as `fixed`; a surfaced one as `open`. Recommend is polish's opinion; Status is what actually happened, and only a fix or the user's reply changes it.

**Bounded loop:** after applying fixes, re-run the relevant gate **and the build** (or re-check the specific findings) to confirm they're resolved and nothing regressed. Max **3** fix→recheck iterations per gate; if findings persist, stop and surface them — something needs human input.

### Step 6: Persist the full report

Save **all** findings (every severity, fixed and surfaced) to `.claude/temp/<task>-<slug>/<task>-<slug>-review.md`, led by the **review ledger** (the prose list below) so the record on disk shows what ran and what was skipped, not just the findings. Number the Medium-and-above findings `1..n` in the same order and with the same numbers as the chat report (Step 7), and keep each gate's own id (`ST-3`, `CR-2`, …) and `file:line` next to it in the file — the file is the traceable record, the chat is the decision view.

**Carry decisions forward.** When `review.md` already exists from an earlier run, read it before writing. A new finding that matches an earlier item (same problem at the same place) keeps that item's number and Status — a `later`, `skip` or `accepted` item is not reopened. The one exception: an item marked `fixed` that is found again is a regression — set it back to `open` and say "came back after its fix" in its Problem line. Findings with no match get new numbers after the highest existing one.

**Every Medium-and-above item carries a `**Status:**` line in `review.md`, and the file is updated in place, never appended to.** When a later round fixes or decides an item, change that item's Status (and, for a fix, its Changed line) where it is — don't add a "Fix round" section, a "Fixed after go-ahead" section, or a second review on top. One item, one place, one current Status. A one-line round log at the very end (`Round 2 — 2026-11-12: fixed 2, 3; build ✓; tests ✓`) records history; status lives only on the items. This is the record you mine later to tune the reviewer's rules and the checklists — don't drop the Low/Medium items just because they weren't auto-fixed.

**The review ledger (in the file)** — every gate listed in this order, each as a short prose line (not a table, so nothing interesting gets squeezed out): **status** + the info that matters for that gate. For a gate that ran, give its result — findings count, notable catches, what was auto-fixed vs surfaced. For a skipped gate, give the reason its trigger didn't fire. Every gate appears exactly once, even when skipped.

1. **Primary reviewer** — always runs; name which one actually ran per the chosen option (CodeRabbit by default, the built-in `/code-review` under `--reviewer=builtin`, or both under `--compare`) and report its findings and notable catches. When the built-in reviewer ran, state the **effort level** used and the reason for it — the level is part of the record, since it bounds how much the gate could have caught.
2. **checklist-review** — ran (result) or skipped (why, e.g. small generic diff below the threshold).
3. **trace-workflow** — ran (result) or skipped (why, e.g. no conditional logic touched).
4. **trace-dataflow** — ran (result) or skipped (why, e.g. change stays within one layer).
5. **`/security-review`** — ran (result) or skipped (why, e.g. no security-sensitive surface).
6. **`/simplify`** — ran (result: simplification proposals surfaced) or skipped (why, e.g. trivial/config-only diff). Proposals are surfaced, never auto-applied.

### Step 7: Report in chat and hand off

The chat report is the **decision view**: the user reads it instead of `review.md`, so it must be enough to decide without opening code or the app. Emit exactly this shape, as the last thing in the turn, nothing before it:

````markdown
## ✅ Auto-fixed (1)

**1. Bug · High**
**Problem:** Spinner overlay stays on after an auto-refresh and blocks clicks.
**Changed:** clear the loading flag when a normal reload starts.
**Check:** auto-refresh on, then change page size.

---

## 🚩 Needs you (2)

**2. Bug · Medium**
**Problem:** With page size 5000, every refresh re-sends the rejected request and the loader flashes.
**Fix:** skip the reload when only the time border changed.
**Size:** small
**Fix now:** breaks AC-10.

---

**3. Improvement · Medium**
**Problem:** Row-limit helper duplicated in two components.
**Fix:** move it into the shared utils file.
**Size:** small
**Later:** out of scope.

---

+11 low in `<abs path to review.md>` · Reply `fix 2`, `fix recommended`, or `accept`.

## Gates

| Gate | Ran | Result |
|---|---|---|
| CodeRabbit | ✓ | 0 findings |
| Checklist | ✓ | 1 high, 11 low |
| Trace workflow | ✓ | 2 medium |
| Trace dataflow | ✓ | 1 high (fixed), 2 medium |
| Security | – | skipped: no auth / HTTP change |
| Simplify | ✓ | 8 ideas, 1 recommended |

Build ✓ · Unit tests ✓ 5120/5120

Ready for verify once 2 is settled.
````

Rules for the report:
- **Order:** `## ✅ Auto-fixed (n)`, then `## 🚩 Needs you (n)`, then the footer line, then `## Gates`, then the build/test line, then one closing line on what happens next.
- **Items are a list, never a table.** Each item is a block: a bold `**<n>. <Kind> · <Severity>**` line, then one bold-labelled line per field — auto-fixed: `**Problem:**`, `**Changed:**`, `**Check:**` (what to look at during verify); needs-you: `**Problem:**`, `**Fix:**`, `**Size:**`, then the recommendation as its own bold label — `**Fix now:**`, `**Later:**` or `**Skip:**` — followed by the reason. A `---` line after every item.
- **Numbering:** one plain sequence `1..n` across both sections, matching `review.md`, so the user can point at an item. Never gate ids (`ST-3`, `CR-2`, …), never `file:line` in chat.
- **Needs you lists only items whose Status is `open`.** Items already decided (`fixed`, `later`, `skip`, `accepted`) stay in `review.md` and leave the chat report.
- **Only Medium and above** appear as items; Low is a count in the footer. A `/simplify` proposal appears only when its recommendation is `Fix now`.
- **Plain words:** the Problem says what goes wrong for the user and when, not which rule fired. Long is fine when the scenario needs it; jargon is not.
- **Gates table:** one row per gate, every gate, in the ledger order; the primary-reviewer row names the reviewer that ran (and the built-in reviewer's effort level). `✓` ran, `–` skipped (reason in Result), `✗` failed to run (reason in Result). The build/test line reports only what polish actually ran.
- An empty section keeps its heading with one line under it: `None.` / `None — ready to verify.`
- Replies, and the Status each one sets in `review.md`: `fix <numbers>` → `fixed`; `fix recommended` → every `open` item recommended `Fix now` becomes `fixed`; `later <numbers>` → `later`; `skip <numbers>` → `skip`; `accept` → every remaining `open` item becomes `accepted`. After any fix, re-run the build and the touched unit tests, update the items' Status in place, and re-emit the report.

End with the handoff: the change is ready for **manual verification + smoke test**; `ship` comes after.

## Red Flags

**Never:**
- Auto-apply Medium/Low findings or anything needing judgment — surface them
- Run all gates indiscriminately — select by risk and say why
- Run the built-in reviewer without deliberately choosing an effort level — judge it from the diff and state the choice
- Report only the gates that ran — every gate appears in the review ledger, skipped ones with a reason
- Loop fix→recheck more than 3 times on one gate — escalate instead
- Drop Low/Medium findings from the saved report
- Surface a Medium-or-above finding without a confirmed Problem, a concrete Fix and a Recommend — the user should never have to open the code to decide
- Put Low items, gate ids or `file:line` in the chat report
- Perform any git operations (no add, no commit) — that's `ship`, and only after verification
- Treat polish as the end — manual verification still happens after it
