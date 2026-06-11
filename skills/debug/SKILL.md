---
name: debug
description: Use when encountering any bug, test failure, or unexpected behavior. Finds root cause through collaboration and evidence before attempting fixes.
effort: xhigh
---

# Debug

## The Rule

```
NO FIXES WITHOUT ROOT CAUSE.
```

Do not propose fixes until you understand WHY the bug happens. Symptom fixes are failure.

## When to Use

Any technical issue: test failures, bugs, unexpected behavior, build failures, performance problems.

**Especially when:**
- "Just one quick fix" seems obvious
- You've already tried a fix and it didn't work
- You don't fully understand the system area

## The Process

### Phase 1: Understand — ASK FIRST

**Before reading code for more than 2 minutes, ask the user.**

The user knows their codebase. They can point you to the right area in seconds. Do not waste time exploring when a single question gets you there faster.

```
MANDATORY: Use AskUserQuestion within first 2 minutes of investigation.
Ask ONE question. Examples:
- "Which component/service handles [X]?"
- "Has this worked before, or is it new code?"
- "Any recent changes in this area?"
- "Do you have a suspicion where the problem might be?"
```

**Then gather evidence:**

1. **Read error messages completely** — stack traces, line numbers, error codes. Don't skip.
2. **Check recent changes** — `git diff`, `git log` for the affected area.
3. **Reproduce** — can you trigger it reliably? If not, gather more data.

### Phase 2: Trace Root Cause

**Trace backward, not forward.** Start from the error and work UP the call chain.

```
Symptom (error/wrong output)
  ← What produced this value?
    ← What called that with bad input?
      ← Where did the bad input originate?
        = ROOT CAUSE (fix here)
```

**Check for an ADR on this code.** If `docs/adr/README.md` exists, scan it for the area you're tracing. A non-obvious check or guard you're tempted to remove or "simplify" away may be load-bearing — the ADR's *Edge cases & non-obvious constraints* section says what it protects and what breaks without it. Don't remove a guard whose reason you haven't found.

**For multi-component systems — add diagnostic logging BEFORE deep analysis:**

At each component boundary, log what enters and exits. Run once to see WHERE it breaks, THEN investigate that specific component.

**Logging rules (MANDATORY):**
- Always use `JSON.stringify(value, null, 2)` for objects — never log raw objects
- Use labeled prefixes: `console.log('[DEBUG component-name]', JSON.stringify(data, null, 2))`
- Log BEFORE the operation, not after it fails
- In tests: use `console.error()` — `console.log()` may be suppressed

```typescript
// ✅ CORRECT — copy-paste friendly output
console.log('[DEBUG PaymentService.process]', JSON.stringify({
  input: payload,
  config: relevantConfig,
  timestamp: new Date().toISOString()
}, null, 2));

// ❌ WRONG — [object Object] in terminal
console.log('data:', data);
console.log('payload', payload);
```

**Ask the user before adding logging:**

> "I'd like to add diagnostic logging at [X, Y, Z boundaries] to trace where the data breaks. Want me to add those and you run it?"

### Phase 3: Confirm Understanding

Before proposing any fix, state your finding:

> "Root cause: [X] happens because [Y]. The fix should be at [Z]."

Wait for user confirmation. If the user disagrees or has additional context, incorporate it.

### Phase 4: Fix

1. **Single fix** — address the root cause, not the symptom. ONE change at a time.
2. **Verify** — run the failing test/reproduction. Does it pass?
3. **Check for regressions** — run related tests. Nothing else broken?

**If fix doesn't work:**
- 1-2 failed attempts: return to Phase 2, re-trace with new information
- 3+ failed attempts: **STOP.** Tell the user. This likely indicates an architectural issue or a wrong mental model. Discuss before trying again.

## When to Ask the User

Ask via AskUserQuestion (one question at a time) when:

- You've been reading code for >2 minutes without clarity
- You have two equally plausible root causes
- The stack trace leads into unfamiliar territory
- You need domain context (business rules, expected behavior)
- Your fix didn't work and you're not sure why
- 3+ fixes failed — discuss architecture before continuing

**Frame questions to help the user help you:**
```
❌ "I don't understand the code"
✅ "PaymentService calls both ProcessorA and ProcessorB — which one handles [currency type]?"

❌ "What should I do?"
✅ "I see two possible causes: [A] or [B]. Which seems more likely given your experience?"
```

## Red Flags — STOP and Return to Phase 1

If you catch yourself:
- Proposing a fix without tracing the root cause
- Adding try/catch or null checks to suppress errors, or removing a guard before confirming an ADR doesn't explain why it's there
- Making multiple changes at once "just to be safe"
- Thinking "let me just try this"
- Reading code for 5+ minutes without asking the user anything

**STOP. Go back to Phase 1.**

## Quick Reference

| Phase | Action | Gate |
|-------|--------|------|
| 1. Understand | Ask user, read errors, check changes | Know the symptom clearly |
| 2. Trace | Backward tracing + diagnostic logging | Found where bad data originates |
| 3. Confirm | State root cause to user | User agrees with diagnosis |
| 4. Fix | Single targeted fix + verify | Tests pass, no regressions |
