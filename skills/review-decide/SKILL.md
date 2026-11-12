---
name: review-decide
description: Decide what to do with each open review finding from evidence alone — fix, later, skip or needs-human, with the exact fix and the route it needs (local / wide / wrong-approach) — and write `<task>-<slug>-review-decisions.md`. Runs on Opus at max effort and reads only the spec, the evidence file and the code it points to — never the reviewer's recommendations or the author's notes. Changes no code. Use after `review-evidence`, by hand or as a step of an orchestrator's post-review pipeline.
model: opus
effort: max
---

# Review decide

The independent judge between "the evidence says" and "change the code". It replaces the moment a
human would open the code and the app to decide a finding.

**Announce at start:** "I'm using the review-decide skill to decide the open findings from evidence."

**Independence is the point.** Read only what is listed under Input. Polish's own recommendation,
the result file and the plan's rationale are the author's view — reading them anchors you. Reach your
own conclusion from the spec, the evidence and the code.

## Input

`review-decide <task>-<slug>` — the task folder `.claude/temp/<task>-<slug>/`:

- `<task>-<slug>-review-evidence.md` — the items and their facts. **Missing → stop**: run
  `review-evidence` first.
- `<task>-<slug>-spec.md` — what the change is supposed to do (scope, ACs, constraints).
- The code, ADRs and screenshots the evidence points to — read them yourself, don't trust the
  summary.

## Per item — decide

| Decision | When |
|---|---|
| `fix` | reproduced (or clearly true in the code) **and** inside the spec's scope or breaks an AC |
| `later` | real, but outside the spec's scope — a follow-up, not this change |
| `skip` | not reproduced, or real but not worth changing (cost exceeds harm) |
| `needs-human` | what the behaviour *should* be is a product or intent question the spec doesn't answer, or the evidence can't settle it and guessing would be user-visible |

`not reproduced` is `skip` unless the code itself shows the bug beyond doubt — then say so.
`could not check` is decided from the code when the code settles it; otherwise `needs-human`.

For every `fix`, give the **exact fix** (what changes, where, in words) and its **route**, from the
evidence's blast-radius counts:

- **`local`** — one spot, 0 callers outside the change, no shared code, no contract change.
- **`wide`** — shared code, a contract change, callers outside the change, or files outside the
  change. Needs the plan amended, not a patch.
- **`wrong-approach`** — the findings together show the design itself is off (fixes would fight the
  structure, or one fix reopens another). Needs a new plan.

When in doubt between two routes, pick the wider one.

## Output

Write `.claude/temp/<task>-<slug>/<task>-<slug>-review-decisions.md` (rename an earlier round's to
`<task>-<slug>-review-decisions.r<n>.md` first):

```markdown
# <task> — review decisions (round <n>, <YYYY-MM-DD>)

**Overall route:** local | wide | wrong-approach | needs-human   ← the widest across all items

## 2. <the finding, short>
- **Decision:** fix | later | skip | needs-human
- **Why:** <one or two sentences, citing the evidence>
- **Fix:** <exact change, in words> (fix only)
- **Route:** local | wide | wrong-approach (fix only)
- **Question for the human:** <one answerable question> (needs-human only)
```

End with exactly one line:

> Decisions saved to `<absolute path>`.

## Never

- Change code, tests or `review.md` — the fixer and the orchestrator own those.
- Read polish's recommendations, the result file's notes or the plan's rationale.
- Decide `fix` on an item nobody reproduced and the code doesn't prove.
- Turn a product question into a technical decision to avoid `needs-human`.
